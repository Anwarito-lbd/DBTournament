--!strict
-- Script: ServerScriptService.RoundManager
-- States: Waiting -> Intermission -> CharacterSelect -> Countdown -> InRound -> Results -> Intermission
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Modules = script.Parent:WaitForChild("Modules")
local TeamAssignment = require(Modules.TeamAssignment)
local PlayerData = require(Modules.PlayerData)
local Net = require(Modules.Net)
local RateLimit = require(Modules.RateLimit)
local Party = require(Modules.Party)
local Combatant = require(Modules.Combatant)
local Arena = require(Modules.Arena)
local Combat = require(Modules.Combat)
local Fusion = require(Modules.Fusion)
local DevBots = require(Modules.DevBots)
-- v6 systems (races/modifiers, quests, training rooms, Beerus camp, Destroyer moves, team Spirit Bomb)
local RaceRuntime = require(Modules.RaceRuntime)
local QuestService = require(Modules.QuestService)
local TrainingRooms = require(Modules.TrainingRooms)
local DragonBallService = require(Modules.DragonBallService) -- v8
local RankedService = require(Modules.RankedService) -- v8
local RaidService = require(Modules.RaidService) -- v8
local StoryMissionService = require(Modules.StoryMissionService) -- v8
local StoryEpisodeService = require(Modules.StoryEpisodeService) -- v10 Legendary Episodes
local OnboardingService = require(Modules.OnboardingService) -- WP11
require(Modules.BeerusCamp) -- registers the BeerusTrial drill
require(Modules.DestroyerMoves) -- registers move kind "hakai"
local SpiritBomb = require(Modules.SpiritBomb) -- registers move kind "spiritbomb"; v8: resetRound between matches
local BossNPC = require(Modules.BossNPC) -- v8 Universe Survival event
local ToPLogic = require(ReplicatedStorage.Shared.ToPLogic) -- v8 pure ToP rules (tested)
require(Modules.RacePowerUps) -- registers barrier / justice / solarflare / kaikai
local Races = require(ReplicatedStorage.Shared.Races)
local _ = RaceRuntime
local RunService = game:GetService("RunService")
local DEV = Config.DEV_MODE and RunService:IsStudio()
workspace:SetAttribute("DevMode", DEV)

PlayerData.init()
QuestService.init()
TrainingRooms.init()
DragonBallService.init()
RankedService.init()
RaidService.init()
StoryMissionService.init()
StoryEpisodeService.init()
OnboardingService.init()
local lobby = TeamAssignment.getLobby()
if workspace:GetAttribute("EventMode") == nil then
	workspace:SetAttribute("EventMode", Config.EVENT_MODE)
end

-- Server -> client
local RoundState = Net.remote("RoundState") -- (state, timeLeft, extra)
local Eliminated = Net.remote("PlayerEliminated") -- (victim, killer?, reason)
local LevelUpRemote = Net.remote("LevelUp") -- (level, unlocks)
local LastGift = Net.remote("LastGift") -- (windowSeconds, {teammate userIds in range})
-- Client -> server (validated)
local GiftEnergy = Net.remote("GiftEnergy") -- (targetUserId)
local SpectateRequest = Net.remote("SpectateRequest") -- (targetUserId)
local PrestigeRemote = Net.remote("Prestige") -- ()
local IntroSkip = Net.remote("IntroSkip") -- () player skipped the intro cutscene
local WishChoice = Net.remote("WishChoice") -- (wishId) winner picks a Super Dragon Ball wish
local WishResult = Net.remote("WishResult") -- server -> all: (wishId, chooserName, winningTeamName)
-- Server hooks
local EliminateHook = Net.hook("EliminatePlayer") -- combat fires (victim, killer?, "KO"|"RingOut")
local RoundStarted = Net.hook("RoundStarted") -- (universes)
local RoundEnded = Net.hook("RoundEnded") -- (winningTeam?)
local GiftHook = Net.hook("LastGift") -- (from, to)
-- v8 ToP presentation hooks (db-animation / db-story / announcer): remotes for clients + server signals
local UniverseErased = Net.remote("UniverseErased") -- s->c ({ team, universe, placement, by = "Zeno" }) Zeno erase cinematic
local SurvivalEvent = Net.remote("SurvivalEvent") -- s->c ({ phase = "Warn"|"Enter"|"Defeated"|"End", name, ... })
local SuperShenron = Net.remote("SuperShenron") -- s->c ({ phase = "Summon"|"Granted", winner, wish? }) ending cinematic
local ErasedHook = Net.hook("UniverseErased") -- (team, placement)
local SurvivalHook = Net.hook("SurvivalEvent") -- (phase, bossModel?)
local ShenronHook = Net.hook("SuperShenron") -- (phase, winningTeam, wishId?)

