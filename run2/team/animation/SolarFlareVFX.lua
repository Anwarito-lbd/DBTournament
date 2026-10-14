--!strict
-- SolarFlareVFX: Tien Shinhan's Taiyoken / blinding white-gold solar eruption.
-- Play(character, config?). Blinds nearby players with a soft-fade screen flash.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local C = require(script.Parent:WaitForChild("VFXCommon"))

local M = {}

local DEFAULTS = {
	ChargeTime = 0.45,
	BlindDuration = 2.2,
	Radius = 75,
	Color = Color3.fromRGB(255, 250, 220),
	CoreColor = Color3.fromRGB(255, 255, 255),
	SoundId = "",
	ParticleTexture = "",
	ArenaDamage = false,
}

local function getLocalPlayerGui(): PlayerGui?
	local lp = Players.LocalPlayer
	return lp and lp:FindFirstChildOfClass("PlayerGui")
end

function M.Play(character: Model, config: { [string]: any }?)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character)
	if not root then
		return
	end

	local f = C.folder("SolarFlareVFX", c.ChargeTime + c.BlindDuration + 3)

	task.spawn(function()
		local head = C.limb(character, { "Head" }) or root
		local origin = head.Position

		-- Forehead flare beacon
		local flare = C.part(f, Vector3.one * 0.5, c.CoreColor, Enum.PartType.Ball, 0)
		flare.Position = origin + head.CFrame.LookVector * 0.8
		local lt = C.light(flare, c.Color, 8, 2)

		-- Short charge swell
		local t0 = os.clock()
		while os.clock() - t0 < c.ChargeTime and character.Parent do
			local k = (os.clock() - t0) / c.ChargeTime
			flare.Size = Vector3.one * (0.5 + k * 2.5)
			lt.Range = 8 + k * 40
			lt.Brightness = 2 + k * 8
			RunService.Heartbeat:Wait()
		end

		C.sound(c.SoundId, root)
		flare.Size = Vector3.one * 15
		C.tween(flare, 0.4, { Size = Vector3.one * 40, Transparency = 1 })

		-- Expanding sunburst shockwave
		if C.Shockwave then
			C.Shockwave(f, CFrame.new(origin), 2, 45, c.Color, 0.5, 0.5)
			C.Shockwave(f, CFrame.new(origin), 1, 30, c.CoreColor, 0.35, 0.4)
		end

		-- Screen Blind Effect for LocalPlayer if in range and facing
		if RunService:IsClient() and C.Quality.ImpactFrames then
			local lp = Players.LocalPlayer
			local myChar = lp and lp.Character
			local myRoot = myChar and C.root(myChar)

			if myRoot then
				local dist = (myRoot.Position - origin).Magnitude
				if dist <= c.Radius then
					local pg = getLocalPlayerGui()
					if pg then
						local blindGui = Instance.new("ScreenGui")
						blindGui.Name = "SolarFlareBlind"
						blindGui.IgnoreGuiInset = true
						blindGui.DisplayOrder = 999
						blindGui.ResetOnSpawn = false

						local frame = Instance.new("Frame")
						frame.Size = UDim2.fromScale(1, 1)
						frame.BackgroundColor3 = Color3.new(1, 1, 1)
						frame.BackgroundTransparency = 0.05
						frame.BorderSizePixel = 0
						frame.Parent = blindGui
						blindGui.Parent = pg

						-- Fade over BlindDuration
						task.spawn(function()
							task.wait(0.4)
							local tw = C.tween(
								frame,
								c.BlindDuration - 0.4,
								{ BackgroundTransparency = 1 },
								Enum.EasingStyle.Quad,
								Enum.EasingDirection.Out
							)
							tw.Completed:Wait()
							blindGui:Destroy()
						end)
					end
				end
			end
		end

		-- Camera shake & hitstop on caster
		C.CameraShake(0.6)
		C.FOVPunch(8)
	end)
end

return M
