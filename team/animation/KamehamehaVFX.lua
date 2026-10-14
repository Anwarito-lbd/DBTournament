--!nonstrict
-- KamehamehaVFX (ModuleScript) - client-side visual only.
-- Built-in Instances only. Optional asset ids in DEFAULTS (empty = none).
-- Replication: server validates the cast and fires a RemoteEvent
-- ArenaDamage: server calls ServerScriptService.ArenaDamage.DamageAt(hitPos, 18, 120).
-- (e.g. ReplicatedStorage.Remotes.PlayVFX:FireAllClients("Kamehameha", character, targetPos))
-- and each client calls KamehamehaVFX.Play. Damage/hit logic stays on the server.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local KamehamehaVFX = {}
-- v5: if a sibling VFXCommon exists, use its quality primitives (BeamCore, ImpactFrame, spring shake, FOV punch,
-- speed lines, shockwave, cracks, debris). Still works standalone without it.
local CM: any = nil
do
	local ok, mod = pcall(function()
		local m = script.Parent and script.Parent:FindFirstChild("VFXCommon")
		return m and require(m)
	end)
	if ok then CM = mod end
end

export type Config = {
	ChargeTime: number?, BeamTime: number?, BeamSpeed: number?, MaxRange: number?,
	BeamWidth: number?, Color: Color3?, CoreColor: Color3?, Tracking: boolean?,
	TrackTarget: BasePart?, ImpactSize: number?, ParticleTexture: string?,
	ChargeSoundId: string?, FireSoundId: string?, ImpactSoundId: string?,
	OnCameraShake: ((intensity: number, duration: number) -> ())?,
	OnHit: ((hitPos: Vector3, hitPart: BasePart?) -> ())?,
	ArenaDamage: boolean?, ArenaDamagePath: {string}?, ArenaRadius: number?, ArenaPower: number?,
	OnArenaDamage: ((pos: Vector3, radius: number, power: number) -> ())?,
}

local DEFAULTS = {
	ChargeTime = 1.2, BeamTime = 1.5, BeamSpeed = 400, MaxRange = 300,
	BeamWidth = 4, Color = Color3.fromRGB(80, 170, 255), CoreColor = Color3.fromRGB(230, 250, 255),
	Tracking = false, ImpactSize = 22, ParticleTexture = "",
	ChargeSoundId = "rbxassetid://112589551277234", FireSoundId = "rbxassetid://112589551277234", ImpactSoundId = "rbxassetid://106108995063585",
	-- db-map ArenaDamage hook (call server-side in multiplayer; see README)
	ArenaDamage = nil, ArenaDamagePath = {"ServerScriptService", "ArenaDamage"}, ArenaRadius = 18, ArenaPower = 120,
	OnArenaDamage = nil,
}

local function arenaDamage(c: any, pos: Vector3)
	local enabled = c.ArenaDamage
	if enabled == nil then enabled = RunService:IsServer() end -- default off on clients
	if not enabled then return end
	if c.OnArenaDamage then task.spawn(c.OnArenaDamage, pos, c.ArenaRadius, c.ArenaPower) return end
	if not RunService:IsServer() then return end -- ArenaDamage is server-only (ServerScriptService.ArenaDamage)
	local ok, mod = pcall(function()
		local node: any = game:GetService(c.ArenaDamagePath[1])
		for i = 2, #c.ArenaDamagePath do node = node and node:FindFirstChild(c.ArenaDamagePath[i]) end
		return node and node:IsA("ModuleScript") and require(node) or nil
	end)
	if ok and mod and mod.DamageAt then
		local ok2, err = pcall(mod.DamageAt, pos, c.ArenaRadius, c.ArenaPower)
		if not ok2 then warn("ArenaDamage.DamageAt failed:", err) end
	end
end

local function cfg(c: Config?): any
	local out = table.clone(DEFAULTS) :: any
	if c then for k, v in pairs(c :: any) do out[k] = v end end
	return out
end

local function part(parent: Instance, size: Vector3, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function sound(id: string, parent: Instance)
	if id == "" then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 6)
end

local function emitter(parent: Instance, c: any, props: {[string]: any}): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(c.CoreColor, c.Color)
	e.LightEmission = 1
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	if c.ParticleTexture ~= "" then e.Texture = c.ParticleTexture end
	for k, v in pairs(props) do (e :: any)[k] = v end
	e.Parent = parent
	return e
end

