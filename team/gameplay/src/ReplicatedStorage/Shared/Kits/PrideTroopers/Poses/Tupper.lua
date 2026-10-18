--!nonstrict
-- Tupper clip set (Pride Troopers kit). The heaviest trooper's Justice Pose: a deep, wide squat with hands on knees.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

clips.JusticePose = P.justice({
	Root = { 0, -0.8, 0 },
	Waist = { 20, 0, 0 },
	Neck = { -20, 0, 0 },
	LeftShoulder = { 50, 0, -20 },
	LeftElbow = { 30, 0, 0 },
	RightShoulder = { 50, 0, 20 },
	RightElbow = { 30, 0, 0 },
	LeftHip = { 40, 0, -35 },
	LeftKnee = { -80, 0, 0 },
	RightHip = { 40, 0, 35 },
	RightKnee = { -80, 0, 0 },
})

return P.set(clips, Troopers)
