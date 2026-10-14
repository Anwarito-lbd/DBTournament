--!strict
-- ModuleScript: ServerScriptService.Modules.Training (v1.2, db-gameplay hooks for db-map training areas)
-- Contract: map/training/training_spec.md. Builds the areas at runtime if the place doesn't have them yet.
--  * Portals (tag TrainingPortal, attr Destination) teleport to Training/<Dest>/Spawn_<Dest>; "Lobby" -> Spawn_Lobby_01.
--  * Zones (tag TrainingZone): player attribute TrainingArea; XP ticks = Config.TRAINING.baseXpPerMin x area mult;
--    gravity = extra downward VectorForce (capped) + walk/jump debuff; Zeni trickle.
--  * Gravity Room: Remotes.TrainingRequest("SetGravity", g) with g in [10,100] (slider) or any console step; XP scales.
--  * King Kai: "Catch Bubbles" minigame (touch Bubbles 3x in 45s); 3 clears -> KaioKen unlock.
--  * Whis: dodge/counter drill - Whis telegraphs strikes; press E (dodge) or F (counter) in the window.
--    10 successes = 1 drill clear; 3 clears -> UltraInstinctSign unlock (path to MUI).
-- Unlocks/XP go through PlayerData (no schema change: uses prof.unlocks and a profile field "training").
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)
local RateLimit = require(script.Parent.RateLimit)

local Training = {}
local TR = Config.TRAINING
local Req = Net.remote("TrainingRequest")
local Evt = Net.remote("TrainingEvent")

local function root(p: Player): BasePart? return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart? end
local function trainingRoot(): Instance?
	local w = workspace:FindFirstChild("WorldOfVoid"); return w and w:FindFirstChild("Training")
end
local function area(id: string): Instance? local t = trainingRoot(); return t and t:FindFirstChild(id) end
local function prog(p: Player): any
	local prof = PlayerData.get(p) :: any
	if not prof then return { kk = 0, whis = 0 } end
	prof.training = prof.training or { kk = 0, whis = 0 }
	return prof.training
end
local function unlock(p: Player, id: string)
	local prof = PlayerData.get(p) :: any
	if prof and not prof.unlocks[id] then prof.unlocks[id] = true; Evt:FireClient(p, "Unlocked", id) end
end
local function addZeni(p: Player, n: number)
	local prof = PlayerData.get(p) :: any
	if prof then prof.zeni = (prof.zeni or 0) + n end
	p:SetAttribute("Zeni", ((p:GetAttribute("Zeni") :: number?) or 0) + n)
end
Training.addZeni = addZeni

-- ===== teleport =====
local tpDebounce: { [Player]: number } = {}
function Training.teleport(p: Player, dest: string): boolean
	local r = root(p); if not r then return false end
	local target: BasePart?
	if dest == "Lobby" then
		local lobby = workspace:FindFirstChild("WorldOfVoid") and workspace.WorldOfVoid:FindFirstChild("Lobby")
		target = lobby and lobby:FindFirstChild("Spawn_Lobby_01") :: BasePart?
	else
		local a = area(dest); target = a and a:FindFirstChild("Spawn_" .. dest, true) :: BasePart?
	end
	if not target then return false end
	r.AssemblyLinearVelocity = Vector3.zero
	r.CFrame = CFrame.new(target.Position + Vector3.new(0, 4, 0))
	Evt:FireClient(p, "Teleported", dest)
	return true
end
local function hookPad(pad: Instance)
	if not pad:IsA("BasePart") then return end
	pad.Touched:Connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if not p or os.clock() - (tpDebounce[p] or 0) < 2 then return end
		if workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") then return end
		tpDebounce[p] = os.clock()
		Training.teleport(p, (pad:GetAttribute("Destination") :: string?) or "TrainingHub")
	end)
end

-- ===== zones, xp, gravity =====
local gravity: { [Player]: number } = {} -- gravity room setting per player (multiplier)
local function zoneOf(p: Player): (string?, Instance?)
	local r = root(p); if not r then return nil end
	for _, z in CollectionService:GetTagged("TrainingZone") do
		if z:IsA("BasePart") then
			local lp = z.CFrame:PointToObjectSpace(r.Position)
			local h = z.Size / 2
			if math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z then
				return z:GetAttribute("AreaId") :: string, z
			end
		end
	end
	return nil
