--!strict
-- LocalScript: StarterPlayer.StarterPlayerScripts.LevelUpCelebration
--
-- WHY: the server has always sent the unlock list with a level-up -
-- `LevelUpRemote:FireClient(p, level, unlocks)` in RoundManager - but the only consumer was
-- `HUD.client.lua`, which took just `level` and pushed one gold line of text into the right-hand elimination
-- feed. So a brand new player reaching KaioKen mid-match-1 was told about their very first transformation by a
-- small text line competing with elimination spam.
--
-- The ramp itself is well tuned and does not need changing: 1 -> 5 costs 383 XP, the Whis tutorial awards
-- 250 XP (landing a new player at level 3), and KaioKen at level 5 is therefore only ~133 XP away - roughly
-- their first finished match. `Config.XP_PARTICIPATION` 50 + `XP_WIN` 100 + `XP_KO` 15 each. The reward timing
-- is right; the celebration was the missing half.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local AudioRegistry = require(Shared:WaitForChild("AudioRegistry"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer

local gui = UIKit.gui("LevelUpCelebration", 60)

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.42)
card.Size = UDim2.fromOffset(420, 132)
card.BackgroundColor3 = UIKit.DARK
card.BackgroundTransparency = 0.08
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
local cardScale = Instance.new("UIScale")
cardScale.Parent = card

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = UIKit.GOLD
stroke.Thickness = 3
stroke.Parent = card

local title = UIKit.label(card, "LEVEL UP", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 10), 18, UIKit.GOLD)
title.TextXAlignment = Enum.TextXAlignment.Center

local levelText = UIKit.label(card, "LEVEL 2", UDim2.new(1, 0, 0, 46), UDim2.fromOffset(0, 34), 40, Color3.new(1, 1, 1))
levelText.TextXAlignment = Enum.TextXAlignment.Center
levelText.Font = Enum.Font.GothamBlack

local unlockText =
	UIKit.label(card, "", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 86), 16, Color3.fromRGB(255, 200, 60))
unlockText.TextXAlignment = Enum.TextXAlignment.Center

-- "UltraInstinctSign" -> "Ultra Instinct Sign"
local function prettify(id: string): string
	local spaced = string.gsub(id, "(%u)", " %1")
	return string.upper(string.gsub(spaced, "^%s+", ""))
end

local hideAt = 0
local showing = false

local function show(level: number, unlocks: { string }?)
	levelText.Text = "LEVEL " .. tostring(level)
	if unlocks and #unlocks > 0 then
		local names = {}
		for _, id in ipairs(unlocks) do
			table.insert(names, prettify(id))
		end
		unlockText.Text = table.concat(names, "  •  ") .. "  UNLOCKED"
	else
		unlockText.Text = ""
	end

	hideAt = os.clock() + 2.6
	gui.Enabled = true

	if showing then
		-- Rapid levels (the tutorial can award three at once): upgrade the card in place rather than replaying.
		return
	end
	showing = true
	card.Visible = true
	cardScale.Scale = 0.7
	TweenService:Create(cardScale, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	local owner = player.Character or workspace
	AudioRegistry.play("MenuSelect", owner, 1)
	AudioRegistry.play("AuraBurst", owner, 0.5)
end

ClientAPI.onLevelUp:Connect(function(level: number, unlocks: any)
	show(level, if type(unlocks) == "table" then unlocks else nil)
end)

-- Fade + reset once the hold expires.
task.spawn(function()
	while true do
		task.wait(0.1)
		if showing and os.clock() >= hideAt then
			showing = false
			local fade = TweenService:Create(cardScale, TweenInfo.new(0.3), { Scale = 0.85 })
			fade:Play()
			fade.Completed:Wait()
			card.Visible = false
			cardScale.Scale = 1
		end
	end
end)
