--!nonstrict
-- JusticeWaveVFX (Pride Troopers kit). A hand-fired energy wave drawn by BeamFX with the character's `wave` look:
-- Kahseral's golden Cannon Maximum, Dyspo's quick violet one, Vuon's Dynamite Blaster, Kunshi's thin Threaded Energy.
-- Play(character, target, config?). Visual only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeamFX = require(ReplicatedStorage:WaitForChild("VFX"):WaitForChild("BeamFX"))
local Kit = require(script.Parent.Parent)
local M = {}
function M.Play(character, target, config)
	local wave = Kit.lookFor(Kit.idOf(character), "wave")
	return BeamFX.Play(character, target, wave or "Kamehameha", config)
end
return M
