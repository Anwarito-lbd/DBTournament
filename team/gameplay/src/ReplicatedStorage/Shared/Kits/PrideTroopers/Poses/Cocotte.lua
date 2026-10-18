--!nonstrict
-- Cocotte clip set (Pride Troopers kit). Her Justice Pose holds both hands out with wrists crossed, the gesture she
-- raises Cocotte Zone with (CocotteZoneVFX plays it inside the dome).
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local Troopers = if script then require(script.Parent:WaitForChild("Troopers")) else require("./Troopers")
local P = PoseKit

local clips = {}

clips.JusticePose = P.justice(P.with(P.PLANTED, {
	Neck = { -5, 0, 0 },
	RightShoulder = { 90, -30, 0 },
	RightElbow = { 20, 0, 0 },
	LeftShoulder = { 90, 30, 0 },
	LeftElbow = { 20, 0, 0 },
}))

return P.set(clips, Troopers)
