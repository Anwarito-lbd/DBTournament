-- LocalScript: v1 HUD. HP / Ki / Guard bars, Power Level, level + XP bar, round state + timer, team/universe,
-- alive counts per universe (players + dev bots), elimination feed, controls hint panel (H toggles).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local player = Players.LocalPlayer

local gui = UIKit.gui("HUD", 1)
-- top: state + timer + team + alive
local top = UIKit.frame(gui, UDim2.new(0, 560, 0, 74), UDim2.new(0.5, -280, 0, 8), UIKit.DARK, 0.35) -- v1.2: wide enough for "DRAGON BLOCK Z  •  ..."
local stateL = UIKit.label(top, "", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 2), 24, UIKit.GOLD)
stateL.TextScaled = true -- never truncates the DRAGON BLOCK Z banner
local teamL = UIKit.label(top, "", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 30), 15)
local aliveL = UIKit.label(top, "", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 50), 14, Color3.fromRGB(200, 220, 255))
aliveL.Font = Enum.Font.Gotham

-- bottom-left: bars
local stats = UIKit.frame(gui, UDim2.new(0, 300, 0, 168), UDim2.new(0, 12, 1, -180), UIKit.DARK, 0.35)
local nameL = UIKit.label(stats, "", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 4), 17, UIKit.GOLD)
nameL.TextXAlignment = Enum.TextXAlignment.Left
local setHP = UIKit.bar(stats, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 30), Color3.fromRGB(60, 200, 80), "HP")
local setKi = UIKit.bar(stats, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 54), Color3.fromRGB(70, 160, 255), "KI")
local setGuard =
	UIKit.bar(stats, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 78), Color3.fromRGB(230, 180, 60), "GUARD")
local plL = UIKit.label(stats, "", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 102), 18, Color3.fromRGB(255, 120, 80))
plL.TextXAlignment = Enum.TextXAlignment.Left
local zeniL =
	UIKit.label(stats, "", UDim2.new(0.5, -8, 0, 22), UDim2.new(0.5, 0, 0, 102), 16, Color3.fromRGB(255, 220, 90))
zeniL.TextXAlignment = Enum.TextXAlignment.Right
local setXP = UIKit.bar(stats, UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 130), Color3.fromRGB(170, 90, 230), "XP")

-- right: elimination feed
local feed = Instance.new("Frame")
feed.Size = UDim2.new(0, 320, 0, 220)
feed.Position = UDim2.new(1, -332, 0, 90)
feed.BackgroundTransparency = 1
feed.Parent = gui
local fl = Instance.new("UIListLayout")
fl.SortOrder = Enum.SortOrder.LayoutOrder
fl.Padding = UDim.new(0, 4)
fl.Parent = feed
local feedN = 0
local function pushFeed(text: string, color: Color3?)
	feedN += 1
	local f = UIKit.frame(feed, UDim2.new(1, 0, 0, 28), UDim2.new(), Color3.new(0, 0, 0), 0.4)
	f.LayoutOrder = feedN
	local l = UIKit.label(f, text, UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), 15, color)
	l.TextXAlignment = Enum.TextXAlignment.Right
	task.delay(8, function()
		f:Destroy()
	end)
	local kids = {}
	for _, c in feed:GetChildren() do
		if c:IsA("Frame") then
			table.insert(kids, c)
		end
	end
	if #kids > 6 then
		table.sort(kids, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		kids[1]:Destroy()
	end
end

-- bottom-right: controls hint
local hint = UIKit.frame(gui, UDim2.new(0, 270, 0, 200), UDim2.new(1, -282, 1, -212), UIKit.DARK, 0.4)
local ht = UIKit.label(
	hint,
	table.concat({
		"CONTROLS  (H to hide)",
		"LMB  punch combo   •   G  heavy",
		"1  ki blast   •   2  Kamehameha",
		"F  block (tap = perfect block)",
		"Q  dash   •   E  vanish   •   R  combo breaker",
		"hold C  charge ki / power up",
		"V  mash in beam struggles",
		"B  energy drink (1 per match)  •  L / middle mouse  lock-on",
		"T  Final Explosion (Vegeta)",
		"Spectating: Q/E switch, F free cam",
	}, "\n"),
	UDim2.new(1, -16, 1, -12),
	UDim2.new(0, 8, 0, 6),
	13
)
ht.Font = Enum.Font.Gotham
ht.TextXAlignment = Enum.TextXAlignment.Left
ht.TextYAlignment = Enum.TextYAlignment.Top
local hintWanted = true
UserInputService.InputBegan:Connect(function(i, processed)
	if not processed and i.KeyCode == Enum.KeyCode.H then
		hintWanted = not hintWanted
	end
end)

-- FOCUS MODE (FTUE 2026-10-14): the first minutes were a wall of panels. The controls block, the elimination
-- feed, the quest tracker and Roblox's built-in player list were all on screen at once, stacked over the tutorial
-- card. While the Whis tutorial runs, the HUD keeps only what a brand new player needs: the banner, the
-- HP/KI/GUARD bars, the Whis card and the skill bar.
local StarterGui = game:GetService("StarterGui")
local playerListOn: boolean? = nil
local function setPlayerList(on: boolean)
	if playerListOn == on then
		return
	end
	playerListOn = on
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, on)
	end)
