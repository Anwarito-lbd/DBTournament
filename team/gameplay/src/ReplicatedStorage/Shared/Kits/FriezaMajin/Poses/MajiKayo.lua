--!nonstrict
-- Clip set: Maji Kayo. A body with no fixed shape:
--   Idle               wide, low and loose, arms hanging out from the body, swaying side to side like jelly.
--   Heavy              the Giant Fist: right arm swung overhead, then brought down in front with the whole body.
--   Kamehameha_*       the Mystic Attack (his signature slot): right arm cocked back, left hand aiming, then the arm
--                      thrown out at full stretch (the effect stretches it across the arena).
--   Transform_SSJ      swelling into his muscular form: a double-biceps flex that grows on each pulse.
-- Other clips fall back to the neutral Shared set (not Goku's).
-- `script` is absent in the plain-Luau data check (tests/kit_friezamajin_tests.luau): load siblings by path there
local K = if script then require(script.Parent:WaitForChild("ClipKit")) else require("./ClipKit")

local stance = {
	root = { 0, -0.3, 0 },
	W = { 10, 0, 8 },
	N = { -5, 0, -6 },
	RS = { 5, 0, 20 },
	RE = { 25, 0, 0 },
	LS = { 5, 0, 20 },
	LE = { 25, 0, 0 },
	RH = { 10, 0, 15 },
	RK = { -20, 0, 0 },
	LH = { 10, 0, 15 },
	LK = { -20, 0, 0 },
}
local sway = K.pose(stance, { root = { 0, -0.45, 0 }, W = { 14, 0, -8 }, N = { -5, 0, 6 }, RS = { 5, 0, 26 },
	LS = { 5, 0, 26 } })

local overhead = K.pose(stance, {
	root = { 0, -0.1, 0 },
	W = { -15, 20, 0 },
	N = { -10, -10, 0 },
	RS = { 160, 0, 10 },
	RE = { 30, 0, 0 },
	LS = { 30, 0, 30 },
})
local slam = K.pose(stance, {
	root = { 0, -0.6, 0 },
	W = { 30, -20, 0 },
	N = { -20, 10, 0 },
	RS = { 60, 0, 0 },
	RE = { 0, 0, 0 },
	LS = { -10, 0, 35 },
	RK = { -35, 0, 0 },
	LK = { -35, 0, 0 },
})

local cock = K.pose(stance, {
	root = { 0, -0.4, 0 },
	W = { 0, 35, 0 },
	N = { 0, -30, 0 },
	RS = { -40, 0, 20 },
	RE = { 100, 0, 0 },
	LS = { 60, 0, 0 },
	LE = { 10, 0, 0 },
})
local coiled = K.pose(cock, { W = { 0, 42, 0 }, RS = { -45, 0, 22 } })
local stretch = K.pose(stance, {
	root = { 0, -0.4, 0 },
	W = { 10, -35, 0 },
	N = { 0, 25, 0 },
	RS = { 90, 0, 0 },
	RE = { 0, 0, 0 },
	RWr = { 0, 0, 0 },
	LS = { -20, 0, 30 },
	LE = { 30, 0, 0 },
})

local flex = K.pose(stance, {
	root = { 0, -0.2, 0 },
	W = { -5, 0, 0 },
	N = { -5, 0, 0 },
	RS = { 0, 0, 90 },
	RE = { 100, 0, 0 },
	LS = { 0, 0, 90 },
	LE = { 100, 0, 0 },
})
local swell = K.pose(flex, { root = { 0, 0.1, 0 }, W = { -12, 0, 0 }, N = { -15, 0, 0 }, RE = { 120, 0, 0 },
	LE = { 120, 0, 0 }, RS = { 0, 0, 80 }, LS = { 0, 0, 80 } })

local clips = {}
clips.Idle = K.idle(stance, sway)
clips.Heavy = K.strike(stance, overhead, slam)
clips.Kamehameha_Charge, clips.Kamehameha_Fire = K.beam(stance, cock, coiled, stretch)
clips.Transform_SSJ = K.surge(flex, swell)

return K.set(clips, K.sharedSet())
