--!strict
-- LocalScript: StarterPlayerScripts.MobileControls (WP10)
-- Mobile on-screen touch controls, mobile auto lock-on (40 deg cone), and console gamepad bindings.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ============================================================================
-- AUTO LOCK-ON & TARGETING (Mobile Ergonomics)
-- ============================================================================
local function charRoot(m: Instance?): BasePart?
	if not m or not m:IsA("Model") then
		return nil
	end
	return m:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isEnemy(m: Model, p: Player?): boolean
	if p then
		if p == player then
			return false
		end
		if p:GetAttribute("Alive") == false then
			return false
		end
		if player.Team and p.Team == player.Team then
			return false
		end
		return true
	end
	if m:GetAttribute("IsBot") then
		if m:GetAttribute("Alive") == false then
			return false
		end
		local botTeam = m:GetAttribute("Team")
		if player.Team and botTeam == player.Team.Name then
			return false
		end
		return true
	end
	return false
end

-- Mobile Auto Lock-on: finds the best target within 120 studs and a 40-degree forward cone
local function findAutoLockTarget(): Model?
	local myChar = player.Character
	local myRoot = charRoot(myChar)
	if not myRoot then
		return nil
	end

	local cam = workspace.CurrentCamera
	local look = if cam then cam.CFrame.LookVector else myRoot.CFrame.LookVector
	local myPos = myRoot.Position
	local cos40 = math.cos(math.rad(40)) -- ~0.766

	local bestTarget: Model? = nil
	local bestScore = -math.huge

	-- Check real players
	for _, q in Players:GetPlayers() do
		if q ~= player and q.Character and isEnemy(q.Character, q) then
			local tr = charRoot(q.Character)
			if tr then
				local delta = tr.Position - myPos
				local dist = delta.Magnitude
				if dist <= 120 and dist > 1 then
					local dot = look:Dot(delta.Unit)
					if dot >= cos40 then
						local score = (dot * 2) - (dist / 120)
						if score > bestScore then
							bestScore = score
							bestTarget = q.Character
						end
					end
				end
			end
		end
	end

	-- Check dev bots
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("IsBot") and isEnemy(d, nil) then
			local tr = charRoot(d)
			if tr then
				local delta = tr.Position - myPos
				local dist = delta.Magnitude
				if dist <= 120 and dist > 1 then
					local dot = look:Dot(delta.Unit)
					if dot >= cos40 then
						local score = (dot * 2) - (dist / 120)
						if score > bestScore then
							bestScore = score
							bestTarget = d
						end
					end
				end
			end
		end
	end

	return bestTarget
end

local function applyAutoLock()
	local currentId = player:GetAttribute("LockTargetId")
	local currentName = player:GetAttribute("LockTargetName")
	if currentId ~= nil or currentName ~= nil then
		return
	end

	local target = findAutoLockTarget()
	if target then
		local q = Players:GetPlayerFromCharacter(target)
		if q then
			player:SetAttribute("LockTargetId", q.UserId)
			player:SetAttribute("LockTargetName", nil)
		else
			player:SetAttribute("LockTargetId", nil)
			player:SetAttribute("LockTargetName", target:GetFullName())
		end
	end
end

local function getAimPosition(): Vector3
	local id = player:GetAttribute("LockTargetId")
	local q = id and Players:GetPlayerByUserId(id)
	local r = q and q.Character and q.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if r then
		return r.Position
	end

	local path = player:GetAttribute("LockTargetName")
	if type(path) == "string" then
		local cur: Instance? = game
		for seg in path:gmatch("[^%.]+") do
			cur = cur and cur:FindFirstChild(seg)
		end
		local br = cur and cur:FindFirstChild("HumanoidRootPart") :: BasePart?
		if br then
			return br.Position
		end
	end

	local cam = workspace.CurrentCamera
	if cam then
		local hitRes = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 150)
		if hitRes then
			return hitRes.Position
		end
		return cam.CFrame.Position + cam.CFrame.LookVector * 60
	end
	return mouse.Hit.Position
end

local function getMoveDirection(): Vector3
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local d = hum and hum.MoveDirection or Vector3.zero
	if d.Magnitude < 0.1 then
		local cam = workspace.CurrentCamera
		d = if cam then cam.CFrame.LookVector else Vector3.new(0, 0, -1)
	end
	return d