local function tween(i: Instance, t: number, goal: {[string]: any}, style: Enum.EasingStyle?)
	local tw = TweenService:Create(i, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

local function handsPosition(character: Model): Vector3
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local l = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	local r = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if l and r and l:IsA("BasePart") and r:IsA("BasePart") then
		return (l.Position + r.Position) / 2
	end
	return root and (root.Position + root.CFrame.LookVector * 2) or Vector3.zero
end

-- Default camera shake (local player camera). Override via config.OnCameraShake.
function KamehamehaVFX.DefaultShake(intensity: number, duration: number)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local a = os.clock() - t0
		if a > duration then conn:Disconnect() return end
		local k = intensity * (1 - a / duration)
		cam.CFrame *= CFrame.Angles(math.rad((math.random() - 0.5) * k), math.rad((math.random() - 0.5) * k), 0)
	end)
end

-- target: Vector3 world position, or a direction Vector3 when `isDirection` (unit-length) is used;
-- a Vector3 with magnitude <= 1.01 is treated as a direction.
function KamehamehaVFX.Play(character: Model, target: Vector3, config: Config?)
	local c = cfg(config)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	local folder = Instance.new("Folder")
	folder.Name = "KamehamehaVFX"
	folder.Parent = workspace
	Debris:AddItem(folder, c.ChargeTime + c.BeamTime + 5) -- hard safety cleanup
	local shake = c.OnCameraShake or (CM and CM.CameraShake) or KamehamehaVFX.DefaultShake

	local function dir(): Vector3
		local origin = handsPosition(character)
		if c.Tracking and c.TrackTarget and c.TrackTarget.Parent then
			return (c.TrackTarget.Position - origin).Unit
		elseif target.Magnitude <= 1.01 then
			return target.Unit
		end
		return (target - origin).Unit
	end

	task.spawn(function()
		-- PHASE 1: CHARGE
		sound(c.ChargeSoundId, root)
		local orb = part(folder, Vector3.one * 0.3, c.CoreColor, Enum.PartType.Ball)
		local glow = part(folder, Vector3.one * 0.6, c.Color, Enum.PartType.Ball)
		glow.Transparency = 0.5
		local att = Instance.new("Attachment"); att.Parent = orb
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = c.Color, 4, 2
		light.Parent = orb
		emitter(att, c, {
			Rate = 60, Lifetime = NumberRange.new(0.3, 0.5), Speed = NumberRange.new(-12, -8),
			Size = NumberSequence.new(0.4, 0), Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, SpreadAngle = Vector2.new(180, 180),
		}) -- negative speed + sphere shell => particles gather inward
		-- quality bar: Kamehameha charge = 54f anticipation; slow FOV zoom-in, spark ring, light swell
		if CM then CM.FOVPunch(-5) end
		local t0 = os.clock()
		while os.clock() - t0 < c.ChargeTime and character.Parent do
			local a = (os.clock() - t0) / c.ChargeTime
			local p = handsPosition(character)
			orb.Position, glow.Position = p, p
			orb.Size = Vector3.one * (0.3 + a * 1.7)
			glow.Size = Vector3.one * (0.6 + a * 3) * (1 + 0.08 * math.sin(os.clock() * 40))
			light.Range, light.Brightness = 4 + a * 14, 2 + a * 4
			RunService.Heartbeat:Wait()
		end
		glow:Destroy()
		if not character.Parent then folder:Destroy() return end

		-- PHASE 2: BEAM
		sound(c.FireSoundId, root)
		shake(1.2, c.BeamTime)
		local bc: any = nil
		if CM then
			-- release: 1 white impact frame, FOV punch out, speed lines for 24f
			CM.ImpactFrame("white", 1)
			CM.FOVPunch(10)
			CM.SpeedLines(0.4, c.CoreColor)
			CM.Shockwave(folder, CFrame.lookAt(handsPosition(character), handsPosition(character) + dir()) * CFrame.Angles(0, math.rad(90), 0), 1, c.BeamWidth * 3, c.Color, 0.3)
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character, folder}
		local beam = part(folder, Vector3.new(0.1, c.BeamWidth, c.BeamWidth), c.Color, Enum.PartType.Cylinder)
		beam.Transparency = 0.25
		local core = part(folder, Vector3.new(0.1, c.BeamWidth * 0.5, c.BeamWidth * 0.5), c.CoreColor, Enum.PartType.Cylinder)
		if CM then
			bc = CM.BeamCore(folder, {Width = c.BeamWidth, Core = c.CoreColor, Inner = c.Color, Outer = c.Color})
			beam.Transparency, core.Transparency = 1, 1
		end
		local tip = part(folder, Vector3.one * c.BeamWidth * 1.4, c.Color, Enum.PartType.Ball)
		tip.Transparency = 0.3
		local tipAtt = Instance.new("Attachment"); tipAtt.Parent = tip
		local tipFx = emitter(tipAtt, c, {
			Rate = 80, Lifetime = NumberRange.new(0.2, 0.4), Speed = NumberRange.new(10, 20),
			Size = NumberSequence.new(1.2, 0), SpreadAngle = Vector2.new(180, 180),
		})
		local beamLight = Instance.new("PointLight")
		beamLight.Color, beamLight.Range, beamLight.Brightness = c.Color, 24, 6
		beamLight.Parent = tip

		local length, hitPos, hitPart = 0, nil :: Vector3?, nil :: BasePart?
		local fireStart = os.clock()
		while os.clock() - fireStart < c.BeamTime and character.Parent do
			local dt = RunService.Heartbeat:Wait()
			local origin = handsPosition(character)
			local d = dir()
			if hitPos == nil then length = math.min(length + c.BeamSpeed * dt, c.MaxRange) end
			local result = workspace:Raycast(origin, d * length, params)
			if result then
				length = (result.Position - origin).Magnitude
				if hitPos == nil then
					hitPos, hitPart = result.Position, result.Instance :: BasePart
					if c.OnHit then c.OnHit(result.Position, result.Instance :: BasePart) end
				end
				hitPos = result.Position
			elseif hitPos then
				hitPos = nil -- tracking moved off target; keep extending
			end
			local pulse = 1 + 0.06 * math.sin(os.clock() * 50)
			local cf = CFrame.lookAt(origin, origin + d) * CFrame.new(0, 0, -length / 2) * CFrame.Angles(0, math.rad(90), 0)
			beam.CFrame, core.CFrame = cf, cf
			beam.Size = Vector3.new(length, c.BeamWidth * pulse, c.BeamWidth * pulse)
			core.Size = Vector3.new(length, c.BeamWidth * 0.5, c.BeamWidth * 0.5)
			if bc then bc:Update(origin, d, length) end
			tip.Position = origin + d * length
			orb.Position = origin
		end
		if bc then bc:Fade(0.25) end
		tipFx.Enabled = false
		local endPos = tip.Position
		for _, p in ipairs({beam, core, orb, tip}) do
			tween(p, 0.25, {Transparency = 1})
		end

		-- PHASE 3: IMPACT
		sound(c.ImpactSoundId, root)
		if CM then
			CM.Impact(folder, endPos, c.ImpactSize, c.Color, c.CoreColor, "Ultimate", {Subjects = {character}})
		else
			shake(3, 0.5)
		end
		arenaDamage(c, endPos)
		local boom = part(folder, Vector3.one * 2, c.CoreColor, Enum.PartType.Ball)
		boom.Position = endPos
		tween(boom, 0.4, {Size = Vector3.one * c.ImpactSize, Transparency = 1, Color = c.Color})
		local ring = part(folder, Vector3.new(0.4, 2, 2), c.Color, Enum.PartType.Cylinder)
		ring.CFrame = CFrame.new(endPos) * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.2
		tween(ring, 0.5, {Size = Vector3.new(0.2, c.ImpactSize * 2, c.ImpactSize * 2), Transparency = 1})
		local burstAtt = Instance.new("Attachment")
		burstAtt.WorldPosition = endPos
		burstAtt.Parent = workspace.Terrain
		local burst = emitter(burstAtt, c, {
			Rate = 0, Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(30, 60),
			Size = NumberSequence.new(2, 0), SpreadAngle = Vector2.new(180, 180), Drag = 4,
		})
		burst:Emit(60)
		local flash = Instance.new("PointLight")
		flash.Color, flash.Range, flash.Brightness = c.Color, 40, 10
		flash.Parent = boom
		Debris:AddItem(burstAtt, 1.5)
		task.wait(1)
		folder:Destroy()
	end)
	return folder
end

-- v1.1 quality pass: delegate the visible beam to BeamFX (core + glow + spiral, charge sphere, big impact, shake).
-- Legacy implementation kept as KamehamehaVFX.LegacyPlay.
do
	local BeamFX = require(script.Parent:WaitForChild("BeamFX"))
	KamehamehaVFX.LegacyPlay = KamehamehaVFX.Play
	KamehamehaVFX.Play = function(character, target, config)
		return BeamFX.Play(character, target, "Kamehameha", nil)
	end
end
return KamehamehaVFX
