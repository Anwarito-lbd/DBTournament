-- LocalScript (v10, HUD rebuilt v11): Legendary Episodes client. Visual + intent only: plays act cinematics
-- (CutsceneDirector + ShotLibrary), episode lighting, and the episode HUD on the v11 kit (UIStyle tokens +
-- ScreenManager zones): boss plate with story-beat notches, one-line goal, beat tracker, objective tracker, Bangers
-- callouts, clash tug-of-war and hold grip meters, KO and clear modals. Every decision (objectives, thresholds,
-- rewards) is the server's (ServerScriptService.Modules.StoryEpisodeService). Reduce Motion turns off shake / impact
-- frames / flashes / callout tilt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
local SM = require(Shared:WaitForChild("ScreenManager"))
if not S.remotes({ "EpisodeUpdate", "EpisodeInput", "CombatEvent" }, 20) then return end
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local StoryEpisodes = require(Shared:WaitForChild("StoryEpisodes"))
local ShotLibrary = require(Shared:WaitForChild("ShotLibrary"))
local CutsceneDirector = require(Shared:WaitForChild("CutsceneDirector"))
local VFXFolder = ReplicatedStorage:WaitForChild("VFX", 10)
local C: any = nil
do
	local m = VFXFolder and VFXFolder:FindFirstChild("VFXCommon")
	local ok, res = pcall(function() return m and require(m) end)
	if ok then C = res end
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Update = Remotes:WaitForChild("EpisodeUpdate") :: RemoteEvent
local Input = Remotes:WaitForChild("EpisodeInput") :: RemoteEvent
local player = Players.LocalPlayer

local fxFolder = Instance.new("Folder")
fxFolder.Name = "EpisodeFX"
fxFolder.Parent = workspace

-- ===== state =====
local current: any = nil -- last "act" cue
local actors: { [string]: Instance? } = {}
local anchor: CFrame = CFrame.new()
local cinematicRun: any = nil

local function reduceMotion(): boolean
	return player:GetAttribute("ReduceMotion") == true
end

-- ===== actor lookup (refs can arrive before replication; fall back to tags) =====
local function actor(role: string): Model?
	if role == "lead" then return player.Character end
	local ref = actors[role]
	if ref and ref.Parent and ref:IsA("Model") then return ref end
	for _, m in CollectionService:GetTagged("EpisodeActor") do
		if m:IsA("Model") and m.Parent and m:GetAttribute("OwnerId") == player.UserId and m:GetAttribute("Role") == role then
			actors[role] = m
			return m
		end
	end
	return nil
end
local function rootCF(m: Model?): CFrame?
	local r = m and m:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if r then r.CFrame else (m and m:GetPivot())
end

-- ===== lighting: storm grade, restored on exit =====
local LIGHTING = {
	StormCanyon = {
		-- readable storm: overcast sky (clouds), shadowed canyon floor still lit enough to read telegraphs and fighters
		props = { ClockTime = 17.4, Brightness = 2.2, Ambient = Color3.fromRGB(112, 102, 118), OutdoorAmbient = Color3.fromRGB(150, 136, 146),
			FogColor = Color3.fromRGB(110, 100, 106), FogStart = 160, FogEnd = 950 },
		cc = { Saturation = -0.15, Contrast = 0.12, Brightness = 0.02, TintColor = Color3.fromRGB(255, 236, 222) },
		clouds = { Cover = 0.86, Density = 0.62, Color = Color3.fromRGB(150, 142, 150) },
		rain = true,
	},
}
local savedLighting: { [string]: any }? = nil
local savedClouds: { [string]: any }? = nil -- Terrain.Clouds props before the episode ({} = we created the Clouds)
local clouds: Clouds? = nil
local cc: ColorCorrectionEffect? = nil
local rainPart: Part? = nil
local rainConn: RBXScriptConnection? = nil
local function applyLighting(name: string?)
	local preset = name and LIGHTING[name]
	if not preset or savedLighting then return end
	savedLighting = {}
	for k, v in preset.props do
		(savedLighting :: any)[k] = (Lighting :: any)[k]
		;(Lighting :: any)[k] = v
	end
	local e = Instance.new("ColorCorrectionEffect")
	e.Name = "EpisodeGrade"
	for k, v in preset.cc do (e :: any)[k] = v end
	e.Parent = Lighting
	cc = e
	if preset.clouds then
		local c = workspace.Terrain:FindFirstChildOfClass("Clouds")
		if c then
			local saved = {}
			for k in preset.clouds do saved[k] = (c :: any)[k] end
			savedClouds = saved
		else
			c = Instance.new("Clouds")
			savedClouds = {}
			c.Parent = workspace.Terrain
		end
		for k, v in preset.clouds do ((c :: Clouds) :: any)[k] = v end
		clouds = c
	end
	if preset.rain then
		local p = Instance.new("Part")
		p.Name = "EpisodeRain"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.Transparency = 1; p.Size = Vector3.new(90, 1, 90); p.Parent = fxFolder
		local em = Instance.new("ParticleEmitter")
		em.Rate = if reduceMotion() then 120 else 380
		em.Lifetime = NumberRange.new(0.9, 1.2); em.Speed = NumberRange.new(90, 110)
		em.EmissionDirection = Enum.NormalId.Bottom; em.SpreadAngle = Vector2.new(4, 4)
		em.Size = NumberSequence.new(0.06); em.Squash = NumberSequence.new(6)
		em.Transparency = NumberSequence.new(0.45); em.LightEmission = 0.2
		em.Color = ColorSequence.new(Color3.fromRGB(200, 205, 220)); em.Orientation = Enum.ParticleOrientation.VelocityParallel
		em.Parent = p
		rainPart = p
		rainConn = RunService.RenderStepped:Connect(function()
			local cam = workspace.CurrentCamera
			if cam and rainPart then rainPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 45, 0)) end
		end)
	end
