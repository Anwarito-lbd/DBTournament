--!strict
-- ModuleScript: ServerScriptService.Modules.Combat  (v4: skill expression + compressed balance)
-- Every action is client INTENT -> server validates state, cooldown, ki, range, timing.
-- Remotes (client -> server):
--   RequestMove(moveId, targetPos, origin?, branch?)  Block(isDown)  Dash(dir)  Vanish(dir?)  ComboBreak()  StruggleInput()
--   (branch: "up" / "down" hint for the 4th M1 of a chain; see Shared/FightRules)
-- Remotes (server -> client): PlayVFX(kind, character, arg)  CombatEvent(kind, data)  TeamCombo(...)
-- Balance: damage ratio = clamp((PL_att/PL_vic)^0.25, 1/1.35, 1.35)  (tier gap compression)
-- Counterplay by tier (Config.TIER_RULES): hurtbox scale, ki regen, recovery.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ToPLogic = require(game:GetService("ReplicatedStorage").Shared.ToPLogic)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local Combatant = require(script.Parent.Combatant)
local Arena = require(script.Parent.Arena)
local DevBots = require(script.Parent.DevBots) -- v1 dev mode training bots
local RaceRuntime = require(script.Parent.RaceRuntime) -- v6 races/modifiers (StatResolver)
local QuestService = require(script.Parent.QuestService)
local TrainingBots = require(script.Parent.TrainingBots) -- v7 Gravity Room sparring NPCs
local BossNPC = require(script.Parent.BossNPC) -- v8 raid / story bosses
local StatResolver = require(game:GetService("ReplicatedStorage").Shared.StatResolver)
local EpisodeLogic = require(game:GetService("ReplicatedStorage").Shared.EpisodeLogic) -- v10 boss struggles
local FightRules = require(game:GetService("ReplicatedStorage").Shared.FightRules) -- 4th-hit branches, knockdown, rewards

local Combat = {}
local SK = Config.SKILL

local RequestMove = Net.remote("RequestMove")
local BlockRemote = Net.remote("Block")
local DashRemote = Net.remote("Dash")
local VanishRemote = Net.remote("Vanish")
local BreakRemote = Net.remote("ComboBreak")
local StruggleInput = Net.remote("StruggleInput")
local PlayVFX = Net.remote("PlayVFX")
local CombatEvent = Net.remote("CombatEvent")
local TeamComboRemote = Net.remote("TeamCombo")
local UseItemRemote = Net.remote("UseItem")
local TeamComboHook = Net.hook("TeamCombo")
local DamagedHook = Net.hook("PlayerDamaged") -- (victim, attacker, amount)
local EliminateHook = Net.hook("EliminatePlayer") -- RoundManager listens (victim, killer?, reason)
local SignalHook = Net.hook("CombatSignal") -- v10: (player, kind) accepted actions for story objectives ("vanish")
local eraseUsed = false -- Zeno Erase: once per MATCH
local kindHandlers: { [string]: (Player, any, Vector3, string) -> () }

type CS = {
	ki: number,
	blocking: boolean,
	blockSince: number,
	guard: number,
	stunUntil: number,
	invulnUntil: number,
	recoveryUntil: number,
	lastDash: number,
	lastVanish: number,
	lastBreak: number,
	cds: { [string]: number },
	lastMove: string?,
	lastMoveT: number,
	lastAttacker: Player?,
	struggle: any?,
	armorUntil: number,
	locked: boolean,
	usedFinal: boolean,
	lastAutoDodge: number?,
	blindUntil: number?,
	barrierUntil: number?,
	-- fight-research additions (Shared/FightRules)
	m1Step: number?,
	m1T: number?,
	knockdownUntil: number?,
	kdToken: number?,
	kiBurstUntil: number?,
	recentHits: { [Player]: number }?,
	teamBurstReady: boolean?,
	lastTeamBurst: number?,
}
local cs: { [Player]: CS } = {}

local function S(p: Player): CS
	local s = cs[p]
	if not s then
		s = {
			ki = Config.KI.max,
			blocking = false,
			blockSince = 0,
			guard = SK.GuardMax,
			stunUntil = 0,
			invulnUntil = 0,
			recoveryUntil = 0,
			lastDash = -1e9,
			lastVanish = -1e9,
			lastBreak = -1e9,
			cds = {},
			lastMove = nil,
			lastMoveT = 0,
			lastAttacker = nil,
			struggle = nil,
			armorUntil = 0,
			locked = false,
			usedFinal = false,
		}
		cs[p] = s
	end
	return s :: CS
end

local function publish(p: Player)
	local s = S(p)
	p:SetAttribute("Ki", math.floor(s.ki))
	p:SetAttribute("Guard", math.floor(s.guard))
	p:SetAttribute("Blocking", s.blocking)
	p:SetAttribute("Stunned", s.stunUntil > os.clock())
	p:SetAttribute("KiBurst", if (s.kiBurstUntil or 0) > os.clock() then true else nil)
	p:SetAttribute("TeamBurstReady", if s.teamBurstReady then true else nil)
end

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function humOf(p: Player): Humanoid?
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end
local function canAct(p: Player): boolean
	local roundState = workspace:GetAttribute("RoundState")
	-- the global round freeze doesn't apply to players fighting in a raid/story instance (v10)
	if (roundState == "Intro" or roundState == "Ending") and p:GetAttribute("InRaid") ~= true then
		return false
	end
	if p:GetAttribute("FusedPassenger") then
		return false
	end
	local h = humOf(p)
	return h ~= nil and h.Health > 0 and rootOf(p) ~= nil
end
local function spend(p: Player, amount: number): boolean
	local s = S(p)
	if amount > 0 and RaceRuntime.race(p).ki == "infinite" then
		return true
	end -- Android: infinite ki
	if s.ki < amount then
		return false
	end
	s.ki -= amount
	return true
end
local function event(kind: string, data: any)
	CombatEvent:FireAllClients(kind, data)
end
-- FTUE: platform-independent move confirmation. The onboarding tutorial used to detect steps from raw client
-- input, which cannot work on touch (the on-screen buttons call ClientAPI directly, so no keycode is ever
-- produced) or reliably on gamepad. Publishing the ACCEPTED move id lets the client count real, server-validated
-- actions on every platform. MoveSeq makes repeats of the same move (e.g. an M1 combo) observable.
local function announceMove(p: Player, moveId: string)
	p:SetAttribute("LastMove", moveId)
	p:SetAttribute("MoveSeq", (p:GetAttribute("MoveSeq") or 0) + 1)
end
-- v1.2 pay-to-win guard: purchased/wish stat boosts stack with the PL ratio but never exceed Config.STAT_CAP (1.35x);
-- workspace attribute "Ranked" = true normalizes (boosts ignored).
local function boosted(att: Player, ratio: number): number
	if workspace:GetAttribute("Ranked") == true then
		return ratio
	end
	local b = (att:GetAttribute("StoreStatBoost") :: number?) or 1 -- v9: no wish stat boost
	return math.min(ratio * b, Config.STAT_CAP)
