--!nonstrict
-- JusticeWhipVFX (Pride Troopers kit, Vuon). Justice Whip: a thin energy lasso snapped out to the target, in the
-- kit's `whip` look. Wrapper over DeathBeamVFX's finger beam. Play(character, target, config?). Visual only (the
-- bind is the server's hitstun).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local DeathBeam = require(VFX:WaitForChild("DeathBeamVFX"))
local Kit = require(script.Parent.Parent)
local M = {}
function M.Play(character, target, config)
	return DeathBeam.Play(character, target, C.merge(Kit.lookFor(Kit.idOf(character), "whip"), config))
end
return M
