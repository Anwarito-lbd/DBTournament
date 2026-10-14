# DRAGON BLOCK Z — Full Game Design Document (v1.0, Oct 13 2026)
Roblox, team PvP anime fighter. The flagship mode is **Tournament of Power**. Owner of this document: db-gameplay. Lead: roblox.

**Status tags used throughout:**
- **[IMPL]:** in code today (`gameplay/src`, `map/`, `animation/`).
- **[CONFIG]:** the numbers exist in `Config.lua`, but the system is not built yet.
- **[PLANNED]:** design only.

**Sources of truth:**
- Gameplay code and Config: `gameplay/SPEC.md` (v5) and `gameplay/src/ReplicatedStorage/Shared/Config.lua`. **Config numbers win** over this document if they ever differ.
- `MASTER_DESIGN.md`
- `UPGRADE_UX_PLAN.md`
- `PLAYER_RESEARCH.md`
- `MONETIZATION.md`
- `story.md` / `StoryDialogue.lua`
- `map/layout_spec.md`, `map/training/training_spec.md`
- `animation/movesets_v4.md`, `VFX_QUALITY_BAR.md`

**IP and brand rules:**
- **Original assets only:** original logo, UI, voices and music. No ripped audio and no official logos.
- **Energy drink:** the "Dragon Block Z" energy drink is our own brand.
- **Names:** character names are used as fan tribute; see the risks in `UPGRADE_UX_PLAN.md` §8.

---
## 0. Pillars
1. **Feels like the show.** Screams, auras, power levels climbing, beam struggles, ring-outs, and a destructible arena.
2. **Skill beats stats.** Every stat edge in a fight is compressed to **at most 1.35×**. Paid power is also capped at 1.35×. Ranked is fully normalized.
3. **Fast to fun.** First fight in under 90 seconds, Super Saiyan within the first session, XP from every match, and no XP loss.
4. **Team spectacle.** Universes fight as teams: team combos, a team-charged Spirit Bomb, the last energy gift, fusion.
5. **Fair money.** Cosmetics and time-savers. No paid random power, and any paid random cosmetic shows its odds and has pity. All power can be earned.

## 1. Core loop
```
Join → (first time: 60 s Whis tutorial in the Time Chamber) → Lobby hub (World of Void)
  → choose: Tournament of Power | Ranked | Training | Raids | Story | Shop / Dragon Pass / Quests
  → match: team assignment → character select (12s) → countdown → fight (≤300s) → results (XP, Zeni, quest ticks, pass XP)
  → unlock: characters, forms, races and power-ups by level → return to the hub (daily reward, Dragon Ball hunt)
```
- **Session target:** 3–5 matches plus one Training visit, about 25 minutes.
- **Habit layer:** daily streak, 3 daily and 3 weekly quests, the weekly Dragon Ball hunt (Shenron wish), and the seasonal Dragon Pass.

## 2. Progression
### 2.1 Levels 1–500 [IMPL]
- **XP to next level:** `xpToNext(L) = floor(60 + 10·L^1.35)` for L ≤ 100, and `5071 + 8·(L−100)` above that.

| Level | XP to next | Cumulative | Approx. play time at 50 XP/min |
|---|---|---|---|
| 2 | 85 | 70 | 1 min |
| 5 | 147 | 383 | 8 min |
| 10 | 283 | 1.4k | 28 min (14 with the first-session ×2) |
| 15 (SSJ) | 447 | 3.1k | ~60 min (~**30** with first-session ×2 [PLANNED]) |
| 30 | 1,046 | 13.8k | 4.6 h |
| 50 | 2,026 | 43.8k | 15 h |
| 100 | 5,071 | 217k | 72 h |
| 250 | 6,271 | ~1.07M | ~360 h |
| 500 | 8,271 | ~2.9M | ~960 h base (~480 h with 2× XP) |

- **XP sources [IMPL]:**

  | Source | XP |
  |---|---|
  | Participation | 50 per match |
  | Playtime | 10/min |
  | KO | 15 |
  | Placement | 5 × rank |
  | Win | 100 |
  | Team-combo link | 3 |

  A typical 5-minute match gives about 200–300 XP.
- **XP multipliers (multiplicative) [IMPL]:**
  - 2× XP pass ×2
  - VIP ×1.25
  - 30-minute boost ×2
  - prestige +5% each
  - Training area multiplier ×1–4 (applies in Training only)
- **First-session ×2 XP [PLANNED]:** for the first 30 minutes. This meets the PLAYER_RESEARCH goal of "SSJ in the first session".
- **Never:** no XP or Zeni loss on death.
- **Power Level per level:** `+50 PL` per level. Combat compression (§4) means level alone can never give more than a 1.35× edge.

