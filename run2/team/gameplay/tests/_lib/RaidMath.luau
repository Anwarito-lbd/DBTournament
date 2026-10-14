--!strict
-- ModuleScript: ReplicatedStorage.Shared.RaidMath  (PURE; GDD §7.3/7.4; tests in gameplay/tests)
local RaidMath = {}

-- GDD: boss HP x (1 + 0.6 (players-1)). Damage x (1 + 0.08 (players-1)) [proposal: keeps solo/8p TTK similar].
function RaidMath.hpScale(players: number): number return 1 + 0.6 * (math.max(1, players) - 1) end
function RaidMath.dmgScale(players: number): number return 1 + 0.08 * (math.max(1, players) - 1) end

-- phases: ascending list of { at = hpFraction threshold (enter when hp <= at), ... }; returns the index of active phase (1 = start)
function RaidMath.phase(hpFrac: number, thresholds: { number }): number
	local idx = 1
	for i, at in thresholds do if hpFrac <= at then idx = i + 1 end end
	return idx
end

-- Rewards: Zeni 300..800 by difficulty tier 1..3, + first-clear-of-the-week bonus (deterministic), + a free cosmetic drop
-- with PUBLISHED odds (rolled from a server seed). Free drops only: no paid random items.
function RaidMath.zeni(tier: number, contribution: number): number
	local base = ({ 300, 550, 800 })[math.clamp(tier, 1, 3)]
	return math.floor(base * math.clamp(0.5 + contribution, 0.5, 1)) -- contribution: share of boss damage (0..1); everyone gets >=50%
end

-- odds: { {id, p} } with sum(p) <= 1 (remainder = nothing). r in [0,1).
function RaidMath.rollDrop(odds: { { id: string, p: number } }, r: number): string?
	local acc = 0
	for _, o in odds do
		acc += o.p
		if r < acc then return o.id end
	end
	return nil
end
function RaidMath.oddsValid(odds: { { id: string, p: number } }): boolean
	local s = 0
	for _, o in odds do if o.p < 0 then return false end; s += o.p end
	return s <= 1 + 1e-9
end

return RaidMath
