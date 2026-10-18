-- Saiyan kit data check (plain Luau): loads Kits/Saiyan and its clip sets, then checks every fighter's fields,
-- that every effect module it names exists, that its forms cover each roster form's preset, and that fighters
-- stay distinct. Run from this folder: luau kit_saiyan_tests.luau (not part of run.sh).
-- Effect modules need Roblox to run, so they are only resolved: a module that loads and then fails on `game`
-- exists; "could not resolve" means a typo or a missing file.
local KIT = "../src/ReplicatedStorage/Shared/Kits/Saiyan"
local Kit = require("../src/ReplicatedStorage/Shared/Kits/Saiyan")
local okConfig, Config = pcall(require, "../src/ReplicatedStorage/Shared/Config")
local passed, failed = 0, 0
local function test(n, f) local o, e = pcall(f); if o then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end

local FIGHTERS = { "u7_goku", "u7_vegeta", "u7_gohan", "u7_trunks", "u7_broly", "u6_cabba", "u6_caulifla", "u6_kale",
	"u6_kefla", "u10_goku_black" }
local SHARED_CLIP_SETS = { Goku = true, Vegeta = true, Frieza = true, Shared = true } -- team/animation/poses
local AURAS = { SSJ = true, SSJ2 = true, SSJ3 = true, SSG = true, SSB = true, SSBEvolved = true, UISign = true, MUI = true,
	UltraEgo = true, BeastGohan = true, GoldenFrieza = true, FriezaBlack = true, FriezaFullPower = true, KaioKen = true,
	JirenFullPower = true, ToppoGoD = true, Default = true } -- VFXCommon.AURAS keys
-- presets this kit styles before Config maps them (KITS.md "needs server work")
local PENDING_PRESETS = { BrolyFullPower = "u7_broly", BlackRose = "u10_goku_black" }
local STYLE_FLAGS = { lightning = true, crack = true, calmRings = true, wisps = true, slowmo = true, dark = true }
local EASES = { Linear = true, Constant = true, Sine = true, CubicIn = true, CubicOut = true, QuadOut = true, BackOut = true }
local JOINTS = { "Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
	"RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle" }

-- the kit's view of a fighter: character entry first, race default second (same rule as Kits/init.lua)
local function field(id, name) local c = Kit.characters[id]; local v = c and c[name]; if v ~= nil then return v end; return Kit.defaults[name] end
local function keyed(id, name, key)
	local t = Kit.characters[id][name]
	if t and t[key] ~= nil then return t[key] end
	local d = Kit.defaults[name]
	return d and d[key]
end
local function moduleExists(name)
	for _, dir in { KIT .. "/VFX/", "../../animation/" } do
		local ok, err = pcall(require, dir .. name)
		if ok or not string.find(tostring(err), "could not resolve", 1, true) then return true end
	end
	return false
end
local function clipSet(name)
	local ok, set = pcall(require, KIT .. "/Poses/" .. name)
	if ok then return set end
	assert(string.find(tostring(set), "could not resolve", 1, true), "clip set " .. name .. " failed to load: " .. tostring(set))
	return nil
end

