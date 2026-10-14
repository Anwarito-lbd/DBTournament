--!strict
-- ModuleScript: ServerScriptService.Modules.Combatant
-- Character picks (any unlocked champion; one per team; team power budget; divine caps), forms, ki charge, Power Level.
-- Remotes (client -> server): PickCharacter(charId), KiCharge(isCharging: boolean), Transform(formId)
-- Replicated attributes: Character, Form, KiCharge (0..cap), Charging, PowerLevel, GiftBoost, Fused
-- v3: divine guest picks (capped per match / event-only), last-gift boost, fusion character override.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ToPLogic = require(game:GetService("ReplicatedStorage").Shared.ToPLogic)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local AvatarSlots = require(script.Parent.AvatarSlots)
local PlayerData = require(script.Parent.PlayerData)
local TeamAssignment = require(script.Parent.TeamAssignment)
local Races = require(game:GetService("ReplicatedStorage").Shared.Races)
local QuestService = require(script.Parent.QuestService)

local Combatant = {}

local PickCharacter = Net.remote("PickCharacter")
local KiCharge = Net.remote("KiCharge")
local Transform = Net.remote("Transform")
local CharacterPicked = Net.hook("CharacterPicked") -- (player, charId) for db-animation to swap rig
local FormChanged = Net.hook("FormChanged") -- (player, formId)
local PlayVFX = Net.remote("PlayVFX")
local PickResult = Net.remote("PickResult") -- (ok, charId, reason?) reasons: Invalid, Locked, NoTeam, TakenByTeammate, DivineCap, OverBudget -- db-animation flow: ("Transform", character, presetName)

type State = {
	char: string?, form: string, charge: number, charging: boolean, lastForm: number,
	gift: number, giftUntil: number, fusion: string?, absorb: number, absorbUntil: number, drink: number, drinkUntil: number,
}
local states: { [Player]: State } = {}
local DEFAULT_BASE = 800

local function st(p: Player): State
	local s = states[p]
	if not s then
		s = { char = nil, form = "Base", charge = 0, charging = false, lastForm = 0, gift = 0, giftUntil = 0, fusion = nil, absorb = 0, absorbUntil = 0, drink = 0, drinkUntil = 0 }
		states[p] = s
	end
	return s :: State
end

local function roundState(): string
	return (workspace:GetAttribute("RoundState") :: string?) or "Waiting"
end

local function activeChar(s: State): string?
	return s.fusion or s.char
end

local function giftOf(s: State): number
	return if s.giftUntil > os.clock() then s.gift else 0
end

function Combatant.powerLevel(p: Player, includeCharge: boolean?): number
	local s = st(p)
	local id = activeChar(s)
	local ch = id and Config.CHAR_BY_ID[id]
	local base = if ch then ch.base else DEFAULT_BASE
	local form = Config.FORMS[s.form] or Config.FORMS.Base
	local charge = if includeCharge == false then 0 else s.charge
	local gift = if includeCharge == false then 0 else giftOf(s) + (if s.absorbUntil > os.clock() then s.absorb else 0)
	if workspace:GetAttribute("Ranked") == true then return Config.RANKED.power end -- skill only
	local wish = 1 -- v9: the Power stat wish was removed (cosmetic/Zeni ending); kept as a neutral factor
	-- Paid power cap: paid multiplier = (paid champion base / earned best base) * (paid form / earned best form)
	-- * (1 + drink boost), clamped to PAID_STAT_CAP; earned parts are uncapped (still compressed in combat).
	local level = PlayerData.getLevel(p)
	local formMult = form.mult
	local earnedBase, earnedForm = base, formMult
	local paid = 1
	if ch and not (ch :: any).tier and PlayerData.isPaidUnlock(p, ch.id, ch.level) then
		earnedBase = Combatant.earnedBestBase(level)
		paid *= math.max(1, base / earnedBase)
	end
	if s.form ~= "Base" and Config.FORMS[s.form] and PlayerData.isPaidUnlock(p, s.form, Config.FORMS[s.form].level) then
		earnedForm = Combatant.earnedBestForm(ch, level)
		paid *= math.max(1, formMult / earnedForm)
	end
	if includeCharge ~= false and s.drinkUntil > os.clock() then paid *= 1 + s.drink end
	paid = math.min(paid, Config.PAID_STAT_CAP)
	local core = (math.min(base, earnedBase) + level * Config.POWER_PER_LEVEL) * math.min(formMult, earnedForm)
	return math.floor(core * paid * (1 + charge + gift) * wish)
end

