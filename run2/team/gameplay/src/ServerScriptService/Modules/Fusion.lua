--!strict
-- ModuleScript: ServerScriptService.Modules.Fusion
-- Fusion Dance / Potara, fully server-validated.
-- Client: Remotes.FusionRequest(method: "Dance"|"Potara", partnerUserId) — both players must request each other
-- (same method) within RequestTTL. Remotes.FusionCancel(). Server -> client: Remotes.FusionState(state, data).
-- Dance: both stand still within DanceRange for DanceChannel s; any damage taken or moving cancels.
-- Potara: requires "Potara" unlock (level 35 power-up or PotaraEarrings pass) on either player; within PotaraRange, PotaraChannel s.
-- Result: higher Power Level player controls the fused character; partner becomes passenger (anchored at stands, spectating).
-- End: timer -> both restored next to each other (HP split by fused HP%); controller eliminated -> passenger eliminated too.
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local Combatant = require(script.Parent.Combatant)
local Arena = require(script.Parent.Arena)
local TeamAssignment = require(script.Parent.TeamAssignment)

local Fusion = {}

local FusionRequest = Net.remote("FusionRequest")
local FusionCancel = Net.remote("FusionCancel")
local FusionState = Net.remote("FusionState")
local FusedHook = Net.hook("Fused") -- (controller, passenger, fusionId, method)
local DefusedHook = Net.hook("Defused") -- (controller, passenger, reason)
local DamagedHook = Net.hook("PlayerDamaged")

local F = Config.FUSION
type Req = { to: Player, method: string, t: number }
type Fused = { passenger: Player, id: string, untilT: number, maxHP: number, pMaxHP: number }
local requests: { [Player]: Req } = {}
local channeling: { [Player]: { partner: Player, hit: boolean } } = {}
local fused: { [Player]: Fused } = {} -- controller -> data
local passengerOf: { [Player]: Player } = {} -- passenger -> controller
local cooldownUntil: { [Player]: number } = {}

local function humOf(p: Player): Humanoid?
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end
local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function dist(a: Player, b: Player): number
	local ra, rb = rootOf(a), rootOf(b)
	return if ra and rb then (ra.Position - rb.Position).Magnitude else math.huge
end
local function busy(p: Player): boolean
	return fused[p] ~= nil or passengerOf[p] ~= nil or channeling[p] ~= nil
end

local function eligible(a: Player, b: Player, method: string): string?
	if workspace:GetAttribute("RoundState") ~= "InRound" then return "NotInRound" end
	if workspace:GetAttribute("Ranked") == true and workspace:GetAttribute("RankedFormat") == "1v1" then return "Ranked1v1" end -- D20
	if a == b or a.Team ~= b.Team or a.Team == nil then return "NotTeammates" end
	for _, p in { a, b } do
		if p:GetAttribute("Alive") ~= true then return "NotAlive" end
		local h = humOf(p)
		if not h or h.Health <= 0 then return "NotAlive" end
		if busy(p) then return "Busy" end
		if (cooldownUntil[p] or 0) > os.clock() then return "Cooldown" end
	end
	local ca, cb = Combatant.activeCharacter(a), Combatant.activeCharacter(b)
	if not ca or not cb or not Config.fusionFor(ca, cb, method) then return "NoFusionForPair" end
	local range = if method == "Dance" then F.DanceRange else F.PotaraRange
	if dist(a, b) > range then return "TooFar" end
	if method == "Potara" and not (PlayerData.hasUnlock(a, "Potara") or PlayerData.hasUnlock(b, "Potara")) then
		return "NeedPotara"
	end
	return nil
end

local function notify(p: Player, state: string, data: any?)
	p:SetAttribute("FusionState", state)
	FusionState:FireClient(p, state, data)
end

local function fail(a: Player, b: Player, why: string)
	channeling[a] = nil; channeling[b] = nil
	for _, p in { a, b } do
		cooldownUntil[p] = os.clock() + F.FailCooldown
		if p.Parent then notify(p, "Failed", why) end
	end
