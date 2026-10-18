--!nonstrict
-- Clip set: Kale. Two fighters in one: at rest she is timid, shoulders drawn in and hands clasped low; once she
-- strikes she fights like Broly (his heavy and finisher are inherited). Her beam slot is the Eraser Cannon: one
-- arm drawn back with a green sphere, pushed out from the palm. Clips not listed here fall back to Broly's
-- set, then Goku's, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_saiyan_tests.luau): load siblings by path there
local B = if script then require(script.Parent.Parent:WaitForChild("ClipBuilder")) else require("../ClipBuilder")
local Broly = if script then require(script.Parent:WaitForChild("Broly")) else require("./Broly")

local stance = {
	Root = { pos = { 0, -0.15, 0 }, rot = { 0, 0, 0 } },
	Waist = { 12, 0, 0 },
	Neck = { 18, -10, 0 }, -- eyes down, half looking away
	LeftShoulder = { 25, 0, 20 },
	LeftElbow = { 60, 0, 0 },
	RightShoulder = { 25, 0, -20 },
	RightElbow = { 60, 0, 0 },
	LeftHip = { 5, 0, 4 },
	LeftKnee = { -10, 0, 0 },
	RightHip = { 5, 0, -4 },
	RightKnee = { -10, 0, 0 },
}
local breathe = B.pose(stance, { Neck = { 22, 5, 0 }, Waist = { 14, 0, 0 } })

local clips = {}
clips.Idle = B.idle(stance, breathe)

-- Eraser Cannon: right arm cocked back with the sphere, pushed out at full stretch
local gather = {
	Root = { pos = { 0, -0.5, -0.1 }, rot = { 0, 0, 0 } },
	Waist = { 10, 40, 0 },
	Neck = { -10, -35, 0 },
	LeftShoulder = { 70, 0, -20 },
	LeftElbow = { 30, 0, 0 },
	RightShoulder = { 20, 0, 70 },
	RightElbow = { 90, 0, 0 },
	RightWrist = { -40, 0, 0 },
	LeftHip = { 25, 0, -15 },
	LeftKnee = { -40, 0, 0 },
	RightHip = { 5, 0, 15 },
	RightKnee = { -35, 0, 0 },
}
local pulse = B.pose(gather, { Root = { pos = { 0, -0.58, -0.1 }, rot = { 0, 0, 0 } } })
local push = {
	Root = { pos = { 0, -0.5, 0.5 }, rot = { 0, 0, 0 } },
	Waist = { 15, -25, 0 },
	Neck = { 0, 20, 0 },
	LeftShoulder = { 20, 0, -40 },
	RightShoulder = { 95, 0, 0 },
	RightElbow = { 0, 0, 0 },
	RightWrist = { -70, 0, 0 },
	LeftHip = { 35, 0, -15 },
	LeftKnee = { -45, 0, 0 },
	RightHip = { -20, 0, 15 },
	RightKnee = { -20, 0, 0 },
}
clips.Kamehameha_Charge, clips.Kamehameha_Fire = B.beam(stance, gather, pulse, push, 14)

return B.set(clips, Broly)
