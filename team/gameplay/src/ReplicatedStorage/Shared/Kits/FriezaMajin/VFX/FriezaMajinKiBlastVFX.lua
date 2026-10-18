--!nonstrict
-- FriezaMajinKiBlastVFX (FriezaMajin kit): each fighter's plain ki blast. Frieza flicks a fast thin pink Death
-- Bullet; Frost's Chaos Shot is blue-violet; Moro throws three slow green orbs in a fan; Maji Kayo lobs a heavy
-- blue jelly glob. Same cheap projectile as VFXCommon.KiBlast, which this calls.
-- NOTE: VFXRouter currently draws every "KiBlast" with the shared projectile before consulting kits, so this module
-- only plays once the router asks Kits.signature(id, "KiBlast") first (KITS.md "needs server work").
-- Play(character, target, config?) -- client visual only.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}

-- Color = glow and trail, Core = bolt centre, Speed in studs/s, Count = bolts, Spread = fan angle (degrees)
M.STYLES = {
	u7_frieza = { Color = rgb(255, 80, 210), Core = rgb(255, 240, 255), Speed = 260, Count = 1, Spread = 0 },
	u6_frost = { Color = rgb(120, 130, 255), Core = rgb(225, 240, 255), Speed = 210, Count = 1, Spread = 0 },
	u7_moro = { Color = rgb(120, 230, 90), Core = rgb(235, 255, 225), Speed = 150, Count = 3, Spread = 9 },
	u3_maji_kayo = { Color = rgb(70, 170, 255), Core = rgb(210, 240, 255), Speed = 120, Count = 1, Spread = 0 },
}

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLES[FX.id(character) or ""] or M.STYLES.u7_frieza
	local root = C.root(character)
	if not root then return end
	local goal = FX.target(character, target)
	local dir = C.direction(C.hands(character), goal)
	for i = 1, s.Count do
		local yaw = math.rad((i - (s.Count + 1) / 2) * s.Spread)
		task.delay(0.05 * (i - 1), function()
			if not character.Parent then return end
			C.KiBlast(character, { Direction = CFrame.fromAxisAngle(Vector3.yAxis, yaw):VectorToWorldSpace(dir),
				Color = s.Color, Core = s.Core, Speed = s.Speed })
		end)
	end
end

return M
