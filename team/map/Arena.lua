--!strict
-- Arena.lua  |  ModuleScript: ServerScriptService.Arena
-- Scalable World of Void arena (ring + stands + Zeno box + zones) and fixed lobby.
-- API:
--   Arena.Resize(teamCount, playerCount) -> info   -- idempotent rebuild of Workspace.WorldOfVoid.Arena
--   Arena.BuildLobby(force?)                         -- builds lobby + lighting if missing (Resize calls it)
--   Arena.GetInfo() -> info                          -- last layout
--   Arena.ComputeLayout(teamCount, playerCount) -> info (pure, no instances)
-- Does NOT call ArenaDamage; RoundManager calls ArenaDamage.Init() after Resize.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local Arena = {}

local CFG = {
	ARENA_Y = 500, RING_THICK = 20,
	BASE_RADIUS = 150, PER_PLAYER = 12, MAX_RADIUS = 400, MAX_PLAYERS = 40,
	MIN_TEAMS = 2, MAX_TEAMS = 12,
	STAND_GAP = 250,           -- ring edge -> stand front (unjumpable)
	STAND_DEPTH = 40,
	RINGOUT_KILL_Y = 420, VOID_Y = 300, RINGOUT_LOW_Y = 480, LOW_GRACE = 1, AIR_MARGIN = 25,
	CHUNK_TARGET = 30,         -- desired radial chunk depth at base radius
	MAX_CHUNKS = 220,
	LOBBY_ORIGIN = Vector3.new(3000, 100, 0),
}
Arena.Config = CFG

local C_RING = Color3.fromRGB(200, 200, 210)
local C_RING2 = Color3.fromRGB(185, 185, 196)
local C_EDGE = Color3.fromRGB(120, 90, 200)
local C_ZENO = Color3.fromRGB(230, 200, 90)
local C_LOBBY = Color3.fromRGB(160, 170, 185)
local C_VOID = Color3.fromRGB(20, 18, 40)
-- Per-universe palette (index = universe number 1..12), loosely after the show's team colours
local UNIVERSE_COLORS: {Color3} = {
	Color3.fromRGB(80, 200, 240), Color3.fromRGB(255, 130, 200), Color3.fromRGB(140, 90, 220), Color3.fromRGB(70, 110, 230),
	Color3.fromRGB(240, 210, 70), Color3.fromRGB(70, 190, 110), Color3.fromRGB(240, 120, 40), Color3.fromRGB(150, 150, 160),
	Color3.fromRGB(150, 50, 70), Color3.fromRGB(180, 160, 230), Color3.fromRGB(220, 50, 50), Color3.fromRGB(90, 220, 200),
}
Arena.UniverseColors = UNIVERSE_COLORS

export type Info = {
	teamCount: number, playerCount: number, radius: number, bands: number, chunkCount: number,
	standRadius: number, zenoPos: Vector3, ceilingY: number, boundsRadius: number,
}
local lastInfo: Info? = nil

-- ===== helpers =====
local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder"); f.Name = name; f.Parent = parent; return f
end

local function part(props: {[string]: any}, parent: Instance, tags: {string}?): BasePart
	local p = Instance.new("Part")
	if props.Shape == "Cylinder" then p.Shape = Enum.PartType.Cylinder elseif props.Shape == "Ball" then p.Shape = Enum.PartType.Ball end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or C_RING
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Name = props.Name
	if props.Transparency then p.Transparency = props.Transparency end
	if props.CanCollide ~= nil then p.CanCollide = props.CanCollide end
	if props.CanTouch ~= nil then p.CanTouch = props.CanTouch end
	if props.CanQuery ~= nil then p.CanQuery = props.CanQuery end
	if props.CastShadow ~= nil then p.CastShadow = props.CastShadow end
	p.Parent = parent
	if tags then for _, t in ipairs(tags) do CollectionService:AddTag(p, t) end end
	return p
end

local function vcyl(c: Vector3): CFrame
	return CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90))
end

