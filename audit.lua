local RS, SSS, SP = game.ReplicatedStorage, game.ServerScriptService, game.StarterPlayer.StarterPlayerScripts
local function has(p) local cur = game for s in p:gmatch("[^%.]+") do cur = cur and cur:FindFirstChild(s) end return cur end
local r = {}
for _, p in ipairs({"ReplicatedStorage.Shared.CutsceneDirector","ReplicatedStorage.Shared.Credits","ReplicatedStorage.StoryDialogue","ReplicatedStorage.CharacterModels","ReplicatedStorage.SegSources","ServerScriptService.RoundManager","ServerScriptService.Modules.AvatarSlots","ServerScriptService.Arena","StarterPlayer.StarterPlayerScripts.AnimeStyle","StarterPlayer.StarterPlayerScripts.CreditsUI","StarterPlayer.StarterPlayerScripts.IntroCutscene","Workspace.WorldOfVoid"}) do
	r[#r+1] = p .. "=" .. tostring(has(p) ~= nil)
end
local cm = RS:FindFirstChild("CharacterModels")
if cm then local t = {} for _, c in ipairs(cm:GetChildren()) do t[#t+1] = c.Name .. (c:FindFirstChild("Segments") and "[seg]" or "") end r[#r+1] = "CM:" .. table.concat(t, ",") end
local cd = has("ReplicatedStorage.Shared.CutsceneDirector"); r[#r+1] = "camflip=" .. tostring(cd and cd.Source:find("flipped to face") ~= nil)
local as = has("StarterPlayer.StarterPlayerScripts.AnimeStyle"); r[#r+1] = "outline25=" .. tostring(as and as.Source:find("MAX_OUTLINES = 25") ~= nil)
local n = 0 for _ in ipairs(SSS:GetDescendants()) do n += 1 end r[#r+1] = "SSSdesc=" .. n
local ws = {} for _, c in ipairs(workspace:GetChildren()) do ws[#ws+1] = c.Name end r[#r+1] = "WS:" .. table.concat(ws, ",")
return table.concat(r, "\n")