### 2.2 Unlock table by level
| Level | Unlock |
|---|---|
| 1 | Goku, Vegeta, Gohan, Piccolo, Cabba, Caulifla, Kale, Kahseral, Cocotte, Kunshi, Ribrianne, Rozie, Kakunsa, Paparoni, Koitsukai, Panchia, Ganos, Shantza, Caway, Bergamo, Lavenda, Basil, Rubalt, Jilcol, Murisam |
| 3 | Power-up KiBlast |
| 5 | KaioKen; Android 17/18; U11 troopers; U2/U3/U4/U9/U10 second wave; Obuni |
| 8 | Krillin, Tien, Frost and the rest of the third wave |
| 10 | FullPower form, SignatureBeam power-up (Kamehameha etc.), Dyspo, Saonel, Pirina, Narirama |
| 12 | Master Roshi |
| **15** | **Super Saiyan**, Hit |
| 20 | Frieza, Toppo |
| 25 | Instant Transmission, Anilaza |
| 30 | SSJ2 |
| 35 | Potara (earrings), Kefla (u6_kefla), KeflaPotara |
| 40 | SSJ3 |
| 45 | Ultimate (Gohan) |
| 50 | Jiren |
| 55 | Golden (Frieza) |
| 60 | Super Saiyan God |
| 75 | Super Saiyan Blue, Legendary (Kale) |
| 85 | Ultra Instinct Sign |
| 90 | SSB Evolved (Vegeta), **Moro** (u7_moro) |
| 95 | Beast Gohan, Black Frieza, Moro Awakened |
| 100 | Mastered Ultra Instinct, Ultra Ego |
| 101–249 | Prestige cosmetics: auras, titles, every 25 levels [PLANNED] |
| **250** | **Gods of Destruction** (`div_destroyer_*`), or prestige 1 |
| **350** | **Angels** (`div_angel_*`), or prestige 3 |
| **450** | **Grand Priest** (`div_grand_priest`), or prestige 5 |
| **500** | **Zeno** (`div_zeno`, event only), or prestige 10. **Prestige becomes available.** |

The unlock levels up to 100 are canonical Config values [IMPL]. The divine level thresholds are [IMPL] (level OR prestige).

### 2.3 Prestige [IMPL]
- **When:** available at Lv500, up to prestige 10.
- **Effect:** resets level and XP, keeps all unlocks, and gives +5% XP per prestige.
- **Cosmetics [PLANNED]:** each prestige grants a prestige frame and an aura tint.

## 3. Race system [PLANNED, v1.3]
Every champion belongs to a **race**, and the race gives passive traits plus **race power-ups** unlocked by level. Race traits never break the stat model:
- **Passives** are utility (regen, ki economy, mobility).
- **Damage passives** stack inside the 1.35× compression.
- **Ranked** keeps race utility but normalizes numbers (every passive at 50% strength).

| Race | Champions (examples) | Passive trait | Race power-ups (unlock level) |
|---|---|---|---|
| Saiyan | Goku, Vegeta, Gohan, Cabba, Caulifla, Kale, Kefla | **Zenkai:** after a KO revive (Senzu or gift), +5% PL for the rest of the match (max 2 stacks) | Great Ape roar (taunt buff, Lv20), Saiyan Pride (+ki regen at < 30% HP, Lv60) |
| Frieza race | Frieza, Frost | **Space-born:** flight speed +10%, immune to ring-out *low-Y* timer for 0.5 s extra (1.5 s grace) | Tail Whip (Lv10), Golden Training (+Golden duration, Lv55) |
| Namekian | Piccolo | **Regeneration:** 1.5% max HP/s after 4 s without damage | Giant Form (Lv40): 10 s, hurtbox ×1.6, knockback dealt ×1.3, speed ×0.8; Fusion-with-Nail (+10% PL, Lv70) |
| Majin | (Buu raid boss; future champions) | **Rubber body:** −20% knockback taken | Absorb (Lv50, raid-only) |
| Android | Android 17, 18 | **Infinite ki:** ki regen never stops while blocking or attacking (+25% regen), but **cannot charge** (no PL charge boost) | Barrier (Lv5, 17), Energy Field (Lv40) |
| Earthling | Krillin, Tien, Master Roshi | **Technique:** −15% cooldowns, Solar Flare blind 1.5 s | Multi-Form (Lv8, Tien), Evil Containment (Lv12, Roshi) |
| Pride Trooper | Jiren, Toppo, Dyspo, Kahseral… | **Justice:** +10% team combo bonus per link (0.11 instead of 0.10) | Justice Pose (team buff 5 s, Lv15) |
| Kaioshin | (future: Shin, Zamasu) | **Divine sense:** see enemies' Power Level through walls within 60 studs | Kai Kai teleport (Lv60) |
| Angel | `div_angel_*` | **Autonomous dodge:** 35% chance to auto-vanish a non-ultimate hit (8 ki per proc, 1.5 s internal cooldown) | Time Rewind (HP to 3 s ago, 30 s cooldown) |
| Destroyer | `div_destroyer_*` | **Destroyer aura:** −20% ki-blast damage taken | Hakai (see §5.3), Sphere of Destruction |

