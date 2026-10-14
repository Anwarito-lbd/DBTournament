--!strict
-- ModuleScript: ServerScriptService.Modules.DestroyerMoves  (TASK_BEERUS.md / GDD §5.3)
-- Hakai (move kind "hakai"): 1 s windup on a locked target, interruptible (caster stunned/dead), dodgeable (target
-- vanish i-frames / out of range / LOS broken at release). PvP: executes only targets < 15% HP, else 20 damage
-- through normal hit resolution (compressed, blockable). Bosses/raid bots: 70 damage.
-- Sphere of Destruction is a regular Config.MOVES ray (no special code). Unlock: BeerusCamp chain, or any
-- div_destroyer_* champion (Config.MOVES.*.freeForPrefix). VFX kinds for VFXCommon/VFXRouter: HakaiWindup, Hakai, HakaiFail.
local Combat = require(script.Parent.Combat)
local DevBots = require(script.Parent.DevBots)
local BossNPC = require(script.Parent.BossNPC)

local DestroyerMoves = {}
local U = Combat.util

local function hakai(p: Player, mv: any, targetPos: Vector3, _id: string)
	local target, _ = U.findTarget(p, { kind = "ray", range = mv.range, width = 3 }, targetPos)
	local bot, _bpos = nil, nil
	if not target then bot, _bpos = DevBots.hitScan(p, { kind = "ray", range = mv.range, width = 3 }, targetPos) end
	local boss = nil
	if not target and not bot then boss = BossNPC.hitScan(p, { kind = "ray", range = mv.range, width = 3 }, targetPos); bot = boss end
	if not target and not bot then U.event("HakaiFail", { p.UserId, "NoTarget" }); return end
	local s = U.state(p)
	local start = os.clock()
	local char = p.Character
	U.PlayVFX:FireAllClients("HakaiWindup", char, if target then target.Character else bot)
	U.event("HakaiWindup", { p.UserId, if target then target.UserId else 0, mv.windup })
	task.delay(mv.windup, function()
		-- interrupted: hit/stunned during windup, died, swapped character
		if not U.canAct(p) or p.Character ~= char or s.stunUntil > start then
			U.event("HakaiFail", { p.UserId, "Interrupted" }); return
		end
		if bot then
			if bot.Parent then
				if boss then BossNPC.damage(p, bot, mv.bossDamage) -- bosses: 70, never an execute
				else DevBots.hit(p, bot, { damage = mv.bossDamage, kb = 0, parryable = false }, 1) end
			end
			U.PlayVFX:FireAllClients("Hakai", bot, nil)
			return
		end
		local t = target :: Player
		local ar, tr = U.rootOf(p), U.rootOf(t)
		local ts = U.state(t)
		if not ar or not tr or t:GetAttribute("Alive") ~= true or ts.invulnUntil > os.clock()
			or (tr.Position - ar.Position).Magnitude > mv.range + 5
			or not U.losClear(ar.Position, tr.Position, { p.Character :: Instance, t.Character :: Instance }) then
			U.event("HakaiFail", { p.UserId, "Dodged" }); return
		end
		local h = U.humOf(t)
		if not h then return end
		if h.Health / math.max(1, h.MaxHealth) < mv.executeBelow then
			U.PlayVFX:FireAllClients("Hakai", t.Character, nil) -- dissolve
			U.event("Hakai", { p.UserId, t.UserId })
			local tag = h:FindFirstChild("creator") :: ObjectValue?
			if not tag then local n = Instance.new("ObjectValue"); n.Name = "creator"; n.Parent = h; tag = n end
			(tag :: ObjectValue).Value = p
			U.EliminateHook:Fire(t, p, "KO")
			h.Health = 0
		else
			Combat.resolveHit(p, t, { damage = mv.pvpDamage, kb = mv.kb, guardDamage = mv.guardDamage, hitstun = mv.hitstun,
				parryable = false, kind = "hakai" }, 1)
			U.PlayVFX:FireAllClients("HakaiFail", t.Character, nil)
		end
	end)
end

Combat.registerKind("hakai", hakai)
return DestroyerMoves
