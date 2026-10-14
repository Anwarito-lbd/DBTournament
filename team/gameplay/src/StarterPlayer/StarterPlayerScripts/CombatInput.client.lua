--!strict
-- LocalScript: StarterPlayerScripts.CombatInput
-- AAA Anime Combat Engine (TSB / Jujutsu Shenanigans / DBZ standard):
-- 1) Smart Magnetic Auto-Aim: 65-degree forward cone scan for players and sparring bots (Goku, Vegeta, dev bots).
--    Aligns character and homes Ki Blasts, Kamehamehas, and punches directly at the enemy torso.
-- 2) Melee Forward Magnetism & Lunge: 22-stud sticky tracking that lunges the character into striking range.
-- 3) 4-Hit M1 Combo Chain:
--    Hit 1: Left Jab (M1_1 pose + light punch SFX)
--    Hit 2: Right Cross (M1_2 pose + light punch SFX)
--    Hit 3: Body Hook (M1_3 pose + medium punch SFX)
--    Hit 4: Finisher Launcher Kick (M1_4 pose + heavy finisher SFX + camera punch)
-- 4) Sleek Anime Target Reticle HUD: Dynamic tracking brackets [  ] with live enemy name, form, and HP meter.
-- 5) Hard-Lock Toggle: [C], [L], [Tab], or [MiddleClick] locks camera tracking onto the opponent.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local Config = require(Shared:WaitForChild("Config"))
local AudioRegistry = require(Shared:WaitForChild("AudioRegistry"))
local AnimMarkerRouter = require(Shared:WaitForChild("AnimMarkerRouter"))