end
local function restoreLighting()
	if savedLighting then
		for k, v in savedLighting do (Lighting :: any)[k] = v end
		savedLighting = nil
	end
	if cc then cc:Destroy(); cc = nil end
	if clouds and savedClouds then
		if next(savedClouds) == nil then clouds:Destroy() else for k, v in savedClouds do (clouds :: any)[k] = v end end
	end
	clouds, savedClouds = nil, nil
	if rainConn then rainConn:Disconnect(); rainConn = nil end
	if rainPart then rainPart:Destroy(); rainPart = nil end
end

-- ===== screen fx =====
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1); flash.BackgroundColor3 = Color3.new(1, 1, 1); flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0; flash.ZIndex = 50; flash.Parent = S.gui("StoryEpisodeFlash", 40)

local function meteor(pos: Vector3)
	local from = pos + Vector3.new(40, 160, 55)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball; ball.Size = Vector3.one * 4; ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 120, 150); ball.Anchored = true; ball.CanCollide = false; ball.CanQuery = false
	ball.CFrame = CFrame.new(from); ball.Parent = fxFolder
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.6, 0); a1.Position = Vector3.new(0, -1.6, 0); a0.Parent = ball; a1.Parent = ball
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.35; tr.LightEmission = 1
	tr.Color = ColorSequence.new(Color3.fromRGB(255, 220, 230), Color3.fromRGB(200, 40, 90)); tr.Parent = ball
	local tw = TweenService:Create(ball, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(pos) })
	tw:Play()
	tw.Completed:Wait()
	ball:Destroy()
	if C then
		local g = pos - Vector3.new(0, 3, 0)
		C.Shockwave(fxFolder, CFrame.new(g), 4, 50, Color3.fromRGB(255, 230, 220), 0.6, 0.6)
		C.GroundCrack(fxFolder, g, 16, 12, Color3.fromRGB(60, 45, 40), 6)
		C.DebrisBurst(fxFolder, g, 22, 55, Color3.fromRGB(140, 110, 90), 2.5)
		if not reduceMotion() then C.CameraShake(1.4, 0.6) end
	end
end

