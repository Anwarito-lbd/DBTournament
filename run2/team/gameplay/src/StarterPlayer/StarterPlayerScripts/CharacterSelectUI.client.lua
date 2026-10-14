--!strict
-- LocalScript: StarterPlayerScripts.CharacterSelectUI (WP08)
-- Character selection with interactive 3D ViewportFrame preview, tier tags, universe filter, and gamepad/mobile support.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local Races = require(Shared:WaitForChild("Races"))

local player = Players.LocalPlayer

-- ============================================================================
-- CARD STATS (2026-10-14)
-- Champions are declared as c(id, name, basePL, unlockLevel, forms), so there is no per-champion
-- damage/defense/speed in Config. The real differentiation lives in Races: every race carries
-- stats = { damage, defense, speed, kiRegen } multipliers plus traits. Those are what actually flow through
-- StatResolver, so they are the honest numbers to show on a card. Previously every card read only
-- "PL 1000", which made the whole roster look identical.
-- ============================================================================
local STAT_FLOOR, STAT_CEIL = 0.9, 1.2
local function statFrac(v: number?): number
	local n = v or 1
	return math.clamp((n - STAT_FLOOR) / (STAT_CEIL - STAT_FLOOR), 0, 1)
end

-- Small labelled 3-segment bar: value 0..1
local function statBar(parent: Instance, label: string, frac: number, y: number, color: Color3)
	local row =
		UIKit.label(parent, label, UDim2.fromOffset(30, 12), UDim2.new(0, 6, 0, y), 10, Color3.fromRGB(155, 170, 200))
	row.ZIndex = 2
	row.TextXAlignment = Enum.TextXAlignment.Left
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -44, 0, 5)
	track.Position = UDim2.new(0, 38, 0, y + 4)
	track.BackgroundColor3 = Color3.fromRGB(38, 44, 70)
	track.BorderSizePixel = 0
	track.ZIndex = 2
	track.Parent = parent
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = track
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(frac, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.ZIndex = 3
	fill.Parent = track
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill
end

local TIER_COLORS = {
	C = Color3.fromRGB(130, 135, 150),
	B = Color3.fromRGB(60, 150, 240),
	A = Color3.fromRGB(160, 80, 240),
	S = Color3.fromRGB(245, 185, 40),
	GoD = Color3.fromRGB(210, 60, 210),
	Angel = Color3.fromRGB(90, 210, 255),
	GrandPriest = Color3.fromRGB(130, 230, 255),
	Zeno = Color3.fromRGB(255, 255, 255),
}

local UNIVERSE_ORDER = { 7, 11, 6, 2, 3, 4, 9, 10 }

local gui: ScreenGui? = nil
local status: TextLabel? = nil
local buttons: { [string]: ImageButton } = {}
local previewViewport: ViewportFrame? = nil
local previewModel: Model? = nil
local previewCamera: Camera? = nil
local selectedCharId: string? = nil
local previewTitle: TextLabel? = nil
local previewSub: TextLabel? = nil
local previewTierBadge: TextLabel? = nil
local selectBtn: TextButton? = nil

local function champions()
	local list = {}
	for _, u in UNIVERSE_ORDER do
		for _, ch in Config.ROSTER[u] or {} do
			table.insert(list, ch)
		end
	end
	for _, dv in Config.DIVINE do
		local ch = Config.CHAR_BY_ID[dv.id]
		if ch then
			table.insert(list, ch)
		end
	end
	return list
end

local function unlocked(ch: any): boolean
	if workspace:GetAttribute("DevMode") or RunService:IsStudio() then
		return true
	end
	local lvl = player:GetAttribute("Level") or 1
	local prest = player:GetAttribute("Prestige") or 0
	if ch.tier then
		local dt = Config.DIVINE_TIERS[ch.tier]
		if not dt then
			return false
		end
		return lvl >= (dt.req.level or 1) or prest >= (dt.req.prestige or 1)
	end
	return lvl >= (ch.level or 1)
end

local function cleanPreview()
	if previewModel then
		previewModel:Destroy()
		previewModel = nil
	end
end

local function updatePreview(charId: string)
	selectedCharId = charId
	local ch = Config.CHAR_BY_ID[charId]
	if not ch or not previewViewport then
		return
	end

	cleanPreview()

	local tier = Config.tierOf(ch)
	local tierCol = TIER_COLORS[tier] or Color3.fromRGB(180, 180, 180)

	if previewTitle then
		previewTitle.Text = ch.name:upper()
	end
	if previewTierBadge then
		previewTierBadge.Text = "TIER " .. tier
		previewTierBadge.TextColor3 = tierCol
		local stroke = previewTierBadge:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = tierCol
		end
	end
	if previewSub then
		local unl = unlocked(ch)
		previewSub.Text = string.format(
			"Base Power Level: %s  •  %s",
			ch.base or 1000,
			if unl then "UNLOCKED" else "LOCKED (Lv " .. (ch.level or 1) .. ")"
		)
		previewSub.TextColor3 = if unl then Color3.fromRGB(160, 240, 180) else Color3.fromRGB(240, 110, 110)
	end

	-- Look for model in ReplicatedStorage.CharacterModels
	local charModels = ReplicatedStorage:FindFirstChild("CharacterModels")
	local source = charModels and charModels:FindFirstChild(charId)
	if not source and charModels then
		-- Fallback to goku or vegeta model template
		source = charModels:FindFirstChild("u7_goku")
	end

	if source and source:IsA("Model") then
		local clone = source:Clone()
		clone.Name = "PreviewTarget"

		-- Center and frame the model
		local _cf, size = clone:GetBoundingBox()
		local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
		if not root then
			root = clone:FindFirstChildWhichIsA("BasePart")
		end

		if root then
			clone:PivotTo(CFrame.new(0, 0, 0))
		end

		clone.Parent = previewViewport
		previewModel = clone

		if previewCamera then
			local maxDim = math.max(size.X, size.Y, size.Z)
			local dist = math.clamp(maxDim * 1.8, 6, 18)
			previewCamera.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * 0.1, dist), Vector3.new(0, size.Y * 0.05, 0))
		end
	end
