-- LocalScript (v8, db-gameplay): Ranked queue (1v1 / 3v3, Lv15+) + season leaderboard (top 100). Toggle [K].
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
if not S.remotes({ "RankedQueue", "RankedLeave", "RankedUpdate", "RankedLeaderboard" }, 15) then
	return
end
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local player = Players.LocalPlayer

local RANK_COL = {
	Earthling = Color3.fromRGB(170, 170, 170),
	Saiyan = Color3.fromRGB(255, 210, 80),
	Elite = Color3.fromRGB(90, 200, 255),
	God = Color3.fromRGB(255, 90, 90),
	Angel = Color3.fromRGB(200, 230, 255),
	GrandPriest = Color3.fromRGB(190, 120, 255),
}
local gui = S.gui("RankedUI", 21)
local panel = S.panel(gui, 0.55, 0.7, 720, 540)
S.title(panel, "RANKED: SEASON")
local queuedFmt: string? = nil
local set = S.toggle(gui, panel, Enum.KeyCode.K, "Ranked", 2, function()
	ClientAPI.requestLeaderboard()
end)
S.close(panel, function()
	set(false)
end)
local me = S.label(panel, "", UDim2.fromScale(0.44, 0.2), UDim2.fromScale(0.03, 0.13), S.GOLD)
me.TextXAlignment = Enum.TextXAlignment.Left
local note = S.label(
	panel,
	"Ranked normalizes stats: skill only. No items, Senzu or divine picks.",
	UDim2.fromScale(0.44, 0.1),
	UDim2.fromScale(0.03, 0.34),
	S.MUTED,
	S.FONT_BODY
)
local b1 = S.button(panel, "QUEUE 1v1", UDim2.fromScale(0.2, 0.09), UDim2.fromScale(0.03, 0.47), S.BLUE, function()
	if queuedFmt then
		ClientAPI.leaveRanked()
	else
		ClientAPI.queueRanked("1v1")
	end
end)
local b3 = S.button(panel, "QUEUE 3v3", UDim2.fromScale(0.2, 0.09), UDim2.fromScale(0.26, 0.47), S.BLUE, function()
	if queuedFmt then
		ClientAPI.leaveRanked()
	else
		ClientAPI.queueRanked("3v3")
	end
end)
local qs = S.label(panel, "", UDim2.fromScale(0.44, 0.08), UDim2.fromScale(0.03, 0.58), Color3.new(1, 1, 1))
_ = note
S.label(panel, "TOP 100", UDim2.fromScale(0.45, 0.06), UDim2.fromScale(0.52, 0.13), S.GOLD, S.FONT_TITLE)
local board = S.list(panel, UDim2.fromScale(0.45, 0.78), UDim2.fromScale(0.52, 0.2))

local function lockLevel()
	local lvl = player:GetAttribute("Level") or 1
	local ok = (player:GetAttribute("Prestige") or 0) > 0 or lvl >= 15
	b1.Active = ok
	b3.Active = ok
	b1.BackgroundColor3 = if ok then S.BLUE else Color3.fromRGB(60, 60, 70)
	b3.BackgroundColor3 = b1.BackgroundColor3
	if not ok then
		qs.Text = "Unlocks at Lv15"
	end
end
local function renderMe(d: any)
	local rank = d.rank or player:GetAttribute("RankedRank") or "Earthling"
	me.Text = ("%s  •  %d Elo\nW %d / L %d  •  peak %d%s\nSeason %d"):format(
		rank,
		d.elo or 1000,
		d.wins or 0,
		d.losses or 0,
		d.peak or 1000,
		if d.provisional then "  •  placements" else "",
		d.season or 1
	)
	me.TextColor3 = RANK_COL[rank] or S.GOLD
	queuedFmt = d.queued
	b1.Text = if queuedFmt == "1v1" then "LEAVE QUEUE" else "QUEUE 1v1"
	b3.Text = if queuedFmt == "3v3" then "LEAVE QUEUE" else "QUEUE 3v3"
	qs.Text = if queuedFmt then ("Searching %s..."):format(queuedFmt) else ""
	lockLevel()
end
ClientAPI.onRanked(function(d)
	if d.error then
		S.toast(gui, tostring(d.error), S.RED)
		return
	end
	if d.matchFound then
		S.toast(gui, "MATCH FOUND! (" .. d.matchFound .. ")")
		qs.Text = "Teleporting..."
		return
	end
	if d.result ~= nil then
		S.toast(
			gui,
			(if d.result == 1 then "VICTORY " elseif d.result == 0 then "DEFEAT " else "DRAW ")
				.. (if d.delta >= 0 then "+" else "")
				.. d.delta
				.. " Elo",
			if d.result == 1 then S.GREEN else S.RED
		)
	end
	if d.elo then
		renderMe(d)
	end
end)
ClientAPI.onLeaderboard(function(list)
	S.clear(board)
	for i, e in list do
		local c = S.card(board, 30, i)
		local name = "#" .. e.userId
		pcall(function()
			name = Players:GetNameFromUserIdAsync(e.userId)
		end)
		local l = S.label(
			c,
			("%d.  %s   %d"):format(i, name, e.elo),
			UDim2.new(1, -12, 1, -4),
			UDim2.fromOffset(8, 2),
			if e.userId == player.UserId then S.GOLD else Color3.new(1, 1, 1)
		)
		l.TextXAlignment = Enum.TextXAlignment.Left
	end
	if #list == 0 then
		S.label(board, "No ranked games yet this season.", UDim2.new(1, -12, 0, 30), UDim2.new(), S.MUTED)
	end
end)
renderMe({ elo = player:GetAttribute("RankedElo") or 1000 })
