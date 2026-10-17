-- LocalScript: HUD (v1, rebuilt on the v11 kit). Round banner (context zone), vitals plate with HP / Ki / Guard,
-- Power Level, level + XP and Zeni (vitals zone), elimination feed (tracker zone, under the quests), and a Controls
-- chip (help zone) that opens a readable controls sheet with H. Positions come from ScreenManager zones; the HUD
-- layer hides itself in cinematics and round cutscenes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local S = require(Shared:WaitForChild("UIStyle"))
local SM = require(Shared:WaitForChild("ScreenManager"))
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local player = Players.LocalPlayer

-- ===== context: round banner =====
local banner = Instance.new("Frame")
banner.Name = "RoundBanner"
banner.BackgroundTransparency = 1
banner.AutomaticSize = Enum.AutomaticSize.XY
banner.Size = UDim2.new()
banner.LayoutOrder = 0
banner.Parent = SM.zone("context")
S.stack(banner, "Y", 2, "Center")
local bTitle = S.text(banner, "title", "", { align = "Center" })
bTitle.LayoutOrder = 1
local bStroke = Instance.new("UIStroke"); bStroke.Color = S.C.ink; bStroke.Thickness = 2; bStroke.Parent = bTitle
local bSub = S.text(banner, "body", "", { rich = true, font = S.F.bold, color = S.C.text, align = "Center" })
bSub.LayoutOrder = 2
local bAlive = S.text(banner, "caption", "", { font = S.F.data, color = S.C.muted, align = "Center" })
bAlive.LayoutOrder = 3

local STATE = {
	Waiting = { "World of Void", "Waiting for players" },
	Lobby = { "World of Void", "Lobby" },
	Intermission = { "World of Void", "Next tournament in %s" },
	CharacterSelect = { "Choose your fighter", "%s" },
	Intro = { "Tournament of Power", "" },
	Countdown = { "Get ready", "%s" },
	InRound = { "Tournament of Power", "%s" },
	Ending = { "Super Dragon Balls", "" },
	Results = { "Results", "%s" },
}

-- ===== vitals =====
local vit = S.plate(SM.zone("vitals"), { size = UDim2.new(0, math.floor(340 * S.textScale()), 0, 0), auto = "Y", edge = S.C.orange, pad = 12 })
vit.Name = "Vitals"
S.stack(vit, "Y", 6)
local head = Instance.new("Frame"); head.BackgroundTransparency = 1; head.Size = UDim2.new(1, 0, 0, 0); head.AutomaticSize = Enum.AutomaticSize.Y; head.LayoutOrder = 1; head.Parent = vit
local nameL = S.text(head, "lead", "", {})
local titleL = S.text(head, "caption", "", { font = S.F.bold, color = S.C.gold })
titleL.Position = UDim2.new(0, 0, 0, S.px("lead") + 4)
local plL = S.text(head, "body", "", { font = S.F.data, color = S.C.scouter, align = "Right" })
plL.AnchorPoint = Vector2.new(1, 0); plL.Position = UDim2.fromScale(1, 0)

local function labelledMeter(order: number, label: string, opts: any): ((number, string) -> ())
	local holder = Instance.new("Frame"); holder.BackgroundTransparency = 1; holder.LayoutOrder = order
	holder.Size = UDim2.new(1, 0, 0, opts.height); holder.Parent = vit
	local track, set = S.meter(holder, { size = UDim2.fromScale(1, 1), color = opts.color, gradient = opts.gradient, segments = opts.segments, trail = opts.trail })
	track.ZIndex = 1
	local l, v
	if opts.labels ~= false then
		l = S.text(holder, "caption", label, { font = S.F.bold })
		l.Position = UDim2.new(0, 8, 0.5, 0); l.AnchorPoint = Vector2.new(0, 0.5); l.ZIndex = 5
		v = S.text(holder, "caption", "", { font = S.F.data, align = "Right" })
		v.AnchorPoint = Vector2.new(1, 0.5); v.Position = UDim2.new(1, -8, 0.5, 0); v.ZIndex = 5
		for _, t in { l, v } do local o = Instance.new("UIStroke"); o.Color = S.C.ink; o.Thickness = 1.5; o.Parent = t end
	end
	return function(f: number, text: string)
		set(f)
		if v then v.Text = text end
		if opts.onSet then opts.onSet(track, f) end
	end
