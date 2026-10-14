-- Script: boots v1.2 systems (Store + Training camps). Kept separate from RoundManager so parallel tracks don't collide.
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local Store = require(Modules:WaitForChild("Store"))
local Training = require(Modules:WaitForChild("Training"))
Store.init()
Training.init()
local AnnouncerService = require(Modules:WaitForChild("AnnouncerService"))
AnnouncerService.init()
local Moderation = require(Modules:WaitForChild("Moderation"))
Moderation.init()
local TelegraphService = require(Modules:WaitForChild("TelegraphService"))
TelegraphService.init()
local DragonBallService = require(Modules:WaitForChild("DragonBallService"))
DragonBallService.init()
local KingKaiGames = require(Modules:WaitForChild("KingKaiGames"))
KingKaiGames.init()
local ReplayRecorder = require(Modules:WaitForChild("ReplayRecorder"))
ReplayRecorder.init()
local RankedService = require(Modules:WaitForChild("RankedService"))
RankedService.init()
local DivineFavorService = require(Modules:WaitForChild("DivineFavorService"))
DivineFavorService.init()
-- Studio dev: grant some Zeni so the shop can be tested (never in live servers)
if game:GetService("RunService"):IsStudio() then
	local PlayerData = require(Modules.PlayerData)
	local function dev(p: Player)
		task.spawn(function()
			for _ = 1, 40 do
				if PlayerData.get(p) then
					break
				end
				task.wait(0.25)
			end
			local pr = PlayerData.get(p) :: any
			if pr and (pr.zeni or 0) < 50000 then
				pr.zeni = 50000
				Store.sync(p)
			end
		end)
	end
	for _, p in game.Players:GetPlayers() do
		dev(p)
	end
	game.Players.PlayerAdded:Connect(dev)
end
print("[V12Boot] Store + Training ready")