local function fx(name: string, _beat: any, pos: Vector3)
	local calm = reduceMotion()
	if name == "shake" then
		if C and not calm then C.CameraShake(0.9, 0.45) end
	elseif name == "impactFrame" then
		if C and not calm then C.ImpactFrame("invert", 2, nil) end
	elseif name == "speedLines" then
		if C and not calm then C.SpeedLines(1.1) end
	elseif name == "whiteOut" then
		flash.BackgroundTransparency = if calm then 0.6 else 0
		TweenService:Create(flash, TweenInfo.new(if calm then 0.6 else 1.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	elseif name == "meteor" then
		meteor(pos)
	end
end

-- ===== HUD (v11 kit: UIStyle tokens + ScreenManager zones; built per episode, torn down at the end) =====
local hud: any = nil -- widgets of the running episode
local firstRun = false -- first attempt at this episode: teach the counters with callouts
local teachBlocks = 0

local function goalText(def: any, act: any): string
	local boss = (def.boss and def.boss.name) or "the boss"
	if act.kind == "train" then
		return ("Spar with <font color=\"#FFC93C\">%s</font>"):format((def.spar and def.spar.name) or "your partner")
	elseif act.kind == "boss" then
		local u = act.untilHp
		local target = if u == 0.5 then "half health" elseif u then ("%d%% health"):format(math.floor(u * 100 + 0.5)) else "zero"
		return ("Bring %s to <font color=\"#FFC93C\">%s</font>"):format(boss, target)
	elseif act.kind == "clash" then
		return "Win the <font color=\"#FFC93C\">beam clash</font>"
	elseif act.kind == "hold" then
		return ("Hold %s for <font color=\"#FFC93C\">%d seconds</font>"):format(boss, (def.hold and def.hold.maxTime) or 7)
	end
	return ""
end

local function beatLabel(act: any): string
	if act.finisher then return "Finisher" end
	return ({ cinematic = "Story", train = "Training", boss = "Fight", clash = "Clash", hold = "Hold" } :: any)[act.kind] or "Story"
end

-- beats = non-bridge acts; a bridge act shows as the beat it leads into (or the last beat when nothing follows)
local function beatOf(def: any, index: number): (number, number, string)
	local beats = {}
	for i, a in def.acts do
		if not a.bridge then table.insert(beats, i) end
	end
	for b, i in beats do
		if i >= index then return b, #beats, beatLabel(def.acts[i]) end
	end
	return #beats, #beats, beatLabel(def.acts[beats[#beats]])
end

local function destroyHud()
	if not hud then return end
	for _, w in hud.widgets do w:Destroy() end
	if hud.conn then hud.conn:Disconnect() end
	hud = nil
end

local function buildHud(def: any)
	destroyHud()
	local h: any = { widgets = {}, def = def }
	local function own<T>(x: T): T table.insert(h.widgets, x :: any); return x end

	-- context: episode title (training / story beats) or the boss plate (fights), plus one goal line
	local title = own(S.text(SM.zone("context"), "title", def.title, { align = "Center" }))
	title.LayoutOrder = 1
	h.title = title

	local boss = own(Instance.new("Frame"))
	boss.Name = "BossPlate"
	boss.BackgroundTransparency = 1
	boss.Size = UDim2.new(1, 0, 0, 0)
	boss.AutomaticSize = Enum.AutomaticSize.Y
	boss.LayoutOrder = 2
	boss.Visible = false
	boss.Parent = SM.zone("context")
	S.stack(boss, "Y", 5)
	local cap = Instance.new("UISizeConstraint"); cap.MaxSize = Vector2.new(900, math.huge); cap.Parent = boss
	local head = Instance.new("Frame"); head.BackgroundTransparency = 1; head.Size = UDim2.new(1, 0, 0, 0); head.AutomaticSize = Enum.AutomaticSize.Y; head.Parent = boss
	S.stack(head, "X", 10)
	local bname = S.text(head, "title", (def.boss and def.boss.name) or "Boss", {}); bname.LayoutOrder = 1
	local bstroke = Instance.new("UIStroke"); bstroke.Color = S.C.ink; bstroke.Thickness = 2; bstroke.Parent = bname
	h.phase = S.text(head, "label", "PHASE 1", { font = S.F.bold, color = S.C.rareLight }); h.phase.LayoutOrder = 2
	h.pct = S.text(head, "body", "100%", { font = S.F.data })
	h.pct.LayoutOrder = 3
	local track, setBoss = S.meter(boss, { height = 16, gradient = { S.C.boss, S.C.danger }, trail = true })
	track.LayoutOrder = 2
	track.ClipsDescendants = false
	for _, a in def.acts do -- gold notches where the story turns (phase thresholds)
		if a.kind == "boss" and a.untilHp then
			local n = Instance.new("Frame")
			n.Name = "Notch"; n.BackgroundColor3 = S.C.gold; n.BorderSizePixel = 0; n.ZIndex = 4
			n.Size = UDim2.new(0, 3, 1, 6); n.Position = UDim2.new(a.untilHp, -1, 0, -3)
			n.Parent = track
		end
	end
	h.setBoss = setBoss
	h.boss = boss

	local goal = own(S.plate(SM.zone("context"), { auto = "XY", color = S.C.ink, alpha = 0.35, pad = 6, radius = 14 }))
	goal.LayoutOrder = 3
	h.goalText = S.text(goal, "body", "", { rich = true, font = S.F.bold })
	h.goal = goal

	-- ally: who is fighting with you and what they are doing
	if def.ally then
		local ally = own(S.plate(SM.zone("ally"), { auto = "XY", edge = S.C.hp, pad = 8 }))
		S.stack(ally, "Y", 1)
		S.text(ally, "lead", def.ally.name or "Ally", {}).LayoutOrder = 1
		h.allyStatus = S.text(ally, "caption", "Ready", { color = S.C.muted, font = S.F.bold })
		h.allyStatus.LayoutOrder = 2
		h.ally = ally
	end

	-- system: beat tracker, leave (two-step), motion toggle
	local sys = own(Instance.new("Frame"))
	sys.BackgroundTransparency = 1; sys.AutomaticSize = Enum.AutomaticSize.XY; sys.Size = UDim2.new(); sys.Parent = SM.zone("system")
	local sl = S.stack(sys, "Y", 6, "Right")
	sl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local pips = Instance.new("Frame"); pips.BackgroundTransparency = 1; pips.AutomaticSize = Enum.AutomaticSize.XY; pips.Size = UDim2.new(); pips.LayoutOrder = 1; pips.Parent = sys
	S.stack(pips, "X", 4)
	local _, total = beatOf(def, 1)
	h.pips = {}
	for i = 1, total do
		local p = Instance.new("Frame")
		p.Size = UDim2.new(0, 24, 0, 6); p.BorderSizePixel = 0; p.BackgroundColor3 = Color3.new(1, 1, 1); p.BackgroundTransparency = 0.82; p.LayoutOrder = i; p.Parent = pips
		S.corner(p, 3)
		h.pips[i] = p
	end
	h.beatText = S.text(sys, "caption", "", { color = S.C.muted, font = S.F.bold, align = "Right" })
	h.beatText.LayoutOrder = 2
	local armed = false
	local leave: TextButton
	leave = S.chip(sys, "Leave episode", nil, function()
		local lbl = leave:FindFirstChild("Label") :: TextLabel
		if not armed then
			armed = true
			lbl.Text = "Leave? No reward. Tap again"
			lbl.TextColor3 = S.C.gold
			task.delay(3, function() if lbl.Parent then armed = false; lbl.Text = "Leave episode"; lbl.TextColor3 = S.C.text end end)
			return
		end
		Input:FireServer("quit")
	end)
	leave.LayoutOrder = 3
	local motion: TextButton
	motion = S.chip(sys, if reduceMotion() then "Motion: reduced" else "Motion: full", nil, function()
		player:SetAttribute("ReduceMotion", not reduceMotion());
		(motion:FindFirstChild("Label") :: TextLabel).Text = if reduceMotion() then "Motion: reduced" else "Motion: full"
	end)
	motion.LayoutOrder = 4

	-- tracker: training checklist
	local obj = own(S.plate(SM.zone("tracker"), { size = UDim2.new(1, 0, 0, 0), auto = "Y", edge = S.C.orange }))
	obj.Visible = false
	S.stack(obj, "Y", 8)
	S.text(obj, "lead", "Training", {}).LayoutOrder = 0
	h.objRows = {}
	for i = 1, 4 do
		local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 0); row.AutomaticSize = Enum.AutomaticSize.Y; row.LayoutOrder = i; row.Visible = false; row.Parent = obj
		local box = Instance.new("Frame"); box.Name = "Box"; box.Size = UDim2.new(0, 14, 0, 14); box.Position = UDim2.new(0, 0, 0, 3); box.BackgroundColor3 = S.C.ink; box.BorderSizePixel = 0; box.Parent = row
		S.corner(box, 3)
		local bst = S.stroke(box, S.C.muted, 1.5)
		local t = S.text(row, "body", "", { wrap = true, auto = "Y", size = UDim2.new(1, -64, 0, 0) })
		t.Position = UDim2.new(0, 24, 0, 0)
		local n = S.text(row, "body", "", { font = S.F.data, color = S.C.muted, align = "Right", auto = "Y", size = UDim2.new(0, 40, 0, 0) })
		n.Position = UDim2.new(1, -40, 0, 0)
		h.objRows[i] = { row = row, box = box, stroke = bst, text = t, count = n }
	end
	h.obj = obj

	-- struggle: clash tug-of-war / hold grip, above the skill bar
	local st = own(Instance.new("Frame"))
	st.Name = "Struggle"; st.BackgroundTransparency = 1; st.Size = UDim2.new(1, 0, 0, 0); st.AutomaticSize = Enum.AutomaticSize.Y; st.Visible = false; st.Parent = SM.zone("struggle")
	S.stack(st, "Y", 10, "Center")
	local labels = Instance.new("Frame"); labels.BackgroundTransparency = 1; labels.Size = UDim2.new(1, 0, 0, S.px("lead") + 6); labels.LayoutOrder = 1; labels.Parent = st
	h.stLeft = S.text(labels, "lead", "", { color = S.C.orange })
	h.stMid = S.text(labels, "body", "", { font = S.F.data, color = S.C.muted, align = "Center" }); h.stMid.AnchorPoint = Vector2.new(0.5, 0); h.stMid.Position = UDim2.fromScale(0.5, 0)
	h.stRight = S.text(labels, "lead", "", { color = S.C.rareLight, align = "Right" }); h.stRight.AnchorPoint = Vector2.new(1, 0); h.stRight.Position = UDim2.fromScale(1, 0)
	for _, l in { h.stLeft, h.stMid, h.stRight } do -- legible over bright beam VFX
		local o = Instance.new("UIStroke"); o.Color = S.C.ink; o.Thickness = 2; o.Parent = l
	end
	h.stMid.TextColor3 = S.C.text
	-- tug: your beam (orange) from the left, his (violet) from the right, white seam where they meet
	local tug = Instance.new("Frame"); tug.Name = "Tug"; tug.Size = UDim2.new(1, 0, 0, 26); tug.BackgroundColor3 = S.C.ink; tug.BorderSizePixel = 0; tug.LayoutOrder = 2; tug.Parent = st
	S.corner(tug, 13)
	local ts = S.stroke(tug, Color3.new(1, 1, 1), 2); ts.Transparency = 0.7
	local me = Instance.new("Frame"); me.BorderSizePixel = 0; me.BackgroundColor3 = Color3.new(1, 1, 1); me.Size = UDim2.fromScale(0.5, 1); me.Parent = tug
	S.corner(me, 13)
	local mg = Instance.new("UIGradient"); mg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 179, 90)), ColorSequenceKeypoint.new(0.7, S.C.orange), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 243, 196)) }); mg.Parent = me
	local him = Instance.new("Frame"); him.BorderSizePixel = 0; him.BackgroundColor3 = Color3.new(1, 1, 1); him.AnchorPoint = Vector2.new(1, 0); him.Position = UDim2.fromScale(1, 0); him.Size = UDim2.fromScale(0.5, 1); him.Parent = tug
	S.corner(him, 13)
	local hg = Instance.new("UIGradient"); hg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 230, 255)), ColorSequenceKeypoint.new(0.35, S.C.rare), ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 21, 128)) }); hg.Parent = him
	local seam = Instance.new("Frame"); seam.BorderSizePixel = 0; seam.BackgroundColor3 = Color3.new(1, 1, 1); seam.AnchorPoint = Vector2.new(0.5, 0.5); seam.Position = UDim2.fromScale(0.5, 0.5); seam.Size = UDim2.new(0, 6, 1, 8); seam.ZIndex = 3; seam.Parent = tug
	h.tug, h.tugMe, h.tugHim, h.seam = tug, me, him, seam
	-- grip (hold): one meter + Piccolo's charge underneath
	local grip, setGrip = S.meter(st, { height = 22, color = S.C.orange, radius = 11 })
	grip.LayoutOrder = 3
	local charge, setCharge = S.meter(st, { height = 8, gradient = { Color3.fromRGB(150, 255, 110), Color3.fromRGB(230, 255, 210) }, radius = 4 })
	charge.LayoutOrder = 4
	h.grip, h.setGrip, h.charge, h.setCharge = grip, setGrip, charge, setCharge
	-- input prompt: MASH + key badge (keyboard) / the round MASH button (touch, help zone)
	local prompt = Instance.new("Frame"); prompt.BackgroundTransparency = 1; prompt.AutomaticSize = Enum.AutomaticSize.XY; prompt.Size = UDim2.new(); prompt.LayoutOrder = 5; prompt.Parent = st
	S.stack(prompt, "X", 12)
	local mashText = S.text(prompt, "h1", "MASH", { font = S.F.impact, color = S.C.gold }); mashText.LayoutOrder = 1
	local mst = Instance.new("UIStroke"); mst.Color = S.C.ink; mst.Thickness = 3; mst.Parent = mashText
	local bigKey = S.keyBadge(prompt, "V"); bigKey.LayoutOrder = 2; bigKey.TextSize = S.px("title"); bigKey:SetAttribute("TextRole", "title")
	h.promptHint = S.text(prompt, "body", "Press on the beat: it pushes three times harder", { color = S.C.muted, font = S.F.bold })
	h.promptHint.LayoutOrder = 3
	h.bigKey, h.struggle = bigKey, st

	-- touch: round MASH and BREAK FREE buttons in the right-thumb zone
	local mash = own(Instance.new("TextButton"))
	mash.Name = "Mash"; mash.Text = "MASH"; mash.Font = S.F.impact; mash.TextSize = S.px("h1"); mash:SetAttribute("TextRole", "h1")
	mash.TextColor3 = S.C.ink; mash.BackgroundColor3 = S.C.orange; mash.Size = UDim2.new(0, 132, 0, 132); mash.Visible = false; mash.LayoutOrder = 1
	mash.Parent = SM.zone("help")
	S.corner(mash, 66)
	S.stroke(mash, Color3.fromRGB(255, 179, 87), 3)
	mash.Activated:Connect(function() ClientAPI.struggleInput() end)
	local brk = own(Instance.new("TextButton"))
	brk.Name = "BreakFree"; brk.Text = "BREAK FREE"; brk.Font = S.F.display; brk.TextSize = S.px("lead"); brk:SetAttribute("TextRole", "lead")
	brk.TextColor3 = S.C.text; brk.BackgroundColor3 = S.C.rare; brk.Size = UDim2.new(0, 168, 0, 72); brk.Visible = false; brk.LayoutOrder = 2
	brk.Parent = SM.zone("help")
	S.corner(brk, 14)
	brk.Activated:Connect(function() ClientAPI.comboBreak() end)
	h.mashBtn, h.breakBtn = mash, brk

	-- live boss HP / phase
	h.conn = RunService.RenderStepped:Connect(function()
		if not current or not hud or not hud.boss.Visible then return end
		local m = actor("boss")
		local hum = m and m:FindFirstChildOfClass("Humanoid")
		if hum and hum.MaxHealth > 0 then
			local f = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			hud.setBoss(f)
			hud.pct.Text = ("%d%%"):format(math.floor(f * 100 + 0.5))
			if current.kind == "boss" then hud.phase.Text = ("PHASE %d"):format(tonumber((m :: Model):GetAttribute("Phase")) or 1) end
		end
	end)
	hud = h
