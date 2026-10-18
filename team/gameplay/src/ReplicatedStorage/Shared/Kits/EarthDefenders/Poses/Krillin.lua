--!nonstrict
-- Clip set: Krillin. A low Turtle School guard: left hand open and forward, right fist chambered at the ribs, knees
-- bent and bouncing. The finisher is a jumping elbow, the heavy a two-palm shove from the hips. The beam slot is the
-- Destructo Disc: right arm straight up, palm to the sky while the disc spins up, then a sidearm throw. Clips not
-- listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, -0.45, 0 }, rot = { 0, 0, 0 } },
	Waist = { 8, -25, 0 },
	Neck = { -6, 25, 0 },
	LeftShoulder = { 75, 0, -10 },
	LeftElbow = { 50, 0, 0 },
	LeftWrist = { -30, 0, 0 },
	RightShoulder = { 20, 0, 15 },
	RightElbow = { 110, 0, 0 },
	LeftHip = { 25, 0, -12 },
	LeftKnee = { -40, 0, 0 },
	RightHip = { -10, 0, 12 },
	RightKnee = { -35, 0, 0 },
}
local bounce = B.pose(stance, { Root = { pos = { 0, -0.55, 0 }, rot = { 0, 0, 0 } }, LeftKnee = { -46, 0, 0 },
	RightKnee = { -40, 0, 0 } })

local clips = {}
clips.Idle = B.idle(stance, bounce, 80) -- quicker breathing: always ready to move

-- finisher: hop and drive the right elbow down
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 8,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, 0.4, 0 }, rot = { 0, 0, 0 } },
		Waist = { -10, -30, 0 },
		RightShoulder = { 150, 0, 30 },
		RightElbow = { 130, 0, 0 },
		LeftShoulder = { 40, 0, -30 },
		LeftHip = { 60, 0, -10 },
		LeftKnee = { -90, 0, 0 },
		RightHip = { 30, 0, 10 },
		RightKnee = { -70, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, 0.1, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 30, 20, 0 },
		Neck = { 10, -15, 0 },
		RightShoulder = { 70, 0, -20 },
		RightElbow = { 140, 0, 0 },
		LeftShoulder = { 20, 0, -40 },
		LeftHip = { 40, 0, -10 },
		LeftKnee = { -60, 0, 0 },
		RightHip = { 10, 0, 10 },
		RightKnee = { -50, 0, 0 },
	},
})

-- heavy: two palms driven from the hips into the guard
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 12,
	windup = {
		Root = { pos = { 0, -0.6, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { 0, 0, 0 },
		LeftShoulder = { -20, 0, -20 },
		LeftElbow = { 100, 0, 0 },
		RightShoulder = { -20, 0, 20 },
		RightElbow = { 100, 0, 0 },
		LeftHip = { 30, 0, -12 },
		LeftKnee = { -55, 0, 0 },
		RightKnee = { -45, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.5, 0.8 }, rot = { 0, 0, 0 } },
		Waist = { 15, 0, 0 },
		LeftShoulder = { 90, 0, 10 },
		LeftElbow = { 5, 0, 0 },
		LeftWrist = { -70, 0, 0 },
		RightShoulder = { 90, 0, -10 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { -70, 0, 0 },
		LeftHip = { 45, 0, -12 },
		LeftKnee = { -50, 0, 0 },
		RightHip = { -30, 0, 12 },
		RightKnee = { -10, 0, 0 },
	},
})

-- Destructo Disc: palm up over the head, then a flat sidearm throw
local overhead = {
	Root = { pos = { 0, -0.35, 0 }, rot = { 0, 0, 0 } },
	Waist = { -8, -15, 0 },
	Neck = { -10, 15, 0 },
	RightShoulder = { 175, 0, 10 },
	RightElbow = { 10, 0, 0 },
	RightWrist = { 60, 0, 0 },
	LeftShoulder = { 40, 0, -35 },
	LeftElbow = { 40, 0, 0 },
	LeftHip = { 20, 0, -12 },
	LeftKnee = { -30, 0, 0 },
	RightHip = { -12, 0, 12 },
	RightKnee = { -25, 0, 0 },
}
local spin = B.pose(overhead, { Neck = { -15, 15, 0 }, RightShoulder = { 178, 0, 5 } })
local throw = {
	Root = { pos = { 0, -0.45, 0.5 }, rot = { 0, 0, 0 } },
	Waist = { 10, 40, 0 },
	Neck = { 0, -30, 0 },
	RightShoulder = { 85, 0, -30 },
	RightElbow = { 10, 0, 0 },
	RightWrist = { 0, 0, -20 },
	LeftShoulder = { 20, 0, -45 },
	LeftElbow = { 30, 0, 0 },
	LeftHip = { 35, 0, -12 },
	LeftKnee = { -45, 0, 0 },
	RightHip = { -25, 0, 12 },
	RightKnee = { -15, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, overhead, spin, throw, 10)

return B.set(clips)
