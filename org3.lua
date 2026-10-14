local lib = game.ReplicatedStorage.CharacterModels
local log = {}
for _, c in workspace:GetChildren() do
	if c:IsA("Model") and c.Name:sub(1,8) == "stylized" then
		local id = if c.Name:find("original design, full body") then (if lib:FindFirstChild("u7_frieza") then "u7_frieza_alt" else "u7_frieza") elseif c.Name:find("serpentine") then "npc_shenron" else nil
		table.insert(log, c.Name:sub(1,100) .. " -> " .. tostring(id))
		if id then
			local old = lib:FindFirstChild(id); if old then old:Destroy() end
			c:SetAttribute("Prompt", c.Name); c.Name = id
			if id == "u7_frieza" or id == "u7_frieza_alt" then
				for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.Anchored = false; d.CanCollide = false; d.Massless = true end end
				local cf, size = c:GetBoundingBox()
				local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.Size = Vector3.new(2, 2, 1); hrp.Transparency = 1; hrp.CFrame = cf; hrp.Parent = c
				for _, d in c:GetDescendants() do if d:IsA("BasePart") and d ~= hrp then local w = Instance.new("WeldConstraint"); w.Part0 = hrp; w.Part1 = d; w.Parent = hrp end end
				local h = Instance.new("Humanoid"); h.HipHeight = size.Y / 2 - 1; h.Parent = c; c.PrimaryPart = hrp
			else
				for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
			end
			c.Parent = lib
			table.insert(log, id .. " " .. tostring(c:GetExtentsSize()))
		end
	end
end
local names = {} for _, c in lib:GetChildren() do table.insert(names, c.Name) end
return table.concat(log, "\n") .. "\nLIB: " .. table.concat(names, ",")
