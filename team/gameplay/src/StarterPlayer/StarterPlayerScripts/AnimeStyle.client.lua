-- LocalScript: anime look + anime-style animation layer (client-only, visual).
-- LOOK: cel-shade (flat SmoothPlastic body, no env specular), black Highlight outlines (nearest 28 characters + story actors),
--       anime faces drawn with SurfaceGui shapes on default-avatar heads, per champion eye style, expressions
--       Neutral / Angry / Scream driven by state (charging/transforming -> Angry, beam fire/transform burst -> Scream).
-- ANIM: procedural key poses written to R15 Motor6D.Transform after the Animator each frame (RunService.PreSimulation):
--       Kamehameha stance (Goku), Final Flash pose (Vegeta), finger point (Frieza Death Beam), punch/kick key poses;
--       hitstop (held impact frames) on melee hits, impact flash, speed lines, afterimages on dash/vanish.
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
-- R15 joints: classic Motor6D or the newer AnimationConstraint joints (both expose .Transform)
local function motors(ch: Model): { [string]: any }
	local t = {}
	for _, d in ch:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then t[d.Name] = d end
	end
	return t
end
local function rad(x) return math.rad(x) end
local function ang(x, y, z) return CFrame.Angles(rad(x or 0), rad(y or 0), rad(z or 0)) end

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
-- pose = { [jointName] = CFrame } applied (multiplied) on top of animation, weight 0..1
type Pose = { [string]: CFrame }
local POSES: { [string]: Pose } = {
	KameCharge = { Waist = ang(0, 55, 0), Neck = ang(0, -45, 0),
		RightShoulder = ang(20, 0, 0) * ang(0, 0, 25) * ang(-60, 0, 0), LeftShoulder = ang(-50, 0, -40) * ang(0, 60, 0),
		RightElbow = ang(70, 0, 0), LeftElbow = ang(70, 0, 0),
		LeftHip = ang(0, 0, -20), RightHip = ang(25, 0, 15), LeftKnee = ang(-25, 0, 0), RightKnee = ang(-30, 0, 0) },
	KameFire = { Waist = ang(0, -10, 0), RightShoulder = ang(90, 0, 0) * ang(0, 0, -12), LeftShoulder = ang(90, 0, 0) * ang(0, 0, 12),
		RightElbow = ang(5, 0, 0), LeftElbow = ang(5, 0, 0), RightHip = ang(-10, 0, 20), LeftHip = ang(30, 0, -15), LeftKnee = ang(-35, 0, 0) },
	FlashCharge = { Waist = ang(-8, 0, 0), Neck = ang(15, 0, 0), RightShoulder = ang(0, 0, 95), LeftShoulder = ang(0, 0, -95),
		RightElbow = ang(0, 0, 0), LeftElbow = ang(0, 0, 0), RightHip = ang(0, 0, 18), LeftHip = ang(0, 0, -18) },
	FlashFire = { Waist = ang(5, 0, 0), RightShoulder = ang(95, 0, -10), LeftShoulder = ang(95, 0, 10), RightElbow = ang(0, 0, 0),
		LeftElbow = ang(0, 0, 0), RightHip = ang(-10, 0, 22), LeftHip = ang(25, 0, -22), LeftKnee = ang(-30, 0, 0) },
	FingerPoint = { Waist = ang(0, -20, 0), Neck = ang(-5, 15, 0), RightShoulder = ang(92, 0, 0), RightElbow = ang(0, 0, 0),
		LeftShoulder = ang(0, 0, -25) * ang(0, 0, 0), LeftElbow = ang(80, 0, 0), RightHip = ang(0, 0, 8) },
	Punch1 = { Waist = ang(0, -35, 0), RightShoulder = ang(95, 0, 0), RightElbow = ang(0, 0, 0), LeftShoulder = ang(40, 0, -15), LeftElbow = ang(110, 0, 0),
		LeftHip = ang(35, 0, 0), LeftKnee = ang(-30, 0, 0), RightHip = ang(-20, 0, 0) },
	Punch2 = { Waist = ang(0, 35, 0), LeftShoulder = ang(95, 0, 0), LeftElbow = ang(0, 0, 0), RightShoulder = ang(40, 0, 15), RightElbow = ang(110, 0, 0),
		RightHip = ang(35, 0, 0), RightKnee = ang(-30, 0, 0), LeftHip = ang(-20, 0, 0) },
	HeavyWind = { Waist = ang(10, 60, 0), RightShoulder = ang(-40, 0, 40), RightElbow = ang(100, 0, 0), LeftShoulder = ang(60, 0, -10), RightHip = ang(40, 0, 0), RightKnee = ang(-90, 0, 0) },
	HeavyKick = { Waist = ang(-15, -40, 0), RightHip = ang(100, 0, 10), RightKnee = ang(0, 0, 0), LeftKnee = ang(-15, 0, 0),
		RightShoulder = ang(-20, 0, 50), LeftShoulder = ang(30, 0, -60) },
	PowerUp = { Waist = ang(-12, 0, 0), Neck = ang(-25, 0, 0), RightShoulder = ang(0, 0, 35), LeftShoulder = ang(0, 0, -35), RightElbow = ang(60, 0, 0), LeftElbow = ang(60, 0, 0),
		RightHip = ang(0, 0, 18), LeftHip = ang(0, 0, -18), RightKnee = ang(-15, 0, 0), LeftKnee = ang(-15, 0, 0) },
	-- v1.2 keyframes ------------------------------------------------------------------------------------------
	Uppercut = { Waist = ang(-20, -20, 0), Neck = ang(-15, 0, 0), RightShoulder = ang(150, 0, -10), RightElbow = ang(30, 0, 0), LeftShoulder = ang(20, 0, -20), LeftElbow = ang(90, 0, 0),
		RightHip = ang(-15, 0, 0), LeftHip = ang(30, 0, 0), LeftKnee = ang(-40, 0, 0) },
	SpinKick = { Waist = ang(0, 80, -10), RightHip = ang(80, 0, 40), RightKnee = ang(-5, 0, 0), LeftKnee = ang(-20, 0, 0), RightShoulder = ang(0, 0, 70), LeftShoulder = ang(0, 0, -70) },
	ElbowSmash = { Waist = ang(10, -50, 0), RightShoulder = ang(80, 0, 50), RightElbow = ang(140, 0, 0), LeftShoulder = ang(30, 0, -30), LeftElbow = ang(100, 0, 0), LeftHip = ang(30, 0, 0), LeftKnee = ang(-35, 0, 0) },
	TailWhip = { Waist = ang(0, -90, 15), RightHip = ang(30, 0, 70), LeftHip = ang(-10, 0, -10), RightShoulder = ang(-20, 0, 60), LeftShoulder = ang(10, 0, -40) },
	LauncherCrouch = { Waist = ang(25, 0, 0), RightHip = ang(70, 0, 10), LeftHip = ang(70, 0, -10), RightKnee = ang(-100, 0, 0), LeftKnee = ang(-100, 0, 0),
		RightShoulder = ang(-30, 0, 20), LeftShoulder = ang(-30, 0, -20), RightElbow = ang(90, 0, 0), LeftElbow = ang(90, 0, 0) },
	LauncherUp = { Waist = ang(-25, 0, 0), Neck = ang(-20, 0, 0), RightShoulder = ang(170, 0, 0), RightElbow = ang(0, 0, 0), LeftShoulder = ang(10, 0, -30), RightHip = ang(-20, 0, 0), LeftHip = ang(60, 0, 0), LeftKnee = ang(-80, 0, 0) },
	AirKick = { Waist = ang(-30, 0, 0), RightHip = ang(110, 0, 0), RightKnee = ang(0, 0, 0), LeftHip = ang(40, 0, 0), LeftKnee = ang(-110, 0, 0), RightShoulder = ang(-30, 0, 60), LeftShoulder = ang(-30, 0, -60) },
	AirAxe = { Waist = ang(35, 0, 0), RightShoulder = ang(160, 0, 15), LeftShoulder = ang(160, 0, -15), RightElbow = ang(10, 0, 0), LeftElbow = ang(10, 0, 0), RightHip = ang(40, 0, 0), LeftHip = ang(40, 0, 0), RightKnee = ang(-70, 0, 0), LeftKnee = ang(-70, 0, 0) },
	BlastR = { Waist = ang(0, -30, 0), RightShoulder = ang(90, 0, 10), RightElbow = ang(0, 0, 0), LeftShoulder = ang(30, 0, -10), LeftElbow = ang(80, 0, 0), LeftHip = ang(25, 0, 0), LeftKnee = ang(-25, 0, 0) },
	BlastL = { Waist = ang(0, 30, 0), LeftShoulder = ang(90, 0, -10), LeftElbow = ang(0, 0, 0), RightShoulder = ang(30, 0, 10), RightElbow = ang(80, 0, 0), RightHip = ang(25, 0, 0), RightKnee = ang(-25, 0, 0) },
	Guard = { Waist = ang(12, 0, 0), Neck = ang(15, 0, 0), RightShoulder = ang(100, 0, 35), LeftShoulder = ang(100, 0, -35), RightElbow = ang(120, 0, 0), LeftElbow = ang(120, 0, 0),
		RightHip = ang(20, 0, 10), LeftHip = ang(20, 0, -10), RightKnee = ang(-30, 0, 0), LeftKnee = ang(-30, 0, 0) },
	DashFwd = { Waist = ang(40, 0, 0), Neck = ang(-30, 0, 0), RightShoulder = ang(-50, 0, 20), LeftShoulder = ang(-50, 0, -20), RightHip = ang(-30, 0, 0), LeftHip = ang(50, 0, 0), LeftKnee = ang(-80, 0, 0), RightKnee = ang(-20, 0, 0) },
	FlightIdle = { Waist = ang(8, 0, 0), RightShoulder = ang(15, 0, 20), LeftShoulder = ang(15, 0, -20), RightElbow = ang(35, 0, 0), LeftElbow = ang(35, 0, 0),
		RightHip = ang(25, 0, 5), LeftHip = ang(5, 0, -5), RightKnee = ang(-60, 0, 0), LeftKnee = ang(-25, 0, 0) },
	Hurt1 = { Waist = ang(-20, 15, 0), Neck = ang(-30, 0, 0), RightShoulder = ang(-20, 0, 40), LeftShoulder = ang(-20, 0, -40), RightHip = ang(-10, 0, 0), LeftHip = ang(15, 0, 0) },
	Hurt2 = { Waist = ang(30, -15, 0), Neck = ang(25, 0, 0), RightShoulder = ang(30, 0, 20), LeftShoulder = ang(60, 0, -10), RightElbow = ang(60, 0, 0), LeftElbow = ang(90, 0, 0), RightKnee = ang(-30, 0, 0), LeftKnee = ang(-30, 0, 0) },
	KO = { Waist = ang(-45, 0, 10), Neck = ang(-40, 0, 0), RightShoulder = ang(-10, 0, 110), LeftShoulder = ang(-10, 0, -110), RightHip = ang(-30, 0, 15), LeftHip = ang(-5, 0, -25), RightKnee = ang(-10, 0, 0), LeftKnee = ang(-40, 0, 0) },
	Victory = { Waist = ang(-5, 0, 0), RightShoulder = ang(170, 0, 0), RightElbow = ang(0, 0, 0), LeftShoulder = ang(0, 0, -15), LeftElbow = ang(60, 0, 0), Neck = ang(-10, 0, 0) },
}
-- sequences: list of { pose, holdSeconds, snap (seconds to blend in) } -- anime timing: snap fast, hold long
local SEQ = {
	Kamehameha = { { "KameCharge", 1.1, 0.08 }, { "KameFire", 1.5, 0.04 } },
	FinalFlash = { { "FlashCharge", 1.5, 0.08 }, { "FlashFire", 1.6, 0.04 } },
	DeathBeam = { { "FingerPoint", 0.7, 0.05 } },
	M1a = { { "Punch1", 0.16, 0.03 } }, M1b = { { "Punch2", 0.16, 0.03 } },
	Heavy = { { "HeavyWind", 0.18, 0.05 }, { "HeavyKick", 0.3, 0.03 } },
	PowerUp = { { "PowerUp", 1.2, 0.1 } },
	-- v1.2 strings (pose, hold, blend-in). Hits are server-paced; each M1 press advances one link.
	Combo1 = { { "Punch1", 0.16, 0.05 } }, Combo2 = { { "Punch2", 0.16, 0.05 } },
	Combo3 = { { "Uppercut", 0.2, 0.06 } }, Combo4 = { { "SpinKick", 0.3, 0.07 } },
	Launcher = { { "LauncherCrouch", 0.14, 0.06 }, { "LauncherUp", 0.4, 0.05 } },
	AirCombo = { { "AirKick", 0.18, 0.05 }, { "Punch1", 0.14, 0.04 }, { "AirAxe", 0.35, 0.06 } },
	KiVolley = { { "BlastR", 0.12, 0.04 }, { "BlastL", 0.12, 0.04 }, { "BlastR", 0.12, 0.04 }, { "BlastL", 0.16, 0.04 } },
	Guard = { { "Guard", 0.35, 0.08 } }, Dash = { { "DashFwd", 0.3, 0.05 } }, FlightIdle = { { "FlightIdle", 0.6, 0.25 } },
	Hurt1 = { { "Hurt1", 0.22, 0.04 } }, Hurt2 = { { "Hurt2", 0.22, 0.04 } }, KO = { { "Hurt1", 0.1, 0.03 }, { "KO", 1.6, 0.12 } },
	Victory = { { "Victory", 2.5, 0.2 } },
}
-- per-champion overrides of a sequence (signature style)
local CHAR_SEQ: { [string]: { [string]: { any } } } = {
	u7_vegeta = { Combo3 = { { "ElbowSmash", 0.2, 0.06 } }, Heavy = { { "HeavyWind", 0.16, 0.05 }, { "ElbowSmash", 0.3, 0.04 } } },
	u7_frieza = { Combo3 = { { "TailWhip", 0.2, 0.06 } }, Combo4 = { { "TailWhip", 0.12, 0.05 }, { "SpinKick", 0.28, 0.06 } },
		KiVolley = { { "FingerPoint", 0.12, 0.04 }, { "FingerPoint", 0.12, 0.03 }, { "FingerPoint", 0.16, 0.03 } } },
}
local BLEND_OUT = 0.18 -- smooth release back to the base animation instead of snapping
type Active = { seq: { any }, i: number, t0: number, frozenUntil: number, frozenAt: number, prev: Pose?, last: { [string]: CFrame }, release: number?, relFrom: Pose? }
local active: { [Model]: Active } = {}
local function play(ch: Model, seqName: string)
	local over = CHAR_SEQ[charIdOf(ch) or ""]
	local s = (over and over[seqName]) or SEQ[seqName]; if not s or not ch.Parent then return end
	local cur = active[ch]
	if cur and cur.release and cur.last then -- chain from the pose we're releasing for a smooth transition
		active[ch] = { seq = s, i = 1, t0 = os.clock(), frozenUntil = 0, frozenAt = 0, prev = cur.relFrom, last = {} }
		return
	end
	active[ch] = { seq = s, i = 1, t0 = os.clock(), frozenUntil = 0, frozenAt = 0, prev = nil, last = {} }
