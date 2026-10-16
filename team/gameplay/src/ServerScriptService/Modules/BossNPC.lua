--!strict
-- ModuleScript: ServerScriptService.Modules.BossNPC  (v8: boss engine shared by RaidService + StoryMissionService)
-- Boss = Humanoid model (R15 from HumanoidDescription, block fallback) with attributes BossId / AnimId (db-animation id
-- when one exists, e.g. "u7_moro"; else "boss_<name>") / Phase. Server AI (10 Hz on the raid tick): chase nearest living
-- participant, melee via the injected Combat.npcHit (lethal), specials with telegraphs (CombatEvent "BossTelegraph"),
-- phase changes at HP thresholds (RaidMath.phase) with damage/speed/cooldown mods, ArenaDamage via Arena.damageAt.
-- Players damage bosses through normal Combat moves (Combat falls back to BossNPC.hitScan/hit for InRaid players),
-- Hakai (bossDamage 70) and Spirit Bomb (BossNPC.hitRadius). Must NOT require Combat (Combat requires this).
-- Also allocates instance arenas (tag RaidArena from db-map if present, else a generated platform far from the world).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local RaidMath = require(Shared.RaidMath)
local Net = require(script.Parent.Net)
local Arena = require(script.Parent.Arena)
local TelegraphService = require(script.Parent.TelegraphService) -- v10: visible ground telegraphs for every special

local BossNPC = {}
local CombatEvent = Net.remote("CombatEvent")
local PlayVFX = Net.remote("PlayVFX") -- v10: boss specials reuse the hero VFX modules (VFXRouter accepts any Model)
-- attack(npc, vic, mv) -> outcome string; takeKi(p, n); lastMove(p); stunned(p) -> bool (v10, grab escape check)
local hooks: any = { attack = nil, takeKi = nil, lastMove = nil, stunned = nil }
function BossNPC.setHooks(h: any) hooks = h end

export type Boss = {
	model: Model, def: any, players: { Player }, hpMult: number, dmgMult: number, phase: number, alive: boolean,
	cds: { [string]: number }, lastMelee: number, dmgBy: { [Player]: number }, hitsBy: { [Player]: number },
	onDefeated: ((Boss) -> ())?, stunUntil: number,
	-- v10 story hooks: frozen = AI paused (cinematics / struggles); onDamaged(b, att, amount); onStrike(b, p, outcome)
	frozen: boolean, busyUntil: number, minHp: number?, onDamaged: ((Boss, Player?, number) -> ())?, onStrike: ((Boss, Player, string) -> ())?,
}
local bosses: { [Model]: Boss } = {}

local function rootOf(m: Model): BasePart? return m:FindFirstChild("HumanoidRootPart") :: BasePart? end
local function proot(p: Player): BasePart? return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart? end
local function palive(p: Player, b: any?): boolean
	local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	local inside = p:GetAttribute("InRaid") == true or (b ~= nil and b.def.topEvent == true and p:GetAttribute("Alive") == true)
	return p.Parent ~= nil and h ~= nil and h.Health > 0 and inside
end

-- ===== arenas =====
local nextSlot = 0
local freeSlots: { number } = {}
-- v8b: db-map raid maps (WorldOfVoid.Raid.<BrolyCrater|MoroNamek>): floor tagged RaidArena with attrs Boss (= our raidId,
-- "Broly"/"Moro") + RaidId (area/lighting id); RaidSpawn pads (RaidId, Index 1..8) and a RaidBossPad (Boss, RaidId).
-- raidId nil (story) -> generated platform only. Returns (instance, centerCF, slot, info { spawns, bossCF, areaId }).
local function padsFor(tag: string, areaId: string?): { BasePart }
	local out = {}
	for _, x in CollectionService:GetTagged(tag) do
		if x:IsA("BasePart") and x:GetAttribute("RaidId") == areaId then table.insert(out, x) end
	end
	table.sort(out, function(a, b) return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0) end)
	return out
