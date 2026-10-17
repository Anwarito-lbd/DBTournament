--!strict
-- ModuleScript: ServerScriptService.Modules.DevBots  (v1 dev mode)
-- Training dummy bots so a solo Studio play test can run a full match: spawn on an enemy universe,
-- walk to the nearest enemy and punch, take damage + knockback from Combat, ring-out below LowY.
-- Bots live in workspace.DevBots; attributes: Team (team name), Universe, Alive, IsBot.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DevBots = {}
local bots: { [Model]: { team: Team, alive: boolean, lowSince: number?, lastAtk: number, lastAttacker: Player? } } = {}
local onEliminated: ((Model, Player?, string) -> ())? = nil
local function rootOf(m: Model): BasePart? return m:FindFirstChild("HumanoidRootPart") :: BasePart? end
local NAMES = { "Training Saibaman", "Training Cell Jr.", "Training Frieza Soldier" }

local function folder(): Folder
	local f = workspace:FindFirstChild("DevBots")
	if not f then f = Instance.new("Folder"); f.Name = "DevBots"; f.Parent = workspace end
	return f :: Folder
end

function DevBots.setEliminatedCallback(fn: (Model, Player?, string) -> ()) onEliminated = fn end

local function lowY(): number
	local b = CollectionService:GetTagged("RingBounds")[1]
	return (b and b:GetAttribute("LowY") :: number?) or Config.RINGOUT.lowY
end

local function eliminate(m: Model, reason: string)
	local b = bots[m]
	if not b or not b.alive then return end
	b.alive = false
	m:SetAttribute("Alive", false)
	if onEliminated then onEliminated(m, b.lastAttacker, reason) end
	task.delay(3, function() if m.Parent then m:Destroy() end end)
end

