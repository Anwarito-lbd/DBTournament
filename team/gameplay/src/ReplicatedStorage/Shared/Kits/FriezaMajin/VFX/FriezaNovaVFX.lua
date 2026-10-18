--!nonstrict
-- FriezaNovaVFX (FriezaMajin kit): Frieza's Nova Strike, the energy-wrapped tackle that pushed Jiren out of the
-- ring. An energy sphere closes around him, streaks to the hit point with afterimages and bursts there.
-- Base and 100%: violet; Golden: gold; Black Frieza: crimson on black, and a void opens at the hit a beat later
-- before it detonates (the Black Nova). The server resolves the hit as a melee without moving him, so the sphere
-- travels on its own and the burst lands on the target, not on Frieza (the shared NovaStrikeVFX follows the root
-- and would explode in place).
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false).
local RunService = game:GetService("RunService")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.FORMS = {
	Base = { Color = rgb(199, 125, 255), Core = rgb(255, 176, 240), Size = 8, Impact = 26 },
	Golden = { Color = rgb(255, 196, 0), Core = rgb(255, 245, 190), Size = 9, Impact = 32 },
	FriezaBlack = { Color = rgb(150, 40, 110), Core = rgb(25, 10, 30), Size = 10, Impact = 38, Void = true },
}
M.WRAP, M.TRAVEL = 0.15, 0.18

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local s = M.FORMS[FX.form(character) or "Base"] or M.FORMS.Base
	local goal = FX.target(character, target)
	local f = C.folder("FriezaNova", 4)
	local sphere = C.part(f, Vector3.one * 2, s.Color, Enum.PartType.Ball, 0.45)
	local inner = C.part(f, Vector3.one * 1.4, s.Core, Enum.PartType.Ball, 0.55)
	sphere.Position, inner.Position = root.Position, root.Position
	C.light(sphere, s.Color, 18, 4)
	C.tween(sphere, M.WRAP, { Size = Vector3.one * s.Size })
	C.tween(inner, M.WRAP, { Size = Vector3.one * s.Size * 0.7 })
	if character == game:GetService("Players").LocalPlayer.Character then C.SpeedLines(M.WRAP + M.TRAVEL, s.Core, 30) end
	task.delay(M.WRAP, function()
		local from = root.Position
		local t0, lastAI = os.clock(), 0
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - t0) / M.TRAVEL, 0, 1)
			local p = from:Lerp(goal, k)
			sphere.Position, inner.Position = p, p
			if os.clock() - lastAI > 0.05 then
				lastAI = os.clock()
				C.Afterimage(character, s.Color, 0.25, 0.5)
			end
			if k >= 1 then
				conn:Disconnect()
				C.tween(sphere, 0.15, { Transparency = 1 })
				C.tween(inner, 0.15, { Transparency = 1 })
				if not s.Void then
					C.explosion(f, goal, s.Impact, s.Color, s.Core, "", C.shake)
					return
				end
				-- Black Nova: a black void swells on the target, then bursts
				local void = C.part(f, Vector3.one * 2, rgb(10, 0, 15), Enum.PartType.Ball, 0)
				void.Material = Enum.Material.SmoothPlastic
				void.Position = goal
				C.tween(void, 0.3, { Size = Vector3.one * 16 }, Enum.EasingStyle.Back)
				task.delay(0.35, function()
					C.ImpactFrame("invert", 3, { character })
					C.explosion(f, goal, s.Impact, s.Color, rgb(255, 60, 120), "", C.shake)
					C.tween(void, 0.3, { Transparency = 1 })
				end)
			end
		end)
	end)
end

return M
