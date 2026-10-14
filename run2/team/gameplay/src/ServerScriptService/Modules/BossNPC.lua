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

local BossNPC = {}
local CombatEvent = Net.remote("CombatEvent")
local hooks: any = { attack = nil, takeKi = nil, lastMove = nil }
function BossNPC.setHooks(h: any) hooks = h end

export type Boss = {
	model: Model, def: any, players: { Player }, hpMult: number, dmgMult: number, phase: number, alive: boolean,
	cds: { [string]: number }, lastMelee: number, dmgBy: { [Player]: number }, hitsBy: { [Player]: number },
	onDefeated: ((Boss) -> ())?, stunUntil: number,
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
local function build(def: any, at: CFrame): Model
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromRGB(230, 200, 170); desc.TorsoColor = def.color or Color3.fromRGB(60, 140, 80)
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
		phase = 1, alive = true, cds = {}, lastMelee = 0, dmgBy = {}, hitsBy = {}, onDefeated = o.onDefeated, stunUntil = 0 }
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
	hum:TakeDamage(amount)
	if att then
		b.dmgBy[att] = (b.dmgBy[att] or 0) + amount
		b.hitsBy[att] = (b.hitsBy[att] or 0) + 1
	end
	CombatEvent:FireAllClients("Hit", { m, if att then att.UserId else 0, math.floor(amount + 0.5), 0, hum.Health <= 0 })
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
local function strike(b: Boss, p: Player, dmg: number, kb: number)
	if hooks.attack then hooks.attack(b.model, p, { damage = dmg * b.dmgMult * mod(b).dmg, kb = kb, hitstun = 0.4, lethal = true,
		inRound = b.def.topEvent == true }) end
end
local function aoe(b: Boss, name: string, pos: Vector3, sp: any)
	CombatEvent:FireAllClients("BossTelegraph", { b.model, name, pos, sp.radius or 10, sp.windup or 0.8 })
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
}

function BossNPC.tick()
	local now = os.clock()
	for m, b in bosses do
		if not b.alive then continue end
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
		local tr = proot(target) :: BasePart
		for name, sp in (b.def.specials or {}) do
			local fn = SPECIALS[name]
			if fn and now - (b.cds[name] or now - sp.cd * 0.5) >= sp.cd * mod(b).cdMult then
				b.cds[name] = now
				fn(b, sp, target, tr)
				break
			end
		end
		local mel = b.def.melee
		if best > (mel.range or 8) then hum:MoveTo(tr.Position)
		elseif now - b.lastMelee >= mel.cd * mod(b).cdMult then
			b.lastMelee = now
			strike(b, target, mel.damage, mel.kb or 40)
		end
	end
end

return BossNPC