end
function BossNPC.allocArena(raidId: string?): (Instance, CFrame, number, any)
	if raidId then
		for _, a in CollectionService:GetTagged("RaidArena") do
			if a:IsA("BasePart") and a:GetAttribute("Boss") == raidId and not a:GetAttribute("InUse") then
				a:SetAttribute("InUse", true)
				local areaId = a:GetAttribute("RaidId") :: string?
				local spawns = {}
				for _, s in padsFor("RaidSpawn", areaId) do table.insert(spawns, s.CFrame + Vector3.new(0, 3, 0)) end
				local bossPad = padsFor("RaidBossPad", areaId)[1]
				return a, a.CFrame + Vector3.new(0, a.Size.Y / 2 + 3, 0), -1,
					{ spawns = spawns, bossCF = bossPad and (bossPad.CFrame + Vector3.new(0, 5, 0)), areaId = areaId }
			end
		end
	end
	local slot = table.remove(freeSlots) or (function() nextSlot += 1; return nextSlot end)()
	local R = Config.RAID_RUNTIME
	local o = Vector3.new(R.arenaOrigin.x + (slot - 1) * R.arenaSpacing, R.arenaOrigin.y, R.arenaOrigin.z)
	local f = Instance.new("Folder"); f.Name = "RaidArena_" .. slot
	local floor = Instance.new("Part")
	floor.Name = "Floor"; floor.Anchored = true; floor.Size = Vector3.new(R.arenaSize, 4, R.arenaSize)
	floor.Position = o; floor.Material = Enum.Material.Slate; floor.Color = Color3.fromRGB(70, 60, 80); floor.Parent = f
	local w = workspace:FindFirstChild("WorldOfVoid") or workspace
	f.Parent = w
	return f, CFrame.new(o + Vector3.new(0, 5, 0)), slot, { spawns = {}, bossCF = nil, areaId = nil }
end
function BossNPC.freeArena(inst: Instance, slot: number)
	if slot < 0 then inst:SetAttribute("InUse", nil); return end
	inst:Destroy()
	table.insert(freeSlots, slot)
end

-- ===== model =====
-- v10: def.color may be a Color3 or a pure-data { r, g, b } (StoryEpisodes)
local function color3(c: any, default: Color3): Color3
	if typeof(c) == "Color3" then return c end
	if type(c) == "table" and #c == 3 then return Color3.fromRGB(c[1], c[2], c[3]) end
	return default
end

-- v10: approved art from ReplicatedStorage.CharacterModels[def.visual] (Model with Humanoid + HumanoidRootPart).
-- Scripts are stripped (third-party asset safety), parts unanchored so the Humanoid can move. nil -> generated rig.
local function fromLibrary(visual: string?, scale: number?): Model?
	if type(visual) ~= "string" then return nil end
	local lib = game:GetService("ReplicatedStorage"):FindFirstChild("CharacterModels")
	local src = lib and lib:FindFirstChild(visual)
	if not src or not src:IsA("Model") or not src:FindFirstChildOfClass("Humanoid") or not src:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	local m = src:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("LuaSourceContainer") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored = false end
	end
	m.PrimaryPart = m:FindFirstChild("HumanoidRootPart") :: BasePart
	if scale and scale ~= 1 then pcall(function() m:ScaleTo(m:GetScale() * scale) end) end
	return m
end

