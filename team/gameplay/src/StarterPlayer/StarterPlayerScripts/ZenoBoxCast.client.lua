-- LocalScript: ZenoBoxCast. The Tournament of Power's ever-present cast, always in Zeno's box while the arena exists:
-- Zeno and Future Zeno on their thrones, the Grand Priest front-left, the two attendants behind (CastFigures rigs,
-- placed with CutsceneDirector.castLayout so cutscenes line up). Cutscenes adopt these figures instead of building
-- copies and put them back afterwards. Visual only and local; rebuilt whenever the arena is resized.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CastFigures = require(Shared:WaitForChild("CastFigures"))
local Director = require(Shared:WaitForChild("CutsceneDirector"))

local folder: Folder? = nil
local builtFor: Vector3? = nil

local function clear()
	if folder then folder:Destroy() end
	folder, builtFor = nil, nil
end

local function build(zenoPos: Vector3)
	clear()
	local f = Instance.new("Folder")
	f.Name = "ZenoBoxCast"
	for id, e in Director.castLayout() do
		local m = CastFigures.build(e.kind, e.cf, e.height, e.seated)
		m.Name = id
		m:SetAttribute("Persistent", true)
		m.Parent = f
	end
	f.Parent = workspace
	folder, builtFor = f, zenoPos
end

-- idle life: now and then a Zeno glances around (skipped while a cutscene has borrowed the figure)
task.spawn(function()
	while true do
		task.wait(3 + math.random() * 4)
		local f = folder
		if f then
			local z = f:FindFirstChild(if math.random() < 0.5 then "npc_zeno" else "npc_zeno_future")
			if z and z:IsA("Model") and z:GetAttribute("HomePivot") == nil then CastFigures.anim(z, "Look") end
		end
	end
end)

while true do
	local wov = workspace:FindFirstChild("WorldOfVoid")
	local arena = wov and wov:FindFirstChild("Arena")
	local zp = arena and arena:GetAttribute("ZenoPos")
	if typeof(zp) == "Vector3" then
		if builtFor ~= zp then build(zp) end
	elseif folder then
		clear()
	end
	task.wait(2)
end
