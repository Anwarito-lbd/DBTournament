--!strict
-- LocalScript: StarterPlayer.StarterPlayerScripts.TelegraphRenderer (WP-STORY-2)
-- Client-side rendering of boss danger zones (red cones, circles, lines).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)

local function createIndicatorPart(color: Color3): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.6
	return p
end

local function renderTelegraph(data: any)
	local shape = data.Shape or "Circle"
	local cf = data.CFrame or CFrame.new()
	local color = data.Color or Color3.fromRGB(255, 50, 50)
	local dur = data.Duration or 1.0

	local container = Instance.new("Folder")
	container.Name = "TelegraphZone"
	container.Parent = workspace
	Debris:AddItem(container, dur + 1.0)

	if shape == "Circle" or shape == "Ring" then
		local rad = data.Radius or 30
		local disc = createIndicatorPart(color)
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.2, rad * 2, rad * 2)
		disc.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
		disc.Parent = container

		-- Growing inner charge ring
		local fill = createIndicatorPart(Color3.new(1, 1, 1))
		fill.Shape = Enum.PartType.Cylinder
		fill.Size = Vector3.new(0.3, 1, 1)
		fill.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
		fill.Parent = container

		local tw = TweenService:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
			Size = Vector3.new(0.3, rad * 2, rad * 2),
			Color = color,
		})
		tw:Play()

		task.delay(dur, function()
			TweenService:Create(disc, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			TweenService:Create(fill, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end)
	elseif shape == "Line" then
		local length = data.Length or 100
		local width = data.Width or 4
		local line = createIndicatorPart(color)
		line.Size = Vector3.new(width, 0.2, length)
		line.CFrame = cf * CFrame.new(0, 0, -length / 2)
		line.Parent = container

		task.delay(dur, function()
			TweenService:Create(line, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end)
	elseif shape == "Cone" then
		local radius = data.Radius or 50
		local conePart = createIndicatorPart(color)
		conePart.Size = Vector3.new(radius * 0.8, 0.2, radius)
		conePart.CFrame = cf * CFrame.new(0, 0, -radius / 2)
		conePart.Parent = container

		task.delay(dur, function()
			TweenService:Create(conePart, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end)
	end
end

task.spawn(function()
	local r = Remotes and Remotes:WaitForChild("ShowTelegraph", 15)
	if r and r:IsA("RemoteEvent") then
		r.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" then
				renderTelegraph(data)
			end
		end)
	end
end)