local function build(def: any, at: CFrame): Model
	local lib = fromLibrary(def.visual, def.scale)
	if lib then
		lib.Name = def.name or "Boss"
		lib:SetAttribute("BossId", def.id or def.name)
		lib:SetAttribute("AnimId", def.animId or def.visual)
		lib:SetAttribute("ChampionModel", def.visual)
		if def.aura then lib:SetAttribute("Form", def.aura) end
		CollectionService:AddTag(lib, "Boss")
		lib:PivotTo(at)
		return lib
	end
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromRGB(230, 200, 170); desc.TorsoColor = color3(def.color, Color3.fromRGB(60, 140, 80))
	desc.LeftArmColor = desc.HeadColor; desc.RightArmColor = desc.HeadColor
	desc.LeftLegColor = desc.TorsoColor; desc.RightLegColor = desc.TorsoColor
	desc.HeightScale = def.scale or 1.4; desc.WidthScale = def.scale or 1.4; desc.DepthScale = def.scale or 1.4; desc.HeadScale = def.scale or 1.4
	local ok, m = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	local model: Model
	if ok and m then model = m else
		model = Instance.new("Model")
		local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(3, 3, 2); root.Transparency = 1; root.Parent = model
		local torso = Instance.new("Part"); torso.Name = "Torso"; torso.Size = Vector3.new(4, 6, 2); torso.Color = desc.TorsoColor; torso.Parent = model
		local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = torso; w.Parent = root
		local h = Instance.new("Humanoid"); h.HipHeight = 3; h.Parent = model
		model.PrimaryPart = root
	end
	model.Name = def.name or "Boss"
	model:SetAttribute("BossId", def.id or def.name)
	model:SetAttribute("AnimId", def.animId) -- db-animation: rig/anim set lookup
	if def.aura then model:SetAttribute("Form", def.aura) end -- AuraRenderer NPC aura
	CollectionService:AddTag(model, "Boss")
	model:PivotTo(at)
	return model
end

