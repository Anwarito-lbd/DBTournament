--!nonstrict
-- PsychoJavelinVFX (FriezaMajin kit): Moro's Psycho Javelin. A tree trunk, sharpened at one end, rises beside him
-- wrapped in purple telekinetic glow, swings round to point at the target, hangs for a breath, then is thrown.
-- It splinters on impact. Sorcery, not ki: the projectile is wood, and the only energy is the glow holding it.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false).
local RunService = game:GetService("RunService")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.STYLE = { Wood = rgb(105, 72, 45), Glow = rgb(170, 90, 255), Length = 9, Thick = 1.3, Rise = 0.3, Aim = 0.35,
	Speed = 220, Range = 170 }

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLE
	local root = C.root(character)
	if not root then return end
	local goal = FX.target(character, target)
	local f = C.folder("PsychoJavelin", s.Rise + s.Aim + s.Range / s.Speed + 2)
	local trunk = C.part(f, Vector3.new(s.Thick, s.Thick, s.Length), s.Wood, nil, 0)
	trunk.Material = Enum.Material.Wood
	local tip = C.part(f, Vector3.one * s.Thick * 0.9, s.Wood, Enum.PartType.Ball, 0)
	tip.Material = Enum.Material.Wood
	local hold = Instance.new("SelectionBox")
	hold.Adornee, hold.Color3, hold.LineThickness, hold.SurfaceTransparency = trunk, s.Glow, 0.06, 0.8
	hold.SurfaceColor3 = s.Glow
	hold.Parent = trunk
	C.light(trunk, s.Glow, 10, 2)
	local side = root.CFrame.RightVector * -3
	local start = root.Position + side - Vector3.new(0, 3, 0)
	local high = root.Position + side + Vector3.new(0, 5, 0)
	local function place(pos: Vector3, look: Vector3)
		trunk.CFrame = CFrame.lookAt(pos, pos + look)
		tip.Position = pos + look * (s.Length / 2)
	end
	place(start, Vector3.yAxis)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local el = os.clock() - t0
		if not f.Parent then
			conn:Disconnect()
			return
		end
		if el < s.Rise + s.Aim then
			-- rise, then swing the point round toward the target and hold there, trembling
			local k = math.clamp(el / s.Rise, 0, 1)
			local pos = start:Lerp(high, 1 - (1 - k) ^ 2)
			local aim = math.clamp((el - s.Rise * 0.5) / s.Aim, 0, 1)
			local look = Vector3.yAxis:Lerp((goal - pos).Unit, aim).Unit
			place(pos + Vector3.new(0, math.sin(el * 50) * 0.05, 0), look)
			return
		end
		conn:Disconnect()
		local from = trunk.Position
		local dir = (goal - from).Unit
		local res = workspace:Raycast(from, dir * s.Range, C.rayParams({ character, f }))
		local dist = if res then (res.Position - from).Magnitude else s.Range
		local t1 = os.clock()
		local fly
		fly = RunService.RenderStepped:Connect(function()
			local d = math.min(dist, (os.clock() - t1) * s.Speed)
			place(from + dir * d, dir)
			if d >= dist then
				fly:Disconnect()
				local at = from + dir * dist
				C.DebrisBurst(f, at, 8, 34, s.Wood, 1.5)
				C.Shockwave(f, CFrame.new(at), 1, 8, s.Glow, 0.3, 0.2)
				trunk:Destroy()
				tip:Destroy()
			end
		end)
	end)
end

return M
