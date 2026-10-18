--!nonstrict
-- Clip set: Android 18. Composed and unimpressed: left hand on the hip, right arm loose, chin level. The finisher is
-- a high spinning heel kick, the heavy a rising knee. The beam slot is the Power Blitz: the right hand drawn back by
-- the hip to charge, then thrown forward palm-first. Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { -0.1, 0, 0 }, rot = { 0, 0, -2 } },
	Waist = { 0, 12, 2 },
	Neck = { 0, -10, 0 },
	LeftShoulder = { 0, 0, -45 }, -- hand on hip
	LeftElbow = { 95, 0, 0 },
	RightShoulder = { 8, 0, 6 },
	RightElbow = { 12, 0, 0 },
	LeftHip = { 0, 0, -4 },
	RightHip = { 6, 0, 3 },
	RightKnee = { -12, 0, 0 },
}
local breathe = B.pose(stance, { Waist = { 1, 14, 2 }, Neck = { 0, -8, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe, 140)

-- finisher: spinning heel kick, left leg high
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 9,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.2, 0 }, rot = { 0, 0, 0 } },
		Waist = { 0, 70, 0 },
		Neck = { 0, -50, 0 },
		LeftShoulder = { 20, 0, -40 },
		RightShoulder = { 20, 0, 40 },
		LeftHip = { 30, 0, -20 },
		LeftKnee = { -60, 0, 0 },
		RightKnee = { -20, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, 0, 0.3 }, rot = { 0, 0, 0 } },
		Waist = { -15, -60, 0 },
		Neck = { 0, 45, 0 },
		LeftShoulder = { 30, 0, -70 },
		RightShoulder = { 30, 0, 70 },
		LeftHip = { 110, 0, -50 },
		LeftKnee = { 0, 0, 0 },
		LeftAnkle = { 20, 0, 0 },
		RightHip = { -10, 0, 0 },
		RightKnee = { -10, 0, 0 },
	},
})

-- heavy: grab-height rising knee, hands pulling down
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 10,
	windup = {
		Root = { pos = { 0, -0.25, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { -10, 0, 0 },
		LeftShoulder = { 110, 0, -10 },
		LeftElbow = { 30, 0, 0 },
		RightShoulder = { 110, 0, 10 },
		RightElbow = { 30, 0, 0 },
		RightHip = { 20, 0, 0 },
		RightKnee = { -40, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, 0.2, 0.5 }, rot = { 0, 0, 0 } },
		Waist = { 20, 0, 0 },
		Neck = { 10, 0, 0 },
		LeftShoulder = { 60, 0, -10 },
		LeftElbow = { 80, 0, 0 },
		RightShoulder = { 60, 0, 10 },
		RightElbow = { 80, 0, 0 },
		RightHip = { 110, 0, 0 },
		RightKnee = { -120, 0, 0 },
		LeftKnee = { -10, 0, 0 },
	},
})

-- Power Blitz: right hand cocked back at the hip, then thrown forward
local cock = {
	Root = { pos = { 0, -0.2, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, -35, 0 },
	Neck = { 0, 35, 0 },
	RightShoulder = { -30, 0, 20 },
	RightElbow = { 90, 0, 0 },
	RightWrist = { -40, 0, 0 },
	LeftShoulder = { 70, 0, -15 },
	LeftElbow = { 30, 0, 0 },
	LeftHip = { 18, 0, -8 },
	LeftKnee = { -25, 0, 0 },
	RightHip = { -10, 0, 8 },
	RightKnee = { -15, 0, 0 },
}
local cockPulse = B.pose(cock, { RightWrist = { -55, 0, 0 } })
local thrown = {
	Root = { pos = { 0, -0.3, 0.5 }, rot = { 0, 0, 0 } },
	Waist = { 5, 30, 0 },
	Neck = { 0, -25, 0 },
	RightShoulder = { 90, 0, -5 },
	RightElbow = { 0, 0, 0 },
	RightWrist = { -70, 0, 0 },
	LeftShoulder = { 0, 0, -30 },
	LeftElbow = { 40, 0, 0 },
	LeftHip = { 30, 0, -8 },
	LeftKnee = { -35, 0, 0 },
	RightHip = { -20, 0, 8 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, cock, cockPulse, thrown, 8)

return B.set(clips)