local PosesFolder = ReplicatedStorage:WaitForChild("Poses", 10)
local PosePlayer = PosesFolder and require(PosesFolder:WaitForChild("PosePlayer"))
-- Each hero owns a clip set; Shared.clips covers the rest of the roster.
local GokuPoses = PosesFolder and require(PosesFolder:WaitForChild("Goku"))
local VegetaPoses = PosesFolder and require(PosesFolder:WaitForChild("Vegeta"))
local FriezaPoses = PosesFolder and require(PosesFolder:WaitForChild("Frieza"))
local SharedPoses = PosesFolder and require(PosesFolder:WaitForChild("Shared"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local function getChar(): Model?
	return player.Character
end

local function getRoot(): BasePart?
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getHum(): Humanoid?
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- ========================================================
-- CHAMPION-AWARE CLIP RESOLUTION
-- Every move used to play GokuPoses.*, so a Vegeta or Frieza player animated as Goku and the
-- authored Vegeta clips (GalickGun_*, FinalFlash_*, BigBangAttack, FinalExplosion) and Frieza
-- clips (DeathBeam_*, DeathBall_*, DestructoDisc, NovaStrike, BlackNova) were unreachable.
-- ========================================================
local function clipOf(mod: any, name: string): any
	if not mod then
		return nil
	end
	return mod[name] or (mod.clips and mod.clips[name])
end

local function championId(): string?
	local ch = getChar()
	local id = player:GetAttribute("Character")
	if type(id) ~= "string" and ch then
		id = ch:GetAttribute("ChampionModel")
	end
	if type(id) == "string" and id ~= "" then
		return id
	end
	return nil
end

local function posesFor(id: string?): any
	if id then
		if string.find(id, "vegeta") then
			return VegetaPoses
		end
		if string.find(id, "frieza") or string.find(id, "frost") then
			return FriezaPoses
		end
		if string.find(id, "goku") then
			return GokuPoses
		end
	end
	return SharedPoses or GokuPoses
end

local function clipFor(name: string): any
	return clipOf(posesFor(championId()), name)
end

local function championKey(): string
	local id = championId()
	if id then
		if string.find(id, "vegeta") then
			return "vegeta"
		end
		if string.find(id, "frieza") or string.find(id, "frost") then
			return "frieza"
		end
		if string.find(id, "goku") then
			return "goku"
		end
	end
	return "shared"
end

-- Signature beam per champion. The move KIND stays "Kamehameha" so VFXRouter's per-champion module
-- switch still applies; only the CLIP differs (Vegeta fires a Galick Gun, Frieza a Death Beam).
local SIGNATURE: { [string]: { charge: string, fire: string, move: string } } = {
	goku = { charge = "Kamehameha_Charge", fire = "Kamehameha_Fire", move = "Kamehameha" },
	vegeta = { charge = "GalickGun_Charge", fire = "GalickGun_Fire", move = "Kamehameha" },
	frieza = { charge = "DeathBeam_Charge", fire = "DeathBeam_Fire", move = "Kamehameha" },
	shared = { charge = "KiVolley", fire = "KiVolley", move = "Kamehameha" },
}

local function isAirborne(): boolean
	local hum = getHum()
	return hum ~= nil and hum.FloorMaterial == Enum.Material.Air
end

-- ========================================================
-- SMART TARGET ACQUISITION & AUTO-AIM
-- ========================================================
local hardTarget: Model? = nil
local softTarget: Model? = nil

local function getCandidates(): { Model }
	local list = {}
	local myChar = getChar()

	-- 1. Other players
	for _, q in ipairs(Players:GetPlayers()) do
		if q ~= player and q.Character and q.Character ~= myChar then
			local qh = q.Character:FindFirstChildOfClass("Humanoid")
			local qr = q.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if qh and qh.Health > 0 and qr and q:GetAttribute("Alive") ~= false then
				table.insert(list, q.Character)
			end
		end
	end

	-- 2. Sparring Bots & NPCs (Goku, Vegeta, dev bots, training bots)
	local trainingBots = CollectionService:GetTagged("TrainingBot")
	for _, m in ipairs(trainingBots) do
		if m:IsA("Model") and m ~= myChar then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and hum.Health > 0 and hrp and m:GetAttribute("Alive") ~= false then
				table.insert(list, m)
			end
		end
	end

	for _, d in ipairs(workspace:GetDescendants()) do
		if
			d:IsA("Model")
			and d ~= myChar
			and (
				d:GetAttribute("IsBot") == true
				or d:GetAttribute("TrainingArea") ~= nil
				or d.Name:find("Goku")
				or d.Name:find("Vegeta")
			)
		then
			local hum = d:FindFirstChildOfClass("Humanoid")
			local hrp = d:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and hum.Health > 0 and hrp and d:GetAttribute("Alive") ~= false and not table.find(list, d) then
				table.insert(list, d)
			end
		end
	end

	return list
end

local function scanSmartTarget(maxDist: number, minDot: number): (Model?, Vector3?)
	local myRoot = getRoot()
	if not myRoot then
		return nil, nil
	end

	-- If hard target is valid, stick with it
	if hardTarget and hardTarget.Parent then
		local hr = hardTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hh = hardTarget:FindFirstChildOfClass("Humanoid")
		if hr and hh and hh.Health > 0 and (hr.Position - myRoot.Position).Magnitude <= 160 then
			return hardTarget, hr.Position + Vector3.new(0, 0.4, 0)
		else
			hardTarget = nil
		end
	end

	local camCF = camera.CFrame
	local camPos = camCF.Position
	local camLook = camCF.LookVector

	local bestTarget: Model? = nil
	local bestPos: Vector3? = nil
	local bestScore = math.huge

	for _, m in ipairs(getCandidates()) do
		local tr = m:FindFirstChild("HumanoidRootPart") :: BasePart?
		if tr then
			local tPos = tr.Position + Vector3.new(0, 0.4, 0)
			local toTarget = tPos - myRoot.Position
			local dist = toTarget.Magnitude

			if dist <= maxDist then
				local dirFromCam = (tPos - camPos).Unit
				local dot = camLook:Dot(dirFromCam)

				if dot >= minDot then
					local score = (1.0 - dot) * 90 + (dist / maxDist) * 30
					if score < bestScore then
						bestScore = score
						bestTarget = m
						bestPos = tPos
					end
				end
			end
		end
	end

	return bestTarget, bestPos
end

local function getAimPosition(isMelee: boolean): Vector3
	local target, pos = scanSmartTarget(if isMelee then 26 else 140, if isMelee then 0.3 else 0.45)
	if target and pos then
		return pos
	end

	-- Center screen raycast fallback
	local ray = camera:ViewportPointToRay(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local res = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
	if res then
		return res.Position
	end

	local myRoot = getRoot()
	local origin = if myRoot then myRoot.Position else ray.Origin
	return origin + camera.CFrame.LookVector * 150
end

-- ========================================================
-- SLEEK ANIME HUD TARGET RETICLE
-- ========================================================
local reticleGui = Instance.new("ScreenGui")
reticleGui.Name = "AnimeCombatReticle"
reticleGui.ResetOnSpawn = false
reticleGui.IgnoreGuiInset = true
reticleGui.DisplayOrder = 45
reticleGui.Parent = player:WaitForChild("PlayerGui")

local reticleFrame = Instance.new("Frame")
reticleFrame.Name = "ReticleBox"
reticleFrame.Size = UDim2.fromOffset(80, 80)
reticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
reticleFrame.BackgroundTransparency = 1
reticleFrame.Visible = false
reticleFrame.Parent = reticleGui

local leftBracket = Instance.new("TextLabel")
leftBracket.Size = UDim2.fromScale(0.3, 1)
leftBracket.Position = UDim2.fromScale(0, 0)
leftBracket.BackgroundTransparency = 1
leftBracket.Text = "["
leftBracket.TextColor3 = Color3.fromRGB(100, 220, 255)
leftBracket.TextScaled = true
leftBracket.Font = Enum.Font.GothamBold
leftBracket.Parent = reticleFrame

local rightBracket = leftBracket:Clone()
rightBracket.Position = UDim2.fromScale(0.7, 0)
rightBracket.Text = "]"
rightBracket.Parent = reticleFrame

local nameTag = Instance.new("TextLabel")
nameTag.Name = "TargetName"
nameTag.Size = UDim2.fromOffset(240, 22)
nameTag.Position = UDim2.new(0.5, -120, 0, -28)
nameTag.BackgroundTransparency = 1
nameTag.Font = Enum.Font.GothamBlack
nameTag.TextSize = 14
nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
nameTag.TextStrokeTransparency = 0
nameTag.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
nameTag.Text = "SON GOKU"
nameTag.Parent = reticleFrame

local hpBg = Instance.new("Frame")
hpBg.Name = "HpBg"
hpBg.Size = UDim2.fromOffset(110, 6)
hpBg.Position = UDim2.new(0.5, -55, 0, -6)
hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
hpBg.BorderSizePixel = 0
hpBg.Parent = reticleFrame
local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 3)
bgCorner.Parent = hpBg

local hpFill = Instance.new("Frame")
hpFill.Name = "HpFill"
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 110)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBg
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 3)
fillCorner.Parent = hpFill

