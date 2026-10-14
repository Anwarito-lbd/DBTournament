local lib = game.ReplicatedStorage.CharacterModels
local out = {}
for _, id in {"u7_goku","u7_vegeta","u7_frieza"} do
	local m = lib[id]
	local parts = {}
	for _, d in m:GetDescendants() do table.insert(parts, d.ClassName .. ":" .. d.Name) end
	table.insert(out, id .. " => " .. table.concat(parts, ", "))
	local old = workspace:FindFirstChild("Seg_" .. id); if old then old:Destroy() end
	local s = Instance.new("Model"); s.Name = "Seg_" .. id
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") then local c = d:Clone(); for _, x in c:GetChildren() do if x:IsA("WeldConstraint") then x:Destroy() end end; c.Anchored = true; c.Parent = s end
	end
	s.Parent = workspace
	s:PivotTo(CFrame.new((#out) * 10, 1600, 0))
end
return table.concat(out, "\n")
