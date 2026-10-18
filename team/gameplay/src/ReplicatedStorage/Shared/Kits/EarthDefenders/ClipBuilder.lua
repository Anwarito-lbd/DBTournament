--!nonstrict
-- ClipBuilder: compact authoring for the Earth defenders' clip sets (Kits/EarthDefenders/Poses). Same output and
-- conventions as the Saiyan kit's builder, so the sets read alike: the clip format of team/animation/poses/*.lua
-- (README "Keyframe pose data"): {fps, length, looped, priority, keyframes = {{t, ease, markers, poses =
-- {[joint] = {pos, rot}}}}}, every one of the 15 R15 joints on every key, degrees, joint-local.
-- A pose spec only names the joints that move: { Waist = {rx, ry, rz}, Root = {pos = {x, y, z}, rot = {rx, ry, rz}} }.
-- Angles are design values (sign conventions of the Goku/Vegeta sets): shoulder +X raises the arm forward, elbow +X
-- bends it, hip +X lifts the leg forward, knee -X bends it; right arm out = +Z, left arm out = -Z.
-- Markers are cosmetic only (AnimMarkerRouter primitives and AudioRegistry sounds); hits are decided by the server.
local B = {}

B.JOINTS = { "Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow",
	"RightWrist", "LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle" }

-- quality-bar timings @60 fps (team/animation/VFX_QUALITY_BAR.md section 1)
B.TIMING = { anticipation = 12, hold = 8, recovery = 18 }

-- a full 15-joint pose from a sparse spec; `over` (optional) is laid on top of `spec`
function B.pose(spec: any, over: any?): any
	local out = {}
	for _, j in B.JOINTS do
		local s = (over and over[j]) or (spec and spec[j])
		if type(s) == "table" and s.rot then
			out[j] = { pos = s.pos or { 0, 0, 0 }, rot = s.rot }
		elseif type(s) == "table" then
			out[j] = { pos = { 0, 0, 0 }, rot = { s[1] or 0, s[2] or 0, s[3] or 0 } }
		else
			out[j] = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } }
		end
	end
	return out
end

-- keys = { {t, ease, spec, markers?}, ... } in frame order
function B.clip(length: number, priority: string, keys: { any }, looped: boolean?): any
	local kfs = {}
	for _, k in keys do
		table.insert(kfs, { t = k[1], ease = k[2], markers = k[4], poses = B.pose(k[3]) })
	end
	return { fps = 60, length = length, looped = looped == true, priority = priority, keyframes = kfs }
end

-- breathing idle: stance A, B, A over `frames` (default two seconds)
function B.idle(a: any, b: any, frames: number?): any
	local n = frames or 120
	return B.clip(n, "Idle", { { 0, "Sine", a }, { n / 2, "Sine", b }, { n, "Sine", a } }, true)
end

-- one strike: anticipation (CubicIn) -> 1f smear with afterimage -> contact frame carrying `hit` -> Constant hold
-- -> QuadOut recovery into the stance. o = {stance, windup, contact, tier, anticipation?, hold?, recovery?,
-- swing?, hitSound?, impact? (extra vfx marker string on contact)}
function B.strike(o: any): any
	local a = o.anticipation or B.TIMING.anticipation
	local hold = o.hold or B.TIMING.hold
	local rec = o.recovery or B.TIMING.recovery
	local contactT = a + 2
	local length = contactT + hold + rec
	local vfx = "VFXCommon.ImpactFrame:invert:" .. (if o.tier == "Light" then "1" else "2")
	if o.impact then vfx = vfx .. ";" .. o.impact end
	return B.clip(length, "Action", {
		{ 0, "Linear", o.stance },
		{ a, "CubicIn", o.windup, { sound = o.swing or "Swing_Heavy" } },
		{ a + 1, "Linear", o.contact, { vfx = "VFXCommon.Afterimage:0.5" } },
		{ contactT, "Linear", o.contact, {
			hit = { tier = o.tier or "Heavy", hitstop = o.tier or "Heavy" },
			vfx = vfx,
			sound = o.hitSound or "Hit_Heavy",
		} },
		{ contactT + hold, "Constant", o.contact },
		{ length, "QuadOut", o.stance },
	})
end

-- signature stance pair for the Kamehameha slot (FightAnimator.beamClips plays Kamehameha_Charge then _Fire):
-- charge = gather pose with a slow pulse; fire = snap into the release pose, hold, recover to the stance
function B.beam(stance: any, gather: any, pulse: any, release: any, chargeFrames: number?): (any, any)
	local cf = chargeFrames or 12
	local charge = B.clip(90, "Action4", {
		{ 0, "Linear", stance },
		{ cf, "CubicIn", gather, { sound = "Kamehameha_Charge" } },
		{ 50, "Sine", pulse },
		{ 90, "Sine", gather },
	})
	local fire = B.clip(90, "Action4", {
		{ 0, "Linear", gather },
		{ 4, "CubicOut", release, { sound = "Kamehameha_Fire", vfx = "VFXCommon.SpeedLines:0.4" } },
		{ 60, "Constant", release },
		{ 90, "QuadOut", stance },
	})
	return charge, fire
end

-- a clip set: FightAnimator reads set[name] or set.clips[name]; `base` (another set) fills clips this one lacks
function B.set(clips: { [string]: any }, base: any?): any
	local merged = {}
	if base then
		for k, v in (base.clips or base) do merged[k] = v end
	end
	for k, v in clips do merged[k] = v end
	return { clips = merged }
end

return B