PlayerData.LevelUp:Connect(function(p: Player, level: number, unlocks: { string })
	LevelUpRemote:FireClient(p, level, unlocks)
end)

local state = "Waiting"
local alive: { [Player]: boolean } = {}
local placements: { Team } = {}
local giftWindow: { [Player]: { untilT: number, pos: Vector3, team: Team? } } = {}
local giftUsed: { [Player]: boolean } = {}
local startSize: { [Team]: number } = {} -- v8: fighters per universe at round start (comeback rule)
local erased: { [Team]: boolean } = {}
local erasedAt: { [Team]: number } = {} -- D17: same-tick last wipes -> draw
local safePos: { [Player]: Vector3 } = {} -- v8: last in-ring position (gift range for ring-outs)
local eventBoss: any = nil

local function setState(s: string, t: number, extra: any?)
	state = s
	workspace:SetAttribute("RoundState", s)
	workspace:SetAttribute("TimeLeft", t)
	RoundState:FireAllClients(s, t, extra)
end

local function aliveTeams(): { Team }
	local out = {}
	for _, t in TeamAssignment.getUniverses() do
		local has = DevBots.aliveOn(t) > 0
		if not has then
			for p in alive do
				if p.Team == t then
					has = true
					break
				end
			end
		end
		if has then
			table.insert(out, t)
		end
	end
	return out
end
local roundKOs: { [string]: number } = {}

local function rootPos(p: Player): Vector3?
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return r and r.Position
end

-- ===== Spectate =====
local function pickSpectateTarget(p: Player): Player?
	for q in alive do
		if q.Team == p.Team and not Fusion.isPassenger(q) then
			return q
		end
	end
	for q in alive do
		if not Fusion.isPassenger(q) then
			return q
		end
	end
	return nil
end

local function startSpectate(p: Player)
	p:SetAttribute("Spectating", true)
	local t = pickSpectateTarget(p)
	p:SetAttribute("SpectateTarget", t and t.UserId or nil)
end

local function retargetSpectators(victim: Player)
	for _, q in Players:GetPlayers() do
		if q:GetAttribute("SpectateTarget") == victim.UserId and q:GetAttribute("Spectating") then
			startSpectate(q)
		end
	end
end

SpectateRequest.OnServerEvent:Connect(function(p, targetId)
	if type(targetId) ~= "number" or not RateLimit.allow(p, "spectate", 4, 6) then
		return
	end
	if p:GetAttribute("Spectating") ~= true or Fusion.isPassenger(p) then
		return
	end
	local t = Players:GetPlayerByUserId(targetId)
	if not t or not alive[t] or Fusion.isPassenger(t) then
		return
	end
	-- teammates first: only allow enemies when no teammate is alive
	if t.Team ~= p.Team then
		for q in alive do
			if q.Team == p.Team then
				return
			end
		end
	end
	p:SetAttribute("SpectateTarget", targetId)
end)

-- ===== v8: universe erasure + comeback =====
local checkWipes: () -> ()
local function aliveOn(t: Team): number
	local n = DevBots.aliveOn(t)
	for q in alive do
		if q.Team == t and not Fusion.isPassenger(q) then
			n += 1
		end
	end
	return n
end
checkWipes = function()
	if state ~= "InRound" then
		return
	end
	for _, t in TeamAssignment.getUniverses() do
		if erased[t] then
			continue
		end
		local n = aliveOn(t)
		if ToPLogic.wiped(n) then
			erased[t] = true
			erasedAt[t] = os.clock()
			table.insert(placements, t)
			local info = {
				team = t.Name,
				universe = t:GetAttribute("Universe"),
				placement = #TeamAssignment.getUniverses() - #placements + 1,
				by = "Zeno",
			}
			UniverseErased:FireAllClients(info)
			-- db-story: hide the erased stand (server) after the cinematic's fade; its spectators move to the lobby spawn
			local un = t:GetAttribute("Universe") :: number?
			if un then
				task.delay(3, function()
					if state ~= "InRound" or not erased[t] then
						return
					end
					Arena.hideStand(un)
					for _, q in t:GetPlayers() do
						if not alive[q] then
							Arena.teleport(q, "Lobby")
						end
					end
				end)
			end
			ErasedHook:Fire(t, info.placement)
		elseif n == 1 then
			local mod = ToPLogic.comeback(startSize[t] or 0, n, workspace:GetAttribute("Ranked") == true)
			if mod then
				for q in alive do
					if q.Team == t and not RaceRuntime.isActive(q, mod) then
						RaceRuntime.addBuff(q, mod, 9999)
						q:SetAttribute("LastStand", true)
					end
				end
			end
		end
	end
