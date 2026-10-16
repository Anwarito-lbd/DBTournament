--!strict
-- LocalScript: StarterPlayerScripts.KingKaiGamesUI (WP-TRAIN-2)
-- Renders HUD for Bubbles Chase (+10% speed/round) and Gregory Hammer (10 bonks in 60s).
-- Includes cartoon "BONK!" popup, progress meters, and touch/keyboard input actions.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))

local ActionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("KingKaiAction") :: RemoteEvent
local UpdateRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("KingKaiUpdate") :: RemoteEvent

local _player = Players.LocalPlayer
local gui = S.gui("KingKaiGamesUI", 25)

local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.fromScale(0.34, 0.16)
hudFrame.Position = UDim2.fromScale(0.33, 0.05)
hudFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 20)
hudFrame.BackgroundTransparency = 0.15
hudFrame.BorderSizePixel = 0
hudFrame.Visible = false
hudFrame.Parent = gui
S.corner(hudFrame, 12)
S.stroke(hudFrame, S.GOLD, 2)

local titleLabel =
	S.label(hudFrame, "KING KAI'S TRAINING", UDim2.fromScale(0.9, 0.28), UDim2.fromScale(0.05, 0.08), S.GOLD)
local detailLabel =
	S.label(hudFrame, "", UDim2.fromScale(0.9, 0.24), UDim2.fromScale(0.05, 0.38), Color3.fromRGB(240, 240, 240))
local progressLabel = S.label(hudFrame, "", UDim2.fromScale(0.9, 0.22), UDim2.fromScale(0.05, 0.68), S.GREEN)

local actionBtn = S.button(
	gui,
	"ACTION (E)",
	UDim2.fromScale(0.14, 0.07),
	UDim2.fromScale(0.43, 0.23),
	S.ORANGE,
	function() end
)
actionBtn.Visible = false

local activeGame: string? = nil

local function showBonkPopup(screenPos: Vector2)
	local bonk = Instance.new("TextLabel")
	bonk.Size = UDim2.fromOffset(120, 50)
	bonk.Position = UDim2.fromOffset(screenPos.X - 60, screenPos.Y - 25)
	bonk.BackgroundTransparency = 1
	bonk.Text = "BONK!"
	bonk.TextColor3 = Color3.fromRGB(255, 230, 40)
	bonk.TextStrokeColor3 = Color3.fromRGB(180, 20, 20)
	bonk.TextStrokeTransparency = 0
	bonk.TextScaled = true
	bonk.Font = Enum.Font.FredokaOne
	bonk.Rotation = math.random(-15, 15)
	bonk.Parent = gui

	local tw = TweenService:Create(bonk, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(screenPos.X - 60, screenPos.Y - 80),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function()
		bonk:Destroy()
	end)
end

UpdateRemote.OnClientEvent:Connect(function(event, data)
	if event == "StartBubbles" then
		activeGame = "Bubbles"
		hudFrame.Visible = true
		actionBtn.Visible = true
		actionBtn.Text = "CATCH (E)"
		titleLabel.Text = "BUBBLES CHASE"
		detailLabel.Text = string.format("Round %d / %d  -  Speed: %.1f st/s", data.round, data.maxRounds, data.speed)
		progressLabel.Text = string.format("Time Remaining: %d s", data.time)
		S.toast(gui, "Catch Bubbles! (Speed increases +10% every round)", S.GOLD)
	elseif event == "BubblesRound" then
		detailLabel.Text = string.format("Round %d / 5  -  Speed: %.1f st/s (+10%%)", data.round, data.speed)
		progressLabel.Text = string.format("Time Remaining: %d s", data.time)
		S.toast(gui, string.format("Round %d! Bubbles is 10%% faster!", data.round), S.GREEN)
	elseif event == "BubblesCaught" then
		S.toast(gui, string.format("Bubbles Caught! Round %d Cleared!", data.round), S.GREEN)
	elseif event == "BubblesVictory" then
		activeGame = nil
		hudFrame.Visible = false
		actionBtn.Visible = false
		S.toast(gui, "VICTORY! All 5 Rounds Cleared! Reward: +2500 XP & Title 'Monkey Business'!", S.GOLD)
	elseif event == "BubblesFailed" then
		activeGame = nil
		hudFrame.Visible = false
		actionBtn.Visible = false
		S.toast(gui, string.format("Time Up! Cleared %d / 5 rounds.", data.cleared or 0), S.MUTED)
	elseif event == "StartGregory" then
		activeGame = "Gregory"
		hudFrame.Visible = true
		actionBtn.Visible = true
		actionBtn.Text = "BONK (F)"
		titleLabel.Text = "GREGORY HAMMER"
		detailLabel.Text = string.format("Bonks: 0 / %d", data.goal)
		progressLabel.Text = string.format("Time Remaining: %d s", data.time)
		S.toast(gui, "Hit Gregory with the hammer! 10 bonks in 60s!", S.GOLD)
	elseif event == "GregoryPos" then
		if activeGame == "Gregory" then
			progressLabel.Text = string.format("Time Remaining: %d s", data.timeLeft)
		end
	elseif event == "GregoryBonk" then
		detailLabel.Text = string.format("Bonks: %d / %d", data.bonks, data.goal)
		showBonkPopup(Vector2.new(hudFrame.AbsolutePosition.X + 150, hudFrame.AbsolutePosition.Y + 120))
	elseif event == "GregoryVictory" then
		activeGame = nil
		hudFrame.Visible = false
		actionBtn.Visible = false
		S.toast(gui, "VICTORY! 10 Bonks in 60s! Reward: +3000 XP & Title 'Cricket Whacker'!", S.GOLD)
	elseif event == "GregoryFailed" then
		activeGame = nil
		hudFrame.Visible = false
		actionBtn.Visible = false
		S.toast(gui, string.format("Time Up! You got %d / 10 bonks. Try again!", data.bonks or 0), S.MUTED)
	end
end)

actionBtn.MouseButton1Click:Connect(function()
	if activeGame == "Bubbles" then
		ActionRemote:FireServer("Catch")
	elseif activeGame == "Gregory" then
		ActionRemote:FireServer("Swing")
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if activeGame == "Bubbles" and input.KeyCode == Enum.KeyCode.E then
		ActionRemote:FireServer("Catch")
	elseif activeGame == "Gregory" and (input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.E) then
		ActionRemote:FireServer("Swing")
	end
end)