end
local function hitstop(ch: Model, dur: number)
	local a = active[ch]
	if not a then
		-- freeze current animation by capturing transforms
		local snap: Pose = {}
		for n, m in motors(ch) do snap[n] = m.Transform end
		active[ch] = { seq = { { "__snap", dur, 0 } }, i = 1, t0 = os.clock(), frozenUntil = os.clock() + dur, frozenAt = os.clock(), prev = nil, last = snap }
		a = active[ch]; (a :: any).snap = snap
	else
		a.frozenUntil = os.clock() + dur; a.frozenAt = os.clock()
	end
	-- also pause AnimationTracks so the held frame is clean
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local an = hum and hum:FindFirstChildOfClass("Animator")
	if an then
		for _, tr in an:GetPlayingAnimationTracks() do
			local sp = tr.Speed; tr:AdjustSpeed(0)
			task.delay(dur, function() tr:AdjustSpeed(if sp == 0 then 1 else sp) end)
		end
	end
end

RunService.PreSimulation:Connect(function()
	local now = os.clock()
	for ch, a in active do
		if not ch.Parent then active[ch] = nil; continue end
		local ms = motors(ch)
		local snap = (a :: any).snap
		if snap then
			for n, cf in snap do if ms[n] then ms[n].Transform = cf end end
			if now > a.frozenUntil then active[ch] = nil end
			continue
		end
		if now < a.frozenUntil then
			for n, cf in a.last do if ms[n] then ms[n].Transform = cf end end
			a.t0 += 1 / 60 -- hold: don't advance the sequence clock
			continue
		end
		if a.release then -- smooth blend-out (ease-in-out) from the last pose back to identity
			local k = math.clamp((now - a.release) / BLEND_OUT, 0, 1)
			k = k * k * (3 - 2 * k)
			for n, m in ms do
				local from = a.relFrom and a.relFrom[n]
				if from then m.Transform = m.Transform * from:Lerp(CFrame.identity, k) end
			end
			if k >= 1 then active[ch] = nil end
			continue
		end
		local step = a.seq[a.i]
		local el = now - a.t0
		if el > step[2] then
			a.prev = POSES[step[1]]; a.i += 1; a.t0 = now
			if a.i > #a.seq then
				a.release = now; a.relFrom = a.prev; continue
			end
			step = a.seq[a.i]; el = 0
		end
		local pose = POSES[step[1]]
		local k = math.clamp(el / math.max(step[3], 0.001), 0, 1)
		k = if step[3] >= 0.15 then 0.5 - 0.5 * math.cos(k * math.pi) else 1 - (1 - k) ^ 3 -- slow blends: sine in-out; snaps: ease-out
		for n, m in ms do
			local target = pose[n]
			local from = (a.prev and a.prev[n]) or CFrame.identity
			if target or a.prev and a.prev[n] then
				local off = from:Lerp(target or CFrame.identity, k)
				m.Transform = m.Transform * off
				a.last[n] = m.Transform
			end
		end
	end
end)

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
local function impactFrame(strength: number)
	local f = Instance.new("Frame"); f.Size = UDim2.fromScale(1, 1); f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(1, 1, 1); f.BackgroundTransparency = 1 - 0.55 * strength; f.Parent = gui
	local inv = Instance.new("ColorCorrectionEffect"); inv.Contrast = 0.6 * strength; inv.Saturation = -0.6 * strength; inv.Parent = Lighting
	task.delay(0.06, function() f.BackgroundColor3 = Color3.new(0, 0, 0); f.BackgroundTransparency = 1 - 0.35 * strength end)
	task.delay(0.12, function() f:Destroy(); inv:Destroy() end)