end

-- ===== Elimination (+ last energy gift window) =====
local eliminate: (Player, Player?, string) -> ()

local function openGiftWindow(p: Player, pos: Vector3)
	if giftUsed[p] then
		return
	end
	local cfg = Config.LAST_GIFT
	local candidates = {}
	for q in alive do
		if q.Team == p.Team and not Fusion.isPassenger(q) then
			local qp = rootPos(q)
			if qp and (qp - pos).Magnitude <= cfg.range then
				table.insert(candidates, q.UserId)
			end
		end
	end
	if #candidates == 0 then
		return
	end
	giftWindow[p] = { untilT = os.clock() + cfg.window, pos = pos, team = p.Team }
	p:SetAttribute("GiftWindow", true)
	LastGift:FireClient(p, cfg.window, candidates)
	task.delay(cfg.window, function()
		giftWindow[p] = nil
		if p.Parent then
			p:SetAttribute("GiftWindow", nil)
		end
	end)
end

GiftEnergy.OnServerEvent:Connect(function(p, targetId)
	if type(targetId) ~= "number" or not RateLimit.allow(p, "gift", 2, 3) then
		return
	end
	local w = giftWindow[p]
	if not w or os.clock() > w.untilT or giftUsed[p] then
		return
	end
	local t = Players:GetPlayerByUserId(targetId)
	if not t or t == p or not alive[t] or t.Team ~= w.team or Fusion.isPassenger(t) then
		return
	end
	local tp = rootPos(t)
	if not tp or (tp - w.pos).Magnitude > Config.LAST_GIFT.range then
		return
	end
	giftUsed[p] = true
	giftWindow[p] = nil
	p:SetAttribute("GiftWindow", nil)
	Combatant.giveGift(p, t)
	QuestService.track(p, "gift", 1)
	GiftHook:Fire(p, t)
end)

eliminate = function(p: Player, killer: Player?, reason: string)
	if state ~= "InRound" or not alive[p] then
		return
	end
	if
		reason ~= "Leave"
		and reason ~= "Fusion"
		and reason ~= "SelfKO"
		and reason ~= "Erased"
		and not Fusion.isPassenger(p)
		and not (workspace:GetAttribute("Ranked") == true and not Config.RANKED.allowSenzu)
		and PlayerData.consumeSenzu(p)
	then
		Arena.teleport(p, "Arena", TeamAssignment.universeOf(p)) -- Senzu revive
		Arena.clearRingOut(p)
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = hum.MaxHealth
		end
		return
	end
	local deathPos = if reason == "RingOut" then (safePos[p] or rootPos(p)) else rootPos(p)
	local wasFused = Fusion.wasFused(p)
	if ToPLogic.fusedOutcome(reason) == "Defuse" then
		Fusion.onLeave(p)
	end -- D20: disconnect defuses, partner fights on
	local passenger = Fusion.onEliminated(p) -- D20: KO / ring-out / AFK of the fused body -> both out
	alive[p] = nil
	Arena.clearRingOut(p)
	p:SetAttribute("Alive", false)
	if killer and killer ~= p and alive[killer] then
		PlayerData.addXP(killer, Config.XP_KO)
		PlayerData.addStat(killer, "kos", 1)
		roundKOs[killer.Name] = (roundKOs[killer.Name] or 0) + 1
		QuestService.track(killer, "ko", 1)
		-- Majin: heal 15% max HP on a melee KO (Ranked 50%)
		local heal = Races.koHeal(
			RaceRuntime.raceId(killer),
			Combat.lastMoveKind(killer),
			workspace:GetAttribute("Ranked") == true,
			Config.RACE_POWERUPS.MajinKOHeal,
			Config.RACE_POWERUPS.rankedUtility
		)
		local kh = killer.Character and killer.Character:FindFirstChildOfClass("Humanoid")
		if heal > 0 and kh and kh.Health > 0 then
			kh.Health = math.min(kh.MaxHealth, kh.Health + kh.MaxHealth * heal)
		end
		if reason == "RingOut" then
			QuestService.track(killer, "ringout", 1)
		end
	end
	Eliminated:FireAllClients(p, killer, reason)
	checkWipes()
	retargetSpectators(p)
	if passenger then
		eliminate(passenger, nil, "Fusion")
	end
	if reason == "Leave" then
		return
	end
	if ToPLogic.giftAllowed(reason, wasFused) and deathPos then
		openGiftWindow(p, deathPos)
	end -- no gift from a fused body / AFK
	local u = TeamAssignment.universeOf(p)
	task.delay(if giftWindow[p] then Config.LAST_GIFT.window else 0, function()
		if not p.Parent then
			return
		end
		Combatant.resetCombat(p)
		Arena.teleport(p, "Stand", u)
		startSpectate(p)
	end)
