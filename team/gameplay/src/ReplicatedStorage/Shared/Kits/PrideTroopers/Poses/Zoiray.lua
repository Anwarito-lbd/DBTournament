--!nonstrict
-- Zoiray clip set (Pride Troopers kit). A Justice Pose wound up for his spin: torso twisted, one arm high and one low.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

clips.JusticePose = P.justice({
	Root = { 0, -0.15, 0 },
	Waist = { 0, 40, 0 },
	Neck = { -5, -30, 0 },
	RightShoulder = { 160, 0, 30 },
	RightElbow = { 10, 0, 0 },
	LeftShoulder = { -20, 0, -30 },
	LeftElbow = { 10, 0, 0 },
	LeftHip = { 10, 0, -5 },
	RightHip = { -10, 0, 5 },
})

return P.set(clips, Troopers)
