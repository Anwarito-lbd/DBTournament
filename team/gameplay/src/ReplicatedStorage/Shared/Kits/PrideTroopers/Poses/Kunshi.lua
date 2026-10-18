--!nonstrict
-- Kunshi clip set (Pride Troopers kit). Threaded Energy drawn from one fingertip (a quick, precise shot, not a
-- two-handed wave), and a high-guard Justice Pose on one leg.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

local FINGER = P.with(P.PLANTED, {
	Waist = { 0, -30, 0 },
	Neck = { -4, 25, 0 },
	RightShoulder = { 100, 5, 8 },
	RightElbow = { 5, 0, 0 },
	LeftShoulder = { 8, 0, -18 },
	LeftElbow = { 70, 0, 0 },
})

clips.Kamehameha_Charge = P.clip(40, false, "Action4", {
	{ 0, "Sine", {} },
	{ 10, "CubicOut", FINGER },
	{ 40, "Constant", FINGER },
})
clips.Kamehameha_Fire = P.clip(30, false, "Action4", {
	{ 0, "Linear", FINGER },
	{ 2, "Linear", P.with(FINGER, { RightShoulder = { 104, 5, 8 } }) },
	{ 12, "Constant", FINGER },
	{ 30, "QuadOut", {} },
})
clips.JusticePose = P.justice({
	Root = { 0, -0.1, 0 },
	Neck = { -5, 0, 0 },
	LeftShoulder = { 60, 0, -30 },
	LeftElbow = { 120, 0, 0 },
	RightShoulder = { 60, 0, 30 },
	RightElbow = { 120, 0, 0 },
	LeftHip = { 70, 0, -5 },
	LeftKnee = { -90, 0, 0 },
	RightKnee = { -10, 0, 0 },
})

return P.set(clips, Troopers)
