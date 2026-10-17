--!strict
-- ArtPass.lua (db-map v4, "Null Realm" art direction, PLAN_V11 Step A; reads Arena attrs Radius/Bands, stand
-- UniverseNumber/UniverseColor). ModuleScript ServerScriptService.ArtPass; Apply() runs after every Arena.Resize
-- (Modules.Arena.refresh) and is idempotent.
-- Look (approved 2026-10-16, artifact "Tournament Arena Look"): A as the base = pale lavender-grey stone stage, tall
-- square columns (some broken), layered rock underside, starry void; B only where it means "the gods" = gold trim on
-- Zeno's box and the universe stands; C for damage = glowing ki cracks (ArenaDamage). The void's colour drifts over
-- the 48:00 show clock on the client (SkyCycle.client.lua), from the base set here.
-- Gameplay-safe: chunks keep names/tags/size (ArenaDamage records colour/material at Init, so destruction still works);
-- every decor part is CanCollide/CanTouch/CanQuery = false (never counts for ring-out) and lives in WorldOfVoid.Decor.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local ArtPass = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- palette (PLAN_V11 Step A, look-dev A)
ArtPass.Palette = {
	stoneA = rgb(196, 192, 204), stoneB = rgb(176, 172, 186), seam = rgb(78, 70, 94),
	trim = rgb(232, 230, 238), column = rgb(205, 200, 212), cap = rgb(238, 236, 244),
	rock = rgb(120, 108, 132), gold = rgb(214, 172, 66), goldBright = rgb(255, 214, 110),
	-- base void (SkyCycle drifts from here)
	atmo = rgb(150, 128, 196), decay = rgb(70, 46, 120), tint = rgb(246, 242, 255),
}
local PAL = ArtPass.Palette

-- Nebula skybox (team/map/skybox, from the CC-BY "FREE - SkyBox Space Nebula" by paul_paul_paul; credit in
-- Shared/Credits.lua). Set to the six uploaded image ids ({ Ft = "rbxassetid://...", ... }) once uploaded; nil keeps
-- the procedural starfield. Roblox renders a skybox black at night, so with faces the arena runs at a daytime clock.
ArtPass.SkyFaces = nil :: { [string]: string }?

-- Exactly one Sky / Atmosphere / grade in Lighting. Leftovers from older builds (untagged, saved in the place) are
-- moved to ServerStorage.LightingArchive at runtime, never deleted, so the place file keeps them.
local function archiveStrayLighting()
	local archive = ServerStorage:FindFirstChild("LightingArchive")
	for _, c in Lighting:GetChildren() do
		local isLook = c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("PostEffect")
		if isLook and not c:GetAttribute("WorldOfVoid") then
			if not archive then
				local f = Instance.new("Folder")
				f.Name = "LightingArchive"
				f.Parent = ServerStorage
				archive = f
			end
			c.Parent = archive
		end
	end
end