-- Highest base among champions earnable at this level / best form multiplier earned for a champion.
local baseCache: { [number]: number } = {}
function Combatant.earnedBestBase(level: number): number
	local c = baseCache[level]
	if c then return c end
	local best = DEFAULT_BASE
	for _, ch in Config.CHAR_BY_ID do
		local x = ch :: any
		if not x.fused and not x.tier and ch.level <= level and ch.base > best then best = ch.base end
	end
	baseCache[level] = best
	return best
end
function Combatant.earnedBestForm(ch: any, level: number): number
	local best = 1
	if ch then
		for _, fid in ch.forms do
			local f = Config.FORMS[fid]
			if f and f.level <= level and f.mult > best then best = f.mult end
		end
	end
	return best
end

-- Energy drink power boost (paid bucket).
function Combatant.addDrinkBoost(p: Player, amount: number, duration: number)
	local s = st(p)
	s.drink = amount
	s.drinkUntil = os.clock() + duration
end

-- Balancing uses Power Level without temporary charge/form.
function Combatant.balancePower(p: Player): number
	local s = st(p)
	local ch = s.char and Config.CHAR_BY_ID[s.char]
	local base = if ch then ch.base else DEFAULT_BASE
	return base + PlayerData.getLevel(p) * Config.POWER_PER_LEVEL
end

local function publish(p: Player)
	local s = st(p)
	p:SetAttribute("Character", activeChar(s))
	p:SetAttribute("GiftBoost", giftOf(s))
	p:SetAttribute("Fused", s.fusion)
	p:SetAttribute("Form", s.form)
	p:SetAttribute("KiCharge", math.floor(s.charge * 100 + 0.5) / 100)
	p:SetAttribute("Charging", s.charging)
	p:SetAttribute("PowerLevel", Combatant.powerLevel(p))
	local tier = Config.tierOf(Config.CHAR_BY_ID[activeChar(s) or ""] or { base = 0 })
	p:SetAttribute("Tier", tier)
	p:SetAttribute("HurtboxScale", Config.TIER_RULES[tier].hurtbox) -- db-animation may scale the rig to match
end

-- Divine guest-pick accounting (reset each round).
local function isEventMode(): boolean
	return workspace:GetAttribute("EventMode") == true
end

local function divineCount(filter: (Player, any) -> boolean): number
	local n = 0
	for q, qs in states do
		local id = qs.char
		local ch = id and Config.CHAR_BY_ID[id] :: any
		if ch and ch.tier and q.Parent and q:GetAttribute("Alive") == true and filter(q, ch) then n += 1 end
	end
	return n
end

-- ===== v4 picks: any unlocked champion, one per team, team power budget =====
local function teammates(p: Player): { Player }
	local out = {}
	local team = p.Team
	if not team then return out end
	for q in states do
		if q ~= p and q.Parent and q.Team == team and q:GetAttribute("Alive") == true then table.insert(out, q) end
	end
	return out
end

function Combatant.tierOf(charId: string?): string
	local ch = charId and Config.CHAR_BY_ID[charId]
	return if ch then Config.tierOf(ch) else "C"
end

function Combatant.tierRules(p: Player)
	if workspace:GetAttribute("Ranked") == true then return Config.TIER_RULES.C end -- Ranked: normalized
	return Config.TIER_RULES[Combatant.tierOf(activeChar(st(p)))]
end

function Combatant.teamBudget(team: Team): number
	return Config.BUDGET_PER_PLAYER * #team:GetPlayers() + Config.BUDGET_BONUS
end

local function budgetUsedExcept(p: Player): number
	local used = 0
	for _, q in teammates(p) do
		local id = st(q).char
		if id then used += Config.TIER_RULES[Combatant.tierOf(id)].cost end
	end
	return used
end

function Combatant.canPickDivine(p: Player, ch: any): boolean
	local tier = Config.DIVINE_TIERS[ch.tier]
	if tier.eventOnly and not isEventMode() then return false end
	local others = function(q: Player) return q ~= p end
	if divineCount(function(q, c2) return others(q) and c2.tier == ch.tier end) >= tier.perMatch then return false end
	local team = p.Team
	if divineCount(function(q) return others(q) and q.Team == team end) >= Config.DIVINE_PER_TEAM then return false end
	if not isEventMode() and divineCount(others) >= Config.DIVINE_TOTAL_PER_MATCH then return false end
	return true
end

