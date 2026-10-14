--!strict
-- ModuleScript: ServerScriptService.Modules.TrainingRooms  (server logic for db-map training areas, training_spec.md v1.2)
-- Map contract (tags/attrs from map/training/TrainingAreas.lua): Workspace.WorldOfVoid.Training/<AreaId>, TrainingPortal pads
-- (Destination), TrainingSpawn (Spawn_<AreaId>), TrainingZone (Zone_<AreaId>: AreaId, GravityMultiplier, XPMultiplier...),
-- TrainingFallZone, GravityConsole (GravityMultiplier/Min/Max), GR_Readout label, TrainingNPCSpot (NPC=...).
-- Server does: teleports (debounced), zone tracking (attr TrainingArea + LightingPreset for the client), gravity
-- (VectorForce + Gravity Room speed table), XP over time x area multiplier, HTC visits/day + max stay, Gravity Room
-- console (validated remote), drills (dodge / catch / collect / hold / endure) with rewards and earned-early unlocks.
-- Remotes: SetGravity(g), StartDrill(drillId), DrillUpdate (server->client: kind, data).
-- Training never grants stats: only XP, Zeni, drinks, and earned-early unlocks (still normal Power Level rules).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local QuestService = require(script.Parent.QuestService)
local Combat = require(script.Parent.Combat)
local TrainingBots = require(script.Parent.TrainingBots)
local TrainingMath = require(game:GetService("ReplicatedStorage").Shared.TrainingMath)

local TrainingRooms = {}
local RT = Config.TRAINING_RUNTIME
local OWNER = RT.owner == "TrainingRooms" -- false: Training.lua (v1.2) owns portals/zones/gravity/XP; we read its TrainingArea attr
local SetGravity = Net.remote("SetGravity")
local StartDrill = Net.remote("StartDrill")
local DrillUpdate = Net.remote("DrillUpdate")

type PS = { area: string?, enteredAt: number, xpAcc: number, minuteAcc: number, gAt300: number, gDone: boolean,
	lastTp: number, drill: string?, baseSpeed: number? }
local ps: { [Player]: PS } = {}
local function S(p: Player): PS
	local s = ps[p]
	if not s then s = { area = nil, enteredAt = 0, xpAcc = 0, minuteAcc = 0, gAt300 = 0, gDone = false, lastTp = -1e9, drill = nil }; ps[p] = s end
	return s :: PS
end
local function root(p: Player): BasePart? return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart? end
local function hum(p: Player): Humanoid? return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function inMatch(p: Player): boolean
	return workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") == true
end

local function trainingFolder(): Instance?
	local w = workspace:FindFirstChild("WorldOfVoid")
	return w and w:FindFirstChild("Training")
end
function TrainingRooms.areaFolder(areaId: string): Instance?
	local t = trainingFolder()
	return t and t:FindFirstChild(areaId)
end
local function spawnOf(dest: string): BasePart?
	if dest == "Lobby" then
		local w = workspace:FindFirstChild("WorldOfVoid") or workspace
		return w:FindFirstChild("Spawn_Lobby_01", true) :: BasePart?
	end
	local f = TrainingRooms.areaFolder(dest)
	return f and f:FindFirstChild("Spawn_" .. dest, true) :: BasePart?
end
function TrainingRooms.npcSpot(npc: string): BasePart?
	for _, x in CollectionService:GetTagged("TrainingNPCSpot") do
		if x:GetAttribute("NPC") == npc and x:IsA("BasePart") then return x end
	end
	return nil
end

function TrainingRooms.teleport(p: Player, dest: string): boolean
	local r, sp = root(p), spawnOf(dest)
	if not r or not sp then return false end
	S(p).lastTp = os.clock()
	r.AssemblyLinearVelocity = Vector3.zero
	r.CFrame = sp.CFrame + Vector3.new(0, 3, 0)
	return true
end

-- ===== portals / fall zones =====
local function hookPortal(pad: Instance)
	if not pad:IsA("BasePart") then return end
	pad.Touched:Connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if not p or inMatch(p) then return end
		local s = S(p)
		if os.clock() - s.lastTp < RT.teleportDebounce or s.drill then return end
		local dest = pad:GetAttribute("Destination")
		if type(dest) ~= "string" then return end
		if dest == "HyperbolicTimeChamber" and not TrainingRooms.htcAdmit(p) then return end
		TrainingRooms.teleport(p, dest)
	end)