end
EliminateHook.Event:Connect(eliminate)

-- Dev bots: feed eliminations into the same flow (victim sent as the bot's name string)
DevBots.setEliminatedCallback(function(m: Model, killer: Player?, reason: string)
	if state ~= "InRound" then
		return
	end
	if killer and alive[killer] then
		PlayerData.addXP(killer, math.floor(Config.XP_KO * ToPLogic.BOT_XP_MULT)) -- D19: bots give 50% XP, no quest ticks
		roundKOs[killer.Name] = (roundKOs[killer.Name] or 0) + 1
	end
	Eliminated:FireAllClients(m.Name, killer, reason)
	checkWipes()
end)

-- ===== §10.1 AFK: activity = moved > 2 studs, a combat action, or ki charging (sampled 1 Hz) =====
local lastActive: { [Player]: number } = {}
local lastPos: { [Player]: Vector3 } = {}
local function touchActive(p: Player)
	lastActive[p] = os.clock()
	lastPos[p] = rootPos(p) :: any
end
task.spawn(function()
	while true do
		task.wait(1)
		for _, p in Players:GetPlayers() do
			local rp, lp = rootPos(p), lastPos[p]
			if not lastActive[p] then
				touchActive(p)
			elseif
				(rp and lp and (rp - lp).Magnitude > 2)
				or p:GetAttribute("Charging") == true
				or Combat.lastActiveT(p) > lastActive[p]
			then
				lastActive[p] = os.clock()
				lastPos[p] = rp :: any
			end
			p:SetAttribute("AFK", ToPLogic.isAfk(lastActive[p], os.clock(), "lobby") or nil)
		end
	end
end)

local introSkipped: { [Player]: boolean } = {}
-- PACING FIX (2026-10-14): who has already seen the intro this session, so repeat rounds can be short.
local introSeen: { [Player]: boolean } = {}
IntroSkip.OnServerEvent:Connect(function(p)
	if state == "Intro" then
		introSkipped[p] = true
	end
end)

local wishWinner: Team? = nil
local wishChosen: string? = nil
WishChoice.OnServerEvent:Connect(function(p, wishId)
	if state ~= "Ending" or wishChosen or not wishWinner or p.Team ~= wishWinner then
		return
	end
	if type(wishId) ~= "string" or not Config.WISHES[wishId] then
		return
	end
	wishChosen = wishId
	local w = Config.WISHES[wishId]
	for _, q in wishWinner:GetPlayers() do
		q:SetAttribute("Title", w.title)
		local prof = PlayerData.get(q) :: any
		if prof then
			prof.title = w.title
		end
		if w.aura then
			q:SetAttribute("Aura", w.aura)
			if prof then
				prof.aura = w.aura
			end
		end -- v8: cosmetic only
		if w.zeni then
			PlayerData.addZeni(q, w.zeni)
		end
		Combatant.resetCombat(q) -- republish Power Level with the wish boost
		if w.cosmetic then
			q:SetAttribute("Cosmetic", w.cosmetic)
			if prof then
				prof.cosmetic = w.cosmetic
			end
		end
	end
	if w.serverZeni then
		for _, q in Players:GetPlayers() do
			local prof = PlayerData.get(q) :: any
			local z = ((prof and prof.zeni) or q:GetAttribute("Zeni") or 0) + w.serverZeni
			if prof then
				prof.zeni = z
			end
			q:SetAttribute("Zeni", z)
		end
	end
	WishResult:FireAllClients(wishId, p.Name, wishWinner.Name)
	SuperShenron:FireAllClients({ phase = "Granted", winner = wishWinner.Name, wish = wishId })
	ShenronHook:Fire("Granted", wishWinner, wishId)
end)

local function hookCharacter(p: Player, char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	hum.Died:Connect(function()
		local tag = hum:FindFirstChild("creator") :: ObjectValue?
		local killer = tag and tag.Value
		eliminate(p, if killer and killer:IsA("Player") then killer else nil, "KO")
	end)
end
local function onPlayer(p: Player)
	p.Team = lobby
	p.CharacterAdded:Connect(function(c)
		hookCharacter(p, c)
		if p:GetAttribute("Spectating") and not alive[p] then
			task.defer(Arena.teleport, p, "Stand", TeamAssignment.universeOf(p))
		end
	end)
	if p.Character then
		hookCharacter(p, p.Character)
	end
	if state == "InRound" then
		TeamAssignment.onJoinMidRound(p)
		startSpectate(p)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	onPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	if state == "InRound" then
		eliminate(p, nil, "Leave")
	else
		alive[p] = nil
	end
	giftWindow[p] = nil
	giftUsed[p] = nil
	safePos[p] = nil
	lastActive[p] = nil
	lastPos[p] = nil
end)

PrestigeRemote.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "prestige", 0.2, 1) or state == "InRound" then
		return
	end
	PlayerData.prestige(p)