local distTag = Instance.new("TextLabel")
distTag.Name = "DistTag"
distTag.Size = UDim2.fromOffset(180, 18)
distTag.Position = UDim2.new(0.5, -90, 1, 8)
distTag.BackgroundTransparency = 1
distTag.Font = Enum.Font.GothamBold
distTag.TextSize = 12
distTag.TextColor3 = Color3.fromRGB(180, 230, 255)
distTag.TextStrokeTransparency = 0
distTag.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
distTag.Text = "14 STUDS  [LOCKED]"
distTag.Parent = reticleFrame

-- ========================================================
-- TARGET LOCK TOGGLE & CAMERA TRACKING
-- ========================================================
local function toggleLock()
	if hardTarget then
		hardTarget = nil
		player:SetAttribute("LockTargetId", nil)
		player:SetAttribute("LockTargetName", nil)
	else
		local best, _ = scanSmartTarget(120, 0.4)
		if best then
			hardTarget = best
			local q = Players:GetPlayerFromCharacter(best)
			player:SetAttribute("LockTargetId", if q then q.UserId else nil)
			player:SetAttribute("LockTargetName", best:GetFullName())
			AudioRegistry.play("Vanish", getChar(), 0.5)
		end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local target, pos = scanSmartTarget(140, 0.4)
	softTarget = target

	local active = hardTarget or softTarget
	if active and active.Parent and pos then
		local myRoot = getRoot()
		local scrPos, onScreen = camera:WorldToViewportPoint(pos)

		if onScreen and myRoot then
			reticleFrame.Visible = true
			reticleFrame.Position = UDim2.fromOffset(scrPos.X, scrPos.Y)

			local isHard = (active == hardTarget)
			local col = if isHard then Color3.fromRGB(255, 175, 45) else Color3.fromRGB(110, 225, 255)
			leftBracket.TextColor3 = col
			rightBracket.TextColor3 = col
			distTag.TextColor3 = col

			local hum = active:FindFirstChildOfClass("Humanoid")
			if hum then
				local hpPct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
				hpFill.Size = UDim2.fromScale(hpPct, 1)
				hpFill.BackgroundColor3 = if hpPct > 0.5
					then Color3.fromRGB(60, 220, 110)
					elseif hpPct > 0.25 then Color3.fromRGB(255, 200, 50)
					else Color3.fromRGB(255, 60, 60)
			end

			local dist = math.floor((pos - myRoot.Position).Magnitude)
			local partnerKey = active:GetAttribute("PartnerKey") or active.Name
			local form = active:GetAttribute("Form") or "Base"
			nameTag.Text = string.upper(tostring(partnerKey))
				.. (if form ~= "Base" then " • " .. string.upper(form) else "")
			distTag.Text = string.format("%d STUDS  %s", dist, if isHard then "[LOCKED]" else "[AIM ASSIST]")
		else
			reticleFrame.Visible = false
		end

		-- Hard-lock camera framing
		if hardTarget and myRoot then
			local tr = hardTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
			if tr then
				local focus = (myRoot.Position + tr.Position) * 0.5
				local back = (myRoot.Position - tr.Position)
				back = Vector3.new(back.X, 0, back.Z)
				if back.Magnitude > 0.1 then
					local want = CFrame.lookAt(myRoot.Position + back.Unit * 13 + Vector3.new(0, 5.5, 0), focus)
					camera.CFrame = camera.CFrame:Lerp(want, math.min(1, dt * 8))
				end
			end
		end
	else
		reticleFrame.Visible = false
	end