end

local function complete(a: Player, b: Player, method: string)
	channeling[a] = nil; channeling[b] = nil
	local why = eligible(a, b, method)
	if why and why ~= "Busy" then fail(a, b, why); return end
	local ca, cb = Combatant.activeCharacter(a) :: string, Combatant.activeCharacter(b) :: string
	local id = Config.fusionFor(ca, cb, method) :: string
	local controller, passenger = a, b
	if Combatant.powerLevel(b, false) > Combatant.powerLevel(a, false) then controller, passenger = b, a end
	local ch, ph = humOf(controller) :: Humanoid, humOf(passenger) :: Humanoid
	local data: Fused = {
		passenger = passenger, id = id,
		untilT = os.clock() + (if method == "Dance" then F.DanceDuration else F.PotaraDuration),
		maxHP = ch.MaxHealth, pMaxHP = ph.MaxHealth,
	}
	fused[controller] = data
	passengerOf[passenger] = controller
	-- fused HP = avg * (1 + bonus)
	local avgMax = (ch.MaxHealth + ph.MaxHealth) / 2
	local avgHP = (ch.Health + ph.Health) / 2
	ch.MaxHealth = avgMax * (1 + F.HealthBonus)
	ch.Health = math.min(ch.MaxHealth, avgHP * (1 + F.HealthBonus))
	Combatant.setFusion(controller, id)
	-- passenger: park at own universe stand, anchored, spectating the controller
	Arena.teleport(passenger, "Stand", TeamAssignment.universeOf(passenger))
	local pr = rootOf(passenger)
	if pr then pr.Anchored = true end
	passenger:SetAttribute("FusedPassenger", true)
	passenger:SetAttribute("Spectating", true)
	passenger:SetAttribute("SpectateTarget", controller.UserId)
	controller:SetAttribute("FusionPartner", passenger.UserId)
	notify(controller, "FusedController", { id = id, duration = data.untilT - os.clock() })
	notify(passenger, "FusedPassenger", { id = id, controller = controller.UserId })
	FusedHook:Fire(controller, passenger, id, method)
end

local function startChannel(a: Player, b: Player, method: string)
	channeling[a] = { partner = b, hit = false }
	channeling[b] = { partner = a, hit = false }
	local dur = if method == "Dance" then F.DanceChannel else F.PotaraChannel
	notify(a, "Channeling", { method = method, duration = dur, partner = b.UserId })
	notify(b, "Channeling", { method = method, duration = dur, partner = a.UserId })
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			task.wait(0.1)
			local ca, cb = channeling[a], channeling[b]
			if not ca or not cb then fail(a, b, "Cancelled"); return end
			if ca.hit or cb.hit then fail(a, b, "Interrupted"); return end
			if not a.Parent or not b.Parent then fail(a, b, "Left"); return end
			if a:GetAttribute("Alive") ~= true or b:GetAttribute("Alive") ~= true then fail(a, b, "NotAlive"); return end
			local range = if method == "Dance" then F.DanceRange else F.PotaraRange
			if dist(a, b) > range then fail(a, b, "TooFar"); return end
			if method == "Dance" and (not Combatant.isStill(a) or not Combatant.isStill(b)) then fail(a, b, "Moved"); return end
		end
		complete(a, b, method)
	end)
end

FusionRequest.OnServerEvent:Connect(function(p, method, partnerId)
	if not RateLimit.allow(p, "fusion", 1, 3) then return end
	if (method ~= "Dance" and method ~= "Potara") or type(partnerId) ~= "number" then return end
	local partner = Players:GetPlayerByUserId(partnerId)
	if not partner then return end
	local why = eligible(p, partner, method)
	if why then notify(p, "Rejected", why); return end
	requests[p] = { to = partner, method = method, t = os.clock() }
	local back = requests[partner]
	if back and back.to == p and back.method == method and os.clock() - back.t <= F.RequestTTL then
		requests[p] = nil; requests[partner] = nil
		startChannel(partner, p, method)
	else
		notify(p, "Requested", { partner = partnerId, method = method })
		FusionState:FireClient(partner, "Invited", { from = p.UserId, method = method })
	end
end)

