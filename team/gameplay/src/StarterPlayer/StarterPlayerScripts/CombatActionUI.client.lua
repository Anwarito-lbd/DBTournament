--!strict
-- LocalScript: StarterPlayerScripts.CombatActionUI
-- The Strongest Battlegrounds (TSB) style Action Hotbar & Animation HUD:
-- 4-Slot Skill Action Bar with live cooldown sweeps and mobile touch buttons,
-- Awakening Transformation Bar with radiant pulsing glow and [G]/[X] activation,
-- Movement/Defense status badges ([Q] Dash, [F] Guard, [C] Charge),
-- Dynamic Comic-Book Combo Counter with bounce animation and punch sound,
-- and Interactive Martial Arts Battle Stances selector ([B]).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local Config = require(Shared:WaitForChild("Config"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local PosesFolder = ReplicatedStorage:WaitForChild("Poses", 10)
local FightAnimator = require(Shared:WaitForChild("FightAnimator")) -- the one owner of combat poses
local GokuPoses = PosesFolder and require(PosesFolder:WaitForChild("Goku"))
local VegetaPoses = PosesFolder and require(PosesFolder:WaitForChild("Vegeta"))
local SharedPoses = PosesFolder and require(PosesFolder:WaitForChild("Shared"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local gui = UIKit.gui("CombatActionHUD", 10)

local function aim(): Vector3
	local id = player:GetAttribute("LockTargetId")
	local q = id and Players:GetPlayerByUserId(id)
	local r = q and q.Character and q.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if r then
		return r.Position
	end
	return mouse.Hit.Position
end

local function moveDir(): Vector3
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local d = hum and hum.MoveDirection or Vector3.zero
	if d.Magnitude < 0.1 then
		d = workspace.CurrentCamera.CFrame.LookVector
	end
	return d
end

local currentPoseHandle: any = nil
local function stopCurrentPose()
	if currentPoseHandle then
		-- only release the body if the stance is still what is playing (a move may have taken over)
		if FightAnimator.current(player.Character) == "Stance" then FightAnimator.stop(player.Character, 0.2) end
		currentPoseHandle = nil
	end
end

-- ========================================================
-- 1. AWAKENING TRANSFORMATION BAR (TSB Style)
-- ========================================================
local awakenFrame = Instance.new("Frame")
awakenFrame.Name = "AwakeningFrame"
awakenFrame.Size = UDim2.new(0, 480, 0, 36)
awakenFrame.Position = UDim2.new(0.5, -240, 1, -135)
awakenFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
awakenFrame.BackgroundTransparency = 0.25
awakenFrame.BorderSizePixel = 0
awakenFrame.Parent = gui

local awakenCorner = Instance.new("UICorner")
awakenCorner.CornerRadius = UDim.new(0, 8)
awakenCorner.Parent = awakenFrame

local awakenStroke = Instance.new("UIStroke")
awakenStroke.Color = Color3.fromRGB(70, 70, 85)
awakenStroke.Thickness = 1.5
awakenStroke.Parent = awakenFrame

local awakenFill = Instance.new("Frame")
awakenFill.Name = "Fill"
awakenFill.Size = UDim2.new(0, 0, 1, 0)
awakenFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
awakenFill.BorderSizePixel = 0
awakenFill.Parent = awakenFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = awakenFill

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 255)),
})
fillGrad.Parent = awakenFill

local awakenLabel = Instance.new("TextLabel")
awakenLabel.Name = "Label"
awakenLabel.Size = UDim2.new(1, 0, 1, 0)
awakenLabel.BackgroundTransparency = 1
awakenLabel.Font = Enum.Font.GothamBlack
awakenLabel.TextSize = 14
awakenLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
awakenLabel.Text = "AWAKENING  0%"
awakenLabel.Parent = awakenFrame

local awakenBtn = Instance.new("TextButton")
awakenBtn.Size = UDim2.new(1, 0, 1, 0)
awakenBtn.BackgroundTransparency = 1
awakenBtn.Text = ""
awakenBtn.Parent = awakenFrame

awakenBtn.MouseButton1Click:Connect(function()
	stopCurrentPose()
	ClientAPI.transform("Next")
end)

-- ========================================================
-- 2. TSB 4-SLOT COMBAT ACTION BAR
-- ========================================================
local hotbar = Instance.new("Frame")
hotbar.Name = "SkillHotbar"
hotbar.Size = UDim2.new(0, 480, 0, 72)
hotbar.Position = UDim2.new(0.5, -240, 1, -90)
hotbar.BackgroundTransparency = 1
hotbar.Parent = gui

