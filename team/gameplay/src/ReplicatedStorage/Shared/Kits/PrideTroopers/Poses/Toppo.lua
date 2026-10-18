--!nonstrict
-- Toppo clip set (Pride Troopers kit). A wide, chest-out roar for his power-up, Justice Flash fired from two
-- fingertips with a kick of recoil on each shot, and a Justice Pose with one fist thrown to the sky.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

local ROAR = P.with(P.WIDE_STANCE, {
	Root = { 0, -0.5, 0 },
	Waist = { -18, 0, 0 },
	Neck = { -25, 0, 0 },
	LeftShoulder = { 20, -10, -40 },
	LeftElbow = { 100, 0, 0 },
	RightShoulder = { 20, 10, 40 },
	RightElbow = { 100, 0, 0 },
})
local AIM = P.with(P.PLANTED, {
	Root = { 0, -0.2, 0 },
	Waist = { 0, -25, 0 },
	Neck = { -5, 20, 0 },
	RightShoulder = { 95, 0, 8 },
	RightElbow = { 15, 0, 0 },
	LeftShoulder = { 10, 0, -20 },
	LeftElbow = { 90, 0, 0 },
})
local RECOIL = P.with(AIM, { Waist = { -4, -22, 0 }, RightShoulder = { 108, 0, 8 }, RightElbow = { 30, 0, 0 } })

clips.Transform_SSJ = P.clip(120, false, "Action3", {
	{ 0, "Sine", {} },
	{ 20, "CubicIn", ROAR },
	{ 90, "Constant", ROAR },
	{ 120, "Sine", P.with(ROAR, { Neck = { -15, 0, 0 } }) },
})
clips.Kamehameha_Charge = P.clip(60, false, "Action4", {
	{ 0, "Sine", {} },
	{ 12, "CubicOut", AIM },
	{ 60, "Constant", AIM },
})
clips.Kamehameha_Fire = P.clip(60, false, "Action4", {
	{ 0, "Linear", AIM },
	{ 4, "Linear", RECOIL },
	{ 9, "Linear", AIM },
	{ 13, "Linear", RECOIL },
	{ 18, "Linear", AIM },
	{ 22, "Linear", RECOIL },
	{ 30, "Constant", AIM },
	{ 60, "QuadOut", {} },
})
clips.JusticePose = P.justice(P.with(P.WIDE_STANCE, {
	Root = { 0, -0.35, 0 },
	Neck = { -15, 0, 0 },
	RightShoulder = { 170, 0, 25 },
	RightElbow = { 20, 0, 0 },
	LeftShoulder = { 10, 0, -30 },
	LeftElbow = { 100, 0, 0 },
}))

return P.set(clips, Troopers)
