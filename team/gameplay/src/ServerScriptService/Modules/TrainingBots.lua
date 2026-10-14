--!strict
-- ModuleScript: ServerScriptService.Modules.TrainingBots (v3.0 Adaptive Goku & Vegeta Sparring System)
-- The player's sparring partners are Son Goku and Prince Vegeta.
-- "The more you spar with them, the better they become, forcing you to become better":
-- Features dynamic Zenkai adaptation and in-match form ascensions:
-- Level 1: Base Form (Warmup fundamentals)
-- Level 2: Super Saiyan (Golden aura, faster combos, sidestep flash steps)
-- Level 3: Super Saiyan Blue (Azure god ki, counter-parry, beam combos)
-- Level 4: Mastered Ultra Instinct (Goku autonomous dodge) & Ultra Ego (Vegeta pain-to-power scaling)!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TrainingMath = require(ReplicatedStorage.Shared.TrainingMath)
local PlayerData = require(script.Parent.PlayerData)
local QuestService = require(script.Parent.QuestService)
local AvatarSlots = require(script.Parent.AvatarSlots)
local Net = require(script.Parent.Net)

local PlayVFX = Net.remote("PlayVFX")

local Poses = ReplicatedStorage:FindFirstChild("Poses")
local PosePlayer = Poses and require(Poses:WaitForChild("PosePlayer"))
local GokuPoses = Poses and require(Poses:WaitForChild("Goku"))
local VegetaPoses = Poses and require(Poses:WaitForChild("Vegeta"))

local TrainingBots = {}
local CFG = Config.SPAR_BOTS

type PartnerInfo = {
	id: string,
	displayName: string,
	giShirt: string,
	giPants: string,
	hairName: string,
	forms: { string },
}

local PARTNERS: { [string]: PartnerInfo } = {
	Goku = {
		id = "u7_goku",
		displayName = "Son Goku",
		giShirt = "rbxassetid://18504993117",
		giPants = "rbxassetid://18504993117",
		hairName = "GokuHair",
		forms = { "Base", "SuperSaiyan", "SuperSaiyanBlue", "MUI" },
	},
	Vegeta = {
		id = "u7_vegeta",
		displayName = "Prince Vegeta",
		giShirt = "rbxassetid://1245568434",
		giPants = "rbxassetid://917557257",
		hairName = "VegetaHair",
		forms = { "Base", "SuperSaiyan", "SuperSaiyanBlue", "UltraEgo" },
	},
}

type Bot = {
	model: Model,
	pad: BasePart,
	alive: boolean,
	lastAttack: number,
	stunUntil: number,
	lastAttacker: Player?,
	g: number,
	partnerKey: string,
	partner: PartnerInfo,
	masteryLevel: number,
	form: string,
	comboStep: number,
	blocking: boolean,
	blockUntil: number,
	lastDodge: number,
	lastBlast: number,
	painBoost: number,
	hasAscendedInFight: boolean,
	titleLabel: TextLabel?,
	formLabel: TextLabel?,
	hpFill: Frame?,
}

local bots: { [Model]: Bot } = {}
local padBusy: { [BasePart]: number } = {}
local playerMastery: { [Player]: { Goku: number, Vegeta: number } } = {}
local koCount: { [Player]: number } = {}
local attackFn: ((Model, Player, any) -> string)? = nil
local emptySince: number? = nil

function TrainingBots.setAttack(fn: (Model, Player, any) -> string)
	attackFn = fn
end

local function gravity(): number
	local c = CollectionService:GetTagged("GravityConsole")[1]
	return (c and c:GetAttribute("GravityMultiplier") :: number?) or 1
end

local function xpMult(g: number): number
	local G = Config.TRAINING.GravityRoom
	return G.xpMultAtStep[TrainingMath.stepIndex(G.steps, g)]
end

local function rootOf(m: Model): BasePart?
	return m:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local BOT_AREAS = { GravityRoom = true, WhisGround = true, TrainingHub = true, Lobby = true }

local function areaOccupied(room: { Player }, area: string): boolean
	for _, p in room do
		local a = p:GetAttribute("TrainingArea")
		if a == area or a == nil or area == "TrainingHub" or area == "Lobby" then return true end
	end
	return false
end