end
local function gravityRoomXp(g: number): number
	-- slider 10..100 maps onto Config steps' xp curve (10->1.2 ... 100->1.6); steps above 100 keep Config values
	local steps, xs = TR.GravityRoom.steps, TR.GravityRoom.xpMultAtStep
	for i = #steps, 1, -1 do
		if g >= steps[i] then
			local j = math.min(i + 1, #steps)
			local k = if j == i then 0 else (g - steps[i]) / (steps[j] - steps[i])
			return xs[i] + (xs[j] - xs[i]) * k
		end
	end
	return 1
end
local function areaMult(p: Player, id: string): (number, number)
	if id == "HyperbolicTimeChamber" then return TR.HyperbolicTimeChamber.xpMult, TR.HyperbolicTimeChamber.gravity end
	if id == "KingKaiPlanet" then return TR.KingKaiPlanet.xpMult, TR.KingKaiPlanet.gravity end
	if id == "WhisGround" then return TR.WhisGround.xpMult, TR.WhisGround.gravity end
	if id == "GravityRoom" then local g = gravity[p] or 10; return gravityRoomXp(g), g end
	return 1, 1
end
local function applyGravity(p: Player, g: number)
	local ch = p.Character; local r = root(p); local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not r or not hum then return end
	local vf = r:FindFirstChild("TrainingGravity") :: VectorForce?
	local att = r:FindFirstChild("TrainingGravityAtt") :: Attachment?
	if g <= 1.01 then
		if vf then vf:Destroy() end; if att then att:Destroy() end
		if ch:GetAttribute("BaseWalk") then hum.WalkSpeed = ch:GetAttribute("BaseWalk") :: number; hum.JumpPower = ch:GetAttribute("BaseJump") :: number end
		ch:SetAttribute("BaseWalk", nil); ch:SetAttribute("BaseJump", nil)
		return
	end
	if not ch:GetAttribute("BaseWalk") then ch:SetAttribute("BaseWalk", hum.WalkSpeed); ch:SetAttribute("BaseJump", hum.JumpPower) end
	if not att then att = Instance.new("Attachment"); att.Name = "TrainingGravityAtt"; att.Parent = r end
	if not vf then vf = Instance.new("VectorForce"); vf.Name = "TrainingGravity"; vf.RelativeTo = Enum.ActuatorRelativeTo.World; vf.ApplyAtCenterOfMass = true; vf.Parent = r end
	vf.Attachment0 = att
	-- feel: up to 2x extra weight physically (beyond that Humanoids become unplayable); the rest is a move debuff
	local extra = math.clamp(math.log(g, 10), 0, 2)
	vf.Force = Vector3.new(0, -r.AssemblyMass * workspace.Gravity * extra, 0)
	local slow = math.clamp(1 - 0.0065 * g, 0.35, 1)
	hum.WalkSpeed = (ch:GetAttribute("BaseWalk") :: number) * slow
	hum.JumpPower = (ch:GetAttribute("BaseJump") :: number) * math.clamp(1 - 0.004 * g, 0.5, 1)
end

-- ===== King Kai: Catch Bubbles =====
local bubbles: Model? = nil
local chase: { [Player]: { hits: number, untilT: number } } = {}
local function makeMonkey(at: Vector3): Model
	local m = Instance.new("Model"); m.Name = "Bubbles"
	local function bp(n: string, s: Vector3, cf: CFrame, c: Color3, shape: Enum.PartType?)
		local x = Instance.new("Part"); x.Name = n; x.Size = s; x.CFrame = cf; x.Color = c; x.Anchored = true; x.CanCollide = false
		if shape then x.Shape = shape end; x.Parent = m; return x
	end
	local body = bp("Body", Vector3.new(2.2, 2.6, 2), CFrame.new(at), Color3.fromRGB(150, 95, 50), Enum.PartType.Ball)
	bp("Head", Vector3.new(1.8, 1.8, 1.8), CFrame.new(at + Vector3.new(0, 2, 0)), Color3.fromRGB(150, 95, 50), Enum.PartType.Ball)
	bp("Face", Vector3.new(1.2, 1.1, 0.6), CFrame.new(at + Vector3.new(0, 1.9, -0.7)), Color3.fromRGB(240, 200, 160), Enum.PartType.Ball)
	bp("EarL", Vector3.new(0.7, 0.7, 0.3), CFrame.new(at + Vector3.new(-1, 2.2, 0)), Color3.fromRGB(240, 200, 160), Enum.PartType.Ball)
	bp("EarR", Vector3.new(0.7, 0.7, 0.3), CFrame.new(at + Vector3.new(1, 2.2, 0)), Color3.fromRGB(240, 200, 160), Enum.PartType.Ball)
	bp("Tail", Vector3.new(0.3, 0.3, 2.2), CFrame.new(at + Vector3.new(0, 0, 1.4)) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(150, 95, 50))
	m.PrimaryPart = body
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromOffset(160, 30); bb.StudsOffset = Vector3.new(0, 4, 0); bb.AlwaysOnTop = true; bb.Parent = body
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Text = "Bubbles (catch me!)"; t.TextScaled = true
	t.Font = Enum.Font.GothamBold; t.TextColor3 = Color3.fromRGB(255, 230, 120); t.TextStrokeTransparency = 0; t.Parent = bb
	return m
end
local function kkTop(): Vector3?
	local a = area("KingKaiPlanet"); if not a then return nil end
	local spot = a:FindFirstChild("NPC_Bubbles", true) :: BasePart?
	return spot and spot.Position
end
function Training.startChase(p: Player): boolean
	if chase[p] then return false end
	chase[p] = { hits = 0, untilT = os.clock() + 45 }
	Evt:FireClient(p, "ChaseStart", 45)
	return true
end
local function tickBubbles(t: number)
	local top = kkTop(); if not top then return end
	if not bubbles or not bubbles.Parent then bubbles = makeMonkey(top + Vector3.new(0, 1.5, 0)); (bubbles :: Model).Parent = area("KingKaiPlanet") end
	local m = bubbles :: Model
	-- run a loop around the planet top; dart away from the nearest chaser
	local a = area("KingKaiPlanet") :: Instance
	local centre = (a:GetAttribute("Origin") :: Vector3?) or Vector3.new(9000, 300, 0)
	local ang = t * 0.9
	local pos = top + Vector3.new(math.cos(ang) * 14, 1.5 + math.abs(math.sin(t * 6)) * 0.8, math.sin(ang * 1.3) * 14)
	local up = (pos - centre).Unit
	m:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)), up))
	for p, st in chase do
		local r = root(p)
		if not p.Parent or not r or os.clock() > st.untilT then
			chase[p] = nil
			if p.Parent then Evt:FireClient(p, "ChaseFail", st.hits) end
		elseif (r.Position - pos).Magnitude < 5 then
			st.hits += 1
			st.untilT = math.max(st.untilT, os.clock() + 3) -- small grace after each catch
			Evt:FireClient(p, "ChaseHit", st.hits)
			m:PivotTo(m:GetPivot() + Vector3.new(0, 6, 0))
			if st.hits >= 3 then
				chase[p] = nil
				local pr = prog(p); pr.kk += 1
				PlayerData.addXP(p, 60, true); addZeni(p, 75)
				Evt:FireClient(p, "ChaseClear", pr.kk, TR.KingKaiPlanet.clearsToUnlock)
				if pr.kk >= TR.KingKaiPlanet.clearsToUnlock then unlock(p, TR.KingKaiPlanet.unlock) end
			end
		end
	end
