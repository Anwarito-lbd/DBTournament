-- ModuleScript: ReplicatedStorage.Shared.CutsceneDirector (v2 story player)
-- Plays StoryDialogue beat lists: { cam, actors, action, speaker, text, duration, perTeam, then, onEnd, triggersWishChoice }.
-- Actors come from ReplicatedStorage.CharacterModels[<id>] when present (generated meshes), else UIKit placeholder figures.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local SuperShenron = require(script.Parent:WaitForChild("SuperShenron"))
local CastFigures = require(script.Parent:WaitForChild("CastFigures"))
local player = Players.LocalPlayer

local D = {}
local CENTER = Vector3.new(0, 500, 0)
local FACE = Vector3.new(0, 0, 1)
-- Layout is read from the v2 scalable arena (Workspace.WorldOfVoid.Arena attrs + ZenoBox/Spawn_Zeno) on every D.new()
local SPOTS: { [string]: Vector3 } = {}
local HEIGHT = { npc_grand_priest = 5.4, npc_zeno = 4, npc_zeno_future = 4, npc_zeno_guard_1 = 11, npc_zeno_guard_2 = 11 }
-- the ever-present cast is built by CastFigures (rigged, anime-accurate); CharacterModels entries are not used for them
local CAST_KIND = { npc_zeno = "Zeno", npc_zeno_future = "FutureZeno", npc_grand_priest = "GrandPriest",
	npc_zeno_guard_1 = "Attendant", npc_zeno_guard_2 = "Attendant" }
local SHENRON_BASE, BALLS_C, BALLS_R, K = Vector3.new(0, 470, -190), Vector3.new(0, 506, -120), 26, 1
-- built Super Shenron (no library model): tail root far behind Zeno's box, facing the ring; scales with the arena
local SHENRON_ROOT, SHENRON_SCALE = CFrame.new(0, 80, -600), 1
-- built Super Dragon Balls (anime reference: six in a ring around one, floating in space): planet-like orbs whose
-- formation stands above and behind the arena facing the players. SDB_CF's local Y faces the viewers; balls sit in
-- its XZ plane at radius SDB_R; diameter SDB_D
local SDB_CF, SDB_R, SDB_D = CFrame.new(0, 610, -60), 70, 40
local function readLayout()
	local wov = workspace:FindFirstChild("WorldOfVoid")
	local arena = wov and wov:FindFirstChild("Arena")
	local R = (arena and arena:GetAttribute("Radius") :: number?) or 150
	K = R / 150
	local function spawnPart(): BasePart?
		local box = arena and arena:FindFirstChild("ZenoBox")
		local p = box and box:FindFirstChild("Spawn_Zeno")
		return if p and p:IsA("BasePart") then p else nil
	end
	-- Zeno's box floats ~600 studs from the ring, so with StreamingEnabled it is often not loaded yet when a cutscene
	-- starts: ask for it to stream in, and if it still isn't here, derive the spot from the Arena's ZenoPos attribute
	-- (the folder and its attributes always replicate) exactly as map/Arena.lua places Spawn_Zeno
	local zp = arena and arena:GetAttribute("ZenoPos")
	local zs = spawnPart()
	if not zs and typeof(zp) == "Vector3" then
		pcall(function() player:RequestStreamAroundAsync(zp, 2) end)
		zs = spawnPart()
	end
	local zcf: CFrame
	if zs then
		local pos = zs.Position + Vector3.new(0, 0.5, 0)
		zcf = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
	elseif typeof(zp) == "Vector3" then
		local pos = zp + Vector3.new(0, 3, 0) -- the box is level: Spawn_Zeno's top sits 3 studs above the box's centre
		zcf = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
	else
		zcf = CFrame.lookAt(Vector3.new(0, 514, -62), Vector3.new(0, 514, 0))
	end
	FACE = zcf.LookVector
	local function at(x, z) return (zcf * CFrame.new(x, 0, z)).Position end
	-- zcf sits on the spawn pad's top, 1 stud above the box floor; the throne seats are 2 studs above the pad
	local floor, seat = Vector3.new(0, -1, 0), Vector3.new(0, 2, 0)
	SPOTS = {
		npc_zeno = at(-6, 4.3) + seat, npc_zeno_future = at(6, 4.3) + seat,
		npc_zeno_guard_1 = at(-15, 9) + floor, npc_zeno_guard_2 = at(15, 9) + floor,
		npc_grand_priest = at(-20, -6) + floor,
	}
	-- Shenron rises behind the far (-Z) edge of the ring; balls gather on the ring near that edge
	SHENRON_BASE = Vector3.new(0, 470, -(R + 60))
	-- the colossus coils up out of the void behind Zeno's box; its head hangs a few hundred studs above the box
	SHENRON_SCALE = math.max(1, R / 200)
	local rootY, rootZ = 500 - 470 * SHENRON_SCALE, zcf.Position.Z - 300 * SHENRON_SCALE
	SHENRON_ROOT = CFrame.lookAt(Vector3.new(0, rootY, rootZ), Vector3.new(0, rootY, 0))
	BALLS_C, BALLS_R = Vector3.new(0, 506, -R * 0.55), math.max(26, R * 0.17)
	local sdbPos = Vector3.new(0, 500 + 230 * K, -R * 0.45)
	SDB_CF = CFrame.lookAt(sdbPos, CENTER + Vector3.new(0, 10 * K, 90 * K)) * CFrame.Angles(-math.pi / 2, 0, 0)
	SDB_D = 84 * K -- "planet-sized": each ball dwarfs the fighters
	SDB_R = SDB_D * 1.75
end

local function anchorAll(m: Instance)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
	end
end

local function fromLibrary(id: string): Model?
	local lib = ReplicatedStorage:FindFirstChild("CharacterModels")
	if not lib then return nil end
	local ALIAS = { npc_zeno_future = "npc_zeno" }
	local src = lib:FindFirstChild(id) or (ALIAS[id] and lib:FindFirstChild(ALIAS[id])) or lib:FindFirstChild((string.gsub(id, "_%d+$", "")))
	if not src then return nil end
	local m: Model
	if src:IsA("Model") then m = src:Clone() else m = Instance.new("Model"); src:Clone().Parent = m end
	anchorAll(m)
	return m
