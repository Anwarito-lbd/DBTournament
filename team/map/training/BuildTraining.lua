--!strict
-- BuildTraining.lua | Command bar / one-shot Script. GENERATED copy of TrainingAreas.lua + runner. (db-map v1.2)
-- Builds Workspace.WorldOfVoid.Training/{TrainingHub,Shop,HyperbolicTimeChamber,GravityRoom,KingKaiPlanet,WhisGround}
-- API: TrainingAreas.BuildAll() ; TrainingAreas.Build(areaId) ; TrainingAreas.Areas (layout table) ; TrainingAreas.Budget
-- Idempotent: each Build(areaId) destroys and rebuilds its own folder. Needs no external assets.
-- Gameplay contract (attributes/tags) documented in training_spec.md.
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local TrainingAreas = {}

local LOBBY = Vector3.new(3000, 100, 0)
local AREAS: {[string]: Vector3} = {
	TrainingHub = Vector3.new(2700, 100, 0),          -- west of lobby, bridged to Lobby_Training pad
	Shop = Vector3.new(3000, 100, 270),               -- south (+Z) of lobby, walkway from Lobby_Shop pad
	HyperbolicTimeChamber = Vector3.new(6000, 100, 0),
	GravityRoom = Vector3.new(6000, 100, 3000),
	KingKaiPlanet = Vector3.new(9000, 300, 0),
	WhisGround = Vector3.new(9000, 100, 3000),
	DragonBallSpawns = Vector3.new(0, 0, 0),           -- anchor set spread over lobby/hub/planets (positions absolute)
	BrolyCrater = Vector3.new(0, 100, -12000),         -- raid (WorldOfVoid.Raid), far from everything
	MoroNamek = Vector3.new(1600, 100, -12000),        -- raid (WorldOfVoid.Raid)
}
-- which WorldOfVoid subfolder each area lives in
local ROOT_OF: {[string]: string} = { BrolyCrater = "Raid", MoroNamek = "Raid" }
TrainingAreas.Areas = AREAS
local BUDGET: {[string]: number} = {
	TrainingHub = 90, Shop = 80, HyperbolicTimeChamber = 70, GravityRoom = 90, KingKaiPlanet = 70, WhisGround = 90,
	DragonBallSpawns = 16, BrolyCrater = 120, MoroNamek = 120,
}
TrainingAreas.Budget = BUDGET

-- ===== helpers =====
local count = 0
local function rgb(r: number, g: number, b: number): Color3 return Color3.fromRGB(r, g, b) end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?,
	opts: {[string]: any}?, tags: {string}?): Part
	local p = Instance.new("Part")
	local o = opts or {}
	if o.Shape then p.Shape = o.Shape end
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if o.Transparency then p.Transparency = o.Transparency end
	if o.CanCollide ~= nil then p.CanCollide = o.CanCollide end
	if o.CanTouch ~= nil then p.CanTouch = o.CanTouch end
	if o.CanQuery ~= nil then p.CanQuery = o.CanQuery end
	if o.CastShadow ~= nil then p.CastShadow = o.CastShadow end
	p.Parent = parent
	if tags then for _, t in ipairs(tags) do CollectionService:AddTag(p, t) end end
	count += 1
	return p
end
local BALL = { Shape = Enum.PartType.Ball }
local CYL = { Shape = Enum.PartType.Cylinder }
local DECO = { CanCollide = false, CanTouch = false, CanQuery = false }
local function merge(a: {[string]: any}, b: {[string]: any}): {[string]: any}
	local t = {}
	for k, v in pairs(a) do t[k] = v end
	for k, v in pairs(b) do t[k] = v end
	return t
end
-- vertical cylinder centered at c
local function vcyl(c: Vector3): CFrame return CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90)) end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder"); f.Name = name; f.Parent = parent; return f
end

local function trainingRoot(sub: string?): Folder
	local name = sub or "Training"
	local wov = Workspace:FindFirstChild("WorldOfVoid")
	if not wov then
		wov = Instance.new("Folder"); (wov :: Folder).Name = "WorldOfVoid"; (wov :: Folder).Parent = Workspace
	end
	local t = (wov :: Instance):FindFirstChild(name)
	if t and t:IsA("Folder") then return t end
	return folder(name, wov :: Instance)
end

local function spawnPoint(parent: Instance, areaId: string, pos: Vector3, name: string?): SpawnLocation
	local s = Instance.new("SpawnLocation")
	s.Name = name or ("Spawn_" .. areaId)
	s.Anchored = true; s.Size = Vector3.new(6, 1, 6); s.CFrame = CFrame.new(pos)
	s.Material = Enum.Material.Neon; s.Color = rgb(80, 200, 255); s.Transparency = 0.4
	s.Enabled = false; s.Neutral = true; s.Duration = 0
	s:SetAttribute("AreaId", areaId)
	s.Parent = parent
	CollectionService:AddTag(s, "TrainingSpawn")
	count += 1
	return s
end

-- Portal: neon pad (touch = teleport request) inside a simple arch. Server reads Destination attr.
local function portal(parent: Instance, name: string, cf: CFrame, dest: string, color: Color3)
	local f = folder(name, parent)
	part(f, "Post_L", Vector3.new(2, 14, 2), cf * CFrame.new(-6, 7, 0), rgb(235, 235, 240), Enum.Material.Metal)
	part(f, "Post_R", Vector3.new(2, 14, 2), cf * CFrame.new(6, 7, 0), rgb(235, 235, 240), Enum.Material.Metal)
	part(f, "Top", Vector3.new(14, 2, 2), cf * CFrame.new(0, 15, 0), color, Enum.Material.Neon)
	part(f, "Veil", Vector3.new(10, 12, 0.2), cf * CFrame.new(0, 7, 0), color, Enum.Material.ForceField,
		merge(DECO, { Transparency = 0.3 }))
	local pad = part(f, "Pad", Vector3.new(10, 1, 6), cf * CFrame.new(0, 0.5, 0), color, Enum.Material.Neon, nil, { "TrainingPortal" })
	pad:SetAttribute("Destination", dest)
end

local function label(p: BasePart, text: string, face: Enum.NormalId, color: Color3)
	local g = Instance.new("SurfaceGui")
	g.Face = face; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 20
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.TextScaled = true
	t.Font = Enum.Font.GothamBlack; t.TextColor3 = color; t.Text = text; t.Parent = g
	g.Parent = p
end

local function oob(parent: Instance, center: Vector3, size: number, y: number, areaId: string)
	local z = part(parent, "Zone_" .. areaId .. "_Fall", Vector3.new(size, 10, size), CFrame.new(center.X, y, center.Z),
		rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false, CanQuery = false }, { "TrainingFallZone" })
	z:SetAttribute("AreaId", areaId)
end

local function zone(parent: Instance, areaId: string, size: Vector3, cf: CFrame): Part
	local z = part(parent, "Zone_" .. areaId, size, cf, rgb(0, 0, 0), nil,
		{ Transparency = 1, CanCollide = false, CanQuery = false }, { "TrainingZone" })
	z:SetAttribute("AreaId", areaId)
	return z
end