### 3.1 Stacking rules (canonical)
- **Form multipliers do not stack with each other.** Only one form is active at a time.
- **Kaioken × Blue (Blue Kaioken):** for Goku in SSB only. The effective multiplier is `SSB.mult × 1.15`, with a ki drain of 4/s and HP self-damage of 1%/s. It counts as a form layer inside the 1.35× compression [PLANNED].
- **Ultra Ego growth:** +5% damage per 10% HP lost, capped at +40%. It is applied before compression and pairs with db-animation's `UltraEgoGrowth` VFX hook [PLANNED].
- **Beast rage meter (Gohan):** fills 1% per 1% HP lost by Gohan or by teammates within 40 studs. At 100% he can enter BeastGohan without the 3 s cinematic. The meter decays 2%/s when out of combat [PLANNED].
- **Android infinite ki:** see the race table. Androids get no charge PL bonus, but their ki never runs dry. They are counter-picked by guard break.
- **Namekian regen + Giant form:** regen pauses during Giant form, and Giant form can't be used during fusion.
- **Additive boosts:** charge (≤ +0.5), gift (≤ +0.5), absorb (≤ +0.25) and drink (+0.10, paid bucket) add inside `(1 + …)` in the PL formula. The whole stack is then compressed.
- **Fusion:** race passives come from the controller's race, except Kefla (Saiyan).

## 4. Stat model (all formulas) [IMPL unless tagged]
- **Power Level (display, matchmaking):**
  ```
  PL = floor( (min(base, earnedBase) + level·50) · min(formMult, earnedForm) · paid · (1 + charge + gift + absorb) · wish )
  ```
  - `paid = clamp( (base/earnedBase if the champion is paid-early) · (formMult/earnedForm if the form is paid-early) · (1 + drinkBoost), 1, 1.35 )`, where `PAID_STAT_CAP = 1.35`.
  - `earnedBase` is the highest base among non-divine champions the player has reached by level. `earnedForm` is the best form multiplier earned for the current champion.
  - An item counts as "paid-early" when it is owned while level < its unlock level, at prestige 0.
- **Combat ratio (tier gap compression):**
  ```
  ratio = clamp( (PL_att / PL_vic)^0.25 , 1/1.35 , 1.35 )
  ```
  - Damage is multiplied by ratio, knockback by √ratio, and beam-struggle inputs by ratio.
  - **Ranked:** PL is 3500 for everyone and `ratio = 1`.
- **Damage:** `dmg = move.damage · power · ratio · comboMult`, where `comboMult = 1 + 0.10·links` (up to 5).
  - Blocked hits take 15% chip damage. A guard break deals 50%.
- **Knockback:** `kb = move.kb · power · (1 + 1.5·missingHP%) · √ratio`, plus 0.35 up-vector.
- **Ki:** pool 100, `regen = 8/s · tier.kiRegen · (3 while charging)`. A parry gives +10.
- **Counterplay by tier:**

  | Tier | Hurtbox | Ki regen | Recovery | Budget |
  |---|---|---|---|---|
  | C | 1.00 | 1.00 | 1.00 | 1 |
  | B | 1.05 | 0.95 | 1.05 | 2 |
  | A | 1.10 | 0.90 | 1.10 | 3 |
  | S | 1.20 | 0.85 | 1.15 | 4 |
  | GoD | 1.30 | 0.75 | 1.25 | 6 |
  | Angel | 1.30 | 0.75 | 1.25 | 7 |
  | Grand Priest | 1.35 | 0.70 | 1.30 | 9 |
  | Zeno | 1.40 | 0.70 | 1.30 | 10 |

  The tier comes from base power: S ≥ 1000, A ≥ 850, B ≥ 750, otherwise C.
- **Team budget:** `Σ cost ≤ 3·teamSize + 1`. It's waived in event mode.
- **Worked example:** a Lv100 Goku in MUI (×6) fully charged against a Lv5 Krillin. The PL ratio is about 9 (≈ 37k vs 1.2k), and `9^0.25 = 1.73`, which is capped at **1.35×**. Krillin's parry, vanish and positioning still decide the fight.

## 5. Champion roster
Roles: **R** rusher, **Z** zoner, **T** tank, **S** support, **A** assassin. The kit is M1 string + 4 skills + ultimate + forms.
- **Implemented moves [IMPL]:** M1, Heavy, KiBlast, Kamehameha (as the generic SignatureBeam), Absorb, Copy, FinalExplosion and Erase.
- **Everything else [PLANNED]:** follows `animation/movesets_v2.md` and `movesets_v4.md`. In-combat cinematics are ≤ 3 s.

