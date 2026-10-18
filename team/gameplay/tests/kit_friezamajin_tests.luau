-- FriezaMajin kit data check (plain Luau): loads Kits/FriezaMajin and its clip sets, then checks every fighter's
-- fields, that every effect module it names exists, that its forms cover each roster form's preset, that kit moves
-- are well-formed and that the four fighters stay distinct. Run from this folder: luau kit_friezamajin_tests.luau
-- (not part of run.sh).
-- Effect modules need Roblox to run, so they are only resolved: a module that loads and then fails on `game`
-- exists; "could not resolve" means a typo or a missing file.
local KIT = "../src/ReplicatedStorage/Shared/Kits/FriezaMajin"
local Kit = require("../src/ReplicatedStorage/Shared/Kits/FriezaMajin")
local okConfig, Config = pcall(require, "../src/ReplicatedStorage/Shared/Config")
local passed, failed = 0, 0
local function test(n, f) local o, e = pcall(f); if o then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end

local FIGHTERS = { "u7_frieza", "u6_frost", "u7_moro", "u3_maji_kayo" }
local AURAS = { SSJ = true, SSJ2 = true, SSJ3 = true, SSG = true, SSB = true, SSBEvolved = true, UISign = true, MUI = true,
	UltraEgo = true, BeastGohan = true, GoldenFrieza = true, FriezaBlack = true, FriezaFullPower = true, KaioKen = true,
	JirenFullPower = true, ToppoGoD = true, Default = true } -- VFXCommon.AURAS keys
-- presets this kit styles before Config maps them (KITS.md "needs server work")
local PENDING_PRESETS = { FrostFinal = "u6_frost", KayoMuscular = "u3_maji_kayo" }
local STYLE_FLAGS = { lightning = true, crack = true, calmRings = true, wisps = true, slowmo = true, dark = true }
local STYLE_FIELDS = { title = true, color = true, flash = true, dur = true, orbit = true, shell = true }
local EASES = { Linear = true, Constant = true, Sine = true, CubicIn = true, CubicOut = true, QuadOut = true, BackOut = true }
local JOINTS = { "Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
	"RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle" }
local MOVE_KINDS = { melee = true, ray = true }
local MOVE_NUMBERS = { "cooldown", "range", "damage", "ki", "recovery", "kb", "guardDamage", "hitstun" }
-- move kinds the server broadcasts for every fighter; each fighter must look like themselves on these
local CORE_KINDS = { "Kamehameha", "Heavy", "KiBlast" }

-- the kit's view of a fighter: character entry first, race default second (same rule as Kits/init.lua)
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
local function key(v) -- a comparable string for a colour (plain values outside Roblox)
	return if type(v) == "table" then table.concat(v, ",") else tostring(v)
end