end

local function showStruggle(kind: string?)
	if not hud then return end
	local on = kind ~= nil
	hud.struggle.Visible = on
	hud.tug.Visible = kind == "clash"
	hud.grip.Visible = kind == "hold"
	hud.charge.Visible = kind == "hold"
	local touch = S.device() == "Touch"
	hud.mashBtn.Visible = on and touch
	hud.bigKey.Text = S.keyFor("mash")
	hud.bigKey.Visible = on and S.keyFor("mash") ~= ""
	hud.promptHint.Visible = on and not touch
	if kind == "clash" then
		local def = hud.def
		hud.stLeft.Text = (def.clash and def.clash.beam == "Kamehameha" and "Kamehameha") or "Your beam"
		hud.stRight.Text = (def.boss and def.boss.name) or "Boss"
		hud.stRight.TextColor3 = S.C.rareLight
		hud.stMid.Text = ""
		hud.tugMe.Size = UDim2.fromScale(0.5, 1); hud.tugHim.Size = UDim2.fromScale(0.5, 1); hud.seam.Position = UDim2.fromScale(0.5, 0.5)
	elseif kind == "hold" then
		hud.stLeft.Text = "Grip"
		hud.stRight.Text = (hud.def.ally and (hud.def.ally.name .. " charging")) or "Charging"
		hud.stRight.TextColor3 = Color3.fromRGB(150, 255, 110)
		hud.stMid.Text = ""
		hud.setGrip(0.7); hud.setCharge(0)
	end