### 5.1 Headliners
| ID | Tier/Role | Base / Lv | Skills (1–4) | Ultimate | Forms |
|---|---|---|---|---|---|
| u7_goku | S/R | 1000 / 1 | Kamehameha (hold), Instant Transmission (to lock-on or ally), Kaioken burst, Dragon Fist | **Spirit Bomb** (team charge, §6.6) | KaioKen, SSJ, SSJ2, SSJ3, SSG, SSB, UltraInstinctSign, MUI (+Blue Kaioken) |
| u7_vegeta | S/R | 1000 / 1 | Galick Gun, Big Bang Attack, Final Flash, guard-crush rush | **Final Explosion** [IMPL] (≤ 25% HP, self-KO) | SSJ, SSJ2, SSG, SSB, SSBEvolved, UltraEgo |
| u7_gohan | A/R | 950 / 1 | Masenko, Rage Rush, Father-Son Kame (with a Goku ally), Special Beam Cannon (Beast) | Beast SBC | SSJ, SSJ2, Ultimate, BeastGohan |
| u7_piccolo | A/Z | 850 / 1 | Special Beam Cannon, Hellzone Grenade, Stretch Grab, Regenerate | Light Grenade | (Giant via race; Orange [PLANNED]) |
| u7_frieza | S/Z | 1000 / 20 | Death Beam, Death Saucer, Nova Strike, Psychokinesis throw | Death Ball (arena chunk) | FullPower, Golden, FriezaBlack |
| u7_moro | S/A | 1100 / 90 | **Absorb** [IMPL], **Copy** [IMPL], Energy Absorption Touch, Clone | Planet Drain (r30, 3 pulses) | MoroAwakened |
| u11_jiren | S/T | 1200 / 50 | Glare counter, Power Impact, Infinity Rush, Meteor combo | Full Power Meteor | FullPower |
| u6_hit | S/A | 1050 / 15 | **Time Skip** (0.6 s local freeze, 20 s cooldown), Time Cage, invisible punch, Death Blow | Pure Progress rush | (Pure Progress [PLANNED]) |
| u6_kefla | S/R | 1900 / 35 | Gigantic Ray, Kefla Rush, Spark Burst, Crush Cannon | Ultimate Spark Burst | KeflaPotara, SSJ, SSJ2 |
| fus_gogeta / fus_vegito | S (fusion only) | 2600 | Stardust Breaker, Big Bang Kamehameha / Spirit Sword, Final Kamehameha | — | SSJ, SSB |

### 5.2 Full roster (tier from Config base) [IMPL IDs]
- **S tier:** u7_goku, u7_vegeta, u7_frieza, u7_moro, u11_jiren, u11_toppo, u6_hit, u6_kefla, u3_anilaza
- **A tier:** u7_gohan, u7_piccolo, u7_android_17, u7_android_18, u11_dyspo, u6_cabba, u6_caulifla, u6_kale, u6_frost, u2_ribrianne, u4_ganos, u9_bergamo, u10_obuni
- **B tier:** u11_kahseral, u11_cocotte, u11_kunshi, u6_saonel, u6_pirina, u2_rozie, u2_kakunsa, u2_jimeze, u2_zircor, u3_paparoni, u3_koitsukai, u3_panchia, u3_bollarator, u3_katopesla, u3_viara, u4_shantza, u4_caway, u4_majora, u4_damom, u9_lavenda, u9_basil, u10_rubalt, u10_jilcol, u10_murisam, u10_napapa
- **C tier:** u7_krillin, u7_tien, u7_master_roshi, u11_vuon, u11_zoiray, u11_tupper, u6_botamo, u6_magetta, u2_vikal, u2_hermila, u2_prum, u3_maji_kayo, u3_nigrisshi, u3_narirama, u4_gamisaras, u4_monna, u4_nink, u9_hop, u9_sorrel, u9_oregano, u9_roselle, u9_comfrey, u10_jium, u10_lilibeu

C-tier champions are deliberately *good* picks: hurtbox ×1.0, full ki regen, fastest recovery, and budget cost 1. Each one gets a utility skill (Solar Flare, Multi-Form, Evil Containment, barriers) [PLANNED].

### 5.3 Divine tiers (playable, capped)
| ID family | Tier / base | Kit [PLANNED unless noted] | Limits |
|---|---|---|---|
| `div_destroyer_<beerus, belmod, champa, quitela, sidra, rumsshi, iwne, heles, mosco, liquiir, arak, giin>` | GoD / 2000 | **Hakai**: 2 s lock-on charge, interruptible by any hit. It instant-KOs only a target below 15% HP, and otherwise deals 70. Sphere of Destruction (40), Hakai Field. | Lv250 or P1, ≤ 2 per match, 1 per team, within budget |
| `div_angel_<whis, vados, marcarita, cognac, cukatail, kusu, sour, campari, martinu, mojito, korn>` | Angel / 2400 | Support: auto-dodge 35%, damage ×0.6, Staff Tap ragdoll, Time Rewind, Angelic Barrier team shield | Lv350 or P3, ≤ 1 per match |
| `div_grand_priest` | GP / 2800 | Controller: Arena Command pull, Rewind ally, Elimination Ruling | Lv450 or P5, **event only** |
| `div_zeno` | Zeno / 3200 (non-combat) | **Erase** [IMPL]: once per match, 8 s warning, erases one random enemy. Can't deal or take damage. | Lv500 or P10, **event only** |