function BossNPC.spawn(def: any, at: CFrame, parent: Instance, players: { Player }, opts: any?): Boss
	local o = opts or {}
	local m = build(def, at)
	local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	local hpMult = o.hpMult or RaidMath.hpScale(#players)
	hum.MaxHealth = def.hp * hpMult; hum.Health = hum.MaxHealth
	hum.WalkSpeed = def.walkSpeed or 16
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	m.Parent = parent
	local r = rootOf(m)
	if r then pcall(function() (r :: BasePart):SetNetworkOwner(nil) end) end
	local b: Boss = { model = m, def = def, players = players, hpMult = hpMult, dmgMult = o.dmgMult or RaidMath.dmgScale(#players),
		phase = 1, alive = true, cds = {}, lastMelee = 0, dmgBy = {}, hitsBy = {}, onDefeated = o.onDefeated, stunUntil = 0,
		frozen = false, busyUntil = 0, onDamaged = o.onDamaged, onStrike = o.onStrike }
	bosses[m] = b
	m:SetAttribute("Phase", 1)
	hum.Died:Connect(function() BossNPC.defeat(b) end)
	return b
end

function BossNPC.defeat(b: Boss)
	if not b.alive then return end
	b.alive = false
	CombatEvent:FireAllClients("BossDefeated", { b.model, b.def.name })
	if b.onDefeated then task.spawn(b.onDefeated :: any, b) end
	task.delay(3, function() bosses[b.model] = nil; if b.model.Parent then b.model:Destroy() end end)
end
function BossNPC.despawn(b: Boss) b.alive = false; bosses[b.model] = nil; if b.model.Parent then b.model:Destroy() end end

-- ===== players -> boss =====
function BossNPC.hitScan(att: Player, mv: any, targetPos: Vector3): (Model?, Vector3)
	if att:GetAttribute("InRaid") ~= true and att:GetAttribute("Alive") ~= true then return nil, targetPos end
	local ar = proot(att)
	if not ar then return nil, targetPos end
	local from = ar.Position
	local dir = targetPos - from
	dir = if dir.Magnitude > 0.01 then dir.Unit else ar.CFrame.LookVector
	local best, bestD = nil, math.huge
	for m, b in bosses do
		local r = rootOf(m)
		if b.alive and r and table.find(b.players, att) then
			local rel = r.Position - from
			local reach = 4 -- big hurtbox
			if mv.kind == "melee" then
				local d = rel.Magnitude
				if d <= (mv.range or 7) + reach and d < bestD then best, bestD = m, d end
			else
				local along = rel:Dot(dir)
				if along > 0 and along <= (mv.range or 150) and (rel - dir * along).Magnitude <= (mv.width or 1) + reach and along < bestD then
					best, bestD = m, along
				end
			end
		end
	end
	if best then return best, (rootOf(best) :: BasePart).Position end
	return nil, targetPos
end

function BossNPC.damage(att: Player?, m: Model, amount: number)
	local b = bosses[m]
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not b or not b.alive or not hum or amount <= 0 then return end
	if b.minHp then -- v10: story bosses can't drop below the floor until the scripted finisher clears it
		amount = math.min(amount, hum.Health - b.minHp)
		if amount <= 0 then return end
	end
	hum:TakeDamage(amount)
	if att then
		b.dmgBy[att] = (b.dmgBy[att] or 0) + amount
		b.hitsBy[att] = (b.hitsBy[att] or 0) + 1
	end
	CombatEvent:FireAllClients("Hit", { m, if att then att.UserId else 0, math.floor(amount + 0.5), 0, hum.Health <= 0 })
	if b.onDamaged then task.spawn(b.onDamaged :: any, b, att, amount) end
end
function BossNPC.hit(att: Player, m: Model, mv: any, power: number)
	BossNPC.damage(att, m, (mv.damage or 5) * (power or 1)) -- no PL ratio vs bosses: boss HP scales with party size instead
end
function BossNPC.hitRadius(att: Player, pos: Vector3, mv: any)
	for m, b in bosses do
		local r = rootOf(m)
		if b.alive and r and (r.Position - pos).Magnitude <= (mv.radius or 10) + 4 then BossNPC.damage(att, m, mv.damage or 0) end
	end
end
function BossNPC.get(m: Model): Boss? return bosses[m] end

-- ===== AI =====
local function mod(b: Boss): any return (b.def.phaseMods and b.def.phaseMods[b.phase]) or { dmg = 1, speed = 1, cdMult = 1 } end
local function strike(b: Boss, p: Player, dmg: number, kb: number, hitstun: number?): string
	local outcome = "None"
	if hooks.attack then
		outcome = hooks.attack(b.model, p, { damage = dmg * b.dmgMult * mod(b).dmg, kb = kb, hitstun = hitstun or 0.4, lethal = true,
			inRound = b.def.topEvent == true }) or "None"
	end
	if b.onStrike then task.spawn(b.onStrike :: any, b, p, outcome) end
	return outcome
end

-- v10: floor point under a position (telegraphs sit on the ground, not at root height)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function ground(pos: Vector3): Vector3
	local ex: { Instance } = {}
	for _, p in Players:GetPlayers() do if p.Character then table.insert(ex, p.Character) end end
	for m in bosses do table.insert(ex, m) end
	groundParams.FilterDescendantsInstances = ex
	local hit = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), groundParams)
	return if hit then hit.Position + Vector3.new(0, 0.15, 0) else pos - Vector3.new(0, 3, 0)
end
local RED, ORANGE = Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 150, 40)
local function telegraphCircle(pos: Vector3, radius: number, windup: number, color: Color3?)
	TelegraphService.show({ Shape = "Circle", CFrame = CFrame.new(ground(pos)), Color = color or RED, Duration = windup, Radius = radius })
end

local function aoe(b: Boss, name: string, pos: Vector3, sp: any)
	CombatEvent:FireAllClients("BossTelegraph", { b.model, name, pos, sp.radius or 10, sp.windup or 0.8 })
	telegraphCircle(pos, sp.radius or 10, sp.windup or 0.8)
	task.delay(sp.windup or 0.8, function()
		if not b.alive then return end
		for _, p in b.players do
			local r = proot(p)
			if palive(p, b) and r and (r.Position - pos).Magnitude <= (sp.radius or 10) then strike(b, p, sp.damage or 10, 50) end
		end
		if sp.arenaRadius then Arena.damageAt(pos, sp.arenaRadius, sp.arenaPower or 0) end
		CombatEvent:FireAllClients("BossSpecial", { b.model, name, pos })
	end)
end