end)

-- Playtime XP ticker
task.spawn(function()
	while true do
		task.wait(60)
		for _, p in Players:GetPlayers() do
			if p:GetAttribute("DataLoaded") then
				PlayerData.addXP(p, Config.XP_PER_MINUTE)
				PlayerData.addStat(p, "playtime", 60)
			end
		end
	end
end)

local function countdown(name: string, secs: number, abortIf: (() -> boolean)?): boolean
	for t = secs, 1, -1 do
		setState(name, t)
		task.wait(1)
		if abortIf and abortIf() then
			return false
		end
	end
	return true
end

local function enoughPlayers()
	if DEV and workspace:GetAttribute("DevHoldLobby") then
		return false
	end -- dev: freeze in lobby (VFX/art tests)
	if RankedService.isRankedServer() then
		return #Players:GetPlayers() >= RankedService.expectedPlayers()
	end -- v8: full ranked lobby
	return #Players:GetPlayers() >= (if DEV then 1 else Config.MIN_PLAYERS)
end

local function cleanupRound()
	Fusion.resetRound()
	Combat.resetRound()
	Arena.reset() -- db-map: restore destructible ring between rounds
	Arena.clearNPCs() -- v3: Bulma/spectators respawn on next Resize
	Arena.restoreStands() -- db-story: erased stands come back
	table.clear(alive)
	table.clear(giftWindow)
	table.clear(giftUsed)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("Alive", nil)
		p:SetAttribute("Spectating", false)
		p:SetAttribute("SpectateTarget", nil)
		p:SetAttribute("GiftWindow", nil)
		Combatant.resetCombat(p)
		Arena.clearRingOut(p)
		Arena.teleport(p, "Lobby")
	end
	DevBots.clear()
	SpiritBomb.resetRound()
	if eventBoss then
		BossNPC.despawn(eventBoss)
		eventBoss = nil
	end
	table.clear(startSize)
	table.clear(erased)
	table.clear(erasedAt)
	table.clear(safePos)
	workspace:SetAttribute("ShowClock", nil)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("LastStand", nil)
	end
	TeamAssignment.clear()
end

