local CS=game:GetService("CollectionService")
local out={}
for _,t in {"ArenaSpawn","StandSpawn","LobbySpawn","RingBounds","RingChunk","ArenaCover"} do table.insert(out,t.."="..#CS:GetTagged(t)) end
local s=CS:GetTagged("ArenaSpawn")[1]; if s then table.insert(out,"spawnU="..tostring(s:GetAttribute("Universe")).." pos="..tostring(s.Position)) end
local l=CS:GetTagged("LobbySpawn")[1]; if l then table.insert(out,"lobby="..tostring(l.Position)) end
table.insert(out,"SpawnLocation="..tostring(workspace:FindFirstChild("SpawnLocation")))
table.insert(out,"Baseplate="..tostring(workspace:FindFirstChild("Baseplate")))
return table.concat(out,", ")
