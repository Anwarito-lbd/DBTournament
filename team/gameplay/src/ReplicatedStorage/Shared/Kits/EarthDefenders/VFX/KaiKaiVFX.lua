--!nonstrict
-- KaiKaiVFX (Earth defenders kit). Shin's Kai Kai: unlike Instant Transmission there is no ki to lock onto and no
-- fingers to the brow, just a raised hand, a soft lavender column, and he is gone; the same column rises where he
-- lands. The flicker is borrowed from the shared InstantTransmissionVFX, slowed and tinted.
-- Play(character, destination, config?) -- client visual only; the server already moved him.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local IT = require(VFX:WaitForChild("InstantTransmissionVFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(200, 160, 255), core = rgb(250, 240, 255), height = 16, width = 3.5 }

local function column(pos: Vector3)
	local s = M.STYLE
	local f = C.folder("KaiKaiColumn", 1.5)
	-- a cylinder's axis is its X: stand it up
	local col = C.part(f, Vector3.new(s.height, s.width, s.width), s.color, Enum.PartType.Cylinder, 0.4)
	col.CFrame = CFrame.new(pos + Vector3.new(0, s.height / 2 - 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	C.tween(col, 0.5, { Size = Vector3.new(s.height * 1.4, 0.1, 0.1), Transparency = 1 })
	C.light(col, s.color, 12, 2)
	C.Shockwave(f, CFrame.new(pos - Vector3.new(0, 2.8, 0)), 1, 9, s.core, 0.4)
end

function M.Play(character: Model, destination: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	column(root.Position)
	local dest = if typeof(destination) == "Vector3" then destination else root.Position
	IT.Play(character, dest, { Color = M.STYLE.color, Flickers = 2, FlickerTime = 0.07, Gap = 0.1 })
	task.delay(0.12, column, dest)
end
return M
