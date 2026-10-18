--!nonstrict
-- JusticeFlashVFX (Pride Troopers kit, Toppo). Base form: Justice Flash, rapid ki shots from his fingertips. Destroyer
-- form (his "FullPower" form): Destructive Flare, a dark violet sphere of destruction energy pushed at the target.
-- Colours and shapes come from the kit's `flash` and `destroyer` looks. Play(character, target, config?). Visual only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local DeathBeam = require(VFX:WaitForChild("DeathBeamVFX"))
local DeathBall = require(VFX:WaitForChild("DeathBallVFX"))
local Kit = require(script.Parent.Parent)
local M = {}
M.DESTROYER_FORM = "FullPower"
local function form(character: Model): any
	local p = Players:GetPlayerFromCharacter(character)
	return (p and p:GetAttribute("Form")) or character:GetAttribute("Form")
end
function M.Play(character, target, config)
	local id = Kit.idOf(character)
	if form(character) == M.DESTROYER_FORM then
		return DeathBall.Play(character, target, C.merge(Kit.lookFor(id, "destroyer"), config))
	end
	local flash = Kit.lookFor(id, "flash")
	return DeathBeam.Rapid(character, target, flash.Shots or 5, C.merge(flash, config))
end
return M
