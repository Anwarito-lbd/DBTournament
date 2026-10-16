--!strict
-- LocalScript (WP23 & v10, db-gameplay): Tournament of Power Announcer, Divine Subtitles & Banners.
-- Subtitle bar for Grand Priest, Lord Zeno, and Bulma cheers with styled speaker badges.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
local ToPLogic = require(Shared:WaitForChild("ToPLogic"))

local player = Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

local gui = S.gui("ToPAnnouncer", 18)

-- ===== Top Banner (Super Shenron / Last Stand) =====
local banner =
	S.label(gui, "", UDim2.fromScale(0.7, 0.08), UDim2.fromScale(0.15, 0.2), Color3.new(1, 1, 1), S.FONT_TITLE)
banner.TextStrokeTransparency = 0
banner.TextTransparency = 1
local bannerConstraint = banner:FindFirstChildOfClass("UITextSizeConstraint")
if bannerConstraint then
	bannerConstraint.MaxTextSize = 44
end
local sub = S.label(gui, "", UDim2.fromScale(0.6, 0.04), UDim2.fromScale(0.2, 0.28), S.MUTED)
sub.TextTransparency = 1

local function showBanner(text: string, small: string?, color: Color3?, secs: number?)
	banner.Text = text
	banner.TextColor3 = color or S.GOLD
	sub.Text = small or ""
	banner.TextTransparency = 0
	sub.TextTransparency = 0
	local sc = banner:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	sc.Parent = banner
	sc.Scale = 1.4
	TweenService:Create(sc, S.POP, { Scale = 1 }):Play()
	task.delay(secs or 3, function()
		if banner.Text == text then
			TweenService:Create(banner, S.FAST, { TextTransparency = 1 }):Play()
			TweenService:Create(sub, S.FAST, { TextTransparency = 1 }):Play()
		end
	end)
end

-- ===== Bottom-Center Dialogue & Subtitle Bar (WP23) =====
local subContainer = Instance.new("Frame")
subContainer.Name = "SubtitleContainer"
subContainer.AnchorPoint = Vector2.new(0.5, 1)
subContainer.Position = UDim2.new(0.5, 0, 1, -110) -- Above hotbar/controls
subContainer.Size = UDim2.fromOffset(560, 68)
subContainer.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
subContainer.BackgroundTransparency = 0.25
subContainer.BorderSizePixel = 0
subContainer.Visible = false
subContainer.Parent = gui

local subCorner = Instance.new("UICorner")
subCorner.CornerRadius = UDim.new(0, 10)
subCorner.Parent = subContainer

local subStroke = Instance.new("UIStroke")
subStroke.Thickness = 1.5
subStroke.Color = Color3.fromRGB(120, 180, 255)
subStroke.Transparency = 0.3
subStroke.Parent = subContainer

-- Speaker Badge Pill
local badge = Instance.new("Frame")
badge.Name = "SpeakerBadge"
badge.AnchorPoint = Vector2.new(0, 0)
badge.Position = UDim2.new(0, 12, 0, 8)
badge.Size = UDim2.fromOffset(130, 22)
badge.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
badge.BorderSizePixel = 0
badge.Parent = subContainer

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 6)
badgeCorner.Parent = badge

local badgeText = Instance.new("TextLabel")
badgeText.Name = "Label"
badgeText.Size = UDim2.fromScale(1, 1)
badgeText.BackgroundTransparency = 1
badgeText.Font = Enum.Font.GothamBold
badgeText.TextSize = 11
badgeText.TextColor3 = Color3.fromRGB(160, 220, 255)
badgeText.Text = "GRAND PRIEST"
badgeText.Parent = badge