## 6. Combat
### 6.1 Controls (PC / mobile / console) — see UPGRADE_UX_PLAN §3.5
- **PC [IMPL]:** LMB M1, G Heavy, 1–2 beams, F block, Q dash, E vanish, R breaker, V struggle, C charge, T/Y specials.
- **Mobile [PLANNED]:** auto lock-on within a 40° cone, plus a layout editor and haptics.

### 6.2 M1 strings [IMPL base, PLANNED variants]
- **Basic M1:** cooldown 0.3 s, damage 5, hitstun 0.35 s, recovery 0.10 s, knockback 8.
- **String:** a 4-hit chain where hit 4 is the launcher (knockback ×4).
- **Rush chase [PLANNED]:** after a launcher, tap dash within 0.6 s to chase and extend (Budokai-style). Each chase costs 10 ki, with a maximum of 2 chases per combo.
- **Heavy:** cooldown 4 s, damage 10, guard break, recovery 0.45 s.

### 6.3 Guard, perfect guard, vanish, breaker [IMPL]
- **Block:** 15% chip damage. Guard is 100 and regenerates 20/s. Blocking needs to face the attacker (dot ≥ 0.2).
- **Perfect guard:** pressed ≤ 0.20 s before the hit. The attacker is stunned 0.8 s and the defender gains +10 ki. VFX: silver rim and a 0.25 s client slow-motion.
- **Guard break:** a Heavy or guard reaching 0. The defender is stunned 1.2 s and takes 50% damage.
- **Vanish:** 25 ki, cooldown 3 s, 0.35 s i-frames. The player teleports behind their last attacker within 20 studs.
- **Dash-cancel:** 15 ki to cancel recovery.
- **Combo breaker:** only while in hitstun. 50 ki, cooldown 8 s, 0.4 s i-frames, pushback 50 within r10.

### 6.4 Beam struggle math [IMPL]
- **Trigger:** two enemy beams aimed within 20 studs of each other's caster, fired within 0.2 s of each other.
- **Duration:** up to 4 s.
- **Scoring:** each input scores `w = (1 or 3 if within ±0.12 s of the 0.5 s pulse) × ratio`. Inputs are capped at 15/s.
  - The skill ceiling is therefore about 3 × 8 on-pulse inputs + mashing, while stats can shift it by at most ±35%.
- **Win:** reaching ±30. The winner's beam hits at ×1.25 and the arena chunk at the loser's position is destroyed.
- **Tie** (|score| < 3): both take 15 damage.

### 6.5 Team combos [IMPL]
- Hits from different teammates on one target within 1.5 s chain links: `+10% per link`, up to 5, with +3 XP each.
- A combo breaker resets the chain.
- **Pride Trooper bonus [PLANNED]:** +11% per link.

### 6.6 Team Spirit Bomb [PLANNED, v1.2]
- **Cast:** Goku (or any Saiyan with the Spirit Bomb power-up) raises it: hold for 6 s, armored, with movement ×0.3.
- **Teammates contribute:** teammates within 60 studs hold **Give Ki** (5 ki/s each, up to 4 donors).
  - Size: `radius = 6 + 0.35·ki` (max 30). Damage: `40 + 0.6·ki` (max 100). Arena damage: `DamageAt(pos, radius, 150 + ki)`.
- **Counterplay:** the bomb is slow (40 studs/s) and can be deflected by a perfect guard from any S-tier or higher defender, which redirects it at 50%.
- **Server validation:** donor distance, alive, same team, and a ki ledger on the server.

### 6.7 Last energy gift [IMPL]
- On a KO or ring-out, the eliminated player has 2 s to gift a teammate within 40 studs of their death position.
- **Effect:** `+min(0.5, 0.25 + 0.5·charge)` PL boost for 20 s, plus half the ki charge.
- Limited to one gift per round.

### 6.8 Fusion [IMPL]
| | Dance | Potara |
|---|---|---|
| Channel | 3 s, both still within 12 studs, any hit fails it | 1.5 s within 10 studs, needs earrings (Lv35 or pass) |
| Duration | 60 s | 90 s |
| Pairs | Goku + Vegeta → Gogeta | Goku + Vegeta → Vegito; Caulifla + Kale → Kefla |
| Fused HP | avg × 1.3 | avg × 1.3 |

- **Control:** the player with the higher PL controls the fused character, and the partner spectates.
- **Endings:**
  - **Timeout:** both are restored with the HP percentage of the fused body.
  - **Fused character eliminated:** both are eliminated.
  - **Failure:** a 10 s cooldown.
- **Fusion PL:** it counts the fusion base, so compression applies as usual.

### 6.9 Ring-out and destruction [IMPL]
- **Ring-out:** touching a non-ring surface, or Y < 480 for more than 1 s.
- **Arena damage:** chunks crack, crater, then fall. Ki blast r6/p25, Kamehameha r18/p120, Final Explosion r35/p220.
- **Arena size:** `Arena.Resize(teams, players)` from db-map scales the arena up to 40 players.

