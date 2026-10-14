-- LocalScript (v3, db-story): live Tournament of Power cinematics + Grand Priest announcer, driven by db-gameplay remotes.
--   UniverseErased -> StoryDialogue.Erase      (Zenos raise hands, stand fades to light, Grand Priest announces)
--   SurvivalEvent  -> Warn: 5s countdown banner + SurvivalWarn line; Enter: StoryDialogue.SurvivalEnter (Jiren entrance);
--                     Defeated: SurvivalDefeated + ZenoReactions; End: SurvivalEnd
--   PlayerEliminated (victim, killer?, "KO"|"RingOut"|...) -> EliminationAnnounce / RingOutAnnounce barks,
--                     sometimes a ZenoReactions line, BulmaCheers when your universe scored the KO
--   SuperShenron is NOT handled here: EndingUI.client.lua owns the Summon / Granted ending (no double play).
-- Every cinematic runs through CutsceneDirector.run (skip button + Space/Enter/B, watchdog, camera always restored).
-- Fighters still alive in the round keep their camera and controls (HUD + in-world FX only); spectators and
-- eliminated players get the full camera cinematic. Flip CINEMATIC_FOR_FIGHTERS to change that.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared:WaitForChild("UIKit"))
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local Director = require(Shared:WaitForChild("CutsceneDirector"))
local Story = require(ReplicatedStorage:WaitForChild("StoryDialogue"))
local player = Players.LocalPlayer

local CINEMATIC_FOR_FIGHTERS = false
local BARK_GAP = 2.5          -- seconds between announcer barks (extra eliminations inside the gap are dropped)
local ZENO_REACT_CHANCE = 0.3
local BULMA_CHANCE = 0.5

local function fighting(): boolean
	return player:GetAttribute("Alive") == true and workspace:GetAttribute("RoundState") == "InRound"
end
local function takeCamera(): boolean return CINEMATIC_FOR_FIGHTERS or not fighting() end

local function teamLabel(t: any, fallbackN: any?): string
	if typeof(t) == "Instance" and t:IsA("Team") then return t.Name end
	if type(t) == "string" and t ~= "" then return t end
	if fallbackN then return "Universe " .. tostring(fallbackN) end
	return "their universe"
end

-- ===== barks (non-blocking subtitles, hidden while a cinematic is up) =====
local barkGui = UIKit.gui("ToPBarks", 17)
local barkSay = UIKit.subtitles(barkGui)
local barkBox = barkGui:FindFirstChildOfClass("Frame") :: Frame
barkBox.Visible = false
local lastBark, barkSeq = 0, 0
local function bark(speaker: string, text: string, secs: number?)
	if Director.isPlaying() then return end
	barkSeq += 1
	local my = barkSeq
	barkBox.Visible = true
	barkSay(speaker, text)
	task.delay(secs or 3, function() if my == barkSeq then barkBox.Visible = false end end)
end
local function barkPool(pool: string, speaker: string, vars: { [string]: any }?, secs: number?): boolean
	local l = Director.pick((Story :: any)[pool])
	if not l then return false end
	bark(l.speaker or speaker, Director.fill(l.text, vars), secs)
	return true
end

-- ===== queue: cinematics never overlap; a newer one waits for the current one (max 3 pending) =====
local queue: { () -> () } = {}
local busy = false
local function pump()
	if busy then return end
	local nextFn = table.remove(queue, 1)
	if not nextFn then return end
	busy = true
	nextFn()
end
local function enqueue(fn: (done: () -> ()) -> ())
	if #queue >= 3 then table.remove(queue, 1) end
	table.insert(queue, function()
		local finished = false
		fn(function()
			if finished then return end
			finished = true; busy = false; task.defer(pump)
		end)
	end)
	pump()
end
local function cinematic(name: string, beats: { any }, vars: { [string]: any }, maxSeconds: number)
	enqueue(function(done)
		if workspace:GetAttribute("RoundState") ~= "InRound" then done(); return end
		barkSeq += 1; barkBox.Visible = false
		Director.run({ name = name, beats = beats, story = Story, team = player.Team, vars = vars,
			takeCamera = takeCamera(), maxSeconds = maxSeconds, onDone = function() done() end })
	end)
end

