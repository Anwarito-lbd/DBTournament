--!strict
-- ModuleScript: ServerScriptService.Modules.SpiritBomb  (GDD §6.6, Config.SPIRIT_BOMB)
-- Caster (Goku always; Saiyan/Half-Saiyan with the SpiritBomb power-up, Lv40) channels 6 s: armored, locked, speed x0.3.
-- Teammates within 60 studs hold GiveKi(true): 5 ki/s each from their SERVER ki ledger, max 4 donors.
-- radius = 6 + 0.35*ki (<=30), damage = 40 + 0.6*ki (<=100), arena DamageAt(pos, radius, 150 + ki).
-- The thrown bomb travels 40 studs/s; damage goes through Combat.resolveHit (compressed to the 1.35x STAT_CAP, Ranked = 1).
-- Counterplay: a perfect guard (within the parry window) by an S-tier-or-higher defender deflects it back at 50% damage.
-- Remotes: GiveKi(holding: boolean). Events (CombatEvent): SpiritBombStart, SpiritBombSize, SpiritBombThrow,
-- SpiritBombDeflect, SpiritBombDetonate, SpiritBombCancel. VFX kinds: SpiritBombCharge, SpiritBombThrow, SpiritBombDetonate.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local Combat = require(script.Parent.Combat)
local Combatant = require(script.Parent.Combatant)
local Arena = require(script.Parent.Arena)
local DevBots = require(script.Parent.DevBots)
local BossNPC = require(script.Parent.BossNPC)
local QuestService = require(script.Parent.QuestService)

local SpiritBomb = {}
local U = Combat.util
local CFG = Config.SPIRIT_BOMB
local GiveKi = Net.remote("GiveKi")

type Bomb = { caster: Player, ki: number, donors: { [Player]: boolean }, holding: { [Player]: boolean }, t0: number, target: Vector3 }
local bombs: { [Player]: Bomb } = {} -- by caster
local ThrownHook = Net.hook("SpiritBombThrown") -- (caster, bomb) server signal for the ToP flow / announcer
-- v8: RoundManager calls this between rounds so no channel/bomb survives into the next match
function SpiritBomb.resetRound() table.clear(bombs) end

function SpiritBomb.size(ki: number): (number, number)
	return math.min(CFG.maxRadius, CFG.baseRadius + CFG.radiusPerKi * ki), math.min(CFG.maxDamage, CFG.baseDamage + CFG.damagePerKi * ki)
end

local function bombNear(p: Player): Bomb?
	local pr = U.rootOf(p)
	if not pr then return nil end
	for caster, b in bombs do
		local cr = U.rootOf(caster)
		if caster ~= p and caster.Team == p.Team and p.Team ~= nil and cr and (cr.Position - pr.Position).Magnitude <= CFG.donorRange then
			return b
		end
	end
	return nil
end

GiveKi.OnServerEvent:Connect(function(p, holding)
	if type(holding) ~= "boolean" or not RateLimit.allow(p, "giveki", 4, 6) then return end
	for _, b in bombs do b.holding[p] = nil end
	if not holding or not U.canAct(p) then return end
	local b = bombNear(p)
	if not b then return end
	local n = 0
	for _ in b.donors do n += 1 end
	if not b.donors[p] and n >= CFG.maxDonors then return end
	if not b.donors[p] then b.donors[p] = true; QuestService.track(p, "spiritBombDonate", 1) end
	b.holding[p] = true
end)

local function detonate(owner: Player, pos: Vector3, radius: number, dmg: number, ki: number)
	local mv = { damage = dmg, kb = CFG.kb, guardDamage = 100, hitstun = 0.6, parryable = false, beam = true, ultimate = true,
		radius = radius }
	for _, q in U.enemies(owner) do
		local qr = U.rootOf(q)
		if qr and (qr.Position - pos).Magnitude <= radius + U.hurtRadius(q) then Combat.resolveHit(owner, q, mv, 1) end
	end
	DevBots.hitRadius(owner, pos, mv)
	BossNPC.hitRadius(owner, pos, mv)
	Arena.damageAt(pos, radius, CFG.arenaBase + ki)
	U.PlayVFX:FireAllClients("SpiritBombDetonate", nil, { pos, radius })
	U.event("SpiritBombDetonate", { owner.UserId, radius, dmg })
end