end)

-- ========================================================
-- 4-HIT M1 COMBO CHAIN & MELEE MAGNETISM
-- ========================================================
local comboStep = 1
local lastM1Time = 0
local activePoseHandle = nil

-- Plays a clip by NAME (so the correct champion's clips are used) and routes that clip's
-- vfx/sound markers through AnimMarkerRouter. Without opts.Registry/OnMarker, PosePlayer drops
-- every marker, which is what made the strikes silent and effect-free.
local function playPose(name: string, speed: number)
	if not PosePlayer then
		return
	end
	local ch = getChar()
	local clip = clipFor(name)
	if not ch or not clip then
		return
	end
	if activePoseHandle and activePoseHandle.Stop then
		activePoseHandle:Stop(0.08)
	end
	AnimMarkerRouter.bind(ch)
	activePoseHandle = PosePlayer.Play(ch, clip, AnimMarkerRouter.opts({ Speed = speed or 1.25, Name = name }))
end

local function executeM1()
	local now = os.clock()
	if now - lastM1Time > 1.25 then
		comboStep = 1
	end
	lastM1Time = now

	local aimPos = getAimPosition(true)
	local myRoot = getRoot()

	-- Melee Magnetism: snap face & forward lunge towards target
	if myRoot then
		local toTarget = aimPos - myRoot.Position
		local flatDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude

		if flatDist <= 24 then
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))
			if flatDist > 3.2 then
				local lungeDir = (Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z) - myRoot.Position).Unit
				myRoot.AssemblyLinearVelocity = lungeDir * 32 + Vector3.new(0, 3, 0)
			end
		else
			myRoot.AssemblyLinearVelocity = myRoot.CFrame.LookVector * 18 + Vector3.new(0, 3, 0)
		end
	end

	-- Animation per combo step. The clips now carry their own contact-frame feedback (swing whoosh, hit
	-- SFX, afterimage smear, hitstop, impact frame, camera shake, FOV), so the manual duplicates that used
	-- to sit here are gone - they would double every hit sound and camera kick. Airborne uses the air combo.
	if isAirborne() then
		playPose("AirCombo", 1.15)
	elseif comboStep == 1 then
		playPose("M1_1", 1.35)
	elseif comboStep == 2 then
		playPose("M1_2", 1.35)
	elseif comboStep == 3 then
		playPose("M1_3", 1.35)
	elseif comboStep == 4 then
		playPose("M1_4", 1.15)
	end

	comboStep = if comboStep >= 4 then 1 else comboStep + 1

	ClientAPI.requestMove("M1", aimPos)