-- Spoken Text Label
local dialogueLabel = Instance.new("TextLabel")
dialogueLabel.Name = "DialogueLabel"
dialogueLabel.AnchorPoint = Vector2.new(0, 0)
dialogueLabel.Position = UDim2.new(0, 14, 0, 32)
dialogueLabel.Size = UDim2.new(1, -28, 0, 30)
dialogueLabel.BackgroundTransparency = 1
dialogueLabel.Font = Enum.Font.GothamMedium
dialogueLabel.TextSize = 13
dialogueLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
dialogueLabel.TextXAlignment = Enum.TextXAlignment.Left
dialogueLabel.TextYAlignment = Enum.TextYAlignment.Top
dialogueLabel.TextWrapped = true
dialogueLabel.Text = ""
dialogueLabel.Parent = subContainer

local activeToken = 0

local SPEAKER_STYLES = {
	GrandPriest = {
		Name = "✦ GRAND PRIEST",
		BadgeBg = Color3.fromRGB(20, 35, 55),
		BadgeColor = Color3.fromRGB(150, 220, 255),
		BorderColor = Color3.fromRGB(100, 180, 255),
	},
	Zeno = {
		Name = "👑 LORD ZENO",
		BadgeBg = Color3.fromRGB(50, 40, 15),
		BadgeColor = Color3.fromRGB(255, 215, 80),
		BorderColor = Color3.fromRGB(240, 190, 50),
	},
	Bulma = {
		Name = "📢 BULMA (STANDS)",
		BadgeBg = Color3.fromRGB(15, 45, 45),
		BadgeColor = Color3.fromRGB(80, 230, 255),
		BorderColor = Color3.fromRGB(60, 200, 220),
	},
}

local function showSubtitle(speaker: string, text: string, duration: number?)
	local style = SPEAKER_STYLES[speaker] or SPEAKER_STYLES.GrandPriest
	badgeText.Text = style.Name
	badge.BackgroundColor3 = style.BadgeBg
	badgeText.TextColor3 = style.BadgeColor
	subStroke.Color = style.BorderColor
	dialogueLabel.Text = text

	activeToken += 1
	local currentToken = activeToken

	subContainer.Visible = true
	subContainer.BackgroundTransparency = 0.25
	subContainer.Position = UDim2.new(0.5, 0, 1, -100)
	TweenService:Create(subContainer, S.FAST, { Position = UDim2.new(0.5, 0, 1, -110) }):Play()

	local dur = duration or 3.5
	task.delay(dur, function()
		if activeToken == currentToken then
			local tw = TweenService:Create(
				subContainer,
				S.FAST,
				{ BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 1, -100) }
			)
			tw:Play()
			tw.Completed:Connect(function()
				if activeToken == currentToken then
					subContainer.Visible = false
				end
			end)
		end
	end)
end

-- ===== Remote Listeners =====
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)

-- Listen for AnnouncerEvent
task.spawn(function()
	local r = Remotes and Remotes:WaitForChild("AnnouncerEvent", 15)
	if r and r:IsA("RemoteEvent") then
		r.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" and data.text and not player:GetAttribute("InRaid") then -- v10: not over a raid / episode
				showSubtitle(data.speaker or "GrandPriest", data.text, data.duration)
			end
		end)
	end
end)

-- LastStand Listener
local _ = ToPLogic
player:GetAttributeChangedSignal("LastStand"):Connect(function()
	if player:GetAttribute("LastStand") then
		showBanner("LAST STAND", "You are your universe's last hope: power up!", Color3.fromRGB(255, 120, 60))
	end
end)

-- SuperShenron Listener
task.spawn(function()
	local r = Remotes and Remotes:WaitForChild("SuperShenron", 15)
	if r and r:IsA("RemoteEvent") then
		r.OnClientEvent:Connect(function(d)
			if typeof(d) ~= "table" or player:GetAttribute("InRaid") then return end -- v10: not over a raid / episode
			if d.phase == "Summon" then
				showBanner("SUPER SHENRON", tostring(d.winner) .. " may make a wish", S.GOLD, 4)
			elseif d.phase == "Granted" then
				showBanner("YOUR WISH HAS BEEN GRANTED", tostring(d.winner), S.GOLD, 4)
			end
		end)
	end
end)
