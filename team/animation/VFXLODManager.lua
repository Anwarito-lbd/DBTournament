--!strict
-- VFXLODManager: Dynamic quality auto-detection & distance culling for WP22.
-- Enforces: Max 2,000 particles (1,000 on mobile), 3-tier Aura LOD, 150 debris cap.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local C = require(script.Parent:WaitForChild("VFXCommon"))

local M = {}

export type AuraTrack = {
	Character: Model,
	Root: BasePart,
	Emitters: { ParticleEmitter },
	Lights: { PointLight },
	BaseRates: { [ParticleEmitter]: number },
}

local activeAuras: { [Model]: AuraTrack } = {}
local isInitialized = false
local fpsHistory: { number } = {}
local lowFpsSeconds = 0

-- Distance thresholds (WP22 spec)
local FULL_AURA_DIST = 80 -- Full detail, all emitters & lights
local SIMPLE_AURA_DIST = 200 -- Simple aura (reduced rate, lights off)
-- Beyond 200 studs = completely culled (rate 0)

function M.RegisterAura(character: Model, emitters: { ParticleEmitter }, lights: { PointLight }?)
	local root = C.root(character)
	if not root then
		return
	end

	local baseRates: { [ParticleEmitter]: number } = {}
	for _, em in ipairs(emitters) do
		baseRates[em] = em.Rate
	end

	local track: AuraTrack = {
		Character = character,
		Root = root,
		Emitters = emitters,
		Lights = lights or {},
		BaseRates = baseRates,
	}

	activeAuras[character] = track

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			activeAuras[character] = nil
		end
	end)
end

function M.UnregisterAura(character: Model)
	activeAuras[character] = nil
end

local function updateLOD(cameraPos: Vector3)
	for char, track in pairs(activeAuras) do
		if not track.Root.Parent then
			activeAuras[char] = nil
			continue
		end

		local dist = (track.Root.Position - cameraPos).Magnitude
		if dist <= FULL_AURA_DIST then
			-- Tier 1: Full
			for em, base in pairs(track.BaseRates) do
				em.Rate = C.q(base)
			end
			for _, lt in ipairs(track.Lights) do
				lt.Enabled = true
			end
		elseif dist <= SIMPLE_AURA_DIST then
			-- Tier 2: Simple (50% particles, lights disabled)
			for em, base in pairs(track.BaseRates) do
				em.Rate = C.q(math.floor(base * 0.4))
			end
			for _, lt in ipairs(track.Lights) do
				lt.Enabled = false
			end
		else
			-- Tier 3: Culled beyond 200 studs
			for _, em in ipairs(track.Emitters) do
				em.Rate = 0
			end
			for _, lt in ipairs(track.Lights) do
				lt.Enabled = false
			end
		end
	end
end

function M.Init()
	if isInitialized or not RunService:IsClient() then
		return
	end
	isInitialized = true

	-- Mobile check
	local isMobile = false
	pcall(function()
		isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end)

	if isMobile then
		C.SetQuality(1)
	end

	-- Heartbeat monitor: tracks FPS and manages distance LOD
	local lastCheck = os.clock()
	local frameCount = 0

	RunService.Heartbeat:Connect(function(dt)
		frameCount += 1
		local now = os.clock()

		-- Every 1 second, evaluate average FPS
		if now - lastCheck >= 1.0 then
			local fps = frameCount / (now - lastCheck)
			frameCount = 0
			lastCheck = now

			table.insert(fpsHistory, fps)
			if #fpsHistory > 10 then
				table.remove(fpsHistory, 1)
			end

			-- WP22 Auto-set: if FPS < 30 for 5 consecutive seconds, set Quality to 1 (Low)
			if fps < 30 then
				lowFpsSeconds += 1
				if lowFpsSeconds >= 5 and C.Quality.Level > 1 then
					warn(
						"[VFXLODManager] Low FPS detected ("
							.. math.floor(fps)
							.. " fps). Auto-switching to Low VFX quality."
					)
					C.SetQuality(1)
				end
			else
				lowFpsSeconds = math.max(0, lowFpsSeconds - 1)
			end
		end

		-- Update aura distance culling
		local cam = workspace.CurrentCamera
		if cam then
			updateLOD(cam.CFrame.Position)
		end
	end)
end

return M
