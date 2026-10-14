-- LocalScript (v8, db-gameplay): Story mission list (arc, enemy, goal, rewards, locks). Toggle [M].
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
if not S.remotes({ "StoryList", "StoryStart", "StoryUpdate" }, 15) then return end
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))

local gui = S.gui("StoryUI", 21)
local panel = S.panel(gui, 0.6, 0.75, 760, 580)
S.title(panel, "STORY MODE")
local set = S.toggle(gui, panel, Enum.KeyCode.M, "Story", 4, function() ClientAPI.requestStory() end)
S.close(panel, function() set(false) end)
local list = S.list(panel, UDim2.fromScale(0.94, 0.84), UDim2.fromScale(0.03, 0.13))

local function goalText(g: any): string
	if not g then return "" end
	if g.type == "survive" then return ("Survive %d s"):format(g.seconds or 0)
	elseif g.type == "hits" then return ("Land %d hit%s"):format(g.count or 1, if (g.count or 1) == 1 then "" else "s")
	elseif g.type == "timed" then return ("Win within %d s"):format(g.seconds or 0) end
	return "Defeat the enemy"
end
ClientAPI.onStoryList(function(d)
	S.clear(list)
	if not d.available then S.label(list, "Story missions are not available on this server yet.", UDim2.new(1, -12, 0, 40), UDim2.new(), S.MUTED); return end
	local lastArc = nil
	for i, m in d.missions do
		if m.arc ~= lastArc then
			lastArc = m.arc
			local h = S.label(list, string.upper(m.arc) .. " ARC", UDim2.new(1, -12, 0, 26), UDim2.new(), S.GOLD, S.FONT_TITLE); h.LayoutOrder = i * 2 - 1
			h.TextXAlignment = Enum.TextXAlignment.Left
		end
		local c = S.card(list, 84, i * 2)
		if not m.unlocked then c.BackgroundTransparency = 0.5 end
		local t = S.label(c, ("%d. %s%s"):format(m.id, m.name, if m.done then "  ✓" else ""), UDim2.new(0.7, 0, 0, 26), UDim2.new(0, 10, 0, 4),
			if m.done then S.GREEN else Color3.new(1, 1, 1)); t.TextXAlignment = Enum.TextXAlignment.Left
		local r = m.rewards or {}
		local b = S.label(c, ("vs %s  •  %s\n%s\nRewards: %d XP, %d Zeni%s"):format(m.enemy or "?", goalText(m.goal), m.objective, r.xp or 0, r.zeni or 0,
			if r.title then (", title \"" .. r.title .. "\"") else ""), UDim2.new(0.7, 0, 0, 54), UDim2.new(0, 10, 0, 28), S.MUTED, S.FONT_BODY)
		b.TextXAlignment = Enum.TextXAlignment.Left; b.TextYAlignment = Enum.TextYAlignment.Top
		if m.unlocked then
			S.button(c, if m.done then "REPLAY" else "START", UDim2.new(0.22, 0, 0, 44), UDim2.new(0.76, 0, 0.5, -22), if m.done then S.BLUE else S.GREEN,
				function() ClientAPI.startStory(m.id); set(false) end)
		else
			S.label(c, "LOCKED\nclear the previous mission", UDim2.new(0.22, 0, 0, 44), UDim2.new(0.76, 0, 0.5, -22), S.RED)
		end
	end
end)
ClientAPI.onStory(function(d)
	if d.error then S.toast(gui, tostring(d.error), S.RED)
	elseif d.started then S.toast(gui, d.name .. ": " .. goalText(d.goal))
	elseif d.result then S.toast(gui, "Mission " .. d.result, if d.result == "Victory" then S.GREEN else S.RED) end
end)
