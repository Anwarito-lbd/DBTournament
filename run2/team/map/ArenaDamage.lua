--!strict
-- ArenaDamage.lua  |  ModuleScript (put in ServerScriptService as "ArenaDamage")
-- Server-authoritative destructible ring for World of Void. Requires BuildArena.lua chunk grid.
-- API:
--   ArenaDamage.Init(root: Instance?)               -- scan chunks (auto on first call)
--   ArenaDamage.DamageAt(pos: Vector3, radius: number, power: number): number  -- returns chunks hit
--   ArenaDamage.Reset()                             -- full restore between rounds
--   ArenaDamage.IsRingSurface(part: BasePart?): boolean -- true if intact/attached ring chunk
--   ArenaDamage.GetStats(): {[string]: number}
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local ArenaDamage = {}

-- Damage stages (attribute DamageStage on each RingChunk; DamageStageName mirrors it):
--   0 Intact   health > 75%
--   1 Cracked  health <= 75%  (1 neon crack strip)
--   2 Cratered health <= 40%  (sinks up to CRATER_MAX_DEPTH, tilts, darkens to Basalt, 2nd crack)
--   3 Detached health <= 0    (unanchored, falls FALL_TIME s, then hidden; Detached=true)
ArenaDamage.Stages = { [0] = "Intact", [1] = "Cracked", [2] = "Cratered", [3] = "Detached" }
local function setStage(p: BasePart, st: number)
	if p:GetAttribute("DamageStage") ~= st then
		p:SetAttribute("DamageStage", st)
		p:SetAttribute("DamageStageName", ArenaDamage.Stages[st])
	end
end

-- ===== Budget / tuning =====
local CFG = {
	MAX_CALLS_PER_SEC = 30,     -- token bucket; excess DamageAt calls are dropped
	MAX_CHUNKS_PER_CALL = 16,  -- arena has <=220 chunks (Arena.Config.MAX_CHUNKS)
	MAX_RADIUS = 80,
	CRACK_AT = 0.75,            -- health ratio thresholds
	CRATER_AT = 0.4,
	CRATER_MAX_DEPTH = 8,       -- v1.2: deeper craters (was 5)
	MAX_CRACKS = 150,
	MAX_DEBRIS = 90,            -- pooled parts, hard cap
	DEBRIS_PER_HIT = 8,         -- v1.2: more visible destruction (was 4)
	DEBRIS_LIFETIME = 5,        -- v1.2 (was 3)
	MAX_FALLING = 20,           -- unanchored chunks simulating at once
	FALL_TIME = 4,              -- seconds before a detached chunk is hidden
}
ArenaDamage.Config = CFG

type ChunkState = {
	part: BasePart, home: CFrame, color: Color3, material: Enum.Material,
	maxHealth: number, health: number, cracked: boolean, detached: boolean, parent: Instance,
}

local chunks: {ChunkState} = {}
local byPart: {[BasePart]: ChunkState} = {}
local cracks: {BasePart} = {}
local debrisPool: {BasePart} = {}
local debrisActive: {[BasePart]: number} = {}
local falling = 0
local round = 0 -- bumps on Reset so stale delayed callbacks no-op
local tokens = CFG.MAX_CALLS_PER_SEC
local lastRefill = os.clock()
local fxFolder: Folder? = nil
local inited = false

local function assertServer()
	assert(RunService:IsServer(), "ArenaDamage is server-only")
end

function ArenaDamage.Init(root: Instance?)
	-- Safe to call repeatedly (e.g. after every Arena.Resize): invalidates timers, drops old state/FX.
	assertServer()
	round += 1
	for _, c in ipairs(cracks) do c:Destroy() end
	for p in pairs(debrisActive) do p:Destroy() end
	for _, p in ipairs(debrisPool) do p:Destroy() end
	for _, s in ipairs(chunks) do
		if s.detached and s.part.Parent == nil then s.part:Destroy() end
	end
	tokens = CFG.MAX_CALLS_PER_SEC
	chunks, byPart = {}, {}
	-- Guard: only RingChunk parts under Workspace.WorldOfVoid.Arena are ever registered,
	-- so Training/Lobby/Decor parts can never be damaged (even if mis-tagged).
	local wov = Workspace:FindFirstChild("WorldOfVoid")
	local arenaRoot = wov and wov:FindFirstChild("Arena")
	if not arenaRoot then warn("[ArenaDamage] Workspace.WorldOfVoid.Arena missing; no chunks registered") end
	for _, inst in ipairs(CollectionService:GetTagged("RingChunk")) do
		if inst:IsA("BasePart") and arenaRoot and inst:IsDescendantOf(arenaRoot)
			and (root == nil or inst:IsDescendantOf(root)) then
			local mh = (inst:GetAttribute("MaxHealth") :: number?) or 100
			local s: ChunkState = { part = inst, home = inst.CFrame, color = inst.Color, material = inst.Material,
				maxHealth = mh, health = mh, cracked = false, detached = false, parent = inst.Parent :: Instance }
			table.insert(chunks, s)
			byPart[inst] = s
			inst:SetAttribute("Health", mh)
			setStage(inst, 0)
		end
	end
	local wov = Workspace:FindFirstChild("WorldOfVoid")
	local old = wov and wov:FindFirstChild("DamageFX")
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "DamageFX"
	f.Parent = wov or Workspace
	fxFolder = f
	cracks, debrisPool, debrisActive, falling = {}, {}, {}, 0
	inited = true