local function spawnPad(name: string, pos: Vector3, parent: Instance, tag: string, enabled: boolean): SpawnLocation
	local s = Instance.new("SpawnLocation")
	s.Name = name; s.Anchored = true; s.Size = Vector3.new(6, 1, 6); s.CFrame = CFrame.new(pos)
	s.Material = Enum.Material.Neon; s.Color = Color3.fromRGB(80, 200, 255)
	s.Neutral = true; s.Enabled = enabled; s.Duration = 0; s.Parent = parent
	CollectionService:AddTag(s, tag)
	return s
end

local function getRoot(): Folder
	local r = Workspace:FindFirstChild("WorldOfVoid")
	if r and r:IsA("Folder") then return r end
	if r then r:Destroy() end
	local f = folder("WorldOfVoid", Workspace)
	f:SetAttribute("Version", "v2-scalable")
	return f
end

-- ===== layout math =====
local function bandsFor(R: number): number
	-- radial depth grows with radius: 30 @150 -> 50 @400  => bands 5..8
	local depth = CFG.CHUNK_TARGET + (R - CFG.BASE_RADIUS) * 0.08
	return math.clamp(math.floor(R / depth + 0.5), 5, 8)
end

local function slicesFor(bands: number, R: number): {number}
	local d = R / bands
	local out = {}
	for b = 1, bands do
		local rm = (b - 0.5) * d
		out[b] = (b == 1) and 6 or math.max(6, math.floor(2 * math.pi * rm / d + 0.5))
	end
	return out
end

function Arena.ComputeLayout(teamCount: number, playerCount: number): Info
	local T = math.clamp(math.floor(teamCount), CFG.MIN_TEAMS, CFG.MAX_TEAMS)
	local P = math.clamp(math.floor(playerCount), T, CFG.MAX_PLAYERS)
	local R = math.min(CFG.MAX_RADIUS, CFG.BASE_RADIUS + CFG.PER_PLAYER * P)
	local B = bandsFor(R)
	local sl = slicesFor(B, R)
	local n = 0
	for _, k in ipairs(sl) do n += k end
	while n > CFG.MAX_CHUNKS and B > 4 do
		B -= 1; sl = slicesFor(B, R); n = 0
		for _, k in ipairs(sl) do n += k end
	end
	local standR = R + CFG.STAND_GAP + CFG.STAND_DEPTH / 2
	return {
		teamCount = T, playerCount = P, radius = R, bands = B, chunkCount = n,
		standRadius = standR,
		zenoPos = Vector3.new(0, CFG.ARENA_Y + 200 + R * 0.25, -(standR + 120)),
		ceilingY = CFG.ARENA_Y + math.max(400, R * 1.5),
		boundsRadius = R + CFG.AIR_MARGIN,
	}
end