local function makeBot(i: number): Model
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromRGB(120, 170, 90); desc.TorsoColor = Color3.fromRGB(70, 110, 60)
	desc.LeftArmColor = desc.HeadColor; desc.RightArmColor = desc.HeadColor
	desc.LeftLegColor = desc.TorsoColor; desc.RightLegColor = desc.TorsoColor
	local ok, m = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	local model: Model
	if ok and m then
		model = m
	else -- fallback: simple block dummy
		model = Instance.new("Model")
		local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Transparency = 1; root.Parent = model
		local torso = Instance.new("Part"); torso.Name = "Torso"; torso.Size = Vector3.new(2, 3, 1); torso.Color = desc.TorsoColor; torso.Parent = model
		local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = torso; w.Parent = root
		Instance.new("Humanoid").Parent = model
		model.PrimaryPart = root
	end
	model.Name = NAMES[(i - 1) % #NAMES + 1] .. (if i > #NAMES then " " .. i else "")
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.MaxHealth = Config.DEV_BOT_HP; hum.Health = Config.DEV_BOT_HP
	hum.WalkSpeed = 12
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	return model
end

-- Spawns n bots on `team` at the given arena spawn CFrame.
-- keep=true (D19 small-lobby fill): add to existing bots instead of clearing (bots on several teams).
function DevBots.spawn(n: number, team: Team, at: CFrame, keep: boolean?)
	if not keep then DevBots.clear() end
	local base = 0
	for _ in bots do base += 1 end
	for i = 1, math.clamp(n, 1, 3) do
		local m = makeBot(base + i)
		m:SetAttribute("IsBot", true)
		m:SetAttribute("Team", team.Name)
		m:SetAttribute("Universe", team:GetAttribute("Universe"))
		m:SetAttribute("Alive", true)
		m:PivotTo(at * CFrame.new((i - 2) * 8, 5, (i % 2) * 6 - 3))
		m:SetAttribute("SpawnIndex", i)
		m.Parent = folder()
		local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
		bots[m] = { team = team, alive = true, lowSince = nil, lastAtk = 0, lastAttacker = nil }
		hum.Died:Connect(function() eliminate(m, "KO") end)
	end
end

-- Re-place bots on their spawn (called right before the fight starts, in case one slipped during the intro).
function DevBots.placeAll(at: CFrame)
	for m, b in bots do
		local r = rootOf(m)
		local hum = m:FindFirstChildOfClass("Humanoid")
		if b.alive and r and hum then
			local i = (m:GetAttribute("SpawnIndex") :: number?) or 1
			r.AssemblyLinearVelocity = Vector3.zero
			m:PivotTo(at * CFrame.new((i - 2) * 8, 5, (i % 2) * 6 - 3))
			hum.Health = hum.MaxHealth
		end
	end
end

function DevBots.clear()
	for m in bots do if m.Parent then m:Destroy() end end
	table.clear(bots)
end

function DevBots.aliveOn(team: Team): number
	local n = 0
	for _, b in bots do if b.alive and b.team == team then n += 1 end end
	return n
end
-- D17 tiebreak: summed HP fraction of a team's living bots.
function DevBots.hpOn(team: Team): number
	local h = 0
	for m, b in bots do
		local hum = b.alive and b.team == team and m:FindFirstChildOfClass("Humanoid")
		if hum and hum.MaxHealth > 0 then h += math.max(0, hum.Health) / hum.MaxHealth end
	end
	return h
end
function DevBots.any(): boolean return next(bots) ~= nil end


-- Same ray/melee shape as Combat.findTarget, against bots on other teams.
function DevBots.hitScan(att: Player, mv: any, targetPos: Vector3): (Model?, Vector3)
	local ar = att.Character and att.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not ar then return nil, targetPos end
	local from = ar.Position
	local dir = targetPos - from
	dir = if dir.Magnitude > 0.01 then dir.Unit else ar.CFrame.LookVector
	local best, bestD = nil, math.huge
	for m, b in bots do
		local r = rootOf(m)
		if b.alive and r and b.team ~= att.Team then
			local rel = r.Position - from
			if mv.kind == "melee" then
				local d = rel.Magnitude
				if d <= (mv.range or 7) + 2.5 and (d < 2 or dir:Dot(rel.Unit) >= 0.3) and d < bestD then best, bestD = m, d end
			elseif mv.kind == "ray" then
				local along = rel:Dot(dir)
				if along > 0 and along <= mv.range then
					local perp = (rel - dir * along).Magnitude
					if perp <= (mv.width or 1) + 2.5 and along < bestD then best, bestD = m, along end
				end
			end
		end
	end
	if best then return best, (rootOf(best) :: BasePart).Position end
	return nil, targetPos
end

function DevBots.hit(att: Player, m: Model, mv: any, power: number)
	local b = bots[m]
	local hum = m:FindFirstChildOfClass("Humanoid")
	local r = rootOf(m)
	if not b or not b.alive or not hum or not r then return end
	b.lastAttacker = att
	local dmg = (mv.damage or 5) * (power or 1)
	hum:TakeDamage(dmg)
	-- v1.1 GameFeel hit event (bot victims are sent as the Model instance)
	pcall(function()
		(game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CombatEvent") :: RemoteEvent):FireAllClients("Hit",
			{ m, att.UserId, math.floor(dmg + 0.5), (mv.kb or 0) * (power or 1), hum.Health <= 0 })
	end)
	local ar = att.Character and att.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if ar and (mv.kb or 0) > 0 then
		local d = r.Position - ar.Position
		d = Vector3.new(d.X, 0, d.Z)
		d = if d.Magnitude > 0.01 then d.Unit else Vector3.new(1, 0, 0)
		local missing = 1 - hum.Health / math.max(1, hum.MaxHealth)
		local kb = mv.kb * (1 + 1.5 * missing) * 1.6
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		-- 4th-hit finishers (Shared/FightRules): launch straight up, spike down, or a longer knockdown
		local vel = d * kb + Vector3.new(0, kb * 0.35, 0)
		if mv.up then vel = d * kb + Vector3.new(0, mv.up, 0) elseif mv.down then vel = d * kb + Vector3.new(0, -mv.down, 0) end
		r.AssemblyLinearVelocity = vel
		m:SetAttribute("KnockedDown", if mv.knockdown then true else nil)
		task.delay(mv.knockdown or 0.6, function()
			if hum.Parent and hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			if m.Parent then m:SetAttribute("KnockedDown", nil) end
		end)
	end
end

function DevBots.hitRadius(att: Player, pos: Vector3, mv: any)
	for m, b in bots do
		local r = rootOf(m)
		if b.alive and r and b.team ~= att.Team and (r.Position - pos).Magnitude <= (mv.radius or 10) then DevBots.hit(att, m, mv, 1) end
	end
end

-- Called ~10 Hz by RoundManager while InRound: ring-out check + simple chase/punch AI.
function DevBots.tick(inRound: boolean)
	local ly = lowY()
	for m, b in bots do
		local r = rootOf(m)
		local hum = m:FindFirstChildOfClass("Humanoid")
		if b.alive and r and hum then
			if r.Position.Y < ly then
				if not b.lowSince then b.lowSince = os.clock()
				elseif os.clock() - b.lowSince > 1 then eliminate(m, "RingOut") end
			else
				b.lowSince = nil
			end
			if inRound and b.alive and hum.Health > 0 then
				local best, bestD = nil, math.huge
				for _, p in Players:GetPlayers() do
					local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if pr and p.Team ~= b.team and p:GetAttribute("Alive") == true then
						local d = (pr.Position - r.Position).Magnitude
						if d < bestD then best, bestD = p, d end
					end
				end
				if best then
					local pr = (best.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
					if bestD > 5 then hum:MoveTo(pr.Position) else hum:MoveTo(r.Position) end
					if bestD <= 6 and os.clock() - b.lastAtk > 1.5 then
						b.lastAtk = os.clock()
						local ph = (best.Character :: Model):FindFirstChildOfClass("Humanoid")
						if ph and best:GetAttribute("Blocking") ~= true then ph:TakeDamage(3) end
					end
				end
			end
		end
	end
end

-- Studio-only test hook (execute_luau runs in its own module context, so tests spawn bots through this)
if game:GetService("RunService"):IsStudio() then
	local ss = game:GetService("ServerStorage")
	local f = ss:FindFirstChild("DevHooks") or Instance.new("Folder"); f.Name = "DevHooks"; f.Parent = ss
	local bf = f:FindFirstChild("SpawnBot") or Instance.new("BindableFunction"); bf.Name = "SpawnBot"; bf.Parent = f
	;(bf :: BindableFunction).OnInvoke = function(n, team, at) DevBots.spawn(n, team, at); return true end
end

return DevBots
