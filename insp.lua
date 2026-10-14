local o = {}
for _, id in {"u7_goku","u7_vegeta","u7_frieza"} do
	local s = workspace:FindFirstChild("Seg_" .. id)
	if s then
		for _, c in s:GetChildren() do
			local kids = {}
			for _, k in c:GetDescendants() do if k:IsA("BasePart") then table.insert(kids, k.Name .. "@" .. string.format("%.1f", k.Position.Y)) end end
			table.insert(o, id .. " / " .. c.ClassName .. " " .. c.Name .. " : " .. table.concat(kids, ", "))
		end
	end
end
return table.concat(o, "\n")
