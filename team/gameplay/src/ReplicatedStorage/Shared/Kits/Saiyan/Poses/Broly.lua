--!nonstrict
-- Clip set: Broly. Raised far from any teacher, he fights on instinct: hunched forward, arms hanging wide,
-- weight on the toes. No guard to speak of; the heavy is a two-armed overhead smash, the finisher a shoulder
-- charge. The beam slot is a roar with both arms flung back and the chest forward (his Gigantic Roar).
-- Kale's set builds on this one. Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_saiyan_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, -0.5, 0 }, rot = { 0, 0, 0 } },
	Waist = { 25, 0, 0 },
	Neck = { -20, 0, 0 },
	LeftShoulder = { 20, 0, -35 },
	LeftElbow = { 25, 0, 0 },
	RightShoulder = { 20, 0, 35 },
	RightElbow = { 25, 0, 0 },
	LeftHip = { 20, 0, -15 },
	LeftKnee = { -35, 0, 0 },
	LeftAnkle = { 15, 0, 0 },
	RightHip = { 10, 0, 15 },
	RightKnee = { -35, 0, 0 },
	RightAnkle = { 15, 0, 0 },
}
-- the breath is heavy: shoulders rise and fall
local breathe = B.pose(stance, {
	Root = { pos = { 0, -0.62, 0 }, rot = { 0, 0, 0 } },
	Waist = { 30, 0, 0 },
	LeftShoulder = { 25, 0, -40 },
	RightShoulder = { 25, 0, 40 },
})

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- finisher: lowered-shoulder charge through the target
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 12,
	hitSound = "Hit_Finisher",
	impact = "VFXCommon.DebrisBurst",
	windup = {
		Root = { pos = { 0, -0.7, -0.4 }, rot = { 0, 0, 0 } },
		Waist = { 35, 30, 0 },
		Neck = { -25, -20, 0 },
		LeftShoulder = { -20, 0, -30 },
		RightShoulder = { 10, 0, 50 },
		RightElbow = { 60, 0, 0 },
		LeftHip = { 35, 0, -10 },
		LeftKnee = { -55, 0, 0 },
		RightHip = { -20, 0, 10 },
		RightKnee = { -40, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.55, 0.9 }, rot = { 0, 0, 0 } },
		Waist = { 40, -35, 0 },
		Neck = { -30, 25, 0 },
		LeftShoulder = { 30, 0, -60 },
		LeftElbow = { 80, 0, 0 },
		RightShoulder = { -30, 0, 25 },
		LeftHip = { -25, 0, -10 },
		LeftKnee = { -15, 0, 0 },
		RightHip = { 45, 0, 10 },
		RightKnee = { -50, 0, 0 },
	},
})

-- heavy: both arms high, then a full-body smash into the ground
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 16, -- slow, readable, enormous
	recovery = 22,
	impact = "VFXCommon.GroundCrack;VFXCommon.DebrisBurst",
	windup = {
		Root = { pos = { 0, 0.3, -0.3 }, rot = { 0, 0, 0 } },
		Waist = { -30, 0, 0 },
		Neck = { -25, 0, 0 },
		LeftShoulder = { 175, 0, 25 },
		RightShoulder = { 175, 0, -25 },
		LeftElbow = { 20, 0, 0 },
		RightElbow = { 20, 0, 0 },
		LeftHip = { 0, 0, -15 },
		RightHip = { 0, 0, 15 },
	},
	contact = {
		Root = { pos = { 0, -1.0, 0.7 }, rot = { 0, 0, 0 } },
		Waist = { 50, 0, 0 },
		Neck = { 15, 0, 0 },
		LeftShoulder = { 40, 0, 15 },
		RightShoulder = { 40, 0, -15 },
		LeftHip = { 55, 0, -20 },
		LeftKnee = { -75, 0, 0 },
		RightHip = { 20, 0, 20 },
		RightKnee = { -70, 0, 0 },
	},
})

-- Gigantic Roar: arms thrown back, chest out, head up
local gather = {
	Root = { pos = { 0, -0.6, -0.2 }, rot = { 0, 0, 0 } },
	Waist = { -25, 0, 0 },
	Neck = { -35, 0, 0 },
	LeftShoulder = { -45, 0, -55 },
	RightShoulder = { -45, 0, 55 },
	LeftElbow = { 40, 0, 0 },
	RightElbow = { 40, 0, 0 },
	LeftHip = { 25, 0, -18 },
	LeftKnee = { -45, 0, 0 },
	RightHip = { 15, 0, 18 },
	RightKnee = { -45, 0, 0 },
}
local pulse = B.pose(gather, { Waist = { -32, 0, 0 }, Neck = { -42, 0, 0 } })
local roar = {
	Root = { pos = { 0, -0.5, 0.3 }, rot = { 0, 0, 0 } },
	Waist = { 15, 0, 0 },
	Neck = { 5, 0, 0 },
	LeftShoulder = { -60, 0, -70 },
	RightShoulder = { -60, 0, 70 },
	LeftElbow = { 15, 0, 0 },
	RightElbow = { 15, 0, 0 },
	LeftHip = { 35, 0, -18 },
	LeftKnee = { -50, 0, 0 },
	RightHip = { 5, 0, 18 },
	RightKnee = { -30, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, gather, pulse, roar, 16)

return B.set(clips)