test("race and roster", function()
	assert(Kit.race == "FriezaMajin", "race")
	local n = 0
	for id in Kit.characters do
		n += 1
		assert(table.find(FIGHTERS, id), "unexpected fighter " .. id)
	end
	assert(n == #FIGHTERS, "expected 4 fighters, got " .. n)
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
		for _, kind in CORE_KINDS do
			local m = keyed(id, "signatures", kind)
			assert(type(m) == "string", id .. " has no " .. kind .. " signature")
		end
		local seen = {}
		for kind, m in Kit.characters[id].signatures or {} do seen[kind] = m end
		for kind, m in Kit.defaults.signatures do seen[kind] = seen[kind] or m end
		for kind, m in seen do
			assert(moduleExists(m), id .. " " .. kind .. ": no module " .. m)
		end
	end
end)

test("cameras are sane", function()
	for _, id in FIGHTERS do
		for _, kind in CORE_KINDS do
			if kind ~= "KiBlast" then assert(keyed(id, "cameras", kind), id .. " has no camera for " .. kind) end
		end
		for kind, cam in Kit.characters[id].cameras or {} do
			assert(type(cam.zoom) == "number" and math.abs(cam.zoom) <= 15, id .. " " .. kind .. " zoom")
			assert(type(cam.shake) == "number" and cam.shake >= 0 and cam.shake <= 1, id .. " " .. kind .. " shake")
		end
	end
end)

test("forms cover every roster form and are well-formed", function()
	for _, id in FIGHTERS do
		local forms = Kit.characters[id].forms
		assert(type(forms) == "table", id .. " has no forms")
		for preset, st in forms do
			assert(type(st.title) == "string" and #st.title > 0, id .. " " .. preset .. " title")
			assert(st.color ~= nil and st.flash ~= nil, id .. " " .. preset .. " colours")
			assert(type(st.dur) == "number" and st.dur >= 1.5 and st.dur <= 4, id .. " " .. preset .. " dur")
			assert(type(st.orbit) == "number" and st.orbit > 0 and st.orbit <= 2, id .. " " .. preset .. " orbit")
			for k, v in st do
				assert(STYLE_FIELDS[k] or (STYLE_FLAGS[k] and v == true), id .. " " .. preset .. " unknown field " .. k)
			end
			if PENDING_PRESETS[preset] then
				assert(PENDING_PRESETS[preset] == id, preset .. " belongs to " .. PENDING_PRESETS[preset])
			end
		end
		if okConfig then
			for _, formId in Config.CHAR_BY_ID[id].forms do
				local preset = Config.vfxFor(id, formId)
				if preset then
					assert(forms[preset], id .. " has no style for " .. formId .. " (" .. preset .. ")")
				else -- no preset yet: the kit must carry the pending style (listed in KITS.md)
					local found = false
					for p, owner in PENDING_PRESETS do
						if owner == id and forms[p] then found = true end
					end
					assert(found, id .. " " .. formId .. " has no preset and no pending style")
				end
			end
		end
	end
end)

test("kit moves are well-formed and owned", function()
	local ids = {}
	for _, id in FIGHTERS do
		for moveId, mv in Kit.characters[id].moves or {} do
			assert(not ids[moveId], "move id used twice: " .. moveId)
			ids[moveId] = true
			if okConfig then assert(Config.MOVES[moveId] == nil, moveId .. " would shadow a core move") end
			assert(MOVE_KINDS[mv.kind], moveId .. " kind " .. tostring(mv.kind))
			assert(mv.champion == id, moveId .. " champion should be " .. id)
			for _, f in MOVE_NUMBERS do
				assert(type(mv[f]) == "number" and mv[f] >= 0, moveId .. " " .. f)
			end
			assert(type(mv.parryable) == "boolean", moveId .. " parryable")
			if mv.kind == "ray" then assert(type(mv.width) == "number" and mv.width > 0, moveId .. " width") end
			assert(mv.cooldown >= 3, moveId .. " cooldown too short for a kit move")
			assert(type(keyed(id, "signatures", moveId)) == "string", moveId .. " has no effect")
			assert(keyed(id, "cameras", moveId), moveId .. " has no camera")
		end
	end
end)

test("clip sets", function()
	for _, id in FIGHTERS do
		local name = Kit.characters[id].clips
		assert(type(name) == "string", id .. " has no clip set")
		local set = clipSet(name)
		assert(set.Transform_SSJ, name .. " lacks its own Transform_SSJ (power-up would borrow Goku's)")
		assert(set.M1_1 and set.Idle and set.Heavy, name .. " does not reach the basic clips")
		for clipName, clip in set do
			assert(clip.fps == 60 and type(clip.length) == "number", name .. "." .. clipName .. " header")
			local last = -1
			for _, kf in clip.keyframes do
				assert(kf.t > last and kf.t <= clip.length, name .. "." .. clipName .. " frame order at " .. kf.t)
				last = kf.t
				assert(EASES[kf.ease], name .. "." .. clipName .. " ease " .. tostring(kf.ease))
				for _, j in JOINTS do
					local p = kf.poses[j]
					assert(p and #p.pos == 3 and #p.rot == 3, name .. "." .. clipName .. " joint " .. j .. " at " .. kf.t)
				end
			end
			assert(last == clip.length, name .. "." .. clipName .. " ends before its length")
		end
	end
end)

test("fighters stay distinct", function()
	local seen = { sig = {}, color = {}, clips = {}, feel = {} }
	for _, id in FIGHTERS do
		local c = Kit.characters[id]
		local pu = c.powerUp
		local checks = {
			sig = c.signatures.Kamehameha,
			color = key(pu.color),
			clips = c.clips,
			feel = string.format("%s/%s/%s", tostring(pu.screamStage), tostring(pu.zoom), tostring(pu.crack)),
		}
		for what, v in checks do
			assert(not seen[what][v], id .. " shares its " .. what .. " (" .. v .. ") with " .. tostring(seen[what][v]))
			seen[what][v] = id
		end
	end
end)

print(string.format("kit_friezamajin: %d passed, %d failed", passed, failed))
if failed > 0 then error("kit_friezamajin tests failed") end