end

local STATE_NAMES = {
	Waiting = "DRAGON BLOCK Z  •  Waiting for players",
	Intermission = "DRAGON BLOCK Z  •  Next match in",
	CharacterSelect = "Character Select",
	Intro = "The Grand Priest speaks",
	Countdown = "Get ready!",
	InRound = "DRAGON BLOCK Z  •  TOURNAMENT OF POWER",
	Ending = "Super Dragon Balls",
	Results = "Results",
}

STATE_NAMES.Lobby = "DRAGON BLOCK Z  •  Lobby"
local function name(v: any): string
	if typeof(v) == "Instance" and v:IsA("Player") then
		return v.DisplayName
	end
	return tostring(v)
end
ClientAPI.onEliminated:Connect(function(victim, killer, reason)
	local how = if reason == "RingOut"
		then "rang out"
		elseif reason == "SelfKO" then "self-destructed"
		elseif reason == "Leave" then "left"
		else "was knocked out"
	local text = name(victim) .. " " .. how .. (if killer then " by " .. name(killer) else "")
	local mine = (killer == player) or (victim == player)
	pushFeed(text, if mine then UIKit.GOLD else nil)
end)
ClientAPI.onLevelUp:Connect(function(level)
	pushFeed("LEVEL UP!  Level " .. level, UIKit.GOLD)
end)

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		return
	end
	acc = 0
	local state = workspace:GetAttribute("RoundState") or "Waiting"
	local t = workspace:GetAttribute("TimeLeft") or 0
	local cutscene = state == "Intro" or state == "Ending"
	gui.Enabled = not cutscene
	-- FTUE focus mode: strip the screen down while a new player is being onboarded. CharacterSelect also gets
	-- the treatment - its full-screen character grid was being overlapped by the bars, the controls wall, the
	-- elimination feed and Roblox's player list. The top banner stays: "Character Select 0:08" is useful there.
	local inTutorial = player:GetAttribute("InTutorial") == true
	local picking = state == "CharacterSelect"
	local strip = inTutorial or picking
	hint.Visible = hintWanted and not strip
	feed.Visible = not strip
	stats.Visible = not picking
	setPlayerList(not strip)
	local timer = if t > 0 then string.format("  %d:%02d", t // 60, t % 60) else ""
	-- v9 (lead-authorized): in a round show the 48:00 ToP show clock (workspace.ShowClock, compressed onto the real round)
	local show = workspace:GetAttribute("ShowClock")
	if state == "InRound" and type(show) == "number" then
		timer = string.format("  %02d:%02d", show // 60, show % 60)
	end
	stateL.Text = (STATE_NAMES[state] or state) .. timer
	local team = player.Team
	local u = team and team:GetAttribute("Universe")
	teamL.Text = if u
		then ("Universe " .. u .. "  •  " .. (if player:GetAttribute("Alive")
			then "Fighting"
			elseif player:GetAttribute("Spectating") then "Spectating"
			else ""))
		else "Lobby"
	-- alive counts per universe
	local counts: { [string]: number } = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Alive") == true and p.Team then
			counts[p.Team.Name] = (counts[p.Team.Name] or 0) + 1
		end
	end
	local bf = workspace:FindFirstChild("DevBots")
	if bf then
		for _, m in bf:GetChildren() do
			if m:GetAttribute("Alive") == true then
				local tn = m:GetAttribute("Team") or "?"
				counts[tn] = (counts[tn] or 0) + 1
			end
		end
	end
	local parts = {}
	for tn, n in counts do
		table.insert(parts, string.gsub(tn, "Universe ", "U") .. ": " .. n)
	end
	table.sort(parts)
	aliveL.Text = if #parts > 0 then "Alive  " .. table.concat(parts, "   ") else ""
	-- bars
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		setHP(hum.Health / math.max(1, hum.MaxHealth), string.format("%d/%d", hum.Health, hum.MaxHealth))
	end
	local ki = player:GetAttribute("Ki") or 0
	setKi(ki / Config.KI.max, tostring(ki))
	local g = player:GetAttribute("Guard") or 0
	setGuard(g / Config.SKILL.GuardMax, tostring(g))
	local charge = player:GetAttribute("KiCharge") or 0
	plL.Text = string.format(
		"Power Level %s%s",
		tostring(player:GetAttribute("PowerLevel") or 0),
		if charge > 0 then string.format("  (+%d%%)", math.floor(charge * 100)) else ""
	)
	local cid = player:GetAttribute("Character")
	local ch = cid and Config.CHAR_BY_ID[cid]
	local form = player:GetAttribute("Form")
	local title = player:GetAttribute("Title")
	nameL.Text = (ch and ch.name or "No champion")
		.. (if form and form ~= "Base" then " • " .. form else "")
		.. (if title then "  [" .. title .. "]" else "")
	zeniL.Text = string.format("Zeni %s", tostring(player:GetAttribute("Zeni") or 0))
	local xp, nxt = player:GetAttribute("XP") or 0, player:GetAttribute("XPToNext") or 100
	setXP(xp / math.max(1, nxt), string.format("Level %d  •  %d/%d", player:GetAttribute("Level") or 1, xp, nxt))
	-- set title of XP bar to level
end)
