local lib = game.ReplicatedStorage.CharacterModels
local MAP = { head = "Head", torso = "UpperTorso", ["left arm"] = "LeftUpperArm", ["right arm"] = "RightUpperArm",
	["left leg"] = "LeftUpperLeg", ["right leg"] = "RightUpperLeg", legs = "LowerTorso" }
local o = {}
for _, id in {"u7_goku","u7_vegeta","u7_frieza"} do
	local s = workspace:FindFirstChild("Seg_" .. id)
	local entry = lib:FindFirstChild(id)
	if s and entry then
		local seg = Instance.new("Model"); seg.Name = "Segments"
		local names = {}
		for _, k in s:GetDescendants() do
			if k:IsA("MeshPart") and MAP[k.Name] then
				local c = k:Clone(); c:ClearAllChildren(); c.Name = MAP[k.Name]; c.Anchored = true; c.Parent = seg
				table.insert(names, c.Name)
			end
		end
		-- keep the rigid original as "Mesh" for showcase; drop the old swap rig so skin mode is used
		local hrp = entry:FindFirstChild("HumanoidRootPart"); if hrp then hrp:Destroy() end
		local hum = entry:FindFirstChildOfClass("Humanoid"); if hum then hum:Destroy() end
		local old = entry:FindFirstChild("Segments"); if old then old:Destroy() end
		seg.Parent = entry
		for _, d in entry:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
		table.insert(o, id .. ": " .. table.concat(names, ","))
	end
end
return table.concat(o, "\n")
