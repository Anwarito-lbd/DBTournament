-- Data check for the Universe 11 kit (Shared/Kits/PrideTroopers). Plain Luau, no Studio. Run from this folder:
--   luau kit_pridetroopers_tests.luau
-- Loads the kit, its clip sets and Config straight from src (Config's kit merge is guarded and skipped here, so the
-- kit's moves can be checked against the core move table). Effect modules need Roblox to run, so they are only
-- checked to exist: requiring one here fails at runtime, never with "could not resolve".
local SRC = "../src/ReplicatedStorage/Shared/"
local Kit = require("../src/ReplicatedStorage/Shared/Kits/PrideTroopers")
local Config = require("../src/ReplicatedStorage/Shared/Config")

local passed, failed = 0, 0
local function test(n, f)
	local o, e = pcall(f)
	if o then
		passed += 1
	else
		failed += 1
		print("FAIL " .. n .. ": " .. tostring(e))
	end
end
local function check(cond, msg)
	if not cond then
		error(msg, 2)
	end
end

local roster = {}
for _, ch in Config.ROSTER[11] do
	roster[ch.id] = ch
end

-- a module path exists when requiring it does not fail to resolve (it may still fail to run outside Roblox)
local function exists(path)
	local ok, err = pcall(require, path)
	return ok or not string.find(tostring(err), "could not resolve", 1, true)
end
local function effectExists(name)
	return exists("../../animation/" .. name)
		or exists("../src/ReplicatedStorage/Shared/Kits/PrideTroopers/VFX/" .. name)
end
local function field(id, name)
	local c = Kit.characters[id]
	if c[name] ~= nil then
		return c[name]
	end
	return Kit.defaults[name]
end
local function keyed(id, name, key)
	local c = Kit.characters[id][name]
	if c and c[key] ~= nil then
		return c[key]
	end
	local d = Kit.defaults[name]
	return d and d[key]
end
local function signatures(id)
	local out = table.clone(Kit.defaults.signatures or {})
	for k, v in Kit.characters[id].signatures or {} do
		out[k] = v
	end
	return out
end

local KINDS = {}
for _, mv in Config.MOVES do
	KINDS[mv.kind] = true
end
local kitMoves = {}
for id, c in Kit.characters do
	for mid, mv in c.moves or {} do
		kitMoves[mid] = { owner = id, mv = mv }
	end
end

test("race and roster coverage", function()
	check(Kit.race == "PrideTroopers", "race should be PrideTroopers")
	check(next(roster) ~= nil, "no Universe 11 roster in Config")
	for id in roster do
		check(Kit.characters[id], "roster fighter " .. id .. " has no kit entry")
	end
	for id in Kit.characters do
		check(roster[id], id .. " is not on the Universe 11 roster")
	end
end)

test("every fighter has a complete entry", function()
	for id in roster do
		local c = Kit.characters[id]
		check(type(c.clips) == "string", id .. " has no clip set")
		check(type(c.powerUp) == "table", id .. " has no power-up")
		check(type(c.cameras) == "table" and next(c.cameras), id .. " has no cameras")
		check(c.signatures or c.moves, id .. " has neither signatures nor moves of their own")
		local pu = c.powerUp
		check(type(pu.color) == "table", id .. " power-up colour")
		check(type(pu.zoom) == "number" and pu.zoom > 0, id .. " power-up zoom")
		check(type(pu.crack) == "number" and pu.crack > 0 and pu.crack <= 2, id .. " power-up crack")
		check(
			pu.screamStage == 1 or pu.screamStage == 2 or pu.screamStage == 3 or pu.screamStage == 4,
			id .. " scream stage"
		)
		for kind, cam in c.cameras do
			check(type(cam.zoom) == "number" or type(cam.shake) == "number", id .. " camera " .. kind .. " is empty")
		end
	end
end)

test("fighters are distinct", function()
	local seen = {}
	for id in roster do
		local pu = field(id, "powerUp")
		local key = table.concat({
			tostring(field(id, "clips")),
			tostring(keyed(id, "signatures", "Kamehameha")),
			tostring(pu.zoom),
			tostring(pu.screamStage),
			tostring(pu.crack),
			table.concat(pu.color, ","),
		}, "|")
		check(not seen[key], id .. " plays exactly like " .. tostring(seen[key]))
		seen[key] = id
	end
end)

test("signatures name real effect modules and real move kinds", function()
	for id in roster do
		for kind, mod in signatures(id) do
			check(effectExists(mod), id .. " signature " .. kind .. " -> missing effect module " .. mod)
			check(Config.MOVES[kind] or kitMoves[kind], id .. " signature for unknown move " .. kind)
		end
	end
end)

test("effects that read the kit's look find it", function()
	local NEEDS = {
		JusticeBlastVFX = { "blast" },
		JusticePoseVFX = { "pose" },
		JusticeFlashVFX = { "flash", "destroyer" },
		JusticeWaveVFX = { "wave" },
		CocotteZoneVFX = { "zone" },
		LightBulletVFX = { "rush" },
		JusticeWhipVFX = { "whip" },
		JusticeSpinVFX = { "spin" },
	}
	for id in roster do
		for _, mod in signatures(id) do
			for _, f in NEEDS[mod] or {} do
				check(Kit.lookFor(id, f) ~= nil, id .. " uses " .. mod .. " but has no look." .. f)
			end
		end
	end
	check(Kit.lookFor("u11_toppo", "flash").Shots, "Toppo's Justice Flash needs a shot count")
end)

test("forms are reachable and complete", function()
	for id in roster do
		local auraOk = field(id, "powerUp").aura == nil
		for preset, st in Kit.characters[id].forms or {} do
			local reachable = false
			for _, f in roster[id].forms or {} do
				if Config.vfxFor(id, f) == preset then
					reachable = true
				end
			end
			check(reachable, id .. " form style " .. preset .. " is never played: no form of theirs maps to it")
			check(type(st.title) == "string" and st.title ~= "", id .. " " .. preset .. " title")
			check(type(st.color) == "table" and type(st.flash) == "table", id .. " " .. preset .. " colours")
			check(
				type(st.orbit) == "number" and type(st.dur) == "number" and st.dur > 0,
				id .. " " .. preset .. " timing"
			)
			if field(id, "powerUp").aura == preset then
				auraOk = true
			end
		end
		check(auraOk, id .. " power-up aura is not one of their form presets")
	end
end)

test("kit moves use existing server kinds and stay with their owner", function()
	for mid, e in kitMoves do
		local mv = e.mv
		check(Config.MOVES[mid] == nil, mid .. " collides with a core move")
		check(KINDS[mv.kind], mid .. " uses unknown server kind " .. tostring(mv.kind))
		check(mv.champion == e.owner, mid .. " must be gated to " .. e.owner)
		check(type(mv.cooldown) == "number" and mv.cooldown > 0, mid .. " cooldown")
		check(type(mv.ki) == "number" and type(mv.recovery) == "number", mid .. " ki / recovery")
		if mv.kind == "melee" then
			check(
				type(mv.range) == "number" and type(mv.damage) == "number" and type(mv.hitstun) == "number",
				mid .. " melee numbers"
			)
		end
	end
end)

local JOINTS = {
	"Root",
	"Waist",
	"Neck",
	"LeftShoulder",
	"LeftElbow",
	"LeftWrist",
	"RightShoulder",
	"RightElbow",
	"RightWrist",
	"LeftHip",
	"LeftKnee",
	"LeftAnkle",
	"RightHip",
	"RightKnee",
	"RightAnkle",
}
local EASES =
	{ Linear = true, Constant = true, Sine = true, CubicIn = true, CubicOut = true, QuadOut = true, BackOut = true }
local function triple(v)
	return type(v) == "table"
		and #v == 3
		and type(v[1]) == "number"
		and type(v[2]) == "number"
		and type(v[3]) == "number"
end
local function checkClip(name, clip)
	check(clip.fps == 60, name .. " fps")
	check(type(clip.length) == "number" and clip.length > 0, name .. " length")
	local kfs = clip.keyframes
	check(type(kfs) == "table" and #kfs >= 2, name .. " needs 2+ keyframes")
	check(kfs[1].t == 0, name .. " first keyframe must be t = 0")
	local last = -1
	for i, kf in kfs do
		check(kf.t > last, name .. " keyframe " .. i .. " not sorted")
		last = kf.t
		check(EASES[kf.ease], name .. " keyframe " .. i .. " ease " .. tostring(kf.ease))
		local count = 0
		for _ in kf.poses do
			count += 1
		end
		check(count == #JOINTS, name .. " keyframe " .. i .. " has " .. count .. " joints")
		for _, j in JOINTS do
			local p = kf.poses[j]
			check(p and triple(p.pos) and triple(p.rot), name .. " keyframe " .. i .. " joint " .. j)
		end
	end
	check(last <= clip.length, name .. " runs past its length")
end

test("clip sets load, are well formed, and give everyone their own Justice Pose", function()
	local poseOf = {}
	for id in roster do
		local setName = field(id, "clips")
		local set = require(SRC .. "Kits/PrideTroopers/Poses/" .. setName)
		for name, clip in set do -- own clips only (pairs skips the fallback chain)
			checkClip(setName .. "." .. name, clip)
		end
		check(set.JusticePose, id .. " has no JusticePose clip")
		check(rawget(set, "JusticePose"), id .. " borrows the race Justice Pose instead of striking their own")
		check(not poseOf[set.JusticePose], id .. " shares a Justice Pose with " .. tostring(poseOf[set.JusticePose]))
		poseOf[set.JusticePose] = id
	end
	local troopers = require(SRC .. "Kits/PrideTroopers/Poses/Troopers")
	for name, clip in troopers do
		checkClip("Troopers." .. name, clip)
	end
end)

print(("%d passed, %d failed"):format(passed, failed))
if failed > 0 then
	error("tests failed")
end
