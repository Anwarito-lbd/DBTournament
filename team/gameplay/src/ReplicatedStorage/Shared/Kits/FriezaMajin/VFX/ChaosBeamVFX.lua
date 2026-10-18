--!nonstrict
-- ChaosBeamVFX (FriezaMajin kit): Frost's Chaos Beam. Where Frieza fires three precise needles, Frost fires one
-- wider, colder finger beam (ice core, blue-violet glow) and sprays two stray Chaos Shots around it: the same
-- technique as his senpai's, done louder and less exactly.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by BeamFX.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.STYLE = {
	Core = rgb(225, 240, 255), Glow = rgb(110, 125, 255), Haze = rgb(60, 40, 200), Width = 1.4, Charge = 0.35,
	Duration = 0.5, Spiral = false, ImpactSize = 14, Shake = 1.4, ChargeAt = "finger", Speed = 800,
}
M.STRAY = {
	Core = rgb(225, 240, 255), Glow = rgb(140, 150, 255), Haze = rgb(80, 60, 220), Width = 0.5, Charge = 0.05,
	Duration = 0.25, Spiral = false, ImpactSize = 6, Shake = 0.3, ChargeAt = "finger", Speed = 900,
}

function M.Play(character: Model, target: any, _config: any?)
	local pos = FX.target(character, target)
	task.spawn(BeamFX.Play, character, pos, M.STYLE)
	for i, side in { -1, 1 } do
		task.delay(0.3 + 0.08 * i, function()
			if not character.Parent then return end
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local right = if root then root.CFrame.RightVector else Vector3.xAxis
			BeamFX.Play(character, pos + right * side * math.random(6, 10) + Vector3.new(0, math.random(-2, 3), 0), M.STRAY)
		end)
	end
end

return M