local hl = Instance.new("UIListLayout")
hl.FillDirection = Enum.FillDirection.Horizontal
hl.HorizontalAlignment = Enum.HorizontalAlignment.Center
hl.Padding = UDim.new(0, 12)
hl.Parent = hotbar

type SkillDef = { id: string, name: string, key: string, cd: number, ki: number, icon: string }
local SKILLS: { SkillDef } = {
	{ id = "KiBlast", name = "KI BLAST", key = "1", cd = 1.5, ki = 5, icon = "⚡" },
	{ id = "Kamehameha", name = "BEAM CANNON", key = "2", cd = 6.0, ki = 30, icon = "💥" },
	{ id = "Heavy", name = "HEAVY SMASH", key = "G", cd = 4.0, ki = 10, icon = "👊" },
	{ id = "Vanish", name = "VANISH STRIKE", key = "E", cd = 3.0, ki = 15, icon = "💨" },
}

local skillCards: { [string]: { frame: Frame, cdFill: Frame, cdText: TextLabel, lastUsed: number, cdDuration: number } } =
	{}

for _, sk in ipairs(SKILLS) do
	local card = Instance.new("Frame")
	card.Name = "Skill_" .. sk.id
	card.Size = UDim2.new(0, 110, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.Parent = hotbar

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(60, 60, 80)
	cStroke.Thickness = 1.5
	cStroke.Parent = card

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 0, 28)
	iconLabel.Position = UDim2.new(0, 0, 0, 6)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = sk.icon
	iconLabel.TextSize = 22
	iconLabel.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -8, 0, 16)
	titleLabel.Position = UDim2.new(0, 4, 0, 34)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 11
	titleLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
	titleLabel.Text = sk.name
	titleLabel.Parent = card

	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(1, -8, 0, 14)
	costLabel.Position = UDim2.new(0, 4, 0, 50)
	costLabel.BackgroundTransparency = 1
	costLabel.Font = Enum.Font.Gotham
	costLabel.TextSize = 10
	costLabel.TextColor3 = Color3.fromRGB(70, 170, 255)
	costLabel.Text = "KI: " .. sk.ki
	costLabel.Parent = card

	-- Key badge
	local keyBadge = Instance.new("Frame")
	keyBadge.Size = UDim2.new(0, 22, 0, 18)
	keyBadge.Position = UDim2.new(1, -24, 0, 4)
	keyBadge.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	keyBadge.BorderSizePixel = 0
	keyBadge.Parent = card

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, 4)
	kc.Parent = keyBadge

	local keyText = Instance.new("TextLabel")
	keyText.Size = UDim2.new(1, 0, 1, 0)
	keyText.BackgroundTransparency = 1
	keyText.Font = Enum.Font.GothamBlack
	keyText.TextSize = 11
	keyText.TextColor3 = Color3.fromRGB(255, 215, 70)
	keyText.Text = sk.key
	keyText.Parent = keyBadge

	-- Cooldown Overlay
	local cdOverlay = Instance.new("Frame")
	cdOverlay.Name = "CDOverlay"
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1)
	cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.45
	cdOverlay.BorderSizePixel = 0
	cdOverlay.Parent = card

	local cdc = Instance.new("UICorner")
	cdc.CornerRadius = UDim.new(0, 8)
	cdc.Parent = cdOverlay

	local cdNumber = Instance.new("TextLabel")
	cdNumber.Name = "CDNumber"
	cdNumber.Size = UDim2.new(1, 0, 1, 0)
	cdNumber.BackgroundTransparency = 1
	cdNumber.Font = Enum.Font.GothamBlack
	cdNumber.TextSize = 20
	cdNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
	cdNumber.Text = ""
	cdNumber.Parent = card

	-- Click button for touch / click
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = card

	clickBtn.MouseButton1Click:Connect(function()
		stopCurrentPose()
		local cur = skillCards[sk.id]
		if cur and os.clock() - cur.lastUsed < cur.cdDuration then
			return
		end
		if sk.id == "Vanish" then
			ClientAPI.vanish(moveDir())
		else
			ClientAPI.requestMove(sk.id, aim())
		end
		if cur then
			cur.lastUsed = os.clock()
		end
	end)

	skillCards[sk.id] = {
		frame = card,
		cdFill = cdOverlay,
		cdText = cdNumber,
		lastUsed = -100,
		cdDuration = sk.cd,
	}
