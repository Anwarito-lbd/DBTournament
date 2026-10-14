--!strict
-- ModuleScript: ServerScriptService.Modules.QuestService
-- Daily/weekly quests: persistence in PlayerData profile.quests (schema v7), progress via QuestService.track(p, key, n),
-- claim via remote. Remotes: ClaimQuest(scope "daily"|"weekly", index 1..3), RerollQuest(index), QuestUpdate (server->client:
-- state table; also mirrored as player attribute QuestsJson for simple UIs).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Quests = require(game:GetService("ReplicatedStorage").Shared.Quests)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)

local QuestService = {}
local ClaimQuest = Net.remote("ClaimQuest")
local RerollQuest = Net.remote("RerollQuest")
local QuestUpdate = Net.remote("QuestUpdate")

local function state(p: Player): any?
	local prof = PlayerData.get(p)
	if not prof then return nil end
	local x = prof :: any
	if type(x.quests) ~= "table" then x.quests = Quests.new() end
	return x.quests
end

local function push(p: Player)
	local s = state(p)
	if not s then return end
	local view = { daily = {}, weekly = {} }
	for scope, list in { daily = s.daily, weekly = s.weekly } do
		for i, slot in list do
			local d = Quests.def(slot.id)
			if d then (view :: any)[scope][i] = { id = slot.id, text = d.text, prog = slot.prog, goal = d.goal, claimed = slot.claimed, zeni = d.zeni } end
		end
	end
	p:SetAttribute("QuestsJson", HttpService:JSONEncode(view))
	QuestUpdate:FireClient(p, view)
end

function QuestService.refresh(p: Player)
	local s = state(p)
	if s and Quests.refresh(s, p.UserId, os.time()) then push(p) end
end

-- Server-only: add progress. Keys: match, win, ko, ringout, parry, struggleWin, gift, teamCombo, transform,
-- trainMinutes, gravity300, drill, spiritBombDonate.
function QuestService.track(p: Player, key: string, n: number?)
	local s = state(p)
	if not s then return end
	Quests.refresh(s, p.UserId, os.time())
	local done = Quests.track(s, key, n or 1)
	push(p)
	if #done > 0 then QuestUpdate:FireClient(p, { completed = #done }) end
end

ClaimQuest.OnServerEvent:Connect(function(p, scope, index)
	if type(scope) ~= "string" or type(index) ~= "number" or index ~= index // 1 then return end
	if not RateLimit.allow(p, "quest", 2, 3) then return end
	local s = state(p)
	if not s then return end
	Quests.refresh(s, p.UserId, os.time())
	local d = Quests.claim(s, scope, index)
	if d then
		PlayerData.grantReward(p, { zeni = d.zeni, xp = d.xp, drinks = d.drinks, passXp = d.passXp }) -- saves
	end
	push(p)
end)

RerollQuest.OnServerEvent:Connect(function(p, index)
	if type(index) ~= "number" or not RateLimit.allow(p, "quest", 2, 3) then return end
	local s = state(p)
	if not s then return end
	Quests.refresh(s, p.UserId, os.time())
	if Quests.reroll(s, index, p.UserId, os.time()) then PlayerData.saveSoon(p) end
	push(p)
end)

function QuestService.init()
	local function ready(p: Player)
		task.spawn(function()
			local t = os.clock()
			while p.Parent and not p:GetAttribute("DataLoaded") and os.clock() - t < 60 do task.wait(0.5) end
			if p.Parent then QuestService.refresh(p); push(p) end
		end)
	end
	Players.PlayerAdded:Connect(ready)
	for _, p in Players:GetPlayers() do ready(p) end
	task.spawn(function() -- day/week rollover for long sessions
		while true do task.wait(60); for _, p in Players:GetPlayers() do QuestService.refresh(p) end end
	end)
end

return QuestService