end

local function setFight(act: any, def: any)
	if not hud then return end
	local fight = act.kind == "boss" or act.kind == "clash" or act.kind == "hold"
	hud.title.Visible = not fight
	hud.boss.Visible = fight
	local g = goalText(def, act)
	hud.goalText.Text = g
	hud.goal.Visible = g ~= ""
	if act.kind == "clash" then hud.phase.Text = "BEAM CLASH" elseif act.kind == "hold" then hud.phase.Text = "PINNED" end
	if hud.allyStatus then
		hud.allyStatus.Text = if act.kind == "hold" then "Charging his finisher" elseif act.kind == "boss" and act.allyAssist then "Assisting" elseif act.kind == "train" then "Sparring with you" else "Ready"
	end
	local b, total, label = beatOf(def, current.index)
	for i, p in hud.pips do
		p.BackgroundColor3 = if i < b then S.C.gold elseif i == b then S.C.orange else Color3.new(1, 1, 1)
		p.BackgroundTransparency = if i <= b then 0 else 0.82
	end
	hud.beatText.Text = ("Beat %d of %d · %s"):format(b, total, label)
end

local function renderObjectives(list: { any }?)
	if not hud then return end
	hud.obj.Visible = list ~= nil
	for i, r in hud.objRows do
		local o = list and list[i]
		r.row.Visible = o ~= nil
		if o then
			local done = o.have >= o.need
			r.text.Text = o.text
			r.text.TextColor3 = if done then S.C.muted else S.C.text
			r.count.Text = if o.need > 1 then ("%d/%d"):format(o.have, o.need) else (if done then "1/1" else "0/1")
			r.box.BackgroundColor3 = if done then S.C.hp else S.C.ink
			r.stroke.Color = if done then S.C.hp else S.C.muted
		end
	end
