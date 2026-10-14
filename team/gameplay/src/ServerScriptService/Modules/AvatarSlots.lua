--!strict
-- ModuleScript: ServerScriptService.Modules.AvatarSlots (v2.0 Unified Anime R15 Cel-Shaded System)
-- Enforces a cohesive anime fighting game aesthetic (TSB / Jujutsu Shenanigans style).
-- Every character in the 103-fighter roster uses standardized R15 humanoid proportions,
-- canonical clothing templates, race-accurate skin tones, and signature anime 3D hair/accessories.
-- Supports 1-frame dynamic hair/chitin/aura transformations in-match (Base -> SSJ -> Blue -> MUI).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Races = require(ReplicatedStorage.Shared.Races)

local AvatarSlots = {}

local ASSETS_FOLDER = "AnimeRosterAssets"
local function getAssets(): Folder?
	local f = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER)
	return if f and f:IsA("Folder") then f else nil
end

-- Skin tone presets per race / archetype
local SKIN_TONES: { [string]: Color3 } = {
	Saiyan = Color3.fromRGB(255, 222, 192),
	HalfSaiyan = Color3.fromRGB(255, 224, 195),
	Earthling = Color3.fromRGB(255, 220, 190),
	Namekian = Color3.fromRGB(92, 182, 98),
	FriezaRace = Color3.fromRGB(246, 245, 252),
	Android = Color3.fromRGB(255, 226, 200),
	PrideTrooper = Color3.fromRGB(255, 220, 190),
	JirenType = Color3.fromRGB(195, 198, 208),
	Kaioshin = Color3.fromRGB(220, 215, 240),
	Angel = Color3.fromRGB(182, 225, 245),
	Destroyer = Color3.fromRGB(162, 122, 198),
	Majin = Color3.fromRGB(255, 160, 200),
}

-- Transformation hair & eye styling
local FORM_HAIR_STYLES: { [string]: { color: Color3, material: Enum.Material, glow: boolean } } = {
	Base = { color = Color3.fromRGB(25, 25, 25), material = Enum.Material.SmoothPlastic, glow = false },
	KaioKen = { color = Color3.fromRGB(255, 55, 75), material = Enum.Material.Neon, glow = true },
	SuperSaiyan = { color = Color3.fromRGB(255, 225, 55), material = Enum.Material.Neon, glow = true },
	SuperSaiyan2 = { color = Color3.fromRGB(255, 235, 75), material = Enum.Material.Neon, glow = true },
	SuperSaiyan3 = { color = Color3.fromRGB(255, 220, 45), material = Enum.Material.Neon, glow = true },
	SuperSaiyanGod = { color = Color3.fromRGB(255, 42, 82), material = Enum.Material.Neon, glow = true },
	SuperSaiyanBlue = { color = Color3.fromRGB(0, 208, 255), material = Enum.Material.Neon, glow = true },
	SSBEvolved = { color = Color3.fromRGB(0, 135, 255), material = Enum.Material.Neon, glow = true },
	UltraInstinctSign = { color = Color3.fromRGB(48, 48, 58), material = Enum.Material.SmoothPlastic, glow = false },
	MUI = { color = Color3.fromRGB(245, 248, 255), material = Enum.Material.Neon, glow = true },
	UltraEgo = { color = Color3.fromRGB(158, 42, 188), material = Enum.Material.Neon, glow = true },
	Golden = { color = Color3.fromRGB(255, 215, 0), material = Enum.Material.Neon, glow = true },
	FriezaBlack = { color = Color3.fromRGB(28, 28, 34), material = Enum.Material.SmoothPlastic, glow = false },
	BeastGohan = { color = Color3.fromRGB(238, 242, 252), material = Enum.Material.Neon, glow = true },
	Legendary = { color = Color3.fromRGB(118, 255, 48), material = Enum.Material.Neon, glow = true },
	SuperSaiyan4 = { color = Color3.fromRGB(32, 32, 32), material = Enum.Material.SmoothPlastic, glow = false },
	KeflaPotara = { color = Color3.fromRGB(122, 255, 62), material = Enum.Material.Neon, glow = true },
}

local ANIME_FACES: { [string]: { [string]: string } } = {
	goku = {
		Base = "rbxassetid://33395283",
		KaioKen = "rbxassetid://33397568",
		SuperSaiyan = "rbxassetid://33397568",
		SuperSaiyan2 = "rbxassetid://33397568",
		SuperSaiyan3 = "rbxassetid://33397568",
		SuperSaiyanGod = "rbxassetid://261218098",
		SuperSaiyanBlue = "rbxassetid://261218098",
		SSBEvolved = "rbxassetid://261218098",
		UltraInstinctSign = "rbxassetid://33397568",
		MUI = "rbxassetid://33397568",
	},
	vegeta = {
		Base = "rbxassetid://222129434",
		SuperSaiyan = "rbxassetid://222129434",
		SuperSaiyan2 = "rbxassetid://222129434",
		SuperSaiyanGod = "rbxassetid://222129434",
		SuperSaiyanBlue = "rbxassetid://222129434",
		SSBEvolved = "rbxassetid://222129434",
		UltraEgo = "rbxassetid://222129434",
	},
	default = {
		Base = "rbxassetid://33395283",
		SuperSaiyan = "rbxassetid://33397568",
		SuperSaiyanBlue = "rbxassetid://261218098",
		MUI = "rbxassetid://33397568",
	},
}

