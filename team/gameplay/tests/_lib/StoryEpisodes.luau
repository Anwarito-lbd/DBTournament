--!nonstrict
-- ModuleScript: ReplicatedStorage.Shared.StoryEpisodes  (v10, Reborn v4 "Legendary Episodes"; PURE data, no Roblox APIs)
-- Saga episodes: in-engine cinematics + player-controlled objectives / boss / clash / hold, validated by Shared/EpisodeLogic
-- and run by ServerScriptService.Modules.StoryEpisodeService. All subtitles are ORIGINAL wording (no copied anime lines).
-- Shots name ShotLibrary moves; `subject` is an actor role ("lead" | "ally" | "boss") or "anchor" (arena centre).
-- Act kinds:
--   cinematic  camera beats; client replies "ready" when done (server watchdog = maxSeconds)
--   train      objectives counted from server combat signals (storyHit | parry | vanish) vs a sparring partner
--   boss       live fight; ends when boss HP fraction <= `untilHp` (or the boss is defeated if untilHp is nil)
--   clash      boss beam struggle (Combat.startBossStruggle mode "clash"); win = big damage, loss = heavy hit + retry
--   hold       grapple struggle (mode "hold"): keep the grip for maxTime while the ally charges; loss = boss breaks free
-- `checkpoint = true` marks where a KO'd player resumes (the act restarts, boss HP restored to the snapshot taken there).
-- `canon = true` episodes play the legendary fighter (lead), never the custom warrior; results can't diverge from canon.
local StoryEpisodes = {}