end

-- guide highlight on the sparring partner (first attempt only)
local guideHL: Highlight? = nil
local function setGuide(on: boolean)
	if guideHL then guideHL:Destroy(); guideHL = nil end
	if not on then return end
	task.spawn(function()
		for _ = 1, 20 do
			local m = actor("spar")
			if m then
				local h = Instance.new("Highlight")
				h.FillTransparency = 1; h.OutlineColor = S.C.gold; h.Adornee = m; h.Parent = m
				guideHL = h
				return
			end
			task.wait(0.15)
		end
	end)
end

-- ===== modals (KO, clear): own the screen, hide the HUD, dim the world =====
local function modal(seconds: number, build: (Frame) -> ())
	local layer = SM.layer("Modal")
	local dim = Instance.new("Frame")
	dim.Name = "EpisodeModal"; dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = S.C.ink; dim.BackgroundTransparency = 1; dim.BorderSizePixel = 0; dim.Parent = layer
	TweenService:Create(dim, S.FAST, { BackgroundTransparency = 0.35 }):Play()
	local col = Instance.new("Frame"); col.BackgroundTransparency = 1; col.AnchorPoint = Vector2.new(0.5, 0.5); col.Position = UDim2.fromScale(0.5, 0.42); col.AutomaticSize = Enum.AutomaticSize.XY; col.Size = UDim2.new(); col.Parent = dim
	S.stack(col, "Y", 14, "Center")
	build(col)
	local sc = Instance.new("UIScale"); sc.Parent = col
	if not reduceMotion() then sc.Scale = 0.8; TweenService:Create(sc, S.POP, { Scale = 1 }):Play() end
	SM.hideHud("modal", true)
	task.delay(seconds, function()
		SM.hideHud("modal", false)
		if dim.Parent then dim:Destroy() end
	end)
end

local function bigCallout(parent: Instance, text: string, top: Color3, mid: Color3, bottom: Color3, order: number)
	local t = S.text(parent, "callout", text, { color = Color3.new(1, 1, 1), align = "Center" })
	t.LayoutOrder = order
	t.Rotation = if reduceMotion() then 0 else -3
	local g = Instance.new("UIGradient"); g.Rotation = 90
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, top), ColorSequenceKeypoint.new(0.5, mid), ColorSequenceKeypoint.new(1, bottom) })
	g.Parent = t
	local st = Instance.new("UIStroke"); st.Color = S.C.ink; st.Thickness = 5; st.Parent = t
	return t
end

local function koCard(deaths: number)
	modal(3.2, function(col)
		bigCallout(col, "K.O.", Color3.fromRGB(255, 160, 150), S.C.danger, S.C.boss, 1)
		S.text(col, "lead", "Back to the last checkpoint", { align = "Center" }).LayoutOrder = 2
		S.text(col, "body", ("Attempt %d"):format(deaths + 1), { color = S.C.muted, font = S.F.bold, align = "Center" }).LayoutOrder = 3
	end)
end