end

-- ========================================================
-- 3. DEFENSE & MOBILITY STATUS BADGES ([Q] Dash, [F] Guard)
-- ========================================================
local statusFrame = Instance.new("Frame")
statusFrame.Name = "MobilityBadges"
statusFrame.Size = UDim2.new(0, 160, 0, 50)
statusFrame.Position = UDim2.new(0.5, -420, 1, -80)
statusFrame.BackgroundTransparency = 1
statusFrame.Parent = gui

local sl = Instance.new("UIListLayout")
sl.FillDirection = Enum.FillDirection.Horizontal
sl.Padding = UDim.new(0, 10)
sl.Parent = statusFrame

local function makeBadge(name: string, key: string, label: string): (Frame, TextLabel, UIStroke)
	local b = Instance.new("Frame")
	b.Name = name
	b.Size = UDim2.new(0, 70, 0, 48)
	b.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	b.BackgroundTransparency = 0.2
	b.BorderSizePixel = 0
	b.Parent = statusFrame

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = b
	local bs = Instance.new("UIStroke")
	bs.Color = Color3.fromRGB(60, 60, 80)
	bs.Thickness = 1.2
	bs.Parent = b

	local kt = Instance.new("TextLabel")
	kt.Size = UDim2.new(1, 0, 0, 22)
	kt.BackgroundTransparency = 1
	kt.Font = Enum.Font.GothamBlack
	kt.TextSize = 13
	kt.TextColor3 = Color3.fromRGB(255, 215, 70)
	kt.Text = "[" .. key .. "]"
	kt.Parent = b

	local lt = Instance.new("TextLabel")
	lt.Size = UDim2.new(1, 0, 0, 20)
	lt.Position = UDim2.new(0, 0, 0, 22)
	lt.BackgroundTransparency = 1
	lt.Font = Enum.Font.GothamBold
	lt.TextSize = 10
	lt.TextColor3 = Color3.fromRGB(210, 220, 235)
	lt.Text = label
	lt.Parent = b

	return b, lt, bs
end

local dashBadge, dashLabel, dashStroke = makeBadge("DashBadge", "Q", "DASH")
local guardBadge, guardLabel, guardStroke = makeBadge("GuardBadge", "F", "GUARD")

-- ========================================================
-- 4. DYNAMIC COMIC-BOOK COMBO COUNTER (TSB Style)
-- ========================================================
local comboContainer = Instance.new("Frame")
comboContainer.Name = "ComboContainer"
comboContainer.Size = UDim2.new(0, 240, 0, 90)
comboContainer.Position = UDim2.new(0.5, 260, 1, -190)
comboContainer.BackgroundTransparency = 1
comboContainer.Parent = gui

local comboNumber = Instance.new("TextLabel")
comboNumber.Name = "ComboNumber"
comboNumber.Size = UDim2.new(1, 0, 0, 50)
comboNumber.BackgroundTransparency = 1
comboNumber.Font = Enum.Font.GothamBlack
comboNumber.TextSize = 42
comboNumber.TextColor3 = Color3.fromRGB(255, 215, 40)
comboNumber.TextStrokeColor3 = Color3.fromRGB(40, 10, 0)
comboNumber.TextStrokeTransparency = 0
comboNumber.Text = ""
comboNumber.Parent = comboContainer

local comboSub = Instance.new("TextLabel")
comboSub.Name = "ComboSub"
comboSub.Size = UDim2.new(1, 0, 0, 24)
comboSub.Position = UDim2.new(0, 0, 0, 52)
comboSub.BackgroundTransparency = 1
comboSub.Font = Enum.Font.GothamBold
comboSub.TextSize = 13
comboSub.TextColor3 = Color3.fromRGB(255, 255, 255)
comboSub.TextStrokeTransparency = 0.5
comboSub.Text = ""
comboSub.Parent = comboContainer

local currentCombo = 0
local lastHitTime = 0