end
local function camKick(mag: number)
	local cam = workspace.CurrentCamera
	task.spawn(function() for i = 1, 6 do cam.CFrame *= CFrame.new((math.random() - 0.5) * mag, (math.random() - 0.5) * mag, 0); task.wait() end end)
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
local m1Flip: { [Model]: boolean } = {}
local comboState: { [Model]: { n: number, t: number } } = {}
local function nearestOther(ch: Model, pos: Vector3?): Model?
	if not pos then return nil end
	local best, bd = nil, 9
	for _, d in workspace:GetDescendants() do
		if d:IsA("Humanoid") and d.Parent ~= ch then
			local r = d.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
			if r and (r.Position - pos).Magnitude < bd then best, bd = d.Parent, (r.Position - pos).Magnitude end
		end
	end
	return best
end
ClientAPI.onPlayVFX:Connect(function(kind, ch, arg)
	if typeof(ch) ~= "Instance" or not ch:IsA("Model") then return end
	local id = charIdOf(ch)
	local mine = ch == player.Character
	if kind == "Kamehameha" then
		local seq = if id == "u7_vegeta" then "FinalFlash" elseif id == "u7_frieza" then "DeathBeam" else "Kamehameha"
		play(ch, seq)
		local s = SEQ[seq]
		setExpr(ch, "Angry", s[1][2]); task.delay(s[1][2], function() setExpr(ch, "Scream", (s[2] and s[2][2]) or 0.6) end)
		if mine then task.delay(s[1][2], function() speedLines((s[2] and s[2][2]) or 0.5) end) end
	elseif kind == "M1" or kind == "Heavy" then
		if kind == "M1" then
			local now = os.clock()
			local st = comboState[ch]
			if not st or now - st.t > 0.9 then st = { n = 0, t = now } end
			st.n = st.n % 4 + 1; st.t = now; comboState[ch] = st
			local airborne = false
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if hum then local s = hum:GetState(); airborne = s == Enum.HumanoidStateType.Freefall or s == Enum.HumanoidStateType.Jumping end
			play(ch, if airborne then "AirCombo" else "Combo" .. st.n)
		else play(ch, "Heavy") end
		local vic = nearestOther(ch, typeof(arg) == "Vector3" and arg or nil)
		local d = if kind == "Heavy" then 0.16 else 0.07
		task.delay(if kind == "Heavy" then 0.2 else 0.03, function()
			if vic then hitstop(ch, d); hitstop(vic, d); setExpr(vic, "Scream", 0.4) end
			setExpr(ch, "Angry", 0.5)
			if vic and (mine or vic == player.Character) then
				impactFrame(if kind == "Heavy" then 1 else 0.45); camKick(if kind == "Heavy" then 1.2 else 0.4)
				if kind == "Heavy" then speedLines(0.25) end
			end
		end)
	elseif kind == "KiBlast" then
		play(ch, "KiVolley"); setExpr(ch, "Angry", 0.6)
	elseif kind == "Launcher" or kind == "Uppercut" then
		play(ch, "Launcher")
	elseif kind == "Transform" then
		play(ch, "PowerUp"); setExpr(ch, "Scream", 1.4)
		if mine then speedLines(1, Color3.fromRGB(255, 230, 120)) end
	end
end)
ClientAPI.onCombatEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	local ch = data[1] and charByUser(data[1])
	if not ch then return end
	if kind == "Hit" then -- v1.2: victim hurt / KO reaction poses, alternating hurt sides
		local victim = ch
		if data[5] then play(victim, "KO") else
			m1Flip[victim] = not m1Flip[victim]; play(victim, if m1Flip[victim] then "Hurt1" else "Hurt2") end
		return
	end
	if kind == "Dash" then play(ch, "Dash"); afterimage(ch); return end
	if kind == "Vanish" or kind == "DashCancel" then
		play(ch, "Dash")
		afterimage(ch); task.delay(0.08, function() afterimage(ch) end)
		if ch == player.Character then speedLines(0.25) end
	elseif kind == "GuardBreak" or kind == "Parry" then
		local other = data[2] and charByUser(data[2])
		hitstop(ch, 0.12); if other then hitstop(other, 0.12) end
		if ch == player.Character or other == player.Character then impactFrame(0.8) end
	end
