-- LocalScript: spectate camera after elimination (or as fusion passenger).
-- Orbit mode: wide orbit around the server-chosen SpectateTarget (teammates first). Q/E = previous/next target
-- (validated by server via SpectateRequest). F = toggle free camera (WASD + Space/Shift, right mouse to look).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ClientAPI = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ClientAPI"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ORBIT_DIST, ORBIT_HEIGHT, ORBIT_SPEED = 70, 30, 0.25
local FREE_SPEED = 80
local angle = 0
local free = false
local freeCF = CFrame.new()
local yaw, pitch = 0, -0.3

local function spectating(): boolean
	return player:GetAttribute("Spectating") == true
end

local function candidates(): { Player }
	local mine, all = {}, {}
	for _, p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("Alive") == true and not p:GetAttribute("FusedPassenger") then
			table.insert(all, p)
			if p.Team == player.Team then table.insert(mine, p) end
		end
	end
	return if #mine > 0 then mine else all
end

local function cycle(dir: number)
	local list = candidates()
	if #list == 0 then return end
	local cur = player:GetAttribute("SpectateTarget")
	local idx = 0
	for i, p in list do if p.UserId == cur then idx = i end end
	idx = (idx - 1 + dir) % #list + 1
	ClientAPI.spectate(list[idx].UserId)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not spectating() then return end
	if input.KeyCode == Enum.KeyCode.Q then cycle(-1)
	elseif input.KeyCode == Enum.KeyCode.E then cycle(1)
	elseif input.KeyCode == Enum.KeyCode.F then
		free = not free
		freeCF = camera.CFrame
	end
end)

local active = false
RunService.RenderStepped:Connect(function(dt)
	-- db-story: a CutsceneDirector cinematic owns the camera while InCinematic is set (cleared on end/skip); resume after
	if player:GetAttribute("InCinematic") == true then return end
	if not spectating() then
		if active then
			active = false; free = false
			camera.CameraType = Enum.CameraType.Custom
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then camera.CameraSubject = hum end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		return
	end
	active = true
	camera.CameraType = Enum.CameraType.Scriptable
	if free then
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local d = UserInputService:GetMouseDelta()
			yaw -= d.X * 0.004
			pitch = math.clamp(pitch - d.Y * 0.004, -1.4, 1.4)
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move += Vector3.new(0, -1, 0) end
		local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		freeCF = CFrame.new(freeCF.Position + (rot:VectorToWorldSpace(move) * FREE_SPEED * dt)) * rot
		camera.CFrame = freeCF
		return
	end
	local target = Players:GetPlayerByUserId(player:GetAttribute("SpectateTarget") or 0)
	local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local focus = if root then root.Position else Vector3.new(0, 500, 0) -- arena center (db-map)
	angle += dt * ORBIT_SPEED
	local pos = focus + Vector3.new(math.cos(angle) * ORBIT_DIST, ORBIT_HEIGHT, math.sin(angle) * ORBIT_DIST)
	camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(pos, focus), math.min(1, dt * 4))
end)
