-- LocalScript (v10): Legendary Episodes client. Visual + intent only: plays act cinematics (CutsceneDirector +
-- ShotLibrary), episode lighting, objective checklist, boss HP bar, clash / hold meters, parry flashes, grab escape
-- prompt, KO and chapter-clear cards. Every decision (objectives, thresholds, rewards) is the server's
-- (ServerScriptService.Modules.StoryEpisodeService). Reduce Motion (HUD toggle) turns off shake / impact frames / flashes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
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

local gui = S.gui("StoryEpisodeHUD", 22)
gui.Enabled = false
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
		props = { ClockTime = 17.4, Brightness = 1.3, Ambient = Color3.fromRGB(85, 76, 92), OutdoorAmbient = Color3.fromRGB(110, 95, 104),
			FogColor = Color3.fromRGB(92, 82, 88), FogStart = 140, FogEnd = 950 },
		cc = { Saturation = -0.18, Contrast = 0.18, Brightness = -0.03, TintColor = Color3.fromRGB(255, 232, 214) },
		rain = true,
	},
}
local savedLighting: { [string]: any }? = nil
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

-- ===== HUD =====
local top = S.label(gui, "", UDim2.new(0.5, 0, 0, 28), UDim2.new(0.25, 0, 0, 10), S.GOLD, S.FONT_TITLE)
local actLabel = S.label(gui, "", UDim2.new(0.4, 0, 0, 20), UDim2.new(0.3, 0, 0, 40), S.MUTED)

local objFrame = Instance.new("Frame")
objFrame.Size = UDim2.new(0, 330, 0, 120); objFrame.Position = UDim2.new(0, 16, 0.28, 0)
objFrame.BackgroundColor3 = S.DARK; objFrame.BackgroundTransparency = 0.25; objFrame.BorderSizePixel = 0; objFrame.Visible = false
objFrame.Parent = gui
S.corner(objFrame, 10); S.stroke(objFrame, S.GOLD, 1)
local objTitle = S.label(objFrame, "TRAINING", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 4), S.GOLD, S.FONT_TITLE)
objTitle.TextXAlignment = Enum.TextXAlignment.Left
local objRows: { TextLabel } = {}
for i = 1, 4 do
	local l = S.label(objFrame, "", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 4 + i * 24), Color3.new(1, 1, 1), S.FONT_BODY)
	l.TextXAlignment = Enum.TextXAlignment.Left
	objRows[i] = l
end

local function bar(name: string, pos: UDim2, size: UDim2, color: Color3): (Frame, Frame, TextLabel)
	local bg = Instance.new("Frame")
	bg.Name = name; bg.Size = size; bg.Position = pos; bg.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	bg.BackgroundTransparency = 0.2; bg.BorderSizePixel = 0; bg.Visible = false; bg.Parent = gui
	S.corner(bg, 6); S.stroke(bg, Color3.fromRGB(0, 0, 0), 2)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1); fill.BackgroundColor3 = color; fill.BorderSizePixel = 0; fill.Parent = bg
	S.corner(fill, 6)
	local l = S.label(bg, name, UDim2.fromScale(1, 1), UDim2.new(), Color3.new(1, 1, 1), S.FONT)
	l.ZIndex = 3
	return bg, fill, l
end
local bossBg, bossFill, bossText = bar("BOSS", UDim2.new(0.25, 0, 0, 66), UDim2.new(0.5, 0, 0, 22), Color3.fromRGB(210, 40, 70))
local gripBg, gripFill, gripText = bar("GRIP", UDim2.new(0.3, 0, 0.66, 0), UDim2.new(0.4, 0, 0, 22), Color3.fromRGB(255, 170, 40))
local chargeBg, chargeFill, chargeText = bar("PICCOLO CHARGE", UDim2.new(0.3, 0, 0.66, 28), UDim2.new(0.4, 0, 0, 16), Color3.fromRGB(150, 255, 110))
local clashBg, clashFill, clashText = bar("CLASH", UDim2.new(0.3, 0, 0.66, 0), UDim2.new(0.4, 0, 0, 22), Color3.fromRGB(120, 200, 255))

