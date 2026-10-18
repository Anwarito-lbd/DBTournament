--!nonstrict
-- Jiren clip set (Pride Troopers kit). Stoic: arms folded at rest, a cross-legged meditation when hovering, a power-up
-- that barely moves him, and Power Impact thrown from one open hand while the other arm stays folded. He never poses;
-- his Justice Pose is a folded-arm stare.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

local IDLE = P.with(P.CROSSED_ARMS, P.PLANTED, { Root = { 0, -0.08, 0 }, Neck = { -4, 0, 0 } })
local MEDITATE = P.with(P.CROSSED_ARMS, {
	Root = { 0, 0.3, 0 },
	Waist = { -4, 0, 0 },
	Neck = { 10, 0, 0 },
	LeftHip = { 80, 0, -40 },
	LeftKnee = { -120, 0, 0 },
	RightHip = { 80, 0, 40 },
	RightKnee = { -120, 0, 0 },
})
local BRACE = P.with(IDLE, { Root = { 0, -0.3, 0 }, Waist = { 6, 0, 0 }, Neck = { -2, 0, 0 } })
local AIM = P.with(P.PLANTED, {
	Root = { 0, -0.2, 0 },
	Waist = { 0, -20, 0 },
	Neck = { 0, 15, 0 },
	LeftShoulder = { 100, -50, -8 },
	LeftElbow = { 170, -30, 0 },
	RightShoulder = { 95, 0, 10 },
	RightElbow = { 10, 0, 0 },
})
local THRUST = P.with(AIM, {
	Root = { 0, -0.3, -0.25 },
	Waist = { -6, -30, 0 },
	RightShoulder = { 100, 5, 5 },
	RightElbow = { 0, 0, 0 },
})

clips.Idle = P.hold(IDLE, 120, "Idle", 0.02)
clips.FlyIdle = P.hold(MEDITATE, 160, "Movement", 0.08)
clips.Transform_SSJ = P.clip(120, false, "Action3", {
	{ 0, "Sine", IDLE },
	{ 30, "CubicIn", BRACE },
	{ 90, "Constant", BRACE },
	{ 120, "Sine", P.with(IDLE, { Root = { 0, -0.22, 0 } }) },
})
clips.Kamehameha_Charge = P.clip(90, false, "Action4", {
	{ 0, "Sine", IDLE },
	{ 18, "CubicOut", AIM },
	{ 90, "Constant", AIM },
})
clips.Kamehameha_Fire = P.clip(60, false, "Action4", {
	{ 0, "Linear", AIM },
	{ 3, "Linear", THRUST },
	{ 20, "Constant", THRUST },
	{ 60, "QuadOut", IDLE },
})
clips.JusticePose = P.justice(P.with(IDLE, { Root = { 0, -0.12, 0 }, Neck = { -8, 0, 0 } }))

return P.set(clips, Troopers)
