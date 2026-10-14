-- LocalScript: v1 ending + wish + results.
-- "Ending" state: StoryDialogue.Ending with a Super Shenron placeholder; on the triggersWishChoice line, the winning
-- universe gets a 2-option wish UI (Remotes.WishChoice). WishResult plays the granted lines.
-- "Results" state: results screen (winner, wish, KOs, your level/XP).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local Story = require(ReplicatedStorage:WaitForChild("StoryDialogue"))
local Director = require(Shared:WaitForChild("CutsceneDirector"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local SHENRON_BASE = Vector3.new(0, 480, -170)
local endingGui: ScreenGui? = nil
local resultsGui: ScreenGui? = nil
local dir: any = nil
local say: ((string, string) -> ())? = nil
local token = 0
local winnerName: string? = nil
-- v3 (db-story): one ending per round (RoundState "Ending" and SuperShenron "Summon" both start it; whichever lands
-- second is ignored), Granted handled once (WishResult or SuperShenron "Granted"), and the whole thing is skippable.
local playingFor: string? = nil
local granted = false
local wishOffered = false
local skippedEnding = false
local iWonEnding = false

local function clearEnding()
	token += 1
	if endingGui then endingGui:Destroy(); endingGui = nil end
	if dir then dir.cleanup(); dir = nil end
	say = nil
	playingFor = nil
	player:SetAttribute("InCinematic", nil)
	UIKit.restoreCamera()
end

local function wishUI(gui: ScreenGui)
	local panel = UIKit.frame(gui, UDim2.new(0, 640, 0, 260), UDim2.new(0.5, -320, 0.5, -170), UIKit.DARK, 0.1)
	panel.Name = "WishChoice"
	UIKit.label(panel, "MAKE YOUR WISH", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 8), 30, UIKit.GOLD)
	local i = 0
	for _, id in { "Power", "Restoration" } do
		local w = Config.WISHES[id]
		local lines = Story.Wishes[id] and Story.Wishes[id].lines
		-- v9 (lead-authorized, CHANGES.md): the Power wish is cosmetic + Zeni (no stat boost)
		local desc = if id == "Power" then string.format("Gold aura • +%d Zeni\nTitle: %s", w.zeni or 0, w.title)
			else string.format("+%d Zeni for EVERYONE • halo\nTitle: %s", w.serverZeni or 0, w.title)
		local b = UIKit.button(panel, (lines and lines[1].text or id) .. "\n\n" .. desc,
			UDim2.new(0.5, -24, 0, 170), UDim2.new(i * 0.5, 12, 0, 60),
			if id == "Power" then Color3.fromRGB(170, 110, 20) else Color3.fromRGB(30, 110, 170))
		b.TextSize = 17
		b.Name = id
		b.Activated:Connect(function()
			Remotes:WaitForChild("WishChoice"):FireServer(id)
			panel:Destroy()
		end)
		i += 1
	end
end

local function offerWish(gui: ScreenGui, winner: string)
	if wishOffered or granted then return end
	wishOffered = true
	if iWonEnding then
		wishUI(gui)
		if say then say("npc_shenron", "CHOOSE WISELY, CHAMPIONS.") end
	elseif say then
		say("npc_grand_priest", winner .. " is choosing their wish...")
	end
end

-- Skip: stop the beats, remove actors/fx, give the camera back, but keep subtitles + the wish picker usable
local function skipEnding()
	local gui = endingGui
	if not gui or skippedEnding then return end
	skippedEnding = true
	token += 1
	if dir then dir.cleanup(); dir = nil end
	player:SetAttribute("InCinematic", nil)
	UIKit.restoreCamera()
	local b = gui:FindFirstChild("Skip"); if b then b:Destroy() end
	if not granted then offerWish(gui, winnerName or "The winners") end
end

local function playEnding(winner: string)
	if playingFor == winner and endingGui then return end -- already playing this round's ending
	clearEnding()
	playingFor = winner
	granted, wishOffered, skippedEnding = false, false, false
	local my = token
	winnerName = winner
	local iWon = player.Team ~= nil and player.Team.Name == winner
	iWonEnding = iWon
	local gui = UIKit.gui("EndingCutscene", 20)
	endingGui = gui
	player:SetAttribute("InCinematic", true)
	UIKit.frame(gui, UDim2.new(1, 0, 0.1, 0), UDim2.fromScale(0, 0), Color3.new(0, 0, 0), 0)
	UIKit.frame(gui, UDim2.new(1, 0, 0.1, 0), UDim2.fromScale(0, 0.9), Color3.new(0, 0, 0), 0)
	UIKit.label(gui, winner .. " WINS!", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.11, 0), 40, UIKit.GOLD)
	say = UIKit.subtitles(gui)
	local skipBtn = UIKit.button(gui, "Skip ▶ (Space)", UDim2.new(0, 160, 0, 40), UDim2.new(1, -180, 0, 20), Color3.fromRGB(80, 30, 30))
	skipBtn.Name = "Skip"
	skipBtn.Activated:Connect(skipEnding)
	dir = Director.new()
	local d = dir
	Director.play(d, Story.Ending, {
		say = say, story = Story, team = player.Team,
		isAlive = function() return my == token end,
		onHook = function(name)
			if name ~= "WishChoice" then return end
			offerWish(gui, winner)
		end,
	})
