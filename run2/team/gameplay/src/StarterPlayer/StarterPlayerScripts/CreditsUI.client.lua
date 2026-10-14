-- LocalScript: in-game Credits screen (button bottom-left of the screen; data from ReplicatedStorage.Shared.Credits)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared:WaitForChild("UIKit"))
local Credits = require(Shared:WaitForChild("Credits"))

local gui = UIKit.gui("Credits", 30)
-- LAYOUT FIX (2026-10-14): was at 1,-40, i.e. drawn on top of the HUD's bottom-left stats panel.
local btn = UIKit.button(gui, "Credits", UDim2.new(0, 90, 0, 30), UDim2.new(0, 10, 1, -356), Color3.fromRGB(40, 40, 70))
btn.TextSize = 14
local panel = UIKit.frame(gui, UDim2.new(0, 720, 0.8, 0), UDim2.new(0.5, -360, 0.1, 0), UIKit.DARK, 0.05)
panel.Name = "CreditsPanel"
panel.Visible = false
UIKit.label(
	panel,
	string.upper(Credits.game) .. " — CREDITS",
	UDim2.new(1, 0, 0, 40),
	UDim2.new(0, 0, 0, 8),
	28,
	UIKit.GOLD
)
local note = UIKit.label(panel, Credits.note, UDim2.new(1, -40, 0, 36), UDim2.new(0, 20, 0, 48), 14)
note.TextWrapped = true
local close = UIKit.button(panel, "X", UDim2.new(0, 36, 0, 36), UDim2.new(1, -44, 0, 8), Color3.fromRGB(120, 40, 40))
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -40, 1, -110)
list.Position = UDim2.new(0, 20, 0, 92)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = list
for i, m in Credits.models do
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = if i % 2 == 0 then 0.85 else 1
	t.BackgroundColor3 = Color3.new(1, 1, 1)
	t.Size = UDim2.new(1, -10, 0, 34)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	t.Font = Enum.Font.Gotham
	t.TextSize = 13
	t.TextColor3 = if m.note ~= "" then Color3.fromRGB(255, 220, 120) else Color3.new(1, 1, 1)
	t.Text = string.format(
		"%s — by %s (%s)%s\n%s",
		m.title,
		m.author,
		m.licence,
		if m.note ~= "" then "  • " .. m.note else "",
		m.url
	)
	t.LayoutOrder = i
	t.Parent = list
end
btn.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
close.Activated:Connect(function()
	panel.Visible = false
end)

-- STATE VISIBILITY (2026-10-14): this element had no state awareness, so it was drawn over the character-select
-- grid and the Intro/Ending cutscenes. It is built with UIKit.button / Instance.new directly rather than through
-- UIStyle.toggle, so the shared nav guard never reached it.
local function syncStateVisibility()
	local s = workspace:GetAttribute("RoundState")
	gui.Enabled = s ~= "Intro" and s ~= "Ending" and s ~= "CharacterSelect"
end
workspace:GetAttributeChangedSignal("RoundState"):Connect(syncStateVisibility)
syncStateVisibility()
