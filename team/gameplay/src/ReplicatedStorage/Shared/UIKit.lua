--!strict
-- ModuleScript: ReplicatedStorage.Shared.UIKit  (v1 client UI helpers + placeholder story figures)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIKit = {}

UIKit.GOLD = Color3.fromRGB(255, 200, 60)
UIKit.DARK = Color3.fromRGB(12, 14, 30)

function UIKit.gui(name: string, order: number?): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(name)
	if old then old:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = name; g.ResetOnSpawn = false; g.IgnoreGuiInset = true
	g.DisplayOrder = order or 0
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = pg
	return g
end

function UIKit.frame(parent: Instance, size: UDim2, pos: UDim2, color: Color3?, alpha: number?): Frame
	local f = Instance.new("Frame")
	f.Size = size; f.Position = pos
	f.BackgroundColor3 = color or UIKit.DARK
	f.BackgroundTransparency = alpha or 0.25
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f
	return f
end

function UIKit.label(parent: Instance, text: string, size: UDim2, pos: UDim2, textSize: number?, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size; l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize or 18
	l.TextWrapped = true
	l.TextStrokeTransparency = 0.5
	l.Parent = parent
	return l
end

function UIKit.button(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3?): TextButton
	local b = Instance.new("TextButton")
	b.Size = size; b.Position = pos
	b.BackgroundColor3 = color or Color3.fromRGB(40, 60, 140)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.TextWrapped = true
	b.AutoButtonColor = true
	b.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
	return b
end

-- Bar: returns setter(fraction, text)
function UIKit.bar(parent: Instance, size: UDim2, pos: UDim2, color: Color3, title: string): (number, string?) -> ()
	local bg = UIKit.frame(parent, size, pos, Color3.fromRGB(20, 20, 20), 0.3)
	local fill = UIKit.frame(bg, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), color, 0)
	local l = UIKit.label(bg, title, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 14)
	l.ZIndex = 3
	return function(frac: number, text: string?)
		fill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
		l.Text = if text then title .. "  " .. text else title
	end
end

-- Subtitle box with speaker name. Returns show(speaker, text) and destroy().
local SPEAKER_NAMES = { GrandPriest = "Grand Priest", Zeno = "Zeno", FutureZeno = "Future Zeno", SuperShenron = "Super Shenron",
	Leader = "Champion", Team = "Your Team",
	npc_grand_priest = "Grand Priest", npc_zeno = "Zeno", npc_zeno_future = "Future Zeno", npc_shenron = "Super Shenron", God = "God of Destruction", Bulma = "Bulma", Jiren = "Jiren" }
local SPEAKER_COLORS = { GrandPriest = Color3.fromRGB(120, 200, 255), Zeno = Color3.fromRGB(200, 140, 255),
	FutureZeno = Color3.fromRGB(200, 140, 255), SuperShenron = Color3.fromRGB(255, 90, 90), Leader = UIKit.GOLD,
	npc_grand_priest = Color3.fromRGB(120, 200, 255), npc_zeno = Color3.fromRGB(200, 140, 255), npc_zeno_future = Color3.fromRGB(200, 140, 255), npc_shenron = Color3.fromRGB(255, 90, 90),
	Bulma = Color3.fromRGB(80, 220, 210), Jiren = Color3.fromRGB(255, 70, 60),
	-- v10 Legendary Episodes
	Goku = Color3.fromRGB(255, 150, 40), Piccolo = Color3.fromRGB(120, 220, 90), Raditz = Color3.fromRGB(230, 70, 110) }
function UIKit.subtitles(parent: Instance)
	local box = UIKit.frame(parent, UDim2.new(0.7, 0, 0, 110), UDim2.new(0.15, 0, 1, -150), Color3.new(0, 0, 0), 0.35)
	local who = UIKit.label(box, "", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 8), 22, UIKit.GOLD)
	who.TextXAlignment = Enum.TextXAlignment.Left
	local txt = UIKit.label(box, "", UDim2.new(1, -24, 1, -44), UDim2.new(0, 12, 0, 38), 20)
	txt.TextXAlignment = Enum.TextXAlignment.Left; txt.TextYAlignment = Enum.TextYAlignment.Top
	txt.Font = Enum.Font.Gotham
	return function(speaker: string, text: string)
		who.Text = SPEAKER_NAMES[speaker] or speaker
		who.TextColor3 = SPEAKER_COLORS[speaker] or UIKit.GOLD
		txt.Text = text
		txt.MaxVisibleGraphemes = 0
		task.spawn(function()
			local n = utf8.len(text) or #text
			for i = 1, n, 2 do
				if txt.Text ~= text then return end
				txt.MaxVisibleGraphemes = i
				task.wait(0.015)
			end
			txt.MaxVisibleGraphemes = -1
		end)
	end
end

function UIKit.tweenCamera(cf: CFrame, t: number)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = cf }):Play()
end

function UIKit.restoreCamera()
	local cam = workspace.CurrentCamera
	-- v10: hand back a normal follow view (behind + above the character) instead of the last shot's angle
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
		cam.CFrame = CFrame.lookAt(root.Position - flat * 12 + Vector3.new(0, 5, 0), root.Position + Vector3.new(0, 1.5, 0))
	end
	cam.CameraType = Enum.CameraType.Custom
	local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
end

return UIKit
