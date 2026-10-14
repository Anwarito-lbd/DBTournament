--!strict
-- LocalScript: StarterPlayer.StarterPlayerScripts.DivineFavorUI
-- Celebratory jackpot modal for the Variable-Ratio "Divine Favor" reward schedule.
-- Displays Zeno excitement animations, golden jackpot banners, and near-miss teasers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FavorRemote = Remotes:WaitForChild("DivineFavorEvent") :: RemoteEvent
local _player = Players.LocalPlayer

local gui = S.gui("DivineFavorUI", 26)

-- Modal Frame
local modal = Instance.new("Frame")
modal.Size = UDim2.fromScale(0.42, 0.44)
modal.Position = UDim2.fromScale(0.29, 0.28)
modal.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
modal.BackgroundTransparency = 0.1
modal.BorderSizePixel = 0
modal.Visible = false
modal.Parent = gui
S.corner(modal, 16)
S.stroke(modal, S.GOLD, 3)

local _header =
	S.label(modal, "DIVINE FAVOR!", UDim2.fromScale(0.9, 0.18), UDim2.fromScale(0.05, 0.05), S.GOLD, S.FONT_TITLE)

local _zenoQuote = S.label(
	modal,
	'"Sugoi! Lord Zeno is thoroughly entertained!"',
	UDim2.fromScale(0.9, 0.14),
	UDim2.fromScale(0.05, 0.22),
	Color3.fromRGB(255, 230, 140),
	S.FONT_BODY
)

local rewardCard = Instance.new("Frame")
rewardCard.Size = UDim2.fromScale(0.86, 0.32)
rewardCard.Position = UDim2.fromScale(0.07, 0.38)
rewardCard.BackgroundColor3 = Color3.fromRGB(25, 32, 45)
rewardCard.BorderSizePixel = 0
rewardCard.Parent = modal
S.corner(rewardCard, 10)
S.stroke(rewardCard, S.GREEN, 2)

local rewardName = S.label(
	rewardCard,
	"",
	UDim2.fromScale(0.9, 0.45),
	UDim2.fromScale(0.05, 0.1),
	Color3.fromRGB(255, 255, 255),
	S.FONT_TITLE
)
local rewardDetails =
	S.label(rewardCard, "", UDim2.fromScale(0.9, 0.35), UDim2.fromScale(0.05, 0.55), S.GOLD, S.FONT_BODY)

-- Near Miss Teaser Banner
local teaser = S.label(
	modal,
	"",
	UDim2.fromScale(0.9, 0.12),
	UDim2.fromScale(0.05, 0.72),
	Color3.fromRGB(255, 120, 120),
	S.FONT_BODY
)

local _claimBtn = S.button(
	modal,
	"CLAIM REWARD",
	UDim2.fromScale(0.5, 0.12),
	UDim2.fromScale(0.25, 0.85),
	S.GREEN,
	function()
		modal.Visible = false
	end
)

local function displayFavor(payload: any)
	local r = payload.reward
	modal.Visible = true

	rewardName.Text = r.name
	local lines = {}
	if r.zeni then
		table.insert(lines, string.format("+%d Zeni", r.zeni))
	end
	if r.xp then
		table.insert(lines, string.format("+%d Bonus XP", r.xp))
	end
	if r.title then
		table.insert(lines, string.format('Title: "%s"', r.title))
	end
	rewardDetails.Text = table.concat(lines, "  |  ")

	if payload.nearMiss and payload.nextForm then
		teaser.Text = string.format("⚡ ONLY 1 MATCH AWAY FROM UNLOCKING %s!", string.upper(payload.nextForm))
		teaser.Visible = true
	else
		teaser.Visible = false
	end

	-- Card pop bounce animation
	modal.Position = UDim2.fromScale(0.29, 0.22)
	TweenService:Create(modal, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.29, 0.28),
	}):Play()
end

FavorRemote.OnClientEvent:Connect(function(payload)
	displayFavor(payload)
end)
