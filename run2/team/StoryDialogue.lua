-- ReplicatedStorage/StoryDialogue (ModuleScript)
-- Each beat has: cam (camera preset), actors (ids), action, speaker, text, duration
local Dialogue = {}
Dialogue.RoundTimeSeconds = 300

Dialogue.Intro = {
	{ cam = "VoidEstablishWide", actors = {}, duration = 7 },
	{ cam = "CraneToRing", action = "TeleportTeams", perTeam = true, duration = 8 },
	{ cam = "PriestMedium", actors = {"npc_grand_priest"}, action = "Bow", speaker = "npc_grand_priest", text = "Welcome, warriors of every universe. Please be still. His Majesty is arriving.", duration = 8 },
	{ cam = "ThroneLowAngle", actors = {"npc_zeno","npc_zeno_future","npc_zeno_guard_1","npc_zeno_guard_2"}, action = "ZenoArrive_GuardsBehind", duration = 8 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno"}, action = "Wave", speaker = "npc_zeno", text = "Wow, everybody came!", duration = 2.5 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno_future"}, action = "Wave", speaker = "npc_zeno_future", text = "Yay! It's like a big party!", duration = 2.5 },
	{ cam = "RingEdgeTrack", actors = {"npc_grand_priest"}, action = "RingGlow", speaker = "npc_grand_priest", text = "These are the rules. Anyone who falls from the stage is eliminated. Do not kill your opponents, and use no weapons except your own power. You have five minutes. The team with the most fighters left standing wins.", duration = 14 },
	{ cam = "PriestPushIn", actors = {"npc_grand_priest"}, speaker = "npc_grand_priest", text = "The champions will be granted the Super Dragon Balls. Fight with everything you have.", duration = 6 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno"}, action = "Bounce", speaker = "npc_zeno", text = "Fight hard, okay?", duration = 3 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno_future"}, action = "Bounce", speaker = "npc_zeno_future", text = "Show us something cool!", duration = 3 },
	{ cam = "StandsPan", action = "GodsKaisWatch", perTeam = true, speaker = "God", text = "Don't you dare lose...", duration = 10 },
	{ cam = "FighterCuts", perTeam = true, speaker = "Team", text = "Universe {N}, we're ready!", duration = 8, ["then"] = "FriezaBanterIfApplicable" },
	{ cam = "OverheadCountdown", actors = {"npc_grand_priest"}, action = "Countdown321", speaker = "npc_grand_priest", text = "Three... two... one... Begin!", duration = 5, onEnd = "StartRoundTimer" },
}

Dialogue.Universes = {
	[6]  = { god = "Champa",  angel = "Vados",     line = "We're not the copy. We're the upgrade." },
	[7]  = { god = "Beerus",  angel = "Whis",      line = "We fight for everyone back home." },
	[11] = { god = "Belmod",  angel = "Marcarita", line = "Justice does not lose." },
	[2]  = { god = "Heles",   angel = "Sour",      line = "Love conquers every ring!" },
	[3]  = { god = "Mosco",   angel = "Campari",   line = "Calculations complete. Victory is assured." },
	[9]  = { god = "Sidra",   angel = "Mojito",    line = "We'll drag you down with us!" },
	[10] = { god = "Rumsshi", angel = "Cus",       line = "Our honor returns today." },
	[4]  = { god = "Quitela", angel = "Cognac",    line = "You can't hit what you can't see." },
}

-- Plays in the intro and team taunts when Frieza shares a team with Goku/Vegeta
Dialogue.FriezaBanter = {
	{ speaker = "Frieza", text = "Don't misunderstand, Goku. I'm only here because it suits me.", duration = 4 },
	{ speaker = "Goku", text = "Sure, sure. Just don't knock any of us off the ring, okay?", duration = 3 },
	{ speaker = "Vegeta", text = "One wrong move and I'll throw you off myself, Frieza.", duration = 3 },
	{ speaker = "Frieza", text = "Charming as ever, Vegeta. Try to keep up.", duration = 3 },
}

