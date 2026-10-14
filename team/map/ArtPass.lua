--!strict
-- ArtPass.lua (db-map v3; reads Arena attrs Radius/Bands, stand UniverseNumber/UniverseColor) — run once in the Studio command bar AFTER BuildArena.lua. Idempotent.
-- World of Void look: tiled stone ring (two-tone tiles, grout rings), marble pillars with gold caps,
-- purple-blue void sky, floating debris, light shafts, ornate Zeno viewing box, glowing numbered universe stands.
-- Gameplay-safe: chunks keep names/tags/size (ArenaDamage records colour/material at Init, so destruction still works);
-- every decor part is CanCollide/CanTouch/CanQuery = false (never counts for ring-out) and lives in WorldOfVoid.Decor.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

-- v2: ModuleScript ServerScriptService.ArtPass. ArtPass.Apply() reads Workspace.WorldOfVoid.Arena attributes
-- (Radius, Bands) + RingChunk Band/Sector attrs, so it scales with Arena.Resize. Called after every resize (Modules.Arena.refresh).
local ArtPass = {}
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

	local function rgb(r: number, g: number, b: number)
		return Color3.fromRGB(r, g, b)
	end
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

	-- 1) Tiled stone ring: alternate tones per band/sector (chessboard), slate texture
	local STONE_A, STONE_B = rgb(176, 168, 186), rgb(140, 132, 156)
	for _, c in CollectionService:GetTagged("RingChunk") do
		if c:IsA("BasePart") then
			local band = (c:GetAttribute("Band") :: number?) or 1
			local sector = (c:GetAttribute("Sector") :: number?) or 1
			c.Material = Enum.Material.Slate
			c.Color = if (band + sector) % 2 == 0 then STONE_A else STONE_B
		end
	end
	-- grout rings (thin dark lines on the surface between bands) + centre emblem; parented under the ring so they read as tiles
	local grout = Instance.new("Folder")
	grout.Name = "Grout"
	grout.Parent = decor
	-- grout: thin radial lines between sectors of the outer band + thin rim lines (segments, not discs, so tiles stay bright)
	local d = R / BANDS
	local nOuter = sectorsPerBand[BANDS] or 30
	for i = 0, nOuter - 1 do
		local a = math.rad(i * 360 / nOuter)
		local mid = CENTER + Vector3.new(math.cos(a) * (R - d / 2), 0.06, math.sin(a) * (R - d / 2))
		part({
			Name = "GroutR_" .. i,
			Size = Vector3.new(d, 0.12, 0.5),
			CFrame = CFrame.new(mid) * CFrame.Angles(0, -a, 0),
			Color = rgb(70, 60, 90),
			Material = Enum.Material.SmoothPlastic,
		}, grout)
	end
	for b = 1, BANDS - 1 do
		local r = b * d
		local n = math.clamp(math.floor(2 * math.pi * r / 35), 12, 36) -- v3: capped for mobile budget
		for i = 0, n - 1 do
			local a = math.rad((i + 0.5) * 360 / n)
			local mid = CENTER + Vector3.new(math.cos(a) * r, 0.06, math.sin(a) * r)
			part({
				Name = "GroutC",
				Size = Vector3.new(0.5, 0.12, 2 * math.pi * r / n + 0.5),
				CFrame = CFrame.new(mid) * CFrame.Angles(0, -a, 0),
				Color = rgb(70, 60, 90),
				Material = Enum.Material.SmoothPlastic,
			}, grout)
		end
	end
	part({
		Name = "Emblem",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, 26, 26),
		CFrame = CFrame.new(CENTER + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(255, 205, 90),
		Material = Enum.Material.Neon,
		Transparency = 0.55,
	}, grout)
	-- outer rim trim (gold), below the top so it never covers holes
	part({
		Name = "RimTrim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 2 * R + 6, 2 * R + 6),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(200, 160, 70),
		Material = Enum.Material.Metal,
	}, decor)

	-- 2) Pillars: marble shaft + gold base/cap + glowing band
	for _, p in CollectionService:GetTagged("ArenaCover") do
		if p:IsA("BasePart") then
			p.Material = Enum.Material.Marble
			p.Color = rgb(225, 220, 235)
			local top = p.CFrame * CFrame.new(0, p.Size.Y / 2, 0)
			local bot = p.CFrame * CFrame.new(0, -p.Size.Y / 2, 0)
			part({
				Name = p.Name .. "_Cap",
				Size = Vector3.new(p.Size.X + 3, 2.5, p.Size.Z + 3),
				CFrame = top * CFrame.new(0, 1.2, 0),
				Color = rgb(210, 170, 70),
				Material = Enum.Material.Metal,
			})
			part({
				Name = p.Name .. "_Base",
				Size = Vector3.new(p.Size.X + 3, 2, p.Size.Z + 3),
				CFrame = bot * CFrame.new(0, 1, 0),
				Color = rgb(210, 170, 70),
				Material = Enum.Material.Metal,
			})
			part({
				Name = p.Name .. "_Glow",
				Size = Vector3.new(p.Size.X + 0.6, 0.8, p.Size.Z + 0.6),
				CFrame = top * CFrame.new(0, -4, 0),
				Color = rgb(150, 120, 255),
				Material = Enum.Material.Neon,
			})
		end
	end

	-- 3) Void sky + lighting (purple-blue), bloom
	-- SINGLE-OWNER FIX (2026-10-14): this block used its own "ArtPass" tag, while Arena.BuildLobby tags an
	-- identical set (Sky / Atmosphere / ColorCorrectionEffect / BloomEffect) with "WorldOfVoid". Neither cleanup
	-- could see the other, and Modules.Arena.refresh() calls Apply() on every match AFTER Arena.Resize has
	-- already built the lobby lighting - so Lighting permanently held TWO Sky, TWO Atmosphere, TWO BloomEffect
	-- and TWO ColorCorrectionEffect. Same-class post-processing stacks, so bloom was double strength, colour
	-- correction doubled, and the visible skybox was whichever Sky Roblox happened to pick (i.e. the sky details
	-- were effectively random). Both passes now share one tag, so exactly one set exists and the last to run owns it.
	for _, c in Lighting:GetChildren() do
		-- Also purges the legacy "ArtPass" tag so an already-built place repairs itself on the next match.
		if c:GetAttribute("WorldOfVoid") or c:GetAttribute("ArtPass") then
			c:Destroy()
		end
	end
	local function lit(i: Instance)
		i:SetAttribute("WorldOfVoid", true)
		i.Parent = Lighting
	end
	Lighting.ClockTime = 0 -- starry void; ring lit by strong ambient
	Lighting.GeographicLatitude = 30
	Lighting.Ambient = rgb(165, 150, 205)
	Lighting.OutdoorAmbient = rgb(175, 160, 220)
	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.FogColor = rgb(70, 50, 140)
	Lighting.FogStart = 900
	Lighting.FogEnd = 5000
	-- Named so you can tell at a glance in Studio which pass currently owns the lighting.
	local sky = Instance.new("Sky")
	sky.Name = "ArtPass_Sky"
	sky.StarCount = 3000
	sky.CelestialBodiesShown = false
	sky.SunAngularSize = 0
	lit(sky)
	local atm = Instance.new("Atmosphere")
	atm.Name = "ArtPass_Atmosphere"
	atm.Density = 0.3
	atm.Offset = 0.25
	atm.Color = rgb(150, 110, 240)
	atm.Decay = rgb(90, 50, 190)
	atm.Glare = 0.6
	atm.Haze = 1.2
	lit(atm)
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds:Destroy()
	end
	local bp = workspace:FindFirstChild("Baseplate") :: BasePart?
	if bp then
		bp.Transparency = 1
	end -- default baseplate far below the void stays (catches falls) but is hidden
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ArtPass_Bloom"
	bloom.Intensity = 0.8
	bloom.Size = 30
	bloom.Threshold = 1.6
	lit(bloom)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "ArtPass_ColorCorrection"
	cc.TintColor = rgb(235, 228, 255)
	cc.Saturation = 0.12
	cc.Contrast = 0.08
	lit(cc)

	-- 4) Floating debris (rocks + small islands) around the arena
	local debris = Instance.new("Folder")
	debris.Name = "FloatingDebris"
	debris.Parent = decor
	for i = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(R + 70, R + 750)
		local y = 500 + rng:NextNumber(-260, 260)
		local s = if i <= 8 then rng:NextNumber(25, 45) else rng:NextNumber(3, 16)
		part({
			Name = "Rock_" .. i,
			Size = Vector3.new(s, s * rng:NextNumber(0.5, 0.9), s * rng:NextNumber(0.7, 1.2)),
			CFrame = CFrame.new(math.cos(a) * r, y, math.sin(a) * r)
				* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
			Color = rgb(90 + rng:NextInteger(0, 30), 80 + rng:NextInteger(0, 20), 120 + rng:NextInteger(0, 30)),
			Material = Enum.Material.Rock,
		}, debris)
	end
	-- 5) Light shafts from above (transparent neon beams)
	local shafts = Instance.new("Folder")
	shafts.Name = "LightShafts"
	shafts.Parent = decor
	for i = 1, 7 do
		local a = (i / 7) * math.pi * 2 + 0.3
		local base = CENTER
			+ Vector3.new(math.cos(a) * rng:NextNumber(40, R * 0.9), 0, math.sin(a) * rng:NextNumber(40, R * 0.9))
		local top = base + Vector3.new(rng:NextNumber(-80, 80), 700, rng:NextNumber(-80, 80))
		local len = (top - base).Magnitude
		part({
			Name = "Shaft_" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(len, rng:NextNumber(18, 34), rng:NextNumber(18, 34)),
			CFrame = CFrame.lookAt((base + top) / 2, top) * CFrame.Angles(0, math.rad(90), 0),
			Color = rgb(200, 190, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.93,
		}, shafts)
	end

	-- 6) Zeno's ornate viewing box
	local zb = arena:FindFirstChild("ZenoBox")
	local floor = zb and zb:FindFirstChild("Zeno_Floor") :: BasePart?
	if zb and floor then
		local zl = floor.CFrame
		for _, n in { "Zeno_BackWall", "Zeno_Roof", "Zeno_Floor" } do
			local p = zb:FindFirstChild(n) :: BasePart?
			if p then
				p.Material = Enum.Material.Marble
				p.Color = rgb(235, 230, 245)
			end
		end
		local zd = Instance.new("Folder")
		zd.Name = "ZenoOrnate"
		zd.Parent = decor
		local GOLD = rgb(255, 205, 90)
		for _, x in { -30, -15, 0, 15, 30 } do -- front columns
			part({
				Name = "Col",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(30, 3, 3),
				CFrame = zl * CFrame.new(x, 17, -20) * CFrame.Angles(0, 0, math.rad(90)),
				Color = GOLD,
				Material = Enum.Material.Foil,
			}, zd)
		end
		part({
			Name = "Frieze",
			Size = Vector3.new(66, 3, 3),
			CFrame = zl * CFrame.new(0, 32, -21),
			Color = GOLD,
			Material = Enum.Material.Foil,
		}, zd)
		part({
			Name = "Dome",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(40, 22, 30),
			CFrame = zl * CFrame.new(0, 36, 0),
			Color = rgb(120, 90, 210),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
		}, zd)
		part({
			Name = "Spire",
			Size = Vector3.new(2, 14, 2),
			CFrame = zl * CFrame.new(0, 52, 0),
			Color = GOLD,
			Material = Enum.Material.Foil,
		}, zd)
		part({
			Name = "Orb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 4,
			CFrame = zl * CFrame.new(0, 60, 0),
			Color = rgb(255, 230, 140),
			Material = Enum.Material.Neon,
		}, zd)
		part({
			Name = "Underside",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(56, 26, 38),
			CFrame = zl * CFrame.new(0, -12, 0),
			Color = rgb(170, 160, 200),
			Material = Enum.Material.Rock,
		}, zd)
		part({
			Name = "Emblem",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 12, 12),
			CFrame = zl * CFrame.new(0, 25, -22) * CFrame.Angles(0, math.rad(90), 0),
			Color = rgb(255, 220, 90),
			Material = Enum.Material.Neon,
		}, zd)
		-- thrones, platform, NPC spots now built by Arena.lua v3 (Zeno_Throne_*, Zeno_ThroneBack_*, ArenaNPCSpot)
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 220, 160)
		l.Range = 50
		l.Brightness = 2
		l.Parent = floor
	end

	-- 7) Glowing universe stands with numbers
	local stands = arena:FindFirstChild("Stands")
	if stands then
		for _, uf in stands:GetChildren() do
			local u = (uf:GetAttribute("UniverseNumber") :: number?) or (uf:GetAttribute("Universe") :: number?)
			local banner = uf:FindFirstChild("Banner") :: BasePart?
			local base = uf:FindFirstChild("Base") :: BasePart?
			if u and banner and base then
				local col = (uf:GetAttribute("UniverseColor") :: Color3?)
					or Color3.fromHSV(((u - 1) % 12) / 12, 0.75, 1)
				banner.Color = col
				local hasLabel = banner:FindFirstChild("UniverseLabel") ~= nil -- Arena v3 already labels banners
				for _, g in banner:GetChildren() do
					if g:IsA("PointLight") or (g:IsA("SurfaceGui") and not hasLabel) then
						g:Destroy()
					end
				end
				for _, face in (if hasLabel then {} else { Enum.NormalId.Front, Enum.NormalId.Back }) do
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
					t.Font = Enum.Font.GothamBlack
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
				part({
					Name = "StandTrim_U" .. u,
					Size = Vector3.new(base.Size.X + 1, 0.8, 1),
					CFrame = base.CFrame * CFrame.new(0, base.Size.Y / 2, -base.Size.Z / 2),
					Color = col,
					Material = Enum.Material.Neon,
				})
			end
		end
	end

	return string.format("ArtPass done: %d decor parts (R=%d, bands=%d)", count, R, BANDS)
end
return ArtPass
