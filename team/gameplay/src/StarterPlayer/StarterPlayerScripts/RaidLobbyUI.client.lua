-- LocalScript (v8, db-gameplay): Raid lobby (Broly / Moro). Shows players, tier, first-clear reward and PUBLISHED drop
-- odds (free drops). Join / leave queue, countdown, results. Toggle [O].
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
if not S.remotes({ "RaidJoin", "RaidLeave", "RaidUpdate", "RaidInfo" }, 15) then return end
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))

local gui = S.gui("RaidLobbyUI", 21)
local panel = S.panel(gui, 0.55, 0.7, 720, 540)
S.title(panel, "RAIDS")
local set = S.toggle(gui, panel, Enum.KeyCode.O, "Raids", 3, function() ClientAPI.requestRaidInfo() end)
S.close(panel, function() set(false) end)
local status = S.label(panel, "", UDim2.fromScale(0.94, 0.07), UDim2.fromScale(0.03, 0.12), S.GOLD)
local list = S.list(panel, UDim2.fromScale(0.94, 0.78), UDim2.fromScale(0.03, 0.2))
local queued: string? = nil
local raids: { any } = {}

local function pretty(id: string): string return (string.gsub(string.gsub(id, "^%a+_", ""), "(%l)(%u)", "%1 %2")) end
local function render()
	S.clear(list)
	for i, r in raids do
		local c = S.card(list, 150, i)
		local t = S.label(c, ("%s   •   Tier %d   •   %d-%d players"):format(r.name, r.tier, r.min, r.max), UDim2.new(0.68, 0, 0, 30), UDim2.new(0, 10, 0, 6), S.GOLD, S.FONT_TITLE)
		t.TextXAlignment = Enum.TextXAlignment.Left
		local odds = {}
		for _, o in r.odds do table.insert(odds, ("%s  %.0f%%"):format(pretty(o.id), o.p * 100)) end
		local fc = r.firstClear or {}
		local body = S.label(c, ("Drop odds (free, published): %s\nWeekly first clear: +%d Zeni, %s\nAlways: Zeni + XP by damage share"):format(
			table.concat(odds, "  •  "), fc.zeni or 0, pretty(fc.cosmetic or "-")), UDim2.new(0.68, 0, 0, 100), UDim2.new(0, 10, 0, 40), Color3.new(1, 1, 1), S.FONT_BODY)
		body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top
		local inQ = queued == r.id
		S.button(c, if inQ then "LEAVE" else "JOIN", UDim2.new(0.26, 0, 0, 50), UDim2.new(0.71, 0, 0.5, -25), if inQ then S.RED else S.GREEN, function()
			if inQ then ClientAPI.leaveRaid(); queued = nil; status.Text = "" else ClientAPI.joinRaid(r.id); queued = r.id end
			render()
		end)
	end
end
ClientAPI.onRaidInfo(function(l) raids = l; table.sort(raids, function(a, b) return a.tier > b.tier end); render() end)
ClientAPI.onRaid(function(d)
	if d.error then S.toast(gui, tostring(d.error), S.RED); queued = nil; render()
	elseif d.queue then status.Text = ("In queue: %s  (%d / %d, need %d)"):format(d.queue, d.size or 0, d.max or 8, d.min or 4)
	elseif d.countdown then status.Text = ("Raid starts in %d s!"):format(d.countdown)
	elseif d.started then queued = nil; set(false); S.toast(gui, "RAID START: " .. d.started .. "!")
	elseif d.result then S.toast(gui, d.result .. (if d.drop then ("  •  Drop: " .. pretty(d.drop)) else ""), if d.result == "Victory" then S.GREEN else S.RED) end
end)
