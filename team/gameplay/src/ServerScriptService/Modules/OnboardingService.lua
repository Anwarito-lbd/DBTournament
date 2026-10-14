--!strict
-- ModuleScript: ServerScriptService.Modules.OnboardingService (WP11)
-- 60-second Whis onboarding tutorial for first-time players.
-- Handles WhisGround teleport, stage progression, sparring dummy spawn, and reward grants.
local Players = game:GetService("Players")

local Modules = script.Parent
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Net = require(Modules:WaitForChild("Net"))

local OnboardingService = {}

local actionRemote = Net.remote("OnboardingAction")
local eventRemote = Net.remote("OnboardingEvent")

local WHIS_GROUND_CFRAME = CFrame.new(9000, 102.5, 3060)
local DUMMY_SPAWN_CFRAME = CFrame.new(9000, 102.5, 3035)
local LOBBY_CFRAME = CFrame.new(0, 5, 0)

type Session = {
	player: Player,
	step: number,
	dummy: Model?,
	active: boolean,
}

local activeSessions: { [Player]: Session } = {}

local function getCharRoot(p: Player): BasePart?
	local char = p.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function cleanDummy(session: Session)
	if session.dummy and session.dummy.Parent then
		session.dummy:Destroy()
	end
	session.dummy = nil
end

local function spawnDummy(session: Session): Model
	cleanDummy(session)
	local model = Instance.new("Model")
	model.Name = "Whis Training Dummy"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CFrame = DUMMY_SPAWN_CFRAME
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 3, 1)
	torso.Color = Color3.fromRGB(180, 120, 60)
	torso.Material = Enum.Material.Wood
	torso.CanCollide = true
	torso.CFrame = DUMMY_SPAWN_CFRAME
	torso.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = torso
	weld.Parent = root

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = Color3.fromRGB(210, 160, 90)
	head.Material = Enum.Material.Wood
	head.CanCollide = true
	head.CFrame = DUMMY_SPAWN_CFRAME * CFrame.new(0, 2, 0)
	head.Parent = model

	local hw = Instance.new("WeldConstraint")
	hw.Part0 = torso
	hw.Part1 = head
	hw.Parent = torso

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 50
	hum.Health = 50
	hum.WalkSpeed = 8
	hum.DisplayName = "Training Dummy"
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("IsBot", true)
	model:SetAttribute("Alive", true)
	model:SetAttribute("Team", "TrainingDummyTeam")

	local folder = workspace:FindFirstChild("DevBots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DevBots"
		folder.Parent = workspace
	end
	model.Parent = folder

	-- When dummy takes lethal hit, notify player session
	hum.Died:Connect(function()
		model:SetAttribute("Alive", false)
		if session.active and session.step == 6 then
			OnboardingService.finish(session.player)
		end
		task.delay(2, function()
			if model.Parent then
				model:Destroy()
			end
		end)
	end)

	session.dummy = model
	return model
end

function OnboardingService.start(p: Player)
	if activeSessions[p] then
		return
	end
	local root = getCharRoot(p)
	if root then
		root.CFrame = WHIS_GROUND_CFRAME
	end

	local session: Session = {
		player = p,
		step = 1,
		dummy = nil,
		active = true,
	}
	activeSessions[p] = session

	p:SetAttribute("InTutorial", true)
	eventRemote:FireClient(p, "Start", { step = 1, totalSteps = 6 })
end

function OnboardingService.finish(p: Player)
	local session = activeSessions[p]
	if not session or not session.active then
		return
	end
	session.active = false
	cleanDummy(session)
	activeSessions[p] = nil

	p:SetAttribute("InTutorial", false)
	PlayerData.completeTutorial(p)

	local root = getCharRoot(p)
	if root then
		root.CFrame = LOBBY_CFRAME
	end

	eventRemote:FireClient(p, "Complete", {
		xp = 250,
		zeni = 1000,
		boostMinutes = 30,
	})
end

function OnboardingService.skip(p: Player)
	local session = activeSessions[p]
	if session then
		session.active = false
		cleanDummy(session)
		activeSessions[p] = nil
	end
	p:SetAttribute("InTutorial", false)
	PlayerData.completeTutorial(p)

	local root = getCharRoot(p)
	if root then
		root.CFrame = LOBBY_CFRAME
	end

	eventRemote:FireClient(p, "Skipped", {})
end

function OnboardingService.advanceStep(p: Player, step: number)
	local session = activeSessions[p]
	if not session or not session.active then
		return
	end
	session.step = step

	if step == 6 then
		spawnDummy(session)
	end

	eventRemote:FireClient(p, "StepUpdate", { step = step })
end

-- Client Action Remote Handler
actionRemote.OnServerEvent:Connect(function(p, action, arg1)
	if action == "Progress" and typeof(arg1) == "number" then
		OnboardingService.advanceStep(p, arg1)
	elseif action == "Skip" then
		OnboardingService.skip(p)
	elseif action == "Start" then
		OnboardingService.start(p)
	end
end)

-- ============================================================================
-- SCHEDULING (FTUE FIX 2026-10-14)
-- The old gate ran the tutorial only when RoundState was "Lobby" | "Waiting" | nil, checked ONCE 1.5 s after
-- spawn. "Lobby" is not a real RoundState (RoundManager uses Waiting/Intermission/CharacterSelect/Countdown/
-- InRound/Results), and Waiting only exists at server boot - so in practice a first-time player almost never
-- got the tutorial, which is the entire first-5-minutes experience. Now eligibility is remembered and the
-- tutorial starts at the first moment it is safe, and RoundManager's roster skips InTutorial players.
-- ============================================================================
local pending: { [Player]: boolean } = {}

-- Only the genuinely quiet states. CharacterSelect / Countdown / Intro / Ending each draw their own
-- full-screen UI, and the tutorial card + Whis card were rendering on top of the character grid
-- (confirmed in a live screenshot: "STEP 1: MOVEMENT" sat over Goku/Vegeta/Piccolo). InRound is excluded
-- because the player may be a live fighter.
local TUTORIAL_STATES: { [string]: boolean } = { Waiting = true, Intermission = true }

local function stateAllowsTutorial(): boolean
	local s = workspace:GetAttribute("RoundState")
	if s == nil then
		return true
	end
	return TUTORIAL_STATES[s] == true
end

-- During a live round only a spectator (or a non-fighter) can be pulled out to Whis Ground.
local function tutorialSafe(p: Player): boolean
	if stateAllowsTutorial() then
		return true
	end
	return p:GetAttribute("Spectating") == true or p:GetAttribute("Alive") ~= true
end

local function isFirstTimer(p: Player): boolean
	return not PlayerData.isTutorialDone(p) and ((p:GetAttribute("Level") or 1) <= 1)
end

local function tryStart(p: Player)
	if not p.Parent or activeSessions[p] then
		return
	end
	local force = workspace:GetAttribute("ForceTutorial") == true
	if not (isFirstTimer(p) or force) then
		pending[p] = nil
		return
	end
	if not tutorialSafe(p) then
		pending[p] = true
		return
	end
	pending[p] = nil
	OnboardingService.start(p)
end

-- Player Lifecycle
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(1.5)
		tryStart(p)
	end)
	if p.Character then
		task.spawn(function()
			task.wait(1.5)
			tryStart(p)
		end)
	end
