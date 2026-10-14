--!nonstrict
-- DestructoDiscVFX (Frieza version / Krillin recolor). Flat spinning saw disc, homing curve, slash on hit, optional split.
-- Play(character, target(Vector3|BasePart|Model), config?) ; config.Split = 2..3 (Golden) fans out extra discs.
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromHex("FFB0E0"), EdgeColor = Color3.fromHex("FFF080"), Size = 5, Speed = 70, Homing = 3,
	MaxTime = 3, Split = 1, SoundId = "", OnHit = nil}
local function targetPos(t)
	if typeof(t) == "Instance" then return t:IsA("Model") and t:GetPivot().Position or t.Position end
	return t
end
local function oneDisc(character, target, c, angleOffset)
	local root = C.root(character)
	local f = C.folder("DestructoDiscVFX", c.MaxTime + 2)
	local disc = C.part(f, Vector3.new(0.15, c.Size, c.Size), c.Color, Enum.PartType.Cylinder, 0.15)
	local edge = C.part(f, Vector3.new(0.08, c.Size * 1.1, c.Size * 1.1), c.EdgeColor, Enum.PartType.Cylinder, 0.5)
	C.light(disc, c.Color, 8, 2)
	local pos = C.hands(character) + Vector3.new(0, 3, 0)
	local vel = (CFrame.Angles(0, angleOffset, 0) * CFrame.lookAt(Vector3.zero, C.direction(pos, targetPos(target)))).LookVector * c.Speed
	local params = C.rayParams({character, f})
	local spin, t0 = 0, os.clock()
	C.sound(c.SoundId, root)
	while os.clock() - t0 < c.MaxTime do
		local dt = RunService.Heartbeat:Wait()
		local desired = (targetPos(target) - pos).Unit * c.Speed
		vel = vel:Lerp(desired, math.min(1, c.Homing * dt)).Unit * c.Speed
		local res = workspace:Spherecast(pos, c.Size * 0.4, vel * dt, params)
		if res then
			if c.OnHit then c.OnHit(res.Position, res.Instance) end
			local victim = res.Instance:FindFirstAncestorOfClass("Model")
			if victim and victim:FindFirstChildOfClass("Humanoid") then C.Hitstop({victim}, "Medium") end
			C.ImpactFrame("white", 1)
			C.CameraShake(0.35)
			local slash = C.part(f, Vector3.new(0.2, 0.3, c.Size * 2), c.EdgeColor, nil, 0)
			slash.CFrame = CFrame.lookAt(res.Position, res.Position + vel) * CFrame.Angles(0, 0, math.rad(30))
			C.tween(slash, 0.3, {Transparency = 1, Size = Vector3.new(0.05, 0.05, c.Size * 3)})
			break
		end
		pos += vel * dt
		spin += dt * 40
		local cf = CFrame.lookAt(pos, pos + vel) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(spin, 0, 0)
		disc.CFrame, edge.CFrame = cf, cf
	end
	C.tween(disc, 0.2, {Transparency = 1}); C.tween(edge, 0.2, {Transparency = 1})
	task.wait(0.5)
	f:Destroy()
end
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	for i = 1, math.clamp(c.Split, 1, 3) do
		local off = (i - (c.Split + 1) / 2) * math.rad(25)
		task.spawn(oneDisc, character, target, c, off)
	end
end
return M