end
local function hookFall(z: Instance)
	if not z:IsA("BasePart") then return end
	z.CanTouch = true
	z.Touched:Connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		local area = z:GetAttribute("AreaId")
		if p and type(area) == "string" and os.clock() - S(p).lastTp > 0.5 then TrainingRooms.teleport(p, area) end
	end)
end

-- HTC: 3 free visits per UTC day, then 200 Zeni per visit.
function TrainingRooms.htcAdmit(p: Player): boolean
	local prof = PlayerData.get(p) :: any
	if not prof then return false end
	local today = os.time() // 86400
	local t = prof.training
	if t.htcDay ~= today then t.htcDay = today; t.htcVisits = 0 end
	if t.htcVisits >= RT.htcFreeVisitsPerDay then
		if not PlayerData.spendZeni(p, RT.htcExtraVisitZeni) then
			DrillUpdate:FireClient(p, "HTCDenied", { cost = RT.htcExtraVisitZeni }); return false
		end
	end
	t.htcVisits += 1
	return true
end

-- ===== zones =====
local function inside(part: BasePart, pos: Vector3): boolean
	local lp = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end
local function zoneAt(pos: Vector3): BasePart?
	for _, z in CollectionService:GetTagged("TrainingZone") do
		-- v8b: db-map raid zones are also TrainingZone-tagged (attr RaidId): not training areas (no XP / gravity / lighting)
		if z:IsA("BasePart") and z:GetAttribute("RaidId") == nil and inside(z, pos) then return z end
	end
	return nil
end
local function console(): BasePart?
	local c = CollectionService:GetTagged("GravityConsole")[1]
	return if c and c:IsA("BasePart") then c else nil
end
local function areaGravity(areaId: string, z: BasePart): number
	if areaId == "GravityRoom" then
		local c = console()
		return (c and c:GetAttribute("GravityMultiplier") :: number?) or 1
	end
	return (z:GetAttribute("GravityMultiplier") :: number?) or 1
end
local function stepIndex(g: number): number return TrainingMath.stepIndex(Config.TRAINING.GravityRoom.steps, g) end
local function xpMult(areaId: string, z: BasePart, g: number): number
	if areaId == "GravityRoom" then return Config.TRAINING.GravityRoom.xpMultAtStep[stepIndex(g)] end
	local f = TrainingRooms.areaFolder(areaId)
	return (z:GetAttribute("XPMultiplier") :: number?) or (f and f:GetAttribute("XPMultiplier") :: number?)
		or ((Config.TRAINING :: any)[areaId] and (Config.TRAINING :: any)[areaId].xpMult) or 1
end

local function setGravityForce(p: Player, g: number, areaId: string?)
	local r, h = root(p), hum(p)
	if not r or not h then return end
	local vf = r:FindFirstChild("TrainingGravity") :: VectorForce?
	local extra = TrainingMath.extraG(g, RT.gravityExtraPerG, RT.gravityExtraMax)
	if extra <= 0 then
		if vf then vf:Destroy() end
	else
		if not vf then
			local att = r:FindFirstChild("RootRigAttachment") :: Attachment? or Instance.new("Attachment", r)
			local n = Instance.new("VectorForce")
			n.Name = "TrainingGravity"; n.Attachment0 = att; n.RelativeTo = Enum.ActuatorRelativeTo.World
			n.ApplyAtCenterOfMass = true; n.Parent = r
			vf = n
		end
		(vf :: VectorForce).Force = Vector3.new(0, -r.AssemblyMass * workspace.Gravity * extra, 0)
	end
	local s = S(p)
	if not s.baseSpeed then s.baseSpeed = h.WalkSpeed end
	local mult = if areaId == "GravityRoom" then Config.TRAINING.GravityRoom.moveSpeedAtStep[stepIndex(g)] else 1
	h.WalkSpeed = (s.baseSpeed :: number) * mult
	p:SetAttribute("TrainingGravity", g)
end

local function leaveArea(p: Player)
	local s = S(p)
	s.area = nil
	setGravityForce(p, 1, nil)
	s.baseSpeed = nil
	p:SetAttribute("TrainingArea", nil)
	p:SetAttribute("TrainingXPMult", nil)
	p:SetAttribute("LightingPreset", "Lobby")
end

