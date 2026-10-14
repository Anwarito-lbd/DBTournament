--!nonstrict
-- Android17BarrierVFX (client). Requires sibling VFXCommon.
--   local b = Android17BarrierVFX.Start(character, config?)  -- green hex-panel dome follows the character
--   b:Hit(worldPos, strength?)   -- ripple + flash on the panel nearest the hit (call when server reports a blocked hit)
--   b:Shatter()                  -- panels fly outward + burst (detonate / break). Calls ArenaDamage on server only if config.ShatterArenaDamage.
--   b:Stop()                     -- fade out normally
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	Radius = 7, Color = Color3.fromRGB(80, 255, 140), EdgeColor = Color3.fromRGB(200, 255, 220), Duration = 2.5,
	Rings = 5, PanelsPerRing = 12, ShatterArenaDamage = false, UpSoundId = "", HitSoundId = "", ShatterSoundId = "",
	OnCameraShake = nil,
}
function M.Start(character, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character)
	local b = {Active = true}
	if not root then b.Active = false; function b:Hit() end; function b:Shatter() end; function b:Stop() end; return b end
	local f = C.folder("A17Barrier", 30)
	C.sound(c.UpSoundId, root)
	local shell = C.part(f, Vector3.one * 0.5, c.Color, Enum.PartType.Ball, 0.82)
	shell.Material = Enum.Material.ForceField
	C.tween(shell, 0.25, {Size = Vector3.one * c.Radius * 2})
	C.light(shell, c.Color, c.Radius * 2.5, 2)
	-- hex-ish panels on a sphere (lat/long tiling with offset rows)
	local panels = {}
	for ring = 0, c.Rings - 1 do
		local lat = math.rad(-60 + ring * (150 / (c.Rings - 1)))
		local count = math.max(4, math.floor(c.PanelsPerRing * math.cos(lat) + 0.5))
		for i = 0, count - 1 do
			local lon = (i + (ring % 2) * 0.5) / count * math.pi * 2
			local dir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
			local w = 2 * math.pi * c.Radius * math.cos(lat) / count * 0.92
			local p = C.part(f, Vector3.new(math.max(w, 0.8), c.Radius * 0.55, 0.12), c.EdgeColor, nil, 0.75)
			table.insert(panels, {p = p, dir = dir})
		end
	end
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not root.Parent then return end
		local center = root.Position
		shell.Position = center
		for _, pn in ipairs(panels) do
			if not pn.flying then
				local pos = center + pn.dir * c.Radius
				pn.p.CFrame = CFrame.lookAt(pos, pos + pn.dir)
			end
		end
	end)
	function b:Hit(pos, strength)
		if not b.Active then return end
		strength = strength or 1
		C.sound(c.HitSoundId, root)
		local center = root.Position
		local hd = (pos - center).Unit
		for _, pn in ipairs(panels) do
			local dot = pn.dir:Dot(hd)
			if dot > 0.6 then
				local delayT = (1 - dot) * 0.6
				task.delay(delayT, function()
					if pn.flying or not pn.p.Parent then return end
					pn.p.Transparency = 0.1
					pn.p.Color = Color3.new(1, 1, 1)
					C.tween(pn.p, 0.35, {Transparency = 0.75, Color = c.EdgeColor})
				end)
			end
		end
		local ripple = C.part(f, Vector3.new(0.2, 1, 1), c.EdgeColor, Enum.PartType.Cylinder, 0.2)
		local hp = center + hd * c.Radius
		ripple.CFrame = CFrame.lookAt(hp, hp + hd) * CFrame.Angles(0, math.rad(90), 0)
		C.tween(ripple, 0.4, {Size = Vector3.new(0.1, c.Radius * 1.5 * strength, c.Radius * 1.5 * strength), Transparency = 1})
		game:GetService("Debris"):AddItem(ripple, 0.5)
		shell.Transparency = 0.6
		C.tween(shell, 0.3, {Transparency = 0.82})
	end
	local function finish(t)
		b.Active = false
		task.delay(t, function() if conn then conn:Disconnect() end; f:Destroy() end)
	end
	function b:Shatter()
		if not b.Active then return end
		C.sound(c.ShatterSoundId, root)
		local center = root.Position
		for _, pn in ipairs(panels) do
			pn.flying = true
			pn.p.Transparency = 0.2
			C.tween(pn.p, 0.7, {CFrame = pn.p.CFrame * CFrame.new(0, 0, -(8 + math.random() * 10)) * CFrame.Angles(math.random() * 3, math.random() * 3, 0), Transparency = 1})
		end
		C.tween(shell, 0.2, {Size = Vector3.one * c.Radius * 3, Transparency = 1})
		C.explosion(f, center, c.Radius * 3, c.Color, c.EdgeColor, "", c.OnCameraShake or C.shake)
		if c.ShatterArenaDamage then C.arenaDamage(c, center, 12, 40) end
		finish(1)
	end
	function b:Stop()
		if not b.Active then return end
		for _, pn in ipairs(panels) do C.tween(pn.p, 0.3, {Transparency = 1}) end
		C.tween(shell, 0.3, {Transparency = 1, Size = Vector3.one * 0.5})
		finish(0.4)
	end
	if c.Duration and c.Duration > 0 then task.delay(c.Duration, function() b:Stop() end) end
	return b
end
return M
