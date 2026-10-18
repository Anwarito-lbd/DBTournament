-- Earth defenders kit data check (plain Luau): loads Kits/EarthDefenders and its clip sets, then checks every
-- fighter's fields, that every effect module it names exists, that race power-ups get their fighter's effect, that
-- forms only style reachable or listed-pending presets, and that fighters stay distinct.
-- Run from this folder: luau kit_earthdefenders_tests.luau (not part of run.sh).
-- Effect modules need Roblox to run, so they are only resolved: a module that loads and then fails on `game`
-- exists; "could not resolve" means a typo or a missing file.
local KIT = "../src/ReplicatedStorage/Shared/Kits/EarthDefenders"
local Kit = require("../src/ReplicatedStorage/Shared/Kits/EarthDefenders")
local Races = require("../src/ReplicatedStorage/Shared/Races")
local okConfig, Config = pcall(require, "../src/ReplicatedStorage/Shared/Config")
local passed, failed = 0, 0
local function test(n, f) local o, e = pcall(f); if o then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end

local FIGHTERS = { "u7_piccolo", "u7_android_17", "u7_android_18", "u7_krillin", "u7_tien", "u7_master_roshi", "u7_shin" }
-- the race power-up each race broadcasts (Config.MOVES race gates) -> the kit must give the fighter an effect for it
local RACE_POWERUP = { Android = "Barrier", Earthling = "SolarFlare", Kaioshin = "KaiKai" }
local AURAS = { SSJ = true, SSJ2 = true, SSJ3 = true, SSG = true, SSB = true, SSBEvolved = true, UISign = true, MUI = true,
	UltraEgo = true, BeastGohan = true, GoldenFrieza = true, FriezaBlack = true, FriezaFullPower = true, KaioKen = true,
	JirenFullPower = true, ToppoGoD = true, Default = true } -- VFXCommon.AURAS keys
-- presets this kit styles before Config maps them (KITS.md "needs server work")
local PENDING_PRESETS = { PiccoloWeightsOff = "u7_piccolo", RoshiMaxPower = "u7_master_roshi" }
local STYLE_FLAGS = { lightning = true, crack = true, calmRings = true, wisps = true, slowmo = true, dark = true }
local EASES = { Linear = true, Constant = true, Sine = true, CubicIn = true, CubicOut = true, QuadOut = true, BackOut = true }
local JOINTS = { "Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
	"RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle" }
local CORE_CLIPS = { "Idle", "M1_4", "Heavy", "Kamehameha_Charge", "Kamehameha_Fire" }
-- kit move ids other kits already use (Saiyan, PrideTroopers): Config.MOVES keeps the first, so ours must differ
local OTHER_KIT_MOVES = { DragonFist = true, BigBangAttack = true, LightBullet = true, CocotteZone = true,
	JusticeWhip = true, JusticeSpin = true, BurningSpin = true, GrandCharge = true }

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
	assert(ok, "clip set " .. name .. " failed to load: " .. tostring(set))
	return set
end

