--!strict
-- KaiokenVFX: Goku's crimson multiplier surge & double-aura.
-- Start(character, multiplier, config?) -> handle with :Stop(), :SetMultiplier(n)
-- Play(character, config?) -> one-shot surge
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))

local M = {}

local DEFAULTS = {
	Duration = 8,
	Multiplier = 1, -- 1 = Base Kaioken, 3 = x3, 4 = x4, 10 = x10, 20 = x20
	Color = Color3.fromRGB(255, 25, 45),
	InnerColor = Color3.fromRGB(255, 230, 210),
	SecondaryColor = Color3.fromRGB(200, 10, 30),
	SoundId = "",
	BurstSoundId = "",
	ParticleTexture = "",
	ArenaDamage = false,
}

export type KaiokenHandle = {
	Stop: () -> (),
	SetMultiplier: (n: number) -> (),
	Burst: () -> (),
}

function M.Start(character: Model, multiplier: number?, config: { [string]: any }?): KaiokenHandle?
	local c = C.merge(DEFAULTS, config)
	local mult = multiplier or c.Multiplier or 1
	local root = C.root(character)
	if not root then
		return nil
	end

	local f = C.folder("KaiokenVFX", c.Duration + 5)
	local active = true

	-- Crimson outer flame aura
	local att = Instance.new("Attachment")
	att.Name = "KaiokenAuraAtt"
	att.Position = Vector3.new(0, -1.8, 0)
	att.Parent = root

	local outerFlame = C.emitter(att, c.Color, c.SecondaryColor, {
		Rate = C.q(45 + mult * 5),
		Lifetime = NumberRange.new(0.35, 0.65),
		Speed = NumberRange.new(8 + mult * 2, 18 + mult * 3),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.8 + mult * 0.1),
			NumberSequenceKeypoint.new(0.5, 3.2 + mult * 0.2),
			NumberSequenceKeypoint.new(1, 0.4),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.6, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Acceleration = Vector3.new(0, 35, 0),
		Drag = 1.5,
		SpreadAngle = Vector2.new(15, 15),
	}, c.ParticleTexture)

	-- Inner white-hot surge
	local innerSurge = C.emitter(att, c.InnerColor, c.Color, {
		Rate = C.q(25 + mult * 3),
		Lifetime = NumberRange.new(0.2, 0.4),
		Speed = NumberRange.new(6, 14),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.2),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Acceleration = Vector3.new(0, 45, 0),
	}, c.ParticleTexture)

	-- PointLight with subtle flicker
	local lt = C.light(root, c.Color, 14 + mult * 2, 3.5 + mult * 0.5)

	-- Heartbeat rumble
	local pulseConn: RBXScriptConnection? = nil
	pulseConn = RunService.Heartbeat:Connect(function()
		if not active or not root.Parent then
			return
		end
		lt.Brightness = (3.5 + mult * 0.5) * (0.85 + 0.3 * math.sin(os.clock() * 18))
	end)

	local function stop()
		if not active then
			return
		end
		active = false
		if pulseConn then
			pulseConn:Disconnect()
			pulseConn = nil
		end
		outerFlame.Rate = 0
		innerSurge.Rate = 0
		C.tween(lt, 0.4, { Brightness = 0, Range = 0 })
		task.delay(1, function()
			if f.Parent then
				f:Destroy()
			end
		end)
	end

	local function setMultiplier(n: number)
		mult = math.clamp(n, 1, 20)
		outerFlame.Rate = C.q(45 + mult * 5)
		innerSurge.Rate = C.q(25 + mult * 3)
		lt.Range = 14 + mult * 2
	end

	local function burst()
		C.sound(c.BurstSoundId, root)
		C.FOVPunch(6)
		if C.SpeedLines then
			C.SpeedLines(0.4, c.Color, C.q(35))
		end
		outerFlame:Emit(C.q(30))
		innerSurge:Emit(C.q(20))
	end

	-- Initial activation pop
	burst()

	return {
		Stop = stop,
		SetMultiplier = setMultiplier,
		Burst = burst,
	}
end

function M.Play(character: Model, config: { [string]: any }?)
	local h = M.Start(character, (config and config.Multiplier) or 1, config)
	if h then
		local dur = (config and config.Duration) or DEFAULTS.Duration
		task.delay(dur, function()
			h.Stop()
		end)
	end
end

return M