local function playersInRoom(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		local area = p:GetAttribute("TrainingArea") :: any
		if (BOT_AREAS[area] or area == nil) and p: GetAttribute("Alive") == true then
			table.insert(out, p)
		end
	end
	return out
end

local function getPlayerMastery(p: Player, partnerKey: string): number
	local pm = playerMastery[p]
	if not pm then
		pm = { Goku = 1, Vegeta = 1 }
		playerMastery[p] = pm
	end
	return (pm :: any)[partnerKey] or 1
end

local function advanceMastery(p: Player, partnerKey: string)
	local pm = playerMastery[p]
	if not pm then
		pm = { Goku = 1, Vegeta = 1 }
		playerMastery[p] = pm
	end
	local cur = (pm :: any)[partnerKey] or 1
	if cur < 4 then
		(pm :: any)[partnerKey] = cur + 1
	end
end

-- ========================================================
-- BOT CREATION (R15 Rig with Goku / Vegeta Appearance)
-- ========================================================
local function createSaiyanPartner(pad: BasePart, partnerKey: string, masteryLevel: number, g: number): Model
	local partner = PARTNERS[partnerKey]
	local desc = Instance.new("HumanoidDescription")
	local m: Model? = nil
	local ok, res = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and res and res:IsA("Model") then
		m = res
	else
		m = Instance.new("Model")
		local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Transparency = 1; root.Parent = m
		local hum = Instance.new("Humanoid"); hum.RigType = Enum.HumanoidRigType.R15; hum.Parent = m
		m.PrimaryPart = root
	end

	local bot = m :: Model
	bot.Name = partner.displayName
	bot:SetAttribute("Character", partner.id)
	bot:SetAttribute("ChampionModel", partner.id)

	-- Clothing
	local s = bot:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")
	s.Name = "Shirt"; s.ShirtTemplate = partner.giShirt; s.Parent = bot

	local p = bot:FindFirstChildOfClass("Pants") or Instance.new("Pants")
	p.Name = "Pants"; p.PantsTemplate = partner.giPants; p.Parent = bot

	-- Hair Accessory
	local assets = ReplicatedStorage:FindFirstChild("AnimeRosterAssets")
	local hair = assets and assets:FindFirstChild("Hair") and assets.Hair:FindFirstChild(partner.hairName)
	if hair and bot:FindFirstChildOfClass("Humanoid") then
		local hClone = hair:Clone()
		hClone.Name = "AnimeHair"
		bot:FindFirstChildOfClass("Humanoid"):AddAccessory(hClone)
	end

	-- Skin tone
	local bc = bot:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	bc.Name = "BodyColors"
	local skinColor = Color3.fromRGB(255, 222, 192)
	bc.HeadColor3 = skinColor; bc.TorsoColor3 = skinColor; bc.LeftArmColor3 = skinColor
	bc.RightArmColor3 = skinColor; bc.LeftLegColor3 = skinColor; bc.RightLegColor3 = skinColor
	bc.Parent = bot

	-- Stats scaled by gravity and mastery
	local hum = bot:FindFirstChildOfClass("Humanoid") :: Humanoid
	local baseHp = 120 + masteryLevel * 60 + g * 5
	local speed = 18 + masteryLevel * 3 + math.min(8, g * 0.1)
	hum.WalkSpeed = speed
	hum.MaxHealth = baseHp
	hum.Health = baseHp

	-- Combat Billboard
	local head = bot:FindFirstChild("Head") :: BasePart?
	local titleLabel: TextLabel? = nil
	local formLabel: TextLabel? = nil
	local hpFill: Frame? = nil

	if head then
		local bb = Instance.new("BillboardGui")
		bb.Name = "CombatTag"
		bb.Size = UDim2.new(0, 180, 0, 52)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.AlwaysOnTop = true
		bb.Parent = head

		titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0, 18)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBlack
		titleLabel.TextSize = 13
		titleLabel.TextColor3 = if partnerKey == "Goku" then Color3.fromRGB(255, 180, 50) else Color3.fromRGB(70, 180, 255)
		titleLabel.Text = (if partnerKey == "Goku" then "🥋 " else "👑 ") .. partner.displayName:upper()
		titleLabel.Parent = bb

		formLabel = Instance.new("TextLabel")
		formLabel.Size = UDim2.new(1, 0, 0, 14)
		formLabel.Position = UDim2.new(0, 0, 0, 18)
		formLabel.BackgroundTransparency = 1
		formLabel.Font = Enum.Font.GothamBold
		formLabel.TextSize = 10
		formLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
		formLabel.Text = string.format("ADAPTIVE RIVAL (TIER %d)", masteryLevel)
		formLabel.Parent = bb

		local hpBg = Instance.new("Frame")
		hpBg.Size = UDim2.new(1, 0, 0, 8)
		hpBg.Position = UDim2.new(0, 0, 0, 34)
		hpBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		hpBg.BorderSizePixel = 0
		hpBg.Parent = bb

		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = hpBg

		hpFill = Instance.new("Frame")
		hpFill.Name = "HPFill"
		hpFill.Size = UDim2.new(1, 0, 1, 0)
		hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 80)
		hpFill.BorderSizePixel = 0
		hpFill.Parent = hpBg

		local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 4); fc.Parent = hpFill

		hum.HealthChanged:Connect(function(health)
			local frac = math.clamp(health / math.max(1, hum.MaxHealth), 0, 1)
			if hpFill then
				hpFill.Size = UDim2.new(frac, 0, 1, 0)
				if frac < 0.3 then
					hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
				elseif frac < 0.6 then
					hpFill.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
				else
					hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 80)
				end
			end
		end)
	end

	bot:PivotTo(pad.CFrame + Vector3.new(0, 3.5, 0))
	bot:SetAttribute("TrainingBot", true)
	CollectionService:AddTag(bot, "TrainingBot")
	bot.Parent = pad.Parent or workspace

	local root = rootOf(bot)
	if root then pcall(function() root:SetNetworkOwner(nil) end) end

	return bot