Arena.reset()
while true do
	if not enoughPlayers() then
		setState("Waiting", 0)
		repeat
			task.wait(1)
		until enoughPlayers()
	end
	if
		not countdown("Intermission", if DEV then 5 else Config.INTERMISSION, function()
			return not enoughPlayers()
		end)
	then
		continue
	end

	local roster = {}
	for _, p in Players:GetPlayers() do
		if #roster >= Config.MAX_PLAYERS then
			break
		end
		-- v8: players inside a raid / story instance sit this round out
		-- §10.1: idle 90 s in the lobby -> not queued this round
		-- FTUE: a first-timer still in the Whis tutorial sits the round out too, otherwise the round start
		-- teleports them off Whis Ground and the onboarding is lost.
		if
			p:GetAttribute("DataLoaded")
			and p.Character
			and p:GetAttribute("InRaid") ~= true
			and p:GetAttribute("InTutorial") ~= true
			and not ToPLogic.isAfk(lastActive[p] or os.clock(), os.clock(), "lobby")
		then
			table.insert(roster, p)
		end
	end
	local solo = DEV and #roster == 1
	local minPlayers = if DEV then 1 else Config.MIN_PLAYERS
	-- DEADLOCK FIX (2026-10-14): excluding InTutorial players can empty the roster entirely - a fresh server where
	-- everyone is onboarding, or a solo Studio run with the ForceTutorial dev flag set. The loop then spun in
	-- Intermission forever and NO match ever started (confirmed live: 150 s of polling never left Intermission).
	-- If the tutorial-free roster is too small to start, fall back to including first-timers: a briefly interrupted
	-- tutorial is far better than a server that never plays a round.
	if #roster < minPlayers then
		for _, p in ipairs(Players:GetPlayers()) do
			if #roster >= Config.MAX_PLAYERS then
				break
			end
			if
				p:GetAttribute("DataLoaded")
				and p.Character
				and p:GetAttribute("InRaid") ~= true
				and not table.find(roster, p)
				and not ToPLogic.isAfk(lastActive[p] or os.clock(), os.clock(), "lobby")
			then
				table.insert(roster, p)
			end
		end
	end
	solo = DEV and #roster == 1
	if #roster < minPlayers then
		continue
	end

	local universes = if solo
		then TeamAssignment.assignDev(roster)
		else TeamAssignment.assign(
			if RankedService.isRankedServer() then RankedService.groups(roster) else Party.groupsFor(roster),
			Combatant.balancePower
		)
	table.clear(roundKOs)
	table.clear(alive)
	table.clear(placements)
	table.clear(giftUsed)
	for _, p in roster do
		alive[p] = true
		p:SetAttribute("Alive", true)
		p:SetAttribute("Spectating", false)
		Combatant.resetCombat(p)
		Combatant.ensureValidPick(p)
	end
	-- D19: 2-3 humans -> bots up to 4 fighters (not Ranked, not the DEV solo path)
	local fill: { number } = {}
	if not solo then
		local sizes = {}
		for i, t in universes do
			sizes[i] = #t:GetPlayers()
		end
		fill = ToPLogic.botFill(sizes, RankedService.isRankedServer())
	end
	local fillN = 0
	for _, n in fill do
		fillN += n
	end
	-- db-map: resize the arena for this match (pcall, no-op if missing), then refresh refs
	Arena.resize(#universes, #roster + fillN + (if solo then Config.DEV_BOTS else 0), universes)
	countdown("CharacterSelect", Config.CHARACTER_SELECT)
	local slotOf: { [Team]: number } = {}
	for _, p in roster do
		if alive[p] then
			Combatant.ensureValidPick(p)
			local t = p.Team :: Team
			slotOf[t] = (slotOf[t] or 0) + 1
			Arena.teleport(p, "Arena", TeamAssignment.universeOf(p), nil, slotOf[t])
		end
	end
	if solo then
		local sp = Arena.spawnFor("Arena", universes[2] and universes[2]:GetAttribute("Universe") :: number?)
			or Arena.spawnFor("Arena")
		if sp then
			DevBots.spawn(Config.DEV_BOTS, universes[2], sp.CFrame)
		end
	elseif fillN > 0 then
		DevBots.clear()
		for i, n in fill do
			local sp = Arena.spawnFor("Arena", universes[i]:GetAttribute("Universe") :: number?)
				or Arena.spawnFor("Arena")
			if n > 0 and sp then
				DevBots.spawn(n, universes[i], sp.CFrame, true)
			end
		end
	end
	-- Intro cutscene (clients play StoryDialogue.Intro; ends when enough players skipped, or the cap)
	-- PACING FIX (2026-10-14): this was a flat 110 s that replayed EVERY round and only broke early once *every*
	-- player had skipped. Two consequences: a first session could burn 2-3 minutes before its first fight, and on
	-- a populated server a single AFK player forced everyone to wait the whole 110 s. Now:
	--   * the long intro only plays while somebody in the roster has not seen it this session, otherwise
	--     INTRO_MAX_REPEAT,
	--   * the early-out needs a MAJORITY of present players to skip, not unanimity.
	local introCap = Config.INTRO_MAX
	local anyFirstTimer = false
	for _, p in roster do
		if p.Parent and not introSeen[p] then
			anyFirstTimer = true
			break
		end
	end
	if not anyFirstTimer then
		introCap = Config.INTRO_MAX_REPEAT
	end
	table.clear(introSkipped)
	local introT0 = os.clock()
	setState("Intro", introCap)
	while os.clock() - introT0 < introCap do
		local present, skipped = 0, 0
		for _, p in roster do
			if p.Parent then
				present += 1
				if introSkipped[p] then
					skipped += 1
				end
			end
		end
		-- Nobody left to wait for, or a majority has skipped.
		if present == 0 or skipped * 2 >= present then
			break
		end
		workspace:SetAttribute("TimeLeft", math.ceil(introCap - (os.clock() - introT0)))
		task.wait(0.25)
	end
	for _, p in roster do
		if p.Parent then
			introSeen[p] = true
		end
	end
	if solo then
		local sp = Arena.spawnFor("Arena", universes[2] and universes[2]:GetAttribute("Universe") :: number?)
			or Arena.spawnFor("Arena")
		if sp then
			DevBots.placeAll(sp.CFrame)
		end
		for _, p in roster do
			Arena.teleport(p, "Arena", TeamAssignment.universeOf(p))
		end
	end
	countdown("Countdown", Config.COUNTDOWN)
	table.clear(startSize)
	table.clear(erased)
	for _, t in universes do
		startSize[t] = aliveOn(t)
	end
	RoundStarted:Fire(universes)

	local t0 = os.clock()
	for _, p in roster do
		touchActive(p)
	end -- AFK clock starts at BEGIN
	setState("InRound", Config.ROUND_MAX)
	checkWipes() -- a universe with 1 fighter from the start never gets Last Stand (startSize < 2)
	local eventAt, eventDone = ToPLogic.eventTime(Config.ROUND_MAX), false
	while #aliveTeams() > 1 and os.clock() - t0 < Config.ROUND_MAX do
		local elapsed = os.clock() - t0
		workspace:SetAttribute("ShowClock", ToPLogic.showRemaining(elapsed, Config.ROUND_MAX)) -- 48:00 show timer (HUD)
		for p in alive do
			if not Fusion.isPassenger(p) then
				local why = Arena.checkRingOut(p)
				-- v8: ring-out credit to the last enemy who hit them (6 s), so KO XP / ringout quests count
				if why then
					eliminate(p, Combat.lastAttacker(p, 6), why)
				elseif ToPLogic.isAfk(lastActive[p] or os.clock(), os.clock(), "fight") then
					eliminate(p, nil, "AFK") -- §10.1: 30 s idle in the fight -> out to spectate (no gift)
				else
					local rp = rootPos(p)
					if rp then
						safePos[p] = rp
					end
				end
			end
		end
		if not eventDone and elapsed >= eventAt - 5 then -- v8 Universe Survival event (server-side trigger)
			eventDone = true
			local n = 0
			for _ in alive do
				n += 1
			end
			if ToPLogic.eventShould(n, #aliveTeams(), DEV) then
				SurvivalEvent:FireAllClients({ phase = "Warn", name = "Jiren", seconds = 5 })
				SurvivalHook:Fire("Warn", nil)
				task.delay(5, function()
					if state ~= "InRound" or eventBoss then
						return
					end
					local sp = Arena.spawnFor("Arena")
					local hp, dmg = ToPLogic.eventScale(n)
					local fighters = {}
					for q in alive do
						table.insert(fighters, q)
					end
					-- db-story: model is named exactly "Jiren" and parented under WorldOfVoid BEFORE "Enter" fires (ToPCinematics/CutsceneDirector.findBoss)
					local def = {
						id = "top_survival",
						name = "Jiren",
						animId = "u11_jiren",
						topEvent = true,
						hp = hp,
						walkSpeed = 18,
						scale = 1.3,
						color = Color3.fromRGB(200, 40, 40),
						phases = { 0.5 },
						phaseMods = { { dmg = 1, speed = 1, cdMult = 1 }, { dmg = 1.2, speed = 1.15, cdMult = 0.8 } },
						melee = { damage = 14, range = 8, cd = 1.5, kb = 90 },
						specials = {
							Stomp = {
								cd = 8,
								windup = 0.9,
								radius = 16,
								damage = 16,
								arenaRadius = 16,
								arenaPower = 90,
							},
						},
					}
					local at = (if sp then sp.CFrame else CFrame.new(0, 110, 0)) * CFrame.new(0, 6, 0)
					local arenaParent = workspace:FindFirstChild("WorldOfVoid") or workspace
					eventBoss = BossNPC.spawn(def, at, arenaParent, fighters, {
						hpMult = 1,
						dmgMult = dmg,
						onDefeated = function(b)
							local best, bestD = nil, 0
							for q, d in b.dmgBy do
								if d > bestD and q.Parent then
									best, bestD = q, d
								end
							end
							if best and best.Team then
								for _, q in best.Team:GetPlayers() do
									PlayerData.addZeni(q, ToPLogic.EVENT.winnerZeni)
									PlayerData.addXP(q, ToPLogic.EVENT.winnerXp)
								end
							end
							SurvivalEvent:FireAllClients({
								phase = "Defeated",
								name = "Jiren",
								by = best and best.Name,
								team = best and best.Team and best.Team.Name,
							})
							SurvivalHook:Fire("Defeated", b.model)
							eventBoss = nil
						end,
					})
					SurvivalEvent:FireAllClients({ phase = "Enter", name = "Jiren", hp = hp })
					SurvivalHook:Fire("Enter", eventBoss.model)
				end)
			end
		end
		Fusion.tick()
		DevBots.tick(true)
		workspace:SetAttribute("TimeLeft", math.max(0, Config.ROUND_MAX - math.floor(os.clock() - t0)))
		task.wait(0.1)
	end

	-- v9 win detection (D17, tested): last universe standing; at time-up most survivors, then HP%, else draw.
	-- Simultaneous last wipes (0 teams left, erased within the same 0.15 s) -> draw between them.
	local stats, byName = {}, {}
	for _, t in TeamAssignment.getUniverses() do
		local n, hp = DevBots.aliveOn(t), DevBots.hpOn(t)
		for p in alive do
			if p.Team == t and not Fusion.isPassenger(p) then
				n += 1
				local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if h and h.MaxHealth > 0 then
					hp += math.max(0, h.Health) / h.MaxHealth
				end
			end
		end
		stats[t.Name] = { n = n, hp = hp }
		byName[t.Name] = t
	end
	local wName, tied = ToPLogic.resolveTimeout(stats)
	if #tied == 0 then -- nobody left: draw between the last same-tick wipes
		local last = 0
		for _, at in erasedAt do
			last = math.max(last, at)
		end
		for t, at in erasedAt do
			if last - at <= 0.15 then
				table.insert(tied, t.Name)
			end
		end
	end
	local winner: Team? = if wName then byName[wName] else nil
	if not winner then
		for _, name in tied do
			local t = byName[name]
			if t then
				for _, p in t:GetPlayers() do
					PlayerData.addXP(p, math.floor(Config.XP_WIN * ToPLogic.DRAW_XP_MULT))
				end
			end
		end
	end

	for _, p in roster do -- participation XP for everyone who finished the match
		if p.Parent then
			PlayerData.addXP(p, Config.XP_PARTICIPATION)
			QuestService.track(p, "match", 1)
		end
	end
	for rank, team in placements do
		for _, p in team:GetPlayers() do
			PlayerData.addXP(p, Config.XP_SURVIVAL_PER_RANK * rank)
		end
	end
	if winner then
		for _, p in winner:GetPlayers() do
			PlayerData.addXP(p, Config.XP_WIN)
			PlayerData.addStat(p, "wins", 1)
			QuestService.track(p, "win", 1)
		end
	end
	workspace:SetAttribute("ShowClock", 0)
	if eventBoss then
		BossNPC.despawn(eventBoss)
		eventBoss = nil
		SurvivalEvent:FireAllClients({ phase = "End" })
	end
	RoundEnded:Fire(winner)
	-- Ending cutscene + Super Dragon Ball wish (only when a universe with real players won)
	wishWinner, wishChosen = nil, nil
	if winner and #winner:GetPlayers() > 0 then
		wishWinner = winner
		local e0 = os.clock()
		setState("Ending", Config.ENDING_MAX, winner.Name)
		SuperShenron:FireAllClients({ phase = "Summon", winner = winner.Name }) -- v8 ending cinematic hook
		ShenronHook:Fire("Summon", winner, nil)
		while os.clock() - e0 < Config.ENDING_MAX and not wishChosen do
			task.wait(0.25)
		end
		if wishChosen then
			task.wait(5)
		end -- let the granted-wish lines play
	end
	local kos = {}
	for name, n in roundKOs do
		table.insert(kos, { name = name, kos = n })
	end
	local summary = {
		winner = winner and winner.Name or "Draw",
		wish = wishChosen,
		kos = kos,
		duration = math.floor(os.clock() - t0),
	}
	state = "Results"
	setState("Results", Config.RESULTS, summary)
	task.wait(Config.RESULTS)
	cleanupRound()
end
