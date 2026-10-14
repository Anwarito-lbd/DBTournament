local out = {}
for _, root in ipairs({workspace, game:GetService("ServerStorage"), game:GetService("ReplicatedStorage")}) do
	for _, d in ipairs(root:GetDescendants()) do
		if (d:IsA("Model") or d:IsA("MeshPart")) and (d.Name:match("_%x%x%x%x%x%x$") or d.Name:lower():match("sketchfab")) then
			table.insert(out, d:GetFullName())
		end
	end
end
return #out .. " :: " .. table.concat(out, " | ", 1, math.min(#out, 60))