end

local function despawn(m: Model)
	bots[m] = nil
	if m.Parent then m:Destroy() end
end

function TrainingBots.clear()
	for m in bots do despawn(m) end
	table.clear(padBusy)
end

-- ========================================================
-- FORM ASCENSION (In-Combat & Evolution)
-- ========================================================
local function ascendPartner(b: Bot, formName: string)
	if b.form == formName then return end
	b.form = formName
	b.hasAscendedInFight = true
	b.model:SetAttribute("Form", formName)

	-- Update physical hair and colors via AvatarSlots
	AvatarSlots.applyForm(b.model, b.partner.id, formName)

	-- Particle burst & aura
	local vfxPreset = if formName == "SuperSaiyan" then "SSJ"
		elseif formName == "SuperSaiyanBlue" then "SSB"
		elseif formName == "MUI" then "MUI"
		elseif formName == "UltraEgo" then "UltraEgo"
		else nil
	if vfxPreset then
		PlayVFX:FireAllClients("Transform", b.model, vfxPreset)
	end

	-- Heal 40% as transformation surge
	local hum = b.model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.4)
		hum.WalkSpeed += 4
	end

	-- Update billboard title
	if b.formLabel then
		b.formLabel.Text = string.format("⚡ %s ASCENSION ⚡", formName:upper())
		b.formLabel.TextColor3 = if formName == "SuperSaiyan" then Color3.fromRGB(255, 230, 60)
			elseif formName == "SuperSaiyanBlue" then Color3.fromRGB(0, 220, 255)
			elseif formName == "MUI" then Color3.fromRGB(240, 245, 255)
			elseif formName == "UltraEgo" then Color3.fromRGB(200, 60, 255)
			else Color3.fromRGB(220, 220, 235)
	end
end

local function onKO(b: Bot)
	if not b.alive then return end
	b.alive = false
	padBusy[b.pad] = os.clock() + CFG.respawn

	local p = b.lastAttacker
	if p and p.Parent then
		local st = TrainingMath.botStats(CFG, b.g, xpMult(b.g))
		local masteryBonus = 1 + b.masteryLevel * 0.35
		PlayerData.addXP(p, math.floor(st.xp * masteryBonus))
		PlayerData.addZeni(p, math.floor(st.zeni * masteryBonus))

		-- Player defeated this tier: advance partner mastery!
		advanceMastery(p, b.partnerKey)

		koCount[p] = (koCount[p] or 0) + 1
		if koCount[p] % CFG.drillEvery == 0 then QuestService.track(p, "drill", 1) end
	end
	task.delay(1.5, function() despawn(b.model) end)
end

-- ========================================================
-- COMBAT HIT SCAN & REACTION
-- ========================================================
function TrainingBots.hitScan(att: Player, mv: any, targetPos: Vector3): (Model?, Vector3)
	-- Area gate bypassed: bots can be sparred anywhere in training
	local ar = att.Character and att.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not ar then return nil, targetPos end
	local from = ar.Position
	local dir = targetPos - from
	dir = if dir.Magnitude > 0.01 then dir.Unit else ar.CFrame.LookVector
	local best, bestD = nil, math.huge
	for m, b in bots do
		local r = rootOf(m)
		if b.alive and r then
			local rel = r.Position - from
			if mv.kind == "melee" then
				local d = rel.Magnitude
				if d <= (mv.range or 7) + 5.0 and (d < 4.5 or dir:Dot(rel.Unit) >= 0.12) and d < bestD then
					best, bestD = m, d
				end
			elseif mv.kind == "ray" then
				local along = rel:Dot(dir)
				if along > 0 and along <= (mv.range or 100) then
					local perp = (rel - dir * along).Magnitude
					if perp <= (mv.width or 3.5) + 3.5 and along < bestD then
						best, bestD = m, along
					end
				end
			end
		end
	end
	if best then return best, (rootOf(best) :: BasePart).Position end
	return nil, targetPos