-- ===== Gravity console =====
SetGravity.OnServerEvent:Connect(function(p, g)
	if not OWNER or type(g) ~= "number" or not RateLimit.allow(p, "gravity", 1, 2) then return end
	local c, r = console(), root(p)
	if not c or not r or S(p).area ~= "GravityRoom" then return end -- v8: room-wide (TrainingUI slider); console range dropped
	if not table.find(Config.TRAINING.GravityRoom.steps, g) then return end
	local gmin, gmax = (c:GetAttribute("GravityMin") :: number?) or 1, (c:GetAttribute("GravityMax") :: number?) or 500
	if g < gmin or g > gmax then return end
	c:SetAttribute("GravityMultiplier", g)
	local f = TrainingRooms.areaFolder("GravityRoom")
	local z = f and f:FindFirstChild("Zone_GravityRoom")
	if z then z:SetAttribute("GravityMultiplier", g) end
	local ro = f and f:FindFirstChild("GR_Readout", true)
	local lbl = ro and ro:FindFirstChildWhichIsA("TextLabel", true)
	if lbl then (lbl :: TextLabel).Text = tostring(g) .. "G" end
end)

-- ===== Drills =====
local drills: { [string]: (Player) -> () } = {}
function TrainingRooms.registerDrill(id: string, fn: (Player) -> ()) drills[id] = fn end

local function newOrb(pos: Vector3, color: Color3, size: number): Part
	local o = Instance.new("Part")
	o.Shape = Enum.PartType.Ball; o.Size = Vector3.new(size, size, size); o.Material = Enum.Material.Neon; o.Color = color
	o.Anchored = true; o.CanCollide = false; o.CanQuery = false; o.CanTouch = false; o.CastShadow = false
	o.Position = pos; o.Name = "DrillOrb"
	o.Parent = TrainingRooms.areaFolder("WhisGround") or workspace
	return o
end

-- Generic dodge drill: straight-flying orbs aimed at the player's position at launch; hit = fail (or counted if allowHits).
-- Returns success, hits.
function TrainingRooms.dodge(p: Player, seconds: number, speed: number, every: number, color: Color3, allowHits: boolean?): (boolean, number)
	local orbs: { { part: Part, dir: Vector3, t: number } } = {}
	local t0, nextSpawn, hits = os.clock(), os.clock(), 0
	local ok = true
	while os.clock() - t0 < seconds do
		local dt = task.wait(0.05)
		local r = root(p)
		local h = hum(p)
		if not r or not h or h.Health <= 0 or not p.Parent or inMatch(p) then ok = false; break end
		if os.clock() >= nextSpawn then
			nextSpawn = os.clock() + every
			local a = math.random() * math.pi * 2
			local from = r.Position + Vector3.new(math.cos(a) * 45, 4 + math.random() * 6, math.sin(a) * 45)
			local o = newOrb(from, color, 3)
			table.insert(orbs, { part = o, dir = (r.Position - from).Unit, t = os.clock() })
		end
		for i = #orbs, 1, -1 do
			local o = orbs[i]
			o.part.Position += o.dir * speed * dt
			if (o.part.Position - r.Position).Magnitude <= 3.2 then
				hits += 1; o.part:Destroy(); table.remove(orbs, i)
				DrillUpdate:FireClient(p, "Hit", { hits = hits })
				if not allowHits then ok = false; break end
			elseif os.clock() - o.t > 4 then o.part:Destroy(); table.remove(orbs, i) end
		end
		if not ok then break end
		DrillUpdate:FireClient(p, "Progress", { t = os.clock() - t0, total = seconds })
	end
	for _, o in orbs do o.part:Destroy() end
	return ok, hits
end

-- Reach N moving/static markers within the time limit (catch Bubbles / hit Gregory / collect orbs / hold Hakai targets).
function TrainingRooms.reach(p: Player, center: Vector3, count: number, seconds: number, radius: number, moveEvery: number?,
	hold: number?, color: Color3): boolean
	local t0, got = os.clock(), 0
	local function spot(): Vector3
		local a, d = math.random() * math.pi * 2, 10 + math.random() * radius
		return center + Vector3.new(math.cos(a) * d, 2, math.sin(a) * d)
	end
	local markers = {}
	local n = if moveEvery then 1 else count
	for _ = 1, n do table.insert(markers, { part = newOrb(spot(), color, 4), since = nil :: number?, moved = os.clock() }) end
	while os.clock() - t0 < seconds and got < count do
		task.wait(0.1)
		local r = root(p)
		if not r or not p.Parent or inMatch(p) then break end
		for i = #markers, 1, -1 do
			local m = markers[i]
			local near = (m.part.Position - r.Position).Magnitude <= (if hold then 8 else 6)
			if near and hold then m.since = m.since or os.clock() elseif not near then m.since = nil end
			if near and (not hold or os.clock() - (m.since :: number) >= hold) then
				got += 1
				DrillUpdate:FireClient(p, "Progress", { got = got, total = count })
				if moveEvery and got < count then m.part.Position = spot(); m.moved = os.clock(); m.since = nil
				else m.part:Destroy(); table.remove(markers, i) end
			elseif moveEvery and os.clock() - m.moved > moveEvery then
				m.part.Position = spot(); m.moved = os.clock()
			end
		end
	end
	for _, m in markers do m.part:Destroy() end
	return got >= count