FusionCancel.OnServerEvent:Connect(function(p)
	requests[p] = nil
	local c = channeling[p]
	if c then channeling[p] = nil end -- loop detects and fails both
end)

DamagedHook.Event:Connect(function(victim: Player)
	local c = channeling[victim]
	if c then c.hit = true end
end)

-- Restore both after the timer (or early defuse while controller alive).
function Fusion.defuse(controller: Player, reason: string)
	local data = fused[controller]
	if not data then return end
	fused[controller] = nil
	local passenger = data.passenger
	passengerOf[passenger] = nil
	local ch = humOf(controller)
	local frac = if ch and ch.MaxHealth > 0 then ch.Health / ch.MaxHealth else 1
	if ch then ch.MaxHealth = data.maxHP; ch.Health = math.max(1, data.maxHP * frac) end
	Combatant.setFusion(controller, nil)
	controller:SetAttribute("FusionPartner", nil)
	if passenger.Parent then
		local pr, cr = rootOf(passenger), rootOf(controller)
		if pr then
			pr.Anchored = false
			if cr then pr.CFrame = cr.CFrame * CFrame.new(4, 0, 0) end
		end
		local ph = humOf(passenger)
		if ph then ph.MaxHealth = data.pMaxHP; ph.Health = math.max(1, data.pMaxHP * frac) end
		passenger:SetAttribute("FusedPassenger", nil)
		passenger:SetAttribute("Spectating", false)
		passenger:SetAttribute("SpectateTarget", nil)
		notify(passenger, "Defused", reason)
	end
	if controller.Parent then notify(controller, "Defused", reason) end
	DefusedHook:Fire(controller, passenger, reason)
end

-- Called by RoundManager when `p` is eliminated. Returns the passenger that must also be eliminated (if any).
function Fusion.onEliminated(p: Player): Player?
	requests[p] = nil
	if channeling[p] then channeling[p] = nil end
	local data = fused[p]
	if data then
		fused[p] = nil
		local passenger = data.passenger
		passengerOf[passenger] = nil
		p:SetAttribute("FusionPartner", nil)
		local pr = rootOf(passenger)
		if pr then pr.Anchored = false end
		passenger:SetAttribute("FusedPassenger", nil)
		DefusedHook:Fire(p, passenger, "ControllerEliminated")
		return passenger
	end
	local controller = passengerOf[p]
	if controller then Fusion.defuse(controller, "PassengerLeft") end
	return nil
end

-- D20: a disconnect defuses at once (the remaining player keeps the body's HP%); it never eliminates the partner.
function Fusion.onLeave(p: Player)
	requests[p] = nil; channeling[p] = nil
	if fused[p] then Fusion.defuse(p, "Disconnect") return end
	local controller = passengerOf[p]
	if controller then Fusion.defuse(controller, "Disconnect") end
end
function Fusion.wasFused(p: Player): boolean return fused[p] ~= nil or passengerOf[p] ~= nil end

function Fusion.isPassenger(p: Player): boolean return passengerOf[p] ~= nil end

function Fusion.tick()
	local now = os.clock()
	for controller, data in fused do
		if now >= data.untilT then Fusion.defuse(controller, "Timeout") end
	end
end

function Fusion.resetRound()
	for controller in fused do Fusion.defuse(controller, "RoundEnd") end
	table.clear(requests); table.clear(channeling); table.clear(cooldownUntil)
end

Players.PlayerRemoving:Connect(function(p)
	requests[p] = nil
	channeling[p] = nil
	cooldownUntil[p] = nil
end)

return Fusion
