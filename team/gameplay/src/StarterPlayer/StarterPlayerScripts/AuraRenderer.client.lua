-- LocalScript: v1.1 persistent auras for every player (client-side, visual only).
-- Form attribute (server-published): SSJ family = gold flame flicker (+ lightning for SSJ2/3), Blue = cyan flame with
-- white core, Ultra Instinct = silver wisps + heat-haze ring, other forms = coloured flame.
-- Wish rewards: Aura = "ChampionGold" -> gold sparkle + light; Cosmetic = "Halo" -> glowing halo above the head.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local STYLES = {
	gold = { a = rgb(255, 214, 60), b = rgb(255, 250, 200), rate = 140, speed = 9, size = 3.4, light = rgb(255, 210, 80) },
	blue = { a = rgb(40, 200, 255), b = rgb(230, 250, 255), rate = 140, speed = 9, size = 3.4, light = rgb(60, 200, 255) },
	ui = { a = rgb(225, 230, 255), b = rgb(150, 170, 255), rate = 60, speed = 4, size = 2.2, light = rgb(210, 220, 255), wisps = true },
	red = { a = rgb(255, 60, 50), b = rgb(255, 190, 160), rate = 60, speed = 7, size = 2, light = rgb(255, 80, 60) },
	purple = { a = rgb(160, 70, 255), b = rgb(255, 150, 220), rate = 60, speed = 6, size = 2.2, light = rgb(170, 90, 255) },
	white = { a = rgb(255, 255, 255), b = rgb(210, 220, 255), rate = 50, speed = 6, size = 2, light = rgb(240, 240, 255) },
	green = { a = rgb(120, 255, 90), b = rgb(230, 255, 200), rate = 70, speed = 8, size = 2.4, light = rgb(120, 255, 90) },
	black = { a = rgb(40, 20, 60), b = rgb(200, 120, 255), rate = 60, speed = 6, size = 2.2, light = rgb(150, 70, 220) },
}
local FORM_STYLE = {
	SuperSaiyan = "gold", SuperSaiyan2 = "gold", SuperSaiyan3 = "gold", Golden = "gold",
	SuperSaiyanBlue = "blue", SSBEvolved = "blue", UltraInstinctSign = "ui", MUI = "ui", UltraInstinct = "ui",
	SuperSaiyanGod = "red", KaioKen = "red", UltraEgo = "purple", FullPower = "white", Ultimate = "white",
	Legendary = "green", KeflaPotara = "green", BeastGohan = "white", FriezaBlack = "black", MoroAwakened = "purple",
}
local SPARKS = { SuperSaiyan2 = true, SuperSaiyan3 = true, KeflaPotara = true, SSBEvolved = true, BeastGohan = true }

local active: { [Player]: { form: string?, aura: string?, cos: string?, folder: Instance? } } = {}

local function mkPart(parent, size, color, transp)
	local p = Instance.new("Part")
	p.Size = size; p.Color = color; p.Transparency = transp or 1
	p.Material = Enum.Material.Neon; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Massless = true; p.CastShadow = false
	p.Parent = parent
	return p
end
local function weld(a, b, cf)
	b.CFrame = a.CFrame * cf
	local w = Instance.new("WeldConstraint"); w.Part0 = a; w.Part1 = b; w.Parent = b
end