end

local function refresh()
	if not gui then
		return
	end
	local picks = {}
	local team = player.Team
	for id in string.gmatch(team and team:GetAttribute("Picks") or "", "[^,]+") do
		picks[id] = true
	end
	local mine = player:GetAttribute("Character")

	for id, b in buttons do
		local stroke = b:FindFirstChildOfClass("UIStroke") :: UIStroke
		if stroke then
			stroke.Thickness = if id == mine then 4 elseif id == selectedCharId then 2.5 else 0
			stroke.Color = if id == mine then UIKit.GOLD else Color3.fromRGB(140, 190, 255)
		end
		local ch = Config.CHAR_BY_ID[id]
		local isPickedByOther = picks[id] and id ~= mine
		b.BackgroundTransparency = if not unlocked(ch) or isPickedByOther then 0.65 else 0.15
	end

	if team and status then
		status.Text = string.format(
			"%s  •  Budget %d/%d  •  Your pick: %s  •  %ds left",
			team.Name,
			team:GetAttribute("BudgetUsed") or 0,
			team:GetAttribute("Budget") or 0,
			mine and (Config.CHAR_BY_ID[mine] and Config.CHAR_BY_ID[mine].name or mine) or "-",
			workspace:GetAttribute("TimeLeft") or 0
		)
	end
end

local function hide()
	cleanPreview()
	if gui then
		gui:Destroy()
		gui = nil
	end
	table.clear(buttons)
end

