--!nonstrict
-- NovaStrikeVFX (Frieza). Body enveloped in energy sphere, shoulder-charge rush with trail, explosion on contact.
-- Play(character, target, config?) ; movement is server-side (this follows the root); config.Duration = rush length.
-- Black Frieza signature uses config preset M.BLACK (see BlackFriezaVFX / movesets_v4).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromHex("C77DFF"), CoreColor = Color3.fromHex("FFB0F0"), Size = 9, Duration = 0.9,
	ImpactSize = 30, SoundId = "", ImpactSoundId = "", OnHit = nil, OnCameraShake = nil, ArenaRadius = 14, ArenaPower = 90}
M.BLACK = {Color = Color3.fromRGB(150, 40, 110), CoreColor = Color3.fromRGB(25, 10, 30), Size = 11, ImpactSize = 45, ArenaRadius = 20, ArenaPower = 140}
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("NovaStrikeVFX", c.Duration + 3)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.SoundId, root)
		local sphere = C.part(f, Vector3.one * c.Size, c.Color, Enum.PartType.Ball, 0.45)
		local inner = C.part(f, Vector3.one * c.Size * 0.7, c.CoreColor, Enum.PartType.Ball, 0.6)
		C.light(sphere, c.Color, 20, 5)
		local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, c.Size * 0.3, 0); a0.Parent = sphere
		local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -c.Size * 0.3, 0); a1.Parent = sphere
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(c.Color, c.CoreColor)
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Lifetime, trail.LightEmission = 0.4, 1
		trail.Parent = sphere
		local params = C.rayParams({character, f})
		C.SpeedLines(c.Duration, c.CoreColor, 36)
		C.FOVPunch(8)
		local lastAI = 0
		local t0, hit = os.clock(), nil
		while os.clock() - t0 < c.Duration and root.Parent do
			RunService.Heartbeat:Wait()
			sphere.Position, inner.Position = root.Position, root.Position
			inner.Size = Vector3.one * c.Size * (0.7 + 0.08 * math.sin(os.clock() * 40))
			if os.clock() - lastAI > 0.06 then lastAI = os.clock(); C.Afterimage(character, c.Color, 0.25, 0.5) end
			local d = C.direction(root.Position, target)
			local res = workspace:Raycast(root.Position, d * (c.Size * 0.6), params)
			if res then hit = res; break end
		end
		local pos = hit and hit.Position or root.Position
		if hit and c.OnHit then c.OnHit(pos, hit.Instance) end
		if hit then
			local victim = hit.Instance:FindFirstAncestorOfClass("Model")
			C.Hitstop(victim and {character, victim} or {character}, "Heavy")
		end
		C.sound(c.ImpactSoundId, root)
		C.arenaDamage(c, pos, c.ArenaRadius, c.ArenaPower)
		C.explosion(f, pos, c.ImpactSize, c.Color, c.CoreColor, "", shake)
		C.tween(sphere, 0.2, {Transparency = 1}); C.tween(inner, 0.2, {Transparency = 1})
		task.wait(1.2)
		f:Destroy()
	end)
	return f
end
return M
