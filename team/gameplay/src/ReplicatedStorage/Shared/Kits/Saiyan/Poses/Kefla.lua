--!nonstrict
-- Clip set: Kefla. Caulifla's swagger with Kale's raw power: she inherits Caulifla's fast finisher, stands
-- squarer and taller with both hands loose, and her heavy is a straight drop-kick through the guard. The beam
-- slot is the Gigantic Ray, both palms forward from a wide stance. Clips not listed here fall back to
-- Caulifla's set, then Goku's, then Shared.
local B = require(script.Parent.Parent:WaitForChild("ClipBuilder"))
local Caulifla = require(script.Parent:WaitForChild("Caulifla"))

local stance = {
	Root = { pos = { 0, -0.2, 0 }, rot = { 0, 0, 0 } },
	Waist = { -5, -10, 0 },
	Neck = { -10, 10, 0 },
	LeftShoulder = { 30, 0, -25 },
	LeftElbow = { 50, 0, 0 },
	RightShoulder = { 30, 0, 25 },
	RightElbow = { 50, 0, 0 },
	LeftHip = { 12, 0, -14 },
	LeftKnee = { -15, 0, 0 },
	RightHip = { -5, 0, 14 },
	RightKnee = { -15, 0, 0 },
}
local breathe = B.pose(stance, { Root = { pos = { 0, -0.26, 0 }, rot = { 0, 0, 0 } }, Waist = { -2, -14, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- heavy: two-footed drop-kick
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 10,
	impact = "VFXCommon.Shockwave;VFXCommon.DebrisBurst",
	windup = {
		Root = { pos = { 0, 0.5, -0.3 }, rot = { 0, 0, 0 } },
		Waist = { -30, 0, 0 },
		LeftShoulder = { -30, 0, -40 },
		RightShoulder = { -30, 0, 40 },
		LeftHip = { 90, 0, -5 },
		LeftKnee = { -100, 0, 0 },
		RightHip = { 90, 0, 5 },
		RightKnee = { -100, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, 0.3, 0.9 }, rot = { 0, 0, 0 } },
		Waist = { -40, 0, 0 },
		LeftShoulder = { -50, 0, -60 },
		RightShoulder = { -50, 0, 60 },
		LeftHip = { 95, 0, -5 },
		LeftKnee = { -5, 0, 0 },
		RightHip = { 95, 0, 5 },
		RightKnee = { -5, 0, 0 },
	},
})

-- Gigantic Ray: wide stance, both palms forward, fingers spread
local gather = {
	Root = { pos = { 0, -0.5, 0 }, rot = { 0, 0, 0 } },
	Waist = { -5, 0, 0 },
	LeftShoulder = { 80, 0, -45 },
	RightShoulder = { 80, 0, 45 },
	LeftElbow = { 70, 0, 0 },
	RightElbow = { 70, 0, 0 },
	LeftHip = { 20, 0, -25 },
	LeftKnee = { -40, 0, 0 },
	RightHip = { 10, 0, 25 },
	RightKnee = { -40, 0, 0 },
}
local pulse = B.pose(gather, { Root = { pos = { 0, -0.58, 0 }, rot = { 0, 0, 0 } } })
local ray = {
	Root = { pos = { 0, -0.5, 0.4 }, rot = { 0, 0, 0 } },
	Waist = { 12, 0, 0 },
	LeftShoulder = { 92, 0, -6 },
	RightShoulder = { 92, 0, 6 },
	LeftWrist = { -75, 0, 0 },
	RightWrist = { -75, 0, 0 },
	LeftHip = { 30, 0, -25 },
	LeftKnee = { -45, 0, 0 },
	RightHip = { -10, 0, 25 },
	RightKnee = { -25, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, gather, pulse, ray, 10)

return B.set(clips, Caulifla)