end)
-- guard pose while blocking, flight idle while airborne/flying (all players, polled)
local guardT: { [Model]: number } = {}
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, p in Players:GetPlayers() do
		local ch = p.Character
		if ch and (not active[ch] or active[ch].release) then
			if p:GetAttribute("Blocking") then
				if now - (guardT[ch] or 0) > 0.3 then guardT[ch] = now; play(ch, "Guard") end
			elseif p:GetAttribute("Flying") or ch:GetAttribute("Flying") then
				if now - (guardT[ch] or 0) > 0.55 then guardT[ch] = now; play(ch, "FlightIdle") end
			end
		end
	end
end)
ClientAPI.onRoundState:Connect(function(state, winners)
	if state == "Results" and player.Character and player:GetAttribute("Alive") then play(player.Character, "Victory") end
end)
-- ki charge (hold C) -> power-up pose loop for the local player
player:GetAttributeChangedSignal("Charging"):Connect(function()
	if player:GetAttribute("Charging") and player.Character then play(player.Character, "PowerUp") end
end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	scanSpeed()
	acc += dt
	if acc > 0.25 then acc = 0; updateOutlines(); updateFaces() end
end)

-- dev hook for screenshots: workspace attribute AnimePose = "<seq>" plays on the local character
workspace:GetAttributeChangedSignal("AnimePose"):Connect(function()
	local s = workspace:GetAttribute("AnimePose")
	if type(s) == "string" and player.Character then
		if s == "Afterimage" then afterimage(player.Character) elseif s == "SpeedLines" then speedLines(1.5)
		elseif s == "ImpactFrame" then impactFrame(1)
		elseif s:sub(1, 5) == "Expr_" then setExpr(player.Character, s:sub(6), 6)
		else play(player.Character, s) end
	end
end)