## 7. Modes
### 7.1 Tournament of Power [IMPL]
- **Size:** 2–40 players. Teams: `min(n, clamp(max(floor(n/3), ceil(n/5)), 2, 8))`, at most 5 per team.
- **Rules:** last universe standing wins. On timeout, the most survivors wins; a tie is a draw.
- **Timings:** 300 s round, 12 s character select, 20 s intermission.
- **Cutscenes:** the intro and ending (Super Shenron, wish choice) come from db-story.

### 7.2 Ranked [IMPL rules; PLANNED queue]
- **Formats:** 1v1 and 3v3, unlocked at Lv15.
- **Normalization:** stats are fully normalized (PL 3500, ratio 1, tier rules C). Consumables, Senzu and divine picks are off. Forms are cosmetic plus a 5 s "awakening" moveset [PLANNED].
- **Elo:** start at 1000. `K = 32` for the first 20 matches, then `K = 20`. Expected score `E = 1/(1+10^((Rb−Ra)/400))`. In team matches each player uses the team-average Elo.
- **Ranks:**

  | Rank | Elo range |
  |---|---|
  | Earthling | < 1000 |
  | Saiyan | 1000–1199 |
  | Elite | 1200–1399 |
  | God | 1400–1599 |
  | Angel | 1600–1799 |
  | Grand Priest | 1800+ |

  Grand Priest is limited to the top 100.
- **Seasons:** 8 weeks. Rewards are cosmetic only (auras, a title, a ring trail).

### 7.3 Story arcs [PLANNED, v2]
- **Format:** co-op for 1–4 players. Each arc is 3–5 missions of 5–10 minutes, narrated with `StoryDialogue`.
- **Arcs:** Saiyan, Namek (Frieza), Androids, Buu, Super (Hit, Jiren), Moro, Super Hero (Beast Gohan).
- **Difficulty:** tuned by player count with no AI spikes; boss HP scales as `1 + 0.6·(players−1)`.

### 7.4 Raids [PLANNED, v2]
- **Format:** 4–8 players against a multi-phase boss: Legendary Broly (rage phases at 66% and 33%), Moro (absorbs abilities), Super Buu, Jiren.
- **Drops:** cosmetics and Zeni, using a deterministic weekly first-clear reward plus a published-odds cosmetic drop (free, not paid).

### 7.5 Training camps [CONFIG + map built; server PLANNED v1.2]
| Area (db-map) | What | Gains |
|---|---|---|
| Hyperbolic Time Chamber | Whis tutorial and drills (movement, M1, perfect block, vanish, struggle) plus sparring bots; gravity 10 | XP ×4, max stay 600 s per visit |
| Gravity Room | Console from 1 to 500 G; movement ×1.0 down to ×0.35 | XP ×1 to ×2.5 by step |
| King Kai Planet | Catch Bubbles, Hit Gregory (3 clears) | Unlocks KaioKen early; XP ×2 |
| Whis Ground (Beerus planet) | **Whis UI path**: dodge-only drills, 10 stages, which unlock UltraInstinctSign progress. **Beerus path**: Hakai drill and damage-taken trial that progress Ultra Ego. | XP ×3 |

- **Training unlocks:** training "path" unlocks are **earned alternatives**. Clearing the full Whis path unlocks UltraInstinctSign at Lv70 instead of Lv85, and the Beerus path unlocks UltraEgo at Lv85 instead of Lv100. They are never stat grants.
- **Training never gives stats.** It only feeds the XP curve and earned unlocks.

### 7.6 Events
- **Zeno's Festival (weekly):** event mode, divine champions allowed, Erase enabled.
- **Double-XP weekends.**

## 8. Economy
### 8.1 Zeni [PLANNED except wish payout]
- **Sources:**

  | Source | Zeni |
  |---|---|
  | Match | 20 + 5/KO + 30 per win |
  | Daily quest | 100–200 |
  | Weekly quest | 600 |
  | Daily streak | 100–400 |
  | Raids | 300–800 |
  | Dragon Pass | various |
  | Restoration wish | 500 [IMPL] |

  Expected income is about 1,500 Zeni per hour.
- **Sinks:**

  | Sink | Zeni |
  |---|---|
  | Cosmetic shop | 500–8,000 |
  | Aura recolours | 1,000 |
  | Race reroll | 5,000, or 99 R$ |
  | Stat reset | 1,000 |
  | Training stays beyond the free 3/day | 200 |
  | Energy drink | 750 |

  Zeni can't buy level-locked power.