-- ===== builders =====
local builders: {[string]: (Folder, Vector3) -> ()} = {}

builders.TrainingHub = function(f, C)
	f:SetAttribute("GravityMultiplier", 1); f:SetAttribute("LightingPreset", "Lobby")
	-- bridge from lobby west wall (x=2880) to hub edge (x=2780)
	part(f, "Bridge", Vector3.new(104, 1.5, 20), CFrame.new((2882 + 2778) / 2, C.Y - 0.75, 0), rgb(150, 160, 175), Enum.Material.Marble)
	for _, s in ipairs({ -1, 1 }) do
		part(f, "BridgeRail", Vector3.new(104, 3, 1), CFrame.new(2830, C.Y + 1.5, s * 10), rgb(120, 90, 200), Enum.Material.Neon, DECO)
	end
	part(f, "Hub_Floor", Vector3.new(6, 160, 160), vcyl(C - Vector3.new(0, 3, 0)), rgb(170, 175, 190), Enum.Material.Marble, CYL)
	part(f, "Hub_Ring", Vector3.new(1, 164, 164), vcyl(C - Vector3.new(0, 0.6, 0)), rgb(120, 90, 200), Enum.Material.Neon, merge(CYL, DECO))
	-- portals to the four far areas (west half), each facing hub center
	local dests = { { "HyperbolicTimeChamber", rgb(255, 255, 255), 135 }, { "GravityRoom", rgb(255, 60, 60), 165 },
		{ "KingKaiPlanet", rgb(90, 220, 90), 195 }, { "WhisGround", rgb(90, 120, 255), 225 } }
	for _, d in ipairs(dests) do
		local a = math.rad(d[3])
		local p = C + Vector3.new(math.cos(a) * 62, 0, math.sin(a) * 62)
		portal(f, "Portal_" .. d[1], CFrame.lookAt(p, Vector3.new(C.X, C.Y, C.Z)), d[1], d[2])
	end
	-- sparring dummies (punching bags) on east-free arc
	for i = 1, 6 do
		local a = math.rad(-60 + i * 20)
		local p = C + Vector3.new(math.cos(a) * 40 - 15, 0, math.sin(a) * 40)
		part(f, "Dummy_Post_" .. i, Vector3.new(1, 12, 1), CFrame.new(p + Vector3.new(0, 6, 0)), rgb(90, 70, 50), Enum.Material.Wood)
		local bag = part(f, "Dummy_Bag_" .. i, Vector3.new(6, 3, 3), vcyl(p + Vector3.new(0, 7, 0)), rgb(200, 60, 40),
			Enum.Material.Fabric, CYL, { "TrainingDummy" })
		bag:SetAttribute("MaxHealth", 500)
	end
	local sign = part(f, "Sign", Vector3.new(30, 8, 1), CFrame.new(C + Vector3.new(0, 18, -70)), rgb(30, 25, 50), Enum.Material.SmoothPlastic)
	label(sign, "TRAINING HUB", Enum.NormalId.Back, rgb(255, 210, 90))
	spawnPoint(f, "TrainingHub", C + Vector3.new(30, 0.5, 0))
	oob(f, C, 600, C.Y - 80, "TrainingHub")
end

