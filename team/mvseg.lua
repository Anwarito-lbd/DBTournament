local RS = game:GetService("ReplicatedStorage")
local dst = RS:FindFirstChild("SegSources") or Instance.new("Folder"); dst.Name = "SegSources"; dst.Parent = RS
local moved = {}
for _, m in ipairs(workspace:GetChildren()) do
	if m.Name:match("^Seg_u7_") then m.Parent = dst; table.insert(moved, m.Name) end
end
local stray = 0
for _, x in ipairs(workspace:GetChildren()) do if x:IsA("Highlight") and x.Name == "AnimeOutline" then x:Destroy(); stray += 1 end end
return "moved=" .. table.concat(moved, ",") .. " strayHighlightsRemoved=" .. stray
