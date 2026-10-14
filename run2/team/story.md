# Tournament of Power — Story v2 (db-story)

The scenes follow the show's staging, but all the dialogue is original. Actor ids: npc_zeno, npc_zeno_future, npc_zeno_guard_1, npc_zeno_guard_2, npc_grand_priest, npc_shenron, super_dragon_balls.

## 1. Intro cutscene (~85s)

| # | Time | Camera | Actors / Action | Dialogue |
|---|------|--------|-----------------|----------|
| 1 | 0-7s | Wide establishing shot, slow dolly over the World of Void: an endless white floor, stars and the floating ring | none | Ambient choir. |
| 2 | 7-15s | Crane down to the ring; a quick cut on each beam | Teams teleport onto the stage, one beam per team slot (Universe 1..N) | Teleport SFX on each arrival. |
| 3 | 15-23s | Medium shot on the Priest at the stage-side podium | npc_grand_priest floats forward and bows | Grand Priest: "Welcome, warriors of every universe. Please be still. His Majesty is arriving." |
| 4 | 23-31s | Low angle on the throne, then a white flash | npc_zeno and npc_zeno_future appear together; npc_zeno_guard_1 and npc_zeno_guard_2 take their places behind them | Chime SFX, then silence. |
| 5 | 31-36s | Close two-shot of the Zenos | The Zenos wave | Zeno: "Wow, everybody came!" / Future Zeno: "Yay! It's like a big party!" |
| 6 | 36-50s | Tracking shot along the ring edge | npc_grand_priest gestures and the ring glows | Grand Priest: "These are the rules. Anyone who falls from the stage is eliminated. Do not kill your opponents, and use no weapons except your own power. You have five minutes. The team with the most fighters left standing wins." |
| 7 | 50-56s | Push in on the Priest's smile | npc_grand_priest | Grand Priest: "The champions will be granted the Super Dragon Balls. Fight with everything you have." |
| 8 | 56-62s | Two-shot, slight shake | Zenos bounce on the throne | Zeno: "Fight hard, okay?" / Future Zeno: "Show us something cool!" |
| 9 | 62-72s | Slow pan across the stands | Gods of Destruction and Kais watch from the stands (one pair per team slot), nervous or smug | God (ambient): "Don't you dare lose..." |
| 10 | 72-80s | Rapid cuts on fighters, each in a powering-up pose | Per-team line; FriezaBanter plays if it applies | "Universe {N}, we're ready!" |
| 11 | 80-85s | Overhead shot, a 3-2-1 countdown in the sky, then a flash | npc_grand_priest raises his hand | Grand Priest: "Three... two... one... Begin!" Title card: DRAGON BLOCK Z / TOURNAMENT OF POWER. Start the 300s timer. |

## 2. Universe lore

- **Universe 6 (God: Champa, Angel: Vados).** This is Universe 7's twin. It's proud and hungry, and it's always trying to beat its sibling. Saiyans here are honorable soldiers. Fighters are Cabba, Caulifla, Kale, Hit and Frost. Team line: "We're not the copy. We're the upgrade."
- **Universe 7 (God: Beerus, Angel: Whis).** It has a low mortal level but a stubborn, surprising team. They grow stronger mid-fight. Fighters are Goku, Vegeta, Gohan, Piccolo, Android 17, Android 18 and Frieza, who is temporarily revived and an uneasy ally. Team line: "We fight for everyone back home."
- **Universe 11 (God: Belmod, Angel: Marcarita).** This is the Pride Troopers' universe. It's strict about justice and dramatic about it. Jiren is the strongest mortal in the tournament and fights alone with silent intensity. Fighters are Jiren, Toppo and Dyspo. Team line: "Justice does not lose."
- **Universe 2 (God: Heles, Angel: Sour).** Love and beauty are its power. Fighters transform through song and sparkle and turn affection into strength. Their leader is Ribrianne. Team line: "Love conquers every ring!"
- **Universe 3 (God: Mosco, Angel: Campari).** This is a universe of machines and cyborgs that fight with tactics and fusion protocols. They combine into Anilaza. Their leader is Paparoni. Team line: "Calculations complete. Victory is assured."
- **Universe 4 (God: Quitela, Angel: Cognac).** This is a universe of tricksters. Their fighters use invisibility, illusions and dirty plays. Quitela schemes behind the scenes. Fighters are Ganos, Shosa and Caway. Team line: "You can't hit what you can't see."

- **Universe 9 (God: Sidra, Angel: Mojito).** This is a desperate, crime-ridden universe with the lowest mortal level. Its wolf brothers Bergamo, Lavenda and Basil fight dirty because they have nothing to lose. Team line: "We'll drag you down with us!"
- **Universe 10 (God: Rumsshi, Angel: Cus).** This universe is proud of its brawlers but rusty after Zamasu's betrayal. Obuni fights with calm martial-arts focus and a spirit he can split. Team line: "Our honor returns today."

**Frieza banter (Universe 7 team taunts and intro)**
- Frieza: "Don't misunderstand, Goku. I'm only here because it suits me."
- Goku: "Sure, sure. Just don't knock any of us off the ring, okay?"
- Vegeta: "One wrong move and I'll throw you off myself, Frieza."
- Frieza: "Charming as ever, Vegeta. Try to keep up."

## 3. Ending cutscene (~70s)

| # | Camera | Actors / Action | Dialogue |
|---|--------|-----------------|----------|
| 1 | Wide shot of the winners on the ring | npc_grand_priest | Grand Priest: "Time. The match is decided, and here are your champions." |
| 2 | Two-shot | The Zenos clap | Zeno: "That was so much fun!" / Future Zeno: "You're super strong!" |
| 3 | Wide shot, sky dims to black | super_dragon_balls: seven planet-sized golden balls drift in and gather in a ring | Deep hum. |
| 4 | Low angle from the stage | The balls flare | Grand Priest: "Super Shenron, by the authority of the Grand Priest, I summon you!" (the summoning words are written in the Priest's own style) |
| 5 | Massive crane up, slow reveal | npc_shenron rises: golden body, red eyes, galaxy-sized | Thunder SFX. |
| 6 | Extreme low angle, camera shake | npc_shenron | Super Shenron: "WHO HAS AWAKENED ME? SPEAK YOUR WISH. I CAN GRANT ANYTHING." |
| 7 | Over the shoulder of the team leader; the wish choice UI opens | Leader | Leader: "We've earned this." |
| 8A/8B | Wish VFX | npc_shenron's eyes glow | (see Wishes) |
| 9 | Wide shot | npc_shenron dissolves into light; super_dragon_balls scatter like shooting stars, then the sky returns | Super Shenron: "IT IS DONE. FAREWELL." / Zeno: "Let's do it again!" Then the rewards screen. |

Rewards: Power gives an exclusive aura, a stat boost and the title "Multiverse Champion". Restoration gives a cosmetic halo, bonus currency for the whole server and the title "Savior of the Multiverse".

## 4. Luau dialogue table

```lua
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
	{ cam = "FighterCuts", perTeam = true, speaker = "Team", text = "Universe {N}, we're ready!", duration = 8, then = "FriezaBanterIfApplicable" },
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

return Dialogue
```
