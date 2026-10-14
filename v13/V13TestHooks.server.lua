-- TEMPORARY Studio-only test hooks for the v1.3 play-test (installed into the place by test13.py, removed after).
if not game:GetService("RunService"):IsStudio() then return end
local M = game.ServerScriptService:WaitForChild("Modules")
local Config = require(game.ReplicatedStorage.Shared.Config)
if not Config.DEV_MODE then return end
local PlayerData = require(M.PlayerData)
local Arena = require(M.Arena)
local ToPLogic = require(game.ReplicatedStorage.Shared.ToPLogic)
local f = game.ServerStorage:FindFirstChild("DevHooks") or Instance.new("Folder"); f.Name = "DevHooks"; f.Parent = game.ServerStorage
local bf = Instance.new("BindableFunction"); bf.Name = "V13"; bf.Parent = f
bf.OnInvoke = function(cmd, a, b, c)
	local p = game.Players:GetPlayers()[1]
	local prof = p and PlayerData.get(p) :: any
	if cmd == "profile" then
		prof.level = a; prof.story = prof.story or { done = {}, badges = {} }
		for i = 1, b do prof.story.done[tostring(i)] = true end
		p:SetAttribute("Level", a)
		return "level=" .. prof.level .. " done32=" .. tostring(prof.story.done["32"]) ..
			" storyFormOk=" .. tostring(ToPLogic.storyFormOk(Config.FORMS.SuperSaiyan4, prof.level, prof.prestige or 0, prof.story.done))
	elseif cmd == "damage" then
		return Arena.damageAt(a, b, c)
	elseif cmd == "xp" then
		return "level=" .. tostring(prof.level) .. " xp=" .. tostring(prof.xp) .. " total=" .. tostring(prof.totalXp)
	elseif cmd == "ringcheck" then
		return tostring(Arena.checkRingOut(p))
	end
end