end

local function finish(p: Player, id: string, ok: boolean, reward: any?)
	DrillUpdate:FireClient(p, "Result", { id = id, ok = ok, reward = if ok then reward else nil })
	if ok then
		QuestService.track(p, "drill", 1)
		if reward then PlayerData.grantReward(p, reward) end
	end
end
TrainingRooms.finish = finish

StartDrill.OnServerEvent:Connect(function(p, id)
	if type(id) ~= "string" or not RateLimit.allow(p, "drill", 1, 2) then return end
	local s = S(p)
	if s.drill or inMatch(p) or not drills[id] then return end
	s.drill = id
	task.spawn(function()
		local ok, err = pcall(drills[id], p)
		if not ok then warn("[TrainingRooms] drill " .. id .. " error: " .. tostring(err)) end
		s.drill = nil
	end)
end)

local D = RT.drills
local function profileT(p: Player): any? local prof = PlayerData.get(p) :: any; return prof and prof.training end

drills.WhisDodge = function(p)
	local t = profileT(p)
	if not t or S(p).area ~= D.WhisDodge.area or t.whisStage >= D.WhisDodge.stages then return end
	local stage = t.whisStage + 1
	local cfg = D.WhisDodge
	DrillUpdate:FireClient(p, "Start", { id = "WhisDodge", stage = stage, seconds = cfg.seconds })
	local ok = TrainingRooms.dodge(p, cfg.seconds, cfg.orbSpeed0 + cfg.orbSpeedPer * stage,
		math.max(0.4, cfg.orbEvery0 + cfg.orbEveryPer * stage), Color3.fromRGB(120, 200, 255))
	if ok then
		t.whisStage = stage
		if stage >= cfg.stages then PlayerData.grantReward(p, cfg.pathReward) end -- UI Sign earned at Lv70
	end
	finish(p, "WhisDodge", ok, cfg.reward)
end

local function kingKai(p: Player, id: string)
	local cfg = (D :: any)[id]
	local t = profileT(p)
	if not t or S(p).area ~= cfg.area then return end
	local center = (TrainingRooms.npcSpot(if id == "CatchBubbles" then "Bubbles" else "KingKai") :: BasePart?)
	local r = root(p)
	if not r then return end
	DrillUpdate:FireClient(p, "Start", { id = id, seconds = cfg.seconds })
	local ok = TrainingRooms.reach(p, if center then center.Position else r.Position, cfg.catches, cfg.seconds, 25,
		if id == "CatchBubbles" then 3 else 2, nil, if id == "CatchBubbles" then Color3.fromRGB(255, 230, 120) else Color3.fromRGB(90, 200, 90))
	if ok then
		t.kkClears += 1
		if t.kkClears >= RT.kingKaiClearsToUnlock then PlayerData.grantEarly(p, RT.kingKaiUnlock, RT.kingKaiEarlyLevel) end
	end
	finish(p, id, ok, cfg.reward)
end
drills.CatchBubbles = function(p) kingKai(p, "CatchBubbles") end
drills.HitGregory = function(p) kingKai(p, "HitGregory") end

drills.HTCEndure = function(p)
	local cfg = D.HTCEndure
	if S(p).area ~= cfg.area then return end
	DrillUpdate:FireClient(p, "Start", { id = "HTCEndure", seconds = cfg.seconds })
	local t0, ok = os.clock(), true
	while os.clock() - t0 < cfg.seconds do
		task.wait(1)
		if S(p).area ~= cfg.area or not p.Parent then ok = false; break end
		DrillUpdate:FireClient(p, "Progress", { t = os.clock() - t0, total = cfg.seconds })
	end
	finish(p, "HTCEndure", ok, cfg.reward)
end

