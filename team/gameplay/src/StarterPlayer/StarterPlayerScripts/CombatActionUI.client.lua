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
local S = require(Shared:WaitForChild("UIStyle")) -- v11 kit: tokens, fonts, sizes
local SM = require(Shared:WaitForChild("ScreenManager"))
local function dp(n: number): number return math.floor(n * S.textScale() + 0.5) end

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
awakenFrame.Size = UDim2.new(0, dp(560), 0, dp(20))
awakenFrame.Position = UDim2.new(0.5, -dp(280), 1, -dp(142))
awakenFrame.BackgroundColor3 = S.C.ink
awakenFrame.BackgroundTransparency = 0.2
awakenFrame.BorderSizePixel = 0
awakenFrame.Parent = gui

local awakenCorner = Instance.new("UICorner")
awakenCorner.CornerRadius = UDim.new(0, 8)
awakenCorner.Parent = awakenFrame

local awakenStroke = Instance.new("UIStroke")
awakenStroke.Color = S.C.stroke
awakenStroke.Thickness = 1
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
	ColorSequenceKeypoint.new(0, S.C.orange),
	ColorSequenceKeypoint.new(0.6, S.C.gold),
	ColorSequenceKeypoint.new(1, S.C.goldLight),
})
fillGrad.Parent = awakenFill

local awakenLabel = Instance.new("TextLabel")
awakenLabel.Name = "Label"
awakenLabel.Size = UDim2.new(1, 0, 1, 0)
awakenLabel.BackgroundTransparency = 1
awakenLabel.Font = S.F.bold
awakenLabel.TextSize = S.px("caption") - 2
awakenLabel.TextColor3 = S.C.text
awakenLabel.TextStrokeTransparency = 0.4
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
hotbar.Size = UDim2.new(0, dp(680), 0, dp(84))
hotbar.Position = UDim2.new(0.5, -dp(340), 1, -dp(110))
hotbar.BackgroundTransparency = 1
hotbar.Parent = gui

local hl = Instance.new("UIListLayout")
hl.FillDirection = Enum.FillDirection.Horizontal
hl.HorizontalAlignment = Enum.HorizontalAlignment.Center
hl.Padding = UDim.new(0, dp(8))
hl.SortOrder = Enum.SortOrder.LayoutOrder
hl.VerticalAlignment = Enum.VerticalAlignment.Bottom
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

for slotIndex, sk in ipairs(SKILLS) do
	local card = Instance.new("Frame")
	card.Name = "Skill_" .. sk.id
	card.LayoutOrder = slotIndex
	card.Size = UDim2.new(0, dp(104), 0, dp(84))
	card.BackgroundColor3 = S.C.panel
	card.BackgroundTransparency = S.PANEL_ALPHA
	card.BorderSizePixel = 0
	card.Parent = hotbar

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = if sk.id == "Kamehameha" then S.C.orange else S.C.stroke -- the signature move reads as the special slot
	cStroke.Thickness = if sk.id == "Kamehameha" then 2 else 1
	cStroke.Parent = card

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 0, dp(32))
	iconLabel.Position = UDim2.new(0, 0, 0, dp(10))
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = sk.icon
	iconLabel.TextSize = dp(26)
	iconLabel.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -8, 0, dp(16))
	titleLabel.Position = UDim2.new(0, 4, 0, dp(46))
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = S.F.bold
	titleLabel.TextSize = dp(12)
	titleLabel.TextColor3 = S.C.text
	titleLabel.Text = sk.name
	titleLabel.Parent = card

	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(1, -8, 0, dp(14))
	costLabel.Position = UDim2.new(0, 4, 0, dp(63))
	costLabel.BackgroundTransparency = 1
	costLabel.Font = S.F.data
	costLabel.TextSize = dp(11)
	costLabel.TextColor3 = S.C.ki
	costLabel.Text = sk.ki .. " Ki"
	costLabel.Parent = card

	-- Key badge
	local keyBadge = Instance.new("Frame")
	keyBadge.Size = UDim2.new(0, dp(20), 0, dp(18))
	keyBadge.Position = UDim2.new(1, -dp(24), 0, dp(4))
	keyBadge.BackgroundColor3 = S.C.gold
	keyBadge.BorderSizePixel = 0
	keyBadge.Parent = card

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, 4)
	kc.Parent = keyBadge

	local keyText = Instance.new("TextLabel")
	keyText.Size = UDim2.new(1, 0, 1, 0)
	keyText.BackgroundTransparency = 1
	keyText.Font = S.F.data
	keyText.TextSize = dp(12)
	keyText.TextColor3 = S.C.ink
	keyText.Text = sk.key
	keyText.Parent = keyBadge

	-- Cooldown Overlay
	local cdOverlay = Instance.new("Frame")
	cdOverlay.Name = "CDOverlay"
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1)
	cdOverlay.BackgroundColor3 = S.C.ink
	cdOverlay.BackgroundTransparency = 0.3
	cdOverlay.BorderSizePixel = 0
	cdOverlay.Parent = card

	local cdc = Instance.new("UICorner")
	cdc.CornerRadius = UDim.new(0, 8)
	cdc.Parent = cdOverlay

	local cdNumber = Instance.new("TextLabel")
	cdNumber.Name = "CDNumber"
	cdNumber.Size = UDim2.new(1, 0, 1, 0)
	cdNumber.BackgroundTransparency = 1
	cdNumber.Font = S.F.data
	cdNumber.TextSize = dp(22)
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
statusFrame.Size = UDim2.new(0, 0, 0, 0) -- v11: kept for structure; the badges now sit in the hotbar as its end slots
statusFrame.Position = UDim2.new(0.5, 0, 1, 0)
statusFrame.BackgroundTransparency = 1
statusFrame.Parent = gui