end

local function executeHeavy()
	local aimPos = getAimPosition(true)
	local myRoot = getRoot()
	if myRoot then
		myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))
		myRoot.AssemblyLinearVelocity = myRoot.CFrame.LookVector * 26 + Vector3.new(0, 4, 0)
	end

	-- Heavy doubles as the launcher ender: Launcher while the target is airborne, Heavy on the ground.
	playPose(if isAirborne() then "Launcher" else "Heavy", 1.0)

	ClientAPI.requestMove("Heavy", aimPos)
end

local function executeKiBlast()
	local aimPos = getAimPosition(false)
	local myRoot = getRoot()
	if myRoot then
		myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))
	end

	playPose("KiVolley", 1.4)

	ClientAPI.requestMove("KiBlast", aimPos)
end

local function executeKamehameha()
	local aimPos = getAimPosition(false)
	local myRoot = getRoot()
	if myRoot then
		myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))
	end

	local sig = SIGNATURE[championKey()] or SIGNATURE.shared
	playPose(sig.charge, 1.0)
	task.delay(0.6, function()
		playPose(sig.fire, 1.0)
	end)

	ClientAPI.requestMove(sig.move, aimPos)
end

local function moveDir(): Vector3
	local hum = getHum()
	local d = hum and hum.MoveDirection or Vector3.zero
	if d.Magnitude < 0.1 then
		d = camera.CFrame.LookVector
	end
	return d
end