### 8.2 Shop (Capsule Corp, Bulma)
- **Rotation:** 6 slots (db-map `ShopItemSlot 1..6`) rotating daily, plus a featured bundle.
- **Previews:** 3D preview in a ViewportFrame.
- **Pricing:** clear Zeni and Robux prices.
### 8.3 Robux items (from MONETIZATION.md; ProcessReceipt idempotent [IMPL])
- **Game Passes:** 2× XP 449, 2× Zeni 349, Time Chamber VIP 799 (×2 form mastery), +2 loadout slots 199, VIP 499, Flying Nimbus 149, Aura & beam colours 99, Emote pack 149, IT lobby travel 99, Scouter skins 79, Supporter bundle 2,499.
- **Early-unlock passes [IMPL]:** EarlySuperSaiyan, EarlyBlue, EarlyJiren and PotaraEarrings. These are **capped by `PAID_STAT_CAP`** and off in Ranked.
- **Developer Products:**
  - **[IMPL]:** XP boost 30 min, XP pack, Senzu, and Energy Drink ×3 (49).
  - **[PLANNED]:** Zeni packs 49/199/499/1,299 and instant form unlock 199–499 (capped, never divine).
- **Policy:**
  - No paid random power items.
  - A cosmetic crate reroll (49) shows exact odds in the UI before purchase and has a pity at 10.
  - Paid random items are hidden for players where `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted` is true.
  - Every receipt is deduplicated by `PurchaseId` and granted only after a successful save [IMPL].