local SPECIALS: { [string]: (Boss, any, Player, BasePart) -> () } = {
	EraserCannon = function(b, sp, _t, tr) aoe(b, "EraserCannon", tr.Position, sp) end,
	Stomp = function(b, sp, _t, _tr) aoe(b, "Stomp", (rootOf(b.model) :: BasePart).Position, sp) end,
	Absorb = function(b, sp, t, tr)
		local br = rootOf(b.model) :: BasePart
		if (tr.Position - br.Position).Magnitude > sp.range then return end
		local got = if hooks.takeKi then hooks.takeKi(t, sp.ki) else 0
		local hum = b.model:FindFirstChildOfClass("Humanoid") :: Humanoid
		hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * sp.heal)
		CombatEvent:FireAllClients("BossSpecial", { b.model, "Absorb", t.UserId, got })
	end,
	Copy = function(b, sp, t, tr) -- Moro copies a participant's last move (damage x power, as an AoE at the target)
		local id = hooks.lastMove and hooks.lastMove(t)
		local mv = id and Config.MOVES[id]
		if not mv or not mv.damage then return end
		aoe(b, "Copy:" .. id, tr.Position, { radius = math.max(8, mv.arenaRadius or 8), windup = 0.7, damage = mv.damage * sp.power,
			arenaRadius = mv.arenaRadius, arenaPower = (mv.arenaPower or 0) * sp.power })
	end,
	PlanetDrain = function(b, sp, _t, _tr)
		local pos = (rootOf(b.model) :: BasePart).Position
		for i = 0, sp.pulses - 1 do task.delay(i * 1.2, function() if b.alive then aoe(b, "PlanetDrain", pos, sp) end end) end
	end,
	-- ===== v10 story kit (Raditz); every hit is telegraphed and answerable (parry / dodge / Combo Breaker / dash) =====
	-- Rush: closes the gap, then `hits` melee blows; each one flashes (BossWindup) `gap` s before contact -> parry window.
	Rush = function(b, sp, t, tr)
		local br = rootOf(b.model) :: BasePart
		if (tr.Position - br.Position).Magnitude > (sp.range or 60) then return end -- too far: cooldown spent, keep chasing
		local windup, hits, gap = sp.windup or 0.5, sp.hits or 3, sp.gap or 0.35
		b.busyUntil = os.clock() + windup + hits * gap + 0.4
		telegraphCircle(tr.Position, 6, windup, ORANGE)
		CombatEvent:FireAllClients("BossTelegraph", { b.model, "Rush", tr.Position, 6, windup })
		task.delay(windup, function()
			if not b.alive or b.frozen or not palive(t, b) then return end
			local r2 = proot(t)
			if not r2 then return end
			local flat = Vector3.new(br.Position.X - r2.Position.X, 0, br.Position.Z - r2.Position.Z)
			local dir = if flat.Magnitude > 0.1 then flat.Unit else -r2.CFrame.LookVector
			local dest = r2.Position + dir * 4.5
			br.CFrame = CFrame.lookAt(dest, Vector3.new(r2.Position.X, dest.Y, r2.Position.Z))
			CombatEvent:FireAllClients("BossSpecial", { b.model, "Rush", dest })
			for i = 1, hits do
				CombatEvent:FireAllClients("BossWindup", { b.model, t.UserId, gap })
				task.wait(gap)
				local r3 = proot(t)
				if not b.alive or b.frozen or not r3 or not palive(t, b) then return end
				if (r3.Position - br.Position).Magnitude <= 11 then strike(b, t, sp.damage or 7, if i == hits then 55 else 8) end
			end
		end)
	end,
	-- KiVolley: `shots` staggered blasts at wherever the target is standing; keep moving.
	KiVolley = function(b, sp, t, _tr)
		b.busyUntil = os.clock() + (sp.shots or 4) * (sp.gap or 0.3) + 0.2
		for i = 1, sp.shots or 4 do
			task.delay((i - 1) * (sp.gap or 0.3), function()
				local r2 = proot(t)
				if not b.alive or b.frozen or not r2 then return end
				local pos = r2.Position
				aoe(b, "KiVolley", pos, { radius = sp.radius or 8, windup = sp.windup or 0.7, damage = sp.damage or 8 })
				task.delay(math.max(0, (sp.windup or 0.7) - 0.25), function()
					if b.alive then PlayVFX:FireAllClients("KiBlast", b.model, pos) end
				end)
			end)
		end
	end,
	-- Grab: cone in front. Caught -> held (hitstun) for holdTime; Combo Breaker escapes, otherwise a slam lands.
	Grab = function(b, sp, t, tr)
		local br = rootOf(b.model) :: BasePart
		local windup = sp.windup or 0.8
		local flatTo = Vector3.new(tr.Position.X - br.Position.X, 0, tr.Position.Z - br.Position.Z)
		if flatTo.Magnitude < 0.1 then return end
		local g = ground(br.Position)
		b.busyUntil = os.clock() + windup + (sp.holdTime or 1.6) + 0.3
		br.CFrame = CFrame.lookAt(br.Position, br.Position + flatTo)
		TelegraphService.show({ Shape = "Cone", CFrame = CFrame.lookAt(g, g + flatTo), Color = Color3.fromRGB(200, 60, 255),
			Duration = windup, Radius = sp.range or 12 })
		CombatEvent:FireAllClients("BossTelegraph", { b.model, "Grab", tr.Position, sp.range or 12, windup })
		task.delay(windup, function()
			local r2 = proot(t)
			if not b.alive or b.frozen or not r2 or not palive(t, b) then return end
			local rel = r2.Position - br.Position
			local flat = Vector3.new(rel.X, 0, rel.Z)
			if flat.Magnitude > (sp.range or 12) or (flat.Magnitude > 0.1 and br.CFrame.LookVector:Dot(flat.Unit) < 0.4) then
				CombatEvent:FireAllClients("BossSpecial", { b.model, "GrabWhiff", br.Position })
				return
			end
			local out = strike(b, t, 2, 0, (sp.holdTime or 1.6) + 0.3) -- stun outlasts the check: only a Breaker frees you
			if out ~= "Hit" then return end -- blocked / parried / i-frames: no grab
			CombatEvent:FireAllClients("BossSpecial", { b.model, "Grab", t.UserId, sp.holdTime or 1.6 })
			task.delay(sp.holdTime or 1.6, function()
				if not b.alive or not palive(t, b) then return end
				if hooks.stunned and not hooks.stunned(t) then
					CombatEvent:FireAllClients("BossSpecial", { b.model, "GrabEscape", t.UserId })
					return
				end
				strike(b, t, sp.damage or 18, 70)
				local r3 = proot(t)
				if r3 then Arena.damageAt(r3.Position, 8, 20) end
				CombatEvent:FireAllClients("BossSpecial", { b.model, "GrabSlam", t.UserId })
			end)
		end)
	end,
	-- EnergyWave: long line toward the target, fired through the hero beam VFX (sp.vfx, default GalickGun). Dash sideways.
	EnergyWave = function(b, sp, _t, tr)
		local br = rootOf(b.model) :: BasePart
		local flat = Vector3.new(tr.Position.X - br.Position.X, 0, tr.Position.Z - br.Position.Z)
		if flat.Magnitude < 0.1 then return end
		local dir = flat.Unit
		local len, width, windup = sp.length or 140, sp.width or 10, sp.windup or 1.1
		local g = ground(br.Position)
		b.busyUntil = os.clock() + windup + 0.8
		br.CFrame = CFrame.lookAt(br.Position, br.Position + dir)
		TelegraphService.show({ Shape = "Line", CFrame = CFrame.lookAt(g, g + dir), Color = RED, Duration = windup, Length = len, Width = width })
		CombatEvent:FireAllClients("BossTelegraph", { b.model, "EnergyWave", br.Position + dir * len, width, windup })
		task.delay(math.max(0, windup - 0.3), function()
			if b.alive and not b.frozen then PlayVFX:FireAllClients(sp.vfx or "GalickGun", b.model, br.Position + dir * len) end
		end)
		task.delay(windup, function()
			if not b.alive or b.frozen then return end
			local from = br.Position
			for _, p in b.players do
				local r2 = proot(p)
				if r2 and palive(p, b) then
					local rel = r2.Position - from
					local along = rel:Dot(dir)
					local side = (Vector3.new(rel.X, 0, rel.Z) - dir * along).Magnitude
					if along >= 0 and along <= len and side <= width / 2 + 2 then strike(b, p, sp.damage or 22, 75) end
				end
			end
			Arena.damageAt(from + dir * math.min(len, 60), sp.arenaRadius or 10, sp.arenaPower or 25)
			CombatEvent:FireAllClients("BossSpecial", { b.model, "EnergyWave", from + dir * len })
		end)
	end,
}

