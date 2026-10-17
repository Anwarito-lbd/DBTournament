--!nonstrict
-- Clip set: Caulifla. A street-gang boss who learned to fight by fighting: loose, cocky, one hand on the hip and
-- the chin up. Her strikes are wild and fast (short anticipation): a spinning back-kick finisher and a jumping
-- axe kick. The beam slot is the Crush Cannon, fired one-handed from the hip. Kefla's set builds on this one.
-- Clips not listed here fall back to Goku's set, then Shared.
local B = require(script.Parent.Parent:WaitForChild("ClipBuilder"))

local stance = {
	Root = { pos = { 0, -0.1, 0 }, rot = { 0, 0, 0 } },
	Waist = { -5, 15, 0 },
	Neck = { -12, -10, 0 }, -- chin up
	LeftShoulder = { -10, 0, -40 }, -- hand on hip
	LeftElbow = { 100, 0, 0 },
	RightShoulder = { 35, 0, 15 },
	RightElbow = { 70, 0, 0 },
	LeftHip = { 5, 0, -10 },
	RightHip = { 0, 0, 12 },
	RightKnee = { -8, 0, 0 },
}
local breathe = B.pose(stance, { Waist = { -5, 22, 0 }, Neck = { -15, -14, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- finisher: spinning back-kick
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 7,
	hold = 6,
	recovery = 14,
	swing = "Swing",
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } },
		Waist = { 0, 90, 0 },
		Neck = { 0, -70, 0 },
		LeftShoulder = { 40, 0, -50 },
		RightShoulder = { 40, 0, 50 },
		LeftHip = { 10, 0, 0 },
		LeftKnee = { -30, 0, 0 },
		RightHip = { 30, 0, 0 },
		RightKnee = { -70, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, 0, 0.4 }, rot = { 0, 0, 0 } },
		Waist = { -20, 170, 0 },
		Neck = { 10, -150, 0 },
		LeftShoulder = { 20, 0, -70 },
		RightShoulder = { 20, 0, 70 },
		LeftHip = { 0, 0, 0 },
		LeftKnee = { -15, 0, 0 },
		RightHip = { -80, 0, 10 },
		RightKnee = { -5, 0, 0 },
	},
})

-- heavy: jumping axe kick from overhead
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 9,
	impact = "VFXCommon.Shockwave",
	windup = {
		Root = { pos = { 0, 0.6, 0 }, rot = { 0, 0, 0 } },
		Waist = { -25, 0, 0 },
		LeftShoulder = { 60, 0, -60 },
		RightShoulder = { 60, 0, 60 },
		RightHip = { 150, 0, 0 },
		RightKnee = { -5, 0, 0 },
		LeftHip = { -10, 0, 0 },
		LeftKnee = { -30, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.3, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 25, 0, 0 },
		LeftShoulder = { 30, 0, -50 },
		RightShoulder = { 30, 0, 50 },
		RightHip = { 40, 0, 0 },
		RightKnee = { -10, 0, 0 },
		LeftHip = { -15, 0, 0 },
		LeftKnee = { -40, 0, 0 },
	},
})

-- Crush Cannon: no ceremony, a quick wind-up at the hip and a one-armed shot
local gather = {
	Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, 35, 0 },
	Neck = { 0, -30, 0 },
	LeftShoulder = { 60, 0, -15 },
	RightShoulder = { -15, 0, 30 },
	RightElbow = { 95, 0, 0 },
	RightWrist = { -30, 0, 0 },
	LeftHip = { 15, 0, -10 },
	LeftKnee = { -20, 0, 0 },
	RightKnee = { -20, 0, 0 },
}
local pulse = B.pose(gather, { Waist = { 0, 40, 0 } })
local shot = {
	Root = { pos = { 0, -0.3, 0.35 }, rot = { 0, 0, 0 } },
	Waist = { 10, -30, 0 },
	Neck = { -10, 25, 0 },
	LeftShoulder = { -10, 0, -40 },
	LeftElbow = { 100, 0, 0 },
	RightShoulder = { 92, 0, 0 },
	RightWrist = { -70, 0, 0 },
	LeftHip = { 25, 0, -10 },
	LeftKnee = { -25, 0, 0 },
	RightHip = { -15, 0, 10 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, gather, pulse, shot, 6)

return B.set(clips)