end

-- place model so its feet sit at pos, facing dir, scaled to height h
local function stand(m: Model, pos: Vector3, h: number, dir: Vector3?)
	local _, size = m:GetBoundingBox()
	if size.Y > 0 then pcall(function() m:ScaleTo(m:GetScale() * h / size.Y) end) end
	local cf, sz = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(cf)
	local want = CFrame.lookAt(pos + Vector3.new(0, sz.Y / 2, 0), pos + Vector3.new(0, sz.Y / 2, 0) + (dir or FACE))
	m:PivotTo(want * offset:Inverse())
end


-- v3 (db-story): universe stand position (StandSpawn tags, Universe = "U07"), fallback: ring of stands around the arena
local function standPos(u: number?): Vector3
	local sum, n = Vector3.zero, 0
	if u then
		local tag = string.format("U%02d", u)
		for _, inst in CollectionService:GetTagged("StandSpawn") do
			if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) and inst:GetAttribute("Universe") == tag then sum += inst.Position; n += 1 end
		end
	end
	if n > 0 then return sum / n end
	local a = math.rad(((u or 1) - 1) * 30)
	return CENTER + Vector3.new(math.cos(a) * 230 * K, 30, math.sin(a) * 230 * K)
end
local function findBoss(name: string?): Model?
	local wov = workspace:FindFirstChild("WorldOfVoid") or workspace
	local m = wov:FindFirstChild(name or "Jiren", true)
	return if m and m:IsA("Model") then m else nil
end

