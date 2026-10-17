--!nonstrict
-- Clip set: Gohan. Piccolo's student: low, wide stance with the lead hand open and forward; strikes come in as
-- a rising knee and a two-handed hammer. The beam slot is the Masenko, both palms stacked above the forehead
-- and thrown down-forward. Clips not listed here fall back to Goku's set, then Shared.
local B = require(script.Parent.Parent:WaitForChild("ClipBuilder"))

local stance = {
	Root = { pos = { 0, -0.35, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, -25, 0 },
	Neck = { 0, 20, 0 },
	LeftShoulder = { 65, 0, -12 },
	LeftElbow = { 25, 0, 0 },
	LeftWrist = { 0, 0, -15 },
	RightShoulder = { 30, 0, 18 },
	RightElbow = { 95, 0, 0 },
	LeftHip = { 20, 0, -10 },
	LeftKnee = { -30, 0, 0 },
	LeftAnkle = { 10, 0, 0 },
	RightHip = { -12, 0, 12 },
	RightKnee = { -30, 0, 0 },
	RightAnkle = { 12, 0, 0 },
}
local breathe = B.pose(stance, { Root = { pos = { 0, -0.42, 0 }, rot = { 0, 0, 0 } }, Waist = { 3, -25, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- finisher: rising knee into the chest
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 10,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.5, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { -10, 0, 0 },
		LeftShoulder = { 40, 0, -30 },
		RightShoulder = { 40, 0, 30 },
		LeftElbow = { 60, 0, 0 },
		RightElbow = { 60, 0, 0 },
		RightHip = { -25, 0, 0 },
		RightKnee = { -50, 0, 0 },
		LeftHip = { 10, 0, 0 },
		LeftKnee = { -25, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, 0.4, 0.5 }, rot = { 0, 0, 0 } },
		Waist = { 15, 0, 0 },
		Neck = { -10, 0, 0 },
		LeftShoulder = { 70, 0, -20 },
		RightShoulder = { 70, 0, 20 },
		LeftElbow = { 70, 0, 0 },
		RightElbow = { 70, 0, 0 },
		RightHip = { 100, 0, 0 },
		RightKnee = { -110, 0, 0 },
		LeftHip = { -10, 0, 0 },
		LeftKnee = { -10, 0, 0 },
	},
})

-- heavy: both fists raised overhead, hammered down (the anger he keeps under the calm)
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	impact = "VFXCommon.GroundCrack",
	windup = {
		Root = { pos = { 0, 0.1, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { -20, 0, 0 },
		Neck = { -10, 0, 0 },
		LeftShoulder = { 170, 0, 10 },
		RightShoulder = { 170, 0, -10 },
		LeftElbow = { 30, 0, 0 },
		RightElbow = { 30, 0, 0 },
		LeftHip = { 5, 0, -8 },
		RightHip = { -5, 0, 8 },
	},
	contact = {
		Root = { pos = { 0, -0.6, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 35, 0, 0 },
		Neck = { 10, 0, 0 },
		LeftShoulder = { 60, 0, 12 },
		RightShoulder = { 60, 0, -12 },
		LeftElbow = { 5, 0, 0 },
		RightElbow = { 5, 0, 0 },
		LeftHip = { 35, 0, -10 },
		LeftKnee = { -45, 0, 0 },
		RightHip = { -20, 0, 10 },
		RightKnee = { -20, 0, 0 },
	},
})

-- Masenko: palms stacked over the forehead, then thrown forward and down
local overhead = {
	Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } },
	Waist = { -15, 0, 0 },
	Neck = { -12, 0, 0 },
	LeftShoulder = { 165, 0, 15 },
	RightShoulder = { 165, 0, -15 },
	LeftElbow = { 40, 0, 0 },
	RightElbow = { 40, 0, 0 },
	LeftWrist = { -30, 0, 0 },
	RightWrist = { -30, 0, 0 },
	LeftHip = { 15, 0, -12 },
	LeftKnee = { -20, 0, 0 },
	RightHip = { -15, 0, 12 },
	RightKnee = { -20, 0, 0 },
}
local overheadPulse = B.pose(overhead, { Root = { pos = { 0, -0.38, 0 }, rot = { 0, 0, 0 } }, Waist = { -18, 0, 0 } })
local thrown = {
	Root = { pos = { 0, -0.45, 0.3 }, rot = { 0, 0, 0 } },
	Waist = { 20, 0, 0 },
	Neck = { 5, 0, 0 },
	LeftShoulder = { 95, 0, 8 },
	RightShoulder = { 95, 0, -8 },
	LeftWrist = { -60, 0, 0 },
	RightWrist = { -60, 0, 0 },
	LeftHip = { 30, 0, -12 },
	LeftKnee = { -35, 0, 0 },
	RightHip = { -25, 0, 12 },
	RightKnee = { -15, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, overhead, overheadPulse, thrown, 10)

return B.set(clips)
