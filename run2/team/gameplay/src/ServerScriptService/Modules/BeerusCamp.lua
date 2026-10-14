--!strict
-- ModuleScript: ServerScriptService.Modules.BeerusCamp  (TASK_BEERUS.md; zone = db-map WhisGround / Beerus planet)
-- Quest chain saved in PlayerData profile.beerus.step (schema v7), shown via player attribute BeerusStep (QuestTracker UI).
--  1 Sparring           survive 60 s of Beerus orbs (dodge)                    -> XP, Zeni
--  2 DestructionEnergy  collect 6 purple orbs in 60 s                          -> unlock DestructionSphere (move)
--  3 Hakai              hold position on 5 targets for 1 s each in 40 s        -> unlock Hakai (move); Pride Trooper => title
--  4 GodAura            automatic after 3                                       -> unlock GodAura (passive, +5% def while ki>50%)
--  5 UltraEgo           Saiyan + SSB unlocked: endure 45 s of heavy orbs        -> Ultra Ego earned at Lv85 (instead of 100)
-- Start each trial with StartDrill("BeerusTrial") while inside WhisGround. Dialogue is 1-2 lines, skippable (client).
-- All bonuses flow through StatResolver / Power Level rules (paid cap + Ranked normalization unaffected).
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Races = require(game:GetService("ReplicatedStorage").Shared.Races)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)
local TrainingRooms = require(script.Parent.TrainingRooms)

local BeerusCamp = {}
local DrillUpdate = Net.remote("DrillUpdate")
local PURPLE = Color3.fromRGB(170, 90, 230)
local LINES = {
	Sparring = "Beerus: Entertain me. If you can last a minute, I might even learn your name.",
	DestructionEnergy = "Whis: Destruction energy is just ki without hesitation. Gather it.",
	Hakai = "Beerus: Hakai is about intent. Hold it, then release it. Don't miss.",
	UltraEgo = "Beerus: Stop dodging. Take the hits and let your pride grow with them.",
}

function BeerusCamp.step(p: Player): number
	local prof = PlayerData.get(p) :: any
	return prof and prof.beerus.step or 0
end

local function advance(p: Player, to: number)
	local prof = PlayerData.get(p) :: any
	if not prof then return end
	prof.beerus.step = to
	PlayerData.sync(p)
end

local function trial(p: Player)
	local prof = PlayerData.get(p) :: any
	if not prof or TrainingRooms.areaOf(p) ~= "WhisGround" then return end
	local steps = Config.BEERUS.steps
	local idx = prof.beerus.step + 1
	local st = steps[idx]
	if not st then DrillUpdate:FireClient(p, "Result", { id = "BeerusTrial", ok = false, reason = "ChainComplete" }); return end
	if st.requires then
		local charId = p:GetAttribute("Character") :: string?
		if Races.raceOf(charId) ~= st.requires.race or not PlayerData.hasUnlock(p, st.requires.unlock) then
			DrillUpdate:FireClient(p, "Result", { id = "BeerusTrial", ok = false, reason = "Requires", requires = st.requires }); return
		end
	end
	DrillUpdate:FireClient(p, "Dialogue", { text = LINES[st.id], skippable = true, seconds = 3 })
	DrillUpdate:FireClient(p, "Start", { id = "Beerus_" .. st.id, seconds = st.seconds, step = idx })
	local spot = TrainingRooms.npcSpot("Beerus")
	local center = if spot then spot.Position else (p.Character and (p.Character :: Model):GetPivot().Position) or Vector3.zero
	local ok = false
	if st.drill == "BeerusDodge" then
		ok = TrainingRooms.dodge(p, st.seconds, st.orbSpeed, st.orbEvery, PURPLE, false)
	elseif st.drill == "OrbCollect" then
		ok = TrainingRooms.reach(p, center, st.orbs, st.seconds, 50, nil, nil, PURPLE)
	elseif st.drill == "HakaiTrial" then
		ok = TrainingRooms.reach(p, center, st.targets, st.seconds, 40, nil, st.hold, PURPLE)
	elseif st.drill == "EgoEndure" then
		ok = TrainingRooms.dodge(p, st.seconds, st.orbSpeed, st.orbEvery, PURPLE, true)
	end
	if ok then
		advance(p, idx)
		local reward = table.clone(st.reward)
		if st.id == "Hakai" and Races.raceOf(p:GetAttribute("Character") :: string?) == "PrideTrooper" then
			reward.title = Config.BEERUS.destroyerCandidateTitle
		end
		-- step 4 is automatic
		local nxt = steps[idx + 1]
		if nxt and nxt.auto then advance(p, idx + 1); PlayerData.grantReward(p, nxt.reward) end
		TrainingRooms.finish(p, "BeerusTrial", true, reward)
	else
		TrainingRooms.finish(p, "BeerusTrial", false, nil)
	end
end

TrainingRooms.registerDrill("BeerusTrial", trial)
return BeerusCamp