local function clearCard(cue: any)
	local def = StoryEpisodes.BY_ID[cue.episode]
	modal(5, function(col)
		if cue.first then
			local badge = S.text(col, "label", "  FIRST CLEAR  ", { font = S.F.data, color = S.C.ink, align = "Center" })
			badge.BackgroundColor3 = S.C.gold; badge.BackgroundTransparency = 0; badge.LayoutOrder = 1
			S.corner(badge, 4)
		end
		bigCallout(col, "EPISODE CLEAR!", S.C.goldLight, S.C.gold, S.C.orange, 2)
		S.text(col, "title", def and def.title or "", { align = "Center" }).LayoutOrder = 3
		local r = cue.rewards
		if r then
			local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.AutomaticSize = Enum.AutomaticSize.XY; row.Size = UDim2.new(); row.LayoutOrder = 4; row.Parent = col
			S.stack(row, "X", 10)
			local function tile(value: string, label: string, small: boolean?, order: number)
				local t = S.plate(row, { size = UDim2.new(0, 190, 0, 0), auto = "Y", pad = 14 })
				t.LayoutOrder = order
				S.stack(t, "Y", 2, "Center")
				S.text(t, if small then "lead" else "h1", value, { color = if small then S.C.text else S.C.gold, align = "Center" }).LayoutOrder = 1
				S.text(t, "caption", label, { color = S.C.muted, font = S.F.bold, align = "Center" }).LayoutOrder = 2
			end
			tile(("+%d"):format(r.xp or 0), "XP", false, 1)
			tile(("+%d"):format(r.zeni or 0), "ZENI", false, 2)
			if r.title then tile(r.title, "NEW TITLE", true, 3) end
		end
		local t = cue.time or 0
		S.text(col, "body", ("Time %d:%02d   ·   K.O.s %d"):format(t // 60, t % 60, (current and current.deaths) or 0), { font = S.F.data, color = S.C.muted, align = "Center" }).LayoutOrder = 5
		S.text(col, "caption", "Returning to the lobby", { color = S.C.muted, font = S.F.bold, align = "Center" }).LayoutOrder = 6
	end)
end

-- ===== cinematics =====
local function playCinematic(cue: any)
	local def = StoryEpisodes.BY_ID[cue.episode]
	local act = def and def.acts[cue.index]
	if not act then Input:FireServer("ready", cue.index); return end
	local beats = act.beats
	if cue.summary then -- repeat runs: one short summary card instead of the full scene
		beats = { { cam = "establishingWide", subject = "anchor", duration = 2.2, speaker = "Story", text = cue.summary } }
	end
	local alive = true
	local shots = ShotLibrary.build({
		anchor = anchor,
		subject = function(role: string) return rootCF(actor(role)) end,
		fx = fx,
		alive = function() return alive end,
	})
	showStruggle(nil)
	cinematicRun = CutsceneDirector.run({
		name = "Episode_" .. tostring(act.id), beats = beats, shots = shots, canSkip = cue.canSkip == true,
		maxSeconds = (act.maxSeconds or 10) + 2, letterbox = true,
		onDone = function()
			alive = false
			cinematicRun = nil
			if current and current.index == cue.index then Input:FireServer("ready", cue.index) end
		end,
	})
end

local function stopEpisode()
	if cinematicRun then pcall(cinematicRun.stop, false); cinematicRun = nil end
	current = nil
	table.clear(actors)
	setGuide(false)
	restoreLighting()
	destroyHud()
end

-- ===== server cues =====
Update.OnClientEvent:Connect(function(cue: any)
	if type(cue) ~= "table" then return end
	if cue.cue == "act" then
		local def = StoryEpisodes.BY_ID[cue.episode]
		if not def then return end
		if not hud or hud.def ~= def then
			buildHud(def)
			firstRun = cue.index == 1 and cue.canSkip ~= true
			teachBlocks = if firstRun then 3 else 0
		end
		current = cue
		anchor = if typeof(cue.anchor) == "CFrame" then cue.anchor else anchor
		for role, ref in (cue.actors or {}) :: any do actors[role] = ref end
		applyLighting(cue.lighting)
		local act = def.acts[cue.index]
		setFight(act, def)
		showStruggle(nil)
		setGuide(cue.kind == "train" and cue.guide == true)
		renderObjectives(if cue.kind == "train" then cue.objectives else nil)
		if cue.kind == "cinematic" then
			playCinematic(cue)
		elseif cue.kind == "clash" or cue.kind == "hold" then
			showStruggle(cue.kind)
			SM.callout(if cue.kind == "clash" then "CLASH!" else "HOLD HIM!", { duration = 0.9, replace = true })
		end
	elseif cue.cue == "objectives" then
		renderObjectives(cue.objectives)
		if cue.done then setGuide(false); SM.callout("TRAINING DONE!", { duration = 1.1, scale = 0.8 }) end
	elseif cue.cue == "struggleResult" then
		showStruggle(nil)
		if cue.result == "win" then
			SM.callout(if cue.mode == "hold" then "NOW, PICCOLO!" else "OVERPOWERED!", { duration = 1.2, replace = true })
		elseif cue.result == "lose" then
			SM.callout(if cue.mode == "hold" then "HE BROKE FREE!" else "PUSHED BACK!", {
				sub = if cue.mode == "hold" then "Wear him down: the hold comes back" else "Brace and go again",
				top = Color3.fromRGB(255, 160, 150), mid = S.C.danger, bottom = S.C.boss, duration = 1.4, replace = true,
			})
		end
	elseif cue.cue == "ko" then
		showStruggle(nil)
		if cinematicRun then pcall(cinematicRun.stop, false) end
		koCard(cue.deaths or 1)
	elseif cue.cue == "end" then
		if cue.result == "clear" then
			clearCard(cue)
		elseif cue.result == "quit" then
			SM.callout("LEFT EPISODE", { sub = "No reward this time", scale = 0.6, top = S.C.text, mid = S.C.muted, bottom = S.C.muted })
		end
		stopEpisode()
	elseif cue.cue == "error" then
		SM.callout("LOCKED", { sub = if cue.error == "Locked" then "Clear the previous episode first" else tostring(cue.error), scale = 0.6 })
	end
end)

-- ===== combat events: telegraph flashes, callouts, clash/hold meters =====
local function flashModel(m: Model, seconds: number, color: Color3)
	local h = Instance.new("Highlight")
	h.FillColor = color; h.FillTransparency = 0.55; h.OutlineColor = Color3.new(1, 1, 1); h.Adornee = m
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = m
	TweenService:Create(h, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FillTransparency = 0.05 }):Play()
	task.delay(seconds + 0.12, function() h:Destroy() end)
end

local function beatPulse()
	if not hud or not hud.tug.Visible then return end
	local r = hud.seam:FindFirstChild("Pulse") :: Frame?
	if not r then
		local nr = Instance.new("Frame")
		nr.Name = "Pulse"; nr.BackgroundTransparency = 1; nr.AnchorPoint = Vector2.new(0.5, 0.5); nr.Position = UDim2.fromScale(0.5, 0.5); nr.ZIndex = 4
		nr.Parent = hud.seam
		S.corner(nr, 999)
		S.stroke(nr, S.C.gold, 3)
		r = nr
	end
	local ring = r :: Frame
	local s = ring:FindFirstChildOfClass("UIStroke") :: UIStroke
	-- the ring flashes on the rhythm beat: presses landing now count triple
	ring.Size = UDim2.fromOffset(30, 30)
	s.Transparency = 0
	if reduceMotion() then task.delay(0.15, function() s.Transparency = 1 end); return end
	TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(68, 68) }):Play()
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
end

