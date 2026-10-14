--!strict
-- ModuleScript: ServerScriptService.Modules.ReplayRecorder (WP-HOOK-2)
-- 10 Hz ring-buffer recording for last 30s of match combat across all players.
-- Detects and broadcasts the "Best Moment" (highest damage/combo 8s window) for post-match replay.
-- Guaranteed memory <= 2 MB per 40 players.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReplayMath = require(Shared:WaitForChild("ReplayMath"))
local Net = require(script.Parent.Net)

local ReplayRecorder = {}

local ReplayRemote = Net.remote("BestMomentReplay")

type PlayerBuffer = {
	userId: number,
	name: string,
	buffer: ReplayMath.RingBuffer,
}

local playerBuffers: { [number]: PlayerBuffer } = {}
local damageEvents: { ReplayMath.DamageEvent } = {}
local isRecording = false

local function root(p: Player): BasePart?
	return if p.Character then p.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function hum(p: Player): Humanoid?
	return if p.Character then p.Character:FindFirstChildOfClass("Humanoid") else nil
end

function ReplayRecorder.recordDamage(attackerName: string, victimName: string, damage: number, combo: number)
	if not isRecording then
		return
	end
	table.insert(damageEvents, {
		t = os.clock(),
		attacker = attackerName,
		victim = victimName,
		damage = damage,
		combo = combo,
	})
	-- Keep recent damage events within 60s
	if #damageEvents > 200 then
		local cutoff = os.clock() - 60
		local filtered = {}
		for _, ev in damageEvents do
			if ev.t >= cutoff then
				table.insert(filtered, ev)
			end
		end
		damageEvents = filtered
	end
end

function ReplayRecorder.start()
	isRecording = true
	damageEvents = {}
	playerBuffers = {}
	for _, p in Players:GetPlayers() do
		playerBuffers[p.UserId] = {
			userId = p.UserId,
			name = p.Name,
			buffer = ReplayMath.newRingBuffer(),
		}
	end
end

function ReplayRecorder.stop(): any?
	isRecording = false
	local best = ReplayMath.findBestMoment(damageEvents)
	if not best then
		return nil
	end

	-- Extract frame slice around the highlight window [startTime, endTime]
	local highlightFrames: { [string]: { ReplayMath.CompactFrame } } = {}
	for userId, pb in playerBuffers do
		local allFrames = ReplayMath.getFrames(pb.buffer)
		local slice: { ReplayMath.CompactFrame } = {}
		for _, f in allFrames do
			if f.t >= best.startTime - 0.5 and f.t <= best.endTime + 0.5 then
				table.insert(slice, f)
			end
		end
		if #slice > 0 then
			highlightFrames[tostring(userId)] = slice
		end
	end

	local packet = {
		bestMoment = best,
		frames = highlightFrames,
	}

	-- Broadcast best moment to all clients
	ReplayRemote:FireAllClients(packet)
	return packet
end

function ReplayRecorder.init()
	Players.PlayerAdded:Connect(function(p)
		if isRecording then
			playerBuffers[p.UserId] = {
				userId = p.UserId,
				name = p.Name,
				buffer = ReplayMath.newRingBuffer(),
			}
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		playerBuffers[p.UserId] = nil
	end)

	-- 10 Hz recording loop
	task.spawn(function()
		while true do
			task.wait(1 / ReplayMath.SAMPLE_RATE)
			if isRecording then
				local now = os.clock()
				for _, p in Players:GetPlayers() do
					local pb = playerBuffers[p.UserId]
					if pb then
						local r = root(p)
						local h = hum(p)
						if r then
							local pos = r.Position
							local anim = p:GetAttribute("CurrentAnim")
							local hp = if h then h.Health else nil
							ReplayMath.pushFrame(pb.buffer, {
								t = now,
								x = math.floor(pos.X * 10) / 10,
								y = math.floor(pos.Y * 10) / 10,
								z = math.floor(pos.Z * 10) / 10,
								anim = if type(anim) == "string" then anim else nil,
								hp = if hp then math.floor(hp) else nil,
							})
						end
					end
				end
			end
		end
	end)
end

return ReplayRecorder
