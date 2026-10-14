--!nonstrict
-- MUIRushVFX (Goku MUI ultimate). Silver afterimage strikes around target + final palm burst.
-- Play(character, target(Model|BasePart|Vector3), config?).
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromRGB(221, 230, 255), CoreColor = Color3.new(1, 1, 1), Hits = 8, Interval = 0.08,
	FinalSize = 35, OnHit = nil, OnCameraShake = nil, HitSoundId = "", FinalSoundId = "", ArenaRadius = 16, ArenaPower = 110}
local function ghost(character, f, cf, color)
	local root = C.root(character)
	for _, p in ipairs(character:GetChildren()) do
		if p:IsA("BasePart") and p ~= root then
			local g = C.part(f, p.Size, color, nil, 0.35)
			g.CFrame = cf * root.CFrame:ToObjectSpace(p.CFrame)
			C.tween(g, 0.35, {Transparency = 1})
		end
	end
end
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("MUIRushVFX", c.Hits * c.Interval + 4)
	local shake = c.OnCameraShake or C.shake
	local function tpos()
		if typeof(target) == "Instance" then return target:IsA("Model") and target:GetPivot().Position or target.Position end
		return target
	end
	task.spawn(function()
		local hl = Instance.new("Highlight")
		hl.OutlineColor, hl.FillTransparency = c.Color, 1
		hl.Parent = character
		for i = 1, c.Hits do
			local p = tpos()
			local ang = i * 2.4
			local at = p + Vector3.new(math.cos(ang) * 4, math.random() * 2, math.sin(ang) * 4)
			ghost(character, f, CFrame.lookAt(at, p), c.Color)
			C.Afterimage(character, c.Color, 0.3, 0.45)
			if typeof(target) == "Instance" and target:IsA("Model") then C.Hitstop({character, target}, "Light") end
			local s = C.part(f, Vector3.one * 0.6, c.CoreColor, Enum.PartType.Ball)
			s.Position = p:Lerp(at, 0.4)
			C.tween(s, 0.12, {Size = Vector3.one * 4, Transparency = 1})
			C.sound(c.HitSoundId, root)
			if c.OnHit then c.OnHit(s.Position, nil) end
			shake(0.6, 0.08)
			task.wait(c.Interval)
		end
		-- final palm burst
		local p = tpos()
		C.sound(c.FinalSoundId, root)
		C.Hitstop(typeof(target) == "Instance" and target:IsA("Model") and {character, target} or {character}, "Finisher")
		task.wait(C.HITSTOP.Finisher / 60)
		C.ImpactFrame("invert", 3, typeof(target) == "Instance" and target:IsA("Model") and {character, target} or {character})
		C.SpeedLines(0.4, c.Color)
		local wave = C.part(f, Vector3.new(0.3, 3, 3), c.Color, Enum.PartType.Cylinder, 0.1)
		wave.CFrame = CFrame.lookAt(root.Position, p) * CFrame.Angles(0, math.rad(90), 0) + (p - root.Position) * 0.5
		C.tween(wave, 0.4, {Size = Vector3.new(0.1, c.FinalSize, c.FinalSize), Transparency = 1})
		C.arenaDamage(c, p, c.ArenaRadius, c.ArenaPower)
		C.explosion(f, p, c.FinalSize, c.Color, c.CoreColor, "", shake)
		task.wait(0.6)
		hl:Destroy()
		task.wait(1)
		f:Destroy()
	end)
	return f
end
return M
