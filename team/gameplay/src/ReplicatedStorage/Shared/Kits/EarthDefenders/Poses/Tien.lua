--!nonstrict
-- Clip set: Tien. The Crane School stance: tall, arms raised wide with open hands like wings, the lead leg light.
-- The finisher is a downward knife-hand chop, the heavy a driving front kick that plants the ground. The beam slot is
-- the Tri-Beam: thumbs and fingers form a triangle in front of the eyes, the stance widens and braces, and the
-- triangle pushes forward. Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, -0.2, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, -15, 0 },
	Neck = { 0, 15, 0 },
	LeftShoulder = { 60, 0, -60 }, -- wings: both arms raised out, hands open
	LeftElbow = { 30, 0, 0 },
	LeftWrist = { -30, 0, 0 },
	RightShoulder = { 40, 0, 70 },
	RightElbow = { 45, 0, 0 },
	RightWrist = { -30, 0, 0 },
	LeftHip = { 20, 0, -8 },
	LeftKnee = { -30, 0, 0 },
	RightHip = { -8, 0, 8 },
	RightKnee = { -18, 0, 0 },
}
local breathe = B.pose(stance, { LeftShoulder = { 64, 0, -62 }, RightShoulder = { 44, 0, 72 } })

local clips = {}
clips.Idle = B.idle(stance, breathe, 180) -- slow and controlled

-- finisher: right knife-hand chop from high to low
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 10,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.1, 0 }, rot = { 0, 0, 0 } },
		Waist = { -10, -30, 0 },
		RightShoulder = { 170, 0, 30 },
		RightElbow = { 40, 0, 0 },
		LeftShoulder = { 60, 0, -30 },
		LeftElbow = { 60, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.5, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 30, 20, 0 },
		Neck = { 15, -15, 0 },
		RightShoulder = { 60, 0, -10 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { 0, 0, -10 },
		LeftShoulder = { 10, 0, -40 },
		LeftElbow = { 50, 0, 0 },
		LeftHip = { 40, 0, -8 },
		LeftKnee = { -50, 0, 0 },
		RightHip = { -25, 0, 8 },
		RightKnee = { -10, 0, 0 },
	},
})

-- heavy: chambered knee, then a driving front kick through the guard
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 12,
	impact = "VFXCommon.Shockwave",
	windup = {
		Root = { pos = { 0, -0.1, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { -5, 0, 0 },
		RightHip = { 100, 0, 0 },
		RightKnee = { -120, 0, 0 },
		LeftKnee = { -15, 0, 0 },
		LeftShoulder = { 40, 0, -50 },
		RightShoulder = { 30, 0, 50 },
	},
	contact = {
		Root = { pos = { 0, -0.1, 0.7 }, rot = { 0, 0, 0 } },
		Waist = { -20, 0, 0 },
		Neck = { 15, 0, 0 },
		RightHip = { 95, 0, 0 },
		RightKnee = { 0, 0, 0 },
		RightAnkle = { -35, 0, 0 },
		LeftHip = { -15, 0, 0 },
		LeftKnee = { -20, 0, 0 },
		LeftShoulder = { 20, 0, -60 },
		RightShoulder = { 0, 0, 60 },
	},
})

-- Tri-Beam: the triangle in front of the eyes, wide braced legs
local triangle = {
	Root = { pos = { 0, -0.55, 0 }, rot = { 0, 0, 0 } },
	Waist = { 5, 0, 0 },
	Neck = { 0, 0, 0 },
	LeftShoulder = { 100, 0, 15 },
	LeftElbow = { 45, 0, 0 },
	LeftWrist = { -60, 0, 0 },
	RightShoulder = { 100, 0, -15 },
	RightElbow = { 45, 0, 0 },
	RightWrist = { -60, 0, 0 },
	LeftHip = { 25, 0, -20 },
	LeftKnee = { -45, 0, 0 },
	RightHip = { -20, 0, 20 },
	RightKnee = { -35, 0, 0 },
}
local strain = B.pose(triangle, { Root = { pos = { 0, -0.62, 0 }, rot = { 0, 0, 0 } }, Neck = { 5, 0, 0 } })
local push = B.pose(triangle, {
	Root = { pos = { 0, -0.6, 0.3 }, rot = { 0, 0, 0 } },
	Waist = { 12, 0, 0 },
	LeftShoulder = { 95, 0, 10 },
	LeftElbow = { 15, 0, 0 },
	RightShoulder = { 95, 0, -10 },
	RightElbow = { 15, 0, 0 },
})
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, triangle, strain, push, 14)

return B.set(clips)