local prompt = S.label(gui, "", UDim2.new(0.5, 0, 0, 40), UDim2.new(0.25, 0, 0.56, 0), S.GOLD, S.FONT_TITLE)
prompt.TextStrokeTransparency = 0
local function setPrompt(text: string?)
	prompt.Text = text or ""
end

local mashBtn = S.button(gui, "MASH!", UDim2.new(0, 120, 0, 120), UDim2.new(1, -150, 0.5, -60), Color3.fromRGB(150, 30, 30), function()
	ClientAPI.struggleInput()
end)
mashBtn.Visible = false
S.corner(mashBtn, 60)
local breakBtn = S.button(gui, "BREAK FREE", UDim2.new(0, 130, 0, 70), UDim2.new(1, -160, 0.5, 70), Color3.fromRGB(120, 40, 160), function()
	ClientAPI.comboBreak()
end)
breakBtn.Visible = false

local quitArmed = false
local quitBtn: TextButton
quitBtn = S.button(gui, "Leave episode", UDim2.new(0, 150, 0, 34), UDim2.new(1, -166, 0, 12), Color3.fromRGB(70, 30, 30), function()
	if not quitArmed then
		quitArmed = true
		quitBtn.Text = "Tap again: no reward"
		task.delay(3, function() quitArmed = false; quitBtn.Text = "Leave episode" end)
		return
	end
	Input:FireServer("quit")
end)
local motionBtn: TextButton
motionBtn = S.button(gui, "Reduce motion: OFF", UDim2.new(0, 170, 0, 30), UDim2.new(1, -186, 0, 52), S.BLUE, function()
	player:SetAttribute("ReduceMotion", not reduceMotion())
	motionBtn.Text = "Reduce motion: " .. (if reduceMotion() then "ON" else "OFF")
end)

local function hideMeters()
	gripBg.Visible, chargeBg.Visible, clashBg.Visible = false, false, false
	mashBtn.Visible = false
	setPrompt(nil)
end

local function renderObjectives(list: { any }?)
	objFrame.Visible = list ~= nil
	for i, row in objRows do
		local o = list and list[i]
		if o then
			local done = o.have >= o.need
			row.Text = (if done then "✔  " else "•  ") .. o.text .. (if o.need > 1 then ("  (%d/%d)"):format(o.have, o.need) else "")
			row.TextColor3 = if done then S.GREEN else Color3.new(1, 1, 1)
		else
			row.Text = ""
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
				h.FillTransparency = 1; h.OutlineColor = S.GOLD; h.Adornee = m; h.Parent = m
				guideHL = h
				return
			end
			task.wait(0.15)
		end
	end)
end

-- boss HP bar (reads the replicated Humanoid)
RunService.RenderStepped:Connect(function()
	if not current or not gui.Enabled then return end
	local k = current.kind
	local m = if k == "train" then nil else actor("boss")
	local h = m and m:FindFirstChildOfClass("Humanoid")
	bossBg.Visible = h ~= nil and (k == "boss" or k == "clash" or k == "hold")
	if h and h.MaxHealth > 0 then
		local f = math.clamp(h.Health / h.MaxHealth, 0, 1)
		bossFill.Size = UDim2.fromScale(f, 1)
		bossText.Text = string.upper(m.Name) .. ("   %d%%"):format(math.floor(f * 100 + 0.5))
	end
end)

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
	objFrame.Visible = false
	hideMeters()
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

local function card(title: string, lines: { string }, color: Color3, seconds: number)
	local panel = S.panel(gui, 0.4, 0.34, 520, 300)
	local t = S.label(panel, title, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, 14), color, S.FONT_TITLE)
	t.TextStrokeTransparency = 0
	;(t:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint).MaxTextSize = 40
	for i, line in lines do
		S.label(panel, line, UDim2.new(1, -24, 0, 26), UDim2.new(0, 12, 0, 50 + i * 30), Color3.new(1, 1, 1), S.FONT_BODY)
	end
	panel.Size = UDim2.fromScale(0, 0)
	TweenService:Create(panel, S.POP, { Size = UDim2.fromScale(if S.MOBILE then 0.6 else 0.4, if S.MOBILE then 0.4 else 0.34) }):Play()
	task.delay(seconds, function() if panel.Parent then panel:Destroy() end end)