local sl = Instance.new("UIListLayout")
sl.FillDirection = Enum.FillDirection.Horizontal
sl.Padding = UDim.new(0, 10)
sl.Parent = statusFrame

local function makeBadge(name: string, key: string, label: string, order: number): (Frame, TextLabel, UIStroke)
	local b = Instance.new("Frame")
	b.Name = name
	b.LayoutOrder = order
	b.Size = UDim2.new(0, dp(66), 0, dp(66))
	b.BackgroundColor3 = S.C.panel
	b.BackgroundTransparency = S.PANEL_ALPHA
	b.BorderSizePixel = 0
	b.Parent = hotbar

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = b
	local bs = Instance.new("UIStroke")
	bs.Color = S.C.stroke
	bs.Thickness = 1
	bs.Parent = b

	local kt = Instance.new("TextLabel")
	kt.Size = UDim2.new(0, dp(22), 0, dp(20))
	kt.Position = UDim2.new(0.5, -dp(11), 0, dp(10))
	kt.BackgroundTransparency = 0
	kt.BackgroundColor3 = S.C.gold
	local ktc = Instance.new("UICorner"); ktc.CornerRadius = UDim.new(0, 4); ktc.Parent = kt
	kt.Font = S.F.data
	kt.TextSize = dp(13)
	kt.TextColor3 = S.C.ink
	kt.Text = key
	kt.Parent = b

	local lt = Instance.new("TextLabel")
	lt.Size = UDim2.new(1, 0, 0, dp(18))
	lt.Position = UDim2.new(0, 0, 0, dp(38))
	lt.BackgroundTransparency = 1
	lt.Font = S.F.bold
	lt.TextSize = dp(11)
	lt.TextColor3 = S.C.muted
	lt.Text = label
	lt.Parent = b

	return b, lt, bs
end

local dashBadge, dashLabel, dashStroke = makeBadge("DashBadge", "Q", "DASH", 0)
local guardBadge, guardLabel, guardStroke = makeBadge("GuardBadge", "F", "GUARD", 99)

-- ========================================================
-- 4. DYNAMIC COMIC-BOOK COMBO COUNTER (TSB Style)
-- ========================================================
local comboContainer = Instance.new("Frame")
comboContainer.Name = "ComboContainer"
comboContainer.Size = UDim2.new(0, dp(260), 0, dp(96))
comboContainer.Position = UDim2.new(0.5, dp(360), 1, -dp(200))
comboContainer.BackgroundTransparency = 1
comboContainer.Parent = gui

local comboNumber = Instance.new("TextLabel")
comboNumber.Name = "ComboNumber"
comboNumber.Size = UDim2.new(1, 0, 0, 50)
comboNumber.BackgroundTransparency = 1
comboNumber.Font = S.F.impact
comboNumber.TextSize = dp(48)
comboNumber.TextColor3 = S.C.gold
comboNumber.TextStrokeColor3 = S.C.ink
comboNumber.TextStrokeTransparency = 0
comboNumber.Rotation = -4
comboNumber.Text = ""
comboNumber.Parent = comboContainer

local comboSub = Instance.new("TextLabel")
comboSub.Name = "ComboSub"
comboSub.Size = UDim2.new(1, 0, 0, 24)
comboSub.Position = UDim2.new(0, 0, 0, 52)
comboSub.BackgroundTransparency = 1
comboSub.Font = S.F.bold
comboSub.TextSize = dp(14)
comboSub.TextColor3 = S.C.text
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

	comboNumber.Text = currentCombo .. " HITS!"
	comboSub.Text = string.format("+%d%% combo power", math.min(50, currentCombo * 5))

	-- Bounce Tween
	comboNumber.TextSize = dp(60)
	local tw = TweenService:Create(
		comboNumber,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextSize = dp(48) }
	)
	tw:Play()

	if currentCombo >= 10 then
		comboNumber.TextColor3 = S.C.danger
	elseif currentCombo >= 5 then
		comboNumber.TextColor3 = S.C.orange
	else
		comboNumber.TextColor3 = S.C.gold
	end