end

-- ===== Balance =====
function Combat.statRatio(att: Player, vic: Player): number
	if workspace:GetAttribute("Ranked") == true then
		return 1
	end -- Ranked: skill only
	local r = (Combatant.powerLevel(att) / math.max(1, Combatant.powerLevel(vic))) ^ Config.STAT_EXPONENT
	return math.clamp(r, 1 / Config.STAT_CAP, Config.STAT_CAP)
end

-- v6: damage ratio = PL ratio x race/modifier damage / victim defense, compressed ONCE to [1/1.35, 1.35].
function Combat.damageRatio(att: Player, vic: Player): number
	if workspace:GetAttribute("Ranked") == true then
		return 1
	end
	local plr = (Combatant.powerLevel(att) / math.max(1, Combatant.powerLevel(vic))) ^ Config.STAT_EXPONENT
	local a = RaceRuntime.stats(att, (cs[att] and cs[att].ki or Config.KI.max) / Config.KI.max)
	local v = RaceRuntime.stats(vic, (cs[vic] and cs[vic].ki or Config.KI.max) / Config.KI.max)
	return StatResolver.combatRatio(plr, a, v, Config.STAT_CAP)
end

-- Server-side knockback: briefly take network ownership so the impulse is authoritative.
local function knock(p: Player, vel: Vector3)
	local root = rootOf(p)
	if not root then
		return
	end
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	root.AssemblyLinearVelocity = vel
	task.delay(0.5, function()
		if root.Parent and p.Parent then
			pcall(function()
				root:SetNetworkOwner(p)
			end)
		end
	end)
end

-- ===== Knockdown (FightRules): the body goes limp, the fighter can't act; up after the timer or the combo breaker =====
local function getUp(p: Player)
	local s = cs[p]
	if s then
		s.knockdownUntil = math.min(s.knockdownUntil or 0, os.clock()) -- get-up immunity counts from now
		s.kdToken = (s.kdToken or 0) + 1
		s.stunUntil = math.min(s.stunUntil, os.clock())
	end
	p:SetAttribute("KnockedDown", nil)
	local h, r = humOf(p), rootOf(p)
	if h then
		h.PlatformStand = false
	end
	if r and h and h.Health > 0 then
		-- stand upright, keeping the facing
		local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
		look = if look.Magnitude > 0.05 then look.Unit else Vector3.zAxis
		r.CFrame = CFrame.lookAt(r.Position + Vector3.new(0, 1.5, 0), r.Position + Vector3.new(0, 1.5, 0) + look)
		r.AssemblyAngularVelocity = Vector3.zero
	end
end

local function knockDown(p: Player, seconds: number)
	local s = S(p)
	local now = os.clock()
	s.knockdownUntil = now + seconds
	s.stunUntil = math.max(s.stunUntil, now + seconds)
	s.blocking = false
	s.kdToken = (s.kdToken or 0) + 1
	local token = s.kdToken
	p:SetAttribute("KnockedDown", true)
	local h = humOf(p)
	if h then
		h.PlatformStand = true
	end
	task.delay(seconds, function()
		local cur = cs[p]
		if cur and cur.kdToken == token and p.Parent then
			getUp(p)
			publish(p)
		end
	end)
end

-- ===== Team combos =====
type Last = { attacker: Player, team: Team?, t: number, links: number }
local lastHit: { [Instance]: Last } = {}

function Combat.registerHit(attacker: Player, target: Instance, _baseDamage: number?): number
	local cfg = Config.COMBO
	local now = os.clock()
	local prev = lastHit[target]
	local links = 0
	if
		prev
		and prev.attacker ~= attacker
		and prev.team == attacker.Team
		and attacker.Team ~= nil
		and now - prev.t <= cfg.window
	then
		links = math.min(prev.links + 1, cfg.maxLinks)
	elseif prev and prev.attacker == attacker and now - prev.t <= cfg.window then
		links = prev.links
	end
	lastHit[target] = { attacker = attacker, team = attacker.Team, t = now, links = links }
	local perLink = RaceRuntime.race(attacker).comboPerLink or cfg.perLink
	if links > 0 and prev and prev.attacker ~= attacker then
		QuestService.track(attacker, "teamCombo", 1)
		PlayerData.addXP(attacker, cfg.xpPerLink)
		PlayerData.addXP(prev.attacker, cfg.xpPerLink)
		TeamComboHook:Fire(attacker, prev.attacker, target, links)
		TeamComboRemote:FireAllClients(attacker.UserId, prev.attacker.UserId, links, 1 + links * perLink)
	end
	return 1 + links * perLink
end