ClientAPI.onCombatEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	if kind == "BossWindup" then
		-- any boss telegraphing a melee at ME (story, raids): the flash = block now for a parry
		local m = data[1]
		if data[2] == player.UserId and typeof(m) == "Instance" and m:IsA("Model") then
			flashModel(m, math.max(0.15, (tonumber(data[3]) or 0.4) - 0.05), Color3.fromRGB(255, 60, 60))
			if current and teachBlocks > 0 and (current.kind == "train" or current.kind == "boss") then
				teachBlocks -= if current.kind == "boss" then 1 else 0
				SM.callout("BLOCK!", { sub = "on the flash to parry", key = S.keyFor("block"), duration = 0.55, replace = true })
			end
		end
	elseif not current then
		return
	elseif kind == "Parry" and data[1] == player.UserId then
		if C and not reduceMotion() then C.ImpactFrame("invert", 1, nil) end
		SM.callout("PARRY!", { scale = 0.75, duration = 0.6, top = S.C.ki2, mid = S.C.ki, bottom = S.C.blue })
	elseif kind == "BossSpecial" and data[2] == "Grab" and data[3] == player.UserId then
		if hud then hud.breakBtn.Visible = S.device() == "Touch" end
		SM.callout("GRABBED!", { sub = "Break free", key = S.keyFor("breaker"), duration = tonumber(data[4]) or 1.6, replace = true,
			top = Color3.fromRGB(230, 200, 255), mid = S.C.rare, bottom = Color3.fromRGB(90, 30, 150) })
		task.delay(tonumber(data[4]) or 1.6, function() if hud then hud.breakBtn.Visible = false end end)
	elseif kind == "BossSpecial" and (data[2] == "GrabEscape" or data[2] == "GrabSlam") and data[3] == player.UserId then
		if hud then hud.breakBtn.Visible = false end
		if data[2] == "GrabEscape" then SM.callout("ESCAPED!", { scale = 0.75, duration = 0.7, replace = true, top = Color3.fromRGB(200, 255, 220), mid = S.C.hp, bottom = Color3.fromRGB(20, 130, 70) }) end
	elseif kind == "StrugglePulse" and data[1] == player.UserId and current.kind == "clash" and hud then
		local win = (current.clash and current.clash.winScore) or 30
		local f = math.clamp(0.5 + (tonumber(data[3]) or 0) / (2 * win), 0.04, 0.96)
		local ti = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
		TweenService:Create(hud.tugMe, ti, { Size = UDim2.fromScale(f, 1) }):Play()
		TweenService:Create(hud.tugHim, ti, { Size = UDim2.fromScale(1 - f, 1) }):Play()
		TweenService:Create(hud.seam, ti, { Position = UDim2.fromScale(f, 0.5) }):Play()
		local left = math.max(0, ((current.clash and current.clash.maxTime) or 6) - (tonumber(data[4]) or 0))
		hud.stMid.Text = ("%.1f s"):format(left)
		beatPulse()
	elseif kind == "HoldPulse" and data[1] == player.UserId and current.hold and hud then
		local cfg = current.hold
		local score, elapsed = tonumber(data[3]) or 0, tonumber(data[4]) or 0
		hud.setGrip((score + cfg.winScore) / (2 * cfg.winScore))
		local fill = hud.grip:FindFirstChild("Fill") :: Frame
		fill.BackgroundColor3 = if score < -cfg.winScore * 0.5 then S.C.danger else S.C.orange
		hud.setCharge(elapsed / cfg.maxTime)
		hud.stMid.Text = ("%.1f s"):format(math.max(0, cfg.maxTime - elapsed))
	elseif (kind == "HoldEnd" or kind == "StruggleEnd") and hud then
		hud.mashBtn.Visible = false
	end
end)

S.deviceChanged:Connect(function()
	if hud and hud.struggle.Visible then showStruggle(if hud.tug.Visible then "clash" else "hold") end
end)

player.CharacterAdded:Connect(function()
	actors.lead = nil
	if hud then hud.breakBtn.Visible = false end
end)