-- ===== main tick: zones, gravity, XP, HTC stay, Gravity Room quest =====
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < RT.tick then return end
	local step = acc
	acc = 0
	for _, p in Players:GetPlayers() do
		local r = root(p)
		local s = S(p)
		if not OWNER then -- passive mode: area from Training.lua's attribute; only quest tracking here
			local a = p:GetAttribute("TrainingArea") :: string?
			if a ~= s.area then s.area = a; s.enteredAt = os.clock(); s.gDone = false; s.gAt300 = 0 end
			if a and not inMatch(p) then
				s.minuteAcc += step
				if s.minuteAcc >= 60 then s.minuteAcc -= 60; QuestService.track(p, "trainMinutes", 1) end
				if a == "GravityRoom" then
					local c = console()
					local g = (c and c:GetAttribute("GravityMultiplier") :: number?) or (p:GetAttribute("TrainingGravity") :: number?) or 1
					if g >= RT.gravityQuest.step then s.gAt300 += step else s.gAt300 = 0 end
					if not s.gDone and s.gAt300 >= RT.gravityQuest.seconds then s.gDone = true; QuestService.track(p, "gravity300", 1) end
				end
			end
			continue
		end
		if not r or inMatch(p) then
			if s.area then leaveArea(p) end
			continue
		end
		local z = zoneAt(r.Position)
		local areaId = z and z:GetAttribute("AreaId") :: string?
		if areaId ~= s.area then
			if s.area then leaveArea(p) end
			if areaId and z then
				s.area = areaId; s.enteredAt = os.clock(); s.gDone = false; s.gAt300 = 0
				local f = TrainingRooms.areaFolder(areaId)
				p:SetAttribute("TrainingArea", areaId)
				p:SetAttribute("LightingPreset", (f and f:GetAttribute("LightingPreset")) or "Lobby")
			end
		end
		if not areaId or not z then continue end
		local g = areaGravity(areaId, z)
		setGravityForce(p, g, areaId)
		-- XP over time (hub has multiplier 1 but still counts as training)
		s.xpAcc += step
		if s.xpAcc >= RT.xpEvery then
			local mult = xpMult(areaId, z, g)
			p:SetAttribute("TrainingXPMult", math.floor(mult * 100 + 0.5) / 100)
			PlayerData.addXP(p, Config.TRAINING.baseXpPerMin * mult * s.xpAcc / 60)
			s.minuteAcc += s.xpAcc
			s.xpAcc = 0
			if s.minuteAcc >= 60 then s.minuteAcc -= 60; QuestService.track(p, "trainMinutes", 1) end
		end
		if areaId == "HyperbolicTimeChamber" then
			local f = TrainingRooms.areaFolder(areaId)
			local maxStay = (f and f:GetAttribute("MaxStaySeconds") :: number?) or Config.TRAINING.HyperbolicTimeChamber.maxStaySeconds
			p:SetAttribute("HTCTimeLeft", math.max(0, math.floor(maxStay - (os.clock() - s.enteredAt))))
			if os.clock() - s.enteredAt >= maxStay and not s.drill then TrainingRooms.teleport(p, "TrainingHub") end
		elseif areaId == "GravityRoom" then
			if g >= RT.gravityQuest.step then s.gAt300 += step else s.gAt300 = 0 end
			if not s.gDone and s.gAt300 >= RT.gravityQuest.seconds then s.gDone = true; QuestService.track(p, "gravity300", 1) end
		end
	end
end)

function TrainingRooms.init()
	if not OWNER then
		warn("[TrainingRooms] passive mode (Config.TRAINING_RUNTIME.owner = Training): drills/Beerus/quests only")
		Players.PlayerRemoving:Connect(function(p) ps[p] = nil end)
		return
	end
	-- Build the areas at runtime if the place doesn't have them yet (same behaviour Training.lua had)
	if not trainingFolder() then
		local mod = game:GetService("ServerScriptService"):FindFirstChild("TrainingAreas")
		if mod then
			local ok, err = pcall(function() (require(mod :: ModuleScript) :: any).BuildAll() end)
			if not ok then warn("[TrainingRooms] BuildAll failed: " .. tostring(err)) end
		end
	end
	TrainingBots.setAttack(Combat.npcHit) -- sparring bots use Combat's defensive rules
	for _, pad in CollectionService:GetTagged("TrainingPortal") do hookPortal(pad) end
	CollectionService:GetInstanceAddedSignal("TrainingPortal"):Connect(hookPortal) -- areas rebuilt by db-map Build()
	for _, z in CollectionService:GetTagged("TrainingFallZone") do hookFall(z) end
	CollectionService:GetInstanceAddedSignal("TrainingFallZone"):Connect(hookFall)
	Players.PlayerRemoving:Connect(function(p) ps[p] = nil end)
end

function TrainingRooms.areaOf(p: Player): string? return S(p).area end
function TrainingRooms.isBusy(p: Player): boolean return S(p).drill ~= nil end
return TrainingRooms