-- ========================================================
-- INPUT ROUTING
-- ========================================================
local KEYMOVES = {
	[Enum.KeyCode.G] = "Heavy",
	[Enum.KeyCode.One] = "KiBlast",
	[Enum.KeyCode.Two] = "Kamehameha",
	[Enum.KeyCode.Z] = "Absorb",
	[Enum.KeyCode.Three] = "Copy",
	[Enum.KeyCode.T] = "FinalExplosion",
	[Enum.KeyCode.Y] = "Erase",
}

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or player:GetAttribute("Spectating") then
		return
	end

	-- LMB: 4-Hit M1 Combo
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		executeM1()
		return
	end

	-- Lock-on toggle: [C], [L], [Tab], or [MiddleClick]
	if
		input.KeyCode == Enum.KeyCode.C
		or input.KeyCode == Enum.KeyCode.L
		or input.KeyCode == Enum.KeyCode.Tab
		or input.UserInputType == Enum.UserInputType.MouseButton3
		or input.KeyCode == Enum.KeyCode.ButtonR3
	then
		toggleLock()
		return
	end

	local k = input.KeyCode
	if k == Enum.KeyCode.G then
		executeHeavy()
	elseif k == Enum.KeyCode.One then
		executeKiBlast()
	elseif k == Enum.KeyCode.Two then
		executeKamehameha()
	elseif KEYMOVES[k] then
		ClientAPI.requestMove(KEYMOVES[k], getAimPosition(false))
	elseif k == Enum.KeyCode.X or k == Enum.KeyCode.DPadUp then
		ClientAPI.transform("Next")
	elseif k == Enum.KeyCode.F then
		ClientAPI.block(true)
		playPose("Guard", 1.2)
		-- The Guard clip carries no sound marker, so the guard impact stays a manual call.
		AudioRegistry.play("Block", getChar(), 0.7)
	elseif k == Enum.KeyCode.Q then
		ClientAPI.dash(moveDir())
		-- Dash's whoosh comes from the clip's own `sound = "Dash"` marker now.
		playPose("Dash", 1.5)
	elseif k == Enum.KeyCode.E then
		ClientAPI.vanish(moveDir())
		-- No vanish clip exists (the server owns the teleport), so play the SFX directly.
		AudioRegistry.play("Vanish", getChar(), 0.9)
	elseif k == Enum.KeyCode.R then
		ClientAPI.comboBreak()
		AudioRegistry.play("AuraBurst", getChar(), 1.0)
	elseif k == Enum.KeyCode.V then
		ClientAPI.struggleInput()
	elseif k == Enum.KeyCode.B then
		ClientAPI.useItem("EnergyDrink")
	end
end)

-- Authentic Dragon Ball Jump Sound Hook
local lastJumpTime = 0
UserInputService.JumpRequest:Connect(function()
	local now = os.clock()
	if now - lastJumpTime < 0.4 then
		return
	end
	local ch = getChar()
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum and hum.FloorMaterial ~= Enum.Material.Air then
		lastJumpTime = now
		AudioRegistry.play("Jump", ch, 0.75)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		ClientAPI.block(false)
		if activePoseHandle and activePoseHandle.Stop then
			activePoseHandle:Stop(0.1)
		end
	end
end)

-- ========================================================
-- HIT REACTIONS (HurtLight / HurtHeavy / KO)
-- All three clips exist for every hero but nothing ever played them, so a fighter taking a hit showed no
-- reaction at all. Light hits flinch, heavy hits stagger, a KO drops them.
-- ========================================================
local lastReactAt = 0
ClientAPI.onCombatEvent:Connect(function(kind: string, data: any)
	if kind ~= "Hit" or type(data) ~= "table" then
		return
	end
	local me = getChar()
	if not me then
		return
	end
	local victim = data[1]
	if victim ~= player.UserId and victim ~= me then
		return
	end
	if player:GetAttribute("Blocking") == true then
		return
	end
	local now = os.clock()
	if now - lastReactAt < 0.18 then
		return
	end
	lastReactAt = now

	local knockback = data[4] or 0
	if data[5] then
		playPose("KO", 1.0)
	elseif knockback >= 40 then
		playPose("HurtHeavy", 1.15)
	elseif knockback >= 15 then
		playPose("HurtHeavy", 1.3)
	else
		playPose("HurtLight", 1.35)
	end
end)

-- STATE VISIBILITY (2026-10-14): this element had no state awareness, so it was drawn over the character-select
-- grid and the Intro/Ending cutscenes. It is built with UIKit.button / Instance.new directly rather than through
-- UIStyle.toggle, so the shared nav guard never reached it.
local function syncStateVisibility()
	local s = workspace:GetAttribute("RoundState")
	reticleGui.Enabled = s ~= "Intro" and s ~= "Ending" and s ~= "CharacterSelect"
end
workspace:GetAttributeChangedSignal("RoundState"):Connect(syncStateVisibility)
syncStateVisibility()
