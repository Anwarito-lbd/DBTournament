--!nonstrict
-- MoroAbsorbTouchVFX (FriezaMajin kit): Moro's Absorb, drawn on the person being drained. The server broadcasts
-- Absorb with the hit position, but the shared MoroAbsorbVFX wants the victim's Model, so this finds the character
-- standing at that position and runs a short drain on them (green-black tendrils into Moro's hand, the victim's
-- glow dimming). With nobody there (a whiff), only a dark ring at the palm.
-- Play(character, target, config?) -- client visual only.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local Absorb = require(VFX:WaitForChild("MoroAbsorbVFX"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))

local M = {}
M.DURATION, M.RADIUS = 1.2, 7

function M.Play(character: Model, target: any, _config: any?)
	local pos = FX.target(character, target)
	local victim = if typeof(target) == "Instance" and target:IsA("Model") then target
		else FX.victimNear(character, pos, M.RADIUS)
	if victim then
		return Absorb.Play(character, victim, { Duration = M.DURATION })
	end
	local f = C.folder("MoroAbsorbWhiff", 1)
	C.Shockwave(f, CFrame.new(pos), 0.5, 5, Color3.fromRGB(40, 60, 30), 0.3, 0.2)
	return nil
end

return M