end

-- ===== Whis: dodge / counter drills =====
local whis: Model? = nil
local drill: { [Player]: { ok: number, miss: number, strikeAt: number, kind: string, answered: boolean } } = {}
local function makeWhis(at: Vector3): Model
	local m = Instance.new("Model"); m.Name = "Whis"
	local function bp(n: string, s: Vector3, off: CFrame, c: Color3, shape: Enum.PartType?, mat: Enum.Material?)
		local x = Instance.new("Part"); x.Name = n; x.Size = s; x.CFrame = CFrame.new(at) * off; x.Color = c; x.Anchored = true; x.CanCollide = false
		if shape then x.Shape = shape end; if mat then x.Material = mat end; x.Parent = m; return x
	end
	local robe = bp("Robe", Vector3.new(2.6, 5, 2), CFrame.new(0, 2.5, 0), Color3.fromRGB(40, 40, 80))
	bp("Sash", Vector3.new(2.7, 0.6, 2.1), CFrame.new(0, 2.6, 0), Color3.fromRGB(220, 30, 40))
	bp("Head", Vector3.new(1.6, 1.8, 1.6), CFrame.new(0, 5.9, 0), Color3.fromRGB(150, 170, 230), Enum.PartType.Ball)
	bp("Hair", Vector3.new(1.2, 2.6, 1.2), CFrame.new(0, 7.4, 0.2), Color3.fromRGB(235, 240, 255), Enum.PartType.Cylinder)
	bp("Halo", Vector3.new(0.4, 3.6, 3.6), CFrame.new(0, 4.6, 0.6) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 220, 255), Enum.PartType.Cylinder, Enum.Material.Neon)
	bp("Staff", Vector3.new(0.3, 8, 0.3), CFrame.new(1.8, 3.8, 0), Color3.fromRGB(235, 235, 240), nil, Enum.Material.Metal)
	bp("StaffOrb", Vector3.new(1.2, 1.2, 1.2), CFrame.new(1.8, 8, 0), Color3.fromRGB(120, 220, 255), Enum.PartType.Ball, Enum.Material.Neon)
	m.PrimaryPart = robe
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromOffset(200, 30); bb.StudsOffset = Vector3.new(0, 9, 0); bb.AlwaysOnTop = true; bb.Parent = robe
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Text = "Whis - Sparring"; t.TextScaled = true
	t.Font = Enum.Font.GothamBold; t.TextColor3 = Color3.fromRGB(180, 230, 255); t.TextStrokeTransparency = 0; t.Parent = bb
	return m