Dialogue.Ending = {
	{ cam = "WinnersWide", actors = {"npc_grand_priest"}, speaker = "npc_grand_priest", text = "Time. The match is decided, and here are your champions.", duration = 4 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno"}, action = "Clap", speaker = "npc_zeno", text = "That was so much fun!", duration = 2.5 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno_future"}, action = "Clap", speaker = "npc_zeno_future", text = "You're super strong!", duration = 2.5 },
	{ cam = "SkyWide", actors = {"super_dragon_balls"}, action = "SkyDark_BallsGather", duration = 8 },
	{ cam = "StageLowAngle", actors = {"npc_grand_priest","super_dragon_balls"}, action = "BallsFlare", speaker = "npc_grand_priest", text = "Super Shenron, by the authority of the Grand Priest, I summon you!", duration = 5 },
	{ cam = "ShenronCraneReveal", actors = {"npc_shenron"}, action = "RiseGold_RedEyes", duration = 8 },
	{ cam = "ShenronExtremeLow", actors = {"npc_shenron"}, action = "CameraShake", speaker = "npc_shenron", text = "WHO HAS AWAKENED ME? SPEAK YOUR WISH. I CAN GRANT ANYTHING.", duration = 6 },
	{ cam = "LeaderOTS", speaker = "Leader", text = "We've earned this.", duration = 2, triggersWishChoice = true },
}

Dialogue.Wishes = {
	Power = {
		reward = { aura = "ChampionGold", statBoost = 1.1, title = "Multiverse Champion" },
		lines = {
			{ speaker = "Leader", text = "Make us stronger than any warrior in all the universes!", duration = 4 },
			{ speaker = "SuperShenron", text = "Your wish is granted.", duration = 3 },
		},
	},
	Restoration = {
		reward = { cosmetic = "Halo", serverBonusCurrency = 500, title = "Savior of the Multiverse" },
		lines = {
			{ speaker = "Leader", text = "Bring back every universe that was erased!", duration = 4 },
			{ speaker = "SuperShenron", text = "A generous wish. It is granted.", duration = 3 },
		},
	},
}

Dialogue.Outro = {
	{ cam = "SkyWide", actors = {"npc_shenron","super_dragon_balls"}, action = "ShenronDissolve_BallsScatter", speaker = "npc_shenron", text = "IT IS DONE. FAREWELL.", duration = 5 },
	{ cam = "ZenoTwoShot", actors = {"npc_zeno"}, speaker = "npc_zeno", text = "Let's do it again!", duration = 3, onEnd = "ShowRewards" },
}

-- ===== v3 (db-story): live Tournament of Power cinematics + announcer pools =====
-- Placeholders: {player} = fighter name, {universe} = team name ("Universe 7"). All lines are original paraphrase.

-- UniverseErased: both Zenos raise their hands, the stand fades to light, the Grand Priest announces it
Dialogue.Erase = {
	{ cam = "ThroneLowAngle", actors = {"npc_zeno","npc_zeno_future","npc_zeno_guard_1","npc_zeno_guard_2"}, action = "ZenosRaiseHands", pool = "ZenoEraseLines", duration = 2.5 },
	{ cam = "ErasedStandWide", action = "StandFadeToLight", duration = 3.2 },
	{ cam = "PriestMedium", actors = {"npc_grand_priest"}, speaker = "npc_grand_priest", pool = "EraseAnnounce", duration = 3.5 },
}

Dialogue.ZenoEraseLines = {
	{ speaker = "npc_zeno", text = "That universe is all done now. Okay!" },
	{ speaker = "npc_zeno_future", text = "Nobody's left over there. Let's tidy it up!" },
	{ speaker = "npc_zeno", text = "Hmm... no more fighters? Then it goes away." },
	{ speaker = "npc_zeno_future", text = "Ready? Together, one, two..." },
}

Dialogue.EraseAnnounce = {
	"{universe} has no fighters remaining. By His Majesty's decree, it is erased.",
	"And so {universe} is gone. The tournament continues.",
	"His Majesty has spoken. {universe} returns to nothing.",
	"Every warrior of {universe} has fallen. Their universe is no more.",
	"With that, {universe} ceases to be. Fighters, please carry on.",
	"Let the others take note: {universe} has been erased from the multiverse.",
}

-- SurvivalEvent (Universe Survival guest fighter)
Dialogue.SurvivalWarn = {
	"A guest fighter will enter the stage in five seconds. Prepare yourselves.",
	"Attention, everyone. A very strong visitor arrives in five seconds.",
	"His Majesty has invited a special entrant. Five seconds, please brace.",
}