function D.new()
	readLayout()
	local self = { actors = {} :: { [string]: Model }, conns = {}, fx = {} :: { Instance }, vars = {} :: { [string]: any } }

	-- one built Super Dragon Ball: glassy orange orb, inner glow, i red stars facing the arena
	local function superBall(i: number): Model
		local b = Instance.new("Model"); b.Name = "Ball" .. i
		-- ball 1 in the middle, 2..7 on the hexagon (top first)
		local a = (i - 2) / 6 * math.pi * 2 - math.pi / 2
		local off = if i == 1 then CFrame.new() else CFrame.new(math.cos(a) * SDB_R, 0, math.sin(a) * SDB_R)
		local pos = (SDB_CF * off).Position
		local face = CFrame.lookAt(pos, Vector3.new(0, pos.Y - 20 * K, CENTER.Z + 160 * K))
		local orb = Instance.new("Part"); orb.Name = "Orb"; orb.Shape = Enum.PartType.Ball; orb.Size = Vector3.one * SDB_D
		orb.Material = Enum.Material.Glass; orb.Color = Color3.fromRGB(255, 150, 30); orb.Transparency = 0.12; orb.CFrame = face; orb.Parent = b
		local core = Instance.new("Part"); core.Name = "Core"; core.Shape = Enum.PartType.Ball; core.Size = Vector3.one * SDB_D * 0.82
		core.Material = Enum.Material.Neon; core.Color = Color3.fromRGB(255, 176, 70); core.Transparency = 0.55; core.CFrame = face; core.Parent = b
		-- the stars look the same from every angle (Dragon Ball lore), so they are a billboard just in front of the shell
		local sg = Instance.new("BillboardGui"); sg.Name = "Stars"; sg.Adornee = orb; sg.Size = UDim2.fromScale(SDB_D * 0.5, SDB_D * 0.5)
		sg.StudsOffset = Vector3.new(0, 0, SDB_D * 0.52); sg.LightInfluence = 0; sg.Brightness = 2.5; sg.MaxDistance = 1e5; sg.Parent = orb
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Enum.Font.GothamBlack
		t.TextScaled = true; t.TextWrapped = true; t.TextColor3 = Color3.fromRGB(235, 28, 28); t.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
		t.TextStrokeTransparency = 0.3; t.Text = string.rep(utf8.char(0x2605), i); t.Parent = sg
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 170, 70); l.Range = 60; l.Brightness = 2; l.Parent = orb
		anchorAll(b)
		return b
	end

	local function balls(): Model
		local m = Instance.new("Model"); m.Name = "Story_super_dragon_balls"
		for i = 1, 7 do
			local a = math.rad(-90 + (i - 4) * 24)
			local pos = BALLS_C + Vector3.new(math.cos(a) * BALLS_R * 2, 0, math.sin(a) * BALLS_R)
			local b = fromLibrary("super_dragon_ball")
			if b then
				stand(b, pos, 9); b.Name = "Ball" .. i; b.Parent = m
			else
				superBall(i).Parent = m
				m:SetAttribute("Super", true)
			end
		end
		if not m:GetAttribute("Super") then
			for _, d in m:GetDescendants() do if d:IsA("BasePart") then
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 190, 80); l.Range = 14; l.Brightness = 1.5; l.Parent = d; break end end
		end
		anchorAll(m); m.Parent = workspace; return m
	end

	local function shenron(): Model
		local m = fromLibrary("npc_shenron")
		if m then
			stand(m, SHENRON_BASE, 170, Vector3.new(0, 0, 1)); m.Name = "Story_npc_shenron"
			for _, d in m:GetDescendants() do if d:IsA("BasePart") then
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 90); l.Range = 60; l.Brightness = 2; l.Parent = d; break end end
			m.Parent = workspace
			return m
		end
		return SuperShenron.build(SHENRON_ROOT, SHENRON_SCALE)
	end

	-- the ever-present cast in Zeno's box (ZenoBoxCast.client) is reused by cutscenes; cleanup puts it back
	local function adopt(id: string): Model?
		local f = workspace:FindFirstChild("ZenoBoxCast")
		local m = f and f:FindFirstChild(id)
		if m and m:IsA("Model") and m:GetAttribute("Persistent") then
			if m:GetAttribute("HomePivot") == nil then m:SetAttribute("HomePivot", m:GetPivot()) end
			return m
		end
		return nil
	end

	function self.actor(id: string): Model?
		if self.actors[id] then return self.actors[id] end
		local m: Model?
		if id == "super_dragon_balls" then m = balls()
		elseif id == "npc_shenron" then m = shenron()
		elseif SPOTS[id] and CAST_KIND[id] and adopt(id) then
			m = adopt(id)
		elseif SPOTS[id] and CAST_KIND[id] then
			local seated = id == "npc_zeno" or id == "npc_zeno_future" -- the Zenos watch from their thrones
			local fig = CastFigures.build(CAST_KIND[id], CFrame.lookAt(SPOTS[id], SPOTS[id] + FACE), HEIGHT[id], seated)
			fig.Name = "Story_" .. id; fig.Parent = workspace
			m = fig
		end
		if m then self.actors[id] = m end
		return m
	end

	local function focus(id: string): Vector3
		local m = self.actors[id] or self.actor(id)
		if not m then return CENTER end
		if m:GetAttribute("FocusOnHead") and m.PrimaryPart then return m.PrimaryPart.Position end
		local cf, size = m:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y * 0.3, 0)
	end
	local function myRoot(): BasePart?
		return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	local zenoFlip = false

	self.cams = {
		VoidEstablishWide = function() return CFrame.lookAt(CENTER + Vector3.new(0, 140, 330) * K, CENTER + Vector3.new(0, 20, -40)), 0.01 end,
		CraneToRing = function() return CFrame.lookAt(CENTER + Vector3.new(60, 45, 120) * K, CENTER), 4 end,
		PriestMedium = function() local h = focus("npc_grand_priest"); return CFrame.lookAt(h + FACE * 10 + FACE:Cross(Vector3.yAxis) * 4 + Vector3.new(0, 1, 0), h), 1.2 end,
		PriestPushIn = function() local h = focus("npc_grand_priest"); return CFrame.lookAt(h + FACE * 8 + Vector3.new(0, 0.5, 0), h), 3 end,
		ThroneLowAngle = function()
			-- low and in front of the thrones (the figures face FACE), inside the box's glass front
			local z = (SPOTS.npc_zeno + SPOTS.npc_zeno_future) / 2
			return CFrame.lookAt(z + FACE * 14 + Vector3.new(0, -1, 0), z + Vector3.new(0, 4, 0)), 1.5 end,
		ZenoTwoShot = function(beat)
			local z = (SPOTS.npc_zeno + SPOTS.npc_zeno_future) / 2 + Vector3.new(0, 3, 0)
			zenoFlip = not zenoFlip
			local right = FACE:Cross(Vector3.yAxis)
			local side = if beat.speaker == "npc_zeno" then -2 elseif beat.speaker == "npc_zeno_future" then 2 else 0
			return CFrame.lookAt(z + FACE * 11 - right * side * 0.5 + Vector3.new(0, 1.5, 0), z + right * side * 0.4), 0.8 end, -- in front of the Zenos, inside the box
		RingEdgeTrack = function() return CFrame.lookAt(CENTER + Vector3.new(-120, 12, 90) * K, CENTER + Vector3.new(0, 0, -30)), 6 end,
		StandsPan = function() return CFrame.lookAt(CENTER + Vector3.new(0, 60, 40) * K, CENTER + Vector3.new(200, 30, 0) * K), 4 end,
		FighterCuts = function()
			local r = myRoot()
			if r then return CFrame.lookAt(r.Position + r.CFrame.LookVector * 14 + Vector3.new(0, 4, 0), r.Position + Vector3.new(0, 2, 0)), 1 end
			return CFrame.lookAt(CENTER + Vector3.new(160, 90, 160), CENTER), 1 end,
		OverheadCountdown = function() return CFrame.lookAt(CENTER + Vector3.new(0, 220, 30) * K, CENTER), 2 end,
		WinnersWide = function() return CFrame.lookAt(CENTER + Vector3.new(0, 40, 110) * K, CENTER + Vector3.new(0, 10, -40)), 1.5 end,
		SkyWide = function()
			local m = self.actors.super_dragon_balls
			if m and m:GetAttribute("Super") then return CFrame.lookAt(CENTER + Vector3.new(0, 30, 200) * K, SDB_CF.Position + Vector3.new(0, 40 * K, 0)), 2 end
			return CFrame.lookAt(BALLS_C + Vector3.new(0, 30, 150), BALLS_C + Vector3.new(0, 60, -60)), 2 end,
		StageLowAngle = function()
			local m = self.actors.super_dragon_balls
			if m and m:GetAttribute("Super") then return CFrame.lookAt(CENTER + Vector3.new(0, 3, 60 * K), SDB_CF.Position), 1.5 end
			return CFrame.lookAt(BALLS_C + Vector3.new(0, 2, 60), BALLS_C + Vector3.new(0, 18, -20)), 1.5 end,
		ShenronCraneReveal = function()
			local m = self.actor("npc_shenron"); local cf, size = (m :: Model):GetBoundingBox()
			if (m :: Model):GetAttribute("FocusOnHead") and (m :: Model).PrimaryPart then
				-- colossus: rise from the ring's edge and look up past Zeno's box at the head and coils
				local head = ((m :: Model).PrimaryPart :: BasePart).Position
				return CFrame.lookAt(Vector3.new(head.X * 0.3, CENTER.Y + 40 * K, 120 * K), head - Vector3.new(0, 160 * K, 0)), 5
			end
			local h = math.max(size.Y, size.X * 0.6); local fov = math.rad(workspace.CurrentCamera.FieldOfView)
			local dist = (h * 0.62) / math.tan(fov / 2) + size.Z * 0.5
			return CFrame.lookAt(cf.Position + Vector3.new(0, -h * 0.12, dist), cf.Position + Vector3.new(0, h * 0.04, 0)), 5 end,
		ShenronExtremeLow = function()
			local m = self.actor("npc_shenron"); local cf, size = (m :: Model):GetBoundingBox()
			local top = if m:GetAttribute("FocusOnHead") and m.PrimaryPart then m.PrimaryPart.Position else cf.Position + Vector3.new(0, size.Y * 0.35, 0)
			if m:GetAttribute("FocusOnHead") then return CFrame.lookAt(CENTER + Vector3.new(0, 4, 90 * K), top + Vector3.new(0, 40 * K, 0)), 1.5 end
			return CFrame.lookAt(BALLS_C + Vector3.new(0, 1, 40), top), 1.5 end,
		LeaderOTS = function()
			local r = myRoot(); local s = focus("npc_shenron")
			if r then return CFrame.lookAt(r.Position + Vector3.new(3, 4, 10), s), 1.2 end
			return CFrame.lookAt(BALLS_C + Vector3.new(0, 4, 60), s), 1.2 end,
		-- v3 (db-story): Zeno erase + Universe Survival cams
		ErasedStandWide = function()
			local s = standPos(tonumber(self.vars.universeN))
			local dir = (s - CENTER) * Vector3.new(1, 0, 1)
			if dir.Magnitude < 1 then dir = Vector3.new(0, 0, 1) end
			return CFrame.lookAt(s - dir.Unit * 70 + Vector3.new(0, 25, 0), s), 1.2 end,
		BossSkyDrop = function()
			local b = findBoss(self.vars.boss)
			local at = if b then b:GetPivot().Position else CENTER + Vector3.new(0, 6, 0)
			return CFrame.lookAt(at + Vector3.new(0, 30, 70) * K, at + Vector3.new(0, 20, 0)), 1 end,
		BossCloseUp = function()
			local b = findBoss(self.vars.boss)
			if not b then return CFrame.lookAt(CENTER + Vector3.new(0, 15, 40), CENTER + Vector3.new(0, 8, 0)), 1 end
			local cf, size = b:GetBoundingBox()
			local head = cf.Position + Vector3.new(0, size.Y * 0.3, 0)
			return CFrame.lookAt(head + cf.LookVector * 14 + Vector3.new(0, -1.5, 0), head), 1.4 end,
	}

	local function tween(inst: Instance, t: number, props: any, style: Enum.EasingStyle?, rev: boolean?, rep: number?)
		local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, rep or 0, rev or false), props)
		tw:Play(); return tw
	end
	local function hop(id: string, height: number, times: number, period: number)
		local m = self.actors[id]; if not m then return end
		task.spawn(function()
			local base = m:GetPivot()
			for _ = 1, times do
				for i = 0, 10 do
					if not m.Parent then return end
					m:PivotTo(base + Vector3.new(0, math.sin(i / 10 * math.pi) * height, 0)); task.wait(period / 10)
				end
			end
			m:PivotTo(base)
		end)
	end
	local function wobble(id: string, deg: number, times: number)
		local m = self.actors[id]; if not m then return end
		task.spawn(function()
			local base = m:GetPivot()
			for i = 0, times * 8 do
				if not m.Parent then return end
				m:PivotTo(base * CFrame.Angles(0, 0, math.rad(math.sin(i / 8 * math.pi * 2) * deg))); task.wait(0.05)
			end
			m:PivotTo(base)
		end)
	end
	local function addFx(i: Instance) table.insert(self.fx, i); return i end
	-- one warm full-screen flash (softer with the ReduceMotion setting)
	local function flash(peak: number)
		local sg = addFx(Instance.new("ScreenGui")) :: ScreenGui
		sg.Name = "StoryFlash"; sg.IgnoreGuiInset = true; sg.DisplayOrder = 30; sg.Parent = player:WaitForChild("PlayerGui")
		local f = Instance.new("Frame"); f.Size = UDim2.fromScale(1, 1); f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(255, 236, 190); f.BackgroundTransparency = 1; f.Parent = sg
		local top = if player:GetAttribute("ReduceMotion") == true then math.max(peak, 0.75) else peak
		TweenService:Create(f, TweenInfo.new(0.15), { BackgroundTransparency = top }):Play()
		task.delay(0.2, function() if f.Parent then TweenService:Create(f, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play() end end)
	end

	self.actions = {
		Bow = function(beat) local m = self.actors.npc_grand_priest
			if m and m:GetAttribute("CastRig") then CastFigures.anim(m, "Bow"); return end
			if m then local b = m:GetPivot()
			m:PivotTo(b * CFrame.Angles(math.rad(-20), 0, 0)); task.delay(1.5, function() if m.Parent then m:PivotTo(b) end end) end end,
		ZenoArrive_GuardsBehind = function()
			for _, id in { "npc_zeno", "npc_zeno_future" } do
				local m = self.actors[id]; if m then local b = m:GetPivot(); m:PivotTo(b + Vector3.new(0, 12, 0))
					task.spawn(function() for i = 1, 20 do if not m.Parent then return end; m:PivotTo(b + Vector3.new(0, 12 * (1 - i / 20), 0)); task.wait(0.06) end end) end
			end
			for _, id in { "npc_zeno_guard_1", "npc_zeno_guard_2" } do
				local m = self.actors[id]; if m then local b = m:GetPivot(); m:PivotTo(b + Vector3.new(0, -12, 0))
					task.delay(1.4, function() for i = 1, 20 do if not m.Parent then return end; m:PivotTo(b + Vector3.new(0, -12 * (1 - i / 20), 0)); task.wait(0.05) end end) end
			end
		end,
		Wave = function(beat)
			local m = self.actors[beat.speaker]
			if m and m:GetAttribute("CastRig") then CastFigures.anim(m, "Wave") else wobble(beat.speaker, 12, 3) end
		end,
		Bounce = function(beat) hop(beat.speaker, 1.5, 3, 0.45) end,
		Clap = function(beat)
			local m = self.actors[beat.speaker]
			if m and m:GetAttribute("CastRig") then CastFigures.anim(m, "Clap"); hop(beat.speaker, 0.5, 4, 0.3); return end
			hop(beat.speaker, 0.8, 4, 0.3); wobble(beat.speaker, 6, 2)
		end,
		RingGlow = function()
			local ring = workspace:FindFirstChild("WorldOfVoid")
			local p = Instance.new("Part"); p.Shape = Enum.PartType.Cylinder; p.Anchored = true; p.CanCollide = false; p.CanQuery = false
			p.Size = Vector3.new(0.4, 300 * K + 6, 300 * K + 6); p.CFrame = CFrame.new(CENTER + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(140, 200, 255); p.Transparency = 1; p.Parent = ring or workspace
			addFx(p); tween(p, 1.5, { Transparency = 0.75 }, nil, true, 3)
		end,
		GodsKaisWatch = function() end, -- stand banners already show Universe numbers; subtitle carries the line
		TeleportTeams = function() end, -- server teleports teams during Intro state
		Countdown321 = function() end,
		SkyDark_BallsGather = function()
			local cc = addFx(Instance.new("ColorCorrectionEffect")) :: ColorCorrectionEffect
			cc.Name = "StorySky"; cc.Parent = Lighting
			tween(cc, 4, { Brightness = -0.25, Contrast = 0.2, TintColor = Color3.fromRGB(190, 170, 210) })
			local m = self.actor("super_dragon_balls"); if not m then return end
			if m:GetAttribute("Super") then
				-- planet-sized balls streak in from deep space and lock into the circle, then the circle turns slowly
				local homes: { [Model]: CFrame } = {}
				local slot: { [Model]: Vector3 } = {} -- each ball's place on the ring around Shenron (all seven evenly)
				for _, c in m:GetChildren() do
					if not c:IsA("Model") then continue end
					local home = c:GetPivot(); homes[c] = home
					local a = ((tonumber(string.match(c.Name, "%d+")) or 1) - 1) / 7 * math.pi * 2 + math.pi / 2
					slot[c] = Vector3.new(math.cos(a), 0, math.sin(a))
					local from = home + (home.Position - SDB_CF.Position).Unit * 900 * K + Vector3.new(0, 300 * K, -600 * K)
					c:PivotTo(from)
					task.spawn(function()
						for i = 1, 36 do
							if not c.Parent then return end
							c:PivotTo(from:Lerp(home, 1 - (1 - i / 36) ^ 3)); task.wait(0.1)
						end
					end)
				end
				-- when Shenron forms (attribute HaloCF / HaloRadius) the six-around-one formation opens into one great
				-- ring of all seven around him
				task.delay(3.8, function()
					local spin, ringCF, k = 0, SDB_CF, 0
					while m.Parent and not m:GetAttribute("Scatter") do
						spin += 0.004
						local halo = m:GetAttribute("HaloCF")
						if typeof(halo) == "CFrame" then
							ringCF = ringCF:Lerp(halo, 0.025)
							k += (1 - k) * 0.025
						end
						local haloR = (m:GetAttribute("HaloRadius") :: number?) or SDB_R
						for c, home in homes do
							local off = SDB_CF:ToObjectSpace(home)
							local pos = off.Position:Lerp(slot[c] * haloR, k)
							if c.Parent then c:PivotTo(ringCF * CFrame.Angles(0, spin, 0) * CFrame.new(pos) * off.Rotation) end
						end
						task.wait(1 / 30)
					end
				end)
				return
			end
			for _, c in m:GetChildren() do
				local b = c :: any; local base = if c:IsA("Model") then c:GetPivot() else (c :: BasePart).CFrame
				local start = base + Vector3.new(math.random(-80, 80), 120, math.random(-60, 0))
				task.spawn(function()
					for i = 0, 30 do
						if not c.Parent then return end
						local cf = start:Lerp(base, i / 30)
						if c:IsA("Model") then c:PivotTo(cf) else b.CFrame = cf end
						task.wait(0.12)
					end
				end)
			end
		end,
		BallsFlare = function()
			local m = self.actors.super_dragon_balls; if not m then return end
			if m:GetAttribute("Super") then
				for _, d in m:GetDescendants() do
					if d:IsA("PointLight") then tween(d, 1.2, { Brightness = 10 }) end
					if d:IsA("BasePart") and d.Name == "Core" then tween(d, 1.2, { Transparency = 0.3, Color = Color3.fromRGB(255, 196, 90) }) end
				end
				-- a ring of gold light joins the seven balls, then a pillar of light climbs into the sky
				local fx = addFx(Instance.new("Model")) :: Model; fx.Name = "SummonLight"; fx.Parent = workspace
				local n = 60
				for i = 1, n do
					local a0, a1 = (i - 1) / n * math.pi * 2, i / n * math.pi * 2
					local p0 = (SDB_CF * CFrame.new(math.cos(a0) * SDB_R, 0, math.sin(a0) * SDB_R)).Position
					local p1 = (SDB_CF * CFrame.new(math.cos(a1) * SDB_R, 0, math.sin(a1) * SDB_R)).Position
					local seg = Instance.new("Part"); seg.Name = "Ring"; seg.Material = Enum.Material.Neon; seg.Color = Color3.fromRGB(255, 214, 110)
					seg.Size = Vector3.new(3 * K, 3 * K, (p1 - p0).Magnitude + 1); seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1); seg.Transparency = 1
					seg.Parent = fx
					task.delay(0.3 + i / n * 0.9, function() if seg.Parent then tween(seg, 0.3, { Transparency = 0.1 }) end end)
				end
				local beam = Instance.new("Part"); beam.Name = "Pillar"; beam.Shape = Enum.PartType.Cylinder; beam.Material = Enum.Material.Neon
				beam.Color = Color3.fromRGB(255, 230, 160); beam.Transparency = 1; beam.Size = Vector3.new(10, SDB_R * 0.5, SDB_R * 0.5)
				local up = CFrame.new(SDB_CF.Position) * CFrame.Angles(0, 0, math.pi / 2) -- cylinder axis (X) -> world up
				beam.CFrame = up; beam.Parent = fx
				anchorAll(fx)
				task.delay(1.4, function()
					if not beam.Parent then return end
					flash(0.2)
					-- grows from the formation straight up into the sky
					tween(beam, 0.6, { Transparency = 0.15, Size = Vector3.new(4000, SDB_R * 0.5, SDB_R * 0.5), CFrame = up + Vector3.new(0, 2000, 0) })
					task.delay(2.6, function() if beam.Parent then tween(beam, 1.5, { Transparency = 1 }) end end)
				end)
				return
			end
			for _, l in m:GetDescendants() do if l:IsA("PointLight") then tween(l, 1, { Brightness = 8, Range = 40 }, nil, true, 2) end end
			for _, p in m:GetDescendants() do if p:IsA("BasePart") and p.Name == "Star" then tween(p, 0.6, { Size = Vector3.one * 4 }, nil, true, 4) end end
		end,
		RiseGold_RedEyes = function()
			local m = self.actor("npc_shenron"); if not m then return end
			local cf, size = m:GetBoundingBox()
			if m:GetAttribute("FocusOnHead") then
				-- built Super Shenron: too big to rise through the stage; it forms out of the light tail-first, then its
				-- own eyes ignite
				local balls = self.actors.super_dragon_balls
				if balls and balls:GetAttribute("Super") and m.PrimaryPart then
					local head = (m.PrimaryPart :: BasePart).Position
					-- a ring of all seven balls around Shenron's head and upper coils, facing the arena
					local c = head + Vector3.new(0, -110 * K, -200 * K)
					balls:SetAttribute("HaloCF", CFrame.lookAt(c, CENTER + Vector3.new(0, 0, 60 * K)) * CFrame.Angles(-math.pi / 2, 0, 0))
					balls:SetAttribute("HaloRadius", 400 * K)
				end
				for _, fx in self.fx do
					if fx.Name == "StorySky" then tween(fx, 3, { Brightness = -0.04, Contrast = 0.12 }) end
					if fx.Name == "SummonLight" then
						for _, p in fx:GetDescendants() do if p:IsA("BasePart") then tween(p, 2, { Transparency = 1 }) end end
					end
				end
				local aura = m:FindFirstChild("DivineGlow") :: Highlight?
				if aura then
					aura.Enabled = false
					task.delay(2.6, function() if aura.Parent then aura.Enabled = true end end)
				end
				local parts = {}
				for _, p in m:GetDescendants() do if p:IsA("BasePart") then table.insert(parts, p) end end
				for i, p in parts do
					local final = p.Transparency
					p.Transparency = 1
					task.delay(0.2 + 2.2 * i / #parts, function() if p.Parent then tween(p, 0.8, { Transparency = final }) end end)
				end
				for _, e in m:GetDescendants() do
					if e:IsA("BasePart") and e.Name == "Eye" then
						local red = e.Color
						e.Color = Color3.fromRGB(40, 6, 6)
						local l = e:FindFirstChildOfClass("PointLight")
						local glow = if l then l.Brightness else 0
						if l then l.Brightness = 0 end
						task.delay(3.5, function()
							if e == m:FindFirstChild("Eye", true) then flash(0.45) end
							tween(e, 1, { Color = red })
							if l then tween(l, 1, { Brightness = glow }) end
						end)
					end
				end
				return
			end
			local b = m:GetPivot(); m:PivotTo(b + Vector3.new(0, -160, 0))
			task.spawn(function() for i = 1, 40 do if not m.Parent then return end; m:PivotTo(b + Vector3.new(0, -160 * (1 - i / 40) ^ 2, 0)); task.wait(0.1) end end)
			for _, x in { -1, 1 } do
				local e = Instance.new("Part"); e.Name = "RedEye"; e.Shape = Enum.PartType.Ball; e.Anchored = true; e.CanCollide = false; e.CanQuery = false
				e.Material = Enum.Material.Neon; e.Color = Color3.fromRGB(255, 20, 20); e.Size = Vector3.one * 0.1
				e.CFrame = cf * CFrame.new(x * size.X * 0.04, size.Y * 0.42, size.Z * 0.45); e.Parent = m
				task.delay(3.5, function() tween(e, 1, { Size = Vector3.one * 5 }) end)
			end
		end,
		CameraShake = function()
			if player:GetAttribute("ReduceMotion") == true then return end
			task.spawn(function()
				local cam = workspace.CurrentCamera
				for i = 1, 40 do
					cam.CFrame = cam.CFrame * CFrame.new(math.random(-10, 10) / 25, math.random(-10, 10) / 25, 0); task.wait(0.03)
				end
			end)
		end,
		ShenronDissolve_BallsScatter = function()
			local s = self.actors.npc_shenron
			if s then for _, p in s:GetDescendants() do
				if p:IsA("BasePart") then tween(p, 3, { Transparency = 1 }) end
				if p:IsA("Highlight") then tween(p, 2, { FillTransparency = 1, OutlineTransparency = 1 }) end
			end end
			local m = self.actors.super_dragon_balls
			if m then m:SetAttribute("Scatter", true) end
			if m and m:GetAttribute("Super") then
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") and d.Name == "Orb" then tween(d, 1.2, { Color = Color3.fromRGB(128, 116, 104) }) end
					if d:IsA("BasePart") and d.Name == "Core" then tween(d, 1.2, { Transparency = 1 }) end
					if d:IsA("PointLight") then tween(d, 1.2, { Brightness = 0 }) end
					if d:IsA("TextLabel") then tween(d, 1.2, { TextColor3 = Color3.fromRGB(70, 40, 40) }) end
				end
				task.wait(1.2)
			end
			if m then for _, c in m:GetChildren() do
				local target = (if c:IsA("Model") then c:GetPivot() else (c :: BasePart).CFrame) + Vector3.new(math.random(-300, 300), 250, math.random(-300, 300))
				if c:IsA("BasePart") then tween(c, 2.5, { CFrame = target, Transparency = 1 }, Enum.EasingStyle.Quad)
				elseif c:IsA("Model") then task.spawn(function() local b = c:GetPivot() for i = 1, 25 do if not c.Parent then return end; c:PivotTo(b:Lerp(target, i / 25)); task.wait(0.1) end end) end
			end end
		end,
		-- v3 (db-story): both Zenos raise their hands (arms if the model has them, else a lift + glow)
		ZenosRaiseHands = function()
			for _, id in { "npc_zeno", "npc_zeno_future" } do
				local m = self.actors[id]; if not m then continue end
				if m:GetAttribute("CastRig") then CastFigures.anim(m, "RaiseHands"); continue end
				local raised = false
				for _, n in { "ArmL", "ArmR", "LeftUpperArm", "RightUpperArm" } do
					local a = m:FindFirstChild(n, true)
					if a and a:IsA("BasePart") then
						raised = true
						tween(a, 0.6, { CFrame = a.CFrame * CFrame.new(0, a.Size.Y * 0.6, 0) * CFrame.Angles(0, 0, math.rad(if n == "ArmL" or n == "LeftUpperArm" then -20 else 20)) })
					end
				end
				if not raised then hop(id, 1.2, 1, 0.8) end
				local cf, size = m:GetBoundingBox()
				local g = Instance.new("Part"); g.Shape = Enum.PartType.Ball; g.Anchored = true; g.CanCollide = false; g.CanQuery = false
				g.Material = Enum.Material.Neon; g.Color = Color3.fromRGB(220, 200, 255); g.Size = Vector3.one * 0.5; g.Transparency = 0.2
				g.CFrame = cf + Vector3.new(0, size.Y * 0.7, 0); g.Parent = workspace; addFx(g)
				tween(g, 1.2, { Size = Vector3.one * 3 }, nil, true, 1)
			end
		end,
		-- the losing universe's stand is swallowed by light, then the light fades away
		StandFadeToLight = function()
			local s = standPos(tonumber(self.vars.universeN))
			local orb = Instance.new("Part"); orb.Shape = Enum.PartType.Ball; orb.Anchored = true; orb.CanCollide = false; orb.CanQuery = false; orb.CanTouch = false
			orb.Material = Enum.Material.Neon; orb.Color = Color3.fromRGB(245, 240, 255); orb.Size = Vector3.one * 2; orb.Transparency = 0.1
			orb.CFrame = CFrame.new(s); orb.Parent = workspace; addFx(orb)
			local l = Instance.new("PointLight"); l.Range = 60; l.Brightness = 6; l.Color = Color3.fromRGB(235, 225, 255); l.Parent = orb
			local cc = addFx(Instance.new("ColorCorrectionEffect")) :: ColorCorrectionEffect
			cc.Name = "StoryEraseFlash"; cc.Parent = Lighting
			tween(orb, 1.4, { Size = Vector3.one * 70 * K }, Enum.EasingStyle.Quad)
			tween(cc, 1.4, { Brightness = 0.35, Saturation = -0.6 })
			task.delay(1.6, function()
				if orb.Parent then tween(orb, 1.4, { Transparency = 1, Size = Vector3.one * 90 * K }); tween(l, 1.4, { Brightness = 0 }) end
				if cc.Parent then tween(cc, 1.4, { Brightness = 0, Saturation = 0 }) end
			end)
		end,
		-- Universe Survival guest fighter drops in with a red pillar of light
		BossEntrance = function()
			local b = findBoss(self.vars.boss)
			local at = if b then b:GetPivot().Position else CENTER
			local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 60, 50); p.Size = Vector3.new(400, 14, 14); p.Shape = Enum.PartType.Cylinder
			p.CFrame = CFrame.new(at + Vector3.new(0, 200, 0)) * CFrame.Angles(0, 0, math.rad(90)); p.Transparency = 0.3; p.Parent = workspace; addFx(p)
			tween(p, 1.6, { Transparency = 1, Size = Vector3.new(400, 30, 30) })
			local cc = addFx(Instance.new("ColorCorrectionEffect")) :: ColorCorrectionEffect
			cc.Name = "StoryBossTint"; cc.Parent = Lighting
			tween(cc, 0.3, { TintColor = Color3.fromRGB(255, 200, 190), Contrast = 0.25 }, nil, true, 1)
		end,
		BossDefeatFlash = function()
			local cc = addFx(Instance.new("ColorCorrectionEffect")) :: ColorCorrectionEffect
			cc.Name = "StoryBossDown"; cc.Parent = Lighting
			tween(cc, 0.4, { Brightness = 0.3 }, nil, true, 1)
		end,
	}

	function self.cleanup()
		for _, m in self.actors do
			if m:GetAttribute("Persistent") then
				local home = m:GetAttribute("HomePivot")
				if typeof(home) == "CFrame" then m:PivotTo(home) end
				m:SetAttribute("HomePivot", nil)
				CastFigures.anim(m, "Rest")
			else
				m:Destroy()
			end
		end
		for _, f in self.fx do f:Destroy() end
		self.actors = {}; self.fx = {}
	end
	return self
end

-- Run a list of beats. ctx: { say, isAlive: () -> bool, story, team, onHook: (name, beat) -> () }
function D.play(dir: any, beats: { any }, ctx: any)
	local nUniverse = ctx.team and ctx.team:GetAttribute("Universe") or "?"
	local uinfo = ctx.story.Universes and ctx.story.Universes[tonumber(nUniverse) or -1]
	for _, beat in beats do
		if not ctx.isAlive() then return end
		for _, id in beat.actors or {} do dir.actor(id) end
		-- v10: ctx.shots (episode ShotLibrary moves) take precedence over the built-in ToP camera presets
		local shotFn = beat.cam and ((ctx.shots and ctx.shots[beat.cam]) or dir.cams[beat.cam])
		if shotFn and not ctx.noCamera then
			local ok, cf, t = pcall(shotFn, beat)
			if ok and cf then UIKit.tweenCamera(cf, t or 1.2) end
		end
		if beat.action and dir.actions[beat.action] then task.spawn(dir.actions[beat.action], beat) end
		-- v3: beat.pool = "<StoryDialogue pool>" picks a random line ({ speaker?, text } or string); ctx.vars fills {player}/{universe}/...
		local poolLine = beat.pool and D.pick(ctx.story[beat.pool])
		local rawText = beat.text or (poolLine and poolLine.text)
		if rawText and ctx.say then
			local speaker, text = (poolLine and poolLine.speaker) or beat.speaker, string.gsub(D.fill(rawText, ctx.vars), "{N}", tostring(nUniverse))
			if speaker == "God" and uinfo then speaker = uinfo.god end
			ctx.say(speaker, text)
		end
		task.wait((beat.duration or 3) + 0.4)
		if beat.speaker == "God" and uinfo and uinfo.line and ctx.say and ctx.isAlive() then
			ctx.say("Team", uinfo.line); task.wait(3)
		end
		if beat["then"] == "FriezaBanterIfApplicable" and ctx.friezaBanter and ctx.friezaBanter() then
			for _, l in ctx.story.FriezaBanter or {} do
				if not ctx.isAlive() then return end
				ctx.say(l.speaker, l.text); task.wait(l.duration + 0.3)
			end
		end
		if beat.triggersWishChoice and ctx.onHook then ctx.onHook("WishChoice", beat) end
		if beat.onEnd and ctx.onHook then ctx.onHook(beat.onEnd, beat) end
	end
end

-- ===== v3 (db-story): shared helpers for live ToP cinematics =====
-- The ever-present cast's placement (same as the cutscenes'): { [id] = { kind, cf, height, seated } }
function D.castLayout(): { [string]: { kind: string, cf: CFrame, height: number, seated: boolean } }
	readLayout()
	local out = {}
	for id, kind in CAST_KIND do
		local pos = SPOTS[id]
		if pos then
			out[id] = { kind = kind, cf = CFrame.lookAt(pos, pos + FACE), height = HEIGHT[id], seated = id == "npc_zeno" or id == "npc_zeno_future" }
		end
	end
	return out
