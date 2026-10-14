--!nonstrict
-- MoroAbsorbVFX (Moro, u7_moro). Energy absorption touch: green-black tendrils from victim into Moro's hand,
-- victim aura drains (dims), Moro glows. Start(moro, victim, config?) -> handle:Stop().  Play(...) = timed (config.Duration).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromRGB(120, 230, 90), DarkColor = Color3.fromRGB(30, 50, 25), Duration = 2, Tendrils = 4,
	SoundId = "", OnTick = nil}
function M.Start(moro, victim, config)
	local c = C.merge(DEFAULTS, config)
	local h = {Active = true}
	local rm, rv = C.root(moro), C.root(victim)
	if not rm or not rv then h.Active = false; function h:Stop() end; return h end
	local f = C.folder("MoroAbsorbVFX", 30)
	C.sound(c.SoundId, rm)
	local hand = C.limb(moro, {"RightHand", "Right Arm"})
	local segs = {}
	for t = 1, c.Tendrils do
		segs[t] = {}
		for i = 1, 10 do segs[t][i] = C.part(f, Vector3.one * 0.35, (i % 2 == 0) and c.Color or c.DarkColor, Enum.PartType.Ball, 0.2) end
	end
	local glow = C.light(rm, c.Color, 6, 1)
	local hl = Instance.new("Highlight")
	hl.FillColor, hl.FillTransparency, hl.OutlineTransparency = Color3.new(0, 0, 0), 1, 1
	hl.Parent = victim
	local va = Instance.new("Attachment"); va.Parent = rv
	local drainFx = C.emitter(va, c.Color, c.DarkColor, {Rate = 40, Lifetime = NumberRange.new(0.3, 0.5), Speed = NumberRange.new(2, 4),
		Size = NumberSequence.new(0.6, 0), SpreadAngle = Vector2.new(180, 180)})
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not (rm.Parent and rv.Parent) then return end
		local k = math.min(1, (os.clock() - t0) / 2)
		local a, b = rv.Position, hand.Position
		local basis = CFrame.lookAt(a, b)
		for t, list in ipairs(segs) do
			for i, s in ipairs(list) do
				local u = ((i / #list) + os.clock() * 1.5) % 1
				local wig = math.sin(u * math.pi * 3 + t * 1.7 + os.clock() * 6) * (1 - u) * 1.5
				s.Position = a:Lerp(b, u) + basis.RightVector * wig * math.cos(t) + basis.UpVector * wig * math.sin(t)
			end
		end
		hl.FillTransparency = 1 - 0.5 * k
		glow.Range, glow.Brightness = 6 + 10 * k, 1 + 4 * k
		if c.OnTick then c.OnTick(k) end
	end)
	function h:Stop()
		if not h.Active then return end
		h.Active = false
		conn:Disconnect()
		drainFx.Enabled = false
		local burst = C.part(f, Vector3.one * 2, c.Color, Enum.PartType.Ball, 0.3)
		burst.Position = rm.Position
		C.tween(burst, 0.4, {Size = Vector3.one * 12, Transparency = 1})
		for _, list in ipairs(segs) do for _, s in ipairs(list) do C.tween(s, 0.3, {Position = hand.Position, Transparency = 1}) end end
		task.delay(0.6, function() hl:Destroy(); va:Destroy(); glow:Destroy(); f:Destroy() end)
	end
	return h
end
function M.Play(moro, victim, config)
	local c = C.merge(DEFAULTS, config)
	local h = M.Start(moro, victim, c)
	task.delay(c.Duration, function() h:Stop() end)
	return h
end
return M
