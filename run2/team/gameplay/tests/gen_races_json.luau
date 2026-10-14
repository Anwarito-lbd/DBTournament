-- Prints Races.describe() for every champion as JSON. Run: (cd gameplay/tests && sh run.sh >/dev/null; luau gen_races_json.luau > ../data/races_describe.json)
local Config = require("./_lib/Config")
local Races = require("./_lib/Races")
local function q(s) return '"' .. tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"' end
local ids = {}
for id in Config.CHAR_BY_ID do table.insert(ids, id) end
table.sort(ids)
local out = { "{", '  "_note": "Generated from Races.describe(charId) + Config (gameplay/tests/gen_races_json.luau). Stub for CharacterSelect.",', '  "champions": {' }
for i, id in ids do
	local d = Races.describe(id)
	local r = Races.LIST[d.race]
	local ch = Config.CHAR_BY_ID[id]
	local traits, pus = {}, {}
	for _, t in d.traits do table.insert(traits, q(t)) end
	local kit = {}
	local mids = {}
	for mid in Config.MOVES do table.insert(mids, mid) end
	table.sort(mids)
	for _, mid in mids do
		local mv = Config.MOVES[mid]
		if (mv.freeForIds and table.find(mv.freeForIds, id)) or (mv.freeForPrefix and string.sub(id, 1, #mv.freeForPrefix) == mv.freeForPrefix) then
			table.insert(kit, q(mid))
		end
	end
	for _, pu in (r.powerUps or {}) do table.insert(pus, ('{ "id": %s, "level": %d }'):format(q(pu.id), pu.level)) end
	table.insert(out, ('    %s: { "name": %s, "race": %s, "raceName": %s, "desc": %s, "traits": [%s], "powerUps": [%s], "kit": [%s], "playable": %s, "tier": %s }%s')
		:format(q(id), q(ch.name or id), q(d.race), q(d.name), q(d.desc), table.concat(traits, ", "), table.concat(pus, ", "), table.concat(kit, ", "),
			tostring(Races.isPlayable(id, Config.FEATURES)), q(Config.tierOf(ch)), if i < #ids then "," else ""))
end
table.insert(out, "  }")
table.insert(out, "}")
print(table.concat(out, "\n"))
