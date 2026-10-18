--!nonstrict
-- FriezaDeathBeamVFX (FriezaMajin kit): Frieza's signature slot. Not one big beam but three Death Beams from one
-- finger, almost no charge, each a needle that lands before the last fades; the third is the one that matters.
-- The colour follows his form: pink-violet in base and 100%, gold in Golden, crimson on black in Black Frieza.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); the needles are
-- drawn by the shared BeamFX with ChargeAt = "finger".
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
local NEEDLE = { Width = 0.7, Charge = 0.12, Duration = 0.3, Spiral = false, ImpactSize = 7, Shake = 0.5,
	ChargeAt = "finger", Speed = 1100 }
-- per form: Core, Glow, Haze
M.COLORS = {
	Base = { rgb(255, 235, 255), rgb(255, 70, 210), rgb(170, 40, 220) },
	Golden = { rgb(255, 250, 225), rgb(255, 200, 40), rgb(255, 120, 200) },
	FriezaBlack = { rgb(255, 210, 230), rgb(200, 30, 90), rgb(20, 8, 25) },
}
M.COUNT, M.GAP = 3, 0.1

function M.Play(character: Model, target: any, _config: any?)
	local pos = FX.target(character, target)
	local c = M.COLORS[FX.form(character) or "Base"] or M.COLORS.Base
	for i = 1, M.COUNT do
		task.delay((i - 1) * M.GAP, function()
			if not character.Parent then return end
			local last = i == M.COUNT
			local st = table.clone(NEEDLE)
			st.Core, st.Glow, st.Haze = c[1], c[2], c[3]
			if last then st.Width, st.ImpactSize, st.Shake = 1, 12, 1.2 end
			-- the first two needles land just off the mark, the last one dead on
			local off = if last then Vector3.zero else Vector3.new(math.random(-2, 2), math.random(-1, 1), math.random(-2, 2))
			BeamFX.Play(character, pos + off, st)
		end)
	end
end

return M
