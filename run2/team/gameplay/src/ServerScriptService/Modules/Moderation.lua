--!strict
-- ModuleScript: ServerScriptService.Modules.Moderation (WP25)
-- Production moderation, text filtering, reporting, and ban list DataStore.
-- Enforces: TextService filtering, report logging, ban verification on join, and RELEASE dev stripping.
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local DataStoreService = game:GetService("DataStoreService")

local Modules = script.Parent
local Net = require(Modules:WaitForChild("Net"))
local RateLimit = require(Modules:WaitForChild("RateLimit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Moderation = {}

local reportRemote = Net.remote("ReportPlayer")
local blockRemote = Net.remote("BlockPlayer")

export type BanRecord = {
	BannedUntil: number, -- os.time()
	Reason: string,
	BannedAt: number,
	AdminUserId: number?,
}

local banDataStore: DataStore? = nil
pcall(function()
	banDataStore = DataStoreService:GetDataStore("ModerationBans_v1")
end)

local banCache: { [number]: BanRecord } = {}
local reportsToday: { [string]: number } = {}

-- Returns true if game is in production RELEASE mode
function Moderation.isRelease(): boolean
	return (Config.DEV_MODE == false) or (workspace:GetAttribute("RELEASE") == true)
end

-- Filter custom text safely for all players or between two players
function Moderation.filterText(text: string, fromPlayer: Player, toPlayer: Player?): (boolean, string)
	if text == "" then
		return true, ""
	end

	local ok, res = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, fromPlayer.UserId)
		if toPlayer then
			return filterResult:GetChatForUserAsync(toPlayer.UserId)
		else
			return filterResult:GetNonChatStringForBroadcastAsync()
		end
	end)

	if ok and typeof(res) == "string" then
		return true, res
	else
		warn("[Moderation] Text filtering failed for player " .. fromPlayer.Name .. ":", res)
		return false, "###"
	end
end

-- Ban player by UserId
function Moderation.ban(userId: number, durationSeconds: number, reason: string, adminUserId: number?)
	local record: BanRecord = {
		BannedUntil = os.time() + durationSeconds,
		Reason = reason,
		BannedAt = os.time(),
		AdminUserId = adminUserId,
	}
	banCache[userId] = record

	if banDataStore then
		task.spawn(function()
			pcall(function()
				banDataStore:SetAsync(tostring(userId), record)
			end)
		end)
	end

	local targetPlayer = Players:GetPlayerByUserId(userId)
	if targetPlayer then
		targetPlayer:Kick(
			string.format("You have been banned: %s. Expires in %d hours.", reason, math.ceil(durationSeconds / 3600))
		)
	end
end

-- Check if player is currently banned
function Moderation.checkBan(userId: number): (boolean, BanRecord?)
	local cached = banCache[userId]
	if cached then
		if os.time() < cached.BannedUntil then
			return true, cached
		else
			banCache[userId] = nil
			return false, nil
		end
	end

	if banDataStore then
		local ok, record = pcall(function()
			return banDataStore:GetAsync(tostring(userId))
		end)
		if ok and typeof(record) == "table" and record.BannedUntil then
			local b = record :: BanRecord
			if os.time() < b.BannedUntil then
				banCache[userId] = b
				return true, b
			end
		end
	end

	return false, nil
end

-- Log exploit or serious anomaly and kick player
function Moderation.logExploit(player: Player, reason: string)
	warn(string.format("[EXPLOIT] Player %s (%d) flagged: %s", player.Name, player.UserId, reason))
	if Moderation.isRelease() then
		player:Kick("Disconnected for suspicious client activity.")
	end
end

function Moderation.init()
	-- Player join ban check
	Players.PlayerAdded:Connect(function(player)
		local isBanned, record = Moderation.checkBan(player.UserId)
		if isBanned and record then
			local remainingHours = math.ceil((record.BannedUntil - os.time()) / 3600)
			player:Kick(
				string.format("Banned from Dragon Block Z: %s (Remaining: %d hours)", record.Reason, remainingHours)
			)
		end
	end)

	-- Handle player report remote
	reportRemote.OnServerEvent:Connect(function(player, targetUserId, reason, details)
		if not RateLimit.allow(player, "report_player", 10.0, 3) then
			return
		end

		if typeof(targetUserId) ~= "number" or typeof(reason) ~= "string" then
			return
		end

		local cleanDetails = ""
		if typeof(details) == "string" and #details > 0 then
			local _ok, filtered = Moderation.filterText(string.sub(details, 1, 200), player, nil)
			cleanDetails = filtered
		end

		local reportKey = string.format("%d_%d", player.UserId, targetUserId)
		reportsToday[reportKey] = (reportsToday[reportKey] or 0) + 1

		print(
			string.format(
				"[REPORT] %s (%d) reported user %d for '%s'. Details: %s",
				player.Name,
				player.UserId,
				targetUserId,
				reason,
				cleanDetails
			)
		)
	end)

	-- Handle player block remote
	blockRemote.OnServerEvent:Connect(function(player, targetUserId)
		if not RateLimit.allow(player, "block_player", 1.0, 5) then
			return
		end
		if typeof(targetUserId) == "number" then
			print(string.format("[BLOCK] %s (%d) blocked user %d", player.Name, player.UserId, targetUserId))
		end
	end)
end

return Moderation
