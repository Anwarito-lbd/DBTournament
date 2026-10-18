--!nonstrict
-- SubmissionVFX (FriezaMajin kit): Maji Kayo goes semi-liquid and wraps the target: a translucent blue jelly sphere
-- closes over them, wobbles while it holds (the server's hitstun is the hold), then bursts into droplets. The
-- jelly follows the victim when one stands at the hit point; otherwise it stays where it landed.
-- Play(character, target, config?) -- client visual only.
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
-- Hold matches the Submission move's hitstun in the kit (init.lua)
M.STYLE = { Jelly = rgb(70, 170, 255), Shine = rgb(210, 240, 255), Size = 7, Close = 0.18, Hold = 1.2 }

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLE
	local pos = FX.target(character, target)
	local victim = FX.victimNear(character, pos, 7)
	local vroot = victim and victim:FindFirstChild("HumanoidRootPart") :: BasePart?
	local f = C.folder("Submission", s.Close + s.Hold + 2)
	local blob = C.part(f, Vector3.one * 1, s.Jelly, Enum.PartType.Ball, 0.45)
	blob.Material = Enum.Material.Glass
	blob.Position = pos
	C.light(blob, s.Jelly, 10, 1.5)
	C.tween(blob, s.Close, { Size = Vector3.one * s.Size }, Enum.EasingStyle.Back)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local el = os.clock() - t0
		if el > s.Close + s.Hold or not f.Parent then
			conn:Disconnect()
			local at = blob.Position
			local a = C.worldAttachment(at)
			C.emitter(a, s.Shine, s.Jelly, { Rate = 0, Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(10, 22),
				Size = NumberSequence.new(0.7, 0), SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -60, 0) }):Emit(C.q(24))
			Debris:AddItem(a, 1)
			C.tween(blob, 0.15, { Size = Vector3.one * s.Size * 1.3, Transparency = 1 })
			return
		end
		if vroot and vroot.Parent then blob.Position = vroot.Position end
		if el > s.Close then
			local w = 1 + 0.08 * math.sin(el * 18)
			blob.Size = Vector3.new(s.Size * w, s.Size / w, s.Size * w)
		end
	end)
end

return M
