--!strict
-- Token bucket per player per key.
local RateLimit = {}
local buckets: { [Player]: { [string]: { tokens: number, t: number } } } = {}

function RateLimit.allow(p: Player, key: string, perSecond: number, burst: number): boolean
	local b = buckets[p]
	if not b then b = {}; buckets[p] = b end
	local s = b[key]
	local now = os.clock()
	if not s then s = { tokens = burst, t = now }; b[key] = s end
	s.tokens = math.min(burst, s.tokens + (now - s.t) * perSecond)
	s.t = now
	if s.tokens < 1 then return false end
	s.tokens -= 1
	return true
end

game:GetService("Players").PlayerRemoving:Connect(function(p) buckets[p] = nil end)
return RateLimit