-- ===== 5s warning countdown banner =====
local warnGui = UIKit.gui("ToPWarn", 19)
local warnLabel = UIKit.label(warnGui, "", UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 0.34, 0), 56, Color3.fromRGB(255, 80, 60))
warnLabel.Visible = false
local warnSeq = 0
local function countdown(name: string, seconds: number)
	warnSeq += 1
	local my = warnSeq
	task.spawn(function()
		for s = seconds, 1, -1 do
			if my ~= warnSeq or workspace:GetAttribute("RoundState") ~= "InRound" then break end
			warnLabel.Text = string.upper(name) .. " ARRIVES IN " .. s
			warnLabel.Visible = true
			local sc = warnLabel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale"); sc.Parent = warnLabel; sc.Scale = 1.35
			TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			task.wait(1)
		end
		if my == warnSeq then warnLabel.Visible = false end
	end)
end

-- ===== remotes =====
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local function on(name: string, fn: (...any) -> ())
	local r = Remotes and Remotes:WaitForChild(name, 15)
	if r and r:IsA("RemoteEvent") then r.OnClientEvent:Connect(fn) else warn("[ToPCinematics] missing remote " .. name) end
end

task.spawn(on, "UniverseErased", function(d)
	if type(d) ~= "table" then return end
	local vars = { universe = teamLabel(d.team, d.universe), universeN = d.universe, placement = d.placement }
	cinematic("Erase", Story.Erase, vars, 14)
end)

task.spawn(on, "SurvivalEvent", function(d)
	if type(d) ~= "table" then return end
	local name = tostring(d.name or "Jiren")
	if d.phase == "Warn" then
		countdown(name, tonumber(d.seconds) or 5)
		barkPool("SurvivalWarn", "npc_grand_priest", nil, 4)
	elseif d.phase == "Enter" then
		warnSeq += 1; warnLabel.Visible = false
		cinematic("SurvivalEnter", Story.SurvivalEnter, { boss = name }, 12)
	elseif d.phase == "Defeated" then
		local vars = { player = tostring(d.by or "A fighter"), universe = teamLabel(d.team) }
		task.spawn(function()
			barkPool("SurvivalDefeated", "npc_grand_priest", vars, 3.5)
			task.wait(3.6)
			barkPool("ZenoReactions", "npc_zeno", nil, 3)
		end)
	elseif d.phase == "End" then
		warnSeq += 1; warnLabel.Visible = false
		barkPool("SurvivalEnd", "npc_grand_priest", nil, 3.5)
	end
end)

ClientAPI.onEliminated:Connect(function(victim, killer, reason)
	if workspace:GetAttribute("RoundState") ~= "InRound" then return end
	if reason ~= "KO" and reason ~= "RingOut" then return end -- Leave / Fusion are not announced
	local now = os.clock()
	if now - lastBark < BARK_GAP then return end
	lastBark = now
	local vName, vTeam = "A fighter", nil
	if typeof(victim) == "Instance" and victim:IsA("Player") then vName, vTeam = victim.DisplayName, victim.Team
	elseif type(victim) == "string" then vName = victim end -- dev bots arrive as a name string
	local vars = { player = vName, universe = teamLabel(vTeam) }
	barkPool(if reason == "RingOut" then "RingOutAnnounce" else "EliminationAnnounce", "npc_grand_priest", vars, 3)
	local myTeamScored = typeof(killer) == "Instance" and killer:IsA("Player") and player.Team ~= nil and killer.Team == player.Team
	task.delay(3.1, function()
		if workspace:GetAttribute("RoundState") ~= "InRound" then return end
		if myTeamScored and math.random() < BULMA_CHANCE then barkPool("BulmaCheers", "Bulma", nil, 2.6)
		elseif math.random() < ZENO_REACT_CHANCE then barkPool("ZenoReactions", "npc_zeno", nil, 2.6) end
	end)
end)

-- leaving the round always tears everything down (camera restored by Director's stop path)
ClientAPI.onRoundState:Connect(function(state)
	if state ~= "InRound" then
		table.clear(queue)
		Director.stopActive(false)
		warnSeq += 1; warnLabel.Visible = false
		barkSeq += 1; barkBox.Visible = false
	end
end)
