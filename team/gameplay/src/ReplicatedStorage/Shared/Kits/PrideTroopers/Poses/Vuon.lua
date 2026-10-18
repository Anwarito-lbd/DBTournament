--!nonstrict
-- Vuon clip set (Pride Troopers kit). The giant flexes both arms for his Justice Pose; his two-handed Dynamite Blaster
-- uses the stock wave clips.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

clips.JusticePose = P.justice(P.with(P.WIDE_STANCE, {
	Root = { 0, -0.3, 0 },
	Waist = { -8, 0, 0 },
	Neck = { -10, 0, 0 },
	LeftShoulder = { 0, 0, -90 },
	LeftElbow = { 110, 0, 0 },
	RightShoulder = { 0, 0, 90 },
	RightElbow = { 110, 0, 0 },
}))

return P.set(clips, Troopers)
