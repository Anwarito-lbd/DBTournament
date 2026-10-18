--!nonstrict
-- Clip set: Android 17. Relaxed to the point of insolence: weight on one hip, arms loose and low, head tilted. The
-- finisher is a flat push kick, the heavy a short barrier-sheathed straight. The beam slot is his barrier trap: the
-- right palm opens toward the target while the left stays low, no wind-up, no strain. Clips not listed here fall
-- back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0.15, -0.05, 0 }, rot = { 0, 0, 3 } }, -- hip cocked
	Waist = { 0, -15, -3 },
	Neck = { 0, 15, 6 },
	LeftShoulder = { 10, 0, -8 },
	LeftElbow = { 15, 0, 0 },
	RightShoulder = { 5, 0, 10 },
	RightElbow = { 20, 0, 0 },
	LeftHip = { 5, 0, -4 },
	LeftKnee = { -12, 0, 0 },
	RightHip = { 0, 0, 4 },
}
local breathe = B.pose(stance, { Neck = { 0, 18, 4 }, Waist = { 0, -12, -3 } })

local clips = {}
clips.Idle = B.idle(stance, breathe, 160)

-- finisher: a flat push kick with the right foot, hands still low
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 8,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.15, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { -10, -10, 0 },
		RightHip = { 85, 0, 5 },
		RightKnee = { -100, 0, 0 },
		LeftKnee = { -15, 0, 0 },
		LeftShoulder = { 20, 0, -20 },
		RightShoulder = { 15, 0, 20 },
	},
	contact = {
		Root = { pos = { 0, -0.1, 0.5 }, rot = { 0, 0, 0 } },
		Waist = { -20, 0, 0 },
		Neck = { 10, 0, 0 },
		RightHip = { 95, 0, 0 },
		RightKnee = { -5, 0, 0 },
		RightAnkle = { -30, 0, 0 },
		LeftHip = { -10, 0, 0 },
		LeftKnee = { -10, 0, 0 },
		LeftShoulder = { 30, 0, -30 },
		RightShoulder = { -10, 0, 25 },
	},
})

-- heavy: compact straight right with the barrier on the fist (EarthHeavyVFX draws the shell)
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 10,
	windup = {
		Root = { pos = { 0, -0.3, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { 0, -40, 0 },
		Neck = { 0, 35, 0 },
		RightShoulder = { 30, 0, 25 },
		RightElbow = { 110, 0, 0 },
		LeftShoulder = { 60, 0, -15 },
		LeftElbow = { 60, 0, 0 },
		LeftHip = { 20, 0, -6 },
		LeftKnee = { -25, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.35, 0.7 }, rot = { 0, 0, 0 } },
		Waist = { 5, 30, 0 },
		Neck = { 0, -25, 0 },
		RightShoulder = { 90, 0, -5 },
		RightElbow = { 0, 0, 0 },
		LeftShoulder = { 20, 0, -25 },
		LeftElbow = { 50, 0, 0 },
		LeftHip = { 30, 0, -6 },
		LeftKnee = { -40, 0, 0 },
		RightHip = { -25, 0, 6 },
	},
})

-- barrier trap: the right palm opens at the target, almost lazily
local palm = {
	Root = { pos = { 0, -0.1, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, 10, 0 },
	Neck = { 0, -10, 0 },
	RightShoulder = { 70, 0, 10 },
	RightElbow = { 40, 0, 0 },
	RightWrist = { -50, 0, 0 },
	LeftShoulder = { 5, 0, -10 },
	LeftElbow = { 20, 0, 0 },
	LeftHip = { 8, 0, -6 },
	LeftKnee = { -10, 0, 0 },
}
local palmPulse = B.pose(palm, { RightElbow = { 30, 0, 0 } })
local release = B.pose(palm, {
	RightShoulder = { 90, 0, 0 },
	RightElbow = { 5, 0, 0 },
	RightWrist = { -70, 0, 0 },
	Root = { pos = { 0, -0.15, 0.2 }, rot = { 0, 0, 0 } },
})
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, palm, palmPulse, release, 8)

return B.set(clips)
