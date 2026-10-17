-- Plain-Luau tests for Shared/FightRules (copied to _lib by run.sh).
local R = require("./_lib/FightRules")

local passed, failed = 0, 0
local function check(name: string, cond: boolean)
	if cond then
		passed += 1
	else
		failed += 1
		print("FAIL " .. name)
	end
end

-- M1 chain
check("first press is step 1", R.nextM1Step(nil, nil, 10, 1.25) == 1)
check("chain continues", R.nextM1Step(1, 10, 10.5, 1.25) == 2)
check("4th then wraps to 1", R.nextM1Step(4, 10, 10.5, 1.25) == 1)
check("chain resets after the window", R.nextM1Step(3, 10, 11.3, 1.25) == 1)

-- finisher hints are only honoured when they match the attacker's position
check("neutral is blow", R.finisher(nil, false) == "blow")
check("up on the ground launches", R.finisher("up", false) == "launch")
check("up in the air is not a launch", R.finisher("up", true) == "blow")
check("down in the air spikes", R.finisher("down", true) == "spike")
check("down on the ground is not a spike", R.finisher("down", false) == "blow")
check("junk hint is blow", R.finisher(42, true) == "blow")

local tuning = {
	blow = { damageMult = 1.2, kb = 55, knockdown = 2 },
	launch = { damageMult = 1.1, kb = 10, up = 75, hitstun = 0.9 },
	spike = { damageMult = 1.25, kb = 6, down = 60, knockdown = 1.6, crackRadius = 9, crackPower = 60 },
}
local m1 = { kind = "melee", damage = 5, kb = 8, hitstun = 0.35, recovery = 0.1 }
local blow = R.applyFinisher(m1, "blow", tuning)
check("blow scales damage", math.abs(blow.damage - 6) < 1e-6)
check("blow knocks down", blow.knockdown == 2 and blow.kb == 55)
check("finisher copy leaves the move untouched", m1.damage == 5 and m1.knockdown == nil)
local launch = R.applyFinisher(m1, "launch", tuning)
check("launch goes up with longer stun", launch.up == 75 and launch.hitstun == 0.9 and launch.knockdown == nil)
local spike = R.applyFinisher(m1, "spike", tuning)
check("spike goes down and cracks", spike.down == 60 and spike.crackRadius == 9 and spike.knockdown == 1.6)
check("unknown finisher falls back to blow", R.applyFinisher(m1, "nope", tuning).knockdown == 2)

-- knockdown protection
check("not protected when never downed", not R.isProtected(nil, 5, 0.5))
check("protected while down", R.isProtected(12, 11, 0.5))
check("protected just after getting up", R.isProtected(12, 12.3, 0.5))
check("not protected later", not R.isProtected(12, 12.6, 0.5))

-- parry reward
check("first parry primes", R.parryReward(nil, 10) == "prime")
check("second parry while primed vanishes", R.parryReward(12, 10) == "vanish")
check("expired prime primes again", R.parryReward(9, 10) == "prime")

-- anti-team burst
check("one attacker is not a team-up", not R.teamBurstReady({ a = 10 }, 10.5, 3, 2, nil, 30))
check("two attackers within the window", R.teamBurstReady({ a = 9, b = 10 }, 10.5, 3, 2, nil, 30))
check("stale hits do not count", not R.teamBurstReady({ a = 5, b = 10 }, 10.5, 3, 2, nil, 30))
check("cooldown blocks the burst", not R.teamBurstReady({ a = 9, b = 10 }, 10.5, 3, 2, 0, 30))
check("cooldown over allows it", R.teamBurstReady({ a = 39, b = 40 }, 40.5, 3, 2, 0, 30))

print(passed .. " passed, " .. failed .. " failed")
if failed > 0 then
	error("tests failed")
end
