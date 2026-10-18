--!nonstrict
-- Troopers clip set (Pride Troopers kit): the race fallback. A generic Justice Pose (fist raised high, other fist at
-- the hip); every clip it lacks comes from the shared neutral clips, as before this kit existed. Each fighter's own set
-- falls back to this one.
local PoseKit = if script then require(script.Parent:WaitForChild("PoseKit")) else require("./PoseKit")
local P = PoseKit

local clips = {}

clips.JusticePose = P.justice(P.with(P.PLANTED, {
	Root = { 0, -0.1, 0 },
	Neck = { -10, 0, 0 },
	RightShoulder = { 150, 0, 20 },
	RightElbow = { 30, 0, 0 },
	LeftShoulder = { 10, 0, -25 },
	LeftElbow = { 100, 0, 0 },
}))

return P.set(clips, P.sharedClips())