-- ===== lobby + lighting (static) =====
function Arena.BuildLobby(force: boolean?)
	local root = getRoot()
	local existing = root:FindFirstChild("Lobby")
	if existing and not force then return end
	if existing then existing:Destroy() end
	local lobby = folder("Lobby", root)
	local L = CFG.LOBBY_ORIGIN
	part({ Name = "Lobby_Floor", Shape = "Cylinder", Size = Vector3.new(6, 240, 240), CFrame = vcyl(L - Vector3.new(0, 3, 0)),
		Material = Enum.Material.Marble, Color = C_LOBBY }, lobby, { "LobbyFloor" })
	part({ Name = "Lobby_Centerpiece", Shape = "Cylinder", Size = Vector3.new(4, 40, 40), CFrame = vcyl(L + Vector3.new(0, 2, 0)),
		Material = Enum.Material.Neon, Color = C_EDGE }, lobby)
	local pads = { { "Queue_Solo", Vector3.new(0, 0, -80) }, { "Queue_Team", Vector3.new(80, 0, 0) },
		{ "Shop", Vector3.new(0, 0, 80) }, { "Training", Vector3.new(-80, 0, 0) } }
	for _, d in ipairs(pads) do
		local p = part({ Name = "Lobby_" .. d[1], Size = Vector3.new(30, 1, 30), CFrame = CFrame.new(L + d[2] + Vector3.new(0, 0.5, 0)),
			Material = Enum.Material.Neon, Color = C_ZENO }, lobby, { "LobbyPad" })
		p:SetAttribute("PadType", d[1])
	end
	for i = 0, 23 do
		local a = math.rad(i * 15)
		local p = L + Vector3.new(math.cos(a) * 118, 10, math.sin(a) * 118)
		part({ Name = "Lobby_Wall_" .. (i + 1), Size = Vector3.new(32, 20, 2),
			CFrame = CFrame.lookAt(p, Vector3.new(L.X, p.Y, L.Z)), Color = Color3.fromRGB(120, 125, 140), Transparency = 0.3 }, lobby)
	end
	for i = 1, 8 do
		local a = math.rad(i * 45)
		spawnPad(string.format("Spawn_Lobby_%02d", i), L + Vector3.new(math.cos(a) * 40, 0.5, math.sin(a) * 40), lobby, "LobbySpawn", true)
	end
	part({ Name = "Zone_LobbyFall", Size = Vector3.new(1000, 10, 1000), CFrame = CFrame.new(L - Vector3.new(0, 80, 0)),
		Transparency = 1, CanCollide = false, CanQuery = false }, lobby, { "LobbyFallZone" })

	for _, c in ipairs(Lighting:GetChildren()) do
		if c:GetAttribute("WorldOfVoid") then c:Destroy() end
	end
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(70, 60, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 80, 140)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.FogColor = C_VOID
	local function lit(inst: Instance) inst:SetAttribute("WorldOfVoid", true); inst.Parent = Lighting end
	local sky = Instance.new("Sky"); sky.Name = "WOV_Sky"; sky.StarCount = 3000; sky.CelestialBodiesShown = false; lit(sky)
	local atm = Instance.new("Atmosphere"); atm.Name = "WOV_Atmosphere"; atm.Density = 0.35; atm.Offset = 0.2
	atm.Color = Color3.fromRGB(110, 90, 180); atm.Decay = Color3.fromRGB(30, 20, 60); atm.Glare = 0; atm.Haze = 1.5; lit(atm)
	local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "WOV_ColorCorrection"
	cc.TintColor = Color3.fromRGB(225, 215, 255); cc.Contrast = 0.1; cc.Saturation = 0.1; lit(cc)
	local bloom = Instance.new("BloomEffect"); bloom.Name = "WOV_Bloom"; bloom.Intensity = 0.8; bloom.Size = 30; bloom.Threshold = 1.5; lit(bloom)
end

