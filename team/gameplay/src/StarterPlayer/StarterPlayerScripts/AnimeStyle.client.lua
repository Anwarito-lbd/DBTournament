-- LocalScript: anime look + anime-style animation layer (client-only, visual).
-- LOOK: cel-shade (flat SmoothPlastic body, no env specular), black Highlight outlines (nearest 28 characters + story actors),
--       anime faces drawn with SurfaceGui shapes on default-avatar heads, per champion eye style, expressions
--       Neutral / Angry / Scream driven by state (charging/transforming -> Angry, beam fire/transform burst -> Scream).
-- ANIM: drives FightAnimator (the one owner of combat poses) from the server's broadcasts for every character:
--       strings, heavies, ki volleys, signature beams, transforms, dashes, guard and flight loops, and the hurt / KO
--       reactions. Hit feedback (hitstop, impact frames, shake) is GameFeel's; this keeps the cosmetic extras: faces,
--       outlines, speed lines and afterimages.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientAPI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientAPI"))
local player = Players.LocalPlayer

Lighting.EnvironmentSpecularScale = 0
Lighting.EnvironmentDiffuseScale = 0.35

-- ========== helpers ==========
local function charIdOf(ch: Model): string?
	local p = Players:GetPlayerFromCharacter(ch)
	local id = (p and p:GetAttribute("Character")) or ch:GetAttribute("Character") or ch:GetAttribute("ChampionModel")
	return if type(id) == "string" then id else nil
end
local function rad(x) return math.rad(x) end

-- ========== FACES ==========
local EYE = {
	-- w,h: eye size (px of 100x100 face), tilt: outer-corner up(+)/down, brow: brow tilt, iris colour, pupil, extra marks
	u7_goku   = { w = 20, h = 15, tilt = 8,  brow = 14, browW = 26, iris = Color3.fromRGB(25, 25, 30), lash = 4 },
	u7_vegeta = { w = 21, h = 9,  tilt = 16, brow = 26, browW = 28, iris = Color3.fromRGB(20, 20, 25), lash = 5 },
	u7_frieza = { w = 19, h = 12, tilt = 10, brow = 0,  browW = 0,  iris = Color3.fromRGB(200, 20, 40), lash = 4, marks = Color3.fromRGB(150, 60, 190) },
	default   = { w = 18, h = 16, tilt = 4,  brow = 8,  browW = 22, iris = Color3.fromRGB(30, 30, 40), lash = 3 },
}
local function frame(parent, x, y, w, h, color, rot, round)
	local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x / 100, y / 100); f.Size = UDim2.fromScale(w / 100, h / 100)
	f.BackgroundColor3 = color; f.BorderSizePixel = 0; f.Rotation = rot or 0; f.Parent = parent
	if round then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(round, 0); c.Parent = f end
	return f
