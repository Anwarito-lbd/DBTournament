--!strict
-- ModuleScript: ReplicatedStorage.Shared.DragonBalls  (PURE hunt + wish rules; GDD §8.7; tests in gameplay/tests)
-- Weekly hunt (reset Monday 00:00 UTC): 7 balls per player at seeded positions from candidate anchors; collect = server
-- distance check; 7 balls -> summon Shenron once per week -> ONE wish. Wishes are COSMETIC or ZENI only (lead rule):
-- any wish with stat/power/xp/level effects is rejected by validateWish, so nothing can push stats past the 1.35x cap.
local DragonBalls = {}

DragonBalls.COUNT = 7
DragonBalls.COLLECT_RANGE = 8
DragonBalls.MIN_COLLECT_INTERVAL = 1.5 -- s between collects (anti-macro)
DragonBalls.WISH_WINDOW = 60 -- s to choose after summoning
DragonBalls.ALLOWED_KINDS = { cosmetic = true, zeni = true, title = true, aura = true }
DragonBalls.WISHES = {
	{ id = "Zeni", kind = "zeni", zeni = 3000, text = "Riches: 3,000 Zeni" },
	{ id = "AuraShenron", kind = "aura", cosmetic = "Aura_Shenron", text = "Shenron's emerald aura" },
	{ id = "TitleWish", kind = "title", title = "Wish Granter", text = "Title: Wish Granter" },
	{ id = "OutfitRotation", kind = "cosmetic", rotating = true, text = "One of this week's 3 rotating outfits" },
}
DragonBalls.ROTATION = { "Outfit_Shenron_Gi", "Outfit_Namek_Cape", "Outfit_Capsule_Jacket", "Outfit_Red_Ribbon", "Outfit_Turtle_Hermit" }
local FORBIDDEN_KEYS = { "stat", "statBoost", "mult", "power", "xp", "level", "boost", "unlock", "form", "damage", "defense" }

function DragonBalls.weekOf(t: number): number return (t // 86400 + 3) // 7 end

-- validates a wish DEFINITION (also used to lint data); returns ok, reason
function DragonBalls.validateWish(w: any): (boolean, string?)
	if type(w) ~= "table" or type(w.id) ~= "string" then return false, "Malformed" end
	if not DragonBalls.ALLOWED_KINDS[w.kind] then return false, "KindNotAllowed" end
	for _, k in FORBIDDEN_KEYS do if w[k] ~= nil then return false, "StatEffectForbidden:" .. k end end
	if w.kind == "zeni" and (type(w.zeni) ~= "number" or w.zeni <= 0 or w.zeni > 10000) then return false, "ZeniOutOfRange" end
	return true, nil
end

function DragonBalls.wish(id: string): any?
	for _, w in DragonBalls.WISHES do if w.id == id then return w end end
	return nil
end

-- 3 rotating outfits offered this week (deterministic)
function DragonBalls.rotation(week: number): { string }
	local out, n = {}, #DragonBalls.ROTATION
	for i = 0, 2 do table.insert(out, DragonBalls.ROTATION[((week * 3 + i) % n) + 1]) end
	return out
end

-- seeded positions: pick 7 distinct anchors (list of {x,y,z} or Vector3-like) + jitter; deterministic per (userId, week)
function DragonBalls.positions(userId: number, week: number, anchors: { any }): { { x: number, y: number, z: number } }
	local x = (userId * 7919 + week * 104729) % 2147483647
	if x == 0 then x = 1 end
	local function rnd(): number x = (x * 48271) % 2147483647; return x / 2147483647 end
	local idx = {}
	for i = 1, #anchors do idx[i] = i end
	local out = {}
	for i = 1, math.min(DragonBalls.COUNT, #anchors) do
		local k = i + math.floor(rnd() * (#idx - i + 1))
		idx[i], idx[k] = idx[k], idx[i]
		local a = anchors[idx[i]]
		table.insert(out, { x = a.x + (rnd() - 0.5) * 30, y = a.y + 3, z = a.z + (rnd() - 0.5) * 30 })
	end
	return out
end

export type State = { week: number, have: { boolean }, summoned: boolean, lastCollect: number }
-- `have` is always a dense array of 7 booleans (DataStore-safe: no sparse arrays)
local function empty(): { boolean } local t = {}; for i = 1, DragonBalls.COUNT do t[i] = false end; return t end
function DragonBalls.new(): State return { week = -1, have = empty(), summoned = false, lastCollect = 0 } end
function DragonBalls.refresh(s: State, now: number): boolean
	local w = DragonBalls.weekOf(now)
	if s.week ~= w or #s.have ~= DragonBalls.COUNT then s.week = w; s.have = empty(); s.summoned = false; return true end
	return false
end
function DragonBalls.count(s: State): number local n = 0; for i = 1, DragonBalls.COUNT do if s.have[i] then n += 1 end end; return n end

-- collect ball i given the player's distance to the server-known ball position and a clock. Returns ok, reason.
function DragonBalls.collect(s: State, i: number, dist: number, clock: number): (boolean, string?)
	if type(i) ~= "number" or i ~= i // 1 or i < 1 or i > DragonBalls.COUNT then return false, "BadIndex" end
	if s.summoned then return false, "Stone" end
	if s.have[i] then return false, "AlreadyHave" end
	if dist > DragonBalls.COLLECT_RANGE then return false, "TooFar" end
	if clock - s.lastCollect < DragonBalls.MIN_COLLECT_INTERVAL then return false, "TooFast" end
	s.have[i] = true
	s.lastCollect = clock
	return true, nil
end

function DragonBalls.canSummon(s: State): (boolean, string?)
	if s.summoned then return false, "AlreadySummonedThisWeek" end
	if DragonBalls.count(s) < DragonBalls.COUNT then return false, "MissingBalls" end
	return true, nil
end

-- Resolve a wish choice into a reward table for PlayerData.grantReward (cosmetic/zeni/title only).
function DragonBalls.resolve(wishId: string, choice: string?, week: number): (any?, string?)
	local w = DragonBalls.wish(wishId)
	if not w then return nil, "UnknownWish" end
	local ok, why = DragonBalls.validateWish(w)
	if not ok then return nil, why end
	if w.kind == "zeni" then return { zeni = w.zeni }, nil end
	if w.kind == "title" then return { title = w.title }, nil end
	if w.kind == "aura" then return { cosmetic = w.cosmetic }, nil end
	if w.rotating then
		if not choice or not table.find(DragonBalls.rotation(week), choice) then return nil, "BadChoice" end
		return { cosmetic = choice }, nil
	end
	return nil, "Unhandled"
end

return DragonBalls