end
-- HP colour by percentage: green, then yellow below half, red below a quarter (POLISH_BIBLE §2.5)
local setHP = labelledMeter(2, "HP", { height = math.floor(22 * S.textScale()), color = S.C.hp, trail = true, onSet = function(track: Frame, f: number)
	local fill = track:FindFirstChild("Fill") :: Frame
	fill.BackgroundColor3 = if f > 0.5 then S.C.hp elseif f > 0.25 then S.C.hpMid else S.C.danger
end })
local setKi = labelledMeter(3, "KI", { height = math.floor(16 * S.textScale()), gradient = { S.C.ki, S.C.ki2 }, segments = 5 })
local setGuard = labelledMeter(4, "GUARD", { height = math.floor(7 * S.textScale()), color = S.C.gold, labels = false })
local foot = Instance.new("Frame"); foot.BackgroundTransparency = 1; foot.Size = UDim2.new(1, 0, 0, 0); foot.AutomaticSize = Enum.AutomaticSize.Y; foot.LayoutOrder = 5; foot.Parent = vit
local lvL = S.text(foot, "caption", "", { font = S.F.bold, color = S.C.text })
local zeniL = S.text(foot, "caption", "", { font = S.F.data, color = S.C.gold, align = "Right" })
zeniL.AnchorPoint = Vector2.new(1, 0); zeniL.Position = UDim2.fromScale(1, 0)
local xpHolder = Instance.new("Frame"); xpHolder.BackgroundTransparency = 1; xpHolder.LayoutOrder = 6; xpHolder.Size = UDim2.new(1, 0, 0, 5); xpHolder.Parent = vit
local _, setXP = S.meter(xpHolder, { size = UDim2.fromScale(1, 1), color = S.C.rare, radius = 3 })

-- ===== feed: eliminations and level-ups, newest at the bottom, 5 at most =====
local feed = Instance.new("Frame")
feed.Name = "Feed"; feed.BackgroundTransparency = 1; feed.AutomaticSize = Enum.AutomaticSize.XY; feed.Size = UDim2.new(); feed.LayoutOrder = 50
feed.Parent = SM.zone("tracker")
local fl = S.stack(feed, "Y", 4)
fl.HorizontalAlignment = Enum.HorizontalAlignment.Right
local feedN = 0
local function pushFeed(text: string, mine: boolean?)
	feedN += 1
	local f = S.plate(feed, { auto = "XY", color = S.C.ink, alpha = 0.35, pad = 6 })
	f.LayoutOrder = feedN
	S.text(f, "label", text, { font = S.F.bold, color = if mine then S.C.gold else S.C.text })
	task.delay(8, function() if f.Parent then f:Destroy() end end)
	local kids = {}
	for _, c in feed:GetChildren() do if c:IsA("Frame") then table.insert(kids, c) end end
	if #kids > 5 then
		table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		kids[1]:Destroy()
	end
end
local function name(v: any): string
	if typeof(v) == "Instance" and v:IsA("Player") then return v.DisplayName end
	return tostring(v)
end
ClientAPI.onEliminated:Connect(function(victim, killer, reason)
	local how = if reason == "RingOut" then "rang out" elseif reason == "SelfKO" then "self-destructed" elseif reason == "Leave" then "left" else "was knocked out"
	pushFeed(name(victim) .. " " .. how .. (if killer then " by " .. name(killer) else ""), killer == player or victim == player)
end)
ClientAPI.onLevelUp:Connect(function(level)
	pushFeed("Level up: " .. level, true)
end)

-- ===== controls: a chip in the help zone, the full sheet on H =====
local CONTROLS = {
	{ "LMB", "Punch combo" }, { "G", "Heavy" }, { "1", "Ki blast" }, { "2", "Kamehameha" },
	{ "F", "Block (tap on the flash = parry)" }, { "Q", "Dash" }, { "E", "Vanish" }, { "R", "Combo breaker" },
	{ "C", "Hold to charge Ki / power up" }, { "V", "Mash in beam struggles" }, { "B", "Energy drink (1 per match)" },
	{ "L", "Lock on (or middle mouse)" }, { "T", "Final Explosion (Vegeta)" }, { "Q / E", "Switch target while spectating" },
}
local sheet = S.plate(SM.layer("Panel"), { auto = "XY", alpha = 0.06, pad = 18, edge = S.C.orange })
sheet.Name = "ControlsSheet"; sheet.AnchorPoint = Vector2.new(0.5, 0.5); sheet.Position = UDim2.fromScale(0.5, 0.5); sheet.Visible = false
S.stack(sheet, "Y", 10)
S.text(sheet, "title", "Controls", {}).LayoutOrder = 0
local grid = Instance.new("Frame"); grid.BackgroundTransparency = 1; grid.AutomaticSize = Enum.AutomaticSize.XY; grid.Size = UDim2.new(); grid.LayoutOrder = 1; grid.Parent = sheet
local gl = Instance.new("UIGridLayout")
gl.CellSize = UDim2.fromOffset(math.floor(330 * S.textScale()), math.floor(30 * S.textScale())); gl.FillDirectionMaxCells = 2; gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
for i, c in CONTROLS do
	local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.LayoutOrder = i; row.Parent = grid
	S.stack(row, "X", 10)
	S.keyBadge(row, c[1]).LayoutOrder = 1
	S.text(row, "body", c[2], {}).LayoutOrder = 2