end

local function ensure()
	if not inited then ArenaDamage.Init(nil) end
end

local function takeToken(): boolean
	local now = os.clock()
	tokens = math.min(CFG.MAX_CALLS_PER_SEC, tokens + (now - lastRefill) * CFG.MAX_CALLS_PER_SEC)
	lastRefill = now
	if tokens < 1 then return false end
	tokens -= 1
	return true
end

local function addCrack(s: ChunkState)
	if #cracks >= CFG.MAX_CRACKS then return end
	local p = s.part
	local c = Instance.new("Part")
	c.Name = "Crack"
	c.Anchored, c.CanCollide, c.CanTouch, c.CanQuery = true, false, false, false
	c.Material = Enum.Material.Neon
	c.Color = Color3.fromRGB(150, 90, 255)
	c.Size = Vector3.new(0.4, 0.2, math.max(p.Size.Z, p.Size.X) * (0.5 + math.random() * 0.5))
	c.CFrame = p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.05, 0) * CFrame.Angles(0, math.random() * math.pi, 0)
	c.Parent = fxFolder
	-- weld-free: crack follows chunk via attribute lookup on crater/detach
	c:SetAttribute("ChunkId", p.Name)
	table.insert(cracks, c)
	s.cracked = true
end

local function getDebris(): BasePart?
	local d = table.remove(debrisPool)
	if d then return d end
	local n = 0
	for _ in pairs(debrisActive) do n += 1 end
	if n >= CFG.MAX_DEBRIS then
		-- recycle oldest
		local oldest: BasePart?, t = nil, math.huge
		for part, born in pairs(debrisActive) do
			if born < t then oldest, t = part, born end
		end
		if oldest then debrisActive[oldest] = nil end
		return oldest
	end
	local p = Instance.new("Part")
	p.Name = "Debris"
	p.CanTouch, p.CanQuery = false, false -- never triggers ring-out
	p.Material = Enum.Material.Slate
	CollectionService:AddTag(p, "Debris")
	return p
end

local function releaseDebris(p: BasePart)
	if debrisActive[p] == nil then return end
	debrisActive[p] = nil
	p.Anchored = true
	p.Parent = nil
	table.insert(debrisPool, p)
end

local function spawnDebris(at: Vector3, color: Color3)
	local myRound = round
	for _ = 1, CFG.DEBRIS_PER_HIT do
		local d = getDebris()
		if not d then return end
		local sz = 1 + math.random() * 2
		d.Size = Vector3.new(sz, sz, sz)
		d.Color = color
		d.Anchored = false
		d.CFrame = CFrame.new(at + Vector3.new(math.random(-3, 3), 2, math.random(-3, 3)))
		d.Parent = fxFolder
		d.AssemblyLinearVelocity = Vector3.new(math.random(-30, 30), 30 + math.random() * 40, math.random(-30, 30))
		local born = os.clock()
		debrisActive[d] = born
		task.delay(CFG.DEBRIS_LIFETIME, function()
			if round == myRound and debrisActive[d] == born then releaseDebris(d) end
		end)
	end
end

local function detach(s: ChunkState, from: Vector3)
	s.detached = true
	local p = s.part
	p:SetAttribute("Detached", true)
	setStage(p, 3)
	for i = #cracks, 1, -1 do
		if cracks[i]:GetAttribute("ChunkId") == p.Name then cracks[i]:Destroy(); table.remove(cracks, i) end
	end
	p.CanTouch = false -- falling chunk must not count as "ring" or ring-out surface
	if falling >= CFG.MAX_FALLING then
		p.Parent = nil -- over budget: vanish instantly
		return
	end
	falling += 1
	p.Anchored = false
	local away = (p.Position - from) * Vector3.new(1, 0, 1)
	if away.Magnitude > 0.01 then away = away.Unit end
	p.AssemblyLinearVelocity = away * 25 + Vector3.new(0, -10, 0)
	p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 4
	local myRound = round
	task.delay(CFG.FALL_TIME, function()
		if round ~= myRound then return end
		falling -= 1
		p.Anchored = true
		p.Parent = nil
	end)