end

local function onGranted(wishId: string)
	if granted then return end
	granted = true
	local gui = endingGui
	if gui then
		local p = gui:FindFirstChild("WishChoice")
		if p then p:Destroy() end
	end
	local w = Story.Wishes[wishId]
	task.spawn(function()
		local my = token
		for _, line in (w and w.lines or {}) do
			if my ~= token or not say then return end
			say(if line.speaker == "SuperShenron" then "npc_shenron" else line.speaker, line.text)
			task.wait(line.duration)
		end
		if my ~= token or not dir then return end
		Director.play(dir, Story.Outro or {}, {
			say = say, story = Story, team = player.Team,
			isAlive = function() return my == token end,
			onHook = function(name) end, -- ShowRewards: server moves to Results, which opens the rewards screen
		})
	end)
end
ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WishResult").OnClientEvent:Connect(function(wishId, _chooser, _team)
	onGranted(wishId)
end)
task.spawn(function()
	local r = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SuperShenron", 15)
	if not r then warn("[EndingUI] missing remote SuperShenron"); return end
	(r :: RemoteEvent).OnClientEvent:Connect(function(d)
		if type(d) ~= "table" then return end
		if d.phase == "Summon" and d.winner and workspace:GetAttribute("RoundState") == "Ending" then
			task.spawn(playEnding, tostring(d.winner)) -- no-op if RoundState "Ending" already started it
		elseif d.phase == "Granted" and d.wish then
			onGranted(tostring(d.wish)) -- no-op if WishResult already handled it
		end
	end)
end)
UserInputService.InputBegan:Connect(function(input)
	local k = input.KeyCode
	if endingGui and (k == Enum.KeyCode.Space or k == Enum.KeyCode.Return or k == Enum.KeyCode.ButtonB) then skipEnding() end
end)

local function showResults(summary: any)
	if resultsGui then resultsGui:Destroy() end
	local gui = UIKit.gui("Results", 15)
	resultsGui = gui
	local panel = UIKit.frame(gui, UDim2.new(0, 520, 0, 360), UDim2.new(0.5, -260, 0.5, -180), UIKit.DARK, 0.1)
	local winner = if type(summary) == "table" then summary.winner else tostring(summary)
	local iWon = player.Team ~= nil and player.Team.Name == winner
	UIKit.label(panel, if winner == "Draw" then "DRAW" else (winner .. " WINS"), UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 10), 32, UIKit.GOLD)
	UIKit.label(panel, if iWon then "VICTORY — your universe survives!" else "Your universe was defeated...", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 54), 18,
		if iWon then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(255, 120, 120))
	local lines = {}
	if type(summary) == "table" then
		if summary.wish then table.insert(lines, "Wish granted: " .. summary.wish .. " (" .. (Config.WISHES[summary.wish] and Config.WISHES[summary.wish].title or "") .. ")") end
		table.insert(lines, string.format("Match time: %d:%02d", (summary.duration or 0) // 60, (summary.duration or 0) % 60))
		table.insert(lines, "")
		table.insert(lines, "Knockouts:")
		if summary.kos and #summary.kos > 0 then
			table.sort(summary.kos, function(a, b) return a.kos > b.kos end)
			for _, k in summary.kos do table.insert(lines, string.format("   %s — %d", k.name, k.kos)) end
		else
			table.insert(lines, "   none")
		end
	end
	table.insert(lines, "")
	table.insert(lines, string.format("You: Level %d  •  %d/%d XP%s", player:GetAttribute("Level") or 1, player:GetAttribute("XP") or 0,
		player:GetAttribute("XPToNext") or 100, if player:GetAttribute("Zeni") then "  •  Zeni " .. player:GetAttribute("Zeni") else ""))
	local body = UIKit.label(panel, table.concat(lines, "\n"), UDim2.new(1, -40, 1, -130), UDim2.new(0, 20, 0, 88), 17)
	body.Font = Enum.Font.Gotham; body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top
	UIKit.label(panel, "Returning to lobby...", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 1, -32), 14)
end

ClientAPI.onRoundState:Connect(function(state, _t, extra)
	if state == "Ending" then
		task.spawn(playEnding, tostring(extra))
	elseif state == "Results" then
		clearEnding()
		showResults(extra)
	else
		if endingGui then clearEnding() end
		if resultsGui and state ~= "Results" then resultsGui:Destroy(); resultsGui = nil end
	end
end)
