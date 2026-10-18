--!nonstrict
-- Clip set: Piccolo. Tall and unhurried: arms folded across the chest at rest, weight back. The finisher is a high
-- roundhouse kick, the heavy a lunging straight punch at full reach (a Namekian arm goes further than you expect).
-- The beam slot is the Special Beam Cannon: two fingers of the right hand at the forehead while the ki gathers,
-- then the arm snaps out straight at head height. Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, -0.1, 0 }, rot = { 0, 0, 0 } },
	Waist = { -3, -10, 0 },
	Neck = { -4, 10, 0 },
	LeftShoulder = { 75, 0, 25 }, -- arms folded: each forearm across the chest
	LeftElbow = { 115, 0, 0 },
	RightShoulder = { 70, 0, -25 },
	RightElbow = { 120, 0, 0 },
	LeftHip = { 6, 0, -6 },
	LeftKnee = { -8, 0, 0 },
	RightHip = { -4, 0, 6 },
	RightKnee = { -6, 0, 0 },
}
local breathe = B.pose(stance, { Root = { pos = { 0, -0.14, 0 }, rot = { 0, 0, 0 } }, Waist = { -1, -10, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe, 150)

-- finisher: high roundhouse kick with the right leg, arms thrown wide for balance
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 10,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } },
		Waist = { 0, 40, 0 },
		Neck = { 0, -30, 0 },
		LeftShoulder = { 40, 0, -50 },
		LeftElbow = { 40, 0, 0 },
		RightShoulder = { 20, 0, 50 },
		RightElbow = { 30, 0, 0 },
		RightHip = { 50, 0, 20 },
		RightKnee = { -90, 0, 0 },
		LeftKnee = { -25, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.2, 0.4 }, rot = { 0, 0, 0 } },
		Waist = { -10, -50, 0 },
		Neck = { 0, 40, 0 },
		LeftShoulder = { 30, 0, -70 },
		LeftElbow = { 20, 0, 0 },
		RightShoulder = { 10, 0, 60 },
		RightElbow = { 15, 0, 0 },
		RightHip = { 100, 0, 55 },
		RightKnee = { -5, 0, 0 },
		LeftHip = { -10, 0, 0 },
		LeftKnee = { -15, 0, 0 },
	},
})

-- heavy: a long lunging straight right, the whole body behind it
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 12,
	impact = "VFXCommon.Shockwave",
	windup = {
		Root = { pos = { 0, -0.4, -0.3 }, rot = { 0, 0, 0 } },
		Waist = { 5, -45, 0 },
		Neck = { 0, 40, 0 },
		RightShoulder = { 40, 0, 30 },
		RightElbow = { 120, 0, 0 },
		LeftShoulder = { 80, 0, -10 },
		LeftElbow = { 40, 0, 0 },
		LeftHip = { 25, 0, -8 },
		LeftKnee = { -35, 0, 0 },
		RightKnee = { -25, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.6, 1.1 }, rot = { 0, 0, 0 } },
		Waist = { 10, 35, 0 },
		Neck = { -5, -30, 0 },
		RightShoulder = { 92, 0, -5 },
		RightElbow = { 0, 0, 0 },
		LeftShoulder = { 30, 0, -30 },
		LeftElbow = { 70, 0, 0 },
		LeftHip = { 45, 0, -8 },
		LeftKnee = { -55, 0, 0 },
		RightHip = { -35, 0, 8 },
		RightKnee = { -5, 0, 0 },
	},
})

-- Special Beam Cannon: fingers to the brow, left arm low and back, a wide braced stance
local brow = {
	Root = { pos = { 0, -0.35, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, -20, 0 },
	Neck = { 5, 20, 0 },
	RightShoulder = { 160, 0, -25 },
	RightElbow = { 140, 0, 0 },
	RightWrist = { -20, 0, 0 },
	LeftShoulder = { -20, 0, -25 },
	LeftElbow = { 20, 0, 0 },
	LeftHip = { 20, 0, -12 },
	LeftKnee = { -30, 0, 0 },
	RightHip = { -15, 0, 12 },
	RightKnee = { -20, 0, 0 },
}
local browPulse = B.pose(brow, { Neck = { 10, 20, 0 }, Root = { pos = { 0, -0.4, 0 }, rot = { 0, 0, 0 } } })
local point = {
	Root = { pos = { 0, -0.4, 0.3 }, rot = { 0, 0, 0 } },
	Waist = { 5, 15, 0 },
	Neck = { 0, -15, 0 },
	RightShoulder = { 95, 0, 0 },
	RightElbow = { 0, 0, 0 },
	RightWrist = { 0, 0, 0 },
	LeftShoulder = { -25, 0, -30 },
	LeftElbow = { 25, 0, 0 },
	LeftHip = { 25, 0, -12 },
	LeftKnee = { -35, 0, 0 },
	RightHip = { -20, 0, 12 },
	RightKnee = { -15, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, brow, browPulse, point, 14)

return B.set(clips)
