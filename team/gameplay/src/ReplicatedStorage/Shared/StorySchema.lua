--!strict
-- ModuleScript: ReplicatedStorage.Shared.StorySchema  (PURE; validates/normalizes db-story's gameplay/StoryMissions.lua)
-- Expected mission entry (see SPEC §0.11):
--   { id: number (unique, ordered), arc: string, name: string, scene: string ("Hero vs Enemy ..."), character: string (display
--     name of the playable hero), objective: string, fail: string?, twist: string?,
--     rewards = { xp: number?, zeni: number?, title: string?, form: string? (badge only, see below) },
--     dialogue = { string }?, goal = { type = "defeat"|"survive"|"hits"|"timed", seconds: number?, count: number? }? }
-- If `goal` is missing it is parsed from `objective` (Survive 90s / 2 min, Land 10 hits, in under 60s, Defeat/Win/...).
-- Story "form" rewards are a cosmetic mastery BADGE only (no unlock/stat) - power stays on the level curve (proposal).
local StorySchema = {}

local function num(s: string?): number? return s and tonumber(s) end

function StorySchema.parseGoal(objective: string): { type: string, seconds: number?, count: number? }
	local o = string.lower(objective or "")
	local secs = num(string.match(o, "survive%s+(%d+)%s*s")) or (num(string.match(o, "survive%s+(%d+)%s*min")) and (num(string.match(o, "survive%s+(%d+)%s*min")) :: number) * 60)
	if not secs and string.find(o, "survive") then -- "Survive Frieza 100% for 2 min" / "survive ... 45s"
		local mm = num(string.match(o, "(%d+)%s*min"))
		secs = if mm then mm * 60 else num(string.match(o, "(%d+)%s*s%f[%W]"))
	end
	if secs then return { type = "survive", seconds = secs } end
	local hits = num(string.match(o, "land%s+(%d+)%s+hits"))
	if hits then return { type = "hits", count = hits } end
	local under = num(string.match(o, "under%s+(%d+)%s*s"))
	if under then return { type = "timed", seconds = under } end
	local mins = num(string.match(o, "(%d+)%-minute")) or num(string.match(o, "(%d+)%s*min"))
	if mins and string.find(o, "before") then return { type = "timed", seconds = mins * 60 } end
	return { type = "defeat" }
end

function StorySchema.enemyOf(scene: string): string
	local e = string.match(scene or "", "[Vv][Ss]%.?%s+(.+)$")
	if not e then return "Rival" end -- no "vs" in scene: generic boss name (db-story can set `enemy` explicitly)
	e = string.gsub(e, "%s+while.*$", "")
	e = string.gsub(e, "%s+beam clash.*$", "")
	return e
end

-- Returns normalized list + list of error strings. Bad entries are skipped, never crash.
function StorySchema.normalize(raw: any): ({ any }, { string })
	local out, errs = {}, {}
	if type(raw) ~= "table" then return out, { "StoryMissions is not a table" } end
	local seen = {}
	for i, m in raw do
		if type(m) ~= "table" then table.insert(errs, ("#%s not a table"):format(tostring(i))); continue end
		if type(m.id) ~= "number" or seen[m.id] then table.insert(errs, ("#%s bad/duplicate id"):format(tostring(i))); continue end
		if type(m.name) ~= "string" or type(m.objective) ~= "string" then table.insert(errs, ("id %d missing name/objective"):format(m.id)); continue end
		seen[m.id] = true
		local r = type(m.rewards) == "table" and m.rewards or {}
		table.insert(out, {
			id = m.id, arc = m.arc or "?", name = m.name, scene = m.scene or "", character = m.character or "?",
			objective = m.objective, enemy = if type(m.enemy) == "string" then m.enemy else StorySchema.enemyOf(m.scene or ""),
			goal = if type(m.goal) == "table" and type(m.goal.type) == "string" then m.goal else StorySchema.parseGoal(m.objective),
			rewards = { xp = math.clamp(tonumber(r.xp) or 0, 0, 5000), zeni = math.clamp(tonumber(r.zeni) or 0, 0, 5000),
				title = if type(r.title) == "string" then r.title else nil, badge = if type(r.form) == "string" then r.form else nil },
			dialogue = if type(m.dialogue) == "table" then m.dialogue else {},
		})
	end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out, errs
end

return StorySchema