end)

-- Flush the queue whenever the round state changes: a queued first-timer starts as soon as the round ends,
-- and a live tutorial is paused and re-queued if its player somehow stops being safe.
workspace:GetAttributeChangedSignal("RoundState"):Connect(function()
	for p in pairs(pending) do
		tryStart(p)
	end
	for p, session in pairs(activeSessions) do
		if session.active and not tutorialSafe(p) then
			session.active = false
			cleanDummy(session)
			activeSessions[p] = nil
			p:SetAttribute("InTutorial", false)
			eventRemote:FireClient(p, "Skipped", {})
			pending[p] = true
		end
	end
end)

-- Spectating flips on when a player joins mid-round; that is the moment a queued tutorial becomes safe.
Players.PlayerAdded:Connect(function(p)
	p:GetAttributeChangedSignal("Spectating"):Connect(function()
		if pending[p] then
			tryStart(p)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	local session = activeSessions[p]
	if session then
		session.active = false
		cleanDummy(session)
		activeSessions[p] = nil
	end
	pending[p] = nil
end)

-- Dev Hook for Studio testing
workspace:GetAttributeChangedSignal("ForceTutorial"):Connect(function()
	if workspace:GetAttribute("ForceTutorial") then
		for _, p in Players:GetPlayers() do
			OnboardingService.start(p)
		end
	end
end)

function OnboardingService.init()
	-- Initialized
end

return OnboardingService