local function recordHit()
	local now = os.clock()
	if now - lastHitTime > 2.8 then
		currentCombo = 1
	else
		currentCombo += 1
	end
	lastHitTime = now

	comboNumber.Text = "COMBO " .. currentCombo
	comboSub.Text = string.format("+%d%% COMBO POWER", math.min(50, currentCombo * 5))

	-- Bounce Tween
	comboNumber.TextSize = 52
	local tw = TweenService:Create(
		comboNumber,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextSize = 42 }
	)
	tw:Play()

	if currentCombo >= 10 then
		comboNumber.TextColor3 = Color3.fromRGB(255, 45, 45)
	elseif currentCombo >= 5 then
		comboNumber.TextColor3 = Color3.fromRGB(255, 140, 30)
	else
		comboNumber.TextColor3 = Color3.fromRGB(255, 215, 40)
	end
end

ClientAPI.onCombatEvent:Connect(function(kind, data)
	if kind == "Hit" and type(data) == "table" and data.att == player then
		recordHit()
	end
end)

-- ========================================================
-- 5. ANIMATIONS & BATTLE STANCES MENU ([B] Key)
-- ========================================================
local stanceToggleBtn = Instance.new("TextButton")
stanceToggleBtn.Name = "StanceToggleBtn"
stanceToggleBtn.Size = UDim2.new(0, 170, 0, 36)
stanceToggleBtn.Position = UDim2.new(1, -185, 1, -80)
stanceToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
stanceToggleBtn.BorderSizePixel = 0
stanceToggleBtn.Font = Enum.Font.GothamBold
stanceToggleBtn.TextSize = 12
stanceToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 70)
stanceToggleBtn.Text = "🎭 STANCES  [B]"
stanceToggleBtn.Parent = gui

local stbCorner = Instance.new("UICorner")
stbCorner.CornerRadius = UDim.new(0, 8)
stbCorner.Parent = stanceToggleBtn
local stbStroke = Instance.new("UIStroke")
stbStroke.Color = Color3.fromRGB(80, 70, 100)
stbStroke.Thickness = 1.2
stbStroke.Parent = stanceToggleBtn

local stanceModal = Instance.new("Frame")
stanceModal.Name = "StanceModal"
stanceModal.Size = UDim2.new(0, 240, 0, 250)
stanceModal.Position = UDim2.new(1, -255, 1, -345)
stanceModal.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
stanceModal.BackgroundTransparency = 0.1
stanceModal.BorderSizePixel = 0
stanceModal.Visible = false
stanceModal.Parent = gui

local smCorner = Instance.new("UICorner")
smCorner.CornerRadius = UDim.new(0, 10)
smCorner.Parent = stanceModal
local smStroke = Instance.new("UIStroke")
smStroke.Color = Color3.fromRGB(255, 215, 70)
smStroke.Thickness = 1.5
smStroke.Parent = stanceModal

local smTitle = Instance.new("TextLabel")
smTitle.Size = UDim2.new(1, 0, 0, 32)
smTitle.BackgroundTransparency = 1
smTitle.Font = Enum.Font.GothamBlack
smTitle.TextSize = 13
smTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
smTitle.Text = "MARTIAL ARTS STANCES"
smTitle.Parent = stanceModal

local smList = Instance.new("UIListLayout")
smList.Padding = UDim.new(0, 6)
smList.Parent = stanceModal

local STANCE_OPTIONS = {
	{ name = "🥋 Turtle Combat Stance", clip = GokuPoses and GokuPoses.Idle },
	{ name = "👑 Saiyan Prince Stance", clip = VegetaPoses and VegetaPoses.Idle_PridefulCross },
	{ name = "🕊️ Ultra Instinct Sway", clip = GokuPoses and GokuPoses.Idle_UI },
	{ name = "⚡ Power Surge Stance", clip = GokuPoses and GokuPoses.Transform_SSJ },
	{ name = "💥 Kamehameha Charge", clip = GokuPoses and GokuPoses.Kamehameha_Charge },
}

