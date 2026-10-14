--!strict
-- ModuleScript: ServerScriptService.Modules.StoryMissionService  (v8; GDD §7.3)
-- Loads db-story's mission list (gameplay/StoryMissions.lua) from the first ModuleScript found at:
--   ServerScriptService.Modules.StoryMissions | ServerScriptService.StoryMissions | ServerStorage.StoryMissions |
--   ReplicatedStorage.Shared.StoryMissions
-- Validated + normalized by Shared/StorySchema (bad entries skipped, errors warned). Missing/broken file => service stays
-- disabled (StoryList returns { available = false }), nothing else breaks.
-- Mission = solo instance (BossNPC arena): enemy boss scaled by mission id; goal types defeat / survive N s / land N hits /
-- defeat within N s. Sequential unlock (mission n needs n-1). Rewards: XP, Zeni, title; "form" rewards are a cosmetic
-- mastery badge only (story never grants power -- proposal pending lead approval). Persistence: profile.story (v8),
-- keys are tostring(id) (DataStore-safe).
-- Remotes: StoryList (c->s request, s->c list), StoryStart(id), StoryUpdate (s->c).
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local StorySchema = require(Shared.StorySchema)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local Combat = require(script.Parent.Combat)
local BossNPC = require(script.Parent.BossNPC)

local StoryMissionService = {}
local ListR = Net.remote("StoryList")
local StartR = Net.remote("StoryStart")
local Update = Net.remote("StoryUpdate")
local missions: { any } = {}
local byId: { [number]: any } = {}
local available = false
local active: { [Player]: any } = {}

local function findModule(): ModuleScript?
	local mods = ServerScriptService:FindFirstChild("Modules")
	for _, c in
		{
			mods and mods:FindFirstChild("StoryMissions"),
			ServerScriptService:FindFirstChild("StoryMissions"),
			ServerStorage:FindFirstChild("StoryMissions"),
			Shared:FindFirstChild("StoryMissions"),
		}
	do
		if c and c:IsA("ModuleScript") then
			return c
		end
	end
	return nil
end

function StoryMissionService.load(): boolean
	local m = findModule()
	if not m then
		warn("[StoryMissionService] StoryMissions module not found; story disabled")
		return false
	end
	local ok, raw = pcall(require, m)
	if not ok then
		warn("[StoryMissionService] StoryMissions failed to load: " .. tostring(raw))
		return false
	end
	local list, errs = StorySchema.normalize(raw)
	for _, e in errs do
		warn("[StoryMissionService] skipped: " .. e)
	end
	missions = list
	byId = {}
	for _, x in list do
		byId[x.id] = x
	end
	available = #list > 0
	return available
end

local function story(p: Player): any?
	local prof = PlayerData.get(p) :: any
	return prof and prof.story
end
local function unlocked(p: Player, id: number): boolean
	if not Config.STORY.sequential then
		return true
	end
	local s = story(p)
	if not s then
		return false
	end
	local prev = nil
	for _, x in missions do
		if x.id < id then
			prev = x.id
		end
	end
	return prev == nil or s.done[tostring(prev)] == true
end

ListR.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "storylist", 1, 2) then
		return
	end
	if not available then
		ListR:FireClient(p, { available = false })
		return
	end
	local s = story(p)
	local out = {}
	for _, x in missions do
		table.insert(
			out,
			{
				id = x.id,
				arc = x.arc,
				name = x.name,
				enemy = x.enemy,
				objective = x.objective,
				goal = x.goal,
				rewards = x.rewards,
				done = s and s.done[tostring(x.id)] == true,
				unlocked = unlocked(p, x.id),
			}
		)
	end
	ListR:FireClient(p, { available = true, missions = out })
end)