end

function TrainingBots.hit(att: Player, m: Model, mv: any, power: number)
	local b = bots[m]
	local hum = m:FindFirstChildOfClass("Humanoid")
	local r = rootOf(m)
	if not b or not b.alive or not hum or not r then return end

	b.lastAttacker = att
	local now = os.clock()

	-- 1. Goku Ultra Instinct Autonomous Dodge (50% phase-through)
	if b.form == "MUI" and math.random() <= 0.50 then
		PlayVFX:FireAllClients("Transform", m, "UISign")
		-- Flash step sideways / behind
		local ar = att.Character and att.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if ar then
			r.CFrame = ar.CFrame * CFrame.new(math.random(-4, 4), 0, 4) * CFrame.Angles(0, math.pi, 0)
		end
		return -- Completely dodged!
	end

	-- 2. Vegeta Ultra Ego: Pain into Power!
	if b.form == "UltraEgo" then
		b.painBoost = math.min(1.5, b.painBoost + 0.08)
	end

	-- 3. Adaptive Guard & Parry
	local guardChance = 0.25 + b.masteryLevel * 0.10
	if not b.blocking and mv.kind == "melee" and math.random() <= guardChance and now - b.lastDodge > 2.5 then
		b.blocking = true
		b.blockUntil = now + 1.0
	end

	local damageMult = 1.0
	if b.blocking and b.blockUntil > now then
		damageMult = 0.25
		PlayVFX:FireAllClients("Parry", m)
	end

	local finalDamage = (mv.damage or 5) * (power or 1) * damageMult
	hum:TakeDamage(finalDamage)
	b.stunUntil = now + (if b.blocking then 0.1 else (mv.hitstun or 0.35))

	-- In-match Zenkai form ascension when dropped below 50% HP!
	if not b.hasAscendedInFight and hum.Health > 0 and hum.Health <= hum.MaxHealth * 0.5 then
		if b.masteryLevel >= 3 then
			ascendPartner(b, if b.partnerKey == "Goku" then "MUI" else "UltraEgo")
		elseif b.masteryLevel >= 2 then
			ascendPartner(b, "SuperSaiyanBlue")
		else
			ascendPartner(b, "SuperSaiyan")
		end
	end

	-- Knockback & Counter Vanish
	local ar = att.Character and att.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if ar and (mv.kb or 0) > 0 and not b.blocking then
		local d = r.Position - ar.Position
		d = Vector3.new(d.X, 0, d.Z)
		d = if d.Magnitude > 0.01 then d.Unit else Vector3.new(1, 0, 0)
		r.AssemblyLinearVelocity = d * mv.kb + Vector3.new(0, mv.kb * 0.35, 0)

		-- Higher tiers counter-vanish behind attacker
		if b.masteryLevel >= 2 and math.random() <= 0.40 and now - b.lastDodge > 3.0 then
			b.lastDodge = now
			task.delay(0.25, function()
				if b.alive and ar and r then
					r.CFrame = ar.CFrame * CFrame.new(0, 0, 5) * CFrame.Angles(0, math.pi, 0)
					r.AssemblyLinearVelocity = Vector3.zero
				end
			end)
		end
	end

	if hum.Health <= 0 then onKO(b) end
end

function TrainingBots.count(): number
	local n = 0
	for _, b in bots do if b.alive then n += 1 end end
	return n
end