end

-- ============================================================================
-- GAMEPAD / CONSOLE BINDINGS (MASTER_PLAN WP10 Parity)
-- ============================================================================
-- Declared before bindGamepad so the gamepad charge action and the touch CHARGE button share one state
-- (without this the gamepad closure would capture a global instead of the local).
local isCharging = false
local function releaseCharge()
	if isCharging then
		isCharging = false
		ClientAPI.setCharging(false)
	end
end

local function bindGamepad()
	ContextActionService:BindAction("GP_Attack", function(_, state)
		if state == Enum.UserInputState.Begin then
			applyAutoLock()
			ClientAPI.requestMove("M1", getAimPosition())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonR2)

	ContextActionService:BindAction("GP_Heavy", function(_, state)
		if state == Enum.UserInputState.Begin then
			applyAutoLock()
			ClientAPI.requestMove("Heavy", getAimPosition())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonR1)

	ContextActionService:BindAction("GP_Block", function(_, state)
		if state == Enum.UserInputState.Begin then
			ClientAPI.block(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			ClientAPI.block(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("GP_Dash", function(_, state)
		if state == Enum.UserInputState.Begin then
			ClientAPI.dash(getMoveDirection())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonL1)

	ContextActionService:BindAction("GP_Vanish", function(_, state)
		if state == Enum.UserInputState.Begin then
			ClientAPI.vanish(getMoveDirection())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonB)

	ContextActionService:BindAction("GP_KiBlast", function(_, state)
		if state == Enum.UserInputState.Begin then
			applyAutoLock()
			ClientAPI.requestMove("KiBlast", getAimPosition())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonY)

	ContextActionService:BindAction("GP_Transform", function(_, state)
		if state == Enum.UserInputState.Begin then
			ClientAPI.transform("Next")
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.DPadUp)

	ContextActionService:BindAction("GP_Drink", function(_, state)
		if state == Enum.UserInputState.Begin then
			ClientAPI.useItem("EnergyDrink")
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.DPadDown)

	ContextActionService:BindAction("GP_ComboBreak", function(_, state)
		if state == Enum.UserInputState.Begin then
			ClientAPI.comboBreak()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonL3)

	-- PARITY FIX (2026-10-14): touch had BEAM, CHARGE and the MASH! struggle button, and the keyboard had
	-- 2 / hold-charge / V, but the gamepad had none of the three - so on console a player could not fire a
	-- signature beam, charge ki, or contest a beam struggle at all.
	ContextActionService:BindAction("GP_Beam", function(_, state)
		if state == Enum.UserInputState.Begin then
			applyAutoLock()
			ClientAPI.requestMove("Kamehameha", getAimPosition())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonX)

	ContextActionService:BindAction("GP_Charge", function(_, state)
		if state == Enum.UserInputState.Begin then
			isCharging = true
			ClientAPI.setCharging(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			releaseCharge()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.DPadLeft)
end

-- The struggle mash is bound only while a struggle is live, so ButtonA keeps its default jump behaviour the
-- rest of the time.
local struggleBound = false
local function setStruggleBinding(on: boolean)
	if on == struggleBound then
		return
	end
	struggleBound = on
	if on then
		ContextActionService:BindAction("GP_Struggle", function(_, state)
			if state == Enum.UserInputState.Begin then
				ClientAPI.struggleInput()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.ButtonA)
	else
		ContextActionService:UnbindAction("GP_Struggle")
	end
end

bindGamepad()

-- ============================================================================
-- MOBILE ON-SCREEN TOUCH UI (Ergonomic Right Thumb Cluster)
-- ============================================================================
local screenGui = UIKit.gui("MobileControlsGui", 15)

local container = Instance.new("Frame")
container.Name = "ControlsContainer"
container.Size = UDim2.fromScale(1, 1)
container.BackgroundTransparency = 1
container.Parent = screenGui

local function updateVisibility()
	local spectating = player:GetAttribute("Spectating") == true
	local state = workspace:GetAttribute("RoundState")
	local inCutscene = state == "Intro" or state == "Ending" or state == "CharacterSelect"
	local touchWanted = UserInputService.TouchEnabled or workspace:GetAttribute("ForceMobileControls") == true
	container.Visible = touchWanted and not (spectating or inCutscene)
end

player:GetAttributeChangedSignal("Spectating"):Connect(updateVisibility)
workspace:GetAttributeChangedSignal("RoundState"):Connect(updateVisibility)
workspace:GetAttributeChangedSignal("ForceMobileControls"):Connect(updateVisibility)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateVisibility)
updateVisibility()

local function createTouchButton(
	name: string,
	text: string,
	subtext: string?,
	size: number,
	anchor: Vector2,
	pos: UDim2,
	bgColor: Color3,
	strokeColor: Color3
): ImageButton
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.AnchorPoint = anchor
	btn.Position = pos
	btn.Size = UDim2.fromOffset(size, size)
	btn.BackgroundColor3 = bgColor
	btn.BackgroundTransparency = 0.25
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	local str = Instance.new("UIStroke")
	str.Color = strokeColor
	str.Thickness = 2.5
	str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	str.Parent = btn

	local label = Instance.new("TextLabel")
	label.Name = "MainLabel"
	label.Size = UDim2.fromScale(1, if subtext then 0.6 else 1)
	label.Position = UDim2.fromScale(0, if subtext then 0.1 else 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(10, 10, 20)
	label.Parent = btn

	if subtext then
		local sub = Instance.new("TextLabel")
		sub.Name = "SubLabel"
		sub.Size = UDim2.fromScale(1, 0.3)
		sub.Position = UDim2.fromScale(0, 0.65)
		sub.BackgroundTransparency = 1
		sub.Text = subtext
		sub.TextColor3 = strokeColor
		sub.Font = Enum.Font.GothamBold
		sub.TextScaled = true
		sub.TextStrokeTransparency = 0.4
		sub.TextStrokeColor3 = Color3.fromRGB(10, 10, 20)
		sub.Parent = btn
	end

	btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			TweenService:Create(btn, TweenInfo.new(0.08), {
				Size = UDim2.fromOffset(size * 0.92, size * 0.92),
				BackgroundTransparency = 0.05,
			}):Play()
		end
	end)

	local function resetSize()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 0.25,
		}):Play()
	end

	btn.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			resetSize()
		end
	end)

	return btn
