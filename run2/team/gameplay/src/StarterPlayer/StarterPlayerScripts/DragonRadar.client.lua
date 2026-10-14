-- LocalScript (v8, db-gameplay): Dragon Radar + local Dragon Ball rendering. Toggle [N] / touch button.
-- Server is authoritative (DragonBallService): positions come only via DragonBallState; collect = touch/proximity ->
-- ClientAPI.collectDragonBall(i) (server re-checks distance). Fails gracefully (warn + no UI) if remotes are missing.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
if not S.remotes({ "DragonBallState", "CollectDragonBall", "SummonShenron" }, 15) then
	return
end
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local player = Players.LocalPlayer

local gui = S.gui("DragonRadarUI", 22)
local panel = S.panel(gui, 0.26, 0.42, 320, 400)
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.fromScale(0.98, 0.12)
S.title(panel, "DRAGON RADAR")
local set = S.toggle(gui, panel, Enum.KeyCode.N, "Radar", 0)
S.close(panel, function()
	set(false)
end)
local screen = Instance.new("Frame")
screen.Size = UDim2.fromScale(0.8, 0.6)
screen.Position = UDim2.fromScale(0.1, 0.14)
screen.BackgroundColor3 = Color3.fromRGB(30, 90, 40)
screen.BorderSizePixel = 0
screen.Parent = panel
S.corner(screen, 200)
S.stroke(screen, Color3.fromRGB(180, 255, 160), 2)
local ar = Instance.new("UIAspectRatioConstraint")
ar.Parent = screen
local status = S.label(panel, "", UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.05, 0.76), S.GOLD)
local summon = S.button(
	panel,
	"SUMMON SHENRON",
	UDim2.fromScale(0.8, 0.1),
	UDim2.fromScale(0.1, 0.86),
	S.GREEN,
	function()
		ClientAPI.summonShenron()
	end
)
summon.Visible = false

local RANGE = 600 -- studs shown at the radar edge
local state: any = nil
local dots: { [number]: Frame } = {}
local orbs: { [number]: BasePart } = {}
local folder = Instance.new("Folder")
folder.Name = "MyDragonBalls"
folder.Parent = workspace

local function orb(i: number, pos: Vector3): BasePart
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.4, 2.4, 2.4)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 150, 30)
	p.Position = pos
	p.Name = "DragonBall" .. i
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(40, 40)
	bb.AlwaysOnTop = false
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = string.rep("★", i)
	t.TextColor3 = Color3.fromRGB(220, 30, 30)
	t.TextScaled = true
	t.Parent = bb
	local l = Instance.new("PointLight")
	l.Color = p.Color
	l.Range = 14
	l.Parent = p
	p.Parent = folder
	return p
end

local function render()
	for _, o in orbs do
		o:Destroy()
	end
	orbs = {}
	for _, d in dots do
		d:Destroy()
	end
	dots = {}
	if not state or not state.balls then
		return
	end
	local have = 0
	for _, b in state.balls do
		if b.have then
			have += 1
		elseif not state.summoned then
			orbs[b.i] = orb(b.i, b.pos)
			local d = Instance.new("Frame")
			d.Size = UDim2.fromScale(0.06, 0.06)
			d.AnchorPoint = Vector2.new(0.5, 0.5)
			d.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
			d.BorderSizePixel = 0
			d.Parent = screen
			S.corner(d, 20)
			dots[b.i] = d
		end
	end
	status.Text = if state.summoned
		then "The balls have turned to stone. New hunt on Monday."
		else ("%d / 7 Dragon Balls"):format(have)
	summon.Visible = have == 7 and not state.summoned
end

ClientAPI.onDragonBalls(function(s)
	if s.error then
		S.toast(
			gui,
			({ TooFar = "Get closer!", TooFast = "Easy...", Stone = "Already used this week" })[s.error]
				or tostring(s.error),
			S.RED
		)
		return
	end
	state = s
	render()
end)

local acc = 0
local lastTry: { [number]: number } = {}
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 or not state or not state.balls then
		return
	end
	acc = 0
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not r then
		return
	end
	local cam = workspace.CurrentCamera
	local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
	local yaw = math.atan2(-look.X, -look.Z)
	for _, b in state.balls do
		local d = dots[b.i]
		if d then
			local rel = b.pos - r.Position
			local x, z = rel.X, rel.Z
			local rx = x * math.cos(yaw) - z * math.sin(yaw)
			local rz = x * math.sin(yaw) + z * math.cos(yaw)
			local mag = math.sqrt(rx * rx + rz * rz) / RANGE -- clamp far balls to the radar rim
			local k = if mag > 0 then math.min(mag, 1) * 0.46 / mag else 0
			d.Position = UDim2.fromScale(0.5 + rx / RANGE * k, 0.5 + rz / RANGE * k)
			if rel.Magnitude <= 7 and os.clock() - (lastTry[b.i] or 0) > 1 then -- server validates (<= 8 studs, rate limit)
				lastTry[b.i] = os.clock()
				ClientAPI.collectDragonBall(b.i)
			end
		end
	end
end)
