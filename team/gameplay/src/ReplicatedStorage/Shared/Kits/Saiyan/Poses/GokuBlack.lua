--!nonstrict
-- Clip set: Goku Black. Goku's body, a rogue god's manners: upright, unhurried, left hand folded behind the back,
-- fighting one-handed as if the fight were beneath him. The finisher is a palm strike, the heavy a thrust with a
-- blade of ki formed along the right hand. His beam slot keeps Goku's cupped-hands stance (fall-through), since
-- the Black Kamehameha mocks the original. Clips not listed here fall back to Goku's set, then Shared.
local B = require(script.Parent.Parent:WaitForChild("ClipBuilder"))

local stance = {
	Root = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } },
	Waist = { -5, -10, 0 },
	Neck = { -8, 10, 0 },
	LeftShoulder = { -40, 0, -10 }, -- folded behind the back
	LeftElbow = { 110, 0, 0 },
	RightShoulder = { 25, 0, 10 },
	RightElbow = { 40, 0, 0 },
	RightWrist = { 0, 0, 10 },
	LeftHip = { 3, 0, -5 },
	RightHip = { -3, 0, 5 },
}
local breathe = B.pose(stance, { Neck = { -10, 14, 0 }, RightElbow = { 45, 0, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- finisher: open-palm strike, the back hand never moves
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 8,
	swing = "Swing",
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.15, -0.1 }, rot = { 0, 0, 0 } },
		Waist = { 0, 30, 0 },
		Neck = { 0, -25, 0 },
		LeftShoulder = { -40, 0, -10 },
		LeftElbow = { 110, 0, 0 },
		RightShoulder = { 20, 0, 40 },
		RightElbow = { 110, 0, 0 },
		LeftHip = { 10, 0, -5 },
	},
	contact = {
		Root = { pos = { 0, -0.2, 0.5 }, rot = { 0, 0, 0 } },
		Waist = { 5, -25, 0 },
		Neck = { 0, 20, 0 },
		LeftShoulder = { -40, 0, -10 },
		LeftElbow = { 110, 0, 0 },
		RightShoulder = { 90, 0, 0 },
		RightElbow = { 0, 0, 0 },
		RightWrist = { -80, 0, 0 },
		LeftHip = { 25, 0, -5 },
		LeftKnee = { -25, 0, 0 },
		RightHip = { -15, 0, 5 },
	},
})

-- heavy: ki-blade thrust, fingers together, full extension
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 10,
	impact = "VFXCommon.Shockwave",
	windup = {
		Root = { pos = { 0, -0.25, -0.2 }, rot = { 0, 0, 0 } },
		Waist = { 0, 45, 0 },
		Neck = { 0, -40, 0 },
		LeftShoulder = { -40, 0, -10 },
		LeftElbow = { 110, 0, 0 },
		RightShoulder = { 10, 0, 30 },
		RightElbow = { 130, 0, 0 },
		RightWrist = { 0, 0, 0 },
		LeftHip = { 15, 0, -6 },
		LeftKnee = { -15, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.35, 0.8 }, rot = { 0, 0, 0 } },
		Waist = { 8, -40, 0 },
		Neck = { 0, 35, 0 },
		LeftShoulder = { -40, 0, -10 },
		LeftElbow = { 110, 0, 0 },
		RightShoulder = { 92, 0, 0 },
		RightElbow = { 0, 0, 0 },
		RightWrist = { 0, 0, 0 },
		LeftHip = { 35, 0, -6 },
		LeftKnee = { -40, 0, 0 },
		RightHip = { -25, 0, 6 },
		RightKnee = { -10, 0, 0 },
	},
})

return B.set(clips)