builders.Shop = function(f, C)
	f:SetAttribute("GravityMultiplier", 1); f:SetAttribute("LightingPreset", "Lobby")
	local WHITE, BLUE, YEL = rgb(245, 245, 245), rgb(40, 110, 200), rgb(255, 205, 60)
	part(f, "Walkway", Vector3.new(20, 1.5, 104), CFrame.new(3000, C.Y - 0.75, (116 + 220) / 2), rgb(150, 160, 175), Enum.Material.Marble)
	part(f, "Plaza", Vector3.new(140, 2, 110), CFrame.new(C + Vector3.new(0, -1, 0)), rgb(205, 205, 200), Enum.Material.Concrete)
	part(f, "Plaza_Trim", Vector3.new(142, 0.4, 112), CFrame.new(C + Vector3.new(0, -0.1, 0)), BLUE, Enum.Material.SmoothPlastic, DECO)
	-- Capsule Corp HQ style: white drum with big half-dome, blue band, CC logo
	local B = C + Vector3.new(0, 0, 25)
	part(f, "CC_Drum", Vector3.new(24, 70, 70), vcyl(B + Vector3.new(0, 12, 0)), WHITE, Enum.Material.SmoothPlastic, CYL)
	part(f, "CC_Band", Vector3.new(3, 71, 71), vcyl(B + Vector3.new(0, 20, 0)), BLUE, Enum.Material.SmoothPlastic, CYL)
	part(f, "CC_Dome", Vector3.new(70, 70, 70), CFrame.new(B + Vector3.new(0, 24, 0)), WHITE, Enum.Material.SmoothPlastic, BALL)
	part(f, "CC_Roof_Disk", Vector3.new(2, 24, 24), vcyl(B + Vector3.new(0, 59.5, 0)), BLUE, Enum.Material.SmoothPlastic, CYL)
	-- storefront facing lobby (-Z)
	local front = B + Vector3.new(0, 0, -35)
	part(f, "Storefront_Glass", Vector3.new(40, 16, 1), CFrame.new(front + Vector3.new(0, 8, 0)), rgb(170, 220, 255), Enum.Material.Glass,
		merge(DECO, { Transparency = 0.5 }))
	part(f, "Storefront_Frame", Vector3.new(44, 2, 2), CFrame.new(front + Vector3.new(0, 17, 0)), BLUE, Enum.Material.Metal)
	local logo = part(f, "CC_Logo", Vector3.new(14, 14, 1), CFrame.new(front + Vector3.new(0, 27, -1)), BLUE, Enum.Material.SmoothPlastic)
	label(logo, "CC", Enum.NormalId.Front, WHITE)
	local banner = part(f, "CC_Banner", Vector3.new(44, 6, 1), CFrame.new(front + Vector3.new(0, 21, -1)), WHITE, Enum.Material.SmoothPlastic)
	label(banner, "CAPSULE CORP.", Enum.NormalId.Front, BLUE)
	-- counter + shopkeeper spot
	local counter = part(f, "Counter", Vector3.new(24, 4, 4), CFrame.new(front + Vector3.new(0, 2, -10)), WHITE, Enum.Material.SmoothPlastic,
		nil, { "ShopCounter" })
	counter:SetAttribute("ShopId", "CapsuleCorp")
	part(f, "Counter_Top", Vector3.new(25, 0.5, 5), CFrame.new(front + Vector3.new(0, 4.25, -10)), BLUE, Enum.Material.SmoothPlastic)
	local npc = part(f, "Shopkeeper_Spot", Vector3.new(4, 1, 4), CFrame.new(front + Vector3.new(0, 0.5, -5)), YEL, Enum.Material.Neon, DECO,
		{ "ShopNPCSpot" })
	npc:SetAttribute("NPC", "Bulma")
	-- capsule display pedestals (item slots)
	for i = 1, 6 do
		local x = -45 + (i - 1) * 18
		local pos = C + Vector3.new(x, 0, -35)
		if math.abs(x) < 12 then pos += Vector3.new(0, 0, -12) end
		part(f, "Pedestal_" .. i, Vector3.new(4, 5, 5), vcyl(pos + Vector3.new(0, 2.5, 0)), WHITE, Enum.Material.Marble, CYL)
		local cap = part(f, "Capsule_" .. i, Vector3.new(3, 1.6, 1.6), CFrame.new(pos + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			i % 2 == 0 and rgb(220, 40, 40) or WHITE, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder },
			{ "ShopItemSlot" })
		cap:SetAttribute("Slot", i)
		part(f, "CapsuleBand_" .. i, Vector3.new(0.4, 1.7, 1.7), CFrame.new(pos + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			BLUE, Enum.Material.Neon, merge(CYL, DECO))
	end
	spawnPoint(f, "Shop", C + Vector3.new(0, 0.5, -45))
	oob(f, C, 400, C.Y - 80, "Shop")
end

builders.HyperbolicTimeChamber = function(f, C)
	f:SetAttribute("GravityMultiplier", 10); f:SetAttribute("TimeDilation", 365) -- 1 day outside = 1 year inside
	f:SetAttribute("LightingPreset", "HTC"); f:SetAttribute("XPMultiplier", 4); f:SetAttribute("MaxStaySeconds", 600)
	local WHITE, CREAM = rgb(250, 250, 250), rgb(235, 228, 210)
	-- endless white void floor
	part(f, "HTC_Void_Floor", Vector3.new(1200, 4, 1200), CFrame.new(C + Vector3.new(0, -2, 300)), WHITE, Enum.Material.SmoothPlastic)
	-- entrance building: tiled platform + house with domed roofs (living quarters)
	part(f, "HTC_Platform", Vector3.new(120, 3, 80), CFrame.new(C + Vector3.new(0, 1.5, 0)), CREAM, Enum.Material.Marble)
	for i = 0, 5 do
		part(f, "HTC_Tile_" .. i, Vector3.new(120, 0.2, 1), CFrame.new(C + Vector3.new(0, 3.05, -35 + i * 14)), rgb(200, 190, 170),
			Enum.Material.SmoothPlastic, DECO)
	end
	local H = C + Vector3.new(0, 3, -25)
	part(f, "HTC_House", Vector3.new(70, 24, 24), CFrame.new(H + Vector3.new(0, 12, 0)), WHITE, Enum.Material.SmoothPlastic)
	for i, x in ipairs({ -22, 0, 22 }) do
		part(f, "HTC_Dome_" .. i, Vector3.new(22, 22, 22), CFrame.new(H + Vector3.new(x, 24, 0)), WHITE, Enum.Material.SmoothPlastic, BALL)
	end
	part(f, "HTC_Door", Vector3.new(8, 14, 1), CFrame.new(H + Vector3.new(0, 7, 12.2)), rgb(130, 90, 50), Enum.Material.Wood, DECO)
	-- hourglass (entrance symbol): two cones approximated by cylinders
	local G = C + Vector3.new(40, 3, 15)
	for i, s in ipairs({ { 6, 2 }, { 4, 5 }, { 2, 8 }, { 4, 11 }, { 6, 14 } }) do
		part(f, "Hourglass_" .. i, Vector3.new(3, s[1], s[1]), vcyl(G + Vector3.new(0, s[2], 0)), rgb(220, 200, 120), Enum.Material.Glass,
			merge(CYL, { Transparency = 0.3 }))
	end
	-- two marble pillars flanking the stairs into the void
	for i, x in ipairs({ -12, 12 }) do
		part(f, "HTC_Pillar_" .. i, Vector3.new(4, 30, 4), CFrame.new(C + Vector3.new(x, 18, 40)), WHITE, Enum.Material.Marble)
	end
	for i = 1, 3 do
		part(f, "HTC_Step_" .. i, Vector3.new(20, 1, 4), CFrame.new(C + Vector3.new(0, 3 - i, 40 + i * 4)), CREAM, Enum.Material.Marble)
	end
	local z = zone(f, "HyperbolicTimeChamber", Vector3.new(1200, 200, 1200), CFrame.new(C + Vector3.new(0, 100, 300)))
	z:SetAttribute("GravityMultiplier", 10); z:SetAttribute("TimeDilation", 365)
	z:SetAttribute("TemperatureMin", -40); z:SetAttribute("TemperatureMax", 50); z:SetAttribute("AirDensity", 0.25)
	spawnPoint(f, "HyperbolicTimeChamber", C + Vector3.new(0, 3.5, 0))
	portal(f, "Portal_Return", CFrame.new(C + Vector3.new(-45, 3, 10)) * CFrame.Angles(0, math.rad(90), 0), "TrainingHub", rgb(120, 90, 200))
	oob(f, C, 2000, C.Y - 60, "HyperbolicTimeChamber")
end

builders.GravityRoom = function(f, C)
	f:SetAttribute("GravityMultiplier", 1); f:SetAttribute("LightingPreset", "GravityRoom")
	f:SetAttribute("GravityMin", 1); f:SetAttribute("GravityMax", 500); f:SetAttribute("GravitySteps", "1,10,50,100,150,300,500")
	local WHITE, GREY, RED = rgb(240, 240, 240), rgb(150, 155, 165), rgb(255, 40, 40)
	local R = 45
	part(f, "GR_Floor", Vector3.new(2, R * 2 + 4, R * 2 + 4), vcyl(C - Vector3.new(0, 1, 0)), GREY, Enum.Material.DiamondPlate, CYL)
	-- domed spaceship shell: 16 wall panels with porthole windows every other panel, ceiling disc
	for i = 0, 15 do
		local a = math.rad(i * 22.5)
		local p = C + Vector3.new(math.cos(a) * R, 15, math.sin(a) * R)
		local cf = CFrame.lookAt(p, Vector3.new(C.X, p.Y, C.Z))
		part(f, "GR_Wall_" .. (i + 1), Vector3.new(19, 30, 2), cf, WHITE, Enum.Material.SmoothPlastic)
		if i % 2 == 0 then
			part(f, "GR_Window_" .. (i + 1), Vector3.new(0.5, 6, 6), cf * CFrame.new(0, 6, -1.1) * CFrame.Angles(0, math.rad(90), 0),
				rgb(120, 190, 255), Enum.Material.Glass, merge(CYL, merge(DECO, { Transparency = 0.2 })))
		end
	end
	part(f, "GR_Ceiling", Vector3.new(2, R * 2 + 4, R * 2 + 4), vcyl(C + Vector3.new(0, 31, 0)), WHITE, Enum.Material.SmoothPlastic, CYL)
	part(f, "GR_Dome", Vector3.new(R * 2, R * 1.2, R * 2), CFrame.new(C + Vector3.new(0, 31, 0)), WHITE, Enum.Material.SmoothPlastic,
		merge(BALL, { CastShadow = false }))
	part(f, "GR_StripeLight", Vector3.new(1, R * 2 - 4, R * 2 - 4), vcyl(C + Vector3.new(0, 29.6, 0)), rgb(255, 230, 200),
		Enum.Material.Neon, merge(CYL, DECO))
	-- central gravity machine: column + console + red readout
	part(f, "GR_Column", Vector3.new(30, 6, 6), vcyl(C + Vector3.new(0, 15, 0)), GREY, Enum.Material.Metal, CYL)
	part(f, "GR_Column_Ring", Vector3.new(2, 9, 9), vcyl(C + Vector3.new(0, 8, 0)), RED, Enum.Material.Neon, merge(CYL, DECO))
	local console = part(f, "GR_Console", Vector3.new(10, 5, 6), CFrame.new(C + Vector3.new(0, 2.5, -8)), GREY, Enum.Material.Metal, nil,
		{ "GravityConsole" })
	console:SetAttribute("GravityMultiplier", 1)
	console:SetAttribute("GravityMin", 1); console:SetAttribute("GravityMax", 500)
	local readout = part(f, "GR_Readout", Vector3.new(6, 3, 0.4), CFrame.new(C + Vector3.new(0, 6.5, -10.8)), rgb(20, 0, 0),
		Enum.Material.Neon, DECO)
	label(readout, "1G", Enum.NormalId.Front, RED)
	-- training props: weights + bot pads
	for i = 1, 4 do
		local a = math.rad(i * 90 + 45)
		local p = C + Vector3.new(math.cos(a) * 28, 0, math.sin(a) * 28)
		part(f, "GR_Weight_" .. i, Vector3.new(3, 4, 4), vcyl(p + Vector3.new(0, 1.5, 0)), rgb(40, 40, 45), Enum.Material.Metal, CYL)
		local bot = part(f, "GR_BotSpawn_" .. i, Vector3.new(4, 0.4, 4), CFrame.new(p + Vector3.new(6, 0.2, 0)), RED, Enum.Material.Neon, DECO,
			{ "TrainingBotSpawn" })
		bot:SetAttribute("AreaId", "GravityRoom")
	end
	local z = zone(f, "GravityRoom", Vector3.new(R * 2, 30, R * 2), CFrame.new(C + Vector3.new(0, 15, 0)))
	z:SetAttribute("GravityMultiplier", 1); z:SetAttribute("GravityDynamic", true)
	spawnPoint(f, "GravityRoom", C + Vector3.new(0, 0.5, 30))
	portal(f, "Portal_Return", CFrame.lookAt(C + Vector3.new(0, 0, -36), C), "TrainingHub", rgb(120, 90, 200))
	-- exterior ship legs
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		part(f, "GR_Leg_" .. (i + 1), Vector3.new(3, 14, 3), CFrame.new(C + Vector3.new(math.cos(a) * (R - 5), -9, math.sin(a) * (R - 5))),
			GREY, Enum.Material.Metal)
	end
	oob(f, C, 600, C.Y - 60, "GravityRoom")
end

builders.KingKaiPlanet = function(f, C)
	f:SetAttribute("GravityMultiplier", 10); f:SetAttribute("LightingPreset", "KingKai"); f:SetAttribute("XPMultiplier", 2)
	local R = 60 -- planet radius
	local top = C + Vector3.new(0, R, 0)
	part(f, "KK_Planet", Vector3.new(R * 2, R * 2, R * 2), CFrame.new(C), rgb(110, 190, 70), Enum.Material.Grass, BALL)
	-- dirt road loop around the summit: 16 short segments on a small circle, tilted to sphere
	local rr = 30
	for i = 0, 15 do
		local a = math.rad(i * 22.5)
		local dir = Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
		local h = math.sqrt(R * R - rr * rr)
		local p = C + Vector3.new(dir.X, h, dir.Z)
		local up = (p - C).Unit
		local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
		local cf = CFrame.fromMatrix(p + up * 0.15, tangent, up)
		part(f, "KK_Road_" .. (i + 1), Vector3.new(12.5, 0.4, 6), cf, rgb(200, 170, 110), Enum.Material.Ground, DECO)
	end
	-- house: cream drum, red dome roof, door and window
	local H = top + Vector3.new(-6, -0.5, -8)
	part(f, "KK_House", Vector3.new(12, 18, 18), vcyl(H + Vector3.new(0, 6, 0)), rgb(245, 235, 200), Enum.Material.SmoothPlastic, CYL)
	part(f, "KK_Roof", Vector3.new(19, 14, 19), CFrame.new(H + Vector3.new(0, 12, 0)), rgb(220, 50, 40), Enum.Material.SmoothPlastic, BALL)
	part(f, "KK_Chimney", Vector3.new(2, 5, 2), CFrame.new(H + Vector3.new(4, 19, 0)), rgb(220, 50, 40), Enum.Material.SmoothPlastic)
	part(f, "KK_Door", Vector3.new(4, 7, 0.5), CFrame.new(H + Vector3.new(0, 3.5, 9)), rgb(120, 80, 40), Enum.Material.Wood, DECO)
	part(f, "KK_Window", Vector3.new(0.5, 3, 3), CFrame.new(H + Vector3.new(6, 7, 6)) * CFrame.Angles(0, math.rad(-45), 0) * CFrame.Angles(0, math.rad(90), 0),
		rgb(150, 210, 255), Enum.Material.Glass, merge(CYL, DECO))
	-- tree: trunk + three leaf balls
	local T = top + Vector3.new(12, -1, 6)
	part(f, "KK_Tree_Trunk", Vector3.new(14, 2.5, 2.5), vcyl(T + Vector3.new(0, 7, 0)), rgb(110, 75, 40), Enum.Material.Wood, CYL)
	for i, o in ipairs({ Vector3.new(0, 16, 0), Vector3.new(3, 14, 2), Vector3.new(-3, 14, -2) }) do
		part(f, "KK_Tree_Leaves_" .. i, Vector3.new(9, 9, 9), CFrame.new(T + o), rgb(70, 150, 50), Enum.Material.Grass, BALL)
	end
	-- red car (on the road)
	local a0 = math.rad(110)
	local hh = math.sqrt(R * R - rr * rr)
	local cp = C + Vector3.new(math.cos(a0) * rr, hh, math.sin(a0) * rr)
	local cup = (cp - C).Unit
	local ccf = CFrame.fromMatrix(cp + cup * 1.6, Vector3.new(-math.sin(a0), 0, math.cos(a0)), cup)
	part(f, "KK_Car_Body", Vector3.new(8, 2, 4), ccf, rgb(220, 30, 30), Enum.Material.SmoothPlastic, nil, { "KingKaiCar" })
	part(f, "KK_Car_Top", Vector3.new(4, 1.6, 3.6), ccf * CFrame.new(-0.5, 1.8, 0), rgb(255, 255, 255), Enum.Material.SmoothPlastic)
	for i, w in ipairs({ Vector3.new(2.8, -1, 2.1), Vector3.new(-2.8, -1, 2.1), Vector3.new(2.8, -1, -2.1), Vector3.new(-2.8, -1, -2.1) }) do
		part(f, "KK_Car_Wheel_" .. i, Vector3.new(0.8, 1.8, 1.8), ccf * CFrame.new(w) * CFrame.Angles(0, math.rad(90), 0),
			rgb(25, 25, 25), Enum.Material.SmoothPlastic, merge(CYL, DECO))
	end
	-- Bubbles (monkey) + Gregory spots for NPC scripts
	local bub = part(f, "NPC_Bubbles", Vector3.new(3, 0.4, 3), CFrame.new(top + Vector3.new(10, 0, -12)), rgb(255, 230, 120), Enum.Material.Neon,
		merge(DECO, { Transparency = 0.6 }), { "TrainingNPCSpot" })
	bub:SetAttribute("NPC", "Bubbles")
	local kk = part(f, "NPC_KingKai", Vector3.new(3, 0.4, 3), CFrame.new(H + Vector3.new(0, 0.5, 13)), rgb(255, 230, 120), Enum.Material.Neon,
		merge(DECO, { Transparency = 0.6 }), { "TrainingNPCSpot" })
	kk:SetAttribute("NPC", "KingKai")
	-- Snake Way tail: yellow cloud path leading off
	for i = 1, 6 do
		part(f, "SnakeWay_Cloud_" .. i, Vector3.new(14, 6, 10), CFrame.new(C + Vector3.new(-R - i * 12, -R * 0.4 - i * 6, 0)), rgb(250, 220, 120),
			Enum.Material.SmoothPlastic, merge(BALL, DECO))
	end
	local z = zone(f, "KingKaiPlanet", Vector3.new(R * 2.4, R * 2.4, R * 2.4), CFrame.new(C))
	z:SetAttribute("GravityMultiplier", 10)
	spawnPoint(f, "KingKaiPlanet", top + Vector3.new(0, 0.5, 6))
	portal(f, "Portal_Return", CFrame.lookAt(top + Vector3.new(8, -0.5, 14), top), "TrainingHub", rgb(120, 90, 200))
	oob(f, C, 800, C.Y - R - 80, "KingKaiPlanet")
end

builders.WhisGround = function(f, C)
	f:SetAttribute("GravityMultiplier", 1.5); f:SetAttribute("LightingPreset", "BeerusPlanet"); f:SetAttribute("XPMultiplier", 3)
	local TEAL, PURPLE, ROCK = rgb(70, 140, 120), rgb(140, 90, 170), rgb(170, 120, 150)
	part(f, "BP_Ground", Vector3.new(8, 420, 420), vcyl(C - Vector3.new(0, 4, 0)), TEAL, Enum.Material.Grass, CYL)
	part(f, "BP_Underside", Vector3.new(30, 380, 380), vcyl(C - Vector3.new(0, 23, 0)), ROCK, Enum.Material.Rock, merge(CYL, DECO))
	-- Beerus's temple: stepped pyramid + tall spire with orb
	local P = C + Vector3.new(0, 0, -120)
	for i = 0, 4 do
		local s = 90 - i * 16
		part(f, "BP_Temple_Tier_" .. (i + 1), Vector3.new(s, 10, s), CFrame.new(P + Vector3.new(0, 5 + i * 10, 0)), rgb(200, 175, 140),
			Enum.Material.Sandstone)
	end
	part(f, "BP_Spire", Vector3.new(60, 4, 4), vcyl(P + Vector3.new(0, 80, 0)), rgb(200, 175, 140), Enum.Material.Sandstone, CYL)
	part(f, "BP_Spire_Orb", Vector3.new(8, 8, 8), CFrame.new(P + Vector3.new(0, 112, 0)), rgb(120, 220, 255), Enum.Material.Neon, BALL)
	-- mushroom rock spires (iconic)
	for i = 1, 8 do
		local a = math.rad(i * 45 + 10)
		local r = 150 + (i % 3) * 20
		local p = C + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local h = 40 + (i % 4) * 15
		part(f, "BP_Mushroom_Stem_" .. i, Vector3.new(h, 8, 8), vcyl(p + Vector3.new(0, h / 2, 0)), ROCK, Enum.Material.Rock, CYL)
		part(f, "BP_Mushroom_Cap_" .. i, Vector3.new(26, 12, 26), CFrame.new(p + Vector3.new(0, h + 2, 0)), PURPLE, Enum.Material.Rock, BALL)
	end
	-- floating rocks (decor)
	for i = 1, 6 do
		local a = math.rad(i * 60)
		part(f, "BP_FloatRock_" .. i, Vector3.new(14, 9, 12), CFrame.new(C + Vector3.new(math.cos(a) * 100, 70 + i * 6, math.sin(a) * 100)),
			ROCK, Enum.Material.Rock, merge(BALL, DECO))
	end
	-- Whis sparring circle: stone disk with neon ring, staff marker
	local S = C + Vector3.new(0, 0, 40)
	part(f, "Whis_Circle", Vector3.new(1, 70, 70), vcyl(S + Vector3.new(0, 0.5, 0)), rgb(225, 220, 210), Enum.Material.Slate, CYL)
	part(f, "Whis_Circle_Ring", Vector3.new(1.1, 72, 72), vcyl(S + Vector3.new(0, 0.45, 0)), rgb(120, 200, 255), Enum.Material.Neon, merge(CYL, DECO))
	local staff = part(f, "Whis_Staff", Vector3.new(16, 0.6, 0.6), vcyl(S + Vector3.new(0, 8, -30)), rgb(230, 230, 240), Enum.Material.Metal,
		merge(CYL, DECO))
	part(f, "Whis_Staff_Orb", Vector3.new(2.5, 2.5, 2.5), CFrame.new(S + Vector3.new(0, 17, -30)), rgb(120, 200, 255), Enum.Material.Neon,
		merge(BALL, DECO))
	local npc = part(f, "NPC_Whis", Vector3.new(3, 0.4, 3), CFrame.new(S + Vector3.new(0, 1.2, -26)), rgb(120, 200, 255), Enum.Material.Neon,
		merge(DECO, { Transparency = 0.6 }), { "TrainingNPCSpot" })
	npc:SetAttribute("NPC", "Whis")
	local bnpc = part(f, "NPC_Beerus", Vector3.new(3, 0.4, 3), CFrame.new(P + Vector3.new(0, 0.2, 50)), rgb(180, 120, 220), Enum.Material.Neon,
		merge(DECO, { Transparency = 0.6 }), { "TrainingNPCSpot" })
	bnpc:SetAttribute("NPC", "Beerus")
	_ = staff
	for i, x in ipairs({ -18, 18 }) do
		local bot = part(f, "Whis_BotSpawn_" .. i, Vector3.new(4, 0.4, 4), CFrame.new(S + Vector3.new(x, 1.2, 0)), rgb(120, 200, 255),
			Enum.Material.Neon, DECO, { "TrainingBotSpawn" })
		bot:SetAttribute("AreaId", "WhisGround")
	end
	local z = zone(f, "WhisGround", Vector3.new(420, 200, 420), CFrame.new(C + Vector3.new(0, 100, 0)))
	z:SetAttribute("GravityMultiplier", 1.5); z:SetAttribute("XPMultiplier", 3)
	spawnPoint(f, "WhisGround", S + Vector3.new(0, 1.5, 20))
	portal(f, "Portal_Return", CFrame.lookAt(S + Vector3.new(0, 1, 45), S), "TrainingHub", rgb(120, 90, 200))
	oob(f, C, 1000, C.Y - 80, "WhisGround")
end


-- ===== Dragon Ball anchors (DragonBallService reads tag DragonBallSpawn; uses BasePart.Position, needs >=7) =====
builders.DragonBallSpawns = function(f, _C)
	local pts: {{any}} = {
		{ "Lobby", Vector3.new(3060, 102, 60) }, { "Lobby", Vector3.new(2950, 102, -70) },
		{ "TrainingHub", Vector3.new(2650, 101, 60) }, { "TrainingHub", Vector3.new(2760, 101, -50) },
		{ "Shop", Vector3.new(3050, 101, 300) },
		{ "HyperbolicTimeChamber", Vector3.new(6000, 102, 250) },
		{ "GravityRoom", Vector3.new(6020, 101, 3020) },
		{ "KingKaiPlanet", Vector3.new(9000, 361.5, 0) }, { "KingKaiPlanet", Vector3.new(9015, 355, -22) },
		{ "WhisGround", Vector3.new(9100, 101, 3100) }, { "WhisGround", Vector3.new(8900, 101, 2900) },
		{ "WhisGround", Vector3.new(9000, 151, 2880) }, -- on a temple tier
	}
	for i, p in ipairs(pts) do
		local a = part(f, string.format("DBSpawn_%02d", i), Vector3.new(2, 2, 2), CFrame.new(p[2] :: Vector3), rgb(255, 160, 0),
			Enum.Material.Neon, { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false },
			{ "DragonBallSpawn" })
		a:SetAttribute("AreaId", p[1]); a:SetAttribute("Index", i)
	end
end

-- ===== Raids (WorldOfVoid.Raid). BossNPC.allocArena picks a BasePart tagged RaidArena (attr InUse) and
-- spawns at floor.CFrame + (0, Size.Y/2 + 3, 0); so each raid has ONE flat RaidArena floor centered on the fight.
local function raidCommon(f: Folder, C: Vector3, raidId: string, floorColor: Color3, floorMat: Enum.Material, boss: string): Part
	f:SetAttribute("RaidId", raidId); f:SetAttribute("LightingPreset", raidId); f:SetAttribute("GravityMultiplier", 1)
	local floor = part(f, "Raid_Floor", Vector3.new(240, 4, 240), CFrame.new(C - Vector3.new(0, 2, 0)), floorColor, floorMat, nil,
		{ "RaidArena" })
	floor:SetAttribute("RaidId", raidId); floor:SetAttribute("Boss", boss)
	local bp = part(f, "Raid_BossPad", Vector3.new(14, 1, 14), CFrame.new(C + Vector3.new(0, 0.5, -70)), rgb(255, 60, 60), Enum.Material.Neon,
		{ Transparency = 0.5, CanCollide = false, CanQuery = false }, { "RaidBossPad" })
	bp:SetAttribute("Boss", boss); bp:SetAttribute("RaidId", raidId)
	for i = 1, 8 do
		local x = -42 + (i - 1) * 12
		local s = part(f, string.format("Raid_Spawn_%02d", i), Vector3.new(6, 1, 6), CFrame.new(C + Vector3.new(x, 0.5, 80)),
			rgb(80, 200, 255), Enum.Material.Neon, { Transparency = 0.5, CanCollide = false, CanQuery = false }, { "RaidSpawn" })
		s:SetAttribute("RaidId", raidId); s:SetAttribute("Index", i)
	end
	local z = zone(f, raidId, Vector3.new(260, 160, 260), CFrame.new(C + Vector3.new(0, 78, 0)))
	z:SetAttribute("RaidId", raidId)
	local fall = part(f, "Zone_" .. raidId .. "_Fall", Vector3.new(1200, 10, 1200), CFrame.new(C - Vector3.new(0, 60, 0)), rgb(0, 0, 0), nil,
		{ Transparency = 1, CanCollide = false, CanQuery = false }, { "RaidFallZone" })
	fall:SetAttribute("RaidId", raidId)
	local ceil = part(f, "Zone_" .. raidId .. "_Ceiling", Vector3.new(400, 4, 400), CFrame.new(C + Vector3.new(0, 200, 0)), rgb(0, 0, 0), nil,
		{ Transparency = 1, CanTouch = false, CanQuery = false }, { "RaidCeiling" })
	ceil:SetAttribute("RaidId", raidId)
	return floor
end

builders.BrolyCrater = function(f, C)
	local DIRT, ROCK, LAVA = rgb(120, 85, 60), rgb(90, 70, 55), rgb(255, 110, 30)
	raidCommon(f, C, "BrolyCrater", rgb(105, 75, 55), Enum.Material.Ground, "Broly")
	-- crater bowl: sunken centre disc + glowing fissures
	part(f, "Crater_Bowl", Vector3.new(2, 120, 120), vcyl(C + Vector3.new(0, -0.6, 0)), rgb(70, 50, 40), Enum.Material.Basalt, merge(CYL, DECO))
	for i = 0, 7 do
		local a = math.rad(i * 45 + 10)
		part(f, "Crater_Fissure_" .. (i + 1), Vector3.new(1.2, 0.3, 50), CFrame.new(C + Vector3.new(math.cos(a) * 30, 0.1, math.sin(a) * 30))
			* CFrame.Angles(0, -a + math.rad(90), 0), LAVA, Enum.Material.Neon, DECO)
	end
	-- rim: 20 tilted rock slabs forming the crater wall (collidable, contain the fight)
	for i = 0, 19 do
		local a = math.rad(i * 18)
		local p = C + Vector3.new(math.cos(a) * 118, 10, math.sin(a) * 118)
		part(f, "Crater_Rim_" .. (i + 1), Vector3.new(40, 26, 14), CFrame.lookAt(p, C + Vector3.new(0, 30, 0)) , i % 2 == 0 and ROCK or DIRT,
			Enum.Material.Rock)
	end
	-- wasteland spires, boulders, broken cliffs outside the rim
	for i = 1, 10 do
		local a = math.rad(i * 36 + 5)
		local r = 150 + (i % 3) * 25
		local h = 30 + (i % 4) * 18
		part(f, "Waste_Spire_" .. i, Vector3.new(10 + i % 3 * 4, h, 10), CFrame.new(C + Vector3.new(math.cos(a) * r, h / 2 - 4, math.sin(a) * r))
			* CFrame.Angles(0, a, math.rad((i % 5) - 2) * 3), ROCK, Enum.Material.Rock)
	end
	part(f, "Waste_Ground", Vector3.new(500, 4, 500), CFrame.new(C - Vector3.new(0, 6, 0)), DIRT, Enum.Material.Ground)
	for i = 1, 8 do
		local a = math.rad(i * 45 + 22)
		part(f, "Waste_Boulder_" .. i, Vector3.new(8 + i % 3 * 3, 6 + i % 2 * 3, 8), CFrame.new(C + Vector3.new(math.cos(a) * 60, 2, math.sin(a) * 60)),
			ROCK, Enum.Material.Rock, BALL, { "RaidCover" })
	end
	-- green ki glow marker at boss pad (Broly's aura colour)
	part(f, "Broly_AuraMarker", Vector3.new(0.4, 22, 22), vcyl(C + Vector3.new(0, 0.3, -70)), rgb(80, 255, 100), Enum.Material.Neon,
		merge(CYL, merge(DECO, { Transparency = 0.4 })))
end

builders.MoroNamek = function(f, C)
	local GRASS, WATER, ROCK, AJISA = rgb(120, 170, 110), rgb(90, 170, 150), rgb(130, 120, 110), rgb(90, 140, 200)
	raidCommon(f, C, "MoroNamek", rgb(110, 140, 95), Enum.Material.Grass, "Moro")
	-- drained, dying New Namek: grey-teal sea around a plateau, ruined dome houses, withered ajisa trees, drain cracks
	part(f, "Namek_Sea", Vector3.new(900, 2, 900), CFrame.new(C - Vector3.new(0, 14, 0)), WATER, Enum.Material.Water, DECO)
	part(f, "Namek_Plateau", Vector3.new(16, 250, 250), vcyl(C - Vector3.new(0, 12, 0)), ROCK, Enum.Material.Rock, CYL)
	for i = 1, 6 do
		local a = math.rad(i * 60 + 15)
		local p = C + Vector3.new(math.cos(a) * 95, 0, math.sin(a) * 95)
		part(f, "Namek_House_" .. i, Vector3.new(16, 14, 16), CFrame.new(p + Vector3.new(0, 4, 0)), rgb(235, 235, 220), Enum.Material.SmoothPlastic,
			BALL)
		-- broken half: sunk + tilted fragment
		part(f, "Namek_HouseRubble_" .. i, Vector3.new(7, 3, 5), CFrame.new(p + Vector3.new(6, 1, 5)) * CFrame.Angles(0.4, a, 0.3),
			rgb(210, 210, 195), Enum.Material.SmoothPlastic, nil, { "RaidCover" })
		part(f, "Namek_HouseWindow_" .. i, Vector3.new(0.4, 3, 3), CFrame.lookAt(p + Vector3.new(0, 6, 0), C) * CFrame.new(0, 0, -7.6)
			* CFrame.Angles(0, math.rad(90), 0), rgb(60, 60, 70), Enum.Material.SmoothPlastic, merge(CYL, DECO))
	end
	for i = 1, 8 do
		local a = math.rad(i * 45)
		local p = C + Vector3.new(math.cos(a) * 112, 0, math.sin(a) * 112)
		part(f, "Ajisa_Trunk_" .. i, Vector3.new(16, 2, 2), vcyl(p + Vector3.new(0, 8, 0)), rgb(110, 95, 80), Enum.Material.Wood, CYL)
		part(f, "Ajisa_Puff_" .. i, Vector3.new(9, 7, 9), CFrame.new(p + Vector3.new(0, 18, 0)),
			i % 3 == 0 and rgb(120, 110, 100) or AJISA, Enum.Material.Grass, merge(BALL, DECO)) -- some withered/grey
	end
	for i = 0, 9 do
		local a = math.rad(i * 36 + 7)
		part(f, "Drain_Crack_" .. (i + 1), Vector3.new(1, 0.3, 40 + (i % 3) * 10), CFrame.new(C + Vector3.new(math.cos(a) * 35, 0.1, math.sin(a) * 35))
			* CFrame.Angles(0, -a + math.rad(90), 0), rgb(170, 90, 255), Enum.Material.Neon, DECO) -- Moro energy drain
	end
	for i = 1, 6 do
		local a = math.rad(i * 60)
		part(f, "Namek_Mesa_" .. i, Vector3.new(30, 50 + i % 3 * 15, 30), CFrame.new(C + Vector3.new(math.cos(a) * 220, 10, math.sin(a) * 220)),
			ROCK, Enum.Material.Rock)
	end
	part(f, "Moro_DrainMarker", Vector3.new(0.4, 22, 22), vcyl(C + Vector3.new(0, 0.3, -70)), rgb(170, 90, 255), Enum.Material.Neon,
		merge(CYL, merge(DECO, { Transparency = 0.4 })))
end

-- open the lobby wall segments facing the Training and Shop pads (walls rebuilt by Arena.BuildLobby(true))
local function openLobbyWalls()
	local wov = Workspace:FindFirstChild("WorldOfVoid")
	local lobby = wov and wov:FindFirstChild("Lobby")
	if not lobby then
		warn("[Training] Lobby not built yet; run Arena.BuildLobby() / BuildArena.lua first, then rebuild TrainingHub/Shop")
		return
	end
	for _, n in ipairs({ "Lobby_Wall_13", "Lobby_Wall_7" }) do -- 180deg (west, Training) and 90deg (+Z, Shop)
		local w = lobby:FindFirstChild(n)
		if w and w:IsA("BasePart") then
			w.CanCollide = false; w.Transparency = 1; w.CanQuery = false
			w:SetAttribute("OpenedFor", n == "Lobby_Wall_13" and "TrainingHub" or "Shop")
		end
	end
end

function TrainingAreas.Build(areaId: string): number
	local b = builders[areaId]
	assert(b, "unknown training area " .. tostring(areaId))
	local root = trainingRoot(ROOT_OF[areaId])
	local old = root:FindFirstChild(areaId)
	if old then old:Destroy() end
	local f = folder(areaId, root)
	f:SetAttribute("AreaId", areaId)
	f:SetAttribute("Origin", AREAS[areaId])
	count = 0
	b(f, AREAS[areaId])
	f:SetAttribute("PartCount", count)
	f:SetAttribute("PartBudget", BUDGET[areaId])
	if count > BUDGET[areaId] then
		warn(string.format("[Training] %s uses %d parts (budget %d)", areaId, count, BUDGET[areaId]))
	end
	if areaId == "TrainingHub" or areaId == "Shop" then openLobbyWalls() end
	return count
end

TrainingAreas.Order = { "TrainingHub", "Shop", "HyperbolicTimeChamber", "GravityRoom", "KingKaiPlanet", "WhisGround",
	"DragonBallSpawns", "BrolyCrater", "MoroNamek" }
TrainingAreas.RaidAreas = { "BrolyCrater", "MoroNamek" }
function TrainingAreas.BuildAll(): {[string]: number}
	local res = {}
	for _, id in ipairs(TrainingAreas.Order) do res[id] = TrainingAreas.Build(id) end
	TrainingAreas.PublishLightingPresets()
	return res
end

-- ===== Lighting presets → ReplicatedStorage.Shared.TrainingLightingPresets =====
local function serialize(v: any): string
	local ty = typeof(v)
	if ty == "Color3" then
		local c = v :: Color3
		return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	elseif ty == "number" then
		return tostring(v)
	elseif ty == "string" then
		return string.format("%q", v)
	elseif ty == "boolean" then
		return tostring(v)
	end
	error("unsupported preset value type " .. ty)
end

function TrainingAreas.PresetsSource(): string
	local names = {}
	for n in pairs(TrainingAreas.LightingPresets) do table.insert(names, n) end
	table.sort(names)
	local lines = { "--!strict", "-- ReplicatedStorage.Shared.TrainingLightingPresets (generated by db-map TrainingAreas.PublishLightingPresets)",
		"-- Shape: { [presetName]: { [LightingProperty]: value } }; read by TrainingLighting.client.lua", "return {" }
	for _, n in ipairs(names) do
		local keys = {}
		for k in pairs(TrainingAreas.LightingPresets[n]) do table.insert(keys, k) end
		table.sort(keys)
		local kv = {}
		for _, k in ipairs(keys) do table.insert(kv, k .. " = " .. serialize(TrainingAreas.LightingPresets[n][k])) end
		table.insert(lines, "\t" .. n .. " = { " .. table.concat(kv, ", ") .. " },")
	end
	table.insert(lines, "}")
	return table.concat(lines, "\n") .. "\n"
end

-- Creates/updates ReplicatedStorage.Shared.TrainingLightingPresets. Writing .Source only works in Studio
-- (command bar / plugin); in a live server it keeps an existing module and warns if none exists.
function TrainingAreas.PublishLightingPresets(): ModuleScript?
	local RS = game:GetService("ReplicatedStorage")
	local shared = RS:FindFirstChild("Shared")
	if not shared then
		shared = Instance.new("Folder"); (shared :: Folder).Name = "Shared"; (shared :: Folder).Parent = RS
	end
	local ms = (shared :: Instance):FindFirstChild("TrainingLightingPresets")
	if ms and not ms:IsA("ModuleScript") then ms:Destroy(); ms = nil end
	local created = false
	if not ms then
		ms = Instance.new("ModuleScript"); (ms :: ModuleScript).Name = "TrainingLightingPresets"; created = true
	end
	local ok = pcall(function() ((ms :: any) :: ModuleScript).Source = TrainingAreas.PresetsSource() end)
	if not ok then
		if created then
			warn("[Training] cannot write ModuleScript.Source at runtime; sync training/TrainingLightingPresets.lua via Rojo/Studio")
			return nil
		end
		return ms :: ModuleScript
	end
	(ms :: ModuleScript).Parent = shared
	return ms :: ModuleScript
end

-- ===== R15 placeholder bot =====
-- Builds a default R15 rig (Players:CreateHumanoidModelFromDescription, server-only) at a TrainingBotSpawn pad.
-- Falls back to a block rig (HumanoidRootPart + Torso + Head, welded) if the API is unavailable (e.g. edit mode).
-- Result: Model "SparringBot", PrimaryPart = HumanoidRootPart, tag TrainingBot, attrs TrainingBot=true, AreaId, RigType.
function TrainingAreas.CreatePlaceholderBot(pad: BasePart, parent: Instance?): Model
	local Players = game:GetService("Players")
	local m: Model? = nil
	local okR15, res = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = rgb(230, 230, 230); desc.TorsoColor = rgb(200, 40, 40)
		desc.LeftArmColor = rgb(230, 230, 230); desc.RightArmColor = rgb(230, 230, 230)
		desc.LeftLegColor = rgb(60, 60, 70); desc.RightLegColor = rgb(60, 60, 70)
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if okR15 and typeof(res) == "Instance" and (res :: Instance):IsA("Model") then
		m = res :: Model
		(m :: Model):SetAttribute("RigType", "R15")
	else
		local fm = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Transparency = 1; root.Parent = fm
		local torso = Instance.new("Part")
		torso.Name = "UpperTorso"; torso.Size = Vector3.new(2, 2, 1.2); torso.Color = rgb(200, 40, 40); torso.Parent = fm
		local head = Instance.new("Part")
		head.Name = "Head"; head.Size = Vector3.new(1.4, 1.4, 1.4); head.Color = rgb(230, 230, 230)
		head.CFrame = root.CFrame * CFrame.new(0, 1.7, 0); head.Parent = fm
		for _, x in ipairs({ torso, head }) do
			local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = x; w.Parent = root
		end
		local hum = Instance.new("Humanoid"); hum.HipHeight = 2; hum.Parent = fm
		fm.PrimaryPart = root
		fm:SetAttribute("RigType", "Block")
		m = fm
	end
	local model = m :: Model
	model.Name = "SparringBot"
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model:SetAttribute("TrainingBot", true)
	model:SetAttribute("AreaId", pad:GetAttribute("AreaId"))
	CollectionService:AddTag(model, "TrainingBot")
	model:PivotTo(pad.CFrame + Vector3.new(0, 4, 0))
	model.Parent = parent or pad.Parent or Workspace
	local r = model.PrimaryPart
	if r then pcall(function() r:SetNetworkOwner(nil) end) end
	return model
end

-- Spawns one placeholder per TrainingBotSpawn pad (optionally filtered by AreaId). For testing/greybox.
function TrainingAreas.SpawnPlaceholderBots(areaId: string?): {Model}
	local out = {}
	for _, pad in ipairs(CollectionService:GetTagged("TrainingBotSpawn")) do
		if pad:IsA("BasePart") and (areaId == nil or pad:GetAttribute("AreaId") == areaId) then
			table.insert(out, TrainingAreas.CreatePlaceholderBot(pad))
		end
	end
	return out
end

-- Lighting presets are applied CLIENT-side when a player enters an area (Lighting is global).
TrainingAreas.LightingPresets = {
	-- NOTE: keep in sync with training/TrainingLightingPresets.lua (regenerate via PresetsSource())
	Lobby = { ClockTime = 0, Ambient = rgb(70, 60, 110), FogColor = rgb(20, 18, 40), FogEnd = 4000 },
	HTC = { ClockTime = 12, Ambient = rgb(255, 255, 255), OutdoorAmbient = rgb(255, 255, 255), FogColor = rgb(255, 255, 255), FogStart = 50, FogEnd = 700, Brightness = 3 },
	GravityRoom = { ClockTime = 20, Ambient = rgb(180, 60, 60), FogColor = rgb(40, 0, 0), FogEnd = 2000 },
	KingKai = { ClockTime = 14, Ambient = rgb(200, 180, 120), FogColor = rgb(250, 220, 140), FogStart = 300, FogEnd = 2500 },
	BrolyCrater = { ClockTime = 18.5, Ambient = rgb(150, 90, 60), OutdoorAmbient = rgb(170, 100, 60), FogColor = rgb(140, 80, 50), FogStart = 250, FogEnd = 1800, Brightness = 2.5 },
	MoroNamek = { ClockTime = 16, Ambient = rgb(110, 140, 130), OutdoorAmbient = rgb(120, 150, 140), FogColor = rgb(150, 170, 160), FogStart = 300, FogEnd = 2200, Brightness = 2 },
	BeerusPlanet = { ClockTime = 17, Ambient = rgb(140, 110, 170), FogColor = rgb(120, 90, 180), FogStart = 400, FogEnd = 3000 },
}

-- ===== runner =====
local res = TrainingAreas.BuildAll() -- also publishes ReplicatedStorage.Shared.TrainingLightingPresets
for _, id in ipairs(TrainingAreas.Order) do
	print(string.format("[Training] %-22s %3d parts (budget %d)", id, res[id], TrainingAreas.Budget[id]))
end
-- Optional greybox test: TrainingAreas.SpawnPlaceholderBots("GravityRoom")
