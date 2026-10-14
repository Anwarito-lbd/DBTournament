--!nonstrict
-- InstantTransmissionVFX (Goku; also used by Moro's copied teleport). Fingers glow, body flickers 3x, vertical blur streak,
-- reappear at destination with inverse flicker. No big flash. Movement itself is server-side.
--   Vanish(character, config?)            -- at current position
--   Appear(character, position?, config?) -- at position (default current)
--   Play(character, destination, config?) -- vanish, wait config.Gap, appear at destination (visual only)
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromRGB(200, 235, 255), Flickers = 3, FlickerTime = 0.05, Gap = 0.15, SoundId = ""}

local function setAlpha(character, a)
	for _, p in ipairs(character:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.LocalTransparencyModifier = a end
	end
end
local function streak(c, pos)
	local f = C.folder("ITStreak", 1)
	local s = C.part(f, Vector3.new(0.6, 7, 0.6), c.Color, nil, 0.3)
	s.Position = pos
	C.tween(s, 0.25, {Size = Vector3.new(0.05, 12, 0.05), Transparency = 1})
end
function M.Vanish(character, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local hand = C.limb(character, {"RightHand", "Right Arm"})
	local glow = C.light(hand, c.Color, 4, 3)
	C.sound(c.SoundId, root)
	for _ = 1, c.Flickers do
		setAlpha(character, 0.6); task.wait(c.FlickerTime)
		setAlpha(character, 0); task.wait(c.FlickerTime)
	end
	glow:Destroy()
	C.Afterimage(character, c.Color, 0.3, 0.4)
	streak(c, root.Position)
	setAlpha(character, 1)
end
function M.Appear(character, position, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	streak(c, position or root.Position)
	task.delay(0.12, function() C.Afterimage(character, c.Color, 0.25, 0.5) end)
	for _ = 1, c.Flickers do
		setAlpha(character, 0.6); task.wait(c.FlickerTime)
		setAlpha(character, 1); task.wait(c.FlickerTime)
	end
	setAlpha(character, 0)
end
function M.Play(character, destination, config)
	local c = C.merge(DEFAULTS, config)
	task.spawn(function()
		M.Vanish(character, c)
		task.wait(c.Gap)
		M.Appear(character, destination, c)
	end)
end
return M
