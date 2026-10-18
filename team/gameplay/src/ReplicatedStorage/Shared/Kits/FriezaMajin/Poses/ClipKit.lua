--!nonstrict
-- ClipKit (FriezaMajin kit): builds clips in the team/animation/poses format (see team/animation/README.md) from a
-- few key poses, so each clip set below stays a page of poses instead of thousands of keyframe lines.
-- A pose spec uses the generator's anatomical keys (team/animation/poses/gen_poses.py): root = {x, y, z} studs on the
-- Root joint, R/W/N = Root/Waist/Neck rotation, and side keys LS/LE/LWr/LH/LK/LA, RS/RE/RWr/RH/RK/RA as
-- {rx, ry, rz} degrees. Left-side ry/rz are mirrored like the generator does, so LS = RS gives a symmetric pose.
-- Conventions: limbs rx > 0 swing forward, arm rz > 0 raises outward, elbow rx > 0 bends, knee rx < 0 bends.
-- Not a clip set: FightAnimator only asks this folder for the set a kit names.
local K = {}

K.JOINTS = { "Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
	"RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle" }
local CENTER = { R = "Root", W = "Waist", N = "Neck" }
local PART = { S = "Shoulder", E = "Elbow", Wr = "Wrist", H = "Hip", K = "Knee", A = "Ankle" }

-- spec -> {[joint] = {pos, rot}} with all 15 joints present (PosePlayer reads every joint on every key)
local function expand(spec: any): any
	local out = {}
	for _, j in K.JOINTS do
		out[j] = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } }
	end
	for key, v in spec do
		if key == "root" then
			out.Root.pos = { v[1], v[2], v[3] }
		elseif CENTER[key] then
			out[CENTER[key]].rot = { v[1], v[2], v[3] }
		else
			local side = if string.sub(key, 1, 1) == "L" then "Left" else "Right"
			local part = PART[string.sub(key, 2)]
			assert(part, "ClipKit: unknown pose key " .. tostring(key))
			local mirror = if side == "Left" then -1 else 1
			out[side .. part].rot = { v[1], v[2] * mirror, v[3] * mirror }
		end
	end
	return out
end

-- a copy of base with some keys replaced
function K.pose(base: any, over: any?): any
	local o = table.clone(base)
	for k, v in over or {} do
		o[k] = v
	end
	return o
end

-- frames: { {t, ease, spec, markers?}, ... } in frames at 60 fps
function K.clip(length: number, looped: boolean, priority: string, frames: { any }): any
	local kfs = {}
	for i, fr in frames do
		kfs[i] = { t = fr[1], ease = fr[2], markers = fr[4], poses = expand(fr[3]) }
	end
	return { fps = 60, length = length, looped = looped, priority = priority, keyframes = kfs }
end

-- a breathing idle: a -> b -> a over two seconds
function K.idle(a: any, b: any): any
	return K.clip(120, true, "Idle", { { 0, "Sine", a }, { 60, "Sine", b }, { 120, "Sine", a } })
end

-- a Heavy-style strike: anticipation (12f), one-frame smear, contact, hold, recovery (VFX_QUALITY_BAR timings)
function K.strike(stance: any, windup: any, contact: any): any
	return K.clip(42, false, "Action", {
		{ 0, "Linear", stance },
		{ 12, "CubicIn", windup, { sound = "Swing_Heavy" } },
		{ 13, "Linear", contact, { vfx = "VFXCommon.Afterimage:0.5" } },
		{ 14, "Linear", contact, { hit = { tier = "Heavy", hitstop = "Heavy" }, sound = "Hit_Heavy" } },
		{ 24, "Constant", contact },
		{ 42, "QuadOut", stance },
	})
end

-- the signature-slot pair: Charge (gather, then pulse while it builds) and Fire (release, hold, recover)
function K.beam(stance: any, gather: any, pulse: any, fire: any): (any, any)
	local charge = K.clip(90, false, "Action4", {
		{ 0, "Linear", stance },
		{ 14, "CubicIn", gather, { sound = "Charge" } },
		{ 45, "Sine", pulse },
		{ 90, "Sine", gather },
	})
	local release = K.clip(90, false, "Action4", {
		{ 0, "Linear", gather },
		{ 6, "CubicOut", fire, { sound = "Kamehameha_Fire" } },
		{ 60, "Constant", fire },
		{ 90, "QuadOut", stance },
	})
	return charge, release
end

-- Transform_SSJ is both the transformation clip and the looped power-up stance (AnimeStyle plays it with
-- loop = true while charging), so it pulses coil -> release -> coil and loops without a jump
function K.surge(coil: any, release: any): any
	return K.clip(120, false, "Action3", {
		{ 0, "Linear", coil },
		{ 30, "BackOut", release, { sound = "AuraBurst" } },
		{ 60, "Sine", coil },
		{ 90, "BackOut", release },
		{ 120, "Sine", coil },
	})
end

-- the finished set: clips not defined here come from `parent` (another set), then FightAnimator's fallbacks
function K.set(clips: any, parent: any?): any
	return if parent then setmetatable(clips, { __index = parent }) else clips
end

-- the shared clip sets in ReplicatedStorage.Poses (team/animation/poses); nil when absent
local function shared(name: string): any
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Poses")
	local m = folder and folder:FindFirstChild(name)
	if not m then return nil end
	local ok, res = pcall(require, m)
	return if ok then res else nil
end
-- `script` is absent in the plain-Luau data check (tests/kit_friezamajin_tests.luau): load by path there
function K.friezaSet(): any
	return if script then shared("Frieza") else require("../../../../../../../animation/poses/Frieza")
end
function K.sharedSet(): any
	local s = if script then shared("Shared") else require("../../../../../../../animation/poses/Shared")
	return s and s.clips
end

return K
