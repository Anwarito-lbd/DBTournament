--!nonstrict
-- FriezaMajinFX (FriezaMajin kit): small helpers the kit's effect modules share. Not an effect itself.
-- id(character): the fighter id (player attribute, then model attributes), as VFXRouter reads it.
-- form(character): the current form id ("Golden", "FriezaBlack", ...) from the server's Form attribute.
-- target(character, t): a world position from a Vector3, a Model or a part; else a point ahead of the character.
-- victimNear(character, pos, radius): the closest other character with a Humanoid near pos (for touch effects).
local Players = game:GetService("Players")

local M = {}

function M.id(character: Model): string?
	local pl = Players:GetPlayerFromCharacter(character)
	local id = (pl and pl:GetAttribute("Character")) or character:GetAttribute("Character")
		or character:GetAttribute("ChampionModel")
	return if type(id) == "string" then id else nil
end

function M.form(character: Model): string?
	local pl = Players:GetPlayerFromCharacter(character)
	local f = (pl and pl:GetAttribute("Form")) or character:GetAttribute("Form")
	return if type(f) == "string" then f else nil
end

function M.target(character: Model, t: any): Vector3
	if typeof(t) == "Vector3" then return t end
	if typeof(t) == "Instance" then
		if t:IsA("Model") then return t:GetPivot().Position end
		if t:IsA("BasePart") then return t.Position end
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position + root.CFrame.LookVector * 6 else character:GetPivot().Position
end

function M.victimNear(character: Model, pos: Vector3, radius: number): Model?
	local best, bestD = nil, radius
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	for _, p in workspace:GetPartBoundsInRadius(pos, radius, params) do
		local m = p:FindFirstAncestorOfClass("Model")
		local root = m and m:FindFirstChild("HumanoidRootPart") :: BasePart?
		if m and m ~= character and root and m:FindFirstChildOfClass("Humanoid") then
			local d = (root.Position - pos).Magnitude
			if d < bestD then best, bestD = m, d end
		end
	end
	return best
end

return M