local function applyFace(char: Model, charId: string, formId: string)
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local decal = head:FindFirstChildOfClass("Decal")
	if not decal then
		decal = Instance.new("Decal")
		decal.Name = "face"
		decal.Face = Enum.NormalId.Front
		decal.Parent = head
	end
	local key = if charId:find("vegeta") then "vegeta" elseif charId:find("goku") then "goku" else "default"
	local set = ANIME_FACES[key] or ANIME_FACES.default
	decal.Texture = set[formId] or set.Base
end

local function cleanAnimeAssets(char: Model)
	for _, child in ipairs(char:GetChildren()) do
		if child:GetAttribute("AnimeAsset") == true then
			child:Destroy()
		end
	end
end

local function setSkinColors(char: Model, color: Color3)
	local bc = char:FindFirstChildOfClass("BodyColors")
	if not bc then
		bc = Instance.new("BodyColors")
		bc.Name = "BodyColors"
		bc.Parent = char
	end
	bc.HeadColor3 = color
	bc.TorsoColor3 = color
	bc.LeftArmColor3 = color
	bc.RightArmColor3 = color
	bc.LeftLegColor3 = color
	bc.RightLegColor3 = color
end

local function setClothing(char: Model, shirtId: string?, pantsId: string?)
	local s = char:FindFirstChildOfClass("Shirt")
	if shirtId and shirtId ~= "" then
		if not s then
			s = Instance.new("Shirt")
			s.Name = "Shirt"
			s.Parent = char
		end
		s.ShirtTemplate = shirtId
	elseif s then
		s:Destroy()
	end

	local p = char:FindFirstChildOfClass("Pants")
	if pantsId and pantsId ~= "" then
		if not p then
			p = Instance.new("Pants")
			p.Name = "Pants"
			p.Parent = char
		end
		p.PantsTemplate = pantsId
	elseif p then
		p:Destroy()
	end
end

local function setScales(hum: Humanoid, height: number, width: number, depth: number, head: number)
	local function setVal(name: string, val: number)
		local scale = hum:FindFirstChild(name)
		if not scale then
			scale = Instance.new("NumberValue")
			scale.Name = name
			scale.Parent = hum
		end
		(scale :: NumberValue).Value = val
	end
	setVal("BodyHeightScale", height)
	setVal("BodyWidthScale", width)
	setVal("BodyDepthScale", depth)
	setVal("HeadScale", head)
end

