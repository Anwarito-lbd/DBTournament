--!strict
-- LocalScript: StarterPlayerScripts.Crosshair
-- Centre-screen aiming crosshair for ALL THREE platforms (PC, console, mobile).
--
-- WHY: combat aiming runs through the screen centre. `CombatInput.getAimPosition` scans a forward cone and then
-- falls back to a raycast from the exact centre of the viewport, so "where the camera looks" IS "where you aim".
-- On PC the mouse pointer is hidden and the player aims with the camera, on console the right stick turns the
-- camera, and on touch the camera drags under the thumb - but none of them had any on-screen indication of that
-- aim point. The only existing indicator (CombatInput's `AnimeCombatReticle`) draws brackets around a target that
-- has ALREADY been acquired, so before acquiring anything there was nothing to aim with and nothing to learn from.
--
-- This is the reticle you aim WITH; CombatInput's brackets are the one that tracks what you HAVE.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))

local player = Players.LocalPlayer

-- ============================================================================
-- BUILD
-- ============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AimCrosshair"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 44 -- just under CombatInput's target reticle (45), above the HUD (1)
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Crosshair"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(64, 64)
root.BackgroundTransparency = 1
root.Parent = gui

local DOT = Color3.fromRGB(255, 255, 255)
local LOCKED = Color3.fromRGB(255, 175, 45)
local HIT = Color3.fromRGB(255, 70, 70)

-- centre dot
local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(3, 3)
dot.BackgroundColor3 = DOT
dot.BorderSizePixel = 0
dot.Parent = root
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

-- four ticks; `gap` is animated between IDLE / LOCK / FIRE
local TICKS = {
	{ name = "Up", size = UDim2.fromOffset(2, 9), pos = UDim2.new(0.5, -1, 0.5, 0), anchor = Vector2.new(0, 1) },
	{ name = "Down", size = UDim2.fromOffset(2, 9), pos = UDim2.new(0.5, -1, 0.5, 0), anchor = Vector2.new(0, 0) },
	{ name = "Left", size = UDim2.fromOffset(9, 2), pos = UDim2.new(0.5, 0, 0.5, -1), anchor = Vector2.new(1, 0) },
	{ name = "Right", size = UDim2.fromOffset(9, 2), pos = UDim2.new(0.5, 0, 0.5, -1), anchor = Vector2.new(0, 0) },
}

local tickParts: { Frame } = {}
for _, t in ipairs(TICKS) do
	local f = Instance.new("Frame")
	f.Name = t.name
	f.Size = t.size
	f.AnchorPoint = t.anchor
	f.BackgroundColor3 = DOT
	f.BorderSizePixel = 0
	f.Parent = root
	table.insert(tickParts, f)
end

local IDLE_GAP, LOCK_GAP, FIRE_GAP = 7, 11, 20

-- Tiny status line. Deliberately minimal: the user's complaint was that the screen already had too much on it.
local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 1, 6)
status.Size = UDim2.fromOffset(180, 16)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextSize = 12
status.TextColor3 = DOT
status.TextStrokeTransparency = 0.4
status.TextStrokeColor3 = Color3.fromRGB(10, 10, 20)
status.Text = ""
status.Parent = root

-- ============================================================================
-- STATE
-- ============================================================================
local function refreshGap(gap: number, color: Color3)
	for i, f in ipairs(tickParts) do
		local t = TICKS[i]
		f.BackgroundColor3 = color
		if t.name == "Up" then
			f.Position = UDim2.new(0.5, -1, 0.5, -gap)
		elseif t.name == "Down" then
			f.Position = UDim2.new(0.5, -1, 0.5, gap)
		elseif t.name == "Left" then
			f.Position = UDim2.new(0.5, -gap, 0.5, -1)
		else
			f.Position = UDim2.new(0.5, gap, 0.5, -1)
		end
	end
	dot.BackgroundColor3 = color
end

local function isLocked(): boolean
	return player:GetAttribute("LockTargetId") ~= nil or player:GetAttribute("LockTargetName") ~= nil
end

local function isTargetInCone(): boolean
	local char = player.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local cam = workspace.CurrentCamera
	if not rootPart or not cam then
		return false
	end
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m ~= char then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and hum.Health > 0 and hrp then
				local to = hrp.Position - cam.CFrame.Position
				if to.Magnitude <= 140 and cam.CFrame.LookVector:Dot(to.Unit) >= 0.97 then
					return true
				end
			end
		end
	end
	return false
end

local function isMobile(): boolean
	local ok, touch = pcall(function()
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end)
	return ok and touch
end

local mobile = isMobile()
local lastHit = 0

-- Shooting feedback: flash the crosshair open + red, then settle.
local function flashHit()
	lastHit = os.clock()
	refreshGap(FIRE_GAP, HIT)
	TweenService:Create(dot, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { BackgroundColor3 = DOT }):Play()
end

ClientAPI.onCombatEvent:Connect(function(kind: string, data: any)
	if kind ~= "Hit" or type(data) ~= "table" then
		return
	end
	-- data = { victimUserId, attackerUserId, damage, knockback, ko }
	if data[2] == player.UserId then
		flashHit()
	end
end)

-- ============================================================================
-- RENDER
-- ============================================================================
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.05 then
		return
	end
	acc = 0

	local state = workspace:GetAttribute("RoundState")
	local spectating = player:GetAttribute("Spectating") == true
	local cutscene = state == "Intro" or state == "Ending" or state == "CharacterSelect"
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local hasChar = hum ~= nil and hum.Health > 0 -- v11: no crosshair over the K.O. card
	root.Visible = hasChar and not spectating and not cutscene and player:GetAttribute("InCinematic") ~= true -- v11: story/raid cinematics too

	if not root.Visible then
		return
	end

	local locked = isLocked()
	local inCone = locked or isTargetInCone()
	local since = os.clock() - lastHit

	-- While a shot is flashing (0.18 s) the gap/colour set by flashHit must survive, so skip the steady-state
	-- update entirely instead of leaving an empty branch.
	if since >= 0.18 then
		if locked then
			refreshGap(LOCK_GAP, LOCKED)
		elseif inCone then
			refreshGap(LOCK_GAP + 1, Color3.fromRGB(120, 225, 255))
		else
			refreshGap(IDLE_GAP, DOT)
		end
	end

	-- Only say something when it actually helps: these are the two platforms with no cursor at all.
	if locked then
		status.Text = "TARGET LOCKED"
		status.TextColor3 = LOCKED
	elseif mobile then
		status.Text = "AUTO-AIM"
		status.TextColor3 = Color3.fromRGB(180, 220, 255)
	elseif UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad" then -- v11: the device in use, not "a pad is plugged in"
		status.Text = "RIGHT STICK TO AIM"
		status.TextColor3 = Color3.fromRGB(180, 220, 255)
	else
		status.Text = ""
	end
end)
