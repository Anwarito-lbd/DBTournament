--!nonstrict
-- ScissorHandsVFX (FriezaMajin kit): Maji Kayo's hands turn into blades and close on the target: two shining blue
-- crescents cross in an X at the hit point, a beat apart, like scissor blades meeting.
-- Play(character, target, config?) -- client visual only.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.STYLE = { Blade = rgb(90, 185, 255), Edge = rgb(235, 250, 255), Reach = 3.5 }

local function blade(f: Folder, base: CFrame, tilt: number, s: any)
	for i = -3, 3 do
		local seg = C.part(f, Vector3.new(0.18, 0.18, 1.8), if i == 0 then s.Edge else s.Blade, nil, 0.05)
		seg.CFrame = base * CFrame.Angles(0, 0, math.rad(tilt)) * CFrame.new(i * s.Reach / 3, -math.abs(i) * 0.25, 0)
			* CFrame.Angles(0, math.rad(90), 0)
		C.tween(seg, 0.2, { Transparency = 1, Size = Vector3.new(0.05, 0.05, 2.6) })
	end
end

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local pos = FX.target(character, target)
	local f = C.folder("ScissorHands", 1)
	local base = CFrame.lookAt(pos, pos + root.CFrame.LookVector)
	blade(f, base, 40, M.STYLE)
	task.delay(0.06, function() blade(f, base, -40, M.STYLE) end)
end

return M