end

local function applyVisual(s: ChunkState)
	local ratio = s.health / s.maxHealth
	local p = s.part
	if ratio <= CFG.CRACK_AT and not s.cracked then addCrack(s); setStage(p, 1) end
	if ratio <= CFG.CRATER_AT then
		if p:GetAttribute("DamageStage") ~= 2 then addCrack(s); setStage(p, 2) end
		local t = 1 - ratio / CFG.CRATER_AT -- 0..1
		local tilt = (math.random() - 0.5) * 0.15 * t
		p.CFrame = s.home * CFrame.new(0, -CFG.CRATER_MAX_DEPTH * t, 0) * CFrame.Angles(tilt, 0, tilt)
		p.Color = s.color:Lerp(Color3.fromRGB(40, 30, 45), 0.6 * t)
		p.Material = Enum.Material.Basalt
	end
end

function ArenaDamage.DamageAt(pos: Vector3, radius: number, power: number): number
	assertServer()
	ensure()
	if not takeToken() then return 0 end
	radius = math.clamp(radius, 1, CFG.MAX_RADIUS)
	-- Guard: ignore hits far from the arena (training areas are >=2,700 studs away)
	local wov2 = Workspace:FindFirstChild("WorldOfVoid")
	local ar = wov2 and wov2:FindFirstChild("Arena")
	local ringR = (ar and ar:GetAttribute("Radius") :: number?) or 400
	if Vector3.new(pos.X, 0, pos.Z).Magnitude > ringR + radius + 60 or math.abs(pos.Y - 500) > 400 then return 0 end
	-- gather candidates
	local hits: {{s: ChunkState, d: number}} = {}
	for _, s in ipairs(chunks) do
		if not s.detached then
			local hp = s.home.Position
			local d = (hp - pos).Magnitude
			local reach = radius + (s.part:GetAttribute("HalfSpan") :: number? or 15)
			if d <= reach then table.insert(hits, { s = s, d = d / reach }) end
		end
	end
	table.sort(hits, function(a, b) return a.d < b.d end)
	local n = math.min(#hits, CFG.MAX_CHUNKS_PER_CALL)
	for i = 1, n do
		local h = hits[i]
		local s = h.s
		s.health -= power * (1 - h.d * 0.7)
		s.part:SetAttribute("Health", math.max(0, s.health))
		if s.health <= 0 then
			spawnDebris(s.part.Position, s.color)
			detach(s, pos)
		else
			applyVisual(s)
			if i <= 2 then spawnDebris(s.part.Position, s.color) end
		end
	end
	return n
end

function ArenaDamage.Reset()
	assertServer()
	ensure()
	round += 1
	falling = 0
	for _, s in ipairs(chunks) do
		local p = s.part
		p.Anchored = true
		p.AssemblyLinearVelocity = Vector3.zero
		p.AssemblyAngularVelocity = Vector3.zero
		p.CFrame = s.home
		p.Color = s.color
		p.Material = s.material
		p.CanTouch = true
		p.Parent = s.parent
		s.health, s.cracked, s.detached = s.maxHealth, false, false
		p:SetAttribute("Health", s.maxHealth)
		p:SetAttribute("Detached", false)
		setStage(p, 0)
	end
	for _, c in ipairs(cracks) do c:Destroy() end
	cracks = {}
	for d in pairs(debrisActive) do releaseDebris(d) end
	tokens = CFG.MAX_CALLS_PER_SEC
end

function ArenaDamage.IsRingSurface(part: BasePart?): boolean
	if not part then return false end
	local s = byPart[part]
	return s ~= nil and not s.detached
end

function ArenaDamage.GetStats(): {[string]: number}
	local alive, act = 0, 0
	for _, s in ipairs(chunks) do if not s.detached then alive += 1 end end
	for _ in pairs(debrisActive) do act += 1 end
	return { chunks = #chunks, alive = alive, cracks = #cracks, debrisActive = act,
		debrisPooled = #debrisPool, falling = falling, tokens = tokens }
end

return ArenaDamage