-- Returns ok, reason. Rules: exists & not fusion-only, unlocked, assigned to a team, not already taken by a
-- teammate (first come first served), fits the team power budget (skipped in EventMode), divine caps/modes.
function Combatant.checkPick(p: Player, charId: string): (boolean, string?)
	local ch = Config.CHAR_BY_ID[charId] :: any
	if not ch or ch.fused then return false, "Invalid" end
	if not Races.isPlayable(charId, Config.FEATURES) then return false, "NPCOnly" end -- Angels NPC-only at launch
	if not PlayerData.hasUnlock(p, charId) then return false, "Locked" end
	if TeamAssignment.universeOf(p) == nil then return false, "NoTeam" end
	if Config.ONE_PER_TEAM then
		for _, q in teammates(p) do
			if st(q).char == charId then return false, "TakenByTeammate" end
		end
	end
	if ch.tier and workspace:GetAttribute("Ranked") == true and not Config.RANKED.allowDivine then return false, "RankedBanned" end
	if ch.tier and not Combatant.canPickDivine(p, ch) then return false, "DivineCap" end
	if not isEventMode() then
		local cost = Config.TIER_RULES[Config.tierOf(ch)].cost
		if budgetUsedExcept(p) + cost > Combatant.teamBudget(p.Team :: Team) then return false, "OverBudget" end
	end
	return true, nil
end

function Combatant.canPick(p: Player, charId: string): boolean
	return (Combatant.checkPick(p, charId))
end

local function publishTeam(team: Team?)
	if not team or not team.Parent then return end
	local used, picks = 0, {}
	for q, qs in states do
		if q.Parent and q.Team == team and q:GetAttribute("Alive") == true and qs.char then
			used += Config.TIER_RULES[Combatant.tierOf(qs.char)].cost
			table.insert(picks, qs.char)
		end
	end
	team:SetAttribute("BudgetUsed", used)
	team:SetAttribute("Budget", Combatant.teamBudget(team))
	team:SetAttribute("Picks", table.concat(picks, ",")) -- UI greys these out (one per team)
end
Combatant.publishTeam = publishTeam

function Combatant.setCharacter(p: Player, charId: string)
	local s = st(p)
	s.char = charId
	s.form = "Base"
	publish(p)
	publishTeam(p.Team)
	CharacterPicked:Fire(p, charId)
	task.defer(AvatarSlots.apply, p, charId) -- Blender champion model if ReplicatedStorage.CharacterModels[charId] exists
end

-- Fallback: keep current pick if still valid, else first valid of DEFAULT_PICKS, else cheapest valid unlocked.
function Combatant.ensureValidPick(p: Player)
	local s = st(p)
	if s.char and Combatant.canPick(p, s.char) then publishTeam(p.Team); return end
	for _, id in Config.DEFAULT_PICKS do
		if Combatant.canPick(p, id) then Combatant.setCharacter(p, id); return end
	end
	local all = {}
	for id, ch in Config.CHAR_BY_ID do
		if not (ch :: any).fused then table.insert(all, id) end
	end
	table.sort(all, function(a, b)
		local ca, cb = Config.TIER_RULES[Combatant.tierOf(a)].cost, Config.TIER_RULES[Combatant.tierOf(b)].cost
		return if ca == cb then a < b else ca < cb
	end)
	for _, id in all do
		if Combatant.canPick(p, id) then Combatant.setCharacter(p, id); return end
	end
	s.char = nil -- nothing valid (should not happen: 25+ level-1 champions)
	publish(p)
end

function Combatant.resetCombat(p: Player)
	local s = st(p)
	s.form = "Base"; s.charge = 0; s.charging = false
	s.gift = 0; s.giftUntil = 0; s.fusion = nil; s.absorb = 0; s.absorbUntil = 0
	publish(p)
end

PickCharacter.OnServerEvent:Connect(function(p, charId)
	if type(charId) ~= "string" or not RateLimit.allow(p, "pick", 3, 5) then return end
	charId = Config.ALIASES[charId] or charId
	local rs = roundState()
	if rs ~= "CharacterSelect" and rs ~= "Countdown" then return end
	if p:GetAttribute("Alive") ~= true then return end
	local ok, why = Combatant.checkPick(p, charId)
	if not ok then PickResult:FireClient(p, false, charId, why); return end
	Combatant.setCharacter(p, charId)
	PickResult:FireClient(p, true, charId, nil)
end)

local function isStill(p: Player): boolean
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not root or hum.Health <= 0 then return false end
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude <= Config.KI_MAX_CHARGE_SPEED
end

KiCharge.OnServerEvent:Connect(function(p, on)
	if type(on) ~= "boolean" or not RateLimit.allow(p, "ki", 4, 8) then return end
	local s = st(p)
	s.charging = on and isStill(p) and Races.get(activeChar(s)).canCharge -- Android: cannot charge
	publish(p)
end)