-- ===== Hit resolution (block / parry / guard break / i-frames / hitstun / knockback) =====
-- power: 1 normally, 0.7 for Moro Copy, 1.25 for beam-struggle winner. Returns outcome string.
function Combat.resolveHit(att: Player, vic: Player, mv: any, power: number): string
	if vic == att or vic.Team == att.Team or vic:GetAttribute("Alive") ~= true then
		return "None"
	end
	if vic:GetAttribute("FusedPassenger") then
		return "None"
	end
	if
		Config.NON_COMBAT[Combatant.activeCharacter(vic) or ""]
		or Config.NON_COMBAT[Combatant.activeCharacter(att) or ""]
	then
		return "None"
	end
	local vs, as = S(vic), S(att)
	local now = os.clock()
	if vs.invulnUntil > now then
		event("Dodged", { vic.UserId })
		return "Dodged"
	end
	if (vs.barrierUntil or 0) > now then
		event("BarrierBlock", { vic.UserId, att.UserId })
		return "Blocked"
	end -- Android Barrier
	-- Angel race: autonomous dodge vs non-ultimate hits (8 ki, 1.5 s internal cooldown)
	local vrace = RaceRuntime.race(vic)
	if
		vrace.autoDodge
		and not mv.beam
		and not mv.ultimate
		and mv.kind ~= "selfblast"
		and mv.kind ~= "hakai"
		and now - (vs.lastAutoDodge or -1e9) >= Config.ANGEL_DODGE.icd
		and vs.ki >= Config.ANGEL_DODGE.ki
		and math.random() < vrace.autoDodge
	then
		vs.lastAutoDodge = now
		vs.ki -= Config.ANGEL_DODGE.ki
		vs.invulnUntil = now + 0.2
		publish(vic)
		event("Dodged", { vic.UserId, "AutoDodge" })
		return "Dodged"
	end
	local vh, vr, ar = humOf(vic), rootOf(vic), rootOf(att)
	if not vh or not vr or not ar then
		return "None"
	end
	vs.lastAttacker = att
	vs.lastAttackedT = os.clock()
	local ratio = Combat.damageRatio(att, vic)
	local base = mv.damage * power
	if vrace.kiBlastTaken and mv.kind == "ray" and not mv.beam then
		base *= vrace.kiBlastTaken
	end -- Destroyer aura
	local toAtt = (ar.Position - vr.Position)
	local facing = toAtt.Magnitude > 0 and vr.CFrame.LookVector:Dot(toAtt.Unit) >= SK.BlockFacingDot
	local function tag()
		local t = vh:FindFirstChild("creator") :: ObjectValue?
		if not t then
			local n = Instance.new("ObjectValue")
			n.Name = "creator"
			n.Parent = vh
			t = n
		end
		(t :: ObjectValue).Value = att
	end
	if vs.blocking and facing and vs.stunUntil <= now then
		if mv.parryable and now - vs.blockSince <= SK.ParryWindow then
			as.stunUntil = now + SK.ParryStun
			vs.ki = math.min(Config.KI.max, vs.ki + Config.KI.parryGain)
			-- perfect-block reward: the first parry primes a Ki Burst; a parry while primed vanishes behind the attacker
			if FightRules.parryReward(vs.kiBurstUntil, now) == "vanish" then
				vs.invulnUntil = now + SK.VanishCounterIFrames
				vs.blocking = false
				local dest = ar.Position - ar.CFrame.LookVector * 4
				vr.CFrame = CFrame.lookAt(dest, Vector3.new(ar.Position.X, dest.Y, ar.Position.Z))
				event("VanishCounter", { vic.UserId, att.UserId })
			end
			vs.kiBurstUntil = now + SK.KiBurstWindow
			publish(att)
			publish(vic)
			QuestService.track(vic, "parry", 1)
			event("Parry", { vic.UserId, att.UserId })
			return "Parry"
		end
		vs.guard -= (mv.guardDamage or 0) * power
		if mv.guardBreak or vs.guard <= 0 then
			vs.guard = 0
			vs.blocking = false
			vs.stunUntil = now + SK.GuardBreakStun
			local dmg = base * boosted(att, ratio) * SK.GuardBreakDamageMult
			tag()
			vh:TakeDamage(dmg)
			DamagedHook:Fire(vic, att, dmg)
			publish(vic)
			event("GuardBreak", { vic.UserId, att.UserId })
			return "GuardBreak"
		end
		local chip = base * ratio * SK.BlockChip
		tag()
		vh:TakeDamage(chip)
		DamagedHook:Fire(vic, att, chip)
		publish(vic)
		return "Blocked"
	end
	local mult = Combat.registerHit(att, vic.Character :: Instance, base)
	local dmg = base * boosted(att, ratio) * mult -- Power wish: 1.1x damage
	tag()
	vh:TakeDamage(dmg)
	DamagedHook:Fire(vic, att, dmg)
	-- anti-team burst: enough different attackers in a short window unlock a free burst for the victim
	local hits = vs.recentHits or {}
	vs.recentHits = hits
	hits[att] = now
	local tb = SK.TeamBurst
	if not vs.teamBurstReady and FightRules.teamBurstReady(hits, now, tb.window, tb.attackers, vs.lastTeamBurst, tb.cooldown) then
		vs.teamBurstReady = true
	end
	-- Final Explosion charge (armour), being down, or just up again: no hitstun / knockback, so nobody gets looped
	local armored = vs.armorUntil > now or FightRules.isProtected(vs.knockdownUntil, now, SK.GetUpImmunity)
	if not armored then
		vs.stunUntil = math.max(vs.stunUntil, now + (mv.hitstun or SK.Hitstun))
	end
	-- knockback scales with missing HP (ring-out positioning) and the compressed stat ratio
	local missing = 1 - math.clamp(vh.Health / math.max(1, vh.MaxHealth), 0, 1)
	local kb = (mv.kb or 0)
		* power
		* (1 + SK.KnockbackGrowth * missing)
		* math.sqrt(ratio)
		* (vrace.knockbackTaken or 1)
		* (if RaceRuntime.isActive(att, "GiantForm") then 1.3 else 1)
	if not armored and (kb > 0 or mv.up or mv.down) then
		local flat = Vector3.new(vr.Position.X - ar.Position.X, 0, vr.Position.Z - ar.Position.Z)
		local dir = if flat.Magnitude > 0.01 then flat.Unit else ar.CFrame.LookVector
		if mv.up then -- launch: straight up for an air follow-up
			knock(vic, dir * kb + Vector3.new(0, mv.up, 0))
		elseif mv.down then -- spike: driven into the stage, which cracks, then a small bounce
			knock(vic, dir * kb + Vector3.new(0, -mv.down, 0))
			Arena.damageAt(vr.Position - Vector3.new(0, 2.5, 0), mv.crackRadius or 8, (mv.crackPower or 50) * power)
			task.delay(0.15, function()
				local r = rootOf(vic)
				if r then
					r.AssemblyLinearVelocity = Vector3.new(0, 22, 0) + dir * 6
				end
			end)
		else
			knock(vic, (dir + Vector3.new(0, 0.35, 0)).Unit * kb)
		end
		if mv.knockdown then
			knockDown(vic, mv.knockdown)
		end
	end
	publish(vic)
	-- v1.1 GameFeel: clients play hitstop/shake/impact for attacker+victim (data: vic, att, dmg, kb, ko)
	event("Hit", { vic.UserId, att.UserId, math.floor(dmg + 0.5), kb, vh.Health <= 0 })
	return "Hit"
end

-- Back-compat helper (v3 API): direct damage with ratio/combo, no skill checks.
function Combat.applyDamage(attacker: Player, hum: Humanoid, base: number): number
	local vic = Players:GetPlayerFromCharacter(hum.Parent)
	if not vic then
		return 0
	end
	return if Combat.resolveHit(attacker, vic, { damage = base, kb = 0, parryable = false }, 1) == "Hit"
		then base
		else 0
end

-- ===== Targeting (hurtbox scales with victim tier) =====
local function hurtRadius(p: Player): number
	return SK.HurtRadius * Combatant.tierRules(p).hurtbox * (if RaceRuntime.isActive(p, "GiantForm") then 1.6 else 1)
end

local function enemies(att: Player): { Player }
	local out = {}
	for _, q in Players:GetPlayers() do
		if
			q ~= att
			and q.Team ~= att.Team
			and q:GetAttribute("Alive") == true
			and not q:GetAttribute("FusedPassenger")
		then
			table.insert(out, q)
		end
	end
	return out
end