function AvatarSlots.applyAnimeStyle(p: Player, charId: string): boolean
	local char = p.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head") :: BasePart?
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not head or not hrp or hum.RigType ~= Enum.HumanoidRigType.R15 then
		return false
	end

	cleanAnimeAssets(char)
	char:SetAttribute("ChampionModel", charId)

	local raceId = Races.CHAMPION[charId] or "Saiyan"
	local raceColor = SKIN_TONES[raceId] or SKIN_TONES.Saiyan
	setSkinColors(char, raceColor)

	-- Proportions scaling
	if charId == "u11_jiren" or charId == "u11_toppo" or charId == "u7_broly" then
		setScales(hum, 1.15, 1.25, 1.25, 1.05)
	elseif raceId == "Angel" then
		setScales(hum, 1.2, 0.9, 0.9, 0.95)
	elseif charId == "u7_krillin" or charId == "u7_master_roshi" or charId == "npc_grand_priest" then
		setScales(hum, 0.82, 0.9, 0.9, 0.95)
	else
		setScales(hum, 1.0, 1.0, 1.0, 1.0)
	end

	-- Assets lookup
	local assets = getAssets()
	local hairFolder = assets and assets:FindFirstChild("Hair")
	local accFolder = assets and assets:FindFirstChild("Accessories")

	-- Outfit determination
	local shirtId = "rbxassetid://18504993117"
	local pantsId = "rbxassetid://18504993117"

	if charId:find("vegeta") then
		shirtId = "rbxassetid://1245568434"
		pantsId = "rbxassetid://917557257"
	elseif charId:find("jiren") or charId:find("toppo") or charId:find("dyspo") or charId:find("kahseral") then
		shirtId = "http://www.roblox.com/asset/?id=4791252132"
		pantsId = "http://www.roblox.com/asset/?id=4791254254"
	elseif
		charId:find("beerus")
		or charId:find("champa")
		or charId:find("whis")
		or charId:find("vados")
		or raceId == "Angel"
	then
		-- Destroyers and Angels share the same divine formalwear template.
		shirtId = "http://www.roblox.com/asset/?id=245880330"
		pantsId = "http://www.roblox.com/asset/?id=245880370"
	elseif charId == "u6_hit" then
		shirtId = "rbxassetid://1590320673"
		pantsId = "rbxassetid://1296338528"
	elseif charId == "u7_frieza" or charId == "u6_frost" then
		shirtId = "rbxassetid://772791400"
		pantsId = "rbxassetid://889260241"
	elseif charId == "u6_kale" then
		shirtId = "rbxassetid://1590414997"
		pantsId = "rbxassetid://1590407402"
	elseif charId == "u6_caulifla" then
		shirtId = "rbxassetid://1447145991"
		pantsId = "rbxassetid://1394583523"
	end
	setClothing(char, shirtId, pantsId)

	-- Hair / Headpiece
	local hairSource: Instance? = nil
	if charId:find("vegeta") then
		hairSource = hairFolder and hairFolder:FindFirstChild("VegetaHair")
	elseif raceId == "Saiyan" or raceId == "HalfSaiyan" or charId:find("goku") then
		hairSource = hairFolder and hairFolder:FindFirstChild("GokuHair")
	end

	if hairSource then
		local hairClone = hairSource:Clone()
		hairClone.Name = "AnimeHair"
		hairClone:SetAttribute("AnimeAsset", true)
		if hairClone:IsA("Accessory") then
			hum:AddAccessory(hairClone)
		elseif hairClone:IsA("BasePart") or hairClone:IsA("Model") then
			local primary = (
				hairClone:IsA("Model") and (hairClone.PrimaryPart or hairClone:FindFirstChildOfClass("BasePart"))
			) or hairClone :: BasePart
			if primary then
				primary.Anchored = false
				primary.CanCollide = false
				primary.Massless = true
				hairClone:PivotTo(head.CFrame * CFrame.new(0, 0.45, -0.05))
				local w = Instance.new("WeldConstraint")
				w.Part0 = head
				w.Part1 = primary
				w.Parent = primary
			end
			hairClone.Parent = char
		end
	end

	-- Race-specific accessories (Beerus ears, Angel halo)
	if (charId:find("beerus") or charId:find("champa")) and accFolder then
		local ear = accFolder:FindFirstChild("BeerusAccessory1")
		if ear and ear:IsA("BasePart") then
			local ec = ear:Clone()
			ec.Name = "BeerusEars"
			ec:SetAttribute("AnimeAsset", true)
			ec.Anchored = false
			ec.CanCollide = false
			ec.Massless = true
			ec.CFrame = head.CFrame * CFrame.new(0, 0.5, 0)
			local w = Instance.new("WeldConstraint")
			w.Part0 = head
			w.Part1 = ec
			w.Parent = ec
			ec.Parent = char
		end
	elseif (charId:find("whis") or raceId == "Angel") and accFolder then
		local halo = accFolder:FindFirstChild("WhisAngelHalo")
		if halo and halo:IsA("BasePart") then
			local hc = halo:Clone()
			hc.Name = "AngelHaloRing"
			hc:SetAttribute("AnimeAsset", true)
			hc.Anchored = false
			hc.CanCollide = false
			hc.Massless = true
			local upperTorso = char:FindFirstChild("UpperTorso") :: BasePart? or head
			hc.CFrame = upperTorso.CFrame * CFrame.new(0, 0.8, -0.4)
			local w = Instance.new("WeldConstraint")
			w.Part0 = upperTorso
			w.Part1 = hc
			w.Parent = hc
			hc.Parent = char
		end
	end

	applyFace(char, charId, "Base")
	return true
end

function AvatarSlots.applyForm(char: Model, charId: string?, formId: string)
	if not char or not char.Parent then
		return
	end
	applyFace(char, charId or "", formId)
	local style = FORM_HAIR_STYLES[formId] or FORM_HAIR_STYLES.Base

	-- Update Anime Hair color / material
	local hair = char:FindFirstChild("AnimeHair")
	if hair then
		for _, desc in ipairs(hair:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Color = style.color
				desc.Material = style.material
			end
		end
	end

	-- Frieza race Golden / Black transformations
	if charId == "u7_frieza" or charId == "u6_frost" then
		local bodyColor = if formId == "Golden"
			then Color3.fromRGB(255, 215, 0)
			elseif formId == "FriezaBlack" then Color3.fromRGB(25, 25, 30)
			else SKIN_TONES.FriezaRace
		setSkinColors(char, bodyColor)
	end

	-- Broly Legendary scale up
	if (charId == "u7_broly" or charId == "u6_kale") and formId == "Legendary" then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			setScales(hum, 1.25, 1.35, 1.35, 1.05)
		end
	elseif (charId == "u7_broly" or charId == "u6_kale") and formId == "Base" then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			setScales(hum, 1.15, 1.25, 1.25, 1.05)
		end
	end
end

function AvatarSlots.apply(p: Player, charId: string?): boolean
	if not charId then
		return false
	end
	return AvatarSlots.applyAnimeStyle(p, charId)
end

return AvatarSlots