end

local GOLD = Color3.fromRGB(255, 200, 60)
local RED = Color3.fromRGB(235, 75, 75)
local CYAN = Color3.fromRGB(60, 210, 255)
local BLUE = Color3.fromRGB(45, 110, 240)
local GREEN = Color3.fromRGB(60, 220, 100)
local PURPLE = Color3.fromRGB(180, 75, 240)
local DARK_BG = Color3.fromRGB(20, 22, 40)

local btnM1 =
	createTouchButton("Btn_M1", "M1", "STRIKE", 76, Vector2.new(1, 1), UDim2.new(1, -55, 1, -95), DARK_BG, GOLD)
btnM1.Activated:Connect(function()
	applyAutoLock()
	ClientAPI.requestMove("M1", getAimPosition())
end)

local btnHeavy =
	createTouchButton("Btn_Heavy", "HEAVY", "BREAK", 56, Vector2.new(1, 1), UDim2.new(1, -145, 1, -80), DARK_BG, RED)
btnHeavy.Activated:Connect(function()
	applyAutoLock()
	ClientAPI.requestMove("Heavy", getAimPosition())
end)

local btnBlast =
	createTouchButton("Btn_Blast", "KI", "BLAST", 54, Vector2.new(1, 1), UDim2.new(1, -150, 1, -150), DARK_BG, CYAN)
btnBlast.Activated:Connect(function()
	applyAutoLock()
	ClientAPI.requestMove("KiBlast", getAimPosition())
end)

local btnBeam =
	createTouchButton("Btn_Beam", "BEAM", "SPECIAL", 58, Vector2.new(1, 1), UDim2.new(1, -95, 1, -190), DARK_BG, BLUE)
btnBeam.Activated:Connect(function()
	applyAutoLock()
	ClientAPI.requestMove("Kamehameha", getAimPosition())
end)

local btnVanish = createTouchButton(
	"Btn_Vanish",
	"VANISH",
	"DODGE",
	52,
	Vector2.new(1, 1),
	UDim2.new(1, -30, 1, -195),
	DARK_BG,
	Color3.fromRGB(220, 230, 255)
)
btnVanish.Activated:Connect(function()
	ClientAPI.vanish(getMoveDirection())
end)