-- ========================================================
-- COMBAT AI LOOP
-- ========================================================
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.15 then return end
	acc = 0

	local room = playersInRoom()
	local now = os.clock()

	if #room == 0 then
		emptySince = emptySince or now
		if now - emptySince >= CFG.despawnEmpty and next(bots) then TrainingBots.clear() end
		return
	end
	emptySince = nil

	local g = gravity()

	-- Spawn on free pads
	local n = 0
	for _, b in bots do if b.alive then n += 1 end end

	local spawnPads = CollectionService:GetTagged("TrainingBotSpawn")
	for idx, pad in ipairs(spawnPads) do
		if n >= CFG.max then break end
		local area = pad:GetAttribute("AreaId")
		if pad:IsA("BasePart") and BOT_AREAS[area :: any] and areaOccupied(room, area :: any) then
			local t = padBusy[pad]
			if t == nil or (t > 0 and now >= t) then
				-- Alternate Goku (odd) and Vegeta (even)
				local partnerKey = if idx % 2 == 1 then "Goku" else "Vegeta"
				local partner = PARTNERS[partnerKey]

				-- Check player's mastery for this partner
				local highestMastery = 1
				for _, p in ipairs(room) do
					local m = getPlayerMastery(p, partnerKey)
					if m > highestMastery then highestMastery = m end
				end

				local m = createSaiyanPartner(pad, partnerKey, highestMastery, if area == "GravityRoom" then g else 1)
				local initialForm = partner.forms[highestMastery] or "Base"

				bots[m] = {
					model = m,
					pad = pad,
					alive = true,
					lastAttack = 0,
					stunUntil = 0,
					lastAttacker = nil,
					g = if area == "GravityRoom" then g else 1,
					partnerKey = partnerKey,
					partner = partner,
					masteryLevel = highestMastery,
					form = initialForm,
					comboStep = 1,
					blocking = false,
					blockUntil = 0,
					lastDodge = 0,
					lastBlast = 0,
					painBoost = 1.0,
					hasAscendedInFight = false,
					titleLabel = m:FindFirstChild("CombatTag", true) and m:FindFirstChild("CombatTag", true):FindFirstChildOfClass("TextLabel"),
					formLabel = nil,
					hpFill = nil,
				}
				padBusy[pad] = 0

				-- Apply starting form
				if initialForm ~= "Base" then
					ascendPartner(bots[m], initialForm)
				end

				local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
				hum.Died:Connect(function()
					local b = bots[m]
					if b then onKO(b) end
				end)
				n += 1
			end
		end
	end

	-- Per-Bot Combat Execution
	for m, b in bots do
		local r, hum = rootOf(m), m:FindFirstChildOfClass("Humanoid")
		if not b.alive or not r or not hum then continue end

		if b.blocking and now >= b.blockUntil then
			b.blocking = false
		end

		if b.stunUntil > now then continue end

		-- Find target player
		local target, best = nil, CFG.aggroRange
		for _, p in room do
			local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local ph = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if pr and ph and ph.Health > 0 then
				local d = (pr.Position - r.Position).Magnitude
				if d < best then target, best = p, d end
			end
		end
		if not target then continue end

		local tr = (target.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart

		-- MELEE COMBAT (<= 7 studs)
		if best <= CFG.attackRange then
			hum:MoveTo(r.Position)
			r.CFrame = CFrame.new(r.Position, Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z))

			local attackCd = if b.comboStep >= 4 then 0.9 else 0.28
			if now - b.lastAttack >= attackCd and attackFn then
				b.lastAttack = now
				local st = TrainingMath.botStats(CFG, b.g, 1)

				local isFinisher = b.comboStep >= 4
				local damage = (if isFinisher then st.damage * 1.6 else st.damage * 0.8) * b.painBoost
				local kb = if isFinisher then 40 else 8
				local hitstun = if isFinisher then 0.6 else 0.28

				local res = attackFn(m, target, { damage = damage, kb = kb, hitstun = hitstun })
				if res == "Parry" then
					b.stunUntil = now + Config.SKILL.ParryStun
					b.comboStep = 1
				else
					b.comboStep = if isFinisher then 1 else b.comboStep + 1
				end
			end

		-- MID-RANGE KI BLAST / BEAM (14 to 45 studs)
		elseif best > 14 and best <= 45 and now - b.lastBlast >= (if b.masteryLevel >= 3 then 2.5 else 4.0) then
			b.lastBlast = now
			r.CFrame = CFrame.new(r.Position, Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z))
			if attackFn then
				local st = TrainingMath.botStats(CFG, b.g, 1)
				local isBeam = (b.masteryLevel >= 2 and math.random() <= 0.45)
				local damage = if isBeam then st.damage * 1.8 else st.damage * 0.6
				local kb = if isBeam then 35 else 10

				attackFn(m, target, {
					damage = damage * b.painBoost,
					kb = kb,
					hitstun = 0.35,
					kind = "ray",
				})

				-- Beam visual effects
				local beamEffect = if b.partnerKey == "Goku" then "Kamehameha" else "GalickGun"
				PlayVFX:FireAllClients(beamEffect, m, tr.Position)
			end
			hum:MoveTo(tr.Position)

		-- CHASE
		else
			hum:MoveTo(tr.Position)
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	koCount[p] = nil
	playerMastery[p] = nil
end)

return TrainingBots
