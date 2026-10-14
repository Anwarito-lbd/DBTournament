--!nonstrict
-- TimeSkipVFX (Hit). Play(character, targetCharacterOrPos, config?). Requires sibling VFXCommon.
-- World desaturates + purple tint, clock-ring ripple, afterimage at start, Hit "reappears" with purple flash, rapid strike flashes on target, world snaps back.
-- Only the local camera's ColorCorrection is touched (client-only). Movement/teleport is server gameplay, not done here.
local C = require(script.Parent:WaitForChild("VFXCommon"))
local Lighting = game:GetService("Lighting")
local M = {}
local DEFAULTS = {
	Duration = 0.6, Hits = 4, Color = Color3.fromRGB(150, 70, 255), CoreColor = Color3.fromRGB(230, 200, 255),
	SkipSoundId = "", HitSoundId = "", OnHit = nil, OnCameraShake = nil,
}
local function afterimage(character, parent, color)
	for _, p in ipairs(character:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			local g = C.part(parent, p.Size, color, nil, 0.4)
			g.CFrame = p.CFrame
			C.tween(g, 0.5, {Transparency = 1})
		end
	end
end
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("TimeSkipVFX", c.Duration + 4)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.SkipSoundId, root)
		afterimage(character, f, c.Color)
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
		C.tween(cc, 0.08, {Saturation = -0.85, TintColor = Color3.fromRGB(215, 190, 255), Contrast = 0.2})
		local ring = C.part(f, Vector3.new(0.2, 2, 2), c.Color, Enum.PartType.Cylinder, 0.3)
		ring.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, math.rad(90))
		C.tween(ring, c.Duration, {Size = Vector3.new(0.1, 80, 80), Transparency = 1}, Enum.EasingStyle.Sine)
		-- "clock hands" sweeping
		for i = 1, 2 do
			local hand = C.part(f, Vector3.new(0.3, 0.2, 6 * i), c.CoreColor, nil, 0.2)
			local center = root.Position
			task.spawn(function()
				local t0 = os.clock()
				while os.clock() - t0 < c.Duration do
					local ang = (os.clock() - t0) * (i == 1 and 20 or 6)
					hand.CFrame = CFrame.new(center) * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.2, -3 * i)
					task.wait()
				end
				hand:Destroy()
			end)
		end
		local tpos = typeof(target) == "Instance" and (target:IsA("Model") and target:GetPivot().Position or target.Position) or target
		task.wait(c.Duration * 0.4)
		for i = 1, c.Hits do
			local p = tpos + Vector3.new(math.random() * 3 - 1.5, math.random() * 3, math.random() * 3 - 1.5)
			local fl = C.part(f, Vector3.one * 0.5, c.CoreColor, Enum.PartType.Ball)
			fl.Position = p
			C.tween(fl, 0.15, {Size = Vector3.one * 4, Transparency = 1})
			C.light(fl, c.Color, 12, 5)
			C.sound(c.HitSoundId, root)
			if c.OnHit then c.OnHit(p, nil) end
			shake(0.8, 0.1)
			task.wait(c.Duration * 0.6 / c.Hits)
		end
		C.tween(cc, 0.15, {Saturation = 0, TintColor = Color3.new(1, 1, 1), Contrast = 0})
		C.explosion(f, tpos, 10, c.Color, c.CoreColor, "", shake)
		task.wait(0.2); cc:Destroy()
		task.wait(1); f:Destroy()
	end)
	return f
end
return M