### 8.4 Dragon Pass [PLANNED v1.2]
- **Structure:** 50 tiers on a free track and a premium track. Premium is 399 R$; Premium+ (25 tier skips plus an exclusive aura) is 999 R$. Seasons last 6–8 weeks.
- **Progress:** 1,000 pass XP per tier. Matches give 100–200, quests give 300–1,000.
- **Rewards:** cosmetic and QoL only.
- **Free track:** includes 1 champion unlock (one that's already earnable) and Zeni.
### 8.5 Quests [PLANNED v1.2]
- **Daily** (3, from King Kai's board): e.g. win a beam struggle (150 Zeni), land 3 perfect guards (100), gift energy once (100).
- **Weekly** (3): e.g. win 5 ToP matches (600), complete a Gravity Room 300G session (600), ring out 10 enemies (600).
- **Rerolls:** one free reroll per day.
### 8.6 Daily rewards [IMPL]
- **Streak:** 7 days: 100 Zeni / 150 Zeni / 1 drink / 250 Zeni / 500 XP / 400 Zeni / 2 drinks + Senzu + `Aura_Streak7`.
- **Reset:** missing a day resets the streak.
### 8.7 Dragon Ball hunt and Shenron wishes [PLANNED v1.2]
- **Hunt:** each week, 7 Dragon Balls spawn at seeded positions in the hub and training areas. Each player sees their own instances; the Dragon Radar (free) shows the distance.
- **Wish:** collecting all 7 lets you summon Shenron and pick one wish:
  - **XP:** 24 h of ×1.5 XP
  - **Cosmetic:** choice of 1 from 3 rotating
  - **Zeni:** 3,000
  - **Reroll:** re-roll your race
- Deterministic, no randomness in the reward.
- **Super Dragon Balls (ToP winners) [IMPL]:** Power (title "Multiverse Champion", stat boost 1.1, which counts as earned and is compressed) or Restoration (+500 Zeni server-wide, Halo cosmetic).
### 8.8 Energy drink [IMPL]
- **Effect:** +40% ki, +10% PL for 8 s (paid bucket), +30% speed for 5 s.
- **Limits:** 1 per match, off in Ranked.
- **Sources:** product ×3 (49 R$), Zeni 750, daily days 3 and 7, quests.

## 9. Social
- **Parties [IMPL]:** up to 6, with invites and friend-join. Party mode keeps the party on one team; parties larger than the team cap are split evenly.
- **Clans per universe [PLANNED v2]:**
  - **Membership:** a clan of up to 30 pledges to Universe 1–12 (lore). Clans earn weekly points from ToP wins.
  - **Rewards:** the top 3 per universe get a banner on the universe stand (db-map `Stand_Uxx`).
  - **Clan wars:** Saturday, 5v5 normalized.
- **Spectate [IMPL]:** an orbit camera on teammates after elimination, a free camera, and target cycling.
- **Leaderboards [PLANNED]:** weekly wins, Ranked Elo and Training records. The leaderboard monolith is in the hub.
- **Emotes, crowd reactions and MVP replay [PLANNED].**

## 10. UX / HUD
- **First-time user flow [PLANNED v1.1]:** a 6 s skippable cold open, then 4 prompts with Whis in the Time Chamber, then a 2v2 bot match, then the reward screen, then the hub. First fight in under 90 s.
- **HUD [IMPL v1, `HUD.client.lua`]:**
  - Top centre: universe pips and the timer.
  - Top left: teammates with HP and a gift button.
  - Bottom left: HP, 5-segment ki, and the Scouter-green Power Level.
  - Bottom centre: 4 skills, ultimate ring and transform.
  - Right side: kill feed and the combo counter.
  - Damage numbers are off by default.
- **Character select [PLANNED v1.2]:** universe tabs (lore), All and Favourites; locked cards show their level or price; 3D preview; tier and role badges; a live team strip with duplicates blocked by reason (`PickResult` [IMPL]); budget meter (`Team.Budget/BudgetUsed` [IMPL]).
- **Accessibility:** screen-shake slider, photosensitivity toggle (at most 1 impact frame per 1.5 s), VFX intensity slider, colour-blind team palettes.

## 11. Audio / VFX style
- **Hit feel** (db-animation `GameFeel`, `VFX_QUALITY_BAR.md`):

  | Hit | Hitstop |
  |---|---|
  | Light | 40 ms |
  | Finisher | 90 ms |
  | Heavy / guard break | 120 ms |
  | Ultimate | 150 ms + 0.4× slow-motion |
  | KO | 250 ms freeze + 2 inverted impact frames |

- **Visual style:** cel shading with outlines; per-form auras in 3 LODs; anime speed lines; afterimages; destruction decals; a darker sky as damage rises.
- **Budget:** 2,000 particles per client. Mobile halves the emit rates.
- **Audio:** layered hits; original or soundalike scream packs; dynamic music (calm → intense when ≤ 25% of players remain → an original choir on UI activation).

## 12. Live-ops calendar
| Cadence | Content |
|---|---|
| Daily | Shop rotation, 3 quests, streak |
| Weekly | Zeno's Festival (Fri), Double XP (Sat–Sun), Dragon Ball hunt reset (Mon), raid boss rotation, leaderboard reset |
| Biweekly | One new champion or form (mini-update) |
| Monthly | New raid boss or story arc; balance patch (tier and base review from analytics) |
| 6–8 weeks | Dragon Pass season + Ranked season |
| Seasonal | Halloween Janemba aura, Winter Shenron, anniversary Super Dragon Ball event |

## 13. Anti-exploit
- **[IMPL]:**
  - The server is authoritative for damage, eliminations, XP, unlocks, purchases, fusion, gift, Erase and Final Explosion.
  - Clients send intent only, and every remote is type-checked and rate-limited with a token bucket.
  - Range, origin (8 studs) and line-of-sight checks.
  - Cooldowns, ki and recovery are tracked on the server.
  - Knockback takes server network ownership.
  - Session-locked DataStore saves, and an idempotent ProcessReceipt.
  - The client's VFX callbacks (`OnDetonate`) are ignored.
- **[PLANNED]:**
  - **Lag compensation:** server rewind ≤ 200 ms of position history (10 Hz ring buffer) for hit validation.
  - **Movement anti-cheat:** a speed/teleport sanity check (> 1.5× the allowed speed for 0.5 s, or > 50 studs without dash/vanish/IT → rubber-band; 3 strikes → kick, logged).
  - **Anti-teaming in FFA:** damage against a target that 2+ others hit in the last 3 s is ×0.8.
  - **Analytics-based anomaly flags:** K/D, XP/hour and Zeni/hour beyond 4σ.

## 14. Analytics KPIs
| KPI | Target |
|---|---|
| D1 / D7 / D30 retention | 35% / 12% / 5% |
| First fight time | < 90 s (p50) |
| SSJ reached in session 1 | ≥ 50% of new players |
| Avg session length | ≥ 22 min |
| Matches per session | ≥ 3 |
| Payer conversion | 3–5% |
| ARPDAU | 0.02–0.04 USD |
| Ranked participation (Lv15+) | ≥ 25% |
| Pick-rate spread | No champion > 12% or < 0.5% |
| Win-rate by tier | Within 45–55% (C vs S) |
| Beam-struggle share won by the lower-PL side | ≥ 35% (proves skill > stats) |
| Crash/kick rate | < 1% |

- **Events** (AnalyticsService custom events): `match_start/end`, `pick`, `transform`, `parry`, `struggle_end`, `gift`, `fusion`, `purchase`, `quest_complete`, `level_up`, `funnel_onboarding_step`.

## 15. Implementation status (gameplay-owned items from UPGRADE_UX_PLAN)
| Item | Status |
|---|---|
| HUD | IMPL v1 (`HUD.client.lua`) |
| Energy drink | IMPL (stock, 1/match, paid bucket) |
| Daily rewards | IMPL (`ClaimDaily`) |
| Data schema v6 | IMPL (drinks, dailyDay, lastDaily) |
| Ranked rules layer | IMPL; queue and Elo PLANNED |
| Paid 1.35× cap | IMPL (`Combatant.powerLevel`) |
| Levels 1–500 + divine by level | IMPL |
| Mobile controls / lock-on | PLANNED v1.1 |
| Onboarding (Whis) | PLANNED v1.1 (db-story script) |
| Character select 3D | PLANNED v1.2 (server side `PickResult` and budget IMPL) |
| Quests, Dragon Pass, Zeni shop, Dragon Ball hunt | PLANNED v1.2 |
| Training server logic (teleports, gravity, HTC timers) | PLANNED v1.2 (map built, Config ready) |
| Races | PLANNED v1.3 |
| Spirit Bomb team charge, rush chase, Hakai, Blue Kaioken, Ultra Ego growth, Beast meter | PLANNED v1.2–v1.3 |
| Lag compensation, movement anti-cheat, FFA anti-teaming | PLANNED v1.2 |
| Story arcs, raids, clans, leaderboards | PLANNED v2 |