local btnDash =
	createTouchButton("Btn_Dash", "DASH", "BURST", 50, Vector2.new(1, 1), UDim2.new(1, -215, 1, -95), DARK_BG, GOLD)
btnDash.Activated:Connect(function()
	ClientAPI.dash(getMoveDirection())
end)

local btnBlock = createTouchButton(
	"Btn_Block",
	"BLOCK",
	"GUARD",
	56,
	Vector2.new(1, 1),
	UDim2.new(1, -215, 1, -165),
	DARK_BG,
	Color3.fromRGB(240, 180, 50)
)
local isBlocking = false

btnBlock.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isBlocking = true
		ClientAPI.block(true)
	end
end)

local function releaseBlock()
	if isBlocking then
		isBlocking = false
		ClientAPI.block(false)
	end
end
btnBlock.InputEnded:Connect(releaseBlock)

local btnCharge = createTouchButton(
	"Btn_Charge",
	"CHARGE",
	"KI",
	58,
	Vector2.new(1, 1),
	UDim2.new(1, -145, 1, -225),
	DARK_BG,
	Color3.fromRGB(255, 140, 40)
)
btnCharge.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isCharging = true
		ClientAPI.setCharging(true)
	end
end)
btnCharge.InputEnded:Connect(releaseCharge)

local btnTransform = createTouchButton(
	"Btn_Transform",
	"FORM",
	"AWAKEN",
	52,
	Vector2.new(1, 1),
	UDim2.new(1, -210, 1, -235),
	DARK_BG,
	PURPLE
)
btnTransform.Activated:Connect(function()
	ClientAPI.transform("Next")
end)

local btnLock =
	createTouchButton("Btn_Lock", "LOCK", "TARGET", 48, Vector2.new(1, 1), UDim2.new(1, -85, 1, -270), DARK_BG, RED)
btnLock.Activated:Connect(function()
	local curId = player:GetAttribute("LockTargetId")
	local curName = player:GetAttribute("LockTargetName")
	if curId or curName then
		player:SetAttribute("LockTargetId", nil)
		player:SetAttribute("LockTargetName", nil)
	else
		local tgt = findAutoLockTarget()
		if tgt then
			local q = Players:GetPlayerFromCharacter(tgt)
			if q then
				player:SetAttribute("LockTargetId", q.UserId)
				player:SetAttribute("LockTargetName", nil)
			else
				player:SetAttribute("LockTargetId", nil)
				player:SetAttribute("LockTargetName", tgt:GetFullName())
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	local locked = (player:GetAttribute("LockTargetId") ~= nil) or (player:GetAttribute("LockTargetName") ~= nil)
	local stroke = btnLock:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = if locked then Color3.fromRGB(255, 40, 40) else RED
		stroke.Thickness = if locked then 4 else 2.5
	end
end)

local btnDrink =
	createTouchButton("Btn_Drink", "DRINK", "HEAL", 48, Vector2.new(1, 1), UDim2.new(1, -25, 1, -270), DARK_BG, GREEN)
btnDrink.Activated:Connect(function()
	ClientAPI.useItem("EnergyDrink")
end)

local btnMash = createTouchButton(
	"Btn_Mash",
	"MASH!",
	"STRUGGLE",
	90,
	Vector2.new(0.5, 0.5),
	UDim2.fromScale(0.5, 0.62),
	Color3.fromRGB(60, 20, 20),
	GOLD
)
btnMash.Visible = false

ClientAPI.onCombatEvent:Connect(function(kind, _data)
	if kind == "StruggleStart" then
		btnMash.Visible = true
		setStruggleBinding(true)
		local pulseTween = TweenService:Create(
			btnMash,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{
				Size = UDim2.fromOffset(102, 102),
			}
		)
		pulseTween:Play()
	elseif kind == "StruggleEnd" then
		btnMash.Visible = false
		setStruggleBinding(false)
	end
end)

btnMash.Activated:Connect(function()
	ClientAPI.struggleInput()
end)

player.CharacterRemoving:Connect(function()
	releaseBlock()
	releaseCharge()
end)
