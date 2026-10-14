--!nonstrict
-- BlackFriezaVFX (Black Frieza signature: "Black Nova" - instant Nova Strike in black/crimson + delayed void burst).
-- Play(character, target, config?).
local C = require(script.Parent:WaitForChild("VFXCommon"))
local Nova = require(script.Parent:WaitForChild("NovaStrikeVFX"))
local M = {}
function M.Play(character, target, config)
	local c = C.merge(C.merge(Nova.BLACK, {Duration = 0.5}), config)
	local userHit = c.OnHit
	c.OnHit = function(pos, inst)
		if userHit then userHit(pos, inst) end
		task.delay(0.35, function()
			local f = C.folder("BlackNovaVoid", 3)
			local void = C.part(f, Vector3.one * 2, Color3.fromRGB(10, 0, 15), Enum.PartType.Ball, 0)
			void.Material = Enum.Material.SmoothPlastic
			void.Position = pos
			C.tween(void, 0.3, {Size = Vector3.one * 18}, Enum.EasingStyle.Back)
			task.wait(0.35)
			C.ImpactFrame("invert", 3, {character})
			C.explosion(f, pos, 35, Color3.fromRGB(150, 40, 110), Color3.fromRGB(255, 60, 120), "", c.OnCameraShake or C.shake)
			C.tween(void, 0.3, {Transparency = 1})
		end)
	end
	return Nova.Play(character, target, c)
end
return M
