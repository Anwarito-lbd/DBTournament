--!strict
-- ModuleScript: ServerScriptService.Modules.Arena
-- Integration with db-map (map/layout_spec.md v1.1, map/ArenaDamage.lua):
--   * spawns via CollectionService tags ArenaSpawn / StandSpawn / LobbySpawn (attribute Universe = "U07"), with folder fallback
--   * ring-out: touching a non-ring surface (ArenaDamage.IsRingSurface == false) OR root Y < LowY for > LowGrace s
--   * DamageAt / Reset wrappers (no-op if ServerScriptService.ArenaDamage is not installed)
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local ToPLogic = require(game:GetService("ReplicatedStorage").Shared.ToPLogic)

local Arena = {}

local AD: any = nil
do
	local m = ServerScriptService:FindFirstChild("ArenaDamage")
	if m and m:IsA("ModuleScript") then
		local ok, res = pcall(require, m)
		if ok then AD = res else warn("[Arena] ArenaDamage failed to load: " .. tostring(res)) end
	end
end

function Arena.hasArenaDamage(): boolean return AD ~= nil end

function Arena.damageAt(pos: Vector3, radius: number, power: number): number
	if not AD then return 0 end
	local ok, n = pcall(AD.DamageAt, pos, radius, power)
	return if ok then n else 0
end

function Arena.reset()
	if AD then
		local ok, err = pcall(AD.Reset)
		if not ok then warn("[Arena] Reset failed: " .. tostring(err)) end
	end
end

-- ===== db-map Arena.Resize(teamCount, playerCount) =====
-- Looks for a server ModuleScript exposing Resize: ServerScriptService.Arena (db-map), else ArenaDamage.Resize.
-- pcall-guarded; missing = no-op. Afterwards references are refreshed (ArenaDamage re-Init, ring-out timers).
local teamIndex: { [number]: number } = {} -- universe number -> Arena team index (spawn attr Team)
function Arena.resize(teamCount: number, playerCount: number, teams: { Team }?): boolean
	table.clear(teamIndex)
	if teams then for i, t in teams do local u = t:GetAttribute("Universe"); if type(u) == "number" then teamIndex[u] = i end end end
	local resizer: any = nil
	local m = ServerScriptService:FindFirstChild("Arena")
	if m and m:IsA("ModuleScript") then
		local ok, res = pcall(require, m)
		if ok and type(res) == "table" and type(res.Resize) == "function" then resizer = res end
	end
	if not resizer and AD and type(AD.Resize) == "function" then resizer = AD end
	if not resizer then return false end
	-- v3: 3rd arg = display universe number per team index (U7 = largest human team, see TeamAssignment)
	local nums: { number }? = nil
	if teams then
		nums = {}
		for i, t in teams do (nums :: { number })[i] = (t:GetAttribute("Universe") :: number?) or i end
	end
	local ok, err = pcall(resizer.Resize, teamCount, playerCount, nums)
	if not ok then warn("[Arena] Resize failed: " .. tostring(err)); return false end
	Arena.refresh()
	Arena.spawnNPCs()
	return true
end

-- Re-scan after map changes: chunks (ArenaDamage.Init), and drop cached ring-out timers.
-- Spawns and RingBounds (LowY/LowGrace) are read live from CollectionService on every call.
local lowSinceRef: { [Player]: number }? = nil
function Arena.refresh()
	-- art pass first (recolours chunks), so ArenaDamage.Init records the final look for Reset()
	local ap = ServerScriptService:FindFirstChild("ArtPass")
	if ap and ap:IsA("ModuleScript") then
		local ok, res = pcall(function() return (require(ap) :: any).Apply() end)
		if not ok then warn("[Arena] ArtPass failed: " .. tostring(res)) end
	end
	if AD and type(AD.Init) == "function" then pcall(AD.Init) end
	if lowSinceRef then table.clear(lowSinceRef) end
end

-- ===== Spawns =====
local function uTag(u: number): string return string.format("U%02d", u) end

local function tagged(tag: string, universe: number?): { BasePart }
	local out = {}
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
			if universe == nil or inst:GetAttribute("Universe") == uTag(universe) then table.insert(out, inst) end
		end
	end
	return out
end

local function folderSpawns(name: string): { BasePart }
	local out = {}
	local f = workspace:FindFirstChild(name)
	if f then for _, c in f:GetChildren() do if c:IsA("BasePart") then table.insert(out, c) end end end
	return out
end

