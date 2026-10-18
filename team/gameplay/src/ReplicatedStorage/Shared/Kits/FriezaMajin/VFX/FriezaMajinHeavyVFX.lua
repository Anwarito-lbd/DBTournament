--!nonstrict
-- FriezaMajinHeavyVFX (FriezaMajin kit): the contact flourish on each fighter's Heavy (guard-break) strike, played by
-- VFXRouter for the "Heavy" move kind with the server's hit position. Four fighters, four different blows:
--   Frieza  "tail"   - a low crescent from the tail lash, one precise ring, no crater: he doesn't need one.
--   Frost   "needle" - a thin needle flicks out of the wrist, then a toxic violet-green puff lingers on the target.
--   Moro    "drain"  - a dark ring at the palm and green motes pulled from the target back into his hand.
--   Kayo    "fist"   - the Giant Fist: a jelly fist swells at the point of impact, splashes and cracks the ground.
-- World effects only (the striker's camera kick comes from the kit's cameras.Heavy; onlookers get a small shake).
-- Play(character, target, config?) -- client visual only; never deals damage.
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}

-- style: which blow; color/core: main and highlight colours; size: shockwave reach (studs)
M.STYLES = {
	u7_frieza = { style = "tail", color = rgb(200, 120, 255), core = rgb(255, 235, 255), size = 10 },
	u6_frost = { style = "needle", color = rgb(150, 90, 255), core = rgb(150, 255, 120), size = 8 },
	u7_moro = { style = "drain", color = rgb(120, 230, 90), core = rgb(40, 20, 60), size = 9 },
	u3_maji_kayo = { style = "fist", color = rgb(70, 170, 255), core = rgb(210, 240, 255), size = 16 },
}
M.DEFAULT = M.STYLES.u7_frieza

local function burst(pos: Vector3, c1: Color3, c2: Color3, n: number, speed: number, life: number, gravity: number?)
	local a = C.worldAttachment(pos)
	C.emitter(a, c1, c2, { Rate = 0, Lifetime = NumberRange.new(life * 0.5, life), Speed = NumberRange.new(speed * 0.5, speed),
		Size = NumberSequence.new(0.6, 0), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -(gravity or 0), 0) }):Emit(C.q(n))
	Debris:AddItem(a, life + 0.5)
end

local BLOWS = {}

function BLOWS.tail(f: Folder, root: BasePart, pos: Vector3, s: any)
	-- a flat arc swept low across the hit point, right to left, like the tail coming round
	local base = CFrame.lookAt(pos, pos + root.CFrame.LookVector) * CFrame.new(0, -0.6, 0)
	for i = -4, 4 do
		local seg = C.part(f, Vector3.new(0.2, 0.2, 2), if i == 0 then s.core else s.color, nil, 0.15)
		local a = math.rad(i * 14)
		seg.CFrame = base * CFrame.new(math.sin(a) * 4, 0, -math.cos(a) * 1.5 + 1.5) * CFrame.Angles(0, -a + math.rad(90), 0)
		task.delay(0.012 * (i + 4), function()
			C.tween(seg, 0.22, { Transparency = 1, Size = Vector3.new(0.05, 0.05, 3) })
		end)
	end
	C.Shockwave(f, CFrame.new(pos), 1, s.size, s.color, 0.3, 0.15)
end

function BLOWS.needle(f: Folder, root: BasePart, pos: Vector3, s: any, character: Model)
	local wrist = C.limb(character, { "RightHand", "Right Arm" })
	local from = wrist.Position
	local dir = C.direction(from, pos)
	local len = math.max(1, (pos - from).Magnitude)
	local needle = C.part(f, Vector3.new(len, 0.12, 0.12), s.core, Enum.PartType.Cylinder, 0)
	needle.CFrame = C.cylinderCF(from, dir, len)
	C.tween(needle, 0.12, { Transparency = 1 })
	-- the poison: a small violet-green cloud that hangs on the target for a moment
	local a = C.worldAttachment(pos)
	local e = C.emitter(a, s.core, s.color, { Rate = 30, Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(0.5, 2), Size = NumberSequence.new(1.2, 0.2), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 1.5, 0) })
	task.delay(1.2, function() e.Enabled = false end)
	Debris:AddItem(a, 2.5)
	C.Shockwave(f, CFrame.new(pos), 0.5, s.size, s.color, 0.25, 0.1)
end

function BLOWS.drain(f: Folder, root: BasePart, pos: Vector3, s: any, character: Model)
	local hand = C.limb(character, { "RightHand", "Right Arm" })
	C.Shockwave(f, CFrame.new(pos), 1, s.size, s.core, 0.35, 0.3)
	for i = 1, 8 do
		task.delay(0.03 * i, function()
			local mote = C.part(f, Vector3.one * 0.45, s.color, Enum.PartType.Ball, 0.05)
			mote.Position = pos + Vector3.new(math.random(-2, 2), math.random(-1, 2), math.random(-2, 2))
			C.tween(mote, 0.4, { Position = hand.Position, Size = Vector3.one * 0.1 }, Enum.EasingStyle.Quad,
				Enum.EasingDirection.In)
			task.delay(0.42, function() mote:Destroy() end)
		end)
	end
	local glow = C.light(root, s.color, 8, 2)
	Debris:AddItem(glow, 0.6)
end

function BLOWS.fist(f: Folder, root: BasePart, pos: Vector3, s: any, character: Model)
	local fist = C.part(f, Vector3.one * 2, s.color, Enum.PartType.Ball, 0.2)
	fist.Material = Enum.Material.Glass
	fist.Position = pos - root.CFrame.LookVector * 2
	C.tween(fist, 0.12, { Size = Vector3.one * 8, Position = pos }, Enum.EasingStyle.Back)
	task.delay(0.16, function()
		C.tween(fist, 0.2, { Size = Vector3.one * 11, Transparency = 1 })
		burst(pos, s.core, s.color, 22, 26, 0.7, 70)
	end)
	C.Shockwave(f, CFrame.new(pos), 2, s.size, s.color, 0.4)
	local res = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), C.rayParams({ f, character }))
	if res then
		C.GroundCrack(f, res.Position, 6, 6, s.color, 2)
		C.DebrisBurst(f, res.Position, 6, 30, nil, 2)
	end
end

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local s = M.STYLES[FX.id(character) or ""] or M.DEFAULT
	local pos = if typeof(target) == "Vector3" then target else root.Position + root.CFrame.LookVector * 4
	local f = C.folder("FriezaMajinHeavy", 4)
	BLOWS[s.style](f, root, pos, s, character)
	local cam = workspace.CurrentCamera
	if cam and character ~= Players.LocalPlayer.Character then
		local d = (cam.CFrame.Position - pos).Magnitude
		if d < 60 then C.CameraShake(0.2 * (s.size / 12) * (1 - d / 60), 0.25) end
	end
end

return M
