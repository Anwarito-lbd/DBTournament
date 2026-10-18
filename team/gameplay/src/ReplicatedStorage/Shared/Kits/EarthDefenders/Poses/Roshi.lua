--!nonstrict
-- Clip set: Master Roshi. An old hermit at rest: stooped forward, both hands clasped behind the back, knees soft. The
-- finisher is a quick open-palm strike from that lazy posture, the heavy a planted double palm. The beam slot is the
-- original Kamehameha at maximum: the deepest crouch on the team, cupped hands drawn back to the right hip, then a
-- full two-handed push. Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } },
	Waist = { 25, 0, 0 }, -- stooped
	Neck = { -20, 0, 0 },
	LeftShoulder = { -35, 0, 10 }, -- hands clasped behind the back
	LeftElbow = { 70, 0, 0 },
	RightShoulder = { -35, 0, -10 },
	RightElbow = { 70, 0, 0 },
	LeftHip = { 10, 0, -6 },
	LeftKnee = { -18, 0, 0 },
	RightHip = { 4, 0, 6 },
	RightKnee = { -14, 0, 0 },
}
local breathe = B.pose(stance, { Waist = { 22, 0, 0 }, Neck = { -18, 5, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe, 170)

-- finisher: the hands come out from behind the back into a fast right palm
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 6, -- he is faster than he looks
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.35, -0.1 }, rot = { 0, 0, 0 } },
		Waist = { 15, -30, 0 },
		RightShoulder = { 20, 0, 30 },
		RightElbow = { 100, 0, 0 },
		LeftShoulder = { -20, 0, 10 },
		LeftElbow = { 70, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.4, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 15, 25, 0 },
		Neck = { -10, -20, 0 },
		RightShoulder = { 90, 0, -5 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { -75, 0, 0 },
		LeftShoulder = { -30, 0, 10 },
		LeftElbow = { 70, 0, 0 },
		LeftHip = { 35, 0, -8 },
		LeftKnee = { -40, 0, 0 },
		RightHip = { -20, 0, 8 },
	},
})

-- heavy: a planted double palm, the old body suddenly solid
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 12,
	impact = "VFXCommon.Shockwave",
	windup = {
		Root = { pos = { 0, -0.6, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { 5, 0, 0 },
		Neck = { -5, 0, 0 },
		LeftShoulder = { 40, 0, -30 },
		LeftElbow = { 110, 0, 0 },
		RightShoulder = { 40, 0, 30 },
		RightElbow = { 110, 0, 0 },
		LeftHip = { 25, 0, -18 },
		LeftKnee = { -50, 0, 0 },
		RightHip = { -10, 0, 18 },
		RightKnee = { -45, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.65, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 15, 0, 0 },
		LeftShoulder = { 88, 0, 8 },
		LeftElbow = { 5, 0, 0 },
		LeftWrist = { -75, 0, 0 },
		RightShoulder = { 88, 0, -8 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { -75, 0, 0 },
		LeftHip = { 40, 0, -18 },
		LeftKnee = { -55, 0, 0 },
		RightHip = { -25, 0, 18 },
		RightKnee = { -15, 0, 0 },
	},
})

-- MAX Power Kamehameha: the deepest crouch, cupped hands at the right hip, then the full push
local cup = {
	Root = { pos = { 0, -0.9, 0 }, rot = { 0, 0, 0 } },
	Waist = { 5, -50, 0 },
	Neck = { 0, 50, 0 },
	RightShoulder = { -10, 0, 25 },
	RightElbow = { 100, 0, 0 },
	RightWrist = { -40, 0, 0 },
	LeftShoulder = { 20, 0, 40 },
	LeftElbow = { 110, 0, 0 },
	LeftWrist = { -40, 0, 0 },
	LeftHip = { 40, 0, -25 },
	LeftKnee = { -70, 0, 0 },
	RightHip = { -15, 0, 25 },
	RightKnee = { -60, 0, 0 },
}
local cupPulse = B.pose(cup, { Root = { pos = { 0, -1.0, 0 }, rot = { 0, 0, 0 } }, Waist = { 8, -55, 0 } })
local push = {
	Root = { pos = { 0, -0.85, 0.5 }, rot = { 0, 0, 0 } },
	Waist = { 12, 0, 0 },
	Neck = { 0, 0, 0 },
	LeftShoulder = { 90, 0, 8 },
	LeftElbow = { 5, 0, 0 },
	LeftWrist = { -75, 0, 0 },
	RightShoulder = { 90, 0, -8 },
	RightElbow = { 5, 0, 0 },
	RightWrist = { -75, 0, 0 },
	LeftHip = { 45, 0, -25 },
	LeftKnee = { -70, 0, 0 },
	RightHip = { -30, 0, 25 },
	RightKnee = { -30, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, cup, cupPulse, push, 18)

return B.set(clips)
