-- LocalScript: v2 intro cutscene (CutsceneDirector + StoryDialogue v2) (StoryDialogue.Intro). Plays when the server enters the "Intro" state.
-- Grand Priest + Zeno placeholder figures, camera shots over WorldOfVoid, subtitles with speaker names.
-- Skippable (button or Space); skipping tells the server (Remotes.IntroSkip).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared:WaitForChild("UIKit"))
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local Story = require(ReplicatedStorage:WaitForChild("StoryDialogue"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local Director = require(Shared:WaitForChild("CutsceneDirector"))
local playing = false
local token = 0
local cleanup: () -> () = function() end

local function friezaBanter(): boolean
	local team = player.Team; if not team then return false end
	local hasF, hasGV = false, false
	for _, p in team:GetPlayers() do
		local c = p:GetAttribute("Character")
		if c == "u7_frieza" then hasF = true elseif c == "u7_goku" or c == "u7_vegeta" then hasGV = true end
	end
	return hasF and hasGV
end

local function stop(skip: boolean)
	if not playing then return end
	playing = false
	token += 1
	cleanup()
	UIKit.restoreCamera()
	if skip then Remotes:WaitForChild("IntroSkip"):FireServer() end
end

local function play()
	if playing or player:GetAttribute("InRaid") then return end -- v10: raid / story-episode players aren't in the round
	playing = true
	token += 1
	local my = token
	local gui = UIKit.gui("IntroCutscene", 20)
	-- letterbox
	UIKit.frame(gui, UDim2.new(1, 0, 0.1, 0), UDim2.fromScale(0, 0), Color3.new(0, 0, 0), 0)
	UIKit.frame(gui, UDim2.new(1, 0, 0.1, 0), UDim2.fromScale(0, 0.9), Color3.new(0, 0, 0), 0)
	local Config = require(Shared:WaitForChild("Config"))
	local title = UIKit.label(gui, string.upper(Config.GAME_NAME or "Dragon Block Z"), UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0.12, 0), 44, UIKit.GOLD)
	local sub = UIKit.label(title, string.upper(Config.MODE_NAME or "Tournament of Power"), UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 1, 0), 24, Color3.new(1, 1, 1))
	sub.Name = "ModeName"
	title.Visible = false
	local say = UIKit.subtitles(gui)
	local skipBtn = UIKit.button(gui, "Skip ▶ (Space)", UDim2.new(0, 160, 0, 40), UDim2.new(1, -180, 0, 20), Color3.fromRGB(80, 30, 30))
	skipBtn.Activated:Connect(function() stop(true) end)
	local dir = Director.new()
	cleanup = function()
		gui:Destroy()
		dir.cleanup()
	end
	local beats = Story.Intro
	Director.play(dir, beats, {
		say = say, story = Story, team = player.Team, friezaBanter = friezaBanter,
		isAlive = function() return my == token end,
		onHook = function(name)
			if name == "StartRoundTimer" then title.Visible = true end -- server starts the real timer when Intro ends
		end,
	})
	if my == token then stop(true) end
end

UserInputService.InputBegan:Connect(function(input)
	if playing and input.KeyCode == Enum.KeyCode.Space then stop(true) end
end)

ClientAPI.onRoundState:Connect(function(state)
	if state == "Intro" then task.spawn(play) elseif playing then stop(false) end
end)
player:GetAttributeChangedSignal("InRaid"):Connect(function()
	if player:GetAttribute("InRaid") and playing then stop(false) end -- entering a raid / episode ends the round intro
end)
if workspace:GetAttribute("RoundState") == "Intro" then task.spawn(play) end