end
local function buildFace(head: BasePart, id: string?, expr: string)
	local old = head:FindFirstChild("AnimeFace"); if old then old:Destroy() end
	local st = EYE[id or ""] or EYE.default
	-- thin invisible plate just in front of the head so the drawn face is never buried in the head mesh
	local plate = head:FindFirstChild("AnimeFacePlate") :: BasePart?
	if not plate then
		plate = Instance.new("Part"); plate.Name = "AnimeFacePlate"; plate.Transparency = 1; plate.CanCollide = false
		plate.CanQuery = false; plate.CanTouch = false; plate.Massless = true
		plate.Size = Vector3.new(head.Size.X * 0.9, head.Size.Y * 0.9, 0.05)
		plate.CFrame = head.CFrame * CFrame.new(0, 0, -head.Size.Z / 2 - 0.04)
		local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = plate; w.Parent = plate
		plate.Parent = head
		if head:IsA("MeshPart") then head:SetAttribute("OrigTex", head.TextureID); head.TextureID = "" end -- hide built-in face
	end
	local sg = Instance.new("SurfaceGui"); sg.Name = "AnimeFace"; sg.Face = Enum.NormalId.Front; sg.Adornee = plate
	sg.CanvasSize = Vector2.new(200, 200); sg.LightInfluence = 0.3; sg.AlwaysOnTop = false; sg.Parent = head
	sg:SetAttribute("Expr", expr)
	local root = Instance.new("Frame"); root.Size = UDim2.fromScale(1, 1); root.BackgroundTransparency = 1; root.Parent = sg
	local angry = expr == "Angry" or expr == "Scream"
	for side = -1, 1, 2 do
		local x = 50 + side * 17
		local tilt = (st.tilt + (if angry then 10 else 0)) * -side
		local h = if expr == "Scream" then st.h * 0.75 else (if angry then st.h * 0.7 else st.h)
		local white = frame(root, x, 47, st.w, h, Color3.new(1, 1, 1), tilt, 0.45)
		local irisSize = if expr == "Scream" then 0.35 else 0.62 -- shrunken pupils when screaming
		frame(white, 50 - side * 8, 55, 100 * irisSize * h / st.w * 1.1, 100 * irisSize, st.iris, 0, 0.5)
		if expr ~= "Scream" then frame(white, 50 - side * 14, 40, 18, 22, Color3.new(1, 1, 1), 0, 0.5) end -- highlight
		frame(root, x, 47 - h / 2, st.w + 2, st.lash, Color3.new(0, 0, 0), tilt, 0.3) -- upper lash line
		if st.browW > 0 then
			frame(root, x, 47 - h / 2 - 7, st.browW, 4, Color3.new(0, 0, 0), (st.brow + (if angry then 14 else 0)) * -side, 0.2)
		end
		if st.marks then frame(root, x + side * 2, 47 - h / 2 - 5, st.w * 0.6, 3, st.marks, tilt, 0.5) end
	end
	-- nose tick + mouth
	frame(root, 51, 62, 2, 5, Color3.fromRGB(60, 40, 40), 15)
	if expr == "Scream" then
		local m = frame(root, 50, 79, 28, 17, Color3.fromRGB(70, 10, 20), 0, 0.4)
		frame(m, 50, 18, 80, 18, Color3.new(1, 1, 1), 0, 0.3) -- teeth
	elseif expr == "Angry" then
		frame(root, 50, 76, 18, 4, Color3.fromRGB(50, 20, 20), 0, 0.3)
		frame(root, 50, 76, 14, 2, Color3.new(1, 1, 1), 0, 0.3)
	else
		frame(root, 50, 75, 12, 2.5, Color3.fromRGB(70, 30, 30), 0, 0.5)
	end
end

local exprOverride: { [Model]: { expr: string, untilT: number } } = {}
local function setExpr(ch: Model, expr: string, dur: number)
	exprOverride[ch] = { expr = expr, untilT = os.clock() + dur }
end

-- ========== LOOK (applied per character) ==========
local styled: { [Model]: boolean } = {}
local function styleCharacter(ch: Model)
	if styled[ch] then return end
	styled[ch] = true
	for _, d in ch:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and not d:FindFirstAncestor("ChampionSkin") then
			if d.Material ~= Enum.Material.Neon and d.Material ~= Enum.Material.ForceField then d.Material = Enum.Material.SmoothPlastic end
			d.Reflectance = 0
		end
	end
	ch.AncestryChanged:Connect(function(_, parent) if not parent then styled[ch] = nil; exprOverride[ch] = nil end end)
end

-- One Highlight per outlined character, parented to that character; at most MAX_OUTLINES (nearest), recycled from a pool.
-- Roblox renders ~31 Highlights max, so stay well under it.
local MAX_OUTLINES = 25
local outlinePool: { Highlight } = {}
local outlined: { [Model]: Highlight } = {}
local function takeHighlight(): Highlight
	local h = table.remove(outlinePool)
	if not h then
		h = Instance.new("Highlight"); h.Name = "AnimeOutline"; h.FillTransparency = 1; h.OutlineColor = Color3.new(0, 0, 0)
		h.OutlineTransparency = 0; h.DepthMode = Enum.HighlightDepthMode.Occluded
	end
	return h
end
local function releaseHighlight(h: Highlight)
	-- if its character was destroyed the Highlight went with it (Parent locked); just drop it
	if pcall(function() h.Adornee = nil; h.Parent = nil end) then table.insert(outlinePool, h) end
