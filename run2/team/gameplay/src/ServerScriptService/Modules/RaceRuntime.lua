--!strict
-- ModuleScript: ServerScriptService.Modules.RaceRuntime  (server authority for race traits + modifiers)
-- State per player: active toggles/buffs (Kaioken, Giant, Beast/Rage, Zenkai stacks), beast meter, last-damaged time.
-- All numbers go through StatResolver (pure) -> Combat uses RaceRuntime.stats(p).combat for damage/defense,
-- kiRegen, drains; Power Level keeps forms + the paid 1.35x cap (Combatant). Ranked => StatResolver normalizes.
-- Remotes (client -> server): ActivateModifier(modId) toggles a toggle-kind modifier; ReleaseBeast().
-- Attributes: Race, Modifiers (comma list), ZenkaiStacks, BeastMeter (0..100), RageUsed.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Races = require(Shared.Races)
local Modifiers = require(Shared.Modifiers)
local StatResolver = require(Shared.StatResolver)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local Combatant = require(script.Parent.Combatant)

local RaceRuntime = {}
local ActivateModifier = Net.remote("ActivateModifier")
local ReleaseBeast = Net.remote("ReleaseBeast")
local CombatEvent = Net.remote("CombatEvent")
local DamagedHook = Net.hook("PlayerDamaged")
local FormChanged = Net.hook("FormChanged")

type RS = {
	toggles: { [string]: number }, -- modId -> expires (math.huge = until toggled off)
	buffs: { [string]: number },
	zenkai: number, nearDeathAt: number?, rageUsed: boolean, beast: number, lastDamaged: number,
}
local rs: { [Player]: RS } = {}
local function S(p: Player): RS
	local s = rs[p]
	if not s then
		s = { toggles = {}, buffs = {}, zenkai = 0, nearDeathAt = nil, rageUsed = false, beast = 0, lastDamaged = -1e9 }
		rs[p] = s
	end
	return s :: RS
end
local function ranked(): boolean return workspace:GetAttribute("Ranked") == true end
local function humOf(p: Player): Humanoid? return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end

function RaceRuntime.raceId(p: Player): string return Races.raceOf(Combatant.activeCharacter(p)) end
function RaceRuntime.race(p: Player): any return Races.LIST[RaceRuntime.raceId(p)] end

local function activeIds(p: Player): { string }
	local s, now, out = S(p), os.clock(), {}
	for id, t in s.toggles do if t > now then table.insert(out, id) end end
	for id, t in s.buffs do if t > now then table.insert(out, id) end end
	return out
end

local function publish(p: Player)
	local s = S(p)
	p:SetAttribute("Race", RaceRuntime.raceId(p))
	p:SetAttribute("Modifiers", table.concat(activeIds(p), ","))
	p:SetAttribute("ZenkaiStacks", s.zenkai)
	p:SetAttribute("BeastMeter", math.floor(s.beast))
end

-- Resolved stats for combat (pure resolver + live context).
function RaceRuntime.stats(p: Player, kiFrac: number?): any
	local s = S(p)
	local mods = {}
	for _, id in activeIds(p) do table.insert(mods, { id = id }) end
	if s.zenkai > 0 then table.insert(mods, { id = "Zenkai", stacks = s.zenkai }) end
	local form = (p:GetAttribute("Form") :: string?) or "Base"
	if form == "UltraEgo" then table.insert(mods, { id = "UltraEgoGrowth" }) end
	if PlayerData.hasUnlock(p, "GodAura") then table.insert(mods, { id = "GodAura" }) end
	local h = humOf(p)
	local lost = if h and h.MaxHealth > 0 then 1 - h.Health / h.MaxHealth else 0
	local f = Config.FORMS[form]
	local r = StatResolver.resolve({
		charId = Combatant.activeCharacter(p), formMult = f and f.mult or 1, mods = mods, ranked = ranked(),
		hpLostFrac = lost, kiFrac = kiFrac, maxStatMult = Config.MAX_STAT_MULT, maxCombatMult = Config.MAX_COMBAT_MULT,
		paidCap = Config.PAID_STAT_CAP,
	})
	if #r.clamped > 0 and Config.DEV_MODE and RunService:IsStudio() then
		print(("[StatResolver] clamp %s: %s"):format(p.Name, table.concat(r.clamped, ",")))
	end
	return r
end

function RaceRuntime.isActive(p: Player, modId: string): boolean
	local s = S(p)
	return (s.toggles[modId] or 0) > os.clock() or (s.buffs[modId] or 0) > os.clock()
end

function RaceRuntime.addBuff(p: Player, modId: string, duration: number?)
	local m = Modifiers.LIST[modId]
	if not m then return end
	S(p).buffs[modId] = os.clock() + (duration or m.duration or 5)
	CombatEvent:FireAllClients("Modifier", { p.UserId, modId, true })
	publish(p)
end

local function deactivate(p: Player, modId: string)
	local s = S(p)
	if s.toggles[modId] then s.toggles[modId] = nil; CombatEvent:FireAllClients("Modifier", { p.UserId, modId, false }) end
	publish(p)
end