end

ClientAPI.onCombatEvent:Connect(function(kind, data)
	if kind == "Hit" and type(data) == "table" and data[2] == player.UserId then -- positional payload: data[2] = attacker id
		recordHit()
	end
end)

-- ========================================================
-- 5. ANIMATIONS & BATTLE STANCES MENU ([B] Key)
-- ========================================================
local stanceToggleBtn = Instance.new("TextButton")
stanceToggleBtn.Name = "StanceToggleBtn"
stanceToggleBtn.Size = UDim2.new(0, dp(150), 0, dp(34))
stanceToggleBtn.LayoutOrder = 11
stanceToggleBtn.BackgroundColor3 = S.C.panel
stanceToggleBtn.BackgroundTransparency = S.PANEL_ALPHA
stanceToggleBtn.BorderSizePixel = 0
stanceToggleBtn.Font = S.F.bold
stanceToggleBtn.TextSize = S.px("label")
stanceToggleBtn.TextColor3 = S.C.text
stanceToggleBtn.Text = if S.keyFor("stances") ~= "" then "Stances  ·  B" else "Stances"
stanceToggleBtn.Parent = SM.zone("help") -- v11: sits with the Controls chip; hidden with the HUD layer

local stbCorner = Instance.new("UICorner")
stbCorner.CornerRadius = UDim.new(0, 8)
stbCorner.Parent = stanceToggleBtn
local stbStroke = Instance.new("UIStroke")
stbStroke.Color = S.C.stroke
stbStroke.Thickness = 1
stbStroke.Parent = stanceToggleBtn

local stanceModal = Instance.new("Frame")
stanceModal.Name = "StanceModal"
stanceModal.Size = UDim2.new(0, 240, 0, 250)
stanceModal.Position = UDim2.new(1, -255, 1, -345)
stanceModal.BackgroundColor3 = S.C.panel
stanceModal.BackgroundTransparency = 0.06
stanceModal.BorderSizePixel = 0
stanceModal.Visible = false
stanceModal.Parent = gui

local smCorner = Instance.new("UICorner")
smCorner.CornerRadius = UDim.new(0, 10)
smCorner.Parent = stanceModal
local smStroke = Instance.new("UIStroke")
smStroke.Color = S.C.stroke
smStroke.Thickness = 1
smStroke.Parent = stanceModal

local smTitle = Instance.new("TextLabel")
smTitle.Size = UDim2.new(1, 0, 0, 32)
smTitle.BackgroundTransparency = 1
smTitle.Font = S.F.display
smTitle.TextSize = S.px("lead")
smTitle.TextColor3 = S.C.text
smTitle.Text = "Stances"
smTitle.Parent = stanceModal

local smList = Instance.new("UIListLayout")
smList.Padding = UDim.new(0, 6)
smList.Parent = stanceModal

local STANCE_OPTIONS = {
	{ name = "Turtle combat stance", clip = GokuPoses and GokuPoses.Idle },
	{ name = "Saiyan prince stance", clip = VegetaPoses and VegetaPoses.Idle_PridefulCross },
	{ name = "Ultra Instinct sway", clip = GokuPoses and GokuPoses.Idle_UI },
	{ name = "Power surge", clip = GokuPoses and GokuPoses.Transform_SSJ },
	{ name = "Kamehameha charge", clip = GokuPoses and GokuPoses.Kamehameha_Charge },
}

for _, opt in ipairs(STANCE_OPTIONS) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -16, 0, 34)
	b.Position = UDim2.new(0, 8, 0, 0)
	b.BackgroundColor3 = S.C.ink
	b.BorderSizePixel = 0
	b.Font = S.F.bold
	b.TextSize = S.px("label")
	b.TextColor3 = S.C.text
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
		dashStroke.Color = S.C.ki
		task.delay(0.3, function()
			dashStroke.Color = S.C.stroke
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
		guardStroke.Color = S.C.ki
		guardStroke.Thickness = 2
	else
		guardStroke.Color = S.C.stroke
		guardStroke.Thickness = 1
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
		awakenStroke.Color = S.C.gold
		awakenStroke.Thickness = 2
		awakenLabel.TextColor3 = S.C.ink
		local k = S.keyFor("transform")
		awakenLabel.Text = if k ~= "" then ("Awakening ready  ·  press %s"):format(k) else "Awakening ready  ·  tap the bar" -- X transforms (G is Heavy)
	else
		awakenStroke.Color = S.C.stroke
		awakenStroke.Thickness = 1
		awakenLabel.TextColor3 = S.C.text
		awakenLabel.Text = string.format("%s  ·  Awakening %d%%", form, math.floor(awakenFrac * 100))
	end
end)
