--!nonstrict
-- MysticAttackVFX (FriezaMajin kit): Maji Kayo has no ki beam, so his signature slot is the Mystic Attack: his
-- right arm stretches across the arena as a chain of shining blue jelly, a swollen fist at the end. It shoots out,
-- splashes on contact and snaps back. Slower and wobblier than a beam; it should look elastic, not energetic.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false).
local RunService = game:GetService("RunService")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.STYLE = {
	Jelly = rgb(70, 170, 255), Shine = rgb(200, 235, 255), Segments = 12, Out = 0.22, Hold = 0.12, Back = 0.25,
	Range = 160, Fist = 3.2, Splash = 10,
}

local function eased(a: number): number
	return 1 - (1 - a) ^ 3
end

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLE
	local root = C.root(character)
	if not root then return end
	local shoulder = C.limb(character, { "RightUpperArm", "Right Arm" })
	local goal = FX.target(character, target)
	local f = C.folder("MysticAttack", s.Out + s.Hold + s.Back + 2)
	local origin = shoulder.Position
	local dir = C.direction(origin, goal)
	local res = workspace:Raycast(origin, dir * s.Range, C.rayParams({ character, f }))
	local length = math.min(if res then (res.Position - origin).Magnitude else (goal - origin).Magnitude, s.Range)
	local segs = {}
	for i = 1, s.Segments do
		local seg = C.part(f, Vector3.one * 1.1, if i % 3 == 0 then s.Shine else s.Jelly, Enum.PartType.Ball, 0.25)
		seg.Material = Enum.Material.Glass
		segs[i] = seg
	end
	local fist = C.part(f, Vector3.one * s.Fist, s.Jelly, Enum.PartType.Ball, 0.1)
	fist.Material = Enum.Material.Glass
	C.light(fist, s.Jelly, 10, 2)
	local t0, splashed = os.clock(), false
	local total = s.Out + s.Hold + s.Back
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local el = os.clock() - t0
		if el > total or not f.Parent then
			conn:Disconnect()
			f:Destroy()
			return
		end
		local reach
		if el < s.Out then
			reach = eased(el / s.Out)
		elseif el < s.Out + s.Hold then
			reach = 1
		else
			reach = 1 - eased((el - s.Out - s.Hold) / s.Back)
		end
		local o = shoulder.Parent and shoulder.Position or origin
		local tip = o + dir * length * reach
		for i, seg in segs do
			local k = i / (s.Segments + 1)
			local sag = math.sin(k * math.pi) * 0.8 * reach -- the arm droops a little in the middle
			seg.Position = o:Lerp(tip, k) - Vector3.new(0, sag, 0)
			seg.Size = Vector3.one * (1 + 0.25 * math.sin(el * 30 + i))
		end
		fist.Position = tip
		if not splashed and reach >= 1 then
			splashed = true
			C.Shockwave(f, CFrame.new(tip), 1, s.Splash, s.Jelly, 0.3)
			local a = C.worldAttachment(tip)
			C.emitter(a, s.Shine, s.Jelly, { Rate = 0, Lifetime = NumberRange.new(0.3, 0.6),
				Speed = NumberRange.new(12, 24), Size = NumberSequence.new(0.6, 0), SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -60, 0) }):Emit(C.q(18))
			game:GetService("Debris"):AddItem(a, 1)
		end
	end)
end

return M
