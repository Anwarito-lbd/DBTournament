--!nonstrict
-- JusticePoseVFX (Pride Troopers kit). Play(character, _target, config?). The 1 s Justice Pose: the fighter flashes
-- red and white, a light pillar rises, and when the pose lands a ring sweeps the ground out to the buff radius, so
-- allies can see who the Justice Buff reached. Timing and radius come from Config.RACE_POWERUPS.JusticePose.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C = require(ReplicatedStorage:WaitForChild("VFX"):WaitForChild("VFXCommon"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local RULE = (Config.RACE_POWERUPS and Config.RACE_POWERUPS.JusticePose) or {}
local DEFAULTS = {
	Color = Color3.fromRGB(235, 60, 60),
	CoreColor = Color3.fromRGB(255, 245, 240),
	Pose = RULE.pose or 1,
	Radius = RULE.radius or 30,
}
function M.Play(character, _target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character)
	if not root then
		return
	end
	local f = C.folder("JusticePoseVFX", c.Pose + 2)
	local hl = Instance.new("Highlight")
	hl.FillColor, hl.OutlineColor, hl.FillTransparency = c.Color, c.CoreColor, 0.55
	hl.Parent = character
	C.tween(hl, c.Pose, { FillTransparency = 1, OutlineTransparency = 1 })
	game:GetService("Debris"):AddItem(hl, c.Pose + 0.1)
	local ground = root.Position - Vector3.new(0, 3, 0)
	local pillar = C.part(f, Vector3.new(0.5, 30, 0.5), c.CoreColor, Enum.PartType.Cylinder, 0.2)
	pillar.CFrame = CFrame.new(ground + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	C.light(pillar, c.Color, 18, 3)
	C.tween(pillar, c.Pose, { Size = Vector3.new(30, 4, 4), Transparency = 1 })
	C.Shockwave(f, CFrame.new(ground), 2, 10, c.Color, 0.4, 0.3)
	task.delay(c.Pose, function()
		local r = C.root(character)
		local g = if r then r.Position - Vector3.new(0, 3, 0) else ground
		C.Shockwave(f, CFrame.new(g), 4, c.Radius * 2, c.Color, 0.6, 0.5)
		C.Shockwave(f, CFrame.new(g), 2, c.Radius * 1.4, c.CoreColor, 0.45, 0.2)
	end)
end
return M