local function show()
	if gui then
		return
	end
	local g = UIKit.gui("CharacterSelect", 10)
	gui = g

	local panel = UIKit.frame(g, UDim2.fromScale(0.88, 0.82), UDim2.fromScale(0.06, 0.09), UIKit.DARK, 0.15)
	local pStroke = Instance.new("UIStroke")
	pStroke.Color = UIKit.GOLD
	pStroke.Thickness = 2.5
	pStroke.Parent = panel

	UIKit.label(panel, "SELECT YOUR WARRIOR", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 8), 28, UIKit.GOLD)
	status = UIKit.label(panel, "", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 48), 15)

	-- Left: Character Roster Grid
	local sc = Instance.new("ScrollingFrame")
	sc.Size = UDim2.new(0.62, -15, 1, -85)
	sc.Position = UDim2.fromOffset(15, 75)
	sc.BackgroundTransparency = 1
	sc.BorderSizePixel = 0
	sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sc.CanvasSize = UDim2.new()
	sc.ScrollBarThickness = 6
	sc.ScrollBarImageColor3 = UIKit.GOLD
	sc.Parent = panel

	local grid = Instance.new("UIGridLayout")
	-- Taller cards so each one can carry a race line and DMG/DEF/SPD bars (was 148x76).
	grid.CellSize = UDim2.fromOffset(152, 118)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = sc

	-- Right: 3D Preview Frame
	local previewContainer =
		UIKit.frame(panel, UDim2.new(0.38, -25, 1, -85), UDim2.new(0.62, 10, 0, 75), Color3.fromRGB(16, 18, 38), 0.2)
	local prevStroke = Instance.new("UIStroke")
	prevStroke.Color = Color3.fromRGB(80, 95, 140)
	prevStroke.Thickness = 1.5
	prevStroke.Parent = previewContainer

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Character3DPreview"
	vp.Size = UDim2.new(1, -20, 0.58, 0)
	vp.Position = UDim2.fromOffset(10, 10)
	vp.BackgroundTransparency = 1
	vp.LightColor = Color3.fromRGB(255, 245, 230)
	vp.LightDirection = Vector3.new(-1, -1.5, -2)
	vp.Ambient = Color3.fromRGB(140, 150, 180)
	vp.Parent = previewContainer
	previewViewport = vp

	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	cam.Parent = vp
	vp.CurrentCamera = cam
	previewCamera = cam

	previewTitle =
		UIKit.label(previewContainer, "GOKU", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0.60, 0), 22, UIKit.GOLD)
	previewTitle.TextXAlignment = Enum.TextXAlignment.Center

	previewTierBadge =
		UIKit.label(previewContainer, "TIER S", UDim2.fromOffset(90, 22), UDim2.new(0.5, -45, 0.68, 0), 13, UIKit.GOLD)
	local tStroke = Instance.new("UIStroke")
	tStroke.Color = UIKit.GOLD
	tStroke.Thickness = 1.5
	tStroke.Parent = previewTierBadge

	previewSub = UIKit.label(
		previewContainer,
		"Base Power Level: 1000",
		UDim2.new(1, -20, 0, 22),
		UDim2.new(0, 10, 0.76, 0),
		13,
		Color3.new(1, 1, 1)
	)
	previewSub.TextXAlignment = Enum.TextXAlignment.Center

	selectBtn = UIKit.button(
		previewContainer,
		"CONFIRM PICK",
		UDim2.new(1, -30, 0, 38),
		UDim2.new(0, 15, 0.88, 0),
		Color3.fromRGB(50, 160, 80)
	)
	selectBtn.Activated:Connect(function()
		if selectedCharId then
			local ch = Config.CHAR_BY_ID[selectedCharId]
			if ch and not unlocked(ch) then
				if status then
					status.Text = ch.name .. " is locked (Requires Level " .. (ch.level or 1) .. ")"
				end
				return
			end
			ClientAPI.pickCharacter(selectedCharId)
		end
	end)

	local firstCharId: string? = nil
	for i, ch in ipairs(champions()) do
		if not firstCharId then
			firstCharId = ch.id
		end
		local tier = Config.tierOf(ch)
		local b = Instance.new("ImageButton")
		b.Name = ch.id
		b.LayoutOrder = i
		b.BackgroundColor3 = Color3.fromRGB(24, 28, 54)
		b.BackgroundTransparency = 0.15
		b.BorderSizePixel = 0
		b.Parent = sc

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = b

		local s = Instance.new("UIStroke")
		s.Color = UIKit.GOLD
		s.Thickness = 0
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = b

		local tierCol = TIER_COLORS[tier] or Color3.fromRGB(150, 150, 150)

		-- Tier accent stripe down the left edge. Gives each card a "character card" read without needing
		-- portrait art we do not have yet.
		local accent = Instance.new("Frame")
		accent.Name = "TierAccent"
		accent.Size = UDim2.new(0, 4, 1, 0)
		accent.BackgroundColor3 = tierCol
		accent.BorderSizePixel = 0
		accent.ZIndex = 2
		accent.Parent = b
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(0, 8)
		ac.Parent = accent

		local nm = UIKit.label(b, ch.name, UDim2.new(1, -34, 0, 22), UDim2.fromOffset(12, 4), 15)
		nm.ZIndex = 3
		nm.TextXAlignment = Enum.TextXAlignment.Left

		local tierLabel = UIKit.label(b, tier, UDim2.fromOffset(26, 18), UDim2.new(1, -32, 0, 6), 12, tierCol)
		tierLabel.ZIndex = 3

		-- Race + power level, then the three real stat multipliers that flow through StatResolver.
		local race = Races.get(ch.id)
		local lockTxt = if unlocked(ch) then "" else ("  Lv " .. tostring(ch.level))
		local sub = UIKit.label(
			b,
			string.format("PL %d  •  %s%s", ch.base, race and race.name or "?", lockTxt),
			UDim2.new(1, -14, 0, 16),
			UDim2.fromOffset(12, 28),
			11,
			Color3.fromRGB(180, 195, 220)
		)
		sub.ZIndex = 3
		sub.TextXAlignment = Enum.TextXAlignment.Left

		local st = race and race.stats
		statBar(b, "DMG", statFrac(st and st.damage), 50, Color3.fromRGB(255, 110, 90))
		statBar(b, "DEF", statFrac(st and st.defense), 68, Color3.fromRGB(110, 190, 255))
		statBar(b, "SPD", statFrac(st and st.speed), 86, Color3.fromRGB(120, 230, 150))

		b.Activated:Connect(function()
			updatePreview(ch.id)
			refresh()
		end)

		buttons[ch.id] = b
	end

	-- Viewport Turntable Spin Animation
	local angle = 0
	local spinConn: RBXScriptConnection? = nil
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if not gui or not previewViewport then
			if spinConn then
				spinConn:Disconnect()
			end
			return
		end
		if previewModel and previewModel.PrimaryPart then
			angle += dt * 35
			previewModel:SetPrimaryPartCFrame(CFrame.Angles(0, math.rad(angle), 0))
		end
	end)

	if firstCharId then
		updatePreview(firstCharId)
	end
	refresh()
end

ClientAPI.onPickResult:Connect(function(ok, charId, reason)
	if not ok and status then
		local ch = Config.CHAR_BY_ID[charId]
		status.Text = string.format("Can't pick %s: %s", ch and ch.name or tostring(charId), tostring(reason))
	else
		refresh()
	end
end)

ClientAPI.onRoundState:Connect(function(state)
	if state == "CharacterSelect" then
		show()
		refresh()
	elseif state ~= "CharacterSelect" then
		hide()
	end
end)

player:GetAttributeChangedSignal("Character"):Connect(refresh)
workspace:GetAttributeChangedSignal("TimeLeft"):Connect(refresh)

if workspace:GetAttribute("RoundState") == "CharacterSelect" then
	show()
end
