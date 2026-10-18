--!nonstrict
-- DirtyBurstVFX (FriezaMajin kit): Frost's Dirty Burst. He is already in close (afterimage smear), a ball of
-- blue-violet ki flares in his palm at point-blank range, and the blast goes straight through the target and out
-- the other side. Short and ugly on purpose: it is a cheap shot, not a technique to admire.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.STYLE = { Color = rgb(110, 125, 255), Core = rgb(230, 240, 255), Width = 2.2, Through = 22, Flare = 0.12 }

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLE
	local root = C.root(character)
	if not root then return end
	local pos = FX.target(character, target)
	local f = C.folder("DirtyBurst", 2)
	C.Afterimage(character, s.Color, 0.3, 0.4)
	local hand = C.limb(character, { "RightHand", "Right Arm" })
	local ball = C.part(f, Vector3.one * 0.6, s.Core, Enum.PartType.Ball, 0)
	ball.Position = hand.Position
	C.light(ball, s.Color, 12, 5)
	C.tween(ball, s.Flare, { Size = Vector3.one * 2.4 })
	task.delay(s.Flare, function()
		local from = hand.Position
		local dir = C.direction(from, pos)
		local len = (pos - from).Magnitude + s.Through
		local glow = C.part(f, Vector3.new(len, s.Width, s.Width), s.Color, Enum.PartType.Cylinder, 0.2)
		local core = C.part(f, Vector3.new(len, s.Width * 0.45, s.Width * 0.45), s.Core, Enum.PartType.Cylinder, 0)
		glow.CFrame, core.CFrame = C.cylinderCF(from, dir, len), C.cylinderCF(from, dir, len)
		C.Shockwave(f, CFrame.lookAt(pos, pos + dir) * CFrame.Angles(math.rad(90), 0, 0), 1, 7, s.Color, 0.25, 0.2)
		C.Shockwave(f, CFrame.new(pos + dir * s.Through), 1, 9, s.Core, 0.3, 0.15)
		for _, p in { glow, core, ball } do C.tween(p, 0.25, { Transparency = 1 }) end
	end)
end

return M