local function build(p: Player, char: Model, form: string?, aura: string?, cos: string?)
	local root = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not root then return nil end
	local f = Instance.new("Folder"); f.Name = "ClientAura"; f.Parent = char
	local assets = game:GetService("ReplicatedStorage"):findFirstChild("AnimeRosterAssets")
	local auraModelName = if form == "SuperSaiyan" then "Aura_Gold"
		elseif form == "SuperSaiyan2" or form == "SuperSaiyan3" then "Aura_SSJ2"
		elseif form == "SuperSaiyanBlue" or form == "SSBEvolved" then "Aura_Blue"
		elseif form == "MUI" or form == "UltraInstinctSign" then "Aura_UltraInstinct"
		elseif form == "SuperSaiyanGod" or form == "KaioKen" then "Aura_Red"
		elseif form == "UltraEgo" then "Aura_Purple"
		elseif form == "Legendary" then "Aura_Lime"
		else nil
	if auraModelName and assets then
		local auraSrc = assets:FindFirstChild(auraModelName)
		if auraSrc then
			local ac = auraSrc:Clone()
			ac.Name = "AuthenticAnimeAura"
			for _, desc in ipairs(ac:GetDescendants()) do 
				if desc:IsA("BasePart") then
					desc.Anchored = false
					desc.CanCollide = false
					desc.Massless = true
					weld(root, desc, CFrame.new(0, -0.5, 0))
				end
			end
			ac.Parent = f
		end
	end
	local styleId = form and form ~= "Base" and FORM_STYLE[form]
	if styleId then
		local s = STYLES[styleId]
		local vol = mkPart(f, Vector3.new(3.4, 5.5, 2.4), s.a, 1)
		weld(root, vol, CFrame.new(0, -0.3, 0))
		local flame = Instance.new("ParticleEmitter")
		flame.Shape = Enum.ParticleEmitterShape.Box; flame.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		flame.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, s.b), ColorSequenceKeypoint.new(0.4, s.a), ColorSequenceKeypoint.new(1, s.a) })
		flame.LightEmission = 1; flame.LightInfluence = 0
		flame.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s.size * 0.6), NumberSequenceKeypoint.new(0.5, s.size), NumberSequenceKeypoint.new(1, 0) })
		flame.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.3, 0.25), NumberSequenceKeypoint.new(1, 1) })
		flame.Lifetime = NumberRange.new(0.35, 0.6); flame.Rate = s.rate
		flame.Speed = NumberRange.new(s.speed * 0.6, s.speed); flame.EmissionDirection = Enum.NormalId.Top
		flame.SpreadAngle = Vector2.new(8, 8); flame.Acceleration = Vector3.new(0, s.speed, 0)
		flame.Squash = NumberSequence.new(0.6); flame.ZOffset = -0.5
		flame.Parent = vol
		local l = Instance.new("PointLight"); l.Color = s.light; l.Range = 22; l.Brightness = 4; l.Parent = vol
		f:SetAttribute("Flicker", true)
		if s.wisps then -- UI: silver wisps orbiting + haze ring at the feet
			local w = Instance.new("ParticleEmitter")
			w.Color = ColorSequence.new(s.a, s.b); w.LightEmission = 1; w.Size = NumberSequence.new(0.35, 0)
			w.Lifetime = NumberRange.new(1, 1.6); w.Rate = 25; w.Speed = NumberRange.new(1, 3); w.SpreadAngle = Vector2.new(180, 180)
			w.Acceleration = Vector3.new(0, 2, 0); w.Parent = vol
			local ring = mkPart(f, Vector3.new(0.2, 7, 7), s.a, 0.75); ring.Shape = Enum.PartType.Cylinder
			weld(root, ring, CFrame.new(0, -2.9, 0) * CFrame.Angles(0, 0, math.rad(90)))
		end
		if SPARKS[form :: string] then -- SSJ2-style lightning
			local sp = Instance.new("ParticleEmitter")
			sp.Color = ColorSequence.new(rgb(170, 220, 255)); sp.LightEmission = 1; sp.Size = NumberSequence.new(0.25)
			sp.Lifetime = NumberRange.new(0.05, 0.1); sp.Rate = 30; sp.Speed = NumberRange.new(0); sp.Shape = Enum.ParticleEmitterShape.Box
			sp.Squash = NumberSequence.new(-3); sp.Rotation = NumberRange.new(0, 360)
			sp.Parent = vol
		end
	end
	if aura == "ChampionGold" then
		local a = Instance.new("Attachment"); a.Name = "WishAura"; a.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(rgb(255, 230, 120), rgb(255, 180, 40)); e.LightEmission = 1
		e.Size = NumberSequence.new(0.4, 0); e.Lifetime = NumberRange.new(0.8, 1.4); e.Rate = 22
		e.Speed = NumberRange.new(1, 3); e.SpreadAngle = Vector2.new(180, 180); e.Acceleration = Vector3.new(0, 3, 0)
		e.Parent = a
		local l = Instance.new("PointLight"); l.Color = rgb(255, 200, 80); l.Range = 9; l.Brightness = 1.5; l.Parent = a
		a:SetAttribute("Owned", true)
		local tag = Instance.new("ObjectValue"); tag.Value = a; tag.Name = "WishAuraRef"; tag.Parent = f
	end
	-- v1.2 store auras / outfits (StoreCatalog colours)
	local SC = require(game:GetService("ReplicatedStorage").Shared.StoreCatalog)
	local sa = type(aura) == "string" and SC.AURA_COLORS[aura]
	if sa then
		local a = Instance.new("Attachment"); a.Name = "StoreAura"; a.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(sa[1], sa[2]); e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }); e.Lifetime = NumberRange.new(0.6, 1.1); e.Rate = 30
		e.Speed = NumberRange.new(2, 4); e.SpreadAngle = Vector2.new(180, 180); e.Acceleration = Vector3.new(0, 5, 0)
		e.Parent = a
		local l = Instance.new("PointLight"); l.Color = sa[1]; l.Range = 10; l.Brightness = 1.6; l.Parent = a
		local tag = Instance.new("ObjectValue"); tag.Value = a; tag.Name = "StoreAuraRef"; tag.Parent = f
	end
	local so = type(cos) == "string" and SC.OUTFITS[cos]
	if so then
		local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
		local lower = char:FindFirstChild("LowerTorso")
		if torso then
			local gi = mkPart(f, (torso :: BasePart).Size + Vector3.new(0.12, 0.06, 0.12), so.gi, 0); gi.Name = "OutfitGi"; gi.Material = Enum.Material.Fabric
			weld(torso :: BasePart, gi, CFrame.new())
			local belt = mkPart(f, Vector3.new((torso :: BasePart).Size.X + 0.2, 0.3, (torso :: BasePart).Size.Z + 0.2), so.belt, 0); belt.Name = "OutfitBelt"
			weld(torso :: BasePart, belt, CFrame.new(0, -(torso :: BasePart).Size.Y / 2 + 0.1, 0))
			if so.symbol then
				local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = gi
				local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(0.5, 0.5); t.Position = UDim2.fromScale(0.45, 0.1); t.BackgroundColor3 = Color3.new(1, 1, 1)
				t.Text = so.symbol; t.TextScaled = true; t.Font = Enum.Font.GothamBlack; t.TextColor3 = so.belt; t.Parent = sg
			end
		end
		if lower then
			local pants = mkPart(f, (lower :: BasePart).Size + Vector3.new(0.12, 0.06, 0.12), so.pants or so.gi, 0); pants.Material = Enum.Material.Fabric
			weld(lower :: BasePart, pants, CFrame.new())
		end
	end
	if cos == "Halo" and head then
		local halo = mkPart(f, Vector3.new(0.3, 2.4, 2.4), rgb(255, 245, 190), 0.1); halo.Shape = Enum.PartType.Cylinder
		halo.Name = "Halo"
		weld(head, halo, CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local inner = mkPart(f, Vector3.new(0.35, 1.8, 1.8), rgb(30, 30, 40), 0); inner.Shape = Enum.PartType.Cylinder
		inner.Material = Enum.Material.SmoothPlastic
		weld(head, inner, CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local l = Instance.new("PointLight"); l.Color = rgb(255, 240, 180); l.Range = 6; l.Parent = halo
	end
	return f
end

local function refresh(p: Player)
	local char = p.Character
	local st = active[p]
	local form, aura, cos = p:GetAttribute("Form"), p:GetAttribute("Aura"), p:GetAttribute("Cosmetic")
	if st and st.folder and st.folder.Parent == char and st.form == form and st.aura == aura and st.cos == cos then return end
	if st and st.folder then
		local ref = st.folder:FindFirstChild("WishAuraRef")
		if ref and ref.Value then ref.Value:Destroy() end
		st.folder:Destroy()
	end
	active[p] = { form = form, aura = aura, cos = cos, folder = if char then build(p, char, form, aura, cos) else nil }
end

local function watch(p: Player)
	for _, a in { "Form", "Aura", "Cosmetic" } do p:GetAttributeChangedSignal(a):Connect(function() refresh(p) end) end
	p.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart", 5); task.wait(0.2); refresh(p) end)
	if p.Character then refresh(p) end
end
for _, p in Players:GetPlayers() do watch(p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p) active[p] = nil end)

-- Watch non-player combat models (Sparring Bots: Goku, Vegeta, ToP Bosses)
local watchedModels: { [Model]: boolean } = {}
local function watchModel(m: Instance)
	if not m:IsA("Model") or watchedModels[m] then return end
	if Players:GetPlayerFromCharacter(m) then return end -- handled by player watcher
	local root = m:FindFirstChild("HumanoidRootPart")
	if not root then return end
	watchedModels[m] = true

	local function refreshNpc()
		local form = m:GetAttribute("Form")
		local old = m:FindFirstChild("ClientAura")
		if old then old:Destroy() end
		if form and form ~= "Base" then
			build(nil, m, form, nil, nil)
		end
	end

	m:GetAttributeChangedSignal("Form"):Connect(refreshNpc)
	m.AncestryChanged:Connect(function(_, parent)
		if not parent then watchedModels[m] = nil end
	end)
	if m:GetAttribute("Form") and m:GetAttribute("Form") ~= "Base" then
		refreshNpc()
	end
end

workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Model") then
		task.delay(0.2, function()
			if desc.Parent and desc:FindFirstChild("HumanoidRootPart") then
				watchModel(desc)
			end
		end)
	end
end)
for _, desc in ipairs(workspace:GetDescendants()) do
	if desc:IsA("Model") and desc:FindFirstChild("HumanoidRootPart") then
		watchModel(desc)
	end
end


-- flicker (SSJ-style light pulse)
RunService.Heartbeat:Connect(function()
	for _, st in active do
		local f = st.folder
		if f and f.Parent and f:GetAttribute("Flicker") then
			for _, d in f:GetDescendants() do
				if d:IsA("PointLight") then d.Brightness = 3 + math.random() * 3 end
			end
		end
	end
end)
