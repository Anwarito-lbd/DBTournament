--!nonstrict
-- Clip set: Frieza. The shared Frieza set (team/animation/poses/Frieza.lua: upright poise, hand on hip, one-handed
-- guard, Death Beam finger) is already his; this adds the one clip it lacked. Without it his power-up and every
-- transformation borrowed Goku's Super Saiyan scream. Frieza's surge is composed: feet planted, chin up, leaning
-- back; the release spreads both arms wide, palms out, head tilted back as if amused.
-- `script` is absent in the plain-Luau data check (tests/kit_friezamajin_tests.luau): load siblings by path there
local K = if script then require(script.Parent:WaitForChild("ClipKit")) else require("./ClipKit")

local coil = {
	root = { 0, -0.15, 0 },
	W = { -4, 0, 0 },
	N = { -12, 0, 0 },
	RS = { 0, 0, 20 },
	RE = { 20, 0, 0 },
	RWr = { 0, 0, -10 },
	LS = { 0, 0, 20 },
	LE = { 20, 0, 0 },
	LWr = { 0, 0, -10 },
	RH = { 0, 0, 6 },
	LH = { 0, 0, 6 },
}
local release = K.pose(coil, {
	root = { 0, -0.3, 0 },
	W = { -12, 0, 0 },
	N = { -20, 0, 0 },
	RS = { 10, 0, 55 },
	RE = { 5, 0, 0 },
	RWr = { 0, 0, -25 },
	LS = { 10, 0, 55 },
	LE = { 5, 0, 0 },
	LWr = { 0, 0, -25 },
	RK = { -8, 0, 0 },
	LK = { -8, 0, 0 },
})

local clips = {}
clips.Transform_SSJ = K.surge(coil, release)

return K.set(clips, K.friezaSet())
