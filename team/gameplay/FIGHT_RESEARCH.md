# Fight research: how the best fighting games build hits, combos and animation

Research for fight plan P1 (real animations) and P2 (hits that land), and the base for Story Mode and training.
Written 2026-10-17. We study how these games *design* combat; nothing is copied (no assets, footage or audio).

Sources:
- The Strongest Battlegrounds (TSB) wiki [Basic Combat](https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat)
- GAMES.GG [Jujutsu Shenanigans beginner guide](https://games.gg/roblox/guides/jujutsu-shenanigans-beginners-guide/)
- Insider Gaming Sparking! ZERO [attack guide](https://insider-gaming.com/dragon-ball-sparking-zero-attack-guide/) and [defense guide](https://insider-gaming.com/dragon-ball-sparking-zero-defense-guide/)
- Bandai Namco [Sparking! ZERO patch notes](https://www.bandainamcoent.com/news/dragon-ball-sparking-zero-patch-note-june-23-2025)
- Roblox DevForum [Fast Paced Combat](https://devforum.roblox.com/t/fast-paced-combat/2944831) and [hitbox](https://devforum.roblox.com/t/is-this-a-good-way-to-do-hitboxes-in-combat-games/3001235) threads
- Episode list: [Dragon Ball wiki](https://dragonball.fandom.com/wiki/List_of_Dragon_Ball_Super_episodes)

Fan wikis and guides change. Treat exact numbers as "what the game did when the page was written".

## 1. What each game gets right

### The Strongest Battlegrounds (Roblox): readable, punishing, fair

- **The 4-hit M1 string ends in a ragdoll.** Holding M1 gives up to 4 hits (3% + 3% + 4% + 4% damage). If the 4th lands, the opponent is guaranteed to be knocked flying and down.
  - Inputs during the string turn the 4th hit into an **uppercut** (launch) or a **downslam** (pin).
  - After any M1 there is a short window (about 0.2 s) when you can't block, so mashing has a cost.
- **Every hit stuns.** A stunned player can't move, dash, block or counter. Whiffed or blocked big moves stun the attacker, and punishing that is a "true punish".
- **Ragdoll, then escape.** Knocked down for 2 s, you can stand early with a side or back dash (a "ragdoll cancel" / evasive, on a long cooldown). Getting up grants 0.5 s of stun immunity, so nobody can loop you forever.
- **Defence:**
  - Hold block for a 180° frontal guard at reduced speed. Specific moves break guard.
  - A *perfect* block on an M1 makes your next hit a **critical** (3× damage, shatter sound).
  - Another perfect block soon after gives a **Black Flash** (6×, black and red burst).
  - So defence feeds offence.
- **Dashes:**
  - Forward and back share a 5 s cooldown. Side dash has 2 s and shrinks as you lose HP, which rewards a health lead.
  - Side and back dashes **run on the client**, so they feel instant even at 150 ms ping.
  - The forward dash turns into an attack, so it runs on the server.
- **States are the language.**
  - **Armour:** M1s don't interrupt. It's usually granted on hit.
  - **I-frames:** nothing touches you. Cinematic supers grant them on hit.
  - **Armour break**, **roll** (a knock state with no evasive) and **ragdoll**.
- **Wall combos:** a 4th hit, uppercut or downslam near a wall, then a forward dash, gives a short cinematic per character (12% damage, 5 s cooldown).
- **Anti-team "Burst":** a per-character escape and combo extender for being double-teamed. It's directly relevant to a team battle royale like the Tournament of Power.
- **Move types are named:** basic, barrage (damage accumulates and can be parried), grab and multi-grab, splash (AoE), mobility.

### Jujutsu Shenanigans (Roblox): counters you have to read

- **Neutral is M1 trades:** whoever punishes the other's recovery (endlag) wins. Ping, reactions and tracking matter more than raw speed.
- **Block only works facing the attacker.** Turning away means eating the hit. The dash (Q) is "the most important button".
- **Ragdoll cancel:** hold M1 toward the enemy and press Q to break out. Dashing *away* wastes it. Dashing *into* an opponent's long windup turns the escape into a punish.
- **Typed attacks and typed counters:**
  - Every move is melee, bullet, explosion, swarm or domain.
  - There are 10 counters, each beating only some types. A few moves can't be countered.
  - This turns reading the opponent into a skill.
- **Burst works while stunned**, not only while knocked down.
- **Mastery:** using a technique's moves in real fights raises its damage and lowers cooldowns. This is progression that rewards *playing*, not grinding.
- **Awakening / Domain on a meter** that fills through combat. The advice is to spend it when you have position.

### Dragon Ball Sparking! ZERO: the Dragon Ball fantasy

- **Rush chain:** up to 4 light hits ending in a heavy. Hold the heavy to charge a smash (blow-away), or charge fully for a power smash.
  - Up plus heavy is a **lift strike** (send up). Down plus heavy is a **grand slash** (send down).
  - These are the same "4th hit decides the direction" idea as TSB.
- **Follow-ups after a blow-away:** dragon homing (chase), vanishing attack (teleport behind), lightning attack (spike to the ground), throws.
  - Speed-move combos: vanishing assault, step-in rush, burst meteor.
- **Defence is a deep toolbox:**
  - High and low guard. Guarding too long risks a guard break.
  - **Super Perception:** hold before a hit to auto-counter. **Z-Counter:** a chain of mutual vanish counters that grows in damage until someone mistimes. **Revenge Counter**, **Super Counter** and high-speed evasion.
  - Ground and wall recovery with a timed input.
- **Movement is fantasy:** step, dragon dash, Z-burst dash and quick ascend or descend. Wall and ground recovery keep fights airborne.
- **Beam clashes:**
  - A meter fills on its own and resets at the top. Press near the top for big gains, or mash for many small ones. Most total progress wins.
  - Each boost costs ki, and running dry leaves you exhausted afterwards.
- **Skill Count and ki:** skills and counters spend a Skill Count, and blasts spend ki. Patch notes show tuning Skill Count gains (low-HP gain, extra on Attack Break).

## 2. How the Roblox games make it *feel* responsive (engineering)

- **The attacker plays their own animation and sound immediately**, then tells the server. The server owns damage and validates it (distance and facing sanity checks), then relays the effect to *everyone else*.
  - We now do exactly this (FightAnimator prediction plus server echo).
- **Hitboxes are spawned on the animation's contact frame** (a keyframe marker) and checked as a short-lived box in front of the attacker (`GetPartBoundsInBox`, about 0.2 s active window, hits de-duplicated).
  - Use that, never `Touched`. Raycast hitboxes suit fast melee.
- **Ragdolls are simulated on each client** so server latency never freezes a falling body.
- **Movement that isn't an attack runs on the client** (TSB's side and back dash).
- **Every hit applies a brief stun**, which gives feedback and limits chaining. On simultaneous hits, the first one the server received wins.

## 3. What we already have (Config.SKILL / Combat.lua)

| System | Ours today | Compared with the best |
|---|---|---|
| M1 string | 4 hits, 0.35 s hitstun per hit | Same skeleton. The 4th hit doesn't yet branch (uppercut / downslam) or ragdoll |
| Block | Facing check, 15% chip, guard meter 100, regen 20/s | Like JJS and TSB. Missing: no high/low split (SZ) |
| Perfect block | 0.20 s parry window, attacker stunned 0.8 s, +10 ki | Like TSB's flawless block, but no **reward chain** (critical, then Black Flash, or Z-Counter) |
| Guard break | 1.2 s stun, ×0.5 damage | Good |
| Dash / vanish | Dash 0.8 s cd; vanish 25 ki, 3 s cd, 0.35 s i-frames, 12 studs | Fine numbers. Dashes are server-processed; TSB runs side/back dashes on the client |
| Combo breaker | 50 ki, 8 s cd, 0.4 s i-frames, push 50 | Our ragdoll cancel / burst. No anti-team variant |
| Beam clash | Struggle, 0.2 s window, up to 3 beams | Exists; the SZ timing-vs-mash meter is the model to copy |
| Knockback | Grows with missing HP (×1.5) | Good, but no ground/wall bounce or ragdoll state |
| Awakening | Meter on the HUD | Like JJS/TSB awakenings and SZ Sparking mode |

**Conclusion:** our systems are mostly there. What's missing is the animation and feel layer (P1/P2) plus four design gaps:
1. a ragdoll knockdown with cancel and get-up immunity
2. 4th-hit direction branches
3. a perfect-block reward chain
4. an anti-team burst for the free-for-all

## 4. Recommendations for P1 / P2 (in order)

1. **Animation set (P1):** author with keyframe markers for `Hit` (contact frame, where the hitbox spawns), `Sound`, `Smear` and `Cancel` (the earliest frame another action may start).
   - Timing per the existing VFX_QUALITY_BAR: anticipation 4–12 frames, contact 1–2, hold 4–12, recovery.
   - Play through the Animator at Action priority so moves blend with locomotion.
2. **4th-hit branches:** the neutral 4th hit becomes a blow-away (ragdoll). Up becomes a lift / uppercut launch with an air follow-up. Down becomes a grand slash / downslam that bounces off the stage and cracks it. This uses the destructible arena.
3. **Ragdoll state:** 2 s knockdown, simulated per client. Escape with the combo breaker. Grant 0.5 s stun immunity on get-up to stop infinite loops.
4. **Perfect-block reward:** a parry primes a **Ki Burst** critical on your next hit (aura flash, 2× damage). Parry again inside about 4 s for a **Vanish Counter** that teleports behind the attacker: a Dragon Ball take on Black Flash and Z-Counter.
5. **Beam clash:** move to the SZ model (self-filling bar; timing vs mashing; ki cost per boost; exhaustion after).
6. **Client-side side/back dash** for latency-proof movement. Keep the forward dash (an attack) server-side.
7. **Anti-team burst:** in the ToP free-for-all, being hit by 2+ enemies within a short window unlocks a one-time burst that pushes everyone away.
8. **Training reuses all of this.** The Gravity Room drills already list Movement, M1Combo, PerfectBlock, Vanish and BeamStruggle; add a ragdoll cancel and the 4th-hit branches. Story Mode episodes use the same moves with scripted opponents.

## 5. Tournament of Power episode reference (Dragon Ball Super 96–131)

Titles are from the wiki's episode list. Use these as **references only**: no footage, frames, audio or dialogue goes into the game, and every beat is restaged in-engine with original wording. Official viewing: Dragon Ball Super streams on Crunchyroll.

| Ep | Title | Use for |
|---|---|---|
| 96 | The Time Has Come! To the Null Realm with the Universes on the Line! | Arrival in the Null Realm: the opening flythrough |
| 97 | Survive! The Tournament of Power Begins at Last! | Grand Priest's rules, the start bell, opening free-for-all |
| 98 | Ah, the Uncertainty! A Universe Despairs! | First universe erased: the Zeno erase beat |
| 99 | Show Them! Krillin's Underlying Strength! | Krillin's moment |
| 100 | Rampage! A Crazed Warrior's Savagery Awakens! | Berserk power-up fight |
| 101 | Warriors of Justice Close In! The Pride Troopers! | Universe 11's Pride Troopers |
| 102 | The Power of Love Explodes? The 2nd Universe's Witchy Warriors! | Universe 2 transformations |
| 103 | Gohan, Get Ruthless! Showdown with the 10th Universe! | Gohan |
| 104 | A Transcendent Light-Speed Battle Erupts! Goku and Hit's United Front! | Cross-universe team-up |
| 105 | A Valiant Fight! Master Roshi's Blaze of Glory! | Master Roshi's last stand |
| 106 | Find them Out! Deathmatch with a Furtive Attacker! | Invisible attacker |
| 107 | Revenge "F"! A Cunning Trap is Set? | Frieza's scheming |
| 108 | Frieza and Frost! A Mutual Malevolence? | Frieza and Frost |
| 109 | The Mightiest Enemy Zeroes in on Goku! Launch the Knockout Spirit Bomb Now! | Spirit Bomb vs Jiren |
| 110 | Goku Enkindled! The Awakened One's New Ultra Instinct! | Ultra Instinct -Sign- awakening |
| 111 | An Extra-Dimensional Ultimate Battle! Hit vs. Jiren! | Hit vs Jiren (time skip) |
| 112 | A Saiyan Oath! Vegeta's Resolve! | Vegeta's resolve |
| 113 | With Great Joy! The Fighting Freak Saiyans' Battle Rejoined! | Saiyan rematch |
| 114 | Bloodcurdling! The Explosive Birth of a New Super Warrior! | Kefla, Potara fusion |
| 115 | Goku vs. Kefla! Super Saiyan Blue Beaten? | Goku vs Kefla |
| 116 | Signs of a Turnabout! The Autonomous Ultra Instinct Erupts! | Ultra Instinct returns |
| 117 | Showdown of Love! The Androids vs. the 2nd Universe! | Androids 17 and 18 |
| 118 | Accelerating Tragedy Vanishing Universes | Universes erased |
| 119 | Unavoidable? The Ferocity of a Stealth Attack! | Stealth attack |
| 120 | A Perfect Survival Strategy! The 3rd Universe's Menacing Assassin! | Universe 3 |
| 121 | All-Out War! The Ultimate Four-Fold Union vs. the 7th Universe's Total Offensive! | Universe 3's merged giant vs Universe 7 |
| 122 | With His Pride on the Line! Vegeta's Challenge to Be the Strongest! | Vegeta |
| 123 | Body, Soul and Power Unleashed! Goku and Vegeta! | Goku and Vegeta together |
| 124 | A Storm-and-Stress Assault! Gohan's Last Stand! | Gohan's last stand |
| 125 | A Commanding Presence! The Advent of Top the Destroyer! | Toppo's God of Destruction mode: Hakai |
| 126 | Surpass Even a God! Vegeta's Sacrifice Strike! | Vegeta vs the destroyer |
| 127 | The Approaching Wall! A Hopeful Final Barrier! | Jiren as the final wall |
| 128 | To the Noble, Proud End! Vegeta Falls! | Vegeta's last attack |
| 129 | A Transcendent Limit Break! Autonomous Ultra Instinct Mastered! | Mastered Ultra Instinct |
| 130 | The Greatest Showdown of All Time! The Ultimate Survival Battle! | Final three-way survival battle |
| 131 | A Miraculous Conclusion! Farewell Goku! Until We Meet Again! | The winner's wish and Super Shenron: our ending |

Next step for this list: per-episode beat sheets (shots, moves, the moment to recreate) for the headline six fighters' signature moments, written in our own words.
