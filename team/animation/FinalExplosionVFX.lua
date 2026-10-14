--!nonstrict
-- FinalExplosionVFX (Vegeta ultimate, self-KO). Gold aura swells, cracks of light over body, white sphere expands to Radius,
-- lingering smoke. Play(character, config?) ; config.OnDetonate(pos) fires at the blast (server applies damage + KO).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {ChargeTime = 2, Radius = 60, Color = Color3.fromHex("FFD84A"), CoreColor = Color3.new(1, 1, 1),
	ChargeSoundId = "", BlastSoundId = "", OnDetonate = nil, OnCameraShake = nil, ArenaRadius = 35, ArenaPower = 220}
function M.Play(character, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("FinalExplosionVFX", c.ChargeTime + 8)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.ChargeSoundId, root)
		local att = Instance.new("Attachment"); att.Parent = root
		local aura = C.emitter(att, c.CoreColor, c.Color, {Rate = 80, Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(8, 14),
			Size = NumberSequence.new(2, 0), Acceleration = Vector3.new(0, 30, 0), LockedToPart = true})
		local light = C.light(root, c.Color, 10, 3)
		local hl = Instance.new("Highlight")
		hl.FillColor, hl.OutlineColor, hl.FillTransparency = c.Color, c.CoreColor, 1
		hl.Parent = character
		-- light cracks on body: thin neon strips welded visually (follow root)
		local cracks = {}
		for i = 1, 8 do
			local s = C.part(f, Vector3.new(0.12, 1 + math.random() * 1.5, 0.12), c.CoreColor, nil, 1)
			cracks[i] = {p = s, off = CFrame.new(math.random() * 1.6 - 0.8, math.random() * 3 - 1.5, -0.6) * CFrame.Angles(0, 0, math.random() * 3)}
		end
		local t0 = os.clock()
		while os.clock() - t0 < c.ChargeTime and root.Parent do
			local k = (os.clock() - t0) / c.ChargeTime
			aura.Rate = 80 + 300 * k
			light.Range, light.Brightness = 10 + 40 * k, 3 + 10 * k
			hl.FillTransparency = 1 - 0.7 * k
			for i, cr in ipairs(cracks) do
				cr.p.CFrame = root.CFrame * cr.off
				cr.p.Transparency = (i / #cracks) < k and 0 or 1
			end
			if math.random() < 0.15 then shake(0.5 + 2 * k, 0.2) end
			if k > 0.5 and math.random() < 0.05 then C.FOVPunch(-1.5) end
			RunService.Heartbeat:Wait()
		end
		local pos = root.Position
		C.sound(c.BlastSoundId, root)
		if c.OnDetonate then task.spawn(c.OnDetonate, pos) end
		C.arenaDamage(c, pos, c.ArenaRadius, c.ArenaPower)
		aura.Enabled = false
		hl:Destroy()
		for _, cr in ipairs(cracks) do cr.p:Destroy() end
		C.ImpactFrame("invert", 3, {character})
		C.FOVPunch(18)
		C.Shockwave(f, CFrame.new(pos), 4, c.Radius * 2.5, c.Color, 0.8, 0.8)
		local gr = workspace:Raycast(pos, Vector3.new(0, -20, 0), C.rayParams({character, f}))
		if gr then
			C.GroundCrack(f, gr.Position, c.Radius * 0.5, 16, c.Color, 5)
			C.DebrisBurst(workspace, gr.Position, 24, 90, nil, 3.5)
		end
		local sphere = C.part(f, Vector3.one * 4, c.CoreColor, Enum.PartType.Ball)
		sphere.Position = pos
		C.light(sphere, c.Color, 120, 20)
		C.tween(sphere, 1.2, {Size = Vector3.one * c.Radius * 2}, Enum.EasingStyle.Quart)
		shake(5, 1.5)
		task.wait(1.4)
		C.tween(sphere, 0.8, {Transparency = 1, Color = c.Color})
		-- lingering smoke
		local sa = C.worldAttachment(pos)
		local smoke = C.emitter(sa, Color3.fromRGB(90, 85, 80), Color3.fromRGB(40, 38, 36), {Rate = 0, Lifetime = NumberRange.new(3, 5),
			Speed = NumberRange.new(5, 15), Size = NumberSequence.new(8, 20), SpreadAngle = Vector2.new(180, 60), Drag = 1})
		smoke.LightEmission = 0
		smoke:Emit(40)
		game:GetService("Debris"):AddItem(sa, 6)
		att:Destroy(); light:Destroy()
		task.wait(4)
		f:Destroy()
	end)
	return f
end
return M