for _, opt in ipairs(STANCE_OPTIONS) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -16, 0, 34)
	b.Position = UDim2.new(0, 8, 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.fromRGB(240, 240, 255)
	b.Text = opt.name
	b.Parent = stanceModal

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = b

	b.MouseButton1Click:Connect(function()
		stopCurrentPose()
		stanceModal.Visible = false
		if opt.clip and player.Character then
			currentPoseHandle = FightAnimator.play(player.Character, opt.clip, { source = "local", family = "Stance", name = "Stance", loop = true, markers = false })
		end
	end)
end

stanceToggleBtn.MouseButton1Click:Connect(function()
	stanceModal.Visible = not stanceModal.Visible
end)

-- Console parity: keyboard reaches the stance menu with B. GuiButton.MouseButton1Click only fires for mouse
-- and touch, so without this binding the stance selector was unreachable on a gamepad.
ContextActionService:BindAction("GP_Stances", function(_, state)
	if state == Enum.UserInputState.Begin and not player:GetAttribute("Spectating") then
		stanceModal.Visible = not stanceModal.Visible
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonSelect)

-- Keybind triggers
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or player:GetAttribute("Spectating") then
		return
	end
	local k = input.KeyCode
	if k == Enum.KeyCode.B then
		stanceModal.Visible = not stanceModal.Visible
	elseif k == Enum.KeyCode.One and skillCards.KiBlast then
		stopCurrentPose()
		skillCards.KiBlast.lastUsed = os.clock()
	elseif k == Enum.KeyCode.Two and skillCards.Kamehameha then
		stopCurrentPose()
		skillCards.Kamehameha.lastUsed = os.clock()
	elseif k == Enum.KeyCode.G and skillCards.Heavy then
		stopCurrentPose()
		skillCards.Heavy.lastUsed = os.clock()
	elseif k == Enum.KeyCode.E and skillCards.Vanish then
		stopCurrentPose()
		skillCards.Vanish.lastUsed = os.clock()
	elseif k == Enum.KeyCode.Q then
		stopCurrentPose()
		dashStroke.Color = Color3.fromRGB(0, 205, 255)
		task.delay(0.3, function()
			dashStroke.Color = Color3.fromRGB(60, 60, 80)
		end)
	end
end)

-- Render loop
RunService.RenderStepped:Connect(function()
	local now = os.clock()

	-- STATE VISIBILITY (2026-10-14): this HUD had none, so the skill hotbar, the awakening bar and the stance
	-- button were drawn over the character-select grid and the Intro/Ending cutscenes.
	local st = workspace:GetAttribute("RoundState")
	-- v11: raid / story-episode players are outside the round; their own cinematics hide the bar instead
	local away = player:GetAttribute("InRaid") == true
	if (away and player:GetAttribute("InCinematic") == true) or (not away and (st == "Intro" or st == "Ending" or st == "CharacterSelect")) then
		gui.Enabled = false
		return
	end
	gui.Enabled = true

	-- Stop stance if moving
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.MoveDirection.Magnitude > 0.1 and currentPoseHandle then
		stopCurrentPose()
	end

	-- Cooldown sweeps
	for _, sk in ipairs(SKILLS) do
		local c = skillCards[sk.id]
		if c then
			local elapsed = now - c.lastUsed
			if elapsed < c.cdDuration then
				local rem = c.cdDuration - elapsed
				local frac = rem / c.cdDuration
				c.cdFill.Size = UDim2.new(1, 0, frac, 0)
				c.cdText.Text = string.format("%.1f", rem)
			else
				c.cdFill.Size = UDim2.new(1, 0, 0, 0)
				c.cdText.Text = ""
			end
		end
	end

	-- Guard status
	local isBlocking = player:GetAttribute("Blocking") == true
	if isBlocking then
		guardStroke.Color = Color3.fromRGB(0, 235, 255)
		guardStroke.Thickness = 2
	else
		guardStroke.Color = Color3.fromRGB(60, 60, 80)
		guardStroke.Thickness = 1.2
	end

	-- Combo timeout
	if now - lastHitTime > 2.8 and comboNumber.Text ~= "" then
		comboNumber.Text = ""
		comboSub.Text = ""
		currentCombo = 0
	end

	-- Awakening calculation
	local kiCharge = (player:GetAttribute("KiCharge") :: number?) or 0
	local form = (player:GetAttribute("Form") :: string?) or "Base"
	local awakenFrac = math.clamp(kiCharge / 0.5, 0, 1)

	awakenFill.Size = UDim2.new(awakenFrac, 0, 1, 0)

	if awakenFrac >= 0.85 then
		awakenStroke.Color = Color3.fromRGB(255, 215, 50)
		awakenStroke.Thickness = 2.5
		awakenLabel.TextColor3 = Color3.fromRGB(255, 240, 100)
		awakenLabel.Text = "⚡ AWAKENING READY  [G] / [X] ⚡"
	else
		awakenStroke.Color = Color3.fromRGB(70, 70, 85)
		awakenStroke.Thickness = 1.5
		awakenLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
		awakenLabel.Text = string.format("%s  •  AWAKENING %d%%", form:upper(), math.floor(awakenFrac * 100))
	end
end)
