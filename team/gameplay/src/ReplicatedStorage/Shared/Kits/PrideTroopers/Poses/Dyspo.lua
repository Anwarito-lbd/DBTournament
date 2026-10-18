--!nonstrict
-- Dyspo clip set (Pride Troopers kit). Light speed: a dash thrown almost flat with both arms swept back, and a Justice
-- Pose crouched low like a sprinter on the line.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

local LEAN = {
	Root = { 0, -0.6, -0.7 },
	Waist = { 45, 0, 0 },
	Neck = { -35, 0, 0 },
	LeftShoulder = { -50, 0, -20 },
	LeftElbow = { 10, 0, 0 },
	RightShoulder = { -50, 0, 20 },
	RightElbow = { 10, 0, 0 },
	LeftHip = { -20, 0, -5 },
	LeftKnee = { -80, 0, 0 },
	RightHip = { 20, 0, 5 },
	RightKnee = { -40, 0, 0 },
}

clips.Dash = P.clip(24, false, "Movement", {
	{ 0, "CubicIn", {} },
	{ 3, "Linear", LEAN },
	{ 14, "Constant", LEAN },
	{ 24, "QuadOut", {} },
})
clips.JusticePose = P.justice({
	Root = { 0, -0.6, 0 },
	Waist = { 25, 0, 0 },
	Neck = { -20, 0, 0 },
	RightShoulder = { 80, 0, 15 },
	RightElbow = { 20, 0, 0 },
	LeftShoulder = { -30, 0, -20 },
	LeftElbow = { 20, 0, 0 },
	LeftHip = { 40, 0, -10 },
	LeftKnee = { -80, 0, 0 },
	RightHip = { -20, 0, 10 },
	RightKnee = { -40, 0, 0 },
})

return P.set(clips, Troopers)
