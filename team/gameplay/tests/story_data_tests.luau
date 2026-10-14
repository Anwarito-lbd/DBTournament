local SS = require("./_lib/StorySchema")
local raw = require("./_lib/StoryMissions")
local list, errs = SS.normalize(raw)
print(("raw %d, loaded %d, skipped %d"):format(#raw, #list, #errs))
for _, e in errs do print("SKIP " .. e) end
local types = {}
for _, m in list do types[m.goal.type] = (types[m.goal.type] or 0) + 1; if m.enemy == "Rival" then print("NOENEMY " .. m.id .. " " .. m.scene) end end
for k, v in types do print(k, v) end
if #errs > 0 then error("story data has skipped entries") end
print("1 passed, 0 failed")
