--!strict
-- ModuleScript: ServerScriptService.Modules.StoryEpisodeService  (v10; Reborn v4 "Legendary Episodes")
-- Runs Shared/StoryEpisodes through the pure Shared/EpisodeLogic state machine. Server-authoritative: every objective,
-- threshold, struggle result, checkpoint and reward is decided here; clients only play cinematics/HUD and send intent.
-- Reuses: BossNPC (boss/spar AI, arenas, telegraphs), Combat (moves, parry, startBossStruggle), Combatant (temporary
-- legendary-fighter swap, restored afterwards), PlayerData (profile.episodes v10 + grantReward), Net/RateLimit.
-- Remotes: EpisodeList (c->s request, s->c list) | EpisodeStart(id) | EpisodeInput(kind, actIndex?) | EpisodeUpdate (s->c).
-- Arena: a part tagged StoryArena with attribute EpisodeId (authored map; optional pads tagged StorySpawn / StoryBossPad /
-- StoryAllyPad with the same EpisodeId), else a generated canyon on a BossNPC instance platform.
-- Safety: no reward on quit / disconnect / KO-quit; EpisodeLogic.finish runs once per run; the boss can't die before the
-- finisher (BossNPC minHp), players in a live tournament round can't start; RoundManager ignores InRaid players.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local StoryEpisodes = require(Shared.StoryEpisodes)
local EpisodeLogic = require(Shared.EpisodeLogic)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local Combat = require(script.Parent.Combat)
local Combatant = require(script.Parent.Combatant)
local BossNPC = require(script.Parent.BossNPC)

local StoryEpisodeService = {}
local ListR = Net.remote("EpisodeList")
local StartR = Net.remote("EpisodeStart")
local InputR = Net.remote("EpisodeInput")
local Update = Net.remote("EpisodeUpdate")
local PlayVFX = Net.remote("PlayVFX")
local SignalHook = Net.hook("CombatSignal")

local episodes: { any } = {}
local byId: { [string]: any } = {}
local runs: { [Player]: any } = {}

local ACTOR_TAG = "EpisodeActor" -- client resolves actors by tag + attributes (OwnerId, Role) if a ref arrives before replication
local BOSS_FLOOR = 0.05 -- boss HP floor (fraction) until the finisher

-- ===== helpers =====
local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function humOf(p: Player): Humanoid?
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end
local function rgb(c: any, default: Color3): Color3
	if type(c) == "table" and #c == 3 then return Color3.fromRGB(c[1], c[2], c[3]) end
	return default
end
local function tagActor(m: Instance, p: Player, role: string)
	m:SetAttribute("OwnerId", p.UserId)
	m:SetAttribute("Role", role)
	CollectionService:AddTag(m, ACTOR_TAG)
end
local function send(run: any, payload: any)
	if run.p.Parent then Update:FireClient(run.p, payload) end
end
local function bossModel(run: any): Model?
	return run.boss and run.boss.alive and run.boss.model or nil
end
local function bossHum(run: any): Humanoid?
	local m = bossModel(run)
	return m and m:FindFirstChildOfClass("Humanoid")
end
local function holdPlayer(run: any, on: boolean)
	local r = rootOf(run.p)
	if r then r.Anchored = on end
end