end

function D.pick(pool: any): { speaker: string?, text: string }?
	if type(pool) ~= "table" or #pool == 0 then return nil end
	local e = pool[math.random(1, #pool)]
	if type(e) == "string" then return { text = e } end
	return e
end

function D.fill(text: string, vars: { [string]: any }?): string
	if not vars then return text end
	return (string.gsub(text, "{(%w+)}", function(k)
		local v = vars[k]
		return if v ~= nil then tostring(v) else nil -- unknown keys (e.g. {N}) are left for later passes
	end))
end

-- One skippable cinematic at a time. opts = { name, beats, story, team?, vars?, takeCamera?, letterbox?, maxSeconds?, onHook?, onDone?,
--   shots? (v10: { [camName]: (beat) -> (CFrame, tweenTime) }), canSkip? (v10: false hides Skip + ignores skip keys) }
-- Skip: on-screen button, Space / Enter / gamepad B. Every exit path (end, skip, watchdog, D.stopActive) runs the same
-- stop(): destroys actors + fx + gui, clears the InCinematic attribute and restores the player's camera.
local active: any = nil
function D.isPlaying(): boolean return active ~= nil end
function D.stopActive(skipped: boolean?) if active then active.stop(skipped == true) end end

function D.run(opts: any): any
	if active then active.stop(false) end
	local takeCamera = opts.takeCamera ~= false
	local run: any = {}
	local alive, finished = true, false
	local gui = UIKit.gui("Cinematic_" .. tostring(opts.name or "Story"), 21)
	if takeCamera and opts.letterbox ~= false then
		UIKit.frame(gui, UDim2.new(1, 0, 0.1, 0), UDim2.fromScale(0, 0), Color3.new(0, 0, 0), 0)
		UIKit.frame(gui, UDim2.new(1, 0, 0.1, 0), UDim2.fromScale(0, 0.9), Color3.new(0, 0, 0), 0)
	end
	local say = UIKit.subtitles(gui)
	local dir = D.new()
	dir.vars = opts.vars or {}
	local conns: { RBXScriptConnection } = {}
	local function stop(skipped: boolean)
		if finished then return end
		finished, alive = true, false
		if active == run then active = nil end
		for _, c in conns do c:Disconnect() end
		pcall(dir.cleanup)
		gui:Destroy()
		if takeCamera then
			player:SetAttribute("InCinematic", nil)
			UIKit.restoreCamera()
		end
		if opts.onDone then task.spawn(opts.onDone, skipped) end
	end
	run.stop = stop
	run.say = say
	run.gui = gui
	active = run
	local canSkip = opts.canSkip ~= false
	if canSkip then
		local skipBtn = UIKit.button(gui, "Skip ▶ (Space)", UDim2.new(0, 160, 0, 40), UDim2.new(1, -180, 0, 20), Color3.fromRGB(80, 30, 30))
		skipBtn.Name = "Skip"
		table.insert(conns, skipBtn.Activated:Connect(function() stop(true) end))
	end
	if takeCamera then
		-- keys only skip while we own the camera (a fighter still needs Space to jump during HUD-only cinematics)
		table.insert(conns, UserInputService.InputBegan:Connect(function(input)
			local k = input.KeyCode
			if canSkip and (k == Enum.KeyCode.Space or k == Enum.KeyCode.Return or k == Enum.KeyCode.ButtonB) then stop(true) end
		end))
		player:SetAttribute("InCinematic", true)
	end
	table.insert(conns, player.CharacterAdded:Connect(function() stop(false) end))
	task.delay(opts.maxSeconds or 30, function() stop(false) end) -- watchdog: never leave the camera stuck
	task.spawn(function()
		local ok, err = pcall(D.play, dir, opts.beats or {}, {
			say = say, story = opts.story or {}, team = opts.team, vars = opts.vars, noCamera = not takeCamera, shots = opts.shots,
			isAlive = function() return alive end, onHook = opts.onHook,
		})
		if not ok then warn("[CutsceneDirector] " .. tostring(opts.name) .. ": " .. tostring(err)) end
		if alive then task.wait(0.5) end
		stop(false)
	end)
	return run
end

return D
