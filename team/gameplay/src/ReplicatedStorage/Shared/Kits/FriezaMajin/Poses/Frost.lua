--!nonstrict
-- Clip set: Frost. Built on the shared Frieza set (same race, same Death Beam finger stance for his Chaos Beam) with
-- the clips that make him someone else:
--   Idle          the gentleman: upright, hands clasped behind his back, head inclined as if listening politely.
--   Heavy         the hidden needle: right wrist drawn back low, then driven straight out at full reach.
--   Transform_SSJ a power he can't hold: hunched, fists clenched at the hips, then a roar with the arms thrown back.
-- Clips not listed here fall back to the shared Frieza set, then Goku's, then Shared.
-- `script` is absent in the plain-Luau data check (tests/kit_friezamajin_tests.luau): load siblings by path there
local K = if script then require(script.Parent:WaitForChild("ClipKit")) else require("./ClipKit")

local stance = {
	root = { 0, 0, 0 },
	W = { -3, 0, 0 },
	N = { 6, 8, 0 },
	RS = { -25, 0, -10 },
	RE = { 70, 0, 0 },
	RWr = { 0, 0, 10 },
	LS = { -25, 0, -10 },
	LE = { 70, 0, 0 },
	LWr = { 0, 0, 10 },
	RH = { 0, 0, 3 },
	LH = { 0, 0, 3 },
}
local breathe = K.pose(stance, { root = { 0, -0.04, 0 }, N = { 3, 4, 0 }, W = { -1, 0, 0 } })

local windup = {
	root = { 0, -0.25, 0 },
	W = { 8, 30, 0 },
	N = { -5, -25, 0 },
	RS = { -35, 0, 15 },
	RE = { 95, 0, 0 },
	RWr = { -20, 0, 0 },
	LS = { 30, 0, 20 },
	LE = { 60, 0, 0 },
	RH = { 20, 0, 6 },
	RK = { -25, 0, 0 },
	LH = { -10, 0, 6 },
	LK = { -15, 0, 0 },
}
local jab = {
	root = { 0, -0.3, 0 },
	W = { 10, -30, 0 },
	N = { -5, 25, 0 },
	RS = { 90, 0, 0 },
	RE = { 0, 0, 0 },
	RWr = { 10, 0, 0 },
	LS = { -15, 0, 25 },
	LE = { 40, 0, 0 },
	RH = { -15, 0, 6 },
	RK = { -10, 0, 0 },
	LH = { 30, 0, 6 },
	LK = { -35, 0, 0 },
}

local strain = {
	root = { 0, -0.35, 0 },
	W = { 20, 0, 0 },
	N = { 10, 0, 0 },
	RS = { -10, 0, 25 },
	RE = { 60, 0, 0 },
	LS = { -10, 0, 25 },
	LE = { 60, 0, 0 },
	RH = { 10, 0, 10 },
	RK = { -25, 0, 0 },
	LH = { 10, 0, 10 },
	LK = { -25, 0, 0 },
}
local roar = K.pose(strain, {
	root = { 0, -0.2, 0 },
	W = { -15, 0, 0 },
	N = { -25, 0, 0 },
	RS = { -20, 0, 40 },
	RE = { 30, 0, 0 },
	LS = { -20, 0, 40 },
	LE = { 30, 0, 0 },
})

local clips = {}
clips.Idle = K.idle(stance, breathe)
clips.Heavy = K.strike(stance, windup, jab)
clips.Transform_SSJ = K.surge(strain, roar)

return K.set(clips, K.friezaSet())
