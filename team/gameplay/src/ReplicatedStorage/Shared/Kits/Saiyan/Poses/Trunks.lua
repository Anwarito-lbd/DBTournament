--!nonstrict
-- Clip set: Future Trunks. A swordsman from a ruined future: guarded side-on stance, right hand near the hilt
-- over his shoulder. The finisher and heavy are sword cuts (a horizontal slash, then a rising cut into a
-- downward split). The beam slot is the Burning Attack: a fast run of hand signs closing into a palm diamond.
-- Clips not listed here fall back to Goku's set, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_saiyan_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")

local stance = {
	Root = { pos = { 0, -0.25, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, -35, 0 },
	Neck = { 0, 30, 0 },
	LeftShoulder = { 55, 0, -10 },
	LeftElbow = { 70, 0, 0 },
	RightShoulder = { 150, 0, 25 }, -- hand up by the hilt behind the right shoulder
	RightElbow = { 120, 0, 0 },
	LeftHip = { 15, 0, -8 },
	LeftKnee = { -20, 0, 0 },
	RightHip = { -10, 0, 10 },
	RightKnee = { -25, 0, 0 },
	RightAnkle = { 10, 0, 0 },
}
local breathe = B.pose(stance, { Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } }, Waist = { 2, -35, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- finisher: drawn horizontal slash right-to-left
clips.M1_4 = B.strike({
	stance = stance,
	tier = "Finisher",
	anticipation = 8,
	swing = "Swing",
	hitSound = "Hit_Finisher",
	windup = {
		Root = { pos = { 0, -0.35, 0 }, rot = { 0, 0, 0 } },
		Waist = { 0, -60, 0 },
		Neck = { 0, 45, 0 },
		RightShoulder = { 100, 0, 70 },
		RightElbow = { 40, 0, 0 },
		LeftShoulder = { 30, 0, -20 },
		LeftElbow = { 60, 0, 0 },
		LeftHip = { 15, 0, -8 },
		LeftKnee = { -25, 0, 0 },
		RightKnee = { -25, 0, 0 },
	},
	contact = {
		Root = { pos = { 0, -0.45, 0.6 }, rot = { 0, 0, 0 } },
		Waist = { 5, 50, 0 },
		Neck = { 0, -30, 0 },
		RightShoulder = { 90, 0, -40 },
		RightElbow = { 5, 0, 0 },
		RightWrist = { 0, 0, -20 },
		LeftShoulder = { 20, 0, -45 },
		LeftElbow = { 30, 0, 0 },
		LeftHip = { 35, 0, -10 },
		LeftKnee = { -40, 0, 0 },
		RightHip = { -25, 0, 10 },
		RightKnee = { -10, 0, 0 },
	},
})

-- heavy: rising cut with the blade overhead, then a straight downward split
clips.Heavy = B.strike({
	stance = stance,
	tier = "Heavy",
	impact = "VFXCommon.Shockwave",
	windup = {
		Root = { pos = { 0, 0.2, -0.1 }, rot = { 0, 0, 0 } },
		Waist = { -20, -10, 0 },
		Neck = { -10, 0, 0 },
		RightShoulder = { 175, 0, 5 },
		RightElbow = { 30, 0, 0 },
		LeftShoulder = { 170, 0, -5 },
		LeftElbow = { 35, 0, 0 },
		RightHip = { 5, 0, 8 },
		LeftHip = { 10, 0, -8 },
	},
	contact = {
		Root = { pos = { 0, -0.6, 0.7 }, rot = { 0, 0, 0 } },
		Waist = { 35, 0, 0 },
		Neck = { 15, 0, 0 },
		RightShoulder = { 55, 0, -5 },
		RightElbow = { 0, 0, 0 },
		LeftShoulder = { 55, 0, 5 },
		LeftElbow = { 0, 0, 0 },
		LeftHip = { 40, 0, -10 },
		LeftKnee = { -50, 0, 0 },
		RightHip = { -30, 0, 10 },
		RightKnee = { -15, 0, 0 },
	},
})

-- Burning Attack: the sign run happens inside the charge (three quick hand shapes), released palms-together
local signA = {
	Root = { pos = { 0, -0.3, 0 }, rot = { 0, 0, 0 } },
	Waist = { 0, -10, 0 },
	LeftShoulder = { 90, 0, -40 },
	LeftElbow = { 70, 0, 0 },
	RightShoulder = { 120, 0, 40 },
	RightElbow = { 80, 0, 0 },
	LeftHip = { 12, 0, -10 },
	LeftKnee = { -20, 0, 0 },
	RightHip = { -10, 0, 10 },
	RightKnee = { -20, 0, 0 },
}
local signB = B.pose(signA, {
	LeftShoulder = { 120, 0, -30 },
	LeftElbow = { 90, 0, 0 },
	RightShoulder = { 80, 0, 30 },
	RightElbow = { 60, 0, 0 },
	Waist = { 0, 10, 0 },
})
local diamond = {
	Root = { pos = { 0, -0.4, 0.2 }, rot = { 0, 0, 0 } },
	Waist = { 8, 0, 0 },
	LeftShoulder = { 95, 0, 12 },
	RightShoulder = { 95, 0, -12 },
	LeftElbow = { 10, 0, 0 },
	RightElbow = { 10, 0, 0 },
	LeftWrist = { -70, 0, 0 },
	RightWrist = { -70, 0, 0 },
	LeftHip = { 30, 0, -12 },
	LeftKnee = { -35, 0, 0 },
	RightHip = { -25, 0, 12 },
	RightKnee = { -15, 0, 0 },
}
clips.Kamehameha_Charge = B.clip(90, "Action4", {
	{ 0, "Linear", stance },
	{ 8, "CubicIn", signA, { sound = "Kamehameha_Charge" } },
	{ 16, "CubicIn", signB },
	{ 24, "CubicIn", signA },
	{ 32, "CubicIn", signB },
	{ 44, "CubicIn", diamond },
	{ 90, "Sine", diamond },
})
local release = B.pose(diamond, { Root = { pos = { 0, -0.45, 0.45 }, rot = { 0, 0, 0 } }, Waist = { 15, 0, 0 } })
clips.Kamehameha_Fire = B.clip(90, "Action4", {
	{ 0, "Linear", diamond },
	{ 3, "CubicOut", release, { sound = "Kamehameha_Fire", vfx = "VFXCommon.SpeedLines:0.3" } },
	{ 45, "Constant", release },
	{ 90, "QuadOut", stance },
})

return B.set(clips)