-- Decorative, non-hittable actor (the ally). Approved art from ReplicatedStorage.CharacterModels[visual] (scripts
-- stripped, anchored, scaled to ~7 studs), else a generated R15 rig in the spec colours.
local function makeActor(spec: any, at: CFrame, parent: Instance): Model
	local lib = ReplicatedStorage:FindFirstChild("CharacterModels")
	local src = lib and spec.visual and lib:FindFirstChild(spec.visual)
	local m: Model
	if src and src:IsA("Model") then
		m = src:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
		end
		local _, size = m:GetBoundingBox()
		if size.Y > 0 then pcall(function() m:ScaleTo(m:GetScale() * 7 / size.Y) end) end
	else
		local desc = Instance.new("HumanoidDescription")
		local skin = rgb(spec.color, Color3.fromRGB(90, 160, 70))
		desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = skin, skin, skin
		desc.TorsoColor, desc.LeftLegColor, desc.RightLegColor = Color3.fromRGB(90, 50, 140), Color3.fromRGB(90, 50, 140), Color3.fromRGB(90, 50, 140)
		desc.HeightScale, desc.WidthScale, desc.HeadScale = 1.15, 1.05, 1
		local ok, rig = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
		if ok and rig then m = rig else m = Instance.new("Model") end
		for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
	end
	if not m:FindFirstChild("HumanoidRootPart") then -- VFX modules anchor effects on HumanoidRootPart
		local cf, size = m:GetBoundingBox()
		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"; hrp.Size = Vector3.new(2, 2, 1); hrp.Transparency = 1
		hrp.Anchored = true; hrp.CanCollide = false; hrp.CanQuery = false
		hrp.CFrame = cf * CFrame.new(0, math.max(0, size.Y * 0.1), 0)
		hrp.Parent = m
	end
	m.PrimaryPart = m:FindFirstChild("HumanoidRootPart") :: BasePart
	m.Name = spec.name or "Ally"
	m:SetAttribute("Character", spec.id)
	m:PivotTo(at)
	m.Parent = parent
	return m
end