-- ===== arena (scalable) =====
function Arena.Resize(teamCount: number, playerCount: number, universes: {number}?): Info
	local info = Arena.ComputeLayout(teamCount, playerCount)
	local R, T, P, Y = info.radius, info.teamCount, info.playerCount, CFG.ARENA_Y
	local root = getRoot()
	Arena.BuildLobby(false)
	local old = root:FindFirstChild("Arena")
	if old then old:Destroy() end
	local fx = root:FindFirstChild("DamageFX") -- ArenaDamage recreates on Init
	if fx then fx:Destroy() end
	local arena = folder("Arena", root)
	for k, v in pairs(info) do arena:SetAttribute(k:sub(1, 1):upper() .. k:sub(2), v) end

	-- Ring chunks
	local ringF = folder("Ring", arena)
	local chunkF = folder("Chunks", ringF)
	local cy = Y - CFG.RING_THICK / 2
	local d = R / info.bands
	local sl = slicesFor(info.bands, R)
	for b = 1, info.bands do
		local r0, r1, n = (b - 1) * d, b * d, sl[b]
		local rm = (r0 + r1) / 2
		local arc = 2 * math.pi * r1 / n + 1
		local hp = 60 + b * 20 + math.floor(d - 30) -- bigger chunks slightly tougher
		for s = 1, n do
			local a = math.rad((s - 0.5) * 360 / n)
			local pos = Vector3.new(math.cos(a) * rm, cy, math.sin(a) * rm)
			local c = part({ Name = string.format("Chunk_B%d_S%02d", b, s), Size = Vector3.new(arc, CFG.RING_THICK, d + 0.5),
				CFrame = CFrame.lookAt(pos, Vector3.new(0, cy, 0)), Material = Enum.Material.Slate,
				Color = (b + s) % 2 == 0 and C_RING or C_RING2 }, chunkF, { "RingChunk", "ArenaFloor" })
			c:SetAttribute("Band", b); c:SetAttribute("Sector", s)
			c:SetAttribute("MaxHealth", hp); c:SetAttribute("Health", hp)
			c:SetAttribute("HalfSpan", math.max(arc, d) / 2)
			c:SetAttribute("DamageStage", 0); c:SetAttribute("DamageStageName", "Intact")
		end
	end
	-- underside rock (non-collidable so holes are holes)
	for i = 1, 4 do
		local dia = 2 * R * (1 - i * 0.2)
		part({ Name = "Ring_Under_" .. i, Shape = "Cylinder", Size = Vector3.new(15, dia, dia),
			CFrame = vcyl(Vector3.new(0, Y - CFG.RING_THICK - i * 15 + 7.5, 0)), Material = Enum.Material.Rock,
			Color = Color3.fromRGB(90, 85, 100), CanCollide = false, CanTouch = false, CanQuery = false }, ringF)
	end
	-- pillars: 8 + 2 per 50 studs over base
	local np = 8 + 2 * math.floor((R - CFG.BASE_RADIUS) / 50)
	for i = 0, np - 1 do
		local a = math.rad((i + 0.5) * 360 / np)
		local r = R - 20
		part({ Name = "Ring_Pillar_" .. (i + 1), Size = Vector3.new(8, 30, 8),
			CFrame = CFrame.new(math.cos(a) * r, Y + 15, math.sin(a) * r), Material = Enum.Material.Marble }, ringF, { "ArenaCover" })
	end

	-- Fighter spawns: P pads at r=0.65R, contiguous arc per team
	local spawnF = folder("Spawns", arena)
	for i = 1, P do
		local team = math.floor((i - 1) * T / P) + 1
		local a = math.rad((i - 1) * 360 / P)
		local s = spawnPad(string.format("Spawn_Ring_%02d", i),
			Vector3.new(math.cos(a) * R * 0.65, Y + 0.5, math.sin(a) * R * 0.65), spawnF, "ArenaSpawn", false)
		s:SetAttribute("Team", team); s:SetAttribute("Universe", string.format("U%02d", team)); s:SetAttribute("Slot", i)
	end

	-- Stands (show style): T floating stepped grandstands, centered on each team's spawn arc, facing center.
	-- Label number = universes[t] (optional 3rd Resize arg) or t. Contract attrs Team/Universe (= team index) unchanged.
	local standsF = folder("Stands", arena)
	local standW = math.clamp(2 * math.pi * info.standRadius / T * 0.6, 80, 160)
	local bulmaPlaced = false
	for t = 1, T do
		local uNum = (universes and universes[t]) or t
		local col = UNIVERSE_COLORS[((uNum - 1) % 12) + 1]
		local a = math.rad(((t - 0.5) / T) * 360) -- arc midpoint of team t
		local pos = Vector3.new(math.cos(a) * info.standRadius, Y + 40, math.sin(a) * info.standRadius)
		local look = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
		local uf = folder(string.format("Stand_U%02d", t), standsF)
		uf:SetAttribute("Team", t); uf:SetAttribute("Universe", t)
		uf:SetAttribute("UniverseNumber", uNum); uf:SetAttribute("UniverseColor", col)
		part({ Name = "Base", Size = Vector3.new(standW, 4, CFG.STAND_DEPTH), CFrame = look, Material = Enum.Material.Marble,
			Color = Color3.fromRGB(215, 210, 225) }, uf, { "UniverseStand" })
		-- floating rock underside
		part({ Name = "Underside", Shape = "Ball", Size = Vector3.new(standW * 0.9, 18, CFG.STAND_DEPTH * 1.1),
			CFrame = look * CFrame.new(0, -9, 6), Material = Enum.Material.Rock, Color = Color3.fromRGB(110, 100, 125),
			CanCollide = false, CanTouch = false, CanQuery = false }, uf)
		-- front lip in universe colour (neon) + 4 stepped tiers (alternating colour / white seat rows)
		part({ Name = "FrontTrim", Size = Vector3.new(standW + 1, 1, 1), CFrame = look * CFrame.new(0, 2.5, -CFG.STAND_DEPTH / 2),
			Material = Enum.Material.Neon, Color = col, CanCollide = false, CanTouch = false, CanQuery = false }, uf)
		for row = 1, 4 do
			part({ Name = "Tier_" .. row, Size = Vector3.new(standW, 3 * row, 6), CFrame = look * CFrame.new(0, 1.5 * row + 2, -1 + row * 6),
				Material = Enum.Material.SmoothPlastic, Color = row % 2 == 1 and col or Color3.fromRGB(235, 232, 240) }, uf)
		end
		part({ Name = "BackWall", Size = Vector3.new(standW, 18, 2), CFrame = look * CFrame.new(0, 11, 24), Material = Enum.Material.Marble,
			Color = Color3.fromRGB(215, 210, 225) }, uf)
		local banner = part({ Name = "Banner", Size = Vector3.new(40, 20, 1), CFrame = look * CFrame.new(0, 30, 24), Material = Enum.Material.Neon,
			Color = col, CanCollide = false }, uf)
		banner:SetAttribute("UniverseNumber", uNum)
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local sg = Instance.new("SurfaceGui"); sg.Name = "UniverseLabel"; sg.Face = face; sg.LightInfluence = 0
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 20; sg.Parent = banner
			local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1; tl.TextScaled = true
			tl.Font = Enum.Font.GothamBlack; tl.Text = "UNIVERSE\n" .. uNum; tl.TextColor3 = Color3.new(1, 1, 1)
			tl.TextStrokeTransparency = 0.2; tl.TextStrokeColor3 = Color3.fromRGB(20, 10, 40); tl.Parent = sg
		end
		part({ Name = "BannerPole_L", Size = Vector3.new(1.5, 22, 1.5), CFrame = look * CFrame.new(-21, 30, 24), Material = Enum.Material.Metal,
			Color = Color3.fromRGB(210, 170, 70) }, uf)
		part({ Name = "BannerPole_R", Size = Vector3.new(1.5, 22, 1.5), CFrame = look * CFrame.new(21, 30, 24), Material = Enum.Material.Metal,
			Color = Color3.fromRGB(210, 170, 70) }, uf)
		-- spectator NPC slots (god of destruction, angel, kaioshin) on tier 2
		for i, who in ipairs({ "God", "Angel", "Kaioshin" }) do
			local sp = part({ Name = "NPC_" .. who, Size = Vector3.new(3, 0.2, 3), CFrame = look * CFrame.new(-12 + (i - 1) * 12, 5.6, 11),
				Material = Enum.Material.SmoothPlastic, Color = col, Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false },
				uf, { "ArenaNPCSpot" })
			sp:SetAttribute("NPC", who); sp:SetAttribute("UniverseNumber", uNum); sp:SetAttribute("Team", t)
		end
		if uNum == 7 and not bulmaPlaced then
			local bs = part({ Name = "NPC_BulmaCheer", Size = Vector3.new(3, 0.2, 3), CFrame = look * CFrame.new(standW / 2 - 8, 2.1, -8),
				Material = Enum.Material.SmoothPlastic, Color = col, Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false },
				uf, { "ArenaNPCSpot", "BulmaCheerSpot" })
			bs:SetAttribute("NPC", "Bulma"); bs:SetAttribute("UniverseNumber", 7); bs:SetAttribute("Team", t)
			bulmaPlaced = true
		end
		local ss = spawnPad(string.format("Spawn_Stand_U%02d", t), (look * CFrame.new(0, 2.5, -10)).Position, uf, "StandSpawn", false)
		ss:SetAttribute("Team", t); ss:SetAttribute("Universe", string.format("U%02d", t))
	end

	-- Zeno's viewing box (show style): floating platform, ornate box, two Zeno thrones side by side,
	-- Grand Priest standing front-left, two guards behind. Spots match CutsceneDirector offsets from Spawn_Zeno
	-- (zcf = Spawn_Zeno pos facing ring; x right, -z toward ring).
	local zenoF = folder("ZenoBox", arena)
	local zl = CFrame.lookAt(info.zenoPos, Vector3.new(0, Y, 0))
	local GOLD, WHITE, PURP = Color3.fromRGB(230, 190, 80), Color3.fromRGB(240, 236, 248), Color3.fromRGB(110, 70, 200)
	part({ Name = "Zeno_Floor", Size = Vector3.new(60, 4, 40), CFrame = zl, Material = Enum.Material.Marble, Color = WHITE }, zenoF, { "ZenoBox" })
	part({ Name = "Zeno_Platform", Size = Vector3.new(70, 6, 50), CFrame = zl * CFrame.new(0, -5, 0), Material = Enum.Material.Marble,
		Color = Color3.fromRGB(200, 195, 215) }, zenoF)
	part({ Name = "Zeno_PlatformTrim", Size = Vector3.new(71, 1, 51), CFrame = zl * CFrame.new(0, -2.4, 0), Material = Enum.Material.Neon,
		Color = GOLD, CanCollide = false, CanTouch = false, CanQuery = false }, zenoF)
	part({ Name = "Zeno_Carpet", Size = Vector3.new(8, 0.2, 34), CFrame = zl * CFrame.new(0, 2.1, 0), Material = Enum.Material.Fabric,
		Color = PURP, CanCollide = false, CanTouch = false, CanQuery = false }, zenoF)
	part({ Name = "Zeno_BackWall", Size = Vector3.new(60, 30, 2), CFrame = zl * CFrame.new(0, 17, 19), Color = WHITE, Material = Enum.Material.Marble }, zenoF)
	part({ Name = "Zeno_Roof", Size = Vector3.new(64, 2, 44), CFrame = zl * CFrame.new(0, 33, 0), Color = GOLD, Material = Enum.Material.Metal }, zenoF)
	part({ Name = "Zeno_Glass", Size = Vector3.new(60, 26, 1), CFrame = zl * CFrame.new(0, 15, -19.5), Material = Enum.Material.Glass,
		Color = Color3.fromRGB(200, 230, 255), Transparency = 0.75 }, zenoF)
	for i, x in ipairs({ -6, 6 }) do -- Zeno (left) and Future Zeno (right)
		part({ Name = "Zeno_Throne_" .. i, Size = Vector3.new(6, 3, 5), CFrame = zl * CFrame.new(x, 3.5, 4.5), Color = PURP,
			Material = Enum.Material.Fabric }, zenoF)
		part({ Name = "Zeno_ThroneBack_" .. i, Size = Vector3.new(7, 12, 1.2), CFrame = zl * CFrame.new(x, 8, 7.4), Color = GOLD,
			Material = Enum.Material.Foil }, zenoF)
		for j, sx in ipairs({ -3.4, 3.4 }) do
			part({ Name = "Zeno_ThroneArm_" .. i .. "_" .. j, Size = Vector3.new(0.8, 4.5, 5), CFrame = zl * CFrame.new(x + sx, 4.3, 4.5), Color = GOLD,
				Material = Enum.Material.Foil }, zenoF)
		end
	end
	local function npcSpot(name: string, npc: string, cid: string, x: number, z: number)
		local p = part({ Name = name, Size = Vector3.new(3, 0.2, 3), CFrame = zl * CFrame.new(x, 2.1, z), Transparency = 1,
			CanCollide = false, CanTouch = false, CanQuery = false }, zenoF, { "ArenaNPCSpot" })
		p:SetAttribute("NPC", npc); p:SetAttribute("CutsceneId", cid)
	end
	npcSpot("NPC_Zeno", "Zeno", "npc_zeno", -6, 2)
	npcSpot("NPC_FutureZeno", "FutureZeno", "npc_zeno_future", 6, 2)
	npcSpot("NPC_ZenoGuard_1", "ZenoGuard", "npc_zeno_guard_1", -15, 9)
	npcSpot("NPC_ZenoGuard_2", "ZenoGuard", "npc_zeno_guard_2", 15, 9)
	npcSpot("NPC_GrandPriest", "GrandPriest", "npc_grand_priest", -20, -6)
	spawnPad("Spawn_Zeno", (zl * CFrame.new(0, 2.5, 0)).Position, zenoF, "ZenoSpawn", false)

	-- Zones
	local zonesF = folder("Zones", arena)
	local killSize = info.standRadius * 2 + 2000
	part({ Name = "Zone_RingOut_Floor", Size = Vector3.new(killSize, 10, killSize), CFrame = CFrame.new(0, CFG.RINGOUT_KILL_Y, 0),
		Transparency = 1, CanCollide = false, CanQuery = false }, zonesF, { "RingOutZone" })
	local h = info.ceilingY - CFG.RINGOUT_LOW_Y + 10
	local bounds = part({ Name = "Zone_RingBounds", Shape = "Cylinder", Size = Vector3.new(h, info.boundsRadius * 2, info.boundsRadius * 2),
		CFrame = vcyl(Vector3.new(0, CFG.RINGOUT_LOW_Y + h / 2, 0)), Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false },
		zonesF, { "RingBounds" })
	bounds:SetAttribute("Radius", info.boundsRadius)
	bounds:SetAttribute("RingRadius", R)
	bounds:SetAttribute("MinY", CFG.RINGOUT_KILL_Y)
	bounds:SetAttribute("LowY", CFG.RINGOUT_LOW_Y)
	bounds:SetAttribute("LowGrace", CFG.LOW_GRACE)
	bounds:SetAttribute("CeilingY", info.ceilingY)
	bounds:SetAttribute("Center", Vector3.new(0, Y, 0))
	part({ Name = "Zone_Ceiling", Size = Vector3.new(killSize, 4, killSize), CFrame = CFrame.new(0, info.ceilingY, 0),
		Transparency = 1, CanTouch = false, CanQuery = false }, zonesF, { "ArenaCeiling" })

	-- Ring-out void: dark visible void plane far below + swirling rings (visual only; kill zone is Zone_RingOut_Floor)
	local voidF = folder("Void", arena)
	local vs = info.standRadius * 2 + 1500
	part({ Name = "Void_Plane", Size = Vector3.new(vs, 2, vs), CFrame = CFrame.new(0, CFG.VOID_Y, 0), Material = Enum.Material.Neon,
		Color = Color3.fromRGB(14, 8, 30), Transparency = 0.05, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false }, voidF,
		{ "VoidPlane" })
	for i = 1, 3 do
		local dia = R * (1.2 + i * 0.9)
		part({ Name = "Void_Swirl_" .. i, Shape = "Cylinder", Size = Vector3.new(0.5, dia, dia), CFrame = vcyl(Vector3.new(0, CFG.VOID_Y + 4 + i * 6, 0)),
			Material = Enum.Material.Neon, Color = Color3.fromRGB(70 + i * 20, 30, 160), Transparency = 0.6 + i * 0.1,
			CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false }, voidF)
	end
	part({ Name = "Void_Haze", Size = Vector3.new(vs, 1, vs), CFrame = CFrame.new(0, CFG.RINGOUT_KILL_Y - 15, 0), Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(60, 30, 120), Transparency = 0.5, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false }, voidF)

	-- Fog scales with arena
	local k = R / CFG.BASE_RADIUS
	Lighting.FogStart = 800 * k
	Lighting.FogEnd = 4000 * k

	lastInfo = info
	return info
end

function Arena.GetInfo(): Info?
	return lastInfo
end

return Arena