local function throw(b: Bomb)
	local caster = b.caster
	local cr = U.rootOf(caster)
	if not cr then return end
	local radius, dmg = SpiritBomb.size(b.ki)
	local pos = cr.Position + Vector3.new(0, 10 + radius, 0)
	local to = b.target - pos
	local dir = if to.Magnitude > 0.1 then to.Unit else cr.CFrame.LookVector
	local owner, deflected, travelled = caster, false, 0
	U.event("SpiritBombThrow", { caster.UserId, radius, dmg })
	ThrownHook:Fire(caster, b) -- v8 ToP hook (announcer / db-story)
	U.PlayVFX:FireAllClients("SpiritBombThrow", caster.Character, { pos, dir, radius, CFG.speed })
	task.spawn(function()
		local last = os.clock()
		while travelled < CFG.maxTravel do
			task.wait(0.05)
			local dt = os.clock() - last; last = os.clock()
			pos += dir * CFG.speed * dt
			travelled += CFG.speed * dt
			-- hit check: enemy of current owner inside the sphere, or ground
			for _, q in U.enemies(owner) do
				local qr = U.rootOf(q)
				if qr and (qr.Position - pos).Magnitude <= radius + U.hurtRadius(q) then
					local qs = U.state(q)
					local tier = Combatant.tierOf(Combatant.activeCharacter(q))
					if not deflected and qs.blocking and os.clock() - qs.blockSince <= Config.SKILL.ParryWindow + 0.15 and CFG.deflectTiers[tier] then
						deflected = true
						owner = q
						dmg *= CFG.deflectPower
						local back = (U.rootOf(caster) and (U.rootOf(caster) :: BasePart).Position or pos - dir * 50) - pos
						dir = if back.Magnitude > 0.1 then back.Unit else -dir
						travelled = 0
						U.event("SpiritBombDeflect", { q.UserId, caster.UserId })
						break
					end
					detonate(owner, pos, radius, dmg, b.ki); return
				end
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			local ignore = {}
			for _, pl in Players:GetPlayers() do if pl.Character then table.insert(ignore, pl.Character) end end
			params.FilterDescendantsInstances = ignore
			if workspace:Raycast(pos, dir * (radius * 0.5 + 1), params) then detonate(owner, pos, radius, dmg, b.ki); return end
		end
		detonate(owner, pos, radius, dmg, b.ki)
	end)
end

local function cast(p: Player, mv: any, targetPos: Vector3, _id: string)
	if bombs[p] then return end
	local s = U.state(p)
	local h = U.humOf(p)
	if not h then return end
	local b: Bomb = { caster = p, ki = mv.ki or 40, donors = {}, holding = {}, t0 = os.clock(), target = targetPos }
	bombs[p] = b
	s.locked = true; s.blocking = false
	s.armorUntil = os.clock() + CFG.channel
	local baseSpeed = h.WalkSpeed
	h.WalkSpeed = baseSpeed * CFG.moveMult
	local char = p.Character
	U.PlayVFX:FireAllClients("SpiritBombCharge", char, CFG.channel)
	U.event("SpiritBombStart", { p.UserId, CFG.channel })
	task.spawn(function()
		local last = os.clock()
		local ok = true
		while os.clock() - b.t0 < CFG.channel do
			task.wait(0.25)
			local dt = os.clock() - last; last = os.clock()
			if not U.canAct(p) or p.Character ~= char then ok = false; break end
			local cr = U.rootOf(p) :: BasePart
			for d in b.holding do
				local dr = U.rootOf(d)
				if not d.Parent or not U.canAct(d) or d.Team ~= p.Team or not dr or (dr.Position - cr.Position).Magnitude > CFG.donorRange then
					b.holding[d] = nil
				else
					b.ki += Combat.takeKi(d, CFG.donorKiPerSec * dt) -- server ki ledger
				end
			end
			local r, dmg = SpiritBomb.size(b.ki)
			U.event("SpiritBombSize", { p.UserId, r, dmg })
		end
		s.locked = false
		if h.Parent then h.WalkSpeed = baseSpeed end
		bombs[p] = nil
		if not ok then U.event("SpiritBombCancel", { p.UserId }); return end
		throw(b)
	end)
end

Combat.registerKind("spiritbomb", cast)
Players.PlayerRemoving:Connect(function(p) bombs[p] = nil; for _, b in bombs do b.holding[p] = nil; b.donors[p] = nil end end)
local _ = RunService
return SpiritBomb
