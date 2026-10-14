-- Script: ServerScriptService.DevSelfTest  (v1.1, Studio only)
-- Server-logic self tests that run inside the real server VM (same module instances as the game).
-- Trigger: set workspace attribute RunSelfTest = true (Edit) before Play, or at runtime. Results print as
-- "[SelfTest] PASS|FAIL name: detail" and are summarised in workspace attribute SelfTestResult.
-- Multi-client paths (beam struggle between two players, fusion between two players, last-energy gift to a
-- teammate) need 2+ real clients; here they are exercised with mock players / the single real player.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Modules = script.Parent:WaitForChild("Modules")

local function run()
	local TeamAssignment = require(Modules.TeamAssignment)
	local Combatant = require(Modules.Combatant)
	local results, pass, fail = {}, 0, 0
	local function check(name, ok, detail)
		if ok then pass += 1 else fail += 1 end
		local line = string.format("[SelfTest] %s %s: %s", if ok then "PASS" else "FAIL", name, tostring(detail or ""))
		print(line); table.insert(results, line)
	end
	local function try(name, fn)
		local ok, err = pcall(fn)
		if not ok then check(name, false, "error " .. tostring(err)) end
	end

	-- 1) Team assignment with mock players: team counts, sizes, party kept together
	try("teams", function()
		for _, n in { 2, 3, 6, 9, 12 } do
			local mocks = {}
			for i = 1, n do mocks[i] = { Name = "Mock" .. i, UserId = -i, Team = nil, power = 800 + i * 37 } end
			local groups = {}
			local party = { mocks[1], mocks[2] } -- friends queued together
			table.insert(groups, party)
			for i = 3, n do table.insert(groups, { mocks[i] }) end
			local teams = TeamAssignment.assign(groups, function(p) return p.power end)
			local sizes, powers = {}, {}
			for _, m in mocks do
				local t = m.Team
				if t then sizes[t] = (sizes[t] or 0) + 1; powers[t] = (powers[t] or 0) + m.power end
			end
			local minS, maxS, minP, maxP = 99, 0, 1e9, 0
			for t, s in sizes do minS = math.min(minS, s); maxS = math.max(maxS, s); minP = math.min(minP, powers[t]); maxP = math.max(maxP, powers[t]) end
			local together = mocks[1].Team == mocks[2].Team
			check("teams n=" .. n, #teams == TeamAssignment.teamCount(n) and maxS - minS <= 1 and together,
				string.format("%d teams, sizes %d-%d, power %d-%d, party together=%s", #teams, minS, maxS, minP, maxP, tostring(together)))
			for _, m in mocks do m.Team = nil end
			TeamAssignment.clear()
		end
	end)

	-- 2) Fusion rules (Config) + server fusion state on the real player
	try("fusion rules", function()
		check("fusion Dance goku+vegeta", Config.fusionFor("u7_goku", "u7_vegeta", "Dance") == "fus_gogeta", Config.fusionFor("u7_goku", "u7_vegeta", "Dance"))
		check("fusion Potara vegeta+goku", Config.fusionFor("u7_vegeta", "u7_goku", "Potara") == "fus_vegito", Config.fusionFor("u7_vegeta", "u7_goku", "Potara"))
		check("fusion Potara kale+caulifla", Config.fusionFor("u6_kale", "u6_caulifla", "Potara") == "u6_kefla", Config.fusionFor("u6_kale", "u6_caulifla", "Potara"))
		check("fusion invalid pair", Config.fusionFor("u7_goku", "u7_frieza", "Dance") == nil, "nil expected")
	end)
	local p = Players:GetPlayers()[1]
	if p then
		try("fusion state", function()
			local before = Combatant.powerLevel(p)
			Combatant.setFusion(p, "fus_gogeta")
			local during = Combatant.powerLevel(p)
			local active = Combatant.activeCharacter(p)
			Combatant.setFusion(p, nil)
			check("fusion setFusion on player", active == "fus_gogeta" and during > before,
				string.format("active=%s PL %d -> %d -> %d", tostring(active), before, during, Combatant.powerLevel(p)))
		end)
		-- 3) Last energy gift: real Combatant.giveGift path (player -> player; teammate validation is RoundManager's)
		try("gift", function()
			local before = Combatant.powerLevel(p)
			Combatant.giveGift(p, p)
			local after = Combatant.powerLevel(p)
			check("energy gift boosts receiver PL", after > before, string.format("PL %d -> %d (boost %s, %ss)", before, after, tostring(Config.LAST_GIFT.boost), tostring(Config.LAST_GIFT.duration)))
			Combatant.resetCombat(p)
		end)
		-- 4) v9: the Power wish is cosmetic/Zeni only -> it must not carry any stat field
		try("wish", function()
			local w = Config.WISHES.Power
			check("Power wish has no stat boost", w ~= nil and w.statBoost == nil, "aura/title/zeni only")
		end)
	end
	-- 5) Beam struggle tuning sanity (two-player runtime path not runnable solo)
	try("struggle cfg", function()
		local st = Config.SKILL.Struggle
		check("struggle config", st.winScore > st.tieScore and st.maxTime > 0, string.format("win=%s tie=%s max=%ss", st.winScore, st.tieScore, st.maxTime))
	end)

	local summary = string.format("%d pass, %d fail", pass, fail)
	print("[SelfTest] " .. summary)
	workspace:SetAttribute("SelfTestResult", summary)
	workspace:SetAttribute("SelfTestLog", table.concat(results, "\n"))
end

local function maybe()
	if workspace:GetAttribute("RunSelfTest") then
		workspace:SetAttribute("RunSelfTest", nil)
		while #Players:GetPlayers() == 0 do task.wait(0.5) end
		task.wait(2)
		run()
	end
end
workspace:GetAttributeChangedSignal("RunSelfTest"):Connect(function() task.spawn(maybe) end)
task.spawn(maybe)