-- Generated canyon dressing for the fallback platform (authored StoryArena maps replace this). Lives in the arena folder,
-- so BossNPC.freeArena destroys it with the floor.
local function dressCanyon(folder: Instance, center: CFrame)
	local floor = folder:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		floor.Material = Enum.Material.Ground
		floor.Color = Color3.fromRGB(120, 92, 66)
	end
	local rng = Random.new(1984)
	local base = center.Position - Vector3.new(0, 5, 0)
	for i = 1, 26 do
		local a = (i / 26) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local radius = rng:NextNumber(96, 112)
		local h = rng:NextNumber(35, 95)
		local w = rng:NextNumber(18, 34)
		local rock = Instance.new("Part")
		rock.Name = "CanyonWall"; rock.Anchored = true
		rock.Size = Vector3.new(w, h, rng:NextNumber(16, 28))
		rock.Material = if i % 3 == 0 then Enum.Material.Rock else Enum.Material.Slate
		rock.Color = Color3.fromRGB(rng:NextInteger(105, 140), rng:NextInteger(78, 98), rng:NextInteger(58, 74))
		local pos = base + Vector3.new(math.cos(a) * radius, h / 2 - 2, math.sin(a) * radius)
		rock.CFrame = CFrame.lookAt(pos, Vector3.new(base.X, pos.Y, base.Z)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.1, 0.1))
		rock.Parent = folder
	end
	for i = 1, 14 do -- scattered boulders for cover / readable motion
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(35, 85)
		local s = rng:NextNumber(4, 11)
		local b = Instance.new("Part")
		b.Name = "Boulder"; b.Anchored = true; b.Shape = Enum.PartType.Ball
		b.Size = Vector3.one * s; b.Material = Enum.Material.Rock
		b.Color = Color3.fromRGB(110, 86, 64)
		b.Position = base + Vector3.new(math.cos(a) * d, s * 0.3, math.sin(a) * d)
		b.Parent = folder
	end
	-- pod crater behind the boss mark
	local craterAt = (center * CFrame.new(0, -5, -52)).Position
	local rim = Instance.new("Part")
	rim.Name = "CraterRim"; rim.Anchored = true; rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(2.2, 30, 30); rim.Material = Enum.Material.Basalt; rim.Color = Color3.fromRGB(70, 56, 46)
	rim.CFrame = CFrame.new(craterAt + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	rim.Parent = folder
	local pod = Instance.new("Part")
	pod.Name = "SaiyanPod"; pod.Anchored = true; pod.Shape = Enum.PartType.Ball
	pod.Size = Vector3.one * 9; pod.Material = Enum.Material.Metal; pod.Color = Color3.fromRGB(225, 225, 235)
	pod.Position = craterAt + Vector3.new(0, 3.4, 0)
	pod.Parent = folder
	local glass = Instance.new("Part")
	glass.Name = "PodWindow"; glass.Anchored = true; glass.Shape = Enum.PartType.Ball; glass.CanCollide = false
	glass.Size = Vector3.one * 4.2; glass.Material = Enum.Material.Neon; glass.Color = Color3.fromRGB(200, 40, 60)
	glass.Position = pod.Position + (center.LookVector * 3.2) + Vector3.new(0, 1.2, 0)
	glass.Parent = folder
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(90, 85, 80); smoke.Opacity = 0.18; smoke.RiseVelocity = 6; smoke.Size = 6
	smoke.Parent = pod
end

local function pad(tag: string, id: string): BasePart?
	for _, x in CollectionService:GetTagged(tag) do
		if x:IsA("BasePart") and x:GetAttribute("EpisodeId") == id then return x end
	end
	return nil
end

-- Returns arena instance, centre CFrame, slot, and spawn/boss/ally CFrames.
local function allocArena(def: any): (Instance, CFrame, number, any)
	for _, a in CollectionService:GetTagged("StoryArena") do
		if a:IsA("BasePart") and a:GetAttribute("EpisodeId") == def.id and not a:GetAttribute("InUse") then
			a:SetAttribute("InUse", true)
			local center = a.CFrame + Vector3.new(0, a.Size.Y / 2 + 3, 0)
			local sp, bp, ap = pad("StorySpawn", def.id), pad("StoryBossPad", def.id), pad("StoryAllyPad", def.id)
			return a, center, -1, {
				spawn = if sp then sp.CFrame + Vector3.new(0, 3, 0) else center * CFrame.new(0, 0, 35),
				boss = if bp then bp.CFrame + Vector3.new(0, 5, 0) else center * CFrame.new(0, 2, -30),
				ally = if ap then ap.CFrame + Vector3.new(0, 3, 0) else center * CFrame.new(-16, 0, 26),
			}
		end
	end
	local inst, center, slot = BossNPC.allocArena(nil)
	dressCanyon(inst, center)
	local function facing(off: CFrame): CFrame
		local pos = (center * off).Position
		return CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
	end
	return inst, center, slot, {
		spawn = facing(CFrame.new(0, 0, 35)),
		boss = facing(CFrame.new(0, 2, -30)),
		ally = facing(CFrame.new(-16, 0, 26)),
	}
end

local function freeArena(run: any)
	if run.slot < 0 then
		run.arena:SetAttribute("InUse", nil)
	else
		BossNPC.freeArena(run.arena, run.slot)
	end
end

local function teleport(p: Player, cf: CFrame)
	local r = rootOf(p)
	if r then
		r.AssemblyLinearVelocity = Vector3.zero
		r.CFrame = cf
	end
end

-- ===== run flow =====
local startAct: (run: any) -> ()
local finishRun: (run: any, result: string) -> ()

local function nextAct(run: any)
	if run.ended then return end
	local a = EpisodeLogic.advance(run.state, run.def)
	if not a then
		finishRun(run, "clear")
		return
	end
	startAct(run)
end

-- the boss appears on the first act that needs him: a fight act, or a cinematic framing him
local function usesBoss(a: any): boolean
	if a.kind == "boss" or a.kind == "clash" or a.kind == "hold" then return true end
	for _, b in a.beats or {} do
		if b.subject == "boss" then return true end
	end
	return false
end

local function actorRefs(run: any): any
	return { lead = run.p.Character, ally = run.ally, boss = bossModel(run), spar = run.spar and run.spar.model or nil }
end

local function spawnBoss(run: any)
	if bossModel(run) then return end
	local def = run.def
	run.boss = BossNPC.spawn(def.boss, run.pads.boss, run.arena, { run.p }, {
		hpMult = 1,
		dmgMult = 1,
		onDefeated = function()
			run.bossDown = true
		end,
	})
	run.boss.minHp = (run.boss.model:FindFirstChildOfClass("Humanoid") :: Humanoid).MaxHealth * BOSS_FLOOR
	tagActor(run.boss.model, run.p, "boss")
	BossNPC.setFrozen(run.boss, true)
end

local function despawnSpar(run: any)
	if run.spar then
		if run.spar.alive then BossNPC.despawn(run.spar) end
		run.spar = nil
	end
end

local function objectivesView(run: any): { any }
	local out = {}
	for _, o in run.def.objectives do
		table.insert(out, { id = o.id, text = o.text, have = run.state.progress[o.id] or 0, need = o.count or 1 })
	end
	return out
end

local function onSignal(run: any, signal: string)
	local a = EpisodeLogic.current(run.state, run.def)
	if run.ended or run.trainDone or not a or a.kind ~= "train" then return end
	local done = EpisodeLogic.onSignal(run.state, run.def, signal)
	send(run, { cue = "objectives", objectives = objectivesView(run), done = done })
	if done then
		run.trainDone = true
		local token = run.token
		task.delay(1.4, function()
			if run.token == token then
				despawnSpar(run)
				nextAct(run)
			end
		end)
	end
end

local function snapshotBoss(run: any)
	local h = bossHum(run)
	run.bossSnapshot = if h then h.Health else nil
end

-- Ally (Piccolo) chip shots during boss acts: small, never pushes the boss past the act threshold.
local function allyAssist(run: any, token: number, untilHp: number?)
	task.spawn(function()
		while run.token == token and not run.ended do
			task.wait(3.6)
			local m, h = bossModel(run), bossHum(run)
			if run.token ~= token or not m or not h or not run.ally or run.boss.frozen then continue end
			local target = (m:FindFirstChild("HumanoidRootPart") :: BasePart).Position
			PlayVFX:FireAllClients("KiBlast", run.ally, target)
			task.delay(0.45, function()
				local h2 = bossHum(run)
				if run.token == token and h2 and h2.Health / h2.MaxHealth > (untilHp or 0) + 0.06 then
					BossNPC.damage(nil, run.boss.model, 20)
				end
			end)
		end
	end)
end

local function watchThreshold(run: any, token: number, untilHp: number?)
	task.spawn(function()
		while run.token == token and not run.ended do
			task.wait(0.2)
			local h = bossHum(run)
			if run.token ~= token then return end
			if h and untilHp and h.Health / h.MaxHealth <= untilHp then
				nextAct(run)
				return
			end
			if not h and run.bossDown then -- defeated outright (should not happen with minHp), treat as reaching the end
				nextAct(run)
				return
			end
		end
	end)
end

local function runClash(run: any, token: number)
	local def, m = run.def, bossModel(run)
	local pr = rootOf(run.p)
	if not m or not pr then return end
	local br = m:FindFirstChild("HumanoidRootPart") :: BasePart
	BossNPC.setFrozen(run.boss, true)
	br.CFrame = CFrame.lookAt(br.Position, Vector3.new(pr.Position.X, br.Position.Y, pr.Position.Z))
	pr.CFrame = CFrame.lookAt(pr.Position, Vector3.new(br.Position.X, pr.Position.Y, br.Position.Z))
	local cfg = def.clash
	PlayVFX:FireAllClients(cfg.beam or "Kamehameha", run.p.Character, br.Position)
	PlayVFX:FireAllClients(cfg.bossBeam or "GalickGun", m, pr.Position)
	local ok = Combat.startBossStruggle(run.p, m, {
		mode = "clash", maxTime = cfg.maxTime, winScore = cfg.winScore, bossRate = cfg.bossRate,
		onEnd = function(result: string)
			if run.token ~= token or run.ended then return end
			send(run, { cue = "struggleResult", mode = "clash", result = result })
			if result == "win" then
				local h = bossHum(run)
				if h then BossNPC.damage(run.p, m, h.MaxHealth * (cfg.winDamage or 0.2)) end
				task.delay(1.2, function() if run.token == token then nextAct(run) end end)
			elseif result == "lose" then
				local ph = humOf(run.p)
				if ph then ph:TakeDamage(cfg.loseDamage or 30) end
				task.delay(2, function() if run.token == token and not run.ended then startAct(run) end end) -- go again
			elseif not run.pendingKO then -- "abort" without a KO (combat state reset, stun): restart the act, never stall
				task.delay(1, function() if run.token == token and not run.ended then startAct(run) end end)
			end -- a KO's abort is handled by the KO flow (the token already moved on)
		end,
	})
	if not ok then task.delay(1, function() if run.token == token then startAct(run) end end) end
end

local function runHold(run: any, token: number)
	local def, m = run.def, bossModel(run)
	local pr = rootOf(run.p)
	if not m or not pr then return end
	local br = m:FindFirstChild("HumanoidRootPart") :: BasePart
	BossNPC.setFrozen(run.boss, true)
	-- full nelson from behind: player pinned to the boss's back, both held in place
	pr.CFrame = br.CFrame * CFrame.new(0, 0, 3.2)
	holdPlayer(run, true)
	if run.ally then run.ally:SetAttribute("Form", "Legendary") end -- ally charge aura
	local cfg = def.hold
	local ok = Combat.startBossStruggle(run.p, m, {
		mode = "hold", maxTime = cfg.maxTime, winScore = cfg.winScore, bossRate = cfg.bossRate, startScore = cfg.startScore,
		onEnd = function(result: string)
			if run.token ~= token or run.ended then return end
			holdPlayer(run, false)
			if run.ally then run.ally:SetAttribute("Form", nil) end
			send(run, { cue = "struggleResult", mode = "hold", result = result })
			if result == "win" then
				nextAct(run)
			elseif result == "lose" then
				-- Raditz breaks free: shove, resume his AI, re-arm the hold after `rearm` seconds
				local pr2, br2 = rootOf(run.p), m:FindFirstChild("HumanoidRootPart") :: BasePart?
				if pr2 and br2 then
					local flat = Vector3.new(pr2.Position.X - br2.Position.X, 0, pr2.Position.Z - br2.Position.Z)
					pr2.AssemblyLinearVelocity = (if flat.Magnitude > 0.1 then flat.Unit else Vector3.zAxis) * 70 + Vector3.new(0, 25, 0)
				end
				BossNPC.setFrozen(run.boss, false)
				task.delay(cfg.rearm or 6, function() if run.token == token and not run.ended then startAct(run) end end)
			elseif not run.pendingKO then -- "abort" without a KO: re-arm the hold instead of stalling
				task.delay(1, function() if run.token == token and not run.ended then startAct(run) end end)
			end
		end,
	})
	if not ok then
		holdPlayer(run, false)
		task.delay(1, function() if run.token == token then startAct(run) end end)
	end
end

local function playFinisher(run: any)
	local m = bossModel(run)
	if not m or not run.ally then return end
	local target = (m:FindFirstChild("HumanoidRootPart") :: BasePart).Position
	PlayVFX:FireAllClients(run.def.finisher.vfx or "SpecialBeamCannon", run.ally, target)
	task.delay(2.4, function() -- SBC charge (2 s) + travel
		if run.ended then return end -- runs even if the finisher cinematic was skipped (token moved on)
		local h = bossHum(run)
		if run.boss and h then
			run.boss.minHp = nil
			BossNPC.damage(run.p, m, h.Health + 1)
		end
	end)
end

startAct = function(run: any)
	if run.ended then return end
	run.token += 1
	local token = run.token
	local state, def = run.state, run.def
	local a = EpisodeLogic.current(state, def)
	if not a then finishRun(run, "clear"); return end
	local cinematic = a.kind == "cinematic"
	holdPlayer(run, cinematic)
	if not bossModel(run) and not run.bossDown and usesBoss(a) then spawnBoss(run) end
	if run.boss and run.boss.alive then BossNPC.setFrozen(run.boss, a.kind ~= "boss") end
	if a.checkpoint then snapshotBoss(run) end

	send(run, {
		cue = "act", index = state.act, total = #def.acts, id = a.id, kind = a.kind, episode = def.id,
		canSkip = EpisodeLogic.canSkip(state, a), summary = if not state.firstClear then a.summary else nil,
		guide = a.guide == true and state.firstClear and state.deaths == 0,
		actors = actorRefs(run), anchor = run.center, lighting = def.lighting,
		objectives = if a.kind == "train" then objectivesView(run) else nil,
		hold = if a.kind == "hold" then def.hold else nil, clash = if a.kind == "clash" then def.clash else nil,
		deaths = state.deaths,
	})

	if cinematic then
		if a.finisher then playFinisher(run) end
		task.delay((a.maxSeconds or 10) + 4, function() -- watchdog: never stall on a missing client reply
			if run.token == token then nextAct(run) end
		end)
	elseif a.kind == "train" then
		run.trainDone = false
		table.clear(state.progress)
		despawnSpar(run)
		local spec = table.clone(def.spar)
		run.spar = BossNPC.spawn(spec, run.pads.boss * CFrame.new(0, 0, 18), run.arena, { run.p }, {
			hpMult = 1, dmgMult = 1,
			onDamaged = function(_b, att, _amount) if att == run.p then onSignal(run, "storyHit") end end,
			onStrike = function(_b, _p, outcome) if outcome == "Parry" then onSignal(run, "parry") end end,
		})
		tagActor(run.spar.model, run.p, "spar")
		if run.ally then run.ally.Parent = nil end -- Piccolo is the sparring partner during training
	elseif a.kind == "boss" then
		if run.ally and not run.ally.Parent then run.ally.Parent = run.arena end
		watchThreshold(run, token, a.untilHp)
		if a.allyAssist then allyAssist(run, token, a.untilHp) end
	elseif a.kind == "clash" then
		task.delay(0.6, function() if run.token == token then runClash(run, token) end end)
	elseif a.kind == "hold" then
		task.delay(0.4, function() if run.token == token then runHold(run, token) end end)
	end
end

finishRun = function(run: any, result: string)
	if run.ended then return end
	run.ended = true
	run.token += 1
	local p, def = run.p, run.def
	local reward, first = EpisodeLogic.finish(run.state, def, result)
	local elapsed = os.clock() - run.t0
	if result == "clear" then
		local prof = PlayerData.get(p) :: any
		if prof then
			if type(prof.episodes) ~= "table" then prof.episodes = {} end
			prof.episodes[def.id] = EpisodeLogic.recordClear(prof.episodes[def.id], elapsed)
		end
		if reward then
			PlayerData.grantReward(p, reward) -- saves
		else
			PlayerData.saveSoon(p)
		end
	end
	send(run, { cue = "end", result = result, rewards = reward, first = first, time = math.floor(elapsed), episode = def.id })
	for _, c in run.conns do c:Disconnect() end
	task.delay(if result == "clear" then 5 else 1, function()
		despawnSpar(run)
		if run.boss and run.boss.alive then BossNPC.despawn(run.boss) end
		if run.ally then run.ally:Destroy() end
		freeArena(run)
		if p.Parent then
			holdPlayer(run, false)
			p:SetAttribute("InRaid", nil)
			p:SetAttribute("InStory", nil)
			p:SetAttribute("Episode", nil)
			Combat.resetPlayer(p)
			if run.prevChar then Combatant.setCharacter(p, run.prevChar) else Combatant.ensureValidPick(p) end
			local spawn = (workspace:FindFirstChild("WorldOfVoid") or workspace):FindFirstChild("Spawn_Lobby_01", true) :: BasePart?
			if spawn then teleport(p, spawn.CFrame + Vector3.new(0, 3, 0)) end
		end
		if runs[p] == run then runs[p] = nil end
	end)
end

-- KO: respawn at the episode's last checkpoint instead of the lobby
local function bindCharacter(run: any, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum or run.ended then return end
	table.insert(run.conns, hum.Died:Connect(function()
		if run.ended then return end
		run.pendingKO = true
		run.token += 1 -- cancels the running act (struggles abort on their own)
		if run.boss and run.boss.alive then BossNPC.setFrozen(run.boss, true) end
		send(run, { cue = "ko", deaths = run.state.deaths + 1 })
	end))
end

local function onRespawn(run: any, char: Model)
	if run.ended then return end
	task.spawn(function()
		local r = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if not r or run.ended or runs[run.p] ~= run then return end
		bindCharacter(run, char)
		if run.ally then run.ally:SetAttribute("Form", nil) end
		task.wait(0.2)
		Combat.resetPlayer(run.p)
		Combatant.setCharacter(run.p, run.def.lead)
		teleport(run.p, run.pads.spawn)
		-- a real KO resumes at the checkpoint; any other character reload just restarts the current act
		if run.pendingKO then
			run.pendingKO = false
			EpisodeLogic.onDeath(run.state)
		end
		local h = bossHum(run)
		if h and run.bossSnapshot then h.Health = math.max(h.Health, run.bossSnapshot) end -- checkpoint restores boss HP
		local bm = bossModel(run)
		local br = bm and bm:FindFirstChild("HumanoidRootPart") :: BasePart?
		if br then br.CFrame = run.pads.boss end
		startAct(run)
	end)
end

-- ===== remotes =====
local function records(p: Player): { [string]: any }
	local prof = PlayerData.get(p) :: any
	return if prof and type(prof.episodes) == "table" then prof.episodes else {}
end

ListR.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "episodelist", 1, 2) then return end
	local rec = records(p)
	local out = {}
	for _, e in episodes do
		local r = rec[e.id]
		table.insert(out, {
			id = e.id, title = e.title, saga = e.saga, blurb = e.blurb, minutes = e.minutes, lead = e.lead,
			cleared = r ~= nil and r.cleared == true, clears = r and r.clears or 0, bestTime = r and r.bestTime,
			unlocked = EpisodeLogic.unlocked(episodes, e.id, rec), rewards = e.rewards,
		})
	end
	ListR:FireClient(p, { available = #episodes > 0, episodes = out })
end)

StartR.OnServerEvent:Connect(function(p, id)
	if type(id) ~= "string" or not RateLimit.allow(p, "episodestart", 1, 2) then return end
	local def = byId[id]
	if not def or runs[p] or p:GetAttribute("InRaid") or p:GetAttribute("InStory") then return end
	if workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") == true then return end
	local prof = PlayerData.get(p) :: any
	if not prof then return end
	if not EpisodeLogic.unlocked(episodes, id, records(p)) then
		Update:FireClient(p, { cue = "error", error = "Locked" })
		return
	end
	if not rootOf(p) then return end
	local rec = records(p)[id]
	local arena, center, slot, pads = allocArena(def)
	local run: any = {
		p = p, def = def, state = EpisodeLogic.newRun(def, not (rec and rec.cleared)),
		arena = arena, center = center, slot = slot, pads = pads, token = 0, ended = false, conns = {},
		prevChar = Combatant.activeCharacter(p), t0 = os.clock(), boss = nil, spar = nil, ally = nil,
	}
	runs[p] = run
	p:SetAttribute("InRaid", true) -- lets Combat target bosses; RoundManager skips InRaid players
	p:SetAttribute("InStory", true)
	p:SetAttribute("Episode", id)
	Combat.resetPlayer(p)
	Combatant.setCharacter(p, def.lead)
	teleport(p, pads.spawn)
	run.ally = makeActor(def.ally, pads.ally, arena)
	tagActor(run.ally, p, "ally")
	if p.Character then task.spawn(bindCharacter, run, p.Character) end
	table.insert(run.conns, p.CharacterAdded:Connect(function(c) onRespawn(run, c) end))
	task.delay(0.5, function() startAct(run) end) -- let the actors replicate before the first cue
end)

InputR.OnServerEvent:Connect(function(p, kind, index)
	if type(kind) ~= "string" or not RateLimit.allow(p, "episodeinput", 4, 6) then return end
	local run = runs[p]
	if not run or run.ended then return end
	if kind == "quit" then
		finishRun(run, "quit")
	elseif kind == "ready" then
		local a = EpisodeLogic.current(run.state, run.def)
		if a and a.kind == "cinematic" and index == run.state.act then nextAct(run) end
	end
end)

SignalHook.Event:Connect(function(p: Player, kind: string)
	local run = runs[p]
	if run then onSignal(run, kind) end
end)

-- ===== lifecycle =====
function StoryEpisodeService.load(): boolean
	local list, errs = EpisodeLogic.normalize(StoryEpisodes.LIST)
	for _, e in errs do warn("[StoryEpisodeService] skipped: " .. e) end
	episodes = list
	byId = {}
	for _, e in list do byId[e.id] = e end
	return #list > 0
end

function StoryEpisodeService.init()
	StoryEpisodeService.load()
	Players.PlayerRemoving:Connect(function(p)
		local run = runs[p]
		if run then finishRun(run, "disconnect") end
	end)
end

function StoryEpisodeService.isActive(p: Player): boolean
	return runs[p] ~= nil
end

return StoryEpisodeService