ActivateModifier.OnServerEvent:Connect(function(p, modId)
	if type(modId) ~= "string" or not RateLimit.allow(p, "mod", 2, 3) then return end
	if workspace:GetAttribute("RoundState") ~= "InRound" or p:GetAttribute("Alive") ~= true then return end
	local m = Modifiers.LIST[modId]
	if not m or m.kind ~= "toggle" then return end
	local s = S(p)
	if (s.toggles[modId] or 0) > os.clock() then deactivate(p, modId); return end -- toggle off
	if m.unlock and not PlayerData.hasUnlock(p, m.unlock) then return end
	local form = (p:GetAttribute("Form") :: string?) or "Base"
	local ok = Modifiers.canStack(modId, form, RaceRuntime.raceId(p), activeIds(p))
	if not ok then return end
	s.toggles[modId] = os.clock() + (m.duration or math.huge)
	CombatEvent:FireAllClients("Modifier", { p.UserId, modId, true })
	publish(p)
end)

ReleaseBeast.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "beast", 1, 2) or p:GetAttribute("Alive") ~= true then return end
	local s = S(p)
	if RaceRuntime.raceId(p) ~= "HalfSaiyan" or s.beast < 100 then return end
	s.beast = 0
	RaceRuntime.addBuff(p, "BeastRelease")
	p:SetAttribute("BeastReady", true) -- GDD: full meter also allows BeastGohan without the cinematic (client reads)
end)

-- Form change: drop modifiers that are no longer legal (e.g. SSB -> SSJ drops Blue Kaioken).
FormChanged.Event:Connect(function(p: Player, formId: string)
	local s = S(p)
	local keep = Modifiers.prune(formId, RaceRuntime.raceId(p), activeIds(p))
	for id in s.toggles do if not table.find(keep, id) then deactivate(p, id) end end
	publish(p)
end)

-- Damage taken: last-damaged time (regen gate), Zenkai near-death tracking, rage burst, beast meter.
DamagedHook.Event:Connect(function(vic: Player, _att: Player?, amount: number)
	if typeof(vic) ~= "Instance" or not vic:IsA("Player") then return end
	local s = S(vic)
	s.lastDamaged = os.clock()
	local h = humOf(vic)
	if not h or h.MaxHealth <= 0 then return end
	local frac = h.Health / h.MaxHealth
	local race = RaceRuntime.raceId(vic)
	if (race == "Saiyan" or race == "HalfSaiyan") and frac > 0 and frac <= Config.ZENKAI.nearDeath and not s.nearDeathAt then
		s.nearDeathAt = os.clock()
	end
	if race == "HalfSaiyan" and not s.rageUsed and frac > 0 and frac < Config.RAGE.hpBelow then
		s.rageUsed = true
		RaceRuntime.addBuff(vic, "RageBurst")
	end
	-- Beast meter: +1 per 1% max HP lost by self or an ally within range
	local lostPct = 100 * amount / h.MaxHealth
	local vr = vic.Character and vic.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, q in Players:GetPlayers() do
		if (q == vic or (q.Team == vic.Team and vic.Team ~= nil)) and RaceRuntime.raceId(q) == "HalfSaiyan" then
			local qr = q.Character and q.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if q == vic or (qr and vr and (qr.Position - vr.Position).Magnitude <= Config.BEAST.allyRange) then
				local qs = S(q)
				qs.beast = math.min(100, qs.beast + lostPct)
				qs.lastDamaged = math.max(qs.lastDamaged, if q == vic then os.clock() else qs.lastDamaged)
				publish(q)
			end
		end
	end
end)

-- Tick: HP drains (Kaioken), Namekian/Majin regen, Zenkai stack on survival, beast decay, expiry cleanup.
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	local step = acc
	acc = 0
	local now = os.clock()
	local inRound = workspace:GetAttribute("RoundState") == "InRound"
	for p, s in rs do
		if not p.Parent then continue end
		local h = humOf(p)
		local alive = p:GetAttribute("Alive") == true and h ~= nil and h.Health > 0
		if alive and inRound and h then
			local race = RaceRuntime.race(p)
			local st = RaceRuntime.stats(p)
			if st.hpDrainPerSec > 0 then h.Health = math.max(1, h.Health - h.MaxHealth * st.hpDrainPerSec * step) end -- drains never KO
			if race.regenPerSec and now - s.lastDamaged >= (race.regenDelay or 4) and not RaceRuntime.isActive(p, "GiantForm") then
				h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * race.regenPerSec * step)
			end
			if s.nearDeathAt and now - s.nearDeathAt >= Config.ZENKAI.surviveSeconds then
				s.nearDeathAt = nil
				if s.zenkai < Config.ZENKAI.maxStacks then s.zenkai += 1; CombatEvent:FireAllClients("Zenkai", { p.UserId, s.zenkai }) end
			end
			if now - s.lastDamaged > Config.BEAST.outOfCombat and s.beast > 0 then s.beast = math.max(0, s.beast - Config.BEAST.decayPerSec * step) end
		end
		local changed = false
		for id, t in s.toggles do if t <= now then s.toggles[id] = nil; changed = true end end
		for id, t in s.buffs do if t <= now then s.buffs[id] = nil; changed = true end end
		if changed then publish(p) end
	end
end)

-- Combat callback when ki runs out: toggles with ki drain switch off.
function RaceRuntime.onKiEmpty(p: Player)
	for id in S(p).toggles do
		local m = Modifiers.LIST[id]
		if m and m.kiDrainPerSec > 0 then deactivate(p, id) end
	end
end

Net.hook("CharacterPicked").Event:Connect(function(p: Player) if typeof(p) == "Instance" then publish(p) end end)

function RaceRuntime.resetPlayer(p: Player) rs[p] = nil; publish(p) end
function RaceRuntime.resetRound() for _, p in Players:GetPlayers() do RaceRuntime.resetPlayer(p) end end
Players.PlayerRemoving:Connect(function(p) rs[p] = nil end)

return RaceRuntime