Transform.OnServerEvent:Connect(function(p, formId)
	if type(formId) ~= "string" or not RateLimit.allow(p, "form", 1, 3) then return end
	formId = Config.ALIASES[formId] or formId
	if roundState() ~= "InRound" or p:GetAttribute("Alive") ~= true then return end
	local s = st(p)
	local id = activeChar(s)
	local ch = id and Config.CHAR_BY_ID[id]
	if ch and formId == "Next" then -- D21: X / D-pad up cycles to the next unlocked form (Base after the top one)
		formId = ToPLogic.nextForm(ch.forms, s.form, function(fid) return PlayerData.hasUnlock(p, fid) end)
		if formId == s.form then return end
	end
	if not ch or not Config.FORMS[formId] then return end
	if formId ~= "Base" then
		if not table.find(ch.forms, formId) or not PlayerData.hasUnlock(p, formId) then return end
	end
	if formId ~= "Base" and not Races.get(id).canTransform then return end -- Android/Angel/Destroyer/Kaioshin
	if os.clock() - s.lastForm < Config.TRANSFORM_COOLDOWN then return end
	s.lastForm = os.clock()
	s.form = formId
	publish(p)
	FormChanged:Fire(p, formId)
	if formId ~= "Base" then QuestService.track(p, "transform", 1) end
	local preset = Config.vfxFor(id, formId)
	if preset and p.Character then PlayVFX:FireAllClients("Transform", p.Character, preset) end
	if p.Character then task.defer(AvatarSlots.applyForm, p.Character, id, formId) end
end)

-- Last energy gift: add a temporary Power Level boost (fraction) to a teammate.
function Combatant.giveGift(from: Player, to: Player)
	local cfg = Config.LAST_GIFT
	local fs, ts = st(from), st(to)
	local amount = math.min(cfg.maxBoost, cfg.boost + fs.charge * cfg.chargeShare)
	ts.gift = math.min(cfg.maxBoost, giftOf(ts) + amount)
	ts.giftUntil = os.clock() + cfg.duration
	ts.charge = math.min(Config.KI_CHARGE_CAP, ts.charge + fs.charge * cfg.chargeShare)
	fs.charge = 0
	publish(from); publish(to)
end

-- Moro absorption: stacking temporary PL boost, capped.
function Combatant.addAbsorb(p: Player, amount: number)
	local s = st(p)
	local cur = if s.absorbUntil > os.clock() then s.absorb else 0
	s.absorb = math.min(Config.MORO.plCap, cur + amount)
	s.absorbUntil = os.clock() + Config.MORO.plDuration
	publish(p)
end

function Combatant.getCharge(p: Player): number return st(p).charge end
function Combatant.activeCharacter(p: Player): string? return activeChar(st(p)) end
function Combatant.isStill(p: Player): boolean return isStill(p) end

-- Fusion override (nil to defuse). Resets form; keeps underlying pick for restore.
function Combatant.setFusion(p: Player, fusionId: string?)
	local s = st(p)
	s.fusion = fusionId
	s.form = "Base"
	publish(p)
	CharacterPicked:Fire(p, fusionId or s.char)
	local preset = fusionId and Config.vfxFor(fusionId, "Fuse")
	if preset and p.Character then PlayVFX:FireAllClients("Transform", p.Character, preset) end
end

-- Server tick: charge/decay with cap, cancel charging if moving/dead.
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 then return end
	local step = acc
	acc = 0
	for p, s in states do
		if p.Parent then
			local before = s.charge
			if s.charging and not isStill(p) then s.charging = false end
			if s.charging then
				s.charge = math.min(Config.KI_CHARGE_CAP, s.charge + Config.KI_CHARGE_RATE * step)
			else
				s.charge = math.max(0, s.charge - Config.KI_DECAY_RATE * step)
			end
			if s.charge ~= before or p:GetAttribute("Charging") ~= s.charging
				or (s.giftUntil > 0 and s.giftUntil <= os.clock()) then
				if s.giftUntil > 0 and s.giftUntil <= os.clock() then s.gift = 0; s.giftUntil = 0 end
				publish(p)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(p)
	st(p)
	p:GetAttributeChangedSignal("Level"):Connect(function() publish(p) end)
	p.CharacterAdded:Connect(function() local s = st(p); s.charging = false; s.charge = 0; s.form = "Base"; publish(p) end)
end)
for _, p in Players:GetPlayers() do st(p) end
Players.PlayerRemoving:Connect(function(p) states[p] = nil end)

return Combatant
