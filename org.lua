local RS = game:GetService("ReplicatedStorage")
local lib = RS:FindFirstChild("CharacterModels") or Instance.new("Folder")
lib.Name = "CharacterModels"; lib.Parent = RS
local order = {"u7_goku","u7_vegeta","npc_zeno","npc_shenron_green_alt","npc_grand_priest"}
local gen = {}
for _, c in workspace:GetChildren() do
	if c:IsA("Model") and (c.Name:sub(1,8) == "stylized" or c.Name:sub(1,12) == "giant glossy") then table.insert(gen, c) end
end
local log = {}
local i = 0
for _, c in gen do
	local id
	if c.Name:find("giant glossy") then id = "super_dragon_ball"
	elseif c.Name:find("royal guard") or c.Name:find("tall imposing") then id = "npc_zeno_guard"
	else i += 1; id = order[i] end
	if id then
		local old = lib:FindFirstChild(id); if old then old:Destroy() end
		c:SetAttribute("Prompt", c.Name)
		c.Name = id
		for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.Anchored = false; d.CanCollide = false; d.Massless = true end end
		if id == "u7_goku" or id == "u7_vegeta" or id == "u7_frieza" then
			local cf, size = c:GetBoundingBox()
			local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.Size = Vector3.new(2, 2, 1)
			hrp.Transparency = 1; hrp.CanCollide = true; hrp.CFrame = cf; hrp.Massless = false; hrp.Parent = c
			for _, d in c:GetDescendants() do if d:IsA("BasePart") and d ~= hrp then
				local w = Instance.new("WeldConstraint"); w.Part0 = hrp; w.Part1 = d; w.Parent = hrp end end
			local h = Instance.new("Humanoid"); h.HipHeight = size.Y / 2 - 1; h.RigType = Enum.HumanoidRigType.R15; h.Parent = c
			c.PrimaryPart = hrp
		else
			for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
		end
		c.Parent = lib
		table.insert(log, id .. " " .. tostring(c:GetExtentsSize()))
	end
end
return table.concat(log, "\n")
