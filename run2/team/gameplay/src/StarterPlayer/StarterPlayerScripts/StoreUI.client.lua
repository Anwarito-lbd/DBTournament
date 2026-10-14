-- LocalScript (v1.2): Capsule Corp. Store. Opens from the "Store" button (bottom-left) or the ProximityPrompt at the
-- Shop counter. Tabs: Characters / Forms / Cosmetics / Boosts / Items. Each card: Zeni price, Robux button (disabled
-- while the product id is a placeholder), Equip for owned cosmetics. Server validates everything (Modules.Store).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared:WaitForChild("UIKit"))
local Catalog = require(Shared:WaitForChild("StoreCatalog"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Req = Remotes:WaitForChild("StoreRequest") :: RemoteEvent
local Res = Remotes:WaitForChild("StoreResult") :: RemoteEvent
local player = Players.LocalPlayer

local gui = UIKit.gui("StoreUI", 20)
local openBtn =
	-- LAYOUT FIX (2026-10-14): was at 1,-76, which put it inside the HUD's bottom-left stats panel
	-- (300x168 at 12,-180 spans the whole bottom-left corner), so "Store" was drawn over the Zeni/XP rows.
	UIKit.button(gui, "Store", UDim2.new(0, 90, 0, 30), UDim2.new(0, 10, 1, -392), Color3.fromRGB(30, 90, 200))
local panel = UIKit.frame(gui, UDim2.new(0, 860, 0, 520), UDim2.new(0.5, -430, 0.5, -260), UIKit.DARK, 0.04)
panel.Visible = false
local title = UIKit.label(
	panel,
	"CAPSULE CORP.  STORE",
	UDim2.new(1, 0, 0, 40),
	UDim2.new(0, 0, 0, 8),
	28,
	Color3.fromRGB(110, 190, 255)
)
local zeniL = UIKit.label(panel, "", UDim2.new(0, 300, 0, 26), UDim2.new(1, -320, 0, 14), 18, UIKit.GOLD)
zeniL.TextXAlignment = Enum.TextXAlignment.Right
local close = UIKit.button(panel, "X", UDim2.new(0, 32, 0, 32), UDim2.new(1, -40, 0, -36), Color3.fromRGB(150, 30, 40))
close.Position = UDim2.new(1, -40, 0, 10)
local msg = UIKit.label(panel, "", UDim2.new(1, -40, 0, 24), UDim2.new(0, 20, 1, -30), 16, Color3.new(1, 1, 1))
local tabs = Instance.new("Frame")
tabs.BackgroundTransparency = 1
tabs.Size = UDim2.new(1, -40, 0, 34)
tabs.Position = UDim2.new(0, 20, 0, 52)
tabs.Parent = panel
local grid = Instance.new("ScrollingFrame")
grid.BackgroundTransparency = 1
grid.Size = UDim2.new(1, -40, 1, -130)
grid.Position = UDim2.new(0, 20, 0, 94)
grid.ScrollBarThickness = 6
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.CanvasSize = UDim2.new()
grid.BorderSizePixel = 0
grid.Parent = panel
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0, 255, 0, 120)
layout.CellPadding = UDim2.new(0, 12, 0, 12)
layout.Parent = grid
zeniL.Position = UDim2.new(1, -360, 0, 14)

local current = "Characters"
local tabBtns = {}
local CAT_COL = {
	Characters = Color3.fromRGB(220, 120, 40),
	Forms = Color3.fromRGB(230, 190, 40),
	Cosmetics = Color3.fromRGB(170, 90, 230),
	Boosts = Color3.fromRGB(60, 170, 90),
	Items = Color3.fromRGB(60, 140, 220),
}

local function ownedSet(): { [string]: boolean }
	local s = {}
	for id in string.gmatch((player:GetAttribute("StoreOwned") :: string?) or "", "[^,]+") do
		s[id] = true
	end
	return s
end
local function robuxId(it): number
	if not it.robux then
		return -1
	end
	local gp = Config.GAMEPASSES[it.robux]
	if gp then
		return gp.id
	end
	local pd = Config.PRODUCTS[it.robux]
	if pd then
		return pd.id
	end
	return -1
end
local function render()
	for _, c in grid:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for cat, b in tabBtns do
		b.BackgroundColor3 = if cat == current then CAT_COL[cat] else Color3.fromRGB(40, 44, 70)
	end
	local own = ownedSet()
	local zeni = (player:GetAttribute("Zeni") :: number?) or 0
	zeniL.Text = ("Zeni  %d"):format(zeni)
	for _, it in Catalog.ITEMS do
		if it.cat == current then
			local card = UIKit.frame(grid, UDim2.new(0, 255, 0, 120), UDim2.new(), Color3.fromRGB(28, 32, 58), 0)
			local bar = UIKit.frame(card, UDim2.new(0, 6, 1, 0), UDim2.new(), CAT_COL[current], 0)
			_ = bar
			local n =
				UIKit.label(card, it.name, UDim2.new(1, -20, 0, 40), UDim2.new(0, 14, 0, 4), 16, Color3.new(1, 1, 1))
			n.TextWrapped = true
			n.TextXAlignment = Enum.TextXAlignment.Left
			local isOwned = own[it.id] == true
			local equippedAura, equippedOutfit = player:GetAttribute("Aura"), player:GetAttribute("Cosmetic")
			if isOwned and (it.kind == "aura" or it.kind == "outfit") then
				local on = (it.id == equippedAura or it.id == equippedOutfit)
				local eb = UIKit.button(
					card,
					if on then "Equipped (tap to remove)" else "Equip",
					UDim2.new(1, -28, 0, 30),
					UDim2.new(0, 14, 0, 50),
					if on then Color3.fromRGB(60, 150, 80) else Color3.fromRGB(70, 80, 130)
				)
				eb.MouseButton1Click:Connect(function()
					Req:FireServer("Equip", it.id)
				end)
			elseif
				Catalog.lockedFor
				and (
					Catalog.lockedFor(it, {
						level = player:GetAttribute("Level") or 1,
						prestige = player:GetAttribute("Prestige") or 0,
						training = { whisStage = player:GetAttribute("WhisStage") or 0 },
					})
				)
			then -- v8 (lead-authorized): level-gated item
				local _, why = Catalog.lockedFor(it, {
					level = player:GetAttribute("Level") or 1,
					prestige = player:GetAttribute("Prestige") or 0,
					training = { whisStage = player:GetAttribute("WhisStage") or 0 },
				})
				UIKit.label(
					card,
					"LOCKED - " .. tostring(why),
					UDim2.new(1, -28, 0, 44),
					UDim2.new(0, 14, 0, 46),
					13,
					Color3.fromRGB(255, 120, 120)
				)
			elseif isOwned then
				UIKit.label(
					card,
					"OWNED",
					UDim2.new(1, -28, 0, 30),
					UDim2.new(0, 14, 0, 50),
					18,
					Color3.fromRGB(120, 230, 140)
				)
			else
				local zb = UIKit.button(
					card,
					("%d Zeni"):format(it.zeni),
					UDim2.new(0.5, -18, 0, 30),
					UDim2.new(0, 14, 0, 50),
					if zeni >= it.zeni then UIKit.GOLD else Color3.fromRGB(90, 80, 50)
				)
				zb.TextColor3 = Color3.fromRGB(20, 20, 20)
				zb.MouseButton1Click:Connect(function()
					Req:FireServer("BuyZeni", it.id)
				end)
				local rid = robuxId(it)
				if rid >= 0 then
					local rb = UIKit.button(
						card,
						if rid == 0 then "R$ (soon)" else "R$ Buy",
						UDim2.new(0.5, -18, 0, 30),
						UDim2.new(0.5, 4, 0, 50),
						if rid == 0 then Color3.fromRGB(60, 60, 70) else Color3.fromRGB(40, 170, 80)
					)
					rb.MouseButton1Click:Connect(function()
						Req:FireServer("BuyRobux", it.id)
					end)
				end
			end
			local kindTxt = ({
				unlock = "Permanent unlock",
				aura = "Cosmetic aura",
				outfit = "Cosmetic outfit",
				xpboost = "Time-saver",
				drink = "In-match item (1 per match)",
				stat = "Stat boost - capped, off in Ranked",
			})[it.kind] or ""
			local k = UIKit.label(
				card,
				kindTxt,
				UDim2.new(1, -20, 0, 20),
				UDim2.new(0, 14, 0, 90),
				13,
				Color3.fromRGB(170, 180, 210)
			)
			k.TextXAlignment = Enum.TextXAlignment.Left
		end
	end
end
for i, cat in Catalog.CATS do
	local b =
		UIKit.button(tabs, cat, UDim2.new(0, 150, 1, 0), UDim2.new(0, (i - 1) * 160, 0, 0), Color3.fromRGB(40, 44, 70))
	tabBtns[cat] = b
	b.MouseButton1Click:Connect(function()
		current = cat
		render()
	end)
end
local function setOpen(v: boolean)
	-- FTUE (2026-10-14): the Capsule Corp store was opening over the onboarding screen. Every open path (the Store
	-- nav button, the StorePrompt proximity prompt, and the dev BindableFunction) funnels through here.
	if v and player:GetAttribute("InTutorial") == true then
		return
	end
	panel.Visible = v
	if v then
		render()
	end
end
openBtn.MouseButton1Click:Connect(function()
	setOpen(not panel.Visible)
end)
close.MouseButton1Click:Connect(function()
	setOpen(false)
end)
ProximityPromptService.PromptTriggered:Connect(function(pp)
	if pp.Name == "StorePrompt" then
		setOpen(true)
	end
end)
Res.OnClientEvent:Connect(function(ok, id, text)
	msg.Text = text or ""
	msg.TextColor3 = if ok then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(255, 120, 120)
	task.delay(0.1, function()
		if panel.Visible then
			render()
		end
	end)
end)
for _, a in { "Zeni", "StoreOwned", "Aura", "Cosmetic" } do
	player:GetAttributeChangedSignal(a):Connect(function()
		if panel.Visible then
			render()
		end
	end)
end
-- dev/test hook
local bf = Instance.new("BindableFunction")
bf.Name = "StoreTest"
bf.Parent = script
bf.OnInvoke = function(cmd, arg)
	if cmd == "open" then
		setOpen(true)
		if arg then
			current = arg
			render()
		end
	elseif cmd == "close" then
		setOpen(false)
	end
	return msg.Text
end

-- STATE VISIBILITY (2026-10-14): this element had no state awareness, so it was drawn over the character-select
-- grid and the Intro/Ending cutscenes. It is built with UIKit.button / Instance.new directly rather than through
-- UIStyle.toggle, so the shared nav guard never reached it.
local function syncStateVisibility()
	local s = workspace:GetAttribute("RoundState")
	gui.Enabled = s ~= "Intro" and s ~= "Ending" and s ~= "CharacterSelect"
end
workspace:GetAttributeChangedSignal("RoundState"):Connect(syncStateVisibility)
syncStateVisibility()