test("race and roster", function()
	assert(Kit.race == "EarthDefenders", "race")
	local n = 0
	for id, c in Kit.characters do
		n += 1
		assert(table.find(FIGHTERS, id), "unexpected fighter " .. id)
		assert(c.race == Races.CHAMPION[id], id .. " notes race " .. tostring(c.race) .. ", Races says "
			.. tostring(Races.CHAMPION[id]))
	end
	assert(n == #FIGHTERS, "expected 7 fighters, got " .. n)
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
	end
	-- no ki to gather: the androids never scream and barely crack the ground; neither does a calm god
	for _, id in { "u7_android_17", "u7_android_18", "u7_shin" } do
		local pu = Kit.characters[id].powerUp
		assert(pu.screamStage == 4 and pu.crack <= 0.6, id .. " should power up silently")
	end
	assert(Kit.characters.u7_krillin.powerUp.screamStage < Kit.characters.u7_tien.powerUp.screamStage,
		"Krillin shouts before Tien")
end)

test("signatures resolve to effect modules", function()
	for _, id in FIGHTERS do
		for _, kind in { "Kamehameha", "Heavy", "KiBlast" } do
			assert(type(keyed(id, "signatures", kind)) == "string", id .. " has no " .. kind .. " signature")
		end
		local seen = {}
		for kind, m in Kit.characters[id].signatures or {} do seen[kind] = m end
		for kind, m in Kit.defaults.signatures do if seen[kind] == nil then seen[kind] = m end end
		for kind, m in seen do assert(moduleExists(m), id .. " " .. kind .. " -> missing module " .. m) end
	end
end)

test("race power-ups get the fighter's effect", function()
	for _, id in FIGHTERS do
		local kind = RACE_POWERUP[Races.CHAMPION[id]]
		if kind then
			assert(keyed(id, "signatures", kind), id .. " has no effect for its race power-up " .. kind)
			if okConfig then
				local mv = Config.MOVES[kind]
				assert(mv and mv.races and table.find(mv.races, Races.CHAMPION[id]), kind .. " is not a " .. Races.CHAMPION[id] .. " move")
			end
		end
	end
	assert(Kit.characters.u7_android_17.signatures.Barrier == "AndroidBarrierVFX", "17's barrier is his signature")
end)

test("cameras", function()
	for _, id in FIGHTERS do
		local kinds = { "Kamehameha", "Heavy" }
		for kind in Kit.characters[id].cameras do table.insert(kinds, kind) end
		for _, kind in kinds do
			local cam = keyed(id, "cameras", kind)
			assert(cam and type(cam.zoom) == "number" and cam.zoom > 0 and cam.zoom <= 15, id .. " " .. kind .. " zoom")
			assert(type(cam.shake) == "number" and cam.shake > 0 and cam.shake <= 1, id .. " " .. kind .. " shake")
		end
	end
end)

test("forms style reachable or pending presets only", function()
	for _, id in FIGHTERS do
		local forms = Kit.characters[id].forms or {}
		for preset, st in forms do
			assert(type(st.title) == "string" and #st.title > 0, id .. " " .. preset .. " title")
			assert(st.color ~= nil and st.flash ~= nil, id .. " " .. preset .. " colours")
			assert(type(st.dur) == "number" and st.dur >= 1.5 and st.dur <= 4, id .. " " .. preset .. " dur")
			assert(type(st.orbit) == "number" and st.orbit > 0 and st.orbit <= 2, id .. " " .. preset .. " orbit")
			for k, v in st do
				if STYLE_FLAGS[k] then assert(v == true, id .. " " .. preset .. "." .. k) end
				assert(STYLE_FLAGS[k] or k == "title" or k == "color" or k == "flash" or k == "dur" or k == "orbit",
					id .. " " .. preset .. " unknown field " .. k)
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
	for preset, id in PENDING_PRESETS do assert(Kit.characters[id].forms[preset], id .. " lost pending style " .. preset) end
end)

test("clip sets load and are well-formed", function()
	local used = {}
	for _, id in FIGHTERS do
		local name = field(id, "clips")
		assert(type(name) == "string", id .. " clips")
		assert(not used[name], id .. " shares clip set " .. name .. " with " .. tostring(used[name]))
		used[name] = id
		local set = clipSet(name)
		for _, c in CORE_CLIPS do assert(set.clips[c], name .. " lacks " .. c) end
		assert(set.clips.Idle.looped, name .. " needs a looping Idle")
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
					for a = 1, 3 do assert(math.abs(p.rot[a]) <= 180, where .. " key " .. i .. " " .. j .. " angle") end
				end
				last = kf.t
			end
			assert(last == clip.length, where .. " must end on its length")
			local hits = 0
			for _, kf in clip.keyframes do if kf.markers and kf.markers.hit then hits += 1 end end
			if clipName == "M1_4" or clipName == "Heavy" then assert(hits == 1, where .. " needs one hit marker") end
		end
	end
end)

test("kit moves use existing kinds and stay with their fighter", function()
	local ids = {}
	for _, id in FIGHTERS do
		for moveId, mv in Kit.characters[id].moves or {} do
			assert(not ids[moveId] and not OTHER_KIT_MOVES[moveId], moveId .. " is already taken")
			ids[moveId] = true
			assert(mv.kind == "melee" or mv.kind == "ray", moveId .. " kind")
			assert(mv.champion == id, moveId .. " must be gated to " .. id)
			assert(type(mv.damage) == "number" and mv.damage > 0 and mv.damage < 28, moveId .. " damage under the core beam")
			assert(mv.cooldown >= 8 and mv.ki > 0 and mv.range > 0, moveId .. " cost")
			assert(mv.beam == nil, moveId .. " must not join beam struggles")
			assert(keyed(id, "signatures", moveId), moveId .. " has no effect")
			assert(keyed(id, "cameras", moveId), moveId .. " has no camera")
			if okConfig then assert(Config.MOVES[moveId] == nil, moveId .. " collides with a core move") end
		end
	end
end)

test("fighters are distinct", function()
	local beams, looks, heavies = {}, {}, {}
	for _, id in FIGHTERS do
		local c = Kit.characters[id]
		local beam = c.signatures.Kamehameha
		assert(not beams[beam], id .. " shares its beam " .. beam .. " with " .. tostring(beams[beam]))
		beams[beam] = id
		local pu = c.powerUp
		local look = string.format("%s|%s|%s", tostring(pu.zoom), tostring(pu.screamStage), tostring(pu.crack))
		assert(not looks[look], id .. " power-up matches " .. tostring(looks[look]))
		looks[look] = id
		local cam = keyed(id, "cameras", "Kamehameha")
		local h = string.format("%s|%s", tostring(cam.zoom), tostring(cam.shake))
		heavies[h] = (heavies[h] or 0) + 1
	end
	for h, n in heavies do assert(n <= 2, "signature camera " .. h .. " used by " .. n .. " fighters") end
	local a, b = Kit.characters.u7_android_17, Kit.characters.u7_android_18
	assert(a.clips ~= b.clips and a.signatures.Kamehameha ~= b.signatures.Kamehameha, "the twins feel the same")
end)

print(("%d passed, %d failed"):format(passed, failed)); if failed > 0 then error("tests failed") end