Dialogue.SurvivalEnter = {
	{ cam = "BossSkyDrop", action = "BossEntrance", duration = 1.8 },
	{ cam = "BossCloseUp", speaker = "Jiren", pool = "JirenEntranceLines", duration = 2.8 },
	{ cam = "PriestMedium", actors = {"npc_grand_priest"}, speaker = "npc_grand_priest", text = "Every universe is his target. Whoever brings him down earns a reward.", duration = 3 },
}

Dialogue.JirenEntranceLines = {
	{ speaker = "Jiren", text = "Your numbers mean nothing. Only strength stands here." },
	{ speaker = "Jiren", text = "Come, all of you. I will not hold back." },
	{ speaker = "Jiren", text = "I trust no one's power but my own. Show me yours." },
}

Dialogue.SurvivalDefeated = {
	"Splendid. {player} of {universe} has brought down the guest fighter.",
	"The guest fighter has fallen. The reward goes to {player} and {universe}.",
	"Remarkable. {player} has bested our special entrant for {universe}.",
}

Dialogue.SurvivalEnd = {
	"The guest fighter's time is up. He withdraws from the stage.",
	"Our visitor departs undefeated. Please continue the match.",
}

-- ToP announcer: eliminations (KO) and ring-outs
Dialogue.EliminationAnnounce = {
	"{player} of {universe} can no longer fight. Eliminated.",
	"A clean knockout. {player} leaves the stage, and {universe} is one fighter down.",
	"Please take note: {player}, from {universe}, is out of the match.",
	"That was decisive. {player} is eliminated; {universe} must press on without them.",
	"{player} has reached their limit. Eliminated, for {universe}.",
	"Oh my. {player} will be watching from the {universe} stand from now on.",
	"Down and out. {player} of {universe} is finished for this round.",
}

Dialogue.RingOutAnnounce = {
	"{player} of {universe} has left the stage. Ring out.",
	"Out of bounds. {player} is eliminated, and {universe} loses a fighter.",
	"Off the stage means out of the match. Farewell for now, {player} of {universe}.",
	"{player} has been sent over the edge. {universe}, do mind your footing.",
	"A ring out for {universe}. {player}, please return to your stand.",
	"Gravity has the final word. {player} of {universe} is out.",
	"The void is not part of the stage, {player}. You are eliminated.",
}

-- Zeno / Future Zeno reactions (played after some eliminations, the guest fighter's defeat, etc.)
Dialogue.ZenoReactions = {
	{ speaker = "npc_zeno", text = "Ooh, that one flew really far!" },
	{ speaker = "npc_zeno_future", text = "Again, again! Do that again!" },
	{ speaker = "npc_zeno", text = "Hehe. That was a really good punch." },
	{ speaker = "npc_zeno_future", text = "They get all sparkly when they power up. Pretty!" },
	{ speaker = "npc_zeno", text = "Grand Priest, who's winning? I lost count." },
	{ speaker = "npc_zeno_future", text = "I like this one. They're trying super hard." },
	{ speaker = "npc_zeno", text = "Lots of fighters left... this is gonna be fun for ages!" },
	{ speaker = "npc_zeno_future", text = "Whoa! Did you see that? Did you see it?" },
	{ speaker = "npc_zeno", text = "Hmm, that universe is getting kind of small now." },
	{ speaker = "npc_zeno_future", text = "Fighting looks tiring. Good thing we just get to watch." },
}

-- Bulma cheering from the stands when your team scores a KO or ring-out
Dialogue.BulmaCheers = {
	{ speaker = "Bulma", text = "Yes! That's how you do it! Keep going!" },
	{ speaker = "Bulma", text = "Woo! Did everybody see that? That's our team!" },
	{ speaker = "Bulma", text = "Don't you dare slow down now, you've got them on the ropes!" },
	{ speaker = "Bulma", text = "Ha! Somebody get that fighter a medal. Or a snack." },
	{ speaker = "Bulma", text = "Careful near the edge! ...Okay, nice save, nice save!" },
	{ speaker = "Bulma", text = "That's it! Show them what a real universe can do!" },
	{ speaker = "Bulma", text = "I'm not yelling, I'm supporting! GO, GO, GO!" },
	{ speaker = "Bulma", text = "Win this and I'm upgrading everybody's gear. Promise!" },
}

return Dialogue