end

local function stopEpisode()
	if cinematicRun then pcall(cinematicRun.stop, false); cinematicRun = nil end
	current = nil
	table.clear(actors)
	setGuide(false)
	hideMeters()
	breakBtn.Visible = false
	renderObjectives(nil)
	bossBg.Visible = false
	restoreLighting()
	task.delay(5.5, function() if not current then gui.Enabled = false end end)
end

-- ===== server cues =====
Update.OnClientEvent:Connect(function(cue: any)
	if type(cue) ~= "table" then return end
	if cue.cue == "act" then
		current = cue
		gui.Enabled = true
		anchor = if typeof(cue.anchor) == "CFrame" then cue.anchor else anchor
		for role, ref in (cue.actors or {}) :: any do actors[role] = ref end
		applyLighting(cue.lighting)
		local def = StoryEpisodes.BY_ID[cue.episode]
		top.Text = def and string.upper(def.title) or ""
		actLabel.Text = ("Act %d / %d"):format(cue.index, cue.total)
		hideMeters()
		setGuide(cue.kind == "train" and cue.guide == true)
		if cue.kind == "cinematic" then
			playCinematic(cue)
		elseif cue.kind == "train" then
			renderObjectives(cue.objectives)
			setPrompt(if cue.guide then "Piccolo wants a real spar. Show him!" else nil)
			task.delay(3, function() if current == cue then setPrompt(nil) end end)
		else
			renderObjectives(nil)
			if cue.kind == "clash" then
				clashBg.Visible = true
				clashFill.Size = UDim2.fromScale(0.5, 1)
				setPrompt(if S.MOBILE then "MASH to push the beam!" else "MASH [V] to push the beam!")
			elseif cue.kind == "hold" then
				gripBg.Visible, chargeBg.Visible = true, true
				gripFill.Size = UDim2.fromScale(0.7, 1); chargeFill.Size = UDim2.fromScale(0, 1)
				setPrompt(if S.MOBILE then "HOLD HIM! Mash to keep your grip!" else "HOLD HIM! Mash [V] to keep your grip!")
			end
		end
	elseif cue.cue == "objectives" then
		renderObjectives(cue.objectives)
		if cue.done then setGuide(false); S.toast(gui, "Training complete!", S.GREEN) end
	elseif cue.cue == "struggleResult" then
		hideMeters()
		if cue.result == "win" then
			S.toast(gui, if cue.mode == "hold" then "He's pinned! NOW, PICCOLO!" else "You overpowered him!", S.GOLD)
		elseif cue.result == "lose" then
			S.toast(gui, if cue.mode == "hold" then "He broke free! Wear him down again!" else "Pushed back! Brace and try again!", S.RED)
		end
	elseif cue.cue == "ko" then
		hideMeters()
		if cinematicRun then pcall(cinematicRun.stop, false) end
		card("K.O.", { "Back to the last checkpoint.", ("Attempts: %d"):format(cue.deaths or 1) }, S.RED, 3.5)
	elseif cue.cue == "end" then
		local result = cue.result
		if result == "clear" then
			local r = cue.rewards
			local lines = { ("Time  %d:%02d"):format((cue.time or 0) // 60, (cue.time or 0) % 60) }
			if r then
				table.insert(lines, ("+%d XP   +%d Zeni"):format(r.xp or 0, r.zeni or 0))
				if r.title then table.insert(lines, "Title unlocked: " .. r.title) end
			end
			if cue.first then table.insert(lines, "FIRST CLEAR!") end
			card("EPISODE CLEAR", lines, S.GOLD, 5)
		elseif result == "quit" then
			S.toast(gui, "Episode abandoned. No reward.", S.MUTED)
		end
		stopEpisode()
	elseif cue.cue == "error" then
		gui.Enabled = true
		S.toast(gui, if cue.error == "Locked" then "Clear the previous episode first." else tostring(cue.error), S.RED)
		task.delay(3, function() if not current then gui.Enabled = false end end)
	end
end)

-- ===== combat events: parry flashes, grab, clash/hold meters =====
local function flashModel(m: Model, seconds: number, color: Color3)
	local h = Instance.new("Highlight")
	h.FillColor = color; h.FillTransparency = 0.55; h.OutlineColor = Color3.new(1, 1, 1); h.Adornee = m
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = m
	TweenService:Create(h, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FillTransparency = 0.05 }):Play()
	task.delay(seconds + 0.12, function() h:Destroy() end)
end

ClientAPI.onCombatEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	if kind == "BossWindup" then
		-- any boss telegraphing a melee at ME (story, raids): the flash = block now for a parry
		local m = data[1]
		if data[2] == player.UserId and typeof(m) == "Instance" and m:IsA("Model") then
			flashModel(m, math.max(0.15, (tonumber(data[3]) or 0.4) - 0.05), Color3.fromRGB(255, 60, 60))
			if current and current.kind == "train" and current.guide then
				setPrompt(if S.MOBILE then "BLOCK NOW!" else "BLOCK NOW! [F]")
				task.delay(0.8, function() if current and current.kind == "train" then setPrompt(nil) end end)
			end
		end
	elseif not current then
		return
	elseif kind == "Parry" and data[1] == player.UserId then
		if C and not reduceMotion() then C.ImpactFrame("invert", 1, nil) end
		S.toast(gui, "PARRY!", Color3.fromRGB(120, 220, 255))
	elseif kind == "BossSpecial" and data[2] == "Grab" and data[3] == player.UserId then
		breakBtn.Visible = true
		setPrompt(if S.MOBILE then "GRABBED! Break free!" else "GRABBED! Break free [R]!")
		task.delay(tonumber(data[4]) or 1.6, function() breakBtn.Visible = false; setPrompt(nil) end)
	elseif kind == "BossSpecial" and (data[2] == "GrabEscape" or data[2] == "GrabSlam") and data[3] == player.UserId then
		breakBtn.Visible = false
		setPrompt(nil)
		if data[2] == "GrabEscape" then S.toast(gui, "Escaped!", S.GREEN) end
	elseif kind == "StruggleStart" and data[1] == player.UserId and current.kind == "clash" then
		clashBg.Visible = true
		mashBtn.Visible = false -- MobileControls shows its own mash button for beam clashes
	elseif kind == "StrugglePulse" and data[1] == player.UserId and current.kind == "clash" then
		local win = (current.clash and current.clash.winScore) or 30
		clashFill.Size = UDim2.fromScale(math.clamp(0.5 + (tonumber(data[3]) or 0) / (2 * win), 0, 1), 1)
		clashText.Text = "CLASH"
	elseif kind == "HoldStart" and data[1] == player.UserId then
		gripBg.Visible, chargeBg.Visible, mashBtn.Visible = true, true, true
	elseif kind == "HoldPulse" and data[1] == player.UserId and current.hold then
		local cfg = current.hold
		local score, elapsed = tonumber(data[3]) or 0, tonumber(data[4]) or 0
		gripFill.Size = UDim2.fromScale(math.clamp((score + cfg.winScore) / (2 * cfg.winScore), 0, 1), 1)
		gripFill.BackgroundColor3 = if score < -cfg.winScore * 0.5 then S.RED else Color3.fromRGB(255, 170, 40)
		chargeFill.Size = UDim2.fromScale(math.clamp(elapsed / cfg.maxTime, 0, 1), 1)
		chargeText.Text = ("PICCOLO CHARGE  %d%%"):format(math.floor(math.clamp(elapsed / cfg.maxTime, 0, 1) * 100))
		gripText.Text = "GRIP"
	elseif kind == "HoldEnd" and data[1] == player.UserId or (kind == "HoldEnd" and data[2] == player.UserId) then
		mashBtn.Visible = false
	end
end)

player.CharacterAdded:Connect(function()
	actors.lead = nil
	breakBtn.Visible = false
end)
