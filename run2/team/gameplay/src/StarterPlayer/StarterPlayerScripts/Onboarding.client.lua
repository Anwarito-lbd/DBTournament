--!strict
-- LocalScript: StarterPlayerScripts.Onboarding (WP11)
-- Whis onboarding tutorial client: step tracking, Whis dialogue card, and completion UI.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer

local STEPS = {
	{
		title = "STEP 1: MOVEMENT",
		desc = "Walk 30 studs across the training ground (WASD / Thumbstick)",
		whis = "Welcome to the sacred training grounds. Let us begin by warming up your footwork.",
		target = 30,
	},
	{
		title = "STEP 2: BASIC COMBAT",
		desc = "Land 4 strikes in a row (LMB / R2 / M1 button)",
		whis = "Good. Now strike! Chain your attacks together into a martial combo.",
		target = 4,
	},
	{
		title = "STEP 3: EVASION",
		desc = "Vanish out of danger (E / B / VANISH button)",
		whis = "Splendid! When danger closes in, vanish into thin air to slip behind your foe.",
		target = 1,
	},
	{
		title = "STEP 4: KI CHARGE",
		desc = "Hold Charge to raise your power level (Hold C / D-Pad left / CHARGE button)",
		whis = "A true warrior channels divine ki. Hold your charge to raise your power level!",
		target = 1,
	},
	{
		title = "STEP 5: ENERGY BEAM",
		desc = "Fire your signature beam (2 / X / BEAM button)",
		whis = "Magnificent! Now release that accumulated energy into a devastating beam!",
		target = 1,
	},
	{
		title = "STEP 6: SPARRING TEST",
		desc = "Defeat the Training Dummy to finish your trial!",
		whis = "Now prove yourself in battle against this dummy. Apply everything you have learned!",
		target = 1,
	},
}

local currentStep = 1
local active = false

local gui: ScreenGui? = nil
local promptFrame: Frame? = nil
local titleLabel: TextLabel? = nil
local descLabel: TextLabel? = nil
local pipsContainer: Frame? = nil
local pips: { Frame } = {}
local whisFrame: Frame? = nil
local whisText: TextLabel? = nil

local function cleanupUI()
	if gui then
		gui:Destroy()
		gui = nil
	end
	pips = {}
	active = false
end

local function setPips(activeIdx: number)
	for i, pip in ipairs(pips) do
		if i < activeIdx then
			pip.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
		elseif i == activeIdx then
			pip.BackgroundColor3 = UIKit.GOLD
		else
			pip.BackgroundColor3 = Color3.fromRGB(80, 85, 110)
		end
	end
end

local function updateStepUI(idx: number)
	currentStep = idx
	local cfg = STEPS[idx]
	if not cfg then
		return
	end

	if titleLabel then
		titleLabel.Text = cfg.title
	end
	if descLabel then
		descLabel.Text = cfg.desc
	end
	if whisText then
		whisText.Text = cfg.whis
	end
	setPips(idx)

	if promptFrame then
		-- LAYOUT FIX (2026-10-14): this sat at y=18, directly over the HUD banner (y 8..82), so the round state and
		-- timer were hidden behind the tutorial card. Moved below it.
		promptFrame.Position = UDim2.new(0.5, -240, 0, -80)
		TweenService:Create(
			promptFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, -240, 0, 96) }
		):Play()
	end
end

local function advanceStep()
	currentStep += 1
	if currentStep <= #STEPS then
		ClientAPI.tutorialProgress(currentStep, "Advance")
		updateStepUI(currentStep)
	end
end

local function buildUI()
	cleanupUI()
	gui = UIKit.gui("WhisOnboardingGui", 25)
	active = true

	promptFrame = UIKit.frame(gui, UDim2.fromOffset(480, 92), UDim2.new(0.5, -240, 0, 96), UIKit.DARK, 0.15)
	local pStroke = Instance.new("UIStroke")
	pStroke.Color = UIKit.GOLD
	pStroke.Thickness = 2
	pStroke.Parent = promptFrame

	titleLabel =
		UIKit.label(promptFrame, STEPS[1].title, UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 6), 18, UIKit.GOLD)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center

	descLabel = UIKit.label(
		promptFrame,
		STEPS[1].desc,
		UDim2.new(1, -20, 0, 26),
		UDim2.fromOffset(10, 32),
		14,
		Color3.new(1, 1, 1)
	)
	descLabel.TextXAlignment = Enum.TextXAlignment.Center

	pipsContainer = Instance.new("Frame")
	pipsContainer.Name = "Pips"
	pipsContainer.Size = UDim2.fromOffset(240, 10)
	pipsContainer.Position = UDim2.new(0.5, -120, 0, 68)
	pipsContainer.BackgroundTransparency = 1
	pipsContainer.Parent = promptFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = pipsContainer

	for i = 1, #STEPS do
		local pip = Instance.new("Frame")
		pip.Name = "Pip_" .. i
		pip.Size = UDim2.fromOffset(26, 8)
		pip.BackgroundColor3 = Color3.fromRGB(80, 85, 110)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = pip
		pip.Parent = pipsContainer
		table.insert(pips, pip)
	end

	local skipBtn = UIKit.button(
		gui,
		"SKIP TUTORIAL",
		UDim2.fromOffset(140, 34),
		UDim2.new(1, -156, 0, 18),
		Color3.fromRGB(80, 35, 45)
	)
	skipBtn.TextSize = 13
	skipBtn.Activated:Connect(function()
		ClientAPI.skipTutorial()
		cleanupUI()
	end)

	-- LAYOUT FIX (2026-10-14): 460x80 at (24, -100) overlapped BOTH the bottom-left HP/KI/GUARD panel (which sits
	-- at 1,-180 height 168) and the centred skill hotbar. Narrowed and lifted clear of both.
	whisFrame = UIKit.frame(gui, UDim2.fromOffset(320, 80), UDim2.new(0, 24, 1, -272), UIKit.DARK, 0.2)
	local wStroke = Instance.new("UIStroke")
	wStroke.Color = Color3.fromRGB(90, 200, 255)
	wStroke.Thickness = 2
	wStroke.Parent = whisFrame

	local whisName = UIKit.label(
		whisFrame,
		"WHIS",
		UDim2.new(1, -16, 0, 20),
		UDim2.fromOffset(14, 6),
		15,
		Color3.fromRGB(90, 200, 255)
	)
	whisName.TextXAlignment = Enum.TextXAlignment.Left

	whisText = UIKit.label(
		whisFrame,
		STEPS[1].whis,
		UDim2.new(1, -28, 0, 42),
		UDim2.fromOffset(14, 28),
		13,
		Color3.fromRGB(220, 235, 255)
	)
	whisText.TextXAlignment = Enum.TextXAlignment.Left
	whisText.TextYAlignment = Enum.TextYAlignment.Top

	updateStepUI(1)