-- kind: "Arena" | "Stand" | "Lobby"
function Arena.spawnFor(kind: string, universe: number?, index: number?): BasePart?
	local list: { BasePart }
	if kind == "Arena" then
		-- v2 layout: Spawn_Ring_01..P with Team (arena team index) + Slot; one pad per fighter
		local ti = universe and teamIndex[universe]
		if ti then
			local mine = {}
			for _, inst in CollectionService:GetTagged("ArenaSpawn") do
				if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) and inst:GetAttribute("Team") == ti then table.insert(mine, inst) end
			end
			table.sort(mine, function(a, b) return ((a:GetAttribute("Slot") :: number?) or 0) < ((b:GetAttribute("Slot") :: number?) or 0) end)
			if #mine > 0 then return mine[((index or 1) - 1) % #mine + 1] end
		end
		list = if universe then tagged("ArenaSpawn", universe) else {}
		if #list == 0 then list = tagged("ArenaSpawn") end
		if #list == 0 then list = folderSpawns("ArenaSpawns") end
	elseif kind == "Stand" then
		list = if universe then tagged("StandSpawn", universe) else {}
		if #list == 0 then list = tagged("StandSpawn") end
		if #list == 0 then list = folderSpawns("LobbySpawns") end
	else
		list = tagged("LobbySpawn")
		if #list == 0 then list = folderSpawns("LobbySpawns") end
	end
	if #list == 0 then return nil end
	return list[((index or math.random(1, #list)) - 1) % #list + 1]
end

-- slot: 1-based position within the team; spreads up to MAX_TEAM_SIZE players around a single pad.
-- ===== db-story: erased universe -> its stand disappears (server), restored at round cleanup =====
local hiddenStands: { [number]: { { part: BasePart, t: number, cc: boolean, cq: boolean, ct: boolean } } } = {}
local function standFolders(universe: number): { Instance }
	local out, ti = {}, teamIndex[universe]
	for _, inst in workspace:GetDescendants() do
		if (inst:IsA("Folder") or inst:IsA("Model")) and inst.Name:match("^Stand_U%d+$")
			and (inst:GetAttribute("UniverseNumber") == universe or (inst:GetAttribute("UniverseNumber") == nil and ti ~= nil and inst:GetAttribute("Team") == ti)) then
			table.insert(out, inst)
		end
	end
	return out
end
function Arena.hideStand(universe: number)
	if hiddenStands[universe] then return end
	local saved = {}
	for _, f in standFolders(universe) do
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(saved, { part = d, t = d.Transparency, cc = d.CanCollide, cq = d.CanQuery, ct = d.CanTouch })
				d.Transparency = 1; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
			end
		end
	end
	hiddenStands[universe] = saved
end
function Arena.isStandHidden(universe: number?): boolean return universe ~= nil and hiddenStands[universe] ~= nil end
function Arena.restoreStands()
	for _, saved in hiddenStands do
		for _, e in saved do
			if e.part.Parent then e.part.Transparency = e.t; e.part.CanCollide = e.cc; e.part.CanQuery = e.cq; e.part.CanTouch = e.ct end
		end
	end
	table.clear(hiddenStands)
end

function Arena.teleport(p: Player, kind: string, universe: number?, index: number?, slot: number?)
	if kind == "Stand" and Arena.isStandHidden(universe) then kind, universe = "Lobby", nil end -- erased stand is gone
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local sp = Arena.spawnFor(kind, universe, index or slot)
	if not root or not sp then return end
	-- spread around the pad (ring pads are single per universe)
	local off
	if slot and kind == "Arena" and universe and teamIndex[universe] then
		off = Vector3.new(0, 4, 0) -- own pad
	elseif slot then
		local a = (slot - 1) * (2 * math.pi / Config.MAX_TEAM_SIZE)
		off = Vector3.new(math.cos(a) * 7, 4, math.sin(a) * 7)
	elseif kind == "Arena" then
		off = Vector3.new(math.random(-6, 6), 4, math.random(-6, 6))
	else
		off = Vector3.new(math.random(-3, 3), 4, math.random(-3, 3))
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = sp.CFrame + off
end

-- ===== Ring-out =====
local lowSince: { [Player]: number } = {}
lowSinceRef = lowSince

local function boundsCfg(): (number, number)
	local lowY, grace = Config.RINGOUT.lowY, Config.RINGOUT.lowGrace
	local b = CollectionService:GetTagged("RingBounds")[1]
	if b then
		lowY = (b:GetAttribute("LowY") :: number?) or lowY
		grace = (b:GetAttribute("LowGrace") :: number?) or grace
	end
	return lowY, grace
end

local IGNORE_TAGS = { "Debris", "RingOutZone", "RingBounds", "ArenaCeiling", "ArenaSpawn" } -- ring spawn pads sit on the ring

local function countsAsSurface(part: BasePart): boolean
	if not part.CanCollide or not part.CanTouch then return false end -- debris/FX are CanTouch=false
	if part:FindFirstAncestorOfClass("Model") and part:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") then
		return false -- other characters
	end
	for _, t in IGNORE_TAGS do if CollectionService:HasTag(part, t) then return false end end
	-- pillars still standing on the ring are cover, not ring-out (map: "pillars-off-ring" count)
	if CollectionService:HasTag(part, "ArenaCover") then
		local pos = part.Position
		local b = CollectionService:GetTagged("RingBounds")[1]
		local ringR = (b and b:GetAttribute("RingRadius") :: number?) or 150
		if Vector2.new(pos.X, pos.Z).Magnitude <= ringR and pos.Y > 480 then return false end
	end
	return true
end

-- Returns reason string if rung out, else nil. Call ~10 Hz per alive fighter.
function Arena.checkRingOut(p: Player): string?
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not root then return nil end
	if not AD and not next(CollectionService:GetTagged("RingBounds")) then
		-- no db-map arena installed: legacy fallback
		lowSince[p] = nil
		return if root.Position.Y < Config.RING_OUT_Y then "RingOut" else nil
	end
	-- Rule 2: below LowY continuously for > LowGrace
	local lowY, grace = boundsCfg()
	if root.Position.Y < lowY then
		local t = lowSince[p]
		if not t then lowSince[p] = os.clock()
		elseif os.clock() - t > grace then return "RingOut" end
	else
		lowSince[p] = nil
	end
	-- Rule 1: touching a surface that is not an attached ring chunk
	if AD then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }
		local cf, size = char:GetBoundingBox()
		for _, part in workspace:GetPartBoundsInBox(cf, size + Vector3.new(0.5, 0.5, 0.5), params) do
			-- v3: Detached chunks are CanTouch=false (skipped below) but standing on one = ring-out
			local st = part:GetAttribute("DamageStage")
			if st ~= nil and ToPLogic.chunkRingOut(st :: number?, part:GetAttribute("Detached") == true) then return "RingOut" end
			if countsAsSurface(part) and not AD.IsRingSurface(part) then return "RingOut" end
		end
	end
	return nil
end

function Arena.clearRingOut(p: Player) lowSince[p] = nil end

-- ===== v3 arena NPCs (Bulma + spectator gods/angels/kaioshin) =====
-- Spawned at ArenaNPCSpot parts after Resize; spots with CutsceneId (Zeno box) belong to the cutscene director.
local npcFolder: Folder? = nil
function Arena.clearNPCs()
	if npcFolder then npcFolder:Destroy(); npcFolder = nil end
end
local function makeNPC(spot: BasePart, name: string): Model
	local m = Instance.new("Model"); m.Name = name
	local torso = Instance.new("Part"); torso.Name = "HumanoidRootPart"; torso.Size = Vector3.new(2, 2, 1)
	torso.Anchored = true; torso.CanCollide = false; torso.CanQuery = false; torso.CanTouch = false
	torso.CFrame = spot.CFrame + Vector3.new(0, spot.Size.Y / 2 + 3, 0); torso.Parent = m
	local head = Instance.new("Part"); head.Name = "Head"; head.Shape = Enum.PartType.Ball; head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Anchored = true; head.CanCollide = false; head.CanQuery = false; head.CanTouch = false
	head.CFrame = torso.CFrame + Vector3.new(0, 1.6, 0); head.Parent = m
	local hum = Instance.new("Humanoid"); hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.Parent = m
	m.PrimaryPart = torso
	return m
end
function Arena.spawnNPCs(): number
	Arena.clearNPCs()
	local f = Instance.new("Folder"); f.Name = "ArenaNPCs"; npcFolder = f
	local n = 0
	for _, spot in CollectionService:GetTagged("ArenaNPCSpot") do
		if spot:IsA("BasePart") and spot:IsDescendantOf(workspace) and spot:GetAttribute("CutsceneId") == nil then
			local name = (spot:GetAttribute("NPC") :: string?) or spot.Name
			local m = makeNPC(spot, name)
			for _, a in { "NPC", "UniverseNumber", "Team" } do m:SetAttribute(a, spot:GetAttribute(a)) end
			m:SetAttribute("Cheer", CollectionService:HasTag(spot, "BulmaCheerSpot"))
			CollectionService:AddTag(m, "ArenaNPC") -- db-animation hook (idle/cheer)
			m.Parent = f; n += 1
		end
	end
	f.Parent = workspace
	return n
end

return Arena