-- v10: pause/resume the AI (cinematics, struggles). Frozen bosses hold position (root anchored) and never attack.
function BossNPC.setFrozen(b: Boss, on: boolean)
	b.frozen = on
	local r = rootOf(b.model)
	local hum = b.model:FindFirstChildOfClass("Humanoid")
	if r then
		if hum then hum:MoveTo(r.Position) end
		r.Anchored = on
	end
end

function BossNPC.tick()
	local now = os.clock()
	for m, b in bosses do
		if not b.alive or b.frozen then continue end
		local hum = m:FindFirstChildOfClass("Humanoid")
		local r = rootOf(m)
		if not hum or not r then continue end
		local ph = RaidMath.phase(hum.Health / hum.MaxHealth, b.def.phases or {})
		if ph ~= b.phase then
			b.phase = ph; m:SetAttribute("Phase", ph)
			hum.WalkSpeed = (b.def.walkSpeed or 16) * mod(b).speed
			CombatEvent:FireAllClients("BossPhase", { m, ph })
		end
		local target, best = nil, math.huge
		for _, p in b.players do
			local pr = proot(p)
			if palive(p, b) and pr then
				local d = (pr.Position - r.Position).Magnitude
				if d < best then target, best = p, d end
			end
		end
		if not target then continue end
		if now < b.busyUntil then continue end -- v10: committed to a special / melee windup
		local tr = proot(target) :: BasePart
		local usedSpecial = false
		for name, sp in (b.def.specials or {}) do
			local fn = SPECIALS[name]
			-- first use half a cooldown after the AI wakes (the old `or now - cd/2` default never recorded a time,
			-- so it stayed at cd/2 < cd and no special ever fired, raids included)
			if fn and b.cds[name] == nil then b.cds[name] = now - sp.cd * 0.5 end
			if fn and now - b.cds[name] >= sp.cd * mod(b).cdMult then
				b.cds[name] = now
				fn(b, sp, target, tr)
				usedSpecial = true
				break
			end
		end
		if usedSpecial and now < b.busyUntil then continue end
		local mel = b.def.melee
		if best > (mel.range or 8) then hum:MoveTo(tr.Position)
		elseif now - b.lastMelee >= mel.cd * mod(b).cdMult then
			b.lastMelee = now
			if mel.windup then
				-- v10: telegraphed melee (flash -> contact after `windup`): blocking on the flash is a parry
				local w = mel.windup :: number
				b.busyUntil = now + w + 0.1
				hum:MoveTo(r.Position)
				CombatEvent:FireAllClients("BossWindup", { m, target.UserId, w })
				local tgt = target
				task.delay(w, function()
					local r2, br2 = proot(tgt), rootOf(m)
					if b.alive and not b.frozen and r2 and br2 and palive(tgt, b)
						and (r2.Position - br2.Position).Magnitude <= (mel.range or 8) + 3 then
						strike(b, tgt, mel.damage, mel.kb or 40)
					end
				end)
			else
				strike(b, target, mel.damage, mel.kb or 40)
			end
		end
	end
end

return BossNPC
