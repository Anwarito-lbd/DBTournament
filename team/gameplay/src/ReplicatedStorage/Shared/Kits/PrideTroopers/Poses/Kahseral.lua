--!nonstrict
-- Kahseral clip set (Pride Troopers kit). The leader: Cannon Maximum pushed from a braced palm with the other hand on
-- the wrist, and a Justice Pose that points his squad forward.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

local PALM = P.with(P.PLANTED, {
	Root = { 0, -0.3, 0 },
	Waist = { 0, -20, 0 },
	Neck = { 0, 15, 0 },
	RightShoulder = { 90, -10, 5 },
	RightElbow = { 10, 0, 0 },
	LeftShoulder = { 80, -35, -5 },
	LeftElbow = { 50, 0, 0 },
})
local PUSH = P.with(PALM, {
	Root = { 0, -0.35, -0.2 },
	Waist = { -5, -25, 0 },
	RightShoulder = { 95, -5, 5 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { 88, -30, -5 },
	LeftElbow = { 35, 0, 0 },
})

clips.Kamehameha_Charge = P.clip(90, false, "Action4", {
	{ 0, "Sine", {} },
	{ 15, "CubicOut", PALM },
	{ 90, "Constant", PALM },
})
clips.Kamehameha_Fire = P.clip(60, false, "Action4", {
	{ 0, "Linear", PALM },
	{ 3, "Linear", PUSH },
	{ 24, "Constant", PUSH },
	{ 60, "QuadOut", {} },
})
clips.JusticePose = P.justice(P.with(P.WIDE_STANCE, {
	Root = { 0, -0.25, 0 },
	Neck = { -12, 10, 0 },
	RightShoulder = { 140, 10, 20 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { 10, 0, -35 },
	LeftElbow = { 110, 0, 0 },
}))

return P.set(clips, Troopers)