end
local function whisSpot(): Vector3?
	local a = area("WhisGround"); if not a then return nil end
	for _, d in a:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("NPC") == "Whis" then return d.Position end
	end
	local s = a:FindFirstChild("Spawn_WhisGround", true) :: BasePart?
	return s and s.Position + Vector3.new(0, 0, -14)
end
function Training.startDrill(p: Player): boolean
	if drill[p] then return false end
	drill[p] = { ok = 0, miss = 0, strikeAt = os.clock() + 2, kind = "Dodge", answered = false }
	Evt:FireClient(p, "DrillStart", 10)
	return true
end
local WINDOW_BEFORE, WINDOW_AFTER = 0.45, 0.25
local function tickWhis()
	local spot = whisSpot(); if not spot then return end
	if not whis or not whis.Parent then whis = makeWhis(spot); (whis :: Model).Parent = area("WhisGround") end
	local now = os.clock()
	for p, d in drill do
		local r = root(p)
		if not p.Parent or not r then drill[p] = nil; continue end
		local w = whis :: Model
		w:PivotTo(CFrame.lookAt(w:GetPivot().Position, Vector3.new(r.Position.X, w:GetPivot().Position.Y, r.Position.Z)))
		if not d.answered and now > d.strikeAt + WINDOW_AFTER then
			d.miss += 1; Evt:FireClient(p, "DrillResult", false, d.ok, d.kind)
			d.answered = true
		end
		if d.answered and now > d.strikeAt + 0.6 then
			-- next strike: telegraph 0.9 s ahead, random type (dodge = vanish E, counter = block F)
			d.kind = if math.random() < 0.5 then "Dodge" else "Counter"
			d.strikeAt = now + 0.9 + math.random() * 0.8; d.answered = false
			Evt:FireClient(p, "DrillTelegraph", d.kind, d.strikeAt - now)
		end
		if d.miss >= 6 then drill[p] = nil; Evt:FireClient(p, "DrillFail", d.ok) end
	end