end
local function updateOutlines()
	local cam = workspace.CurrentCamera
	local list = {}
	for _, d in workspace:GetChildren() do
		if d:IsA("Model") and (d:FindFirstChildOfClass("Humanoid") or d.Name:sub(1, 6) == "Story_") then
			local ok, cf = pcall(function() return d:GetPivot() end)
			if ok then
				local dist = (cf.Position - cam.CFrame.Position).Magnitude
				if dist < 400 then table.insert(list, { m = d, dist = dist }) end
			end
		end
	end
	table.sort(list, function(a, b) return a.dist < b.dist end)
	local want = {}
	for i = 1, math.min(MAX_OUTLINES, #list) do want[list[i].m] = true end
	for m, h in outlined do
		if not want[m] or not m.Parent or h.Parent ~= m then outlined[m] = nil; releaseHighlight(h) end
	end
	for m in want do
		if not outlined[m] then
			local h = takeHighlight()
			-- a pooled Highlight destroyed together with its old character has a locked Parent: discard it, make a new one
			if not pcall(function() h.Adornee = m; h.Parent = m end) then outlinePool = {}; h = takeHighlight(); h.Adornee = m; h.Parent = m end
			outlined[m] = h
		end
		if m:FindFirstChildOfClass("Humanoid") then styleCharacter(m) end
	end
	-- clean up any stray outlines left directly in Workspace by older builds
	for _, x in workspace:GetChildren() do if x:IsA("Highlight") and x.Name == "AnimeOutline" then x:Destroy() end end
end

local function updateFaces()
	for _, d in workspace:GetChildren() do
		local hum = d:IsA("Model") and d:FindFirstChildOfClass("Humanoid")
		local head = hum and d:FindFirstChild("Head") :: BasePart?
		if head and (head.Transparency >= 1 or d:FindFirstChild("ChampionSkin")) then
			local f = head:FindFirstChild("AnimeFace"); if f then f:Destroy() end
			local pl = head:FindFirstChild("AnimeFacePlate"); if pl then pl:Destroy() end
		elseif head then
			local id = charIdOf(d)
			local p = Players:GetPlayerFromCharacter(d)
			local expr = "Neutral"
			local o = exprOverride[d]
			if o and o.untilT > os.clock() then expr = o.expr
			elseif (p and (p:GetAttribute("Charging") or p:GetAttribute("Blocking"))) or d:GetAttribute("Charging") then expr = "Angry" end
			local cur = head:FindFirstChild("AnimeFace") :: SurfaceGui?
			if not cur or cur:GetAttribute("Expr") ~= expr or cur:GetAttribute("Id") ~= (id or "") then
				buildFace(head, id, expr)
				local f = head:FindFirstChild("AnimeFace") :: SurfaceGui
				f:SetAttribute("Id", id or "")
				local face = head:FindFirstChild("face") :: Decal?
				if face then face.Transparency = 1 end
			end
		end
	end
end

-- ========== POSES ==========
-- Owned by FightAnimator (shared with CombatInput's prediction). "server" plays are skipped for the local character
-- when it just predicted the same move family, so nothing plays twice.
local FightAnimator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FightAnimator"))
local function act(ch: Model, clip: string, family: string, speed: number?, loop: boolean?)
	FightAnimator.play(ch, clip, { source = "server", family = family, speed = speed, loop = loop })
end
local function airborne(ch: Model): boolean
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local st = hum:GetState()
	return st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
end

-- ========== SPEED LINES / IMPACT FLASH ==========
local gui = Instance.new("ScreenGui"); gui.Name = "AnimeFX"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
gui.DisplayOrder = 5; gui.Parent = player:WaitForChild("PlayerGui")
local function speedLines(dur: number, color: Color3?)
	local holder = Instance.new("Frame"); holder.Size = UDim2.fromScale(1, 1); holder.BackgroundTransparency = 1; holder.Parent = gui
	local lines = {}
	for i = 1, 40 do
		local a = math.random() * 360
		local len = math.random(25, 45) / 100
		local l = Instance.new("Frame"); l.AnchorPoint = Vector2.new(0, 0.5); l.BorderSizePixel = 0
		l.BackgroundColor3 = color or Color3.new(1, 1, 1); l.BackgroundTransparency = math.random(10, 50) / 100
		l.Size = UDim2.new(len, 0, 0, math.random(2, 5)); l.Rotation = a
		local r = math.random(55, 70) / 100
		l.Position = UDim2.fromScale(0.5 + math.cos(rad(a)) * r * 0.5, 0.5 + math.sin(rad(a)) * r * 0.5)
		l.Parent = holder; table.insert(lines, l)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			for _, l in lines do l.BackgroundTransparency = math.random(10, 70) / 100 end
			task.wait(0.05)
		end
		holder:Destroy()
	end)
end
-- ========== AFTERIMAGES ==========
local ghosts = 0
local GHOST_COLORS = { u7_goku = Color3.fromRGB(255, 160, 60), u7_vegeta = Color3.fromRGB(90, 140, 255), u7_frieza = Color3.fromRGB(200, 120, 255) }
local function afterimage(ch: Model)
	if ghosts > 90 then return end
	local col = GHOST_COLORS[charIdOf(ch) or ""] or Color3.fromRGB(150, 220, 255)
	for _, d in ch:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" and d.Size.Magnitude < 12 then
			local g: BasePart
			if d:IsA("MeshPart") then g = d:Clone(); g:ClearAllChildren() else
				g = Instance.new("Part"); g.Size = d.Size; g.Shape = if d:IsA("Part") then d.Shape else Enum.PartType.Block end
			g.CFrame = d.CFrame; g.Anchored = true; g.CanCollide = false; g.CanQuery = false; g.CanTouch = false; g.Massless = true
			g.Material = Enum.Material.Neon; g.Color = col; g.Transparency = 0.45; g.Parent = workspace.CurrentCamera
			if g:IsA("MeshPart") then (g :: MeshPart).TextureID = "" end
			ghosts += 1
			TweenService:Create(g, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			task.delay(0.36, function() g:Destroy(); ghosts -= 1 end)
		end
	end
end
local lastGhost: { [Model]: number } = {}
local function scanSpeed()
	local now = os.clock()
	for _, d in workspace:GetChildren() do
		local r = d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and d:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r then
			local v = r.AssemblyLinearVelocity.Magnitude
			if v > 65 and now - (lastGhost[d] or 0) > 0.06 then lastGhost[d] = now; afterimage(d) end
		end
	end
end

-- ========== EVENT HOOKS ==========
local function charByUser(uid: any): Model?
	if typeof(uid) == "Instance" then return uid :: Model end -- dev-bot victims arrive as the Model
	if type(uid) ~= "number" then return nil end
	local p = Players:GetPlayerByUserId(uid); return p and p.Character
end
local comboState: { [Model]: { n: number, t: number } } = {}
ClientAPI.onPlayVFX:Connect(function(kind, ch, arg)
	if typeof(ch) ~= "Instance" or not ch:IsA("Model") then return end
	local mine = ch == player.Character
	if kind == "Kamehameha" then
		local charge, fire = FightAnimator.beamClips(ch)
		act(ch, charge, "Kamehameha")
		task.delay(0.6, function() if ch.Parent then act(ch, fire, "Kamehameha") end end)
		setExpr(ch, "Angry", 0.6); task.delay(0.6, function() setExpr(ch, "Scream", 1.0) end)
		if mine then task.delay(0.6, function() speedLines(0.5) end) end
	elseif kind == "M1" then
		local now = os.clock()
		local st = comboState[ch]
		if not st or now - st.t > 0.9 then st = { n = 0, t = now } end
		st.n = st.n % 4 + 1; st.t = now; comboState[ch] = st
		if airborne(ch) then act(ch, "AirCombo", "M1", 1.15) else act(ch, "M1_" .. st.n, "M1", if st.n == 4 then 1.15 else 1.35) end
		setExpr(ch, "Angry", 0.5)
	elseif kind == "Heavy" then
		act(ch, if airborne(ch) then "Launcher" else "Heavy", "Heavy", 1.0)
		setExpr(ch, "Angry", 0.5)
	elseif kind == "KiBlast" then
		act(ch, "KiVolley", "KiBlast", 1.4); setExpr(ch, "Angry", 0.6)
	elseif kind == "Launcher" or kind == "Uppercut" then
		act(ch, "Launcher", kind)
	elseif kind == "Transform" then
		act(ch, "Transform_SSJ", "Transform"); setExpr(ch, "Scream", 1.4)
		if mine then speedLines(1, Color3.fromRGB(255, 230, 120)) end
	end
end)
-- reactions: every character's flinch / stagger / KO plays here once (the local victim included); guarded hits keep
-- the guard pose; at most one new hurt per 0.18 s per character so a string reads as hits, not jitter
local lastHurt: { [Model]: number } = {}
ClientAPI.onCombatEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	local ch = data[1] and charByUser(data[1])
	if not ch then return end
	if kind == "Hit" then
		setExpr(ch, "Scream", 0.4)
		local ko = data[5] == true
		local p = Players:GetPlayerFromCharacter(ch)
		if not ko and p and p:GetAttribute("Blocking") == true then return end
		local now = os.clock()
		if not ko and now - (lastHurt[ch] or 0) < 0.18 then return end
		lastHurt[ch] = now
		local kb = data[4] or 0
		if ko then act(ch, "KO", "KO", 1.0)
		elseif kb >= 40 then act(ch, "HurtHeavy", "Hurt", 1.15)
		elseif kb >= 15 then act(ch, "HurtHeavy", "Hurt", 1.3)
		else act(ch, "HurtLight", "Hurt", 1.35) end
		return
	end
	if kind == "Finisher" then -- the 4th M1 of a chain: launch, spike or blow-away (Shared/FightRules)
		local f = data[2]
		act(ch, if f == "launch" then "Launcher" elseif f == "spike" then "AirCombo" else "M1_4", "M1", 1.15)
		return
	end
	if kind == "Dash" then act(ch, "Dash", "Dash", 1.5); afterimage(ch); return end
	if kind == "Vanish" or kind == "DashCancel" then
		act(ch, "Dash", kind, 1.5)
		if kind == "DashCancel" then afterimage(ch) end -- the vanish smear and speed lines come from GameFeel
	end
end)
-- knocked down: the fall pose holds while down; guard pose while blocking, flight idle while airborne/flying:
-- looped while the state lasts, released after
local downPlayed: { [Model]: boolean } = {}
RunService.Heartbeat:Connect(function()
	for _, p in Players:GetPlayers() do
		local ch = p.Character
		if ch then
			local cur = FightAnimator.current(ch)
			if p:GetAttribute("KnockedDown") == true then
				if not downPlayed[ch] then
					downPlayed[ch] = true
					act(ch, "KO", "Down", 0.75)
				end
				continue
			elseif downPlayed[ch] then
				downPlayed[ch] = nil
				if cur == "KO" then FightAnimator.stop(ch, 0.2) end
				cur = nil
			end
			if p:GetAttribute("Blocking") == true then
				if cur == nil then act(ch, "Guard", "Guard", 1.2, true) end
			elseif cur == "Guard" then
				FightAnimator.stop(ch, 0.12)
			elseif p:GetAttribute("Flying") or ch:GetAttribute("Flying") then
				if cur == nil then act(ch, "FlyIdle", "Fly", 1, true) end
			elseif cur == "FlyIdle" then
				FightAnimator.stop(ch, 0.25)
			end
		end
	end
end)
-- ki charge (hold C) -> power-up loop for the local player
player:GetAttributeChangedSignal("Charging"):Connect(function()
	local ch = player.Character
	if not ch then return end
	if player:GetAttribute("Charging") then
		FightAnimator.play(ch, "Transform_SSJ", { source = "local", family = "PowerUp", loop = true, markers = false })
	elseif FightAnimator.current(ch) == "Transform_SSJ" then
		FightAnimator.stop(ch, 0.2)
	end
end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	scanSpeed()
	acc += dt
	if acc > 0.25 then acc = 0; updateOutlines(); updateFaces() end
end)

-- dev hook for screenshots: workspace attribute AnimePose = "<clip>" plays that clip on the local character
workspace:GetAttributeChangedSignal("AnimePose"):Connect(function()
	local s = workspace:GetAttribute("AnimePose")
	if type(s) == "string" and player.Character then
		if s == "Afterimage" then afterimage(player.Character) elseif s == "SpeedLines" then speedLines(1.5)
		elseif s:sub(1, 5) == "Expr_" then setExpr(player.Character, s:sub(6), 6)
		else FightAnimator.play(player.Character, s, { source = "local" }) end
	end
end)
