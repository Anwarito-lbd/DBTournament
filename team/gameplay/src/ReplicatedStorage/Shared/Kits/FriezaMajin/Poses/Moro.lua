--!nonstrict
-- Clip set: Moro. An old sorcerer, not a martial artist:
--   Idle               hunched, hands clasped behind the back, head pushed forward and up to look at you.
--   Kamehameha_*       the Mouth Energy Wave (his signature slot): head thrown back with the arms spread low while
--                      the energy gathers, then the head snaps forward and the arms fling back as it leaves the mouth.
--   Heavy              the drain palm: drawn back to the shoulder, pushed out flat at the target.
--   Transform_SSJ      feeding: arms wide, palms up, head back, taking in what the ground gives him.
-- Other clips fall back to the neutral Shared set (not Goku's).
-- `script` is absent in the plain-Luau data check (tests/kit_friezamajin_tests.luau): load siblings by path there
local K = if script then require(script.Parent:WaitForChild("ClipKit")) else require("./ClipKit")

local stance = {
	root = { 0, -0.2, 0 },
	W = { 25, 0, 0 },
	N = { -20, 0, 0 },
	RS = { -20, 0, -5 },
	RE = { 60, 0, 0 },
	LS = { -20, 0, -5 },
	LE = { 60, 0, 0 },
	RH = { 8, 0, 4 },
	RK = { -12, 0, 0 },
	LH = { 8, 0, 4 },
	LK = { -12, 0, 0 },
}
local breathe = K.pose(stance, { root = { 0, -0.25, 0 }, W = { 28, 0, 0 }, N = { -22, 3, 0 } })

local gather = {
	root = { 0, -0.2, 0 },
	W = { -10, 0, 0 },
	N = { -35, 0, 0 },
	RS = { 10, 0, 45 },
	RE = { 15, 0, 0 },
	RWr = { 0, 0, 15 },
	LS = { 10, 0, 45 },
	LE = { 15, 0, 0 },
	LWr = { 0, 0, 15 },
	RH = { 0, 0, 8 },
	LH = { 0, 0, 8 },
}
local pulse = K.pose(gather, { N = { -42, 0, 0 }, W = { -14, 0, 0 } })
local spit = K.pose(gather, {
	W = { 20, 0, 0 },
	N = { 15, 0, 0 },
	RS = { -30, 0, 40 },
	LS = { -30, 0, 40 },
	RK = { -10, 0, 0 },
	LK = { -10, 0, 0 },
})

local draw = K.pose(stance, {
	W = { 15, 30, 0 },
	RS = { -20, 0, 20 },
	RE = { 80, 0, 0 },
	RWr = { -30, 0, 0 },
})
local palm = K.pose(stance, {
	W = { 15, -20, 0 },
	N = { -15, 15, 0 },
	RS = { 85, 0, 0 },
	RE = { 5, 0, 0 },
	RWr = { -60, 0, 0 },
})

local feed = K.pose(gather, { RS = { 20, 0, 60 }, LS = { 20, 0, 60 }, RE = { 20, 0, 0 }, LE = { 20, 0, 0 },
	N = { -30, 0, 0 }, W = { -12, 0, 0 } })
local full = K.pose(feed, { root = { 0, 0.1, 0 }, RS = { 40, 0, 80 }, LS = { 40, 0, 80 }, N = { -40, 0, 0 },
	W = { -18, 0, 0 } })

local clips = {}
clips.Idle = K.idle(stance, breathe)
clips.Kamehameha_Charge, clips.Kamehameha_Fire = K.beam(stance, gather, pulse, spit)
clips.Heavy = K.strike(stance, draw, palm)
clips.Transform_SSJ = K.surge(feed, full)

return K.set(clips, K.sharedSet())