end
local function drillInput(p: Player, kind: string)
	local d = drill[p]; if not d or d.answered then return end
	local now = os.clock()
	if now < d.strikeAt - WINDOW_BEFORE then return end -- too early: ignore (no spam penalty)
	d.answered = true
	local ok = kind == d.kind and now <= d.strikeAt + WINDOW_AFTER
	if ok then d.ok += 1 else d.miss += 1 end
	Evt:FireClient(p, "DrillResult", ok, d.ok, d.kind)
	if d.ok >= 10 then
		drill[p] = nil
		local pr = prog(p); pr.whis += 1
		PlayerData.addXP(p, 120, true); addZeni(p, 150)
		Evt:FireClient(p, "DrillClear", pr.whis, 3)
		if pr.whis >= 3 then unlock(p, "UltraInstinctSign") end
	end
end

-- ===== remotes =====
Req.OnServerEvent:Connect(function(p, action, arg)
	if not RateLimit.allow(p, "training", 8, 8) then return end
	local here = zoneOf(p)
	if action == "SetGravity" and type(arg) == "number" and here == "GravityRoom" then
		local g = math.clamp(math.floor(arg + 0.5), 1, 500)
		gravity[p] = g
		local a = area("GravityRoom")
		local console = a and a:FindFirstChild("GR_Console", true)
		if console then console:SetAttribute("GravityMultiplier", g) end
		local ro = a and a:FindFirstChild("GR_Readout", true)
		local lbl = ro and ro:FindFirstChildWhichIsA("TextLabel", true)
		if lbl then (lbl :: TextLabel).Text = g .. "G" end
		p:SetAttribute("TrainingGravity", g)
	elseif action == "StartChase" and here == "KingKaiPlanet" then Training.startChase(p)
	elseif action == "StartDrill" and here == "WhisGround" then Training.startDrill(p)
	elseif action == "Drill" and (arg == "Dodge" or arg == "Counter") then drillInput(p, arg)
	elseif action == "Teleport" and type(arg) == "string" and (arg == "TrainingHub" or arg == "Lobby") then
		if not (workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive")) then Training.teleport(p, arg) end
	end
end)

local xpAcc: { [Player]: number } = {}
function Training.init()
	if (Config :: any).TRAINING_RUNTIME and (Config :: any).TRAINING_RUNTIME.owner ~= "Training" then return end -- lead: TrainingRooms owns training
	if not trainingRoot() then
		local mod = ServerScriptService:FindFirstChild("TrainingAreas")
		if mod then
			local ok, err = pcall(function() (require(mod :: ModuleScript) :: any).BuildAll() end)
			if not ok then warn("[Training] BuildAll failed: " .. tostring(err)) end
		end
	end
	for _, pad in CollectionService:GetTagged("TrainingPortal") do hookPad(pad) end
	CollectionService:GetInstanceAddedSignal("TrainingPortal"):Connect(hookPad)
	for _, fz in CollectionService:GetTagged("TrainingFallZone") do
		if fz:IsA("BasePart") then
			fz.CanTouch = true
			fz.Touched:Connect(function(hit)
				local p = Players:GetPlayerFromCharacter(hit.Parent)
				if p then Training.teleport(p, (fz:GetAttribute("AreaId") :: string?) or "TrainingHub") end
			end)
		end
	end
	local t0 = os.clock()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		tickWhis()
		tickBubbles(os.clock() - t0)
		if acc < 1 then return end
		local step = acc; acc = 0
		for _, p in Players:GetPlayers() do
			local id = zoneOf(p)
			if p:GetAttribute("TrainingArea") ~= id then p:SetAttribute("TrainingArea", id) end
			if id and id ~= "TrainingHub" and id ~= "Shop" then
				local mult, g = areaMult(p, id)
				p:SetAttribute("TrainingXPMult", math.floor(mult * 100 + 0.5) / 100)
				applyGravity(p, g)
				xpAcc[p] = (xpAcc[p] or 0) + TR.baseXpPerMin / 60 * mult * step
				if xpAcc[p] >= 5 then
					local n = math.floor(xpAcc[p]); xpAcc[p] -= n
					PlayerData.addXP(p, n, true); addZeni(p, math.max(1, n // 5))
					Evt:FireClient(p, "XP", n, mult)
				end
			else
				p:SetAttribute("TrainingXPMult", nil)
				applyGravity(p, 1)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p) gravity[p] = nil; chase[p] = nil; drill[p] = nil; xpAcc[p] = nil; tpDebounce[p] = nil end)
end

return Training
