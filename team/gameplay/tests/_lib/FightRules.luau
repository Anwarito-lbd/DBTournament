--!strict
-- ModuleScript: ReplicatedStorage.Shared.FightRules
-- Pure rules for the fight-research design gaps (team/gameplay/FIGHT_RESEARCH.md section 4). No Roblox services, so
-- tests/fight_rules_tests.luau runs them in plain Luau. Modules/Combat applies them; numbers live in Config.SKILL.
--   * 4th-hit branches: the 4th M1 of a chain becomes a finisher: blow-away (knockdown), launch (up) or spike (down).
--   * knockdown and get-up immunity: hits on a downed fighter, and for a moment after they stand, do no knockback or
--     stun, so nobody can be looped.
--   * perfect-block reward: a parry primes a Ki Burst; a second parry while primed is a Vanish Counter.
--   * anti-team burst: being hit by enough different attackers in a short window unlocks a free burst.
local FightRules = {}

-- the M1 chain step for a new press: continues within `window` seconds of the previous press, wraps after 4
function FightRules.nextM1Step(prevStep: number?, lastT: number?, now: number, window: number): number
	if not prevStep or not lastT or now - lastT > window then
		return 1
	end
	return (prevStep % 4) + 1
end

-- which finisher the 4th hit becomes. The client hints "up" (jump held on the ground) or "down" (airborne); the server
-- only honours a hint that matches where the attacker actually is, otherwise it is the neutral blow-away.
function FightRules.finisher(hint: any, airborne: boolean): string
	if hint == "down" and airborne then
		return "spike"
	elseif hint == "up" and not airborne then
		return "launch"
	end
	return "blow"
end

-- a copy of the M1 move turned into the given finisher, using the Config.SKILL.Finisher tuning table
function FightRules.applyFinisher(mv: { [string]: any }, kind: string, tuning: { [string]: { [string]: any } }): { [string]: any }
	local t = tuning[kind] or tuning.blow
	local out = table.clone(mv)
	out.damage = (mv.damage or 0) * (t.damageMult or 1)
	out.kb = t.kb or mv.kb
	out.finisher = kind
	out.knockdown = t.knockdown -- seconds down, or nil
	out.up = t.up -- launch: upward speed
	out.down = t.down -- spike: downward speed
	out.hitstun = t.hitstun or mv.hitstun
	out.recovery = t.recovery or mv.recovery
	out.crackRadius = t.crackRadius
	out.crackPower = t.crackPower
	return out
end

-- true while the fighter is down, and for `immunity` seconds after getting up: no knockback / stun extension then
function FightRules.isProtected(knockdownUntil: number?, now: number, immunity: number): boolean
	return knockdownUntil ~= nil and knockdownUntil > 0 and now < knockdownUntil + immunity
end

-- perfect-block reward after a parry: "prime" (next hit is a Ki Burst) or "vanish" (already primed: vanish counter)
function FightRules.parryReward(kiBurstUntil: number?, now: number): string
	if kiBurstUntil and kiBurstUntil > now then
		return "vanish"
	end
	return "prime"
end

-- anti-team burst: recentHits maps attacker id -> last hit time. Ready when at least `needed` different attackers hit
-- within `window` seconds and the burst is off cooldown.
function FightRules.teamBurstReady(
	recentHits: { [any]: number },
	now: number,
	window: number,
	needed: number,
	lastBurst: number?,
	cooldown: number
): boolean
	if lastBurst and now - lastBurst < cooldown then
		return false
	end
	local n = 0
	for _, t in recentHits do
		if now - t <= window then
			n += 1
		end
	end
	return n >= needed
end

return FightRules
