--!strict
-- ModuleScript: ServerScriptService.Modules.RacePowerUps  (v7; GDD §3 race power-ups, Config.RACE_POWERUPS / Config.MOVES)
-- Registered as Combat move kinds, so Combat already validated: round state / training, unlock, race (mv.races), cooldown
-- (x Earthling cooldownMult), ki (x kiCostMult; Android infinite ki), recovery, rate limit.
--  barrier    Android  (Lv5)  2 s: every hit is blocked (no damage/knockback); caster can't attack (locked).
--  justice    Pride Trooper / Jiren-type (Lv15)  1 s pose (locked, vulnerable), then allies within 30 studs (incl. self)
--             get JusticeBuff (+5% dmg/def, 5 s) -- through StatResolver: combat cap, 1.35x compression, Ranked = 1.
--  solarflare Earthling (Lv8)  enemies within 25 studs FACING the caster are blinded 1.5 s (can't fire ki rays;
--             attribute BlindUntil for the client whiteout). Ranked: 50% duration (utility kept, reduced).
--  kaikai     Kaioshin (Lv60)  teleport next to an ally within 150 studs (aim near them) or to a point within 80 studs
--             with clear line of sight; 0.3 s i-frames.
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Combat = require(script.Parent.Combat)
local RaceRuntime = require(script.Parent.RaceRuntime)

local RacePowerUps = {}
local U = Combat.util
local C = Config.RACE_POWERUPS
local function ranked(): boolean return workspace:GetAttribute("Ranked") == true end

Combat.registerKind("barrier", function(p, _mv, _t, _id)
	local s = U.state(p)
	local now = os.clock()
	s.barrierUntil = now + C.Barrier.duration
	s.locked = true; s.blocking = false
	U.PlayVFX:FireAllClients("Barrier", p.Character, C.Barrier.duration)
	U.event("Barrier", { p.UserId, C.Barrier.duration })
	task.delay(C.Barrier.duration, function() s.locked = false; U.publish(p) end)
end)

Combat.registerKind("justice", function(p, _mv, _t, _id)
	local s = U.state(p)
	s.locked = true
	local char = p.Character
	U.PlayVFX:FireAllClients("JusticePose", char, nil)
	U.event("JusticePose", { p.UserId })
	task.delay(C.JusticePose.pose, function()
		s.locked = false
		if not U.canAct(p) or p.Character ~= char then return end -- interrupted (KO'd)
		if s.stunUntil > os.clock() then return end -- hit out of the pose
		local pr = U.rootOf(p) :: BasePart
		for _, q in Players:GetPlayers() do
			local qr = U.rootOf(q)
			if (q == p or (q.Team == p.Team and p.Team ~= nil and q:GetAttribute("Alive") == true)) and qr
				and (qr.Position - pr.Position).Magnitude <= C.JusticePose.radius then
				RaceRuntime.addBuff(q, C.JusticePose.buff, C.JusticePose.buffTime)
			end
		end
	end)
end)

Combat.registerKind("solarflare", function(p, _mv, _t, _id)
	local pr = U.rootOf(p) :: BasePart
	local dur = C.SolarFlare.blind * (if ranked() then C.rankedUtility else 1)
	local hit = {}
	for _, q in U.enemies(p) do
		local qr = U.rootOf(q)
		if qr then
			local to = pr.Position - qr.Position
			if to.Magnitude <= C.SolarFlare.radius and to.Magnitude > 0
				and qr.CFrame.LookVector:Dot(to.Unit) >= C.SolarFlare.facingDot -- must be looking at the flash
				and U.losClear(pr.Position, qr.Position, { p.Character :: Instance, q.Character :: Instance }) then
				local qs = U.state(q)
				qs.blindUntil = os.clock() + dur
				q:SetAttribute("BlindUntil", workspace:GetServerTimeNow() + dur)
				table.insert(hit, q.UserId)
			end
		end
	end
	U.PlayVFX:FireAllClients("SolarFlare", p.Character, nil)
	U.event("SolarFlare", { p.UserId, hit, dur })
end)

Combat.registerKind("kaikai", function(p, mv, targetPos, _id)
	local pr = U.rootOf(p) :: BasePart
	local dest: Vector3? = nil
	-- ally nearest to the aim point (within allyRange of caster, within 20 studs of aim)
	local best = 20
	for _, q in Players:GetPlayers() do
		local qr = U.rootOf(q)
		if q ~= p and q.Team == p.Team and p.Team ~= nil and q:GetAttribute("Alive") == true and qr
			and (qr.Position - pr.Position).Magnitude <= C.KaiKai.allyRange and (qr.Position - targetPos).Magnitude < best then
			best = (qr.Position - targetPos).Magnitude
			dest = qr.Position - qr.CFrame.LookVector * 4
		end
	end
	if not dest and (targetPos - pr.Position).Magnitude <= C.KaiKai.pointRange
		and U.losClear(pr.Position, targetPos, { p.Character :: Instance }) then
		dest = targetPos + Vector3.new(0, 3, 0)
	end
	if not dest then U.event("KaiKaiFail", { p.UserId }); return end -- ki/cd already spent: deliberate (no free retries)
	local s = U.state(p)
	s.invulnUntil = os.clock() + C.KaiKai.iframes
	pr.CFrame = CFrame.new(dest :: Vector3) * pr.CFrame.Rotation
	U.event("KaiKai", { p.UserId })
	U.PlayVFX:FireAllClients("KaiKai", p.Character, dest)
	local _ = mv
end)

return RacePowerUps
