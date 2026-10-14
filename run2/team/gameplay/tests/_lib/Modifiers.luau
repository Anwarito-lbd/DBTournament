--!strict
-- ModuleScript: ReplicatedStorage.Shared.Modifiers  (pure data + stacking validation; unit-testable)
-- Modifier = { id, stats (multipliers), kiDrainPerSec, hpDrainPerSec (fraction of max HP), allowedBaseForms,
--              group (only one active per group), kind = "toggle" | "buff" | "passive", dynamic? }
-- Stacking rules (TASK_RACES.md + GDD §3.1):
--  * Kaioken stacks only on Base and Super Saiyan Blue (Blue Kaioken); never on SSJ1-3/God/UI/etc.
--  * Ultra Ego growth only in the UltraEgo form; Beast release only for HalfSaiyan.
--  * Android infinite ki is a RACE flag, never a modifier.
--  * Energy drink / Zenkai / rage are temporary buffs (Energy drink is the PAID bucket: StatResolver caps it).
local Modifiers = {}

export type Mod = {
	id: string, kind: string, group: string?,
	stats: { damage: number?, defense: number?, speed: number?, kiRegen: number? },
	kiDrainPerSec: number, hpDrainPerSec: number,
	allowedBaseForms: { string }?, races: { string }?, unlock: string?,
	duration: number?, maxStacks: number?, perStack: number?, cap: number?, paid: boolean?, desc: string,
}
local function M(t: any): Mod
	t.kiDrainPerSec = t.kiDrainPerSec or 0
	t.hpDrainPerSec = t.hpDrainPerSec or 0
	t.stats = t.stats or {}
	return t :: Mod
end

local KAIOKEN_FORMS = { "Base", "SuperSaiyanBlue" }
Modifiers.LIST = {
	-- Kaioken levels (toggle, group Kaioken). Blue Kaioken x10 = SSB form x Kaioken_x10 (+15%), heavy HP drain.
	Kaioken_x2 = M{ id = "Kaioken_x2", kind = "toggle", group = "Kaioken", unlock = "KaioKen", allowedBaseForms = KAIOKEN_FORMS,
		stats = { damage = 1.05, speed = 1.05 }, kiDrainPerSec = 2, hpDrainPerSec = 0.0025, desc = "Kaioken x2" },
	Kaioken_x3 = M{ id = "Kaioken_x3", kind = "toggle", group = "Kaioken", unlock = "KaioKen", allowedBaseForms = KAIOKEN_FORMS,
		stats = { damage = 1.08, speed = 1.06 }, kiDrainPerSec = 2.5, hpDrainPerSec = 0.004, desc = "Kaioken x3" },
	Kaioken_x4 = M{ id = "Kaioken_x4", kind = "toggle", group = "Kaioken", unlock = "KaioKen", allowedBaseForms = KAIOKEN_FORMS,
		stats = { damage = 1.10, speed = 1.08 }, kiDrainPerSec = 3, hpDrainPerSec = 0.005, desc = "Kaioken x4" },
	Kaioken_x10 = M{ id = "Kaioken_x10", kind = "toggle", group = "Kaioken", unlock = "KaioKen", allowedBaseForms = KAIOKEN_FORMS,
		stats = { damage = 1.15, speed = 1.10 }, kiDrainPerSec = 4, hpDrainPerSec = 0.01, desc = "Kaioken x10 (Blue Kaioken)" },
	Kaioken_x20 = M{ id = "Kaioken_x20", kind = "toggle", group = "Kaioken", unlock = "KaioKen", allowedBaseForms = KAIOKEN_FORMS,
		stats = { damage = 1.25, speed = 1.12 }, kiDrainPerSec = 6, hpDrainPerSec = 0.02, desc = "Kaioken x20" },
	-- Ultra Ego: +1% damage per 2% HP lost (cap +40%), defense x0.85. Dynamic: StatResolver reads ctx.hpLostFrac.
	UltraEgoGrowth = M{ id = "UltraEgoGrowth", kind = "passive", group = "FormPassive", allowedBaseForms = { "UltraEgo" },
		stats = { defense = 0.85 }, perStack = 0.5, cap = 0.40, desc = "Ultra Ego: damage grows with damage taken" },
	-- Beast release: meter 100 -> 6 s burst (+20% damage); meter mechanics live in RaceRuntime.
	BeastRelease = M{ id = "BeastRelease", kind = "buff", group = "Rage", races = { "HalfSaiyan" }, duration = 6,
		stats = { damage = 1.20 }, desc = "Beast rage release" },
	RageBurst = M{ id = "RageBurst", kind = "buff", group = "Rage", races = { "HalfSaiyan" }, duration = 8,
		stats = { damage = 1.15, speed = 1.05 }, desc = "Hidden potential: rage burst at <25% HP" },
	Zenkai = M{ id = "Zenkai", kind = "buff", races = { "Saiyan", "HalfSaiyan" }, maxStacks = 5, perStack = 0.02,
		stats = {}, desc = "Zenkai: +2% damage/defense per stack, max 5 (+10%) per match" },
	GiantForm = M{ id = "GiantForm", kind = "toggle", group = "Giant", races = { "Namekian" }, unlock = "GiantForm", duration = 10,
		allowedBaseForms = { "Base" }, stats = { speed = 0.8, defense = 1.05 }, kiDrainPerSec = 3, desc = "Giant form: hurtbox x1.6, knockback dealt x1.3" },
	JusticeBuff = M{ id = "JusticeBuff", kind = "buff", group = "Justice", duration = 5, stats = { damage = 1.05, defense = 1.05 },
		desc = "Justice Pose: +5% damage/defense for 5 s (team, Pride Trooper)" },
	GodAura = M{ id = "GodAura", kind = "passive", unlock = "GodAura", stats = { defense = 1.05 }, desc = "God aura: +5% defense while ki > 50%" },
	LastStand = M{ id = "LastStand", kind = "buff", paid = true, duration = 9999, stats = { damage = 1.12 },
		desc = "ToP comeback: last fighter of a universe. Paid bucket => capped with paid boosts at 1.35x; Ranked = off" },
	EnergyDrink = M{ id = "EnergyDrink", kind = "buff", paid = true, duration = 8, stats = { damage = 1.10 }, desc = "Dragon Block Z energy drink (paid bucket)" },
} :: { [string]: Mod }

-- Can `modId` be activated given current form, race and already-active ids? Returns ok, reason.
function Modifiers.canStack(modId: string, form: string, race: string, active: { string }): (boolean, string?)
	local m = Modifiers.LIST[modId]
	if not m then return false, "Unknown" end
	if race == "Android" and m.kind == "toggle" and m.group == "Kaioken" then return false, "AndroidNoKaioken" end
	if m.allowedBaseForms and not table.find(m.allowedBaseForms, form) then return false, "FormNotAllowed" end
	if m.races and not table.find(m.races, race) then return false, "RaceNotAllowed" end
	for _, a in active do
		local o = Modifiers.LIST[a]
		if a == modId and not m.maxStacks then return false, "AlreadyActive" end
		if o and m.group and o.group == m.group and a ~= modId then return false, "GroupConflict" end
	end
	return true, nil
end

-- Remove modifiers that became illegal after a form change (e.g. SSB -> SSJ drops Kaioken).
function Modifiers.prune(form: string, race: string, active: { string }): { string }
	local keep = {}
	for _, a in active do
		local m = Modifiers.LIST[a]
		if m and (not m.allowedBaseForms or table.find(m.allowedBaseForms, form)) and (not m.races or table.find(m.races, race)) then
			table.insert(keep, a)
		end
	end
	return keep
end

return Modifiers