local function endMission(p: Player, run: any, win: boolean)
	if run.done then
		return
	end
	run.done = true
	if win then
		local s = story(p)
		local first = s and not s.done[tostring(run.m.id)]
		if s then
			s.done[tostring(run.m.id)] = true
			if run.m.rewards.badge then
				s.badges[run.m.rewards.badge] = true
			end
		end
		local r = run.m.rewards
		-- full rewards on first clear, 25% Zeni/XP on replays (anti-farm)
		PlayerData.grantReward(
			p,
			{
				xp = if first then r.xp else math.floor(r.xp / 4),
				zeni = if first then r.zeni else math.floor(r.zeni / 4),
				title = if first then r.title else nil,
			}
		)
	end
	Update:FireClient(p, { result = if win then "Victory" else "Defeat", id = run.m.id })
	task.delay(3, function()
		active[p] = nil
		p:SetAttribute("InRaid", nil)
		p:SetAttribute("InStory", nil)
		local spawn = (workspace:FindFirstChild("WorldOfVoid") or workspace):FindFirstChild(
				"Spawn_Lobby_01",
				true
			) :: BasePart?
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r and spawn then
			r.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
		end
		if run.boss.alive then
			BossNPC.despawn(run.boss)
		end
		BossNPC.freeArena(run.arena, run.slot)
	end)
end

StartR.OnServerEvent:Connect(function(p, id)
	if type(id) ~= "number" or not RateLimit.allow(p, "storystart", 1, 3) or not available then
		return
	end
	local m = byId[id]
	if
		not m
		or active[p]
		or p:GetAttribute("InRaid")
		or (workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") == true)
	then
		return
	end
	if not unlocked(p, id) then
		Update:FireClient(p, { error = "Locked" })
		return
	end
	local S = Config.STORY
	local arena, cf, slot = BossNPC.allocArena(nil) -- story: generated platform (raid maps stay free)
	p:SetAttribute("InRaid", true)
	p:SetAttribute("InStory", true) -- InRaid lets Combat act vs the boss
	Combat.resetPlayer(p)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if r then
		r.CFrame = cf * CFrame.new(0, 0, 30)
	end
	local def = {
		id = "story_" .. id,
		name = m.enemy,
		animId = "story_" .. string.lower(string.gsub(m.enemy, "%W", "")),
		hp = S.bossBaseHp + S.hpPerMission * id,
		walkSpeed = 15,
		phases = { 0.5 },
		phaseMods = { { dmg = 1, speed = 1, cdMult = 1 }, { dmg = 1.2, speed = 1.1, cdMult = 0.85 } },
		melee = { damage = S.bossDamage + S.dmgPerMission * id, range = 8, cd = 1.6, kb = 40 },
		specials = { Stomp = { cd = 8, windup = 0.8, radius = 14, damage = 10 + id * 0.3 } },
	}
	local run: any = { m = m, arena = arena, slot = slot, t0 = os.clock(), done = false }
	run.boss = BossNPC.spawn(def, cf * CFrame.new(0, 2, -20), arena, { p }, {
		hpMult = 1,
		dmgMult = 1,
		onDefeated = function()
			endMission(p, run, m.goal.type == "defeat" or m.goal.type == "timed" or m.goal.type == "hits")
		end,
	})
	active[p] = run
	Update:FireClient(p, { started = id, name = m.name, objective = m.objective, goal = m.goal, dialogue = m.dialogue })
	local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if h then
		h.Died:Once(function()
			if active[p] == run then
				endMission(p, run, false)
			end
		end)
	end
	task.spawn(function()
		local limit = if m.goal.type == "timed" then m.goal.seconds else S.timeLimit
		while not run.done do
			task.wait(0.5)
			local t = os.clock() - run.t0
			if not p.Parent then
				endMission(p, run, false)
				break
			end
			if
				(m.goal.type == "survive" and t >= (m.goal.seconds or 60))
				or (m.goal.type == "hits" and (run.boss.hitsBy[p] or 0) >= (m.goal.count or 10))
			then
				endMission(p, run, true)
			elseif t >= limit then
				endMission(p, run, false)
			end
		end
	end)
end)

function StoryMissionService.init()
	StoryMissionService.load()
	Players.PlayerRemoving:Connect(function(p)
		active[p] = nil
	end)
end
function StoryMissionService.isAvailable(): boolean
	return available
end

return StoryMissionService
