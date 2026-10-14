--!strict
-- ModuleScript: ReplicatedStorage.Shared.StatResolver  (PURE: no Roblox APIs; tests in gameplay/tests)
-- finalMult = race x form x product(modifiers) x buffs, then clamp per mode.            (TASK_RACES stacking rule 1)
-- Paid boosts are a separate factor capped at PAID_CAP (1.35) total.                      (rule 2)
-- Ranked: paid ignored; race/form/modifier STAT multipliers normalized to 1 (utility kept). (rule 3)
-- Hard global cap MAX_STAT_MULT; clamps are reported (caller logs in DEV_MODE).             (rule 4)
-- "combat" excludes the form (forms already live in Power Level) and paid (also in Power Level), so Combat can
-- multiply PL-ratio x combat.damage/defense and compress once with STAT_CAP -- no double counting.
local function dep(name: string): any
	local s = (script :: any) -- nil under the luau CLI (tests)
	if s then return require(s.Parent:FindFirstChild(name) :: any) end
	return (require :: any)("./" .. name)
end
local Races = dep("Races")
local Modifiers = dep("Modifiers")

local StatResolver = {}
StatResolver.PAID_CAP = 1.35
StatResolver.MAX_STAT_MULT = 8 -- display/total hard cap (MUI 6 x race 1.05 x Kaioken... never beyond)
StatResolver.MAX_COMBAT_MULT = 1.6 -- race x modifiers x buffs before combat compression

export type ActiveMod = { id: string, stacks: number? }
export type Ctx = {
	race: string?, charId: string?, formMult: number?, mods: { ActiveMod }?, paid: number?,
	ranked: boolean?, hpLostFrac: number?, kiFrac: number?,
	paidCap: number?, maxStatMult: number?, maxCombatMult: number?,
}
export type Stats = { damage: number, defense: number, speed: number, kiRegen: number }
export type Result = {
	total: Stats, combat: Stats, paid: number, kiDrainPerSec: number, hpDrainPerSec: number,
	infiniteKi: boolean, clamped: { string },
}

local KEYS = { "damage", "defense", "speed", "kiRegen" }
local function one(): Stats return { damage = 1, defense = 1, speed = 1, kiRegen = 1 } end

function StatResolver.resolve(ctx: Ctx): Result
	local raceId = ctx.race or Races.raceOf(ctx.charId)
	local race = Races.LIST[raceId] or Races.LIST.Earthling
	local ranked = ctx.ranked == true
	local clamped = {}
	local combat = one()
	local kiDrain, hpDrain = 0, 0
	local paid = 1
	-- race
	if not ranked then for _, k in KEYS do (combat :: any)[k] *= (race.stats :: any)[k] end end
	-- modifiers & buffs
	for _, am in (ctx.mods or {}) do
		local m = Modifiers.LIST[am.id]
		if m then
			kiDrain += m.kiDrainPerSec
			hpDrain += m.hpDrainPerSec
			if m.paid then
				for _, k in KEYS do local v = (m.stats :: any)[k]; if v then paid *= v end end -- paid bucket (damage-only boosts)
			elseif not ranked then
				for _, k in KEYS do local v = (m.stats :: any)[k]; if v then (combat :: any)[k] *= v end end
				if m.id == "Zenkai" then
					local n = math.min(am.stacks or 1, m.maxStacks or 1)
					combat.damage *= 1 + n * (m.perStack or 0); combat.defense *= 1 + n * (m.perStack or 0)
				elseif m.id == "UltraEgoGrowth" then
					local lost = math.clamp(ctx.hpLostFrac or 0, 0, 1)
					combat.damage *= 1 + math.min(m.cap or 0.4, lost * (m.perStack or 0.5))
				elseif m.id == "GodAura" and (ctx.kiFrac or 1) <= 0.5 then
					combat.defense /= (m.stats.defense or 1) -- only while ki > 50%
				end
			end
		end
	end
	paid *= ctx.paid or 1
	local pcap = ctx.paidCap or StatResolver.PAID_CAP
	if paid > pcap then paid = pcap; table.insert(clamped, "paid") end
	if paid < 1 then paid = 1 end
	if ranked then paid = 1 end
	local ccap = ctx.maxCombatMult or StatResolver.MAX_COMBAT_MULT
	for _, k in KEYS do
		local v = (combat :: any)[k]
		if v > ccap then (combat :: any)[k] = ccap; table.insert(clamped, "combat." .. k)
		elseif v < 1 / ccap then (combat :: any)[k] = 1 / ccap; table.insert(clamped, "combat." .. k) end
	end
	local total = one()
	local form = if ranked then 1 else (ctx.formMult or 1)
	local maxT = ctx.maxStatMult or StatResolver.MAX_STAT_MULT
	for _, k in KEYS do
		local v = (combat :: any)[k] * (if k == "damage" or k == "defense" then form * paid else 1)
		if v > maxT then v = maxT; table.insert(clamped, "total." .. k) end
		(total :: any)[k] = v
	end
	return {
		total = total, combat = combat, paid = paid,
		kiDrainPerSec = if race.ki == "infinite" then 0 else kiDrain,
		hpDrainPerSec = hpDrain, infiniteKi = race.ki == "infinite", clamped = clamped,
	}
end

-- Combat damage factor: PL ratio x attacker damage / victim defense, compressed once to [1/cap, cap].
function StatResolver.combatRatio(plRatio: number, att: Result?, vic: Result?, cap: number): number
	local r = plRatio * (if att then att.combat.damage else 1) / (if vic then vic.combat.defense else 1)
	return math.clamp(r, 1 / cap, cap)
end

return StatResolver