function ArtPass.Apply(): string
	local wov = workspace:WaitForChild("WorldOfVoid")
	local arena = wov:WaitForChild("Arena")
	local old = wov:FindFirstChild("Decor")
	if old then
		old:Destroy()
	end
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = wov
	local CENTER = Vector3.new(0, 500, 0)
	local R = (arena:GetAttribute("Radius") :: number?) or 150
	local BANDS = (arena:GetAttribute("Bands") :: number?) or 5
	local sectorsPerBand: { [number]: number } = {}
	for _, c in CollectionService:GetTagged("RingChunk") do
		local b = c:GetAttribute("Band") :: number?
		if b then
			sectorsPerBand[b] = math.max(sectorsPerBand[b] or 0, (c:GetAttribute("Sector") :: number?) or 0)
		end
	end
	local rng = Random.new(7)
	local count = 0

	local function part(props: { [string]: any }, parent: Instance?): BasePart
		local p = Instance.new(props.Class or "Part") :: BasePart
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			if k ~= "Class" then
				(p :: any)[k] = v
			end
		end
		p.Parent = parent or decor
		count += 1
		return p
	end

	-- 1) Stone stage: two-tone slate tiles (chessboard by band/sector), dark seams, marble rim
	for _, c in CollectionService:GetTagged("RingChunk") do
		if c:IsA("BasePart") then
			local band = (c:GetAttribute("Band") :: number?) or 1
			local sector = (c:GetAttribute("Sector") :: number?) or 1
			c.Material = Enum.Material.Slate
			c.Color = if (band + sector) % 2 == 0 then PAL.stoneA else PAL.stoneB
		end
	end
	local grout = Instance.new("Folder")
	grout.Name = "Grout"
	grout.Parent = decor
	local d = R / BANDS
	local nOuter = sectorsPerBand[BANDS] or 30
	for i = 0, nOuter - 1 do -- radial seams across the outer band
		local a = math.rad(i * 360 / nOuter)
		local mid = CENTER + Vector3.new(math.cos(a) * (R - d / 2), 0.06, math.sin(a) * (R - d / 2))
		part({ Name = "GroutR_" .. i, Size = Vector3.new(d, 0.12, 0.6), CFrame = CFrame.new(mid) * CFrame.Angles(0, -a, 0),
			Color = PAL.seam, Material = Enum.Material.Slate }, grout)
	end
	for b = 1, BANDS - 1 do -- ring seams between bands (segments, capped for the mobile budget)
		local r = b * d
		local n = math.clamp(math.floor(2 * math.pi * r / 35), 12, 36)
		for i = 0, n - 1 do
			local a = math.rad((i + 0.5) * 360 / n)
			local mid = CENTER + Vector3.new(math.cos(a) * r, 0.06, math.sin(a) * r)
			part({ Name = "GroutC", Size = Vector3.new(0.6, 0.12, 2 * math.pi * r / n + 0.5), CFrame = CFrame.new(mid) * CFrame.Angles(0, -a, 0),
				Color = PAL.seam, Material = Enum.Material.Slate }, grout)
		end
	end
	-- centre medallion: a pale marble disc with a thin dark ring (engraved, not glowing)
	part({ Name = "Medallion", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.14, 30, 30),
		CFrame = CFrame.new(CENTER + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = PAL.trim,
		Material = Enum.Material.Marble }, grout)
	part({ Name = "MedallionRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.16, 26, 26),
		CFrame = CFrame.new(CENTER + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = PAL.seam,
		Material = Enum.Material.Slate }, grout)
	part({ Name = "MedallionCore", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 24.6, 24.6),
		CFrame = CFrame.new(CENTER + Vector3.new(0, 0.09, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = PAL.stoneA,
		Material = Enum.Material.Slate }, grout)
	-- outer rim: marble band below the top surface (never covers holes), with a thin seam under it
	part({ Name = "RimTrim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 2 * R + 6, 2 * R + 6),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = PAL.trim,
		Material = Enum.Material.Marble })
	part({ Name = "RimSeam", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2 * R + 7, 2 * R + 7),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = PAL.seam,
		Material = Enum.Material.Slate })

	-- 2) Columns: concrete shafts with marble cap and base; broken ones get a jagged rubble top instead of a cap
	for _, p in CollectionService:GetTagged("ArenaCover") do
		if p:IsA("BasePart") then
			p.Material = Enum.Material.Concrete
			p.Color = PAL.column
			local top = p.CFrame * CFrame.new(0, p.Size.Y / 2, 0)
			local bot = p.CFrame * CFrame.new(0, -p.Size.Y / 2, 0)
			part({ Name = p.Name .. "_Base", Size = Vector3.new(p.Size.X + 3, 2, p.Size.Z + 3), CFrame = bot * CFrame.new(0, 1, 0),
				Color = PAL.cap, Material = Enum.Material.Marble })
			if p:GetAttribute("Broken") then
				for k = 1, 3 do
					local s = 2.5 + k
					part({ Name = p.Name .. "_Rubble", Size = Vector3.new(s, s * 0.7, s),
						CFrame = top * CFrame.new(rng:NextNumber(-2, 2), 0.3, rng:NextNumber(-2, 2))
							* CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6), rng:NextNumber(-0.6, 0.6)),
						Color = PAL.column, Material = Enum.Material.Concrete })
				end
			else
				part({ Name = p.Name .. "_Cap", Size = Vector3.new(p.Size.X + 3, 2.4, p.Size.Z + 3), CFrame = top * CFrame.new(0, 1.2, 0),
					Color = PAL.cap, Material = Enum.Material.Marble })
				part({ Name = p.Name .. "_Band", Size = Vector3.new(p.Size.X + 0.6, 0.8, p.Size.Z + 0.6), CFrame = top * CFrame.new(0, -3, 0),
					Color = PAL.seam, Material = Enum.Material.Slate })
			end
		end
	end

	-- 3) Underside: hanging rock spurs under the rim so the stage reads as a floating island from the stands
	local spurs = Instance.new("Folder")
	spurs.Name = "Underside"
	spurs.Parent = decor
	local nSpurs = math.clamp(math.floor(R / 12), 12, 32)
	for i = 1, nSpurs do
		local a = (i / nSpurs) * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
		local r = R * rng:NextNumber(0.55, 0.92)
		local h = rng:NextNumber(18, 55)
		local w = rng:NextNumber(10, 22)
		part({ Class = "WedgePart", Name = "Spur", Size = Vector3.new(w, h, w * 0.8),
			CFrame = CFrame.new(CENTER + Vector3.new(math.cos(a) * r, -20 - h / 2, math.sin(a) * r))
				* CFrame.Angles(math.pi, a, rng:NextNumber(-0.2, 0.2)),
			Color = PAL.rock:Lerp(rgb(80, 70, 96), rng:NextNumber(0, 0.5)), Material = Enum.Material.Rock }, spurs)
	end

	-- 4) Lighting: one sky, one atmosphere, one grade, one bloom. Starry void; the stage is lit by a neutral fill so the
	-- stone stays pale and fighters / auras carry the colour. ArtPass.SkyFaces swaps the stars for the nebula.
	archiveStrayLighting()
	for _, c in Lighting:GetChildren() do
		if c:GetAttribute("WorldOfVoid") or c:GetAttribute("ArtPass") then
			c:Destroy()
		end
	end
	local function lit(i: Instance)
		i:SetAttribute("WorldOfVoid", true)
		i.Parent = Lighting
	end
	local faces = ArtPass.SkyFaces
	Lighting.ClockTime = if faces then 14 else 0
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = if faces then 2 else 3
	Lighting.Ambient = rgb(150, 146, 162)
	Lighting.OutdoorAmbient = rgb(172, 168, 184)
	Lighting.ExposureCompensation = 0.25
	Lighting.EnvironmentDiffuseScale = 0.2
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.FogColor = rgb(60, 48, 96)
	Lighting.FogStart = 1200
	Lighting.FogEnd = 6000
	-- publish the base look as replicated attributes: client lighting scripts (TrainingLighting) restore to these
	-- live values when a player leaves an area, instead of a snapshot taken before this pass ran
	for _, k in { "ClockTime", "Ambient", "OutdoorAmbient", "FogColor", "FogStart", "FogEnd", "Brightness" } do
		Lighting:SetAttribute("Base_" .. k, (Lighting :: any)[k])
	end
	local sky = Instance.new("Sky")
	sky.Name = "WOV_Sky"
	sky.StarCount = if faces then 0 else 5000
	sky.CelestialBodiesShown = false
	sky.SunAngularSize = 0
	if faces then
		for _, f in { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" } do
			(sky :: any)["Skybox" .. f] = faces[f]
		end
	end
	lit(sky)
	local atm = Instance.new("Atmosphere")
	atm.Name = "WOV_Atmosphere"
	-- at night a denser atmosphere renders as a sky-blue band; keep it a faint violet horizon. With the nebula faces,
	-- thinner still so the nebula reads through it
	atm.Density = if faces then 0.08 else 0.14
	atm.Offset = if faces then 0.25 else 0.6 -- haze sits at the horizon, the stage stays clean
	atm.Color = PAL.atmo
	atm.Decay = PAL.decay
	atm.Glare = 0
	atm.Haze = if faces then 0.4 else 1.4
	lit(atm)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "WOV_Grade"
	cc.TintColor = PAL.tint
	cc.Saturation = 0.08
	cc.Contrast = 0.1
	lit(cc)
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "WOV_Bloom"
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 1.4
	lit(bloom)
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds:Destroy()
	end
	local bp = workspace:FindFirstChild("Baseplate") :: BasePart?
	if bp then
		bp.Transparency = 1
	end -- default baseplate far below the void stays (catches falls) but is hidden

	-- 4b) The void below: deep and dark, a faint violet swirl far down; the old glowing haze sheet is hidden
	local voidF = arena:FindFirstChild("Void")
	if voidF then
		for _, v in voidF:GetChildren() do
			if v:IsA("BasePart") then
				if v.Name == "Void_Plane" then
					v.Material = Enum.Material.SmoothPlastic
					v.Color = rgb(10, 8, 20)
				elseif v.Name == "Void_Haze" then
					v.Transparency = 1
				elseif v.Name:sub(1, 10) == "Void_Swirl" then
					v.Color = rgb(80, 44, 140)
					v.Transparency = math.max(v.Transparency, 0.93)
				end
			end
		end
	end

	-- 5) Floating debris: chunks of the same stone drifting around the void (some big enough to read as islands)
	local debris = Instance.new("Folder")
	debris.Name = "FloatingDebris"
	debris.Parent = decor
	for i = 1, 60 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(R + 90, R + 760)
		local y = 500 + rng:NextNumber(-240, 220)
		local s = if i <= 8 then rng:NextNumber(24, 44) else rng:NextNumber(3, 14)
		part({ Name = "Rock_" .. i, Size = Vector3.new(s, s * rng:NextNumber(0.5, 0.9), s * rng:NextNumber(0.7, 1.2)),
			CFrame = CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
			Color = (if i % 3 == 0 then PAL.stoneB else PAL.rock):Lerp(rgb(70, 62, 88), rng:NextNumber(0, 0.35)),
			Material = if i % 3 == 0 then Enum.Material.Slate else Enum.Material.Rock }, debris)
	end

	-- 6) Zeno's box: white marble, gold where it matters (columns, frieze, roof edge, spire), violet glass dome
	local zb = arena:FindFirstChild("ZenoBox")
	local floor = zb and zb:FindFirstChild("Zeno_Floor") :: BasePart?
	if zb and floor then
		local zl = floor.CFrame
		for _, n in { "Zeno_BackWall", "Zeno_Floor", "Zeno_Platform" } do
			local p = zb:FindFirstChild(n) :: BasePart?
			if p then
				p.Material = Enum.Material.Marble
				p.Color = PAL.cap
			end
		end
		local roof = zb:FindFirstChild("Zeno_Roof") :: BasePart?
		if roof then
			roof.Material = Enum.Material.Marble
			roof.Color = PAL.cap
		end
		local trim = zb:FindFirstChild("Zeno_PlatformTrim") :: BasePart?
		if trim then
			trim.Material = Enum.Material.Foil
			trim.Color = PAL.gold
		end
		local zd = Instance.new("Folder")
		zd.Name = "ZenoOrnate"
		zd.Parent = decor
		for _, x in { -30, -15, 0, 15, 30 } do
			part({ Name = "Col", Shape = Enum.PartType.Cylinder, Size = Vector3.new(30, 3, 3),
				CFrame = zl * CFrame.new(x, 17, -20) * CFrame.Angles(0, 0, math.rad(90)), Color = PAL.gold, Material = Enum.Material.Foil }, zd)
		end
		part({ Name = "Frieze", Size = Vector3.new(66, 3, 3), CFrame = zl * CFrame.new(0, 32, -21), Color = PAL.gold, Material = Enum.Material.Foil }, zd)
		part({ Name = "RoofEdge", Size = Vector3.new(66, 1.2, 46), CFrame = zl * CFrame.new(0, 34.4, 0), Color = PAL.gold, Material = Enum.Material.Foil }, zd)
		part({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(40, 22, 30), CFrame = zl * CFrame.new(0, 36, 0),
			Color = rgb(150, 110, 230), Material = Enum.Material.Glass, Transparency = 0.25 }, zd)
		part({ Name = "Spire", Size = Vector3.new(2, 14, 2), CFrame = zl * CFrame.new(0, 52, 0), Color = PAL.gold, Material = Enum.Material.Foil }, zd)
		part({ Name = "Orb", Shape = Enum.PartType.Ball, Size = Vector3.one * 4, CFrame = zl * CFrame.new(0, 60, 0), Color = PAL.goldBright,
			Material = Enum.Material.Neon }, zd)
		part({ Name = "Underside", Shape = Enum.PartType.Ball, Size = Vector3.new(56, 26, 38), CFrame = zl * CFrame.new(0, -12, 0),
			Color = PAL.rock, Material = Enum.Material.Rock }, zd)
		part({ Name = "Emblem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 12, 12),
			CFrame = zl * CFrame.new(0, 25, -22) * CFrame.Angles(0, math.rad(90), 0), Color = PAL.goldBright, Material = Enum.Material.Neon }, zd)
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 226, 170)
		l.Range = 50
		l.Brightness = 2
		l.Parent = floor
	end

	-- 7) Universe stands: marble, universe colour on banner and front lip, gold rail along the front (the gods' benches)
	local stands = arena:FindFirstChild("Stands")
	if stands then
		for _, uf in stands:GetChildren() do
			local u = (uf:GetAttribute("UniverseNumber") :: number?) or (uf:GetAttribute("Universe") :: number?)
			local banner = uf:FindFirstChild("Banner") :: BasePart?
			local base = uf:FindFirstChild("Base") :: BasePart?
			if u and banner and base then
				local col = (uf:GetAttribute("UniverseColor") :: Color3?) or Color3.fromHSV(((u - 1) % 12) / 12, 0.75, 1)
				banner.Color = col
				local hasLabel = banner:FindFirstChild("UniverseLabel") ~= nil -- Arena v3 already labels banners
				for _, g in banner:GetChildren() do
					if g:IsA("PointLight") or (g:IsA("SurfaceGui") and not hasLabel) then
						g:Destroy()
					end
				end
				for _, face in (if hasLabel then {} else { Enum.NormalId.Front, Enum.NormalId.Back }) :: { Enum.NormalId } do
					local sg = Instance.new("SurfaceGui")
					sg.Face = face
					sg.LightInfluence = 0
					sg.Brightness = 2
					sg.PixelsPerStud = 25
					sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
					sg.Parent = banner
					local t = Instance.new("TextLabel")
					t.Size = UDim2.fromScale(1, 1)
					t.BackgroundTransparency = 1
					t.Text = "UNIVERSE " .. u
					t.Font = Enum.Font.FredokaOne
					t.TextScaled = true
					t.TextColor3 = Color3.new(1, 1, 1)
					t.TextStrokeTransparency = 0.2
					t.TextStrokeColor3 = rgb(20, 10, 40)
					t.Parent = sg
				end
				local l = Instance.new("PointLight")
				l.Color = col
				l.Range = 45
				l.Brightness = 2.5
				l.Parent = banner
				for _, n in { "Base", "BackWall" } do
					local p = uf:FindFirstChild(n) :: BasePart?
					if p then
						p.Material = Enum.Material.Marble
						p.Color = PAL.cap
					end
				end
				part({ Name = "StandTrim_U" .. u, Size = Vector3.new(base.Size.X + 1, 0.8, 1),
					CFrame = base.CFrame * CFrame.new(0, base.Size.Y / 2, -base.Size.Z / 2), Color = col, Material = Enum.Material.Neon })
				part({ Name = "StandRail_U" .. u, Size = Vector3.new(base.Size.X + 2, 1.2, 1.2),
					CFrame = base.CFrame * CFrame.new(0, base.Size.Y / 2 + 3, -base.Size.Z / 2 + 0.6), Color = PAL.gold, Material = Enum.Material.Foil })
				for _, sx in { -0.48, 0, 0.48 } do
					part({ Name = "StandPost_U" .. u, Size = Vector3.new(0.8, 3, 0.8),
						CFrame = base.CFrame * CFrame.new(base.Size.X * sx, base.Size.Y / 2 + 1.5, -base.Size.Z / 2 + 0.6), Color = PAL.gold,
						Material = Enum.Material.Foil })
				end
			end
		end
	end

	return string.format("ArtPass v4 done: %d decor parts (R=%d, bands=%d)", count, R, BANDS)
end
return ArtPass