test("race and roster", function()
	assert(Kit.race == "Saiyan", "race")
	local n = 0
	for id in Kit.characters do
		n += 1
		assert(table.find(FIGHTERS, id), "unexpected fighter " .. id)
	end
	assert(n == #FIGHTERS, "expected 10 fighters, got " .. n)
	if okConfig then
		for _, id in FIGHTERS do assert(Config.CHAR_BY_ID[id], id .. " is not a roster id") end
	else
		print("SKIP roster ids (Config failed to load): " .. tostring(Config))
	end
end)

test("power-up per fighter", function()
	for _, id in FIGHTERS do
		local pu = Kit.characters[id].powerUp
		assert(type(pu) == "table", id .. " has no own powerUp")
		assert(pu.color ~= nil, id .. " colour")
		assert(type(pu.zoom) == "number" and pu.zoom > 0 and pu.zoom <= 15, id .. " zoom")
		assert(pu.screamStage == 1 or pu.screamStage == 2 or pu.screamStage == 3 or pu.screamStage == 4, id .. " scream stage")
		assert(type(pu.crack) == "number" and pu.crack >= 0.5 and pu.crack <= 2, id .. " crack")
		assert(pu.aura == nil or AURAS[pu.aura], id .. " aura " .. tostring(pu.aura))
		if pu.aura and okConfig then -- a kit aura replaces the form aura, so only single-form fighters may set one
			assert(#Config.CHAR_BY_ID[id].forms == 1, id .. " sets an aura but has several forms")
		end
	end
end)

test("signatures resolve to effect modules", function()
	for _, id in FIGHTERS do
		for _, kind in { "Kamehameha", "Heavy", "KiBlast" } do
			local m = keyed(id, "signatures", kind)
			assert(type(m) == "string", id .. " has no " .. kind .. " signature")
		end
		local seen = {}
		for kind, m in Kit.characters[id].signatures or {} do seen[kind] = m end
		for kind, m in Kit.defaults.signatures do if seen[kind] == nil then seen[kind] = m end end
		for kind, m in seen do assert(moduleExists(m), id .. " " .. kind .. " -> missing module " .. m) end
	end
end)

test("cameras", function()
	for _, id in FIGHTERS do
		for _, kind in { "Kamehameha", "Heavy" } do
			local cam = keyed(id, "cameras", kind)
			assert(cam and type(cam.zoom) == "number" and cam.zoom > 0 and cam.zoom <= 15, id .. " " .. kind .. " zoom")
			assert(type(cam.shake) == "number" and cam.shake > 0 and cam.shake <= 1, id .. " " .. kind .. " shake")
		end
	end
end)

test("forms cover every roster form preset", function()
	for _, id in FIGHTERS do
		local forms = Kit.characters[id].forms
		assert(type(forms) == "table", id .. " has no forms")
		for preset, st in forms do
			assert(type(st.title) == "string" and #st.title > 0, id .. " " .. preset .. " title")
			assert(st.color ~= nil and st.flash ~= nil, id .. " " .. preset .. " colours")
			assert(type(st.dur) == "number" and st.dur >= 1.5 and st.dur <= 4, id .. " " .. preset .. " dur")
			assert(type(st.orbit) == "number" and st.orbit > 0 and st.orbit <= 2, id .. " " .. preset .. " orbit")
			for k, v in st do
				if STYLE_FLAGS[k] then assert(v == true, id .. " " .. preset .. "." .. k) end
				assert(STYLE_FLAGS[k] or k == "title" or k == "color" or k == "flash" or k == "dur" or k == "orbit"
					or k == "shell", id .. " " .. preset .. " unknown field " .. k)
			end
		end
		if okConfig then
			local reachable = {}
			for _, f in Config.CHAR_BY_ID[id].forms do
				local preset = Config.vfxFor(id, f)
				if preset then
					reachable[preset] = true
					assert(forms[preset], id .. " has no style for " .. f .. " (preset " .. preset .. ")")
				end
			end
			for preset in forms do
				assert(reachable[preset] or PENDING_PRESETS[preset] == id, id .. " styles unreachable preset " .. preset)
			end
		end
	end
end)

test("clip sets load and are well-formed", function()
	for _, id in FIGHTERS do
		local name = field(id, "clips")
		assert(type(name) == "string", id .. " clips")
		local set = clipSet(name)
		assert(set or SHARED_CLIP_SETS[name], id .. " clip set " .. name .. " not found")
		if set then
			assert(set.clips.Idle and set.clips.Idle.looped, name .. " needs a looping Idle")
			for clipName, clip in set.clips do
				local where = name .. "." .. clipName
				assert(clip.fps == 60 and clip.length > 0 and type(clip.priority) == "string", where .. " header")
				local last = -1
				for i, kf in clip.keyframes do
					assert(kf.t > last and kf.t <= clip.length, where .. " key " .. i .. " frame order")
					assert(i > 1 or kf.t == 0, where .. " must start at 0")
					assert(EASES[kf.ease], where .. " ease " .. tostring(kf.ease))
					for _, j in JOINTS do
						local p = kf.poses[j]
						assert(p and #p.pos == 3 and #p.rot == 3, where .. " key " .. i .. " joint " .. j)
					end
					last = kf.t
				end
				assert(last == clip.length, where .. " must end on its length")
			end
		end
	end
end)

test("kit moves use existing kinds and stay with their fighter", function()
	for _, id in FIGHTERS do
		for moveId, mv in Kit.characters[id].moves or {} do
			assert(mv.kind == "melee" or mv.kind == "ray", moveId .. " kind")
			assert(mv.champion == id, moveId .. " must be gated to " .. id)
			assert(type(mv.damage) == "number" and mv.damage > 0 and mv.damage < 28, moveId .. " damage under the core beam")
			assert(mv.cooldown >= 8 and mv.ki > 0 and mv.range > 0, moveId .. " cost")
			assert(keyed(id, "signatures", moveId), moveId .. " has no effect")
			assert(keyed(id, "cameras", moveId), moveId .. " has no camera")
			if okConfig then assert(Config.MOVES[moveId] == nil, moveId .. " collides with a core move") end
		end
	end
end)

test("fighters are distinct", function()
	local beams, looks = {}, {}
	for _, id in FIGHTERS do
		local c = Kit.characters[id]
		local beam = c.signatures.Kamehameha
		assert(not beams[beam], id .. " shares its beam " .. beam .. " with " .. tostring(beams[beam]))
		beams[beam] = id
		local pu = c.powerUp
		local look = string.format("%s|%s|%s|%s", tostring(pu.zoom), tostring(pu.screamStage), tostring(pu.crack),
			tostring(c.clips))
		assert(not looks[look], id .. " power-up and clips match " .. tostring(looks[look]))
		looks[look] = id
	end
	local g, v = Kit.characters.u7_goku, Kit.characters.u7_vegeta
	assert(g.powerUp.screamStage ~= v.powerUp.screamStage, "Goku and Vegeta scream at the same stage")
	assert(g.clips ~= v.clips and g.cameras.Kamehameha.zoom ~= v.cameras.Kamehameha.zoom, "Goku and Vegeta feel the same")
end)

print(("%d passed, %d failed"):format(passed, failed)); if failed > 0 then error("tests failed") end