end
S.text(sheet, "caption", "Press H to close", { color = S.C.muted, font = S.F.bold }).LayoutOrder = 2
local notifySheet: (boolean) -> () = function() end
local function setSheet(v: boolean?)
	local on = if v == nil then not sheet.Visible else v
	sheet.Visible = on
	notifySheet(on)
end
notifySheet = S.registerPanel(setSheet)
local helpChip = S.chip(SM.zone("help"), "Controls", S.keyFor("controls"), function() setSheet() end)
helpChip.LayoutOrder = 10
S.deviceChanged:Connect(function(d)
	local k = helpChip:FindFirstChild("Key") :: TextLabel?
	if k then k.Visible = d == "Keyboard" end
end)
UserInputService.InputBegan:Connect(function(i, processed)
	if not processed and i.KeyCode == Enum.KeyCode.H then setSheet() end
end)

-- FOCUS MODE (FTUE 2026-10-14): the first minutes were a wall of panels. While the Whis tutorial runs (and during
-- character select) the HUD keeps only what a brand new player needs.
local playerListOn: boolean? = nil
local function setPlayerList(on: boolean)
	if playerListOn == on then return end
	playerListOn = on
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, on) end)
end

local function clock(n: number): string
	return string.format("<font color=\"#FFC93C\" face=\"RobotoMono\">%d:%02d</font>", n // 60, n % 60)
end

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.1 then return end
	acc = 0
	local state = workspace:GetAttribute("RoundState") or "Waiting"
	local t = workspace:GetAttribute("TimeLeft") or 0
	local away = player:GetAttribute("InRaid") == true -- raids / story episodes own the context zone
	local inTutorial = player:GetAttribute("InTutorial") == true
	local picking = state == "CharacterSelect"
	banner.Visible = not away and not inTutorial -- the tutorial shows its own area title there
	vit.Visible = not picking
	feed.Visible = not (inTutorial or picking)
	helpChip.Visible = not (inTutorial or picking or away)
	if (inTutorial or picking) and sheet.Visible then setSheet(false) end
	setPlayerList(not (inTutorial or picking))

	-- banner
	local spec = (STATE :: any)[state] or { state, "" }
	bTitle.Text = spec[1]
	local timeText = if t > 0 then clock(t) else ""
	local show = workspace:GetAttribute("ShowClock") -- v9: the 48:00 ToP show clock during a round
	if state == "InRound" and type(show) == "number" then timeText = clock(show) end
	local sub = if spec[2]:find("%%s") then spec[2]:format(timeText) else spec[2]
	local u = player.Team and player.Team:GetAttribute("Universe")
	if u and (state == "InRound" or state == "Countdown") then
		local doing = if player:GetAttribute("Alive") then "fighting" elseif player:GetAttribute("Spectating") then "spectating" else ""
		sub = sub .. ("   ·   Universe %s %s"):format(tostring(u), doing)
	end
	bSub.Text = sub
	bSub.Visible = sub ~= ""
	local counts: { [string]: number } = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Alive") == true and p.Team then counts[p.Team.Name] = (counts[p.Team.Name] or 0) + 1 end
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
	for tn, n in counts do table.insert(parts, (string.gsub(tn, "Universe ", "U")) .. " " .. n) end
	table.sort(parts)
	bAlive.Text = if #parts > 0 then "Alive   " .. table.concat(parts, "   ") else ""
	bAlive.Visible = #parts > 0

	-- vitals
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then setHP(hum.Health / math.max(1, hum.MaxHealth), string.format("%d / %d", hum.Health, hum.MaxHealth)) end
	local ki = player:GetAttribute("Ki") or 0
	setKi(ki / Config.KI.max, tostring(ki))
	local g = player:GetAttribute("Guard") or 0
	setGuard(g / Config.SKILL.GuardMax, "")
	local charge = player:GetAttribute("KiCharge") or 0
	plL.Text = ("PL %s%s"):format(tostring(player:GetAttribute("PowerLevel") or 0), if charge > 0 then string.format(" +%d%%", math.floor(charge * 100)) else "")
	local cid = player:GetAttribute("Character")
	local ch = cid and Config.CHAR_BY_ID[cid]
	local form = player:GetAttribute("Form")
	nameL.Text = (ch and ch.name or "Pick a fighter") .. (if form and form ~= "Base" then " · " .. form else "")
	local title = player:GetAttribute("Title")
	titleL.Text = title or ""
	titleL.Visible = title ~= nil
	local xp, nxt = player:GetAttribute("XP") or 0, player:GetAttribute("XPToNext") or 100
	lvL.Text = ("Level %d   ·   %d / %d XP"):format(player:GetAttribute("Level") or 1, xp, nxt)
	setXP(xp / math.max(1, nxt))
	zeniL.Text = ("%s Zeni"):format(tostring(player:GetAttribute("Zeni") or 0))
	foot.Position = UDim2.new()
	head.Size = UDim2.new(1, 0, 0, S.px("lead") + (if title then S.px("caption") + 6 else 0))
end)