end

-- ============================================================================
-- PROGRESS LISTENERS PER STEP
-- ============================================================================
local lastPos: Vector3? = nil
local walkDist = 0

RunService.Heartbeat:Connect(function()
	if not active or currentStep ~= 1 then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		if lastPos then
			local d = (root.Position - lastPos).Magnitude
			if d < 10 then
				walkDist += d
				if walkDist >= 30 then
					advanceStep()
				end
			end
		end
		lastPos = root.Position
	end
end)

-- ============================================================================
-- PLATFORM-INDEPENDENT STEP DETECTION
-- This used to read raw input. On touch that can never work: the on-screen buttons call ClientAPI directly,
-- so no KeyCode or MouseButton1 is ever produced. The beam step also listened for ButtonY, which is Ki Blast,
-- not the beam. Steps 2, 3 and 5 were therefore impossible to complete on mobile - a first-timer got stuck
-- staring at a prompt they could not satisfy. The server now publishes the ACCEPTED move (LastMove/MoveSeq)
-- and broadcasts the Vanish event, both identical on every platform.
-- ============================================================================
local attackCount = 0

player:GetAttributeChangedSignal("MoveSeq"):Connect(function()
	if not active then
		return
	end
	local last = player:GetAttribute("LastMove")
	if currentStep == 2 and last == "M1" then
		attackCount += 1
		if attackCount >= 4 then
			advanceStep()
		end
	elseif currentStep == 5 and last == "Kamehameha" then
		advanceStep()
	end
end)

ClientAPI.onCombatEvent:Connect(function(kind, _data)
	-- The server broadcasts Vanish however it was triggered: key, touch button or gamepad.
	if active and currentStep == 3 and kind == "Vanish" then
		advanceStep()
	end
end)

player:GetAttributeChangedSignal("Charging"):Connect(function()
	if not active or currentStep ~= 4 then
		return
	end
	if player:GetAttribute("Charging") == true then
		task.delay(1.5, function()
			if active and currentStep == 4 and player:GetAttribute("Charging") == true then
				advanceStep()
			end
		end)
	end
end)

-- ============================================================================
-- SERVER SIGNAL HOOKS
-- ============================================================================
ClientAPI.onTutorial(function(event, data)
	if event == "Start" then
		buildUI()
	elseif event == "StepUpdate" then
		if data and data.step then
			updateStepUI(data.step)
		end
	elseif event == "Complete" then
		cleanupUI()
		local compGui = UIKit.gui("TutorialCompleteFanfare", 30)
		local card = UIKit.frame(compGui, UDim2.fromOffset(520, 180), UDim2.new(0.5, -260, 0.4, -90), UIKit.DARK, 0.1)
		local stroke = Instance.new("UIStroke")
		stroke.Color = UIKit.GOLD
		stroke.Thickness = 3
		stroke.Parent = card

		local title =
			UIKit.label(card, "TUTORIAL COMPLETE!", UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, 16), 28, UIKit.GOLD)
		title.TextXAlignment = Enum.TextXAlignment.Center

		local rewText = string.format(
			"+%d XP  •  +%d ZENI  •  2X XP BOOST (%d MIN)",
			data.xp or 250,
			data.zeni or 1000,
			data.boostMinutes or 30
		)
		local sub = UIKit.label(
			card,
			rewText,
			UDim2.new(1, 0, 0, 32),
			UDim2.fromOffset(0, 72),
			17,
			Color3.fromRGB(100, 240, 130)
		)
		sub.TextXAlignment = Enum.TextXAlignment.Center

		local whisCongrats = UIKit.label(
			card,
			'"You have proven yourself worthy of entering the Tournament of Power."',
			UDim2.new(1, -20, 0, 26),
			UDim2.fromOffset(10, 120),
			14,
			Color3.fromRGB(200, 220, 255)
		)
		whisCongrats.TextXAlignment = Enum.TextXAlignment.Center

		task.delay(4, function()
			if compGui then
				TweenService:Create(card, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
				task.wait(0.5)
				compGui:Destroy()
			end
		end)
	elseif event == "Skipped" then
		cleanupUI()
	end
end)
