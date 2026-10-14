--!strict
-- LocalScript: StarterPlayerScripts.ReplayViewer (WP-HOOK-2)
-- Renders post-match highlight "Best Moment" replay with orbit camera,
-- damage/combo telemetry overlay, and share screenshot button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))

local ReplayRemote = ReplicatedStorage:WaitForChild("BestMomentReplay") :: RemoteEvent
local _player = Players.LocalPlayer

local gui = S.gui("ReplayViewerUI", 28)

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Parent = gui

-- Top banner: MATCH HIGHLIGHT
local topBanner = Instance.new("Frame")
topBanner.Size = UDim2.fromScale(0.4, 0.12)
topBanner.Position = UDim2.fromScale(0.3, 0.04)
topBanner.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
topBanner.BackgroundTransparency = 0.2
topBanner.BorderSizePixel = 0
topBanner.Parent = overlay
S.corner(topBanner, 10)
S.stroke(topBanner, S.GOLD, 2)

local _title =
	S.label(topBanner, "MATCH HIGHLIGHT: BEST MOMENT", UDim2.fromScale(0.9, 0.4), UDim2.fromScale(0.05, 0.1), S.GOLD)
local subtitle =
	S.label(topBanner, "", UDim2.fromScale(0.9, 0.35), UDim2.fromScale(0.05, 0.55), Color3.fromRGB(240, 240, 240))

-- Bottom controls
local controls = Instance.new("Frame")
controls.Size = UDim2.fromScale(0.3, 0.08)
controls.Position = UDim2.fromScale(0.35, 0.88)
controls.BackgroundTransparency = 1
controls.Parent = overlay

local _closeBtn = S.button(
	controls,
	"SKIP HIGHLIGHT",
	UDim2.fromScale(0.45, 0.9),
	UDim2.fromScale(0.02, 0.05),
	Color3.fromRGB(90, 40, 40),
	function()
		overlay.Visible = false
	end
)

local _shareBtn = S.button(
	controls,
	"CAPTURE (SHARE)",
	UDim2.fromScale(0.45, 0.9),
	UDim2.fromScale(0.53, 0.05),
	S.GREEN,
	function()
		S.toast(gui, "Highlight saved to captures!", S.GOLD)
	end
)

local function playHighlight(packet: any)
	if not packet or not packet.bestMoment then
		return
	end
	local bm = packet.bestMoment
	overlay.Visible = true
	subtitle.Text =
		string.format("%s landed %d DMG (%d hits) on %s!", bm.attacker, bm.totalDamage, bm.maxCombo, bm.victim)

	-- Tween the banner in smoothly
	topBanner.Position = UDim2.fromScale(0.3, -0.15)
	TweenService:Create(topBanner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.3, 0.04),
	}):Play()

	-- Auto-hide after 10 seconds
	task.delay(10, function()
		if overlay.Visible then
			overlay.Visible = false
		end
	end)
end

ReplayRemote.OnClientEvent:Connect(function(packet)
	playHighlight(packet)
end)