local function losClear(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local res = workspace:Raycast(from, to - from, params)
	return res == nil
end

-- returns target player (or nil) and the impact position
local function findTarget(att: Player, mv: any, targetPos: Vector3): (Player?, Vector3)
	local ar = rootOf(att) :: BasePart
	local from = ar.Position
	local dir = (targetPos - from)
	dir = if dir.Magnitude > 0.01 then dir.Unit else ar.CFrame.LookVector
	local best, bestD = nil, math.huge
	for _, q in enemies(att) do
		local qr = rootOf(q)
		if qr then
			local rel = qr.Position - from
			if mv.kind == "melee" then
				local d = rel.Magnitude
				local reach = mv.range + (if table.find(RaceRuntime.race(att).traits, "StretchLimb") then 2 else 0)
				if d <= reach + hurtRadius(q) and (d < 2 or dir:Dot(rel.Unit) >= 0.3) and d < bestD then
					best, bestD = q, d
				end
			else -- ray
				local along = rel:Dot(dir)
				if along > 0 and along <= mv.range then
					local perp = (rel - dir * along).Magnitude
					if perp <= (mv.width or 1) + hurtRadius(q) and along < bestD then
						best, bestD = q, along
					end
				end
			end
		end
	end
	if best then
		local qr = rootOf(best) :: BasePart
		local ignore = { att.Character :: Instance, best.Character :: Instance }
		if mv.kind == "melee" or losClear(from, qr.Position, ignore) then
			return best, qr.Position
		end
	end
	-- no player hit: impact on world for arena damage
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { att.Character :: Instance }
	local res = workspace:Raycast(from, dir * mv.range, params)
	return nil, if res then res.Position else from + dir * math.min(mv.range, (targetPos - from).Magnitude)
end

-- ===== Moro kit =====
local function onHitExtras(att: Player, vic: Player, mv: any, outcome: string)
	if outcome ~= "Hit" and outcome ~= "GuardBreak" then
		return
	end
	if mv.absorb then
		local vs = S(vic)
		local drained = math.min(Config.MORO.drainKi, vs.ki)
		vs.ki -= drained
		local as = S(att)
		as.ki = math.min(Config.KI.max, as.ki + drained)
		Combatant.addAbsorb(att, Config.MORO.plPerHit)
		publish(att)
		publish(vic)
		event("Absorb", { att.UserId, vic.UserId, drained })
	end
end

-- ===== Beam struggle =====
local pendingBeams: { [Player]: { mv: any, moveId: string, target: Vector3, t: number, power: number } } = {}
local function startStruggle(a: Player, b: Player)
	local cfg = SK.Struggle
	local st = {
		a = a,
		b = b,
		score = 0,
		t0 = os.clock(),
		nextPulse = os.clock() + cfg.pulse,
		lastPulse = os.clock(),
		ma = pendingBeams[a].mv,
		mb = pendingBeams[b].mv,
		pa = pendingBeams[a].power,
		pb = pendingBeams[b].power,
	}
	pendingBeams[a] = nil
	pendingBeams[b] = nil
	S(a).struggle = st
	S(b).struggle = st
	event("StruggleStart", { a.UserId, b.UserId, cfg.maxTime })
	task.spawn(function()
		while os.clock() - st.t0 < cfg.maxTime and math.abs(st.score) < cfg.winScore do
			if os.clock() >= st.nextPulse then
				st.lastPulse = st.nextPulse
				st.nextPulse += cfg.pulse
				event("StrugglePulse", { a.UserId, b.UserId, st.score })
			end
			if not canAct(a) or not canAct(b) then
				break
			end
			task.wait(0.03)
		end
		S(a).struggle = nil
		S(b).struggle = nil
		if st.helper and cs[st.helper] then
			S(st.helper).struggle = nil
		end
		local winner, loser, wmv, wpow
		if st.score >= cfg.tieScore then
			winner, loser, wmv, wpow = a, b, st.ma, st.pa
		elseif st.score <= -cfg.tieScore then
			winner, loser, wmv, wpow = b, a, st.mb, st.pb
		end
		if winner and loser and loser.Parent and winner.Parent then
			event("StruggleEnd", { winner.UserId, loser.UserId })
			QuestService.track(winner, "struggleWin", 1)
			Combat.resolveHit(winner, loser, wmv, wpow * cfg.winBonus)
			local lr = rootOf(loser)
			if lr then
				Arena.damageAt(lr.Position, wmv.arenaRadius or 0, (wmv.arenaPower or 0) * wpow)
			end
		else
			event("StruggleEnd", { 0, 0 })
			for _, p in { a, b } do
				local h = humOf(p)
				if h and p:GetAttribute("Alive") == true then
					h:TakeDamage(cfg.tieDamage)
				end
			end
			local ra, rb = rootOf(a), rootOf(b)
			if ra and rb then
				Arena.damageAt((ra.Position + rb.Position) / 2, st.ma.arenaRadius or 0, st.ma.arenaPower or 0)
			end
		end
	end)
end

StruggleInput.OnServerEvent:Connect(function(p)
	local cfg = SK.Struggle
	if not RateLimit.allow(p, "struggle", cfg.maxInputsPerSec, cfg.maxInputsPerSec) then
		return
	end
	local st = S(p).struggle
	if not st then
		return
	end
	local now = os.clock()
	local nearPulse = math.min(math.abs(now - st.lastPulse), math.abs(st.nextPulse - now)) <= cfg.timingTol
	local w = if nearPulse then cfg.timingWeight else 1
	if st.boss then -- v10 story struggle: the boss side is scripted (startBossStruggle), skill only
		st.score += w
		return
	end
	if st.helper == p then -- D18 third beam: x0.5 weight to the side it supports
		w *= ToPLogic.STRUGGLE_JOIN_WEIGHT
		st.score += if st.helperSide == "a" then w else -w
		return
	end
	local other = if st.a == p then st.b else st.a
	w *= Combat.statRatio(p, other) -- compressed: skill (inputs/timing) dominates
	st.score += if st.a == p then w else -w
end)

-- v10 story: player vs boss struggle (the PvP startStruggle above is untouched).
-- mode "clash": beam clash, broadcast as StruggleStart/Pulse/End with the boss MODEL as side b (TransformCinematic and
-- MobileControls already accept a model there). mode "hold": grapple, broadcast as HoldStart/HoldPulse/HoldEnd.
-- The boss pushes opts.bossRate per second; the player's StruggleInput (V / mash button) pushes back with the usual
-- pulse-timing weight but no stat ratio. Outcome rules: EpisodeLogic.struggleOutcome. opts.onEnd(result) runs once with
-- "win" | "lose" | "abort" (player died/left/reset, boss removed). Returns false if the player is already struggling.
function Combat.startBossStruggle(p: Player, bossModel: Model, opts: any): boolean
	local s = S(p)
	if s.struggle or not canAct(p) then
		return false
	end
	local cfg = SK.Struggle
	local mode = if opts.mode == "hold" then "hold" else "clash"
	local rules = { winScore = opts.winScore or cfg.winScore, maxTime = opts.maxTime or cfg.maxTime }
	local now0 = os.clock()
	local st = {
		boss = bossModel,
		mode = mode,
		a = p,
		score = opts.startScore or 0,
		t0 = now0,
		nextPulse = now0 + cfg.pulse,
		lastPulse = now0,
	}
	pendingBeams[p] = nil
	s.blocking = false
	s.struggle = st
	publish(p)
	local prefix = if mode == "hold" then "Hold" else "Struggle"
	event(prefix .. "Start", { p.UserId, bossModel, rules.maxTime, rules.winScore })
	task.spawn(function()
		local last = os.clock()
		local result = "abort"
		while true do
			task.wait(0.03)
			local now = os.clock()
			st.score -= (opts.bossRate or 8) * (now - last)
			last = now
			if now >= st.nextPulse then
				st.lastPulse = st.nextPulse
				st.nextPulse += cfg.pulse
				event(prefix .. "Pulse", { p.UserId, bossModel, st.score, now - st.t0 })
			end
			local ps = cs[p]
			if not p.Parent or not ps or ps.struggle ~= st or not canAct(p) or not bossModel.Parent then
				break
			end
			local out = EpisodeLogic.struggleOutcome(mode, st.score, now - st.t0, rules)
			if out then
				result = out
				break
			end
		end
		local ps = cs[p]
		if ps and ps.struggle == st then
			ps.struggle = nil
		end
		event(prefix .. "End", { if result == "win" then p.UserId else 0, if result == "lose" then p.UserId else 0, result })
		if result == "win" and mode == "clash" then
			QuestService.track(p, "struggleWin", 1)
		end
		if opts.onEnd then
			task.spawn(opts.onEnd, result)
		end
	end)
	return true
end

-- v10: hitstun query (BossNPC grab: still held at the check = no Combo Breaker used)
function Combat.isStunned(p: Player): boolean
	local s = cs[p]
	return s ~= nil and s.stunUntil > os.clock()
end

-- ===== Executing moves =====
local function execute(p: Player, moveId: string, mv: any, targetPos: Vector3, power: number)
	local char = p.Character :: Model
	if mv.beam then
		-- hold briefly to detect a clash with an enemy beam aimed at us
		local ar = rootOf(p) :: BasePart
		for q, pb in pendingBeams do
			if q ~= p and q.Team ~= p.Team and os.clock() - pb.t <= SK.Struggle.window then
				local qr = rootOf(q)
				if qr and (pb.target - ar.Position).Magnitude <= 20 and (targetPos - qr.Position).Magnitude <= 20 then
					pendingBeams[p] = { mv = mv, moveId = moveId, target = targetPos, t = os.clock(), power = power }
					PlayVFX:FireAllClients(moveId, char, targetPos)
					startStruggle(q, p)
					return
				end
			end
		end
		-- D18: a beam fired into an active struggle joins it (max 3 beams); a full struggle can't be joined
		for _, q in Players:GetPlayers() do
			local qs = cs[q]
			local qst = qs and qs.struggle
			local qr = qst and rootOf(q)
			if qst and qr and q.Team ~= p.Team and (targetPos - qr.Position).Magnitude <= 20 then
				local beams = if qst.helper then 3 else 2
				if ToPLogic.struggleCanJoin(beams) and qst.a ~= p and qst.b ~= p then
					qst.helper = p
					qst.helperSide = if qst.a == q then "b" else "a" -- supports the enemy of q
					S(p).struggle = qst
					PlayVFX:FireAllClients(moveId, char, targetPos)
					event("StruggleJoin", { p.UserId, (if qst.helperSide == "a" then qst.a else qst.b).UserId })
					return
				end
			end
		end
		local myT = os.clock()
		pendingBeams[p] = { mv = mv, moveId = moveId, target = targetPos, t = myT, power = power }
		PlayVFX:FireAllClients(moveId, char, targetPos)
		task.delay(SK.Struggle.window, function()
			local pb = pendingBeams[p]
			if not pb or pb.t ~= myT or S(p).struggle then
				return
			end
			pendingBeams[p] = nil
			if not canAct(p) then
				return
			end
			local vic, hitPos = findTarget(p, mv, targetPos)
			if vic then
				Combat.resolveHit(p, vic, mv, power)
			else
				local bot, bpos = DevBots.hitScan(p, mv, targetPos)
				if bot then
					DevBots.hit(p, bot, mv, power)
					hitPos = bpos
				else
					local tb, tpos = TrainingBots.hitScan(p, mv, targetPos)
					if tb then
						TrainingBots.hit(p, tb, mv, power)
						hitPos = tpos
					else
						local bb, bpos2 = BossNPC.hitScan(p, mv, targetPos)
						if bb then
							BossNPC.hit(p, bb, mv, power)
							hitPos = bpos2
						end
					end
				end
			end
			Arena.damageAt(hitPos, mv.arenaRadius or 0, (mv.arenaPower or 0) * power)
		end)
		return
	end
	local vic, hitPos = findTarget(p, mv, targetPos)
	if vic then
		local outcome = Combat.resolveHit(p, vic, mv, power)
		onHitExtras(p, vic, mv, outcome)
	end
	if not vic then
		local bot, bpos = DevBots.hitScan(p, mv, targetPos)
		if bot then
			DevBots.hit(p, bot, mv, power)
			hitPos = bpos
		else
			local tb, tpos = TrainingBots.hitScan(p, mv, targetPos)
			if tb then
				TrainingBots.hit(p, tb, mv, power)
				hitPos = tpos
			else
				local bb, bpos2 = BossNPC.hitScan(p, mv, targetPos)
				if bb then
					BossNPC.hit(p, bb, mv, power)
					hitPos = bpos2
				end
			end
		end
	end
	if mv.arenaRadius then
		Arena.damageAt(hitPos, mv.arenaRadius, mv.arenaPower * power)
	end
	PlayVFX:FireAllClients(moveId, char, hitPos)
end

-- Vegeta Final Explosion: server owns the timer and the detonation (client VFX OnDetonate is ignored).
local function finalExplosion(p: Player, mv: any)
	local s = S(p)
	s.usedFinal = true
	s.locked = true
	s.blocking = false
	s.armorUntil = os.clock() + mv.charge
	local char = p.Character :: Model
	PlayVFX:FireAllClients("FinalExplosion", char, nil)
	task.delay(mv.charge, function()
		s.locked = false
		if not canAct(p) or p.Character ~= char or Combatant.activeCharacter(p) ~= mv.champion then
			return
		end
		local root = rootOf(p) :: BasePart
		local pos = root.Position
		for _, q in enemies(p) do
			local qr = rootOf(q)
			if qr and (qr.Position - pos).Magnitude <= mv.radius + hurtRadius(q) then
				Combat.resolveHit(p, q, mv, 1)
			end
		end
		DevBots.hitRadius(p, pos, mv)
		Arena.damageAt(pos, mv.arenaRadius, mv.arenaPower)
		event("FinalExplosion", { p.UserId })
		-- self-KO: counted as the caster's elimination (no killer credit, no Senzu, no last gift)
		EliminateHook:Fire(p, nil, "SelfKO")
		local h = humOf(p)
		if h then
			h.Health = 0
		end
	end)
end

-- Zeno Erase: EventMode only, once per match, 8 s warning, then one random living enemy is eliminated.
local function erase(p: Player, mv: any)
	eraseUsed = true -- consumed even if Zeno is interrupted
	event("EraseWarning", { p.UserId, mv.warning })
	PlayVFX:FireAllClients("EraseWarning", p.Character, mv.warning)
	task.delay(mv.warning, function()
		if not canAct(p) then
			return
		end
		local pool = enemies(p)
		if #pool == 0 then
			return
		end
		local target = pool[math.random(1, #pool)]
		PlayVFX:FireAllClients("Erase", target.Character, nil)
		event("Erased", { p.UserId, target.UserId })
		EliminateHook:Fire(target, nil, "Erased") -- no KO credit/XP for Zeno
		local h = humOf(target)
		if h then
			h.Health = 0
		end
	end)
end

-- ===== Extension API (DestroyerMoves, SpiritBomb) =====
kindHandlers = {}
function Combat.registerKind(kind: string, fn: (Player, any, Vector3, string) -> ())
	kindHandlers[kind] = fn
end
Combat.util = {
	state = function(p: Player): any
		return S(p)
	end,
	rootOf = rootOf,
	humOf = humOf,
	canAct = canAct,
	enemies = enemies,
	findTarget = findTarget,
	event = event,
	publish = publish,
	hurtRadius = hurtRadius,
	losClear = losClear,
	knock = knock,
	PlayVFX = PlayVFX,
	EliminateHook = EliminateHook,
}
-- v8 ToP: ring-out credit -> last enemy who hit p within `within` seconds (nil if none / left / same team)
function Combat.lastAttacker(p: Player, within: number): Player?
	local s = cs[p]
	local a = s and s.lastAttacker
	if not a or not a.Parent or a.Team == p.Team or os.clock() - ((s :: any).lastAttackedT or 0) > within then
		return nil
	end
	return a
end
-- AFK (§10.1): last time p did a combat action (move, dash, vanish, block held, struggle).
function Combat.lastActiveT(p: Player): number
	local s = cs[p]
	if not s then
		return 0
	end
	local t = math.max(s.lastMoveT or 0, s.lastDash or 0, s.lastVanish or 0)
	if s.blocking or s.struggle then
		t = os.clock()
	end
	return t
end
function Combat.lastMoveId(p: Player): string?
	local s = cs[p]
	return s and s.lastMove
end
function Combat.lastMoveKind(p: Player): string?
	local s = cs[p]
	local mv = s and s.lastMove and Config.MOVES[s.lastMove]
	return mv and mv.kind
end

-- v7: NPC (TrainingBots) hit on a player, through the same defensive rules: i-frames, Barrier, perfect guard, block chip.
-- Returns "Dodged" | "Blocked" | "Parry" | "Hit". Only used outside matches (Gravity Room sparring).
function Combat.npcHit(npc: Model, vic: Player, mv: any): string
	local vh, vr = humOf(vic), rootOf(vic)
	local nr = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not vh or not vr or not nr or vh.Health <= 0 then
		return "None"
	end
	local vs = S(vic)
	local now = os.clock()
	if vs.invulnUntil > now then
		event("Dodged", { vic.UserId })
		return "Dodged"
	end
	if (vs.barrierUntil or 0) > now then
		return "Blocked"
	end
	local toAtt = nr.Position - vr.Position
	local facing = toAtt.Magnitude > 0 and vr.CFrame.LookVector:Dot(toAtt.Unit) >= SK.BlockFacingDot
	if vs.blocking and facing and vs.stunUntil <= now then
		if now - vs.blockSince <= SK.ParryWindow then
			vs.ki = math.min(Config.KI.max, vs.ki + Config.KI.parryGain)
			if FightRules.parryReward(vs.kiBurstUntil, now) == "vanish" then -- second parry while primed
				vs.invulnUntil = now + SK.VanishCounterIFrames
				vs.blocking = false
				local dest = nr.Position - nr.CFrame.LookVector * 4
				vr.CFrame = CFrame.lookAt(dest, Vector3.new(nr.Position.X, dest.Y, nr.Position.Z))
				event("VanishCounter", { vic.UserId, 0 })
			end
			vs.kiBurstUntil = now + SK.KiBurstWindow
			publish(vic)
			event("Parry", { vic.UserId, 0 })
			QuestService.track(vic, "parry", 1)
			return "Parry"
		end
		vh:TakeDamage(mv.damage * SK.BlockChip)
		return "Blocked"
	end
	vh:TakeDamage(mv.damage)
	vs.stunUntil = math.max(vs.stunUntil, now + (mv.hitstun or SK.Hitstun))
	local flat = Vector3.new(vr.Position.X - nr.Position.X, 0, vr.Position.Z - nr.Position.Z)
	if (mv.kb or 0) > 0 and flat.Magnitude > 0.01 then
		knock(vic, (flat.Unit + Vector3.new(0, 0.35, 0)).Unit * mv.kb)
	end
	publish(vic)
	event("Hit", { vic.UserId, 0, math.floor(mv.damage + 0.5), mv.kb or 0, false })
	return "Hit"
end

function Combat.getKi(p: Player): number
	return S(p).ki
end
function Combat.takeKi(p: Player, n: number): number
	local s = S(p)
	local t = math.clamp(n, 0, s.ki)
	if RaceRuntime.race(p).ki == "infinite" then
		t = n
	end -- Android: ki never runs dry
	s.ki -= if RaceRuntime.race(p).ki == "infinite" then 0 else t
	publish(p)
	return t
end

RequestMove.OnServerEvent:Connect(function(p, moveId, targetPos, origin, branch)
	if type(moveId) ~= "string" or typeof(targetPos) ~= "Vector3" then
		return
	end
	if not RateLimit.allow(p, "move", 6, 8) then
		return
	end
	local mv = Config.MOVES[moveId]
	if not mv or not canAct(p) then
		return
	end
	local s = S(p)
	local now = os.clock()
	if s.locked or s.stunUntil > now or s.recoveryUntil > now or s.struggle or s.blocking then
		return
	end
	if (s.blindUntil or 0) > now and mv.kind == "ray" then
		return
	end -- Solar Flare: blinded fighters can't aim ki
	local char = Combatant.activeCharacter(p) or ""
	local free = (mv.freeForPrefix and string.sub(char, 1, #mv.freeForPrefix) == mv.freeForPrefix)
		or (mv.freeForIds and table.find(mv.freeForIds, char) ~= nil) -- kit moves (e.g. Kai Kai for Shin / Zamasu)
	local isCore = (moveId == "M1" or moveId == "Heavy" or moveId == "KiBlast" or moveId == "Kamehameha")
	if mv.unlock and not isCore and not free and not PlayerData.hasUnlock(p, mv.unlock) then
		return
	end
	if mv.races and not free and not table.find(mv.races, RaceRuntime.raceId(p)) then
		return
	end
	if mv.champion and Combatant.activeCharacter(p) ~= mv.champion then
		return
	end
	if Config.NON_COMBAT[Combatant.activeCharacter(p) or ""] and mv.kind ~= "erase" then
		return
	end
	if mv.kind == "erase" then
		if eraseUsed or workspace:GetAttribute("EventMode") ~= true then
			return
		end
		erase(p, mv)
		return
	end
	if mv.kind == "selfblast" then
		local h = humOf(p) :: Humanoid
		if s.usedFinal or h.Health / math.max(1, h.MaxHealth) > mv.hpThreshold then
			return
		end
		if not spend(p, mv.ki) then
			return
		end
		publish(p)
		finalExplosion(p, mv)
		return
	end
	local root = rootOf(p) :: BasePart
	if
		origin ~= nil
		and (typeof(origin) ~= "Vector3" or (origin - root.Position).Magnitude > Config.MAX_ORIGIN_OFFSET)
	then
		return
	end
	if mv.kind == "melee" then
		local toTarget = targetPos - root.Position
		local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
		if flat.Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
			targetPos = root.Position + flat.Unit * math.clamp(flat.Magnitude, 3, mv.range + 4)
		else
			targetPos = root.Position + root.CFrame.LookVector * (mv.range or 7)
		end
	else
		local toTarget = targetPos - root.Position
		if toTarget.Magnitude > 0.1 then
			local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
			if flat.Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
			end
			if toTarget.Magnitude > mv.range + 50 then
				targetPos = root.Position + toTarget.Unit * mv.range
			end
		end
	end
	local race = RaceRuntime.race(p)
	if s.cds[moveId] and now - s.cds[moveId] < mv.cooldown * (race.cooldownMult or 1) then
		return
	end
	local handler = kindHandlers[mv.kind]
	if handler then -- registered kinds (DestroyerMoves: hakai, SpiritBomb: spiritbomb)
		if not spend(p, (mv.ki or 0) * (race.kiCostMult or 1)) then
			return
		end
		s.cds[moveId] = now
		s.recoveryUntil = now + (mv.recovery or 0) * Combatant.tierRules(p).recovery
		s.lastMove, s.lastMoveT = moveId, now
		publish(p)
		announceMove(p, moveId)
		handler(p, mv, targetPos, moveId)
		return
	end

	local execId, execMv, power = moveId, mv, 1
	-- the 4th M1 of a chain is a finisher: blow-away (knockdown), launch (jump held) or spike (airborne)
	local finisherKind: string? = nil
	if moveId == "M1" then
		s.m1Step = FightRules.nextM1Step(s.m1Step, s.m1T, now, SK.M1ChainWindow)
		s.m1T = now
		if s.m1Step == 4 then
			local h = humOf(p)
			local airborne = h ~= nil and h.FloorMaterial == Enum.Material.Air
			finisherKind = FightRules.finisher(branch, airborne)
			execMv = FightRules.applyFinisher(mv, finisherKind :: string, SK.Finisher)
		end
	end
	if mv.kind == "copy" then
		-- Moro: copy the nearest enemy-to-target's last move (within memory) at reduced power
		local victim, best = nil, math.huge
		for _, q in enemies(p) do
			local qr = rootOf(q)
			if qr then
				local d = (qr.Position - targetPos).Magnitude
				if d < best and (qr.Position - root.Position).Magnitude <= mv.range then
					victim, best = q, d
				end
			end
		end
		local vs = victim and S(victim)
		local copied = vs and vs.lastMove
		if not victim or not vs or not copied or now - vs.lastMoveT > Config.MORO.copyMemory then
			return
		end
		local cmv = Config.MOVES[copied]
		if not cmv or cmv.kind == "copy" or cmv.absorb then
			return
		end
		execId, execMv, power = copied, cmv, Config.MORO.copyPower
		targetPos = (rootOf(victim) :: BasePart).Position
		event("Copy", { p.UserId, victim.UserId, copied })
	end
	if not spend(p, (mv.ki or 0) * (race.kiCostMult or 1)) then
		return
	end
	-- perfect-block reward: the next damaging attack after a parry is critical, whatever it hits
	local kiBurst = (s.kiBurstUntil or 0) > now and (execMv.damage or 0) > 0
	if kiBurst then
		power *= SK.KiBurstMult
		s.kiBurstUntil = 0
		event("KiBurst", { p.UserId })
	end
	s.cds[moveId] = now
	s.recoveryUntil = now + (execMv.recovery or 0) * Combatant.tierRules(p).recovery
	announceMove(p, moveId)
	if finisherKind then
		event("Finisher", { p.UserId, finisherKind })
	end
	if mv.kind ~= "copy" then
		s.lastMove, s.lastMoveT = moveId, now
	end
	publish(p)
	execute(p, execId, execMv, targetPos, power)
end)

-- ===== Defensive / movement skills =====
BlockRemote.OnServerEvent:Connect(function(p, down)
	if type(down) ~= "boolean" or not RateLimit.allow(p, "block", 10, 12) then
		return
	end
	local s = S(p)
	if down then
		if not canAct(p) or s.locked or s.stunUntil > os.clock() or s.guard <= 0 or s.struggle then
			return
		end
		if not s.blocking then
			s.blocking = true
			s.blockSince = os.clock()
		end
	else
		s.blocking = false
	end
	publish(p)
end)

DashRemote.OnServerEvent:Connect(function(p, dir)
	if typeof(dir) ~= "Vector3" or not RateLimit.allow(p, "dash", 3, 3) or not canAct(p) then
		return
	end
	local s = S(p)
	local now = os.clock()
	if s.locked or s.stunUntil > now or s.struggle or now - s.lastDash < SK.DashCooldown then
		return
	end
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	if s.recoveryUntil > now then -- dash-cancel
		if not spend(p, SK.DashCancelKi) then
			return
		end
		s.recoveryUntil = now
		event("DashCancel", { p.UserId })
	end
	s.lastDash = now
	s.blocking = false
	knock(p, flat.Unit * SK.DashSpeed)
	event("Dash", { p.UserId })
	publish(p)
end)

VanishRemote.OnServerEvent:Connect(function(p, dir)
	if not RateLimit.allow(p, "vanish", 2, 2) or not canAct(p) then
		return
	end
	local s = S(p)
	local now = os.clock()
	if s.locked or s.stunUntil > now or s.struggle or now - s.lastVanish < SK.VanishCooldown then
		return
	end
	local root = rootOf(p) :: BasePart
	local dest: Vector3
	local la = s.lastAttacker
	local lr = la and rootOf(la)
	if lr and (lr.Position - root.Position).Magnitude <= 20 then
		dest = lr.Position - lr.CFrame.LookVector * 4 -- appear behind last attacker
	else
		local v = if typeof(dir) == "Vector3" and dir.Magnitude > 0.1 then dir.Unit else root.CFrame.LookVector
		dest = root.Position + v * SK.VanishDistance
	end
	if (dest - root.Position).Magnitude > 25 or not losClear(root.Position, dest, { p.Character :: Instance }) then
		return
	end
	if not spend(p, SK.VanishKi) then
		return
	end
	s.lastVanish = now
	s.invulnUntil = now + SK.VanishIFrames
	root.CFrame = CFrame.lookAt(dest, if lr then lr.Position else dest + root.CFrame.LookVector)
	event("Vanish", { p.UserId })
	publish(p)
	if p:GetAttribute("InStory") then SignalHook:Fire(p, "vanish") end
end)

BreakRemote.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "break", 2, 2) or not canAct(p) then
		return
	end
	local s = S(p)
	local now = os.clock()
	if s.locked then
		return
	end
	-- anti-team burst: when ganged up on, the breaker is free, bigger and usable even without being stunned
	local teamBurst = s.teamBurstReady == true
	if not teamBurst then
		if s.stunUntil <= now or now - s.lastBreak < SK.BreakerCooldown then
			return
		end -- only while in hitstun (a knockdown counts)
		if not spend(p, SK.BreakerKi) then
			return
		end
		s.lastBreak = now
	else
		s.teamBurstReady = false
		s.lastTeamBurst = now
		s.recentHits = {}
	end
	if (s.knockdownUntil or 0) > now then
		getUp(p) -- escape the knockdown
	end
	local tb = SK.TeamBurst
	local radius = if teamBurst then tb.radius else SK.BreakerRadius
	local push = if teamBurst then tb.push else SK.BreakerPush
	s.stunUntil = now
	s.invulnUntil = now + (if teamBurst then tb.iframes else SK.BreakerIFrames)
	lastHit[p.Character :: Instance] = nil -- resets team-combo chain on me
	local root = rootOf(p) :: BasePart
	for _, q in enemies(p) do
		local qr = rootOf(q)
		if qr and (qr.Position - root.Position).Magnitude <= radius then
			local flat = Vector3.new(qr.Position.X - root.Position.X, 0, qr.Position.Z - root.Position.Z)
			if flat.Magnitude > 0.01 then
				knock(q, (flat.Unit + Vector3.new(0, 0.3, 0)).Unit * push)
			end
		end
	end
	event(if teamBurst then "TeamBurst" else "ComboBreaker", { p.UserId })
	publish(p)
end)

-- ===== Regen tick: ki (tier-scaled, x3 while charging), guard =====
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then
		return
	end
	local step = acc
	acc = 0
	for p, s in cs do
		if p.Parent then
			local rules = Combatant.tierRules(p)
			local mult = if p:GetAttribute("Charging") then Config.KI.chargingRegenMult else 1
			local st = RaceRuntime.stats(p, s.ki / Config.KI.max)
			if st.infiniteKi then
				s.ki = Config.KI.max -- Android: infinite ki (no ki bar)
			else
				s.ki = math.min(
					Config.KI.max,
					s.ki + (Config.KI.regen * rules.kiRegen * st.combat.kiRegen * mult - st.kiDrainPerSec) * step
				)
				if s.ki <= 0 then
					s.ki = 0
					if st.kiDrainPerSec > 0 then
						RaceRuntime.onKiEmpty(p)
					end
				end
			end
			if not s.blocking then
				s.guard = math.min(SK.GuardMax, s.guard + SK.GuardRegen * step)
			end
			publish(p)
		end
	end
end)

-- ===== Energy drink (v1.1): in-match consumable, max 1 per match. +40% ki, 5 s speed boost. =====
local DRINK = Config.ENERGY_DRINK
local drinkUsed: { [Player]: boolean } = {}
UseItemRemote.OnServerEvent:Connect(function(p, item)
	if item ~= "EnergyDrink" or not RateLimit.allow(p, "item", 2, 2) or not canAct(p) then
		return
	end
	if drinkUsed[p] then
		return
	end
	if workspace:GetAttribute("Ranked") == true and not Config.RANKED.allowItems then
		return
	end
	local free = Config.DEV_MODE and RunService:IsStudio()
	if not free and not PlayerData.consumeDrink(p) then
		return
	end -- needs stock (bought/daily/quest)
	local h = humOf(p) :: Humanoid
	drinkUsed[p] = true
	p:SetAttribute("EnergyDrinks", 0)
	Combatant.addDrinkBoost(p, DRINK.powerBoost, DRINK.powerTime)
	local s = S(p)
	s.ki = math.min(Config.KI.max, s.ki + Config.KI.max * DRINK.kiFrac)
	local base = h.WalkSpeed
	h.WalkSpeed = base * DRINK.speedMult
	p:SetAttribute("SpeedBoostUntil", workspace:GetServerTimeNow() + DRINK.speedTime)
	task.delay(DRINK.speedTime, function()
		if h.Parent then
			h.WalkSpeed = base
		end
	end)
	event("EnergyDrink", { p.UserId })
	publish(p)
end)

function Combat.resetPlayer(p: Player)
	if cs[p] and (cs[p].knockdownUntil or 0) > os.clock() then
		getUp(p)
	end
	cs[p] = nil
	S(p)
	publish(p)
end

-- Called by RoundManager at match end (Erase is once per match).
function Combat.resetRound()
	eraseUsed = false
	RaceRuntime.resetRound()
	table.clear(drinkUsed)
	for _, q in Players:GetPlayers() do
		q:SetAttribute("EnergyDrinks", 1)
	end
	table.clear(lastHit)
	table.clear(pendingBeams)
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InRaid") ~= true then -- v10: don't wipe a raid / story fight (e.g. a boss struggle) mid-run
			Combat.resetPlayer(p)
		end
	end
end

-- BindableFunction for external combat code: RegisterHit:Invoke(attacker, targetModel, baseDamage) -> multiplier
do
	local folder = Net.hook("PlayerDamaged").Parent :: Instance
	local bf = folder:FindFirstChild("RegisterHit") :: BindableFunction?
	if not bf then
		local nb = Instance.new("BindableFunction")
		nb.Name = "RegisterHit"
		nb.Parent = folder
		bf = nb
	end
	(bf :: BindableFunction).OnInvoke = function(attacker, target, base)
		return Combat.registerHit(attacker, target, base)
	end
end

local function initPlayer(p: Player)
	S(p)
	publish(p)
	p:SetAttribute("EnergyDrinks", 1)
end
Players.PlayerAdded:Connect(initPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	initPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	cs[p] = nil
	pendingBeams[p] = nil
	drinkUsed[p] = nil
end)
for _, q in Players:GetPlayers() do
	if q:GetAttribute("EnergyDrinks") == nil then
		q:SetAttribute("EnergyDrinks", 1)
	end
end

return Combat