StoryEpisodes.LIST = ({
	{
		id = "saiyan_arrival_01",
		order = 1,
		saga = "Saiyan",
		title = "Saiyan Arrival",
		blurb = "An armoured stranger falls from the sky. Goku and Piccolo, sworn rivals, must fight side by side.",
		canon = true,
		minutes = 8,
		lead = "u7_goku",
		ally = { id = "u7_piccolo", name = "Piccolo", visual = "u7_piccolo", color = { 90, 160, 70 } },
		lighting = "StormCanyon",
		-- sparring partner for the training act: high HP, weak telegraphed jab (parry practice)
		spar = {
			id = "spar_piccolo", name = "Piccolo", visual = "u7_piccolo", hp = 100000, walkSpeed = 12, scale = 1.1,
			color = { 90, 160, 70 },
			melee = { damage = 2, range = 9, cd = 2.4, windup = 0.6, kb = 18 },
		},
		boss = {
			id = "boss_raditz", name = "Raditz", visual = "boss_raditz", hp = 2400, walkSpeed = 19, scale = 1.25,
			color = { 40, 40, 55 }, aura = "SaiyanDark",
			phases = { 0.5 },
			phaseMods = { { dmg = 1, speed = 1, cdMult = 1 }, { dmg = 1.25, speed = 1.15, cdMult = 0.8 } },
			melee = { damage = 9, range = 9, cd = 1.5, windup = 0.45, kb = 45 },
			specials = {
				-- parryable 3-hit rush: dashes to the target, each hit telegraphed (block on the flash)
				Rush = { cd = 9, windup = 0.55, hits = 3, gap = 0.35, damage = 7, range = 60 },
				-- ki volley: 4 small circles on the target's position, staggered (keep moving)
				KiVolley = { cd = 7, windup = 0.7, shots = 4, gap = 0.3, radius = 8, damage = 8 },
				-- grab: cone telegraph; if caught you're held -> Combo Breaker (R) or take the slam
				Grab = { cd = 13, windup = 0.8, range = 12, holdTime = 1.6, damage = 18 },
				-- energy wave: long line telegraph down the arena (dash sideways)
				EnergyWave = { cd = 15, windup = 1.1, length = 140, width = 10, damage = 22, vfx = "GalickGun" },
			},
		},
		objectives = {
			{ id = "strike", text = "Land 2 strikes on Piccolo", signal = "storyHit", count = 2 },
			{ id = "parry", text = "Parry Piccolo's jab: block the moment it flashes", signal = "parry", count = 1 },
			{ id = "vanish", text = "Vanish (E / Vanish button)", signal = "vanish", count = 1 },
		},
		clash = { maxTime = 6, winScore = 30, bossRate = 10, winDamage = 0.22, loseDamage = 30, beam = "Kamehameha", bossBeam = "GalickGun" },
		hold = { maxTime = 7, winScore = 30, startScore = 12, bossRate = 9, rearm = 6 },
		finisher = { vfx = "SpecialBeamCannon" },
		rewards = { xp = 600, zeni = 800, title = "Saiyan Arrival" },
		replayFraction = 0.25,
		acts = {
			{
				id = "intro", kind = "cinematic", maxSeconds = 14, summary = "A Saiyan pod has landed. Piccolo is waiting.",
				beats = {
					{ cam = "establishingWide", subject = "anchor", duration = 3.2, fx = { "letterboxGrade" } },
					{ cam = "pushIn", subject = "anchor", duration = 2.6, speaker = "Piccolo", text = "You feel it too. Something huge just fell out of the sky." },
					{ cam = "overShoulder", subject = "ally", duration = 3, speaker = "Goku", text = "Yeah... and it's strong. Stronger than anything I've fought." },
					{ cam = "lowAngleReveal", subject = "ally", duration = 3, speaker = "Piccolo", text = "Then warm up. I won't carry you through this." },
				},
			},
			{ id = "training", kind = "train", checkpoint = true, guide = true },
			{
				id = "arrival", kind = "cinematic", maxSeconds = 8, summary = "Raditz arrives.",
				beats = {
					{ cam = "skyDrop", subject = "boss", duration = 1.6, fx = { "speedLines" } },
					{ cam = "smashZoom", subject = "boss", duration = 1.4, fx = { "impactFrame", "shake" }, speaker = "Raditz", text = "So this is the warrior who forgot what he is." },
					{ cam = "dutchTilt", subject = "boss", duration = 2.4, speaker = "Goku", text = "I don't know you. But you're not leaving here." },
				},
			},
			{ id = "phase1", kind = "boss", checkpoint = true, untilHp = 0.5, allyAssist = true },
			{
				id = "clashIntro", kind = "cinematic", maxSeconds = 4,
				beats = { { cam = "splitClash", subject = "boss", duration = 1.8, fx = { "speedLines", "shake" }, speaker = "Goku", text = "Ka... me... ha... me..." } },
			},
			{ id = "clash", kind = "clash", checkpoint = true },
			{ id = "phase2", kind = "boss", untilHp = 0.2, allyAssist = true },
			{
				id = "holdIntro", kind = "cinematic", maxSeconds = 5,
				beats = { { cam = "orbitCharge", subject = "boss", duration = 2.4, fx = { "shake" }, speaker = "Piccolo", text = "Pin him down! Give me seven seconds!" } },
			},
			{ id = "hold", kind = "hold", checkpoint = true },
			{
				id = "finisher", kind = "cinematic", maxSeconds = 8, finisher = true,
				beats = {
					{ cam = "orbitCharge", subject = "ally", duration = 2.2, fx = { "speedLines" }, speaker = "Piccolo", text = "This one took me years. Don't you dare let go." },
					{ cam = "lowAngleReveal", subject = "boss", duration = 1.4, fx = { "impactFrame", "shake" } },
					{ cam = "whiteOut", subject = "boss", duration = 1.6, fx = { "whiteOut" } },
				},
			},
			{
				id = "resolution", kind = "cinematic", maxSeconds = 10, summary = "Raditz is down, but more are coming.",
				beats = {
					{ cam = "establishingWide", subject = "anchor", duration = 2.6, speaker = "Piccolo", text = "He said others are on their way. Stronger ones." },
					{ cam = "overShoulder", subject = "lead", duration = 3, speaker = "Goku", text = "Then we train harder. Starting today." },
				},
			},
		},
	},
} :: { any }) -- heterogeneous act/beat shapes: validated at runtime by EpisodeLogic.normalize

StoryEpisodes.BY_ID = {} :: { [string]: any }
for _, e in StoryEpisodes.LIST do
	StoryEpisodes.BY_ID[e.id] = e
end

return StoryEpisodes
