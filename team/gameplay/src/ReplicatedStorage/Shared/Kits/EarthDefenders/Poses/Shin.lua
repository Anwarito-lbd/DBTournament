--!nonstrict
-- Clip set: Shin. A young god standing straight: hands loosely joined in front at the waist, feet together, no
-- fighting crouch. The finisher is an open palm pushed from the chest, the heavy a two-palm shove that releases a
-- ripple. The beam slot is Energy's Last: both hands brought forward, palms out, while the purple sphere gathers.
-- Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_earthdefenders_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, 0, 0 },
	Neck = { 3, 0, 0 },
	LeftShoulder = { 30, 0, 15 }, -- hands joined in front of the waist
	LeftElbow = { 50, 0, 0 },
	RightShoulder = { 30, 0, -15 },
	RightElbow = { 50, 0, 0 },
	LeftHip = { 0, 0, -2 },
	RightHip = { 0, 0, 2 },
}
local breathe = B.pose(stance, { Root = { pos = { 0, 0.03, 0 }, rot = { 0, 0, 0 } }, Neck = { 1, 0, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe, 200) -- the calmest idle on the team

-- finisher: one open palm pushed from the chest, a single step
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 10,
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.1, -0.1 }, rot = { 0, 0, 0 } },
		Waist = { 0, -25, 0 },
		RightShoulder = { 40, 0, 10 },
		RightElbow = { 110, 0, 0 },
		RightWrist = { -60, 0, 0 },
		LeftShoulder = { 30, 0, -10 },
		LeftElbow = { 50, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.15, 0.5 }, rot = { 0, 0, 0 } },
		Waist = { 5, 20, 0 },
		RightShoulder = { 90, 0, 0 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { -75, 0, 0 },
		LeftShoulder = { 20, 0, -15 },
		LeftElbow = { 40, 0, 0 },
		LeftHip = { 25, 0, -4 },
		LeftKnee = { -25, 0, 0 },
		RightHip = { -15, 0, 4 },
	},
})

-- heavy: both palms forward together, a short shove
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	anticipation = 12,
	windup = {
		Root = { pos = { 0, -0.2, -0.15 }, rot = { 0, 0, 0 } },
		Waist = { -5, 0, 0 },
		LeftShoulder = { 50, 0, -15 },
		LeftElbow = { 110, 0, 0 },
		RightShoulder = { 50, 0, 15 },
		RightElbow = { 110, 0, 0 },
		LeftHip = { 10, 0, -4 },
		LeftKnee = { -20, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.25, 0.5 }, rot = { 0, 0, 0 } },
		Waist = { 8, 0, 0 },
		LeftShoulder = { 90, 0, 6 },
		LeftElbow = { 5, 0, 0 },
		LeftWrist = { -75, 0, 0 },
		RightShoulder = { 90, 0, -6 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { -75, 0, 0 },
		LeftHip = { 30, 0, -4 },
		LeftKnee = { -30, 0, 0 },
		RightHip = { -15, 0, 4 },
	},
})

-- Energy's Last: both hands forward, palms out, the sphere gathering between them
local hands = {
	Root = { pos = { 0, -0.15, 0 }, rot = { 0, 0, 0 } },
	Waist = { 3, 0, 0 },
	LeftShoulder = { 85, 0, 10 },
	LeftElbow = { 30, 0, 0 },
	LeftWrist = { -65, 0, 0 },
	RightShoulder = { 85, 0, -10 },
	RightElbow = { 30, 0, 0 },
	RightWrist = { -65, 0, 0 },
	LeftHip = { 15, 0, -6 },
	LeftKnee = { -18, 0, 0 },
	RightHip = { -8, 0, 6 },
	RightKnee = { -10, 0, 0 },
}
local gather = B.pose(hands, { LeftElbow = { 40, 0, 0 }, RightElbow = { 40, 0, 0 } })
local release = B.pose(hands, {
	Root = { pos = { 0, -0.2, 0.25 }, rot = { 0, 0, 0 } },
	LeftShoulder = { 90, 0, 6 },
	LeftElbow = { 5, 0, 0 },
	RightShoulder = { 90, 0, -6 },
	RightElbow = { 5, 0, 0 },
})
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, hands, gather, release, 12)

return B.set(clips)
