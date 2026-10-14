# DRAGON BLOCK Z — MASTER PLAN (v1.0, 2026-10-13)
Owner: lead "roblox". This file **wins over** every other doc when they disagree. After this, `Config.lua` is the source for numbers, and §3 lists every decision. Coding tools: **Antigravity (AG)** and **OpenCode (OC)** only. Every work package (WP) names its exact files, and no file is in two WPs.
Status (updated 18:21 ET after db-gameplay's v9 pass): save schema **v9**, Rojo `default.project.json` builds a place. Earlier: 62 Lua files compile, 48 plain-Luau tests pass (`sh gameplay/tests/run.sh`). **Nothing has been run in Studio yet.** DEV_MODE = true, and all product IDs = 0.

---
## 1. Vision, pillars, player journey
**Vision:** the Tournament of Power on Roblox. Up to 40 players in numbered universes (Universe 1..N, 2–8 teams of up to 5) fight on a floating ring that breaks apart. Ring-outs, screams, beam struggles, fusion, a team Spirit Bomb, and Zeno erasing the losers. It should feel like the show, and skill should win.

**Pillars**
1. **Feels like the show:** screams, auras, power levels that climb, beam struggles, a destructible ring, Grand Priest calls and Zeno reactions.
2. **Skill beats stats:** every stat edge is compressed to 1.35x. Paid power is capped at 1.35x. Ranked is fully normalized.
3. **Fast to fun:** first fight in under 90 s, Super Saiyan in the first session, XP from every match, and nothing is lost on death.
4. **Team spectacle:** team combos, the Spirit Bomb, the last energy gift, fusion, and team callouts.
5. **Fair money:** cosmetics and time-savers. No paid random power. Crate odds are shown, with pity. All power can be earned.

**First 10 minutes:** a skippable 6 s cold open (Zeno laughs, the Grand Priest speaks, the title appears). Then the Whis tutorial in the Time Chamber with 4 prompts: move/fly, M1 string, block/perfect guard, ki blast + charge scream. Goku is free. Whis says "Now try it for real," and you get an easy 2v2 bot match. The reward screen fills the XP bar to Lv2 or Lv3, teases "Vegeta at Lv3" (in Config Vegeta is Lv1, so the teaser shows the next real unlock), and claims daily day 1. Then the hub, with an arrow to the ToP pad, and a first real ToP match. First-session 2x XP runs for 30 minutes.
**First day (about 25 to 60 min):** 3 to 5 ToP matches, a KaioKen unlock (Lv5, or early through King Kai), King Kai's quest board (3 dailies), a first Gravity Room session, finding 1 or 2 Dragon Balls with the free radar, **Super Saiyan at Lv15** (about 30 min with 2x), Hit unlocked, and the shop seen once on the results screen. The day-2 streak hook is shown.
**First month:** Lv30 SSJ2, Lv40 SSJ3, Lv50 Jiren, Ranked unlocked at Lv15, the Whis path (10 stages, then UI Sign at Lv70), the Beerus camp (Sphere, Hakai, God aura, Ultra Ego at Lv85), weekly Shenron wishes, Broly and Moro raids, story arcs Saiyan to Buu, Dragon Pass season 1 at tier 30 or higher, and a clan (v2). Lv100 MUI/UE takes about 72 h, which is the "core complete" point. Lv250 Gods of Destruction is the long tail.

---
## 2. System registry
Status: **BT** = built and tested (pure tests), **CO** = code only (compiles, untested), **DO** = design only. *No system is Studio-verified yet.*
| # | System | Owner file(s) | Status | Depends on | Open questions |
|---|---|---|---|---|---|
| 1 | Round state machine / ToP | ServerScriptService/RoundManager.server.lua, Modules/Arena.lua, Shared/ToPLogic.lua, ToPAnnouncer.client.lua | BT (ToPLogic) / CO | TeamAssignment, Combat, map/Arena.lua | — (D17, AFK, bot fill built) |
| 2 | Teams / queue / party | Modules/TeamAssignment.lua, Modules/Party.lua | CO | Config | small-lobby bots? (D19) |
| 3 | Character select + budget | CharacterSelectUI.client.lua, server PickResult in RoundManager | CO (UI basic) | Races describe JSON, Config.ROSTER | 3D preview; NPCOnly handling |
| 4 | Combat core (M1, guard, parry, vanish, breaker, beam struggle) | Modules/Combat.lua, Modules/Combatant.lua, CombatInput.client.lua | CO | StatResolver, Net, RateLimit | lag compensation (DO), 3-way struggle (D18) |
| 5 | Stat model / paid cap / Ranked normalization | Shared/StatResolver.lua, Combatant.powerLevel | BT | Races, Modifiers | — |
| 6 | Races + modifiers | Shared/Races.lua, Shared/Modifiers.lua, Modules/RaceRuntime.lua | BT (pure) / CO (runtime) | StatResolver | about 14 race kit items not built (GDD §3 note) |
| 7 | Race power-ups | Modules/RacePowerUps.lua | CO + tests | RaceRuntime | numbers approved in D11 |
| 8 | Fusion | Modules/Fusion.lua | CO | Combat | KO and ring-out while fused (D20) |
| 9 | Spirit Bomb | Modules/SpiritBomb.lua | CO | Combat, ArenaDamage | — |
| 10 | Last energy gift / team combos | Combat.lua | CO | — | — |
| 11 | Arena + destruction + resize | map/BuildArena.lua, map/ArenaDamage.lua, map/Arena.lua, map/ArtPass.lua | CO (mock-run) | — | Resize module path |
| 12 | Training rooms + bots + lighting | Modules/TrainingRooms.lua, TrainingBots.lua, TrainingLighting.client.lua, TrainingUI.client.lua, Shared/TrainingMath.lua, map/training/* | CO + tests | TrainingAreas | Training.lua is now a no-op (delete in v1.3) |
| 13 | Beerus camp / Hakai | Modules/BeerusCamp.lua, Modules/DestroyerMoves.lua | CO | Races, StatResolver | Beerus model |
| 14 | Progression / data | Modules/PlayerData.lua (schema **v9**: clears legacy statBoost) | CO + migration tests | DataStore | session lock in Studio |
| 15 | Quests | Shared/Quests.lua, Modules/QuestService.lua, QuestTracker.client.lua | BT / CO | PlayerData | — |
| 16 | Daily rewards | PlayerData (ClaimDaily) | CO | — | — |
| 17 | Dragon Ball hunt / Shenron | Shared/DragonBalls.lua, Modules/DragonBallService.lua, DragonRadar (N), ShenronWishUI (P) | BT / CO | db-map DBSpawn_NN parts (wired) | — |
| 18 | Ranked | Shared/Elo.lua, Modules/RankedService.lua, RankedUI (K) | BT / CO | TeleportService, OrderedDataStore | cross-server matching (DO) |
| 19 | Raids | Modules/RaidService.lua, Modules/BossNPC.lua, Shared/RaidMath.lua, RaidLobbyUI (O) | BT / CO | db-map raid maps BrolyCrater/MoroNamek (wired), boss rigs | Super Buu, Jiren raids (DO) |
| 20 | Story missions | Modules/StoryMissionService.lua, Shared/StorySchema.lua, gameplay/StoryMissions.lua, StoryUI (M) | BT (data loads) | BossNPC, StoryDialogue | co-op (DO); Rojo mapping done |
| 21 | Store / monetization | Modules/Store.lua, Shared/StoreCatalog.lua, StoreUI.client.lua | CO | PlayerData receipts | product IDs = 0 |
| 22 | Dragon Pass | — | DO | Quests (pass XP stored) | — |
| 23 | HUD | HUD.client.lua | CO | ClientAPI | redesign to the UX plan |
| 24 | Mobile / console controls | — | DO | CombatInput | — |
| 25 | Onboarding (Whis tutorial) | — (IntroCutscene.client.lua is the intro only) | DO | TrainingRooms HTC, DevBots | — |
| 26 | Cutscenes (intro, ending, credits) | Shared/CutsceneDirector.lua, IntroCutscene, EndingUI, CreditsUI, StoryDialogue.lua | CO | — | skip button everywhere |
| 27 | VFX / game feel | animation/*.lua (VFXCommon plus 27 move modules), VFXRouter.client.lua, GameFeel.client.lua, AuraRenderer, TransformCinematic, AnimeStyle | CO | Combat events | perf at 40 players |
| 28 | Spectate | SpectateCamera.client.lua | CO | — | — |
| 29 | Audio (screams, auras, music, announcer) | — | DO | VFXRouter | original/licensed audio only |
| 30 | Anti-exploit | Net.lua, RateLimit.lua, server checks | CO | — | movement anti-cheat, rewind (DO) |
| 31 | Analytics | — | DO | — | — |
| 32 | Localization | — | DO | UIKit | — |
| 33 | Moderation / safety | — (TextChatService defaults) | DO | — | — |
| 34 | Clans / leaderboards / social | Party.lua only | DO | — | v2 |
| 35 | Dev tools | DevBots.lua, DevSelfTest.server.lua, V12Boot.server.lua | CO | — | strip from release |

---
## 3. Conflicts resolved: single source of truth
| ID | Topic | Conflict | Decision (canonical) |
|---|---|---|---|
| D1 | Level cap | MASTER_DESIGN and SPEC §4 say Lv1–100 | **Lv1–500** (Config.MAX_LEVEL). Forms all unlock by Lv100. |
| D2 | XP curve | SPEC §4 uses `floor(100·L^1.5)` | **`floor(60+10·L^1.35)` up to L100, then `5071+8(L−100)`** (GDD §2.1). Fix the SPEC §4 text. |
| D3 | Prestige | Available at Lv100 (MASTER/SPEC) or at Lv500 (GDD) | **At Lv500**, max P10, +5% XP each, keeps unlocks. |
| D4 | Gods of Destruction unlock | Lv100 or P1 (MASTER) vs Lv250 or P1 (GDD) | **Lv250 or P1**. At most 2 per match, within budget outside events. |
| D5 | Angels | Playable at Lv350/P3 (GDD table, MASTER) vs not playable (TASK_RACES) | **NPC-only at launch** (`FEATURES.PLAYABLE_ANGELS=false`, server returns "NPCOnly"). Revisit at live ops. |
| D6 | UI Sign | Lv85; earlier store sale at any level; GDD says Lv70 after 10 Whis stages | **Lv85, or Lv70 after all 10 Whis stages.** There's no other path. The store refuses purchase before it opens a prompt. |
| D7 | Ultra Ego | Lv100 (unlock table) vs Lv85 Beerus path | **Lv100, or Lv85 after the Beerus chain (steps 1–3) plus SSB**, Vegeta-type only. |
| D8 | Zenkai | GDD race table says +5% PL x2 after a revive | **+2% damage/defense per near-death survival (≤15% HP, survive 3 s), up to +10% per match** (TASK_RACES). |
| D9 | Hakai | Always 70 vs execute | **Execute below 15% HP. Otherwise 20 in PvP (blockable, compressed) and 70 against bosses/raids.** 1 s windup, dodged by vanish, goes through Barrier. |
| D10 | Training owner | Training.lua vs TrainingRooms.lua | **TrainingRooms owns it** (`Config.TRAINING_RUNTIME.owner`). Delete Training.lua in v1.3. One lighting owner: TrainingLighting.client.lua. |
| D11 | Race power-up numbers | Undefined | **Approved:** Barrier 30 ki / 15 s / Lv5; Solar Flare 20 ki / 20 s / Lv8 (half in Ranked); Justice Pose 25 ki / 30 s / Lv15, +5% dmg/def for 5 s; Kai Kai 30 ki / 25 s / Lv60 for the race, **but from Lv1 on Kaioshin champions** (Shin Lv20, Zamasu Lv60, which are confirmed roster adds). |
| D12 | Quests | 3 daily + 3 weekly (GDD/UX) vs "8 daily, 5 weekly" | **3 active dailies and 3 active weeklies, rolled from pools of 8 and 5.** One free reroll a day. |
| D13 | Shenron wishes | XP and race reroll wishes (GDD/UX) | **Cosmetic or Zeni only:** 3,000 Zeni, Shenron aura, the "Wish Granter" title, or 1 of 3 outfits. |
| D14 | Dragon Pass | 30 tiers (UX) vs 50 tiers | **50 tiers**, 1,000 pass XP each. Premium 399, Premium+ 999. 6–8 week seasons. |
| D15 | HTC XP | x2 (UX) vs x4 (GDD/Config) | **x4**, max 600 s per visit, 3 free visits a day, then 200 Zeni. |
| D16 | Energy drink | 40% ki + 5 s speed (handoff) vs +40% ki, +10% PL for 8 s, +30% speed for 5 s | **GDD version.** 1 per match, off in Ranked, counts in the paid bucket. |
| D17 | Timeout winner | "Most survivors"; ties not covered | **Most survivors; if equal, highest total remaining HP%; if still equal, a draw** (both get the win XP x0.5). *Built.* |
| D18 | Beam struggle with 3+ beams | Undefined | **Only 1v1.** A third beam into an active struggle adds its input weight x0.5 to the side it supports. A struggle can't start against a beam already in one with 2 casters. |
| D19 | Small lobbies (<4) | Undefined | At 2–3 players, start 2 teams and **fill with DevBots-grade bots up to 4** (bots give 50% XP and no quest ticks). |
| D20 | Fusion edge cases | Partly defined | A KO or ring-out of the fused body eliminates both. If either player disconnects, it defuses at once and the remaining player keeps the HP%. No last energy gift from a fused body. Fusion is blocked in Ranked 1v1. |
| D21 | Transform key | G = Heavy (GDD §6.1) vs G = Transform (UX §3.5) | **G = Heavy, X = Transform** (server "Next" form in the ladder), **3 = Moro Copy** (moved off X). Console: D-pad up = Transform. *Built.* |
| D22 | Stat reset price | 49 R$ (MONETIZATION) vs 1,000 Zeni | **Both.** |
| D23 | Race reroll | Store 99 R$ / 5,000 Zeni; wish removed | Keep the paid/Zeni reroll (races are utility, inside compression). **Off in Ranked** is not needed because Ranked normalizes. |
| D24 | Story mode | Co-op 1–4 (GDD) vs solo (v8 code) | **Solo for alpha; co-op 1–4 in beta.** A story "form" reward is a **real unlock only if its level is already met; otherwise a badge** that grants the form when the level is reached. **SSJ4 is playable**: mult 5, needs story mission 32 ("Mini Mayhem") **and** Lv80 (prestige counts), Goku and Vegeta after SSB, normal 1.35x compression, no paid or flag bypass (`ToPLogic.storyFormOk`). *Built.* |
| D25 | Ranked numbers | Proposals | **Approved:** soft reset `1000+(elo−1000)/2`, decay off, window ±100 widening +50 every 10 s up to ±400, 5 min queue timeout, Elo floor 100. |
| D26 | Max players | "Set 40 in Studio" | Config.MAX_PLAYERS=40, MAX_TEAM_SIZE=5, teams `min(n, clamp(max(floor(n/3), ceil(n/5)), 2, 8))`. **Studio Game Settings Max Players must be 40 (manual step for anwar).** |
| D28 | Universe numbers | Teams were Universe 1..N by index | **Universe 7 always goes to the largest human team** (first on a tie; Bulma's cheer spot). The others are numbered 1..6, 8.. by team index (`ToPLogic.universeNumbers`). *Built.* |
| D29 | Wish stat boosts | Super Dragon Ball "Power" wish gave +10% | **Removed.** Power wish = gold aura + title + 1,000 Zeni; schema v9 clears saved statBoost. *Built.* |
| D27 | Pre-release flags | — | Before publish: DEV_MODE=false, all product IDs set, DevSelfTest and V12Boot dev hooks disabled. |

---
## 4. UI flow and wireframes
Style: UIKit/UIStyle (Scouter green #3CFF6E, Capsule white, orange accents). Every screen works at 1280x720, on phone safe-area, and with a gamepad (selection groups).
1. **Cold open (6 s, skippable):** full-bleed cutscene. Bottom right: "Hold to skip" ring. Returning players skip it automatically.
2. **Whis tutorial (HTC):** top-centre prompt card ("Press LMB x4"), with a progress pip row of 4 and Whis portrait and subtitle bottom left. A "Skip tutorial" button sits in the corner after the first prompt.
3. **Results screen:** a big XP bar animating, the level-up burst, an "unlocks next" card row (3 cards), Zeni and quest ticks, and pass XP. **At most one** shop offer per session, bottom right. Continue button.
4. **Lobby hub HUD:** top left level, Zeni and pass tier; top right buttons for Quests (J), Shop, Pass, Settings; pads in the world are labelled with billboards (ToP Random, Party, Ranked Lv15+, Training, Raids, Story). Bottom left the Dragon Radar mini (distance to nearest ball). Daily reward modal on first join of the day.
5. **Queue panel:** mode, players in queue, ETA and a cancel button; party members' avatars shown.
6. **Character select (12 s):** top team strip (5 slots with live picks; duplicate picks show "Taken by teammate"); left grid with tabs (All, Favourites, U2..U11 lore) where locked cards are greyed with "Lv 35" or a price; right a 3D Viewport idle, tier and role badge, race badge with traits (from races_describe.json), form ladder, difficulty stars; bottom budget meter "Budget 9/16"; a timer ring. NPCOnly/locked result toasts.
7. **Countdown:** Grand Priest banner "Universe 1 vs ... 3, 2, 1, BEGIN!" with universe colours.
8. **In-match HUD:** top centre universe pips and the timer; top left teammate portraits with HP and the Gift button when one is low; bottom left HP, 5-segment ki and PL in Scouter font; bottom centre 4 skills, ultimate ring and the Transform button (next form); right the kill feed and combo counter ("12 HITS!"); a Spirit Bomb donate prompt ("Hold F to give ki") near the caster; beam struggle overlay (centre meter with the pulse marker); fusion prompt. **Mobile**: right-thumb arc (Attack big, Block, Dash, Vanish, 4 skills, Charge, Transform), left joystick, a Fly toggle, and a layout editor in settings.
9. **Elimination / spectate:** "ELIMINATED - ring-out" banner and the Gift prompt for 2 s, then the spectate bar (prev/next teammate, free cam, "Return to lobby").
10. **Zeno erase / ending:** universe-wipe card with the Zeno laugh, then the Super Shenron wish pick (2 cards, 15 s, default Restoration).
11. **Training UI:** area banner; Gravity Room slider (1/10/50/100/150/300/500 G); drill buttons (King Kai CatchBubbles, Whis WhisDodge); stage list for the Whis path (10 pips) and Beerus chain (5 steps with locks).
12. **Quests (J):** 3 daily cards and 3 weekly cards (progress bar, reward, Claim, Reroll once per day); the day's streak strip.
13. **Shop (Capsule Corp):** tabs Featured, Daily 6 slots, Passes, Zeni, Cosmetics; each card has a 3D preview, a clear price, "LOCKED - reason" when gated, and crate odds shown before buying.
14. **Dragon Pass:** horizontal 50-tier track, free row and premium row, a claim-all button, and a buy-premium button.
15. **Dragon Radar + Shenron:** full radar (map-relative arrows, the distance to each of the remaining balls); summon cutscene, then 4 wish cards with a 60 s timer (default Zeni).
16. **Ranked:** rank badge, Elo, season timer, 1v1/3v3 queue buttons, top 100 leaderboard with your own row pinned.
17. **Raids:** boss picker (Broly/Moro), the weekly first-clear indicator, the lobby list (4–8), drop odds shown; boss HP bar with phase ticks in the fight.
18. **Story:** arc list (15 arcs), mission cards (locked/cleared/stars), a briefing panel (objective, twist hidden until triggered, rewards), dialogue box during play.
19. **Settings:** camera shake, photosensitivity (max 1 impact frame per 1.5 s), VFX intensity (1–3), colour-blind team palette, damage numbers, subtitles, language, music/SFX/voice volumes, control remapping and the mobile layout editor.

---
## 5. Content list
### 5.1 Roster (stable IDs; universe is lore only)
Race is by `Races.describe(charId)` (gameplay/data/races_describe.json covers 98 champions). Unlock levels from Config.
| Champion | Race | Tier | Unlock | Forms (unlock Lv) |
|---|---|---|---|---|
| u7_goku | Saiyan | S | 1 | KaioKen 5, SSJ 15, SSJ2 30, SSJ3 40, SSG 60, SSB 75 (+Blue Kaioken), **SSJ4 80 + story 32**, UI Sign 85 / 70 Whis, MUI 100 |
| u7_vegeta | Saiyan | S | 1 | SSJ 15, SSJ2 30, SSG 60, SSB 75, **SSJ4 80 + story 32**, SSB Evolved 90, Ultra Ego 100 / 85 Beerus |
| u7_gohan | Half-Saiyan | A | 1 | SSJ 15, SSJ2 30, Ultimate 45, Beast 95 |
| u7_piccolo | Namekian | A | 1 | Giant (race, Lv40); Orange (planned) |
| u7_android_17 / 18 | Android | A | 5 | none (Barrier, flat upgrades) |
| u7_krillin, u7_tien | Earthling | C | 8 | KaioKen 5 |
| u7_master_roshi | Earthling | C | 12 | Max Power (planned) |
| u7_frieza | Frieza race | S | 20 | FullPower 10, Golden 55, Black 95 |
| u7_shin (new) | Kaioshin | B | 20 | — (Kai Kai) |
| u7_moro | Majin (lore) | S | 90 | Moro Awakened 95 |
| u11_jiren | Jiren-type | S | 50 | FullPower 10 |
| u11_toppo | Pride Trooper | S | 20 | Destroyer candidate (Beerus title) |
| u11_dyspo | Pride Trooper | A | 10 | — |
| other U11 troopers | Pride Trooper | B/C | 1–5 | — |
| u6_hit | Saiyan-default→Earthling (alien) | S | 15 | Pure Progress (planned) |
| u6_cabba / caulifla / kale | Saiyan | A | 1 | SSJ 15, SSJ2 30; Kale Legendary 75 |
| u6_kefla | Saiyan | S | 35 | KeflaPotara 35, SSJ, SSJ2 |
| u6_frost | Frieza race | A | 8 | FullPower 10 |
| u10_zamasu (new) | Kaioshin | A | 60 | — (Kai Kai) |
| u3_anilaza | Earthling-default | S | 25 | — |
| U2/U3/U4/U9/U10 waves | per JSON | A–C | 1–10 | — |
| fus_gogeta / fus_vegito | Saiyan | S (fusion) | Dance / Potara Lv35 | SSJ, SSB |
| div_destroyer_* (12) | Destroyer | GoD | Lv250 / P1 | God aura |
| div_angel_* (11) | Angel | NPC only | — | — |
| div_grand_priest | — | GP | Lv450 / P5, event | — |
| div_zeno | — | Zeno | Lv500 / P10, event | Erase |
Gaps: rigs exist for Goku/Vegeta/Frieza only (poses). Shin, Zamasu, Broly and the story enemies need rigs.

### 5.2 Maps
World of Void lobby hub (3000,100,0); ToP arena (Ø300 ring, 90 chunks, resize to 8 teams and 40 players, universe stands Stand_Uxx); Training: Hub, Capsule Corp shop (Bulma, 6 ShopItemSlots), HTC 10G, Gravity Room 1–500G, King Kai's Planet 10G, Whis/Beerus ground 1.5G XP x3 (about 252 parts). Raid maps BrolyCrater and MoroNamek (RaidArena, 8 RaidSpawn pads, RaidBossPad, RaidFallZone) and DBSpawn_NN Dragon Ball anchors exist and are wired. Arena NPC spots (ArenaNPCSpot) for the crowd. **Missing:** story mission arenas (reuse the training areas plus the arena at alpha), Kame House/Namek props (beta).
### 5.3 Story missions (32, STORY_MISSIONS.md)
Saiyan 1–3, Namek 4–7, Androids 8–9, Cell 10–12, Buu 13–15, Battle of Gods 16–17, Resurrection F 18, Universe 6 19, Goku Black 20–21, ToP 22–26, Broly 27–28, Moro 29, Granolah 30, Super Hero 31, Daima 32. Form rewards in order from Kaio-ken to SSJ4 (per D24). **SSJ4 is a playable form** (mission 32 + Lv80, see D24). It needs its own aura preset "SSJ4" from VFX; a generic aura is used until then.
### 5.4 Raids
Broly (6000 HP, phases at 66/33%, Eraser Cannon, Stomp); Moro (5000 HP, phase at 50%, Absorb, Copy, Planet Drain). Planned: Super Buu, Jiren. 4–8 players, 10 min, HP x(1+0.6(n−1)).
### 5.5 Shop items
Passes: Aura & beam colours 99, 2x XP 449, VIP 499, 2x Zeni 349, Time Chamber VIP 799, +2 slots 199, Flying Nimbus 149, Emote pack 149, IT travel 99, Scouter skins 79, Saiyan Supporter 2,499, Private server 25/month. Early-unlock passes (capped at 1.35x): EarlySuperSaiyan, EarlyBlue, EarlyJiren, PotaraEarrings. Products: Energy drink x3 49, Zeni 49/199/499/1,299, Senzu 99, 30-min 2x XP 79, instant form unlock 199–499 (never divine or UI Sign), crate reroll 49 (odds + pity 10), stat reset 49, race reroll 99. Dragon Pass 399/999. Zeni shop: drink 750, aura recolour 1,000, race reroll 5,000, stat reset 1,000, cosmetics 500–8,000. Mini Shenron pet (later).

---
## 6. Work packages (Antigravity / OpenCode only, no file overlap)
Paths are relative to `team/`. `SSS/` = `gameplay/src/ServerScriptService/Modules/`, `RS/` = `gameplay/src/ReplicatedStorage/Shared/`, `SPS/` = `gameplay/src/StarterPlayer/StarterPlayerScripts/`. "New" means the WP creates the file. Rules for every WP: `--!strict`, server authority, touch only the files listed (each file belongs to exactly one WP), log edits in CHANGES.md (append-only, the one shared file), run `sh gameplay/tests/run.sh`, then stop and report. Ownership and sign-off rules are in `AI_RULES.md` on the PC.

**Status legend:** DONE = db-gameplay already built it (Studio test still pending); PARTLY = what's left is listed; OPEN = not started.

### 6.1 Core packages (WP01–WP26)
| WP | Tool | Status | Files it may touch (exclusive) | What's left / acceptance criteria | Test steps |
|---|---|---|---|---|---|
| WP01 Release flags & config | OC | PARTLY (SSJ4, D17–D21 numbers in Config) | RS/Config.lua, gameplay/SPEC.md | `Config.RELEASE` flag that forces DEV_MODE false and refuses to boot with product IDs = 0; fix SPEC §4 text (D2/D3) | config_tests asserts D4, D6, D7, D11, D15 |
| WP02 Round edge cases | AG | DONE (D17 tiebreak/draw XP, AFK 30 s/90 s, disconnect = elimination, D19 bot fill, U7 numbering) | SSS/../RoundManager.server.lua, SSS/Arena.lua, RS/ToPLogic.lua | Only: a late joiner spectates until the next round; never start with 1 team. | top_tests; Studio 2-player server, one leaves |
| WP03 Team assignment & party | OC | OPEN | SSS/TeamAssignment.lua, SSS/Party.lua | Party split when over the cap; power balance within 10% over 40 seeded lobbies; leadership passes on leave (U7 rule already built) | Seeded lobby tests |
| WP04 Combat edge cases & lag comp | AG | PARTLY (D18 3-beam join built) | SSS/Combat.lua, SSS/Combatant.lua, SSS/SpiritBomb.lua | 200 ms rewind buffer at 10 Hz; FFA anti-teaming x0.8; Spirit Bomb caster KO refunds 50% of donated ki; server side of WP-FEEL-2 (buffer, cancel windows, perfect-guard crit) | Pure tests; Studio 3-client struggle |
| WP05 Fusion edge cases | OC | DONE (KO/ring-out/AFK eliminates both, disconnect defuses, Ranked 1v1 blocked) | SSS/Fusion.lua | Only: Zeno Erase on a fused body erases both (beta) | Studio: ring-out the fused body |
| WP06 Movement anti-cheat | OC | OPEN | SSS/MoveGuard.lua (new), SSS/Net.lua, SSS/RateLimit.lua | Speed > 1.5x for 0.5 s or a jump > 50 studs without dash/vanish/IT/Kai Kai → rubber-band; 3 strikes → kick and log | Synthetic traces; Studio |
| WP07 Race kit completion | AG | OPEN | SSS/RaceRuntime.lua, SSS/RacePowerUps.lua, RS/Races.lua, RS/Modifiers.lua | Frieza ring-out grace, Jiren Power Impact armor, Majin Absorb (raid), Multi-Form, Saiyan Pride | v7_tests; StatResolver still 1.35 |
| WP08 Character select UI | AG | DONE | SPS/CharacterSelectUI.client.lua, gameplay/data/races_describe.json | §4 screen 6; NPCOnly and budget messages; gamepad and phone | 3 clients pick the same champion |
| WP09 HUD + settings | OC | PARTLY (show clock in HUD) | SPS/HUD.client.lua, RS/UIKit.lua, SPS/Settings.client.lua (new) | §4 screens 8 and 19 (UIStyle tokens come from WP-UI-1) | 720p, phone emulator, gamepad |
| WP10 Mobile & console controls | AG | DONE (X Transform, G Heavy, 3 Copy, D-pad up built in CombatInput) | SPS/MobileControls.client.lua (new), SPS/KiChargeInput.client.lua | Mobile arc and layout editor, auto lock-on 40°, Kaioken/Giant toggles, hold-to-donate, Beast release, the 4 power-ups, console radial. *CombatInput.client.lua now belongs to WP-FEEL-2.* | Device emulator, Xbox controller |
| WP11 Onboarding | AG | DONE | SPS/Onboarding.client.lua (new), SSS/OnboardingService.lua (new), SPS/IntroCutscene.client.lua | First fight < 90 s; skippable; first-session 2x XP 30 min; funnel events | Fresh DataStore key, stopwatch |
| WP12 Training & Beerus server polish | OC | OPEN | SSS/TrainingRooms.lua, SSS/TrainingBots.lua, SSS/BeerusCamp.lua, SSS/DestroyerMoves.lua, SPS/TrainingUI.client.lua, SPS/TrainingLighting.client.lua, RS/TrainingMath.lua, SSS/Training.lua (delete) | Delete Training.lua; register King Kai games from WP-TRAIN-2; Whis 10 stages → UI Sign at Lv70 | Studio walk-through of all areas |
| WP13 Store, receipts & policy | OC | PARTLY (lock before prompt, gated receipts) | SSS/Store.lua, RS/StoreCatalog.lua, SPS/StoreUI.client.lua | Real product IDs; PolicyService hides crates; 1 results offer per session; crate odds + pity; private servers | Sandbox purchases; dedup test |
| WP14 Data schema | AG | DONE (v9 migration clears statBoost) | SSS/PlayerData.lua, RS/ClientAPI.lua | Only: v10 fields when needed (settings, pass, onboarding) with migration; verify session lock in Studio | Migration tests; two servers same key |
| WP15 Dragon Pass | OC | OPEN | SSS/DragonPassService.lua (new), RS/DragonPass.lua (new), SPS/DragonPassUI.client.lua (new) | D14; cosmetic/QoL validator | Tier math tests; claim flow |
| WP16 Quests & daily UI | OC | OPEN | RS/Quests.lua, SSS/QuestService.lua, SPS/QuestTracker.client.lua | D12 active-3 from pools; streak strip; comeback reward | quests_tests |
| WP17 Dragon Balls & Shenron | AG | DONE (DragonRadar N, ShenronWishUI P, DBSpawn wired, tested) | RS/DragonBalls.lua, SSS/DragonBallService.lua, SPS/DragonRadar.client.lua, SPS/ShenronWishUI.client.lua | Summon cutscene; Studio pass only | Collect 7, disconnect mid-wish |
| WP18 Ranked | AG | DONE (RankedUI K, Elo, RankedService, 1v1/3v3 queue, snake draft) | RS/Elo.lua, SSS/RankedService.lua, SPS/RankedUI.client.lua | MemoryStore cross-server queue; season rewards | Needs a published place |
| WP19 Raids | OC | PARTLY (RaidLobbyUI O, raid maps wired) | SSS/RaidService.lua, SSS/BossNPC.lua, RS/RaidMath.lua, SPS/RaidLobbyUI.client.lua | In-fight boss HP bar with phase ticks; call TelegraphService (from WP-STORY-2); Super Buu/Jiren later | Solo raid with DEV HP |
| WP20 Story | AG | PARTLY (StoryUI M, Rojo mapping, goals) | SSS/StoryMissionService.lua, RS/StorySchema.lua, gameplay/StoryMissions.lua, SPS/StoryUI.client.lua, StoryDialogue.lua | Co-op 1–4 (beta); SSJ4 reward hook check on mission 32 | Missions 1, 12, 26, 32 |
| WP21 Map additions | AG | PARTLY (raid maps, DBSpawn, NPC spots done) | map/BuildArena.lua, map/ArenaDamage.lua, map/Arena.lua, map/ArtPass.lua, map/training/TrainingAreas.lua, map/training/BuildTraining.lua, map/training/TrainingLightingPresets.lua | Merge WP-VFX-2's lighting proposal; story arenas; part budget | 40-bot MicroProfiler |
| WP22 VFX hookup & perf LOD | OC | OPEN | animation/*VFX.lua **except** BeamStruggleVFX.lua, animation/VFXCommon.lua, SPS/VFXRouter.client.lua, SPS/TransformCinematic.client.lua, SPS/AnimeStyle.client.lua | Hakai, Spirit Bomb, Kaioken, Zenkai, Barrier, JusticePose, SolarFlare whiteout, KaiKai, SSJ4 aura; Beast skip; 2,000 particle cap; LOD. *(AuraRenderer → WP-VFX-1, GameFeel → WP-FEEL-2.)* | 40-bot stress, < 16 ms frame |
| WP23 Announcer | AG | PARTLY (ToPAnnouncer banners) | SSS/Announcer.lua (new), SPS/ToPAnnouncer.client.lua | Grand Priest elimination calls, Zeno reactions, Bulma cheers, team callouts with subtitles, played through WP-AUD-1's registry/mixer | Listen test |
| WP24 Analytics & localization | OC | OPEN | SSS/Analytics.lua (new), RS/Strings.lua (new), localization/en.csv (new) | GDD §14 + §10.10 events; Strings for all UI; EN alpha, ES/PT-BR/FR launch | Events in DEV; pseudo-locale |
| WP25 Moderation & dev strip | AG | PARTLY (DevBots bot fill, DevSelfTest wish test) | SSS/Moderation.lua (new), SSS/DevBots.lua, SSS/../DevSelfTest.server.lua, SSS/../V12Boot.server.lua, SPS/SpectateCamera.client.lua, SPS/EndingUI.client.lua, SPS/CreditsUI.client.lua, RS/Credits.lua | Report/block, text filtering, dev tools off under RELEASE, remove the Training.lua start in V12Boot, EndingUI replay hook from WP-HOOK-2 | RELEASE on: no dev remotes |
| WP26 Test harness | OC | OPEN | gameplay/tests/run.sh, gameplay/tests/_lib/** | run.sh runs every suite (other WPs add tests only as new files) | Run locally |

### 6.2 Polish packages (from POLISH_BIBLE §6, folded in with file ownership fixed)
To keep zero overlap, these changes to the Bible's file lists apply: each later animation package writes **its own generator file** instead of a section in a shared one; CombatInput and GameFeel move from WP10/WP22 to WP-FEEL-2; AuraRenderer moves from WP22 to WP-VFX-1; UIStyle moves from WP09 to WP-UI-1; CutsceneDirector moves from WP25 to WP-STORY-1; the audio registry replaces my old WP23 AudioDirector/AudioCatalog.
| WP | Tool | Files it may touch (exclusive) | Acceptance (from POLISH_BIBLE §6) |
|---|---|---|---|
| WP-ANIM-1 6-hit M1 + enders | AG | animation/poses/gen_poses.py, poses/Shared.lua, poses/Goku.lua, poses/Vegeta.lua, poses/Frieza.lua | check_poses passes; 15 joints per key; hit markers with tiers; M1_6 = 34 f; 6 hits in < 2.6 s |
| WP-ANIM-2 Marker vocab + Freeze | OC | animation/poses/PosePlayer.lua, animation/AnimMarkerRouter.lua (new), animation/poses/check_poses.luau | Freeze(110) holds ±1 frame; unknown markers warn |
| WP-ANIM-3 Movement & defense clips | AG | animation/poses/gen_poses_move.py (new), poses/SharedMove.lua (new) | Vanish i-frames f0–9; lengths per Bible §1.5 |
| WP-ANIM-4 New characters | OC | animation/poses/gen_poses_ext.py (new), poses/Jiren.lua, poses/Broly.lua, poses/Gohan.lua (new) | Idle, M1_1–6, dash, guard, 3 specials, transform, ultimate, hurt, KO |
| WP-ANIM-5 Beam struggle clips + VFX | AG | animation/BeamStruggleVFX.lua, animation/poses/gen_poses_beam.py (new), poses/BeamStruggle.lua (new) | Orb ≤ 4 studs from the heads; push bar follows −1..1 |
| WP-FEEL-1 Hitstop/shake/FOV tables | OC | RS/FeelTables.lua (new), gameplay/tests/feel_tables_test.lua (new) | Monotonic tiers; Ranked cap; multi-target 50% |
| WP-FEEL-2 Combat input wiring | AG | SPS/CombatInput.client.lua, SPS/GameFeel.client.lua | 200 ms buffer; 1.2 s string reset; perfect-guard crit; keeps X/G/3 binds. Server side is in WP04 |
| WP-HOOK-1 Combo counter, style rank, KO cam | OC | SPS/ComboHUD.client.lua, SPS/KOCam.client.lua, RS/StyleRank.lua, gameplay/tests/style_rank_test.luau (all new) | Colours at 5/10/15/20; KO slow-mo 0.3x ≤ 400 ms |
| WP-HOOK-2 Replays + post-match loop | AG | DONE (SSS/ReplayRecorder.lua, SPS/ReplayViewer.client.lua, ReplayMath, pure tests) | ≤ 2 MB per 40 players; best moment = max-damage window. EndingUI hook done in WP25 |
| WP-VFX-1 Form palette + auras | OC | RS/FormPalette.lua (new) + test (new), SPS/AuraRenderer.client.lua | Every form (incl. SSJ4) has a palette; ≤ 80 particles at Medium; ToP LOD at 20+ |
| WP-VFX-2 Lighting presets proposal | AG | proposals/lighting_presets_patch.lua (new) | WP21 merges it; TrainingLighting reads all keys |
| WP-UI-1 UI tokens + fonts | OC | RS/UIStyle.lua | Text contrast ≥ 4.5:1; existing panels render unchanged |
| WP-AUD-1 Audio registry + mixer | AG | RS/AudioRegistry.lua (new), SPS/AudioMixer.client.lua (new), audio/VO_BRIEFS.md (new), audio/LICENSES/README.md (new) | Ducking math tests; no back-to-back repeats; missing ID logs once; no unlicensed asset. Screams, aura loops, music, ≤ 24 sounds |
| WP-STORY-1 Cutscene grammar | OC | RS/CutsceneDirector.lua, SPS/MangaPanel.client.lua (new) | Skip after 0.5 s hold; pre-mission ≤ 20 s for all 32 |
| WP-STORY-2 Boss telegraphs | AG | RS/Telegraphs.lua (new), SSS/TelegraphService.lua (new) | Windups ≥ 0.6/1.0/1.5 s; Jiren Power Impact red cone 1.0 s before. BossNPC call is in WP19 |
| WP-TRAIN-1 Gravity strain + HTC visuals | OC | SPS/TrainingFeel.client.lua (new) | Strain = clamp((G−1)/150); HTC day counter 365x |
| WP-TRAIN-2 King Kai minigames | AG | DONE (SSS/KingKaiGames.lua, SPS/KingKaiGamesUI.client.lua, KingKaiMath, kingkai_test.luau) | Bubbles +10% per round; 10 bonks in 60 s; XP + title only. Registration is in WP12 |
| WP-TRAIN-3 Whis drills + Beerus feel | OC | SPS/WhisBeerusFeel.client.lua (new), animation/poses/gen_poses_train.py (new), poses/Training.lua (new) | Telegraph 0.5→0.25 s; feints in stages 8–10; 0.3 s perfect-dodge slow-mo |

**Totals:** 26 core + 18 polish = **44 packages** (AG 22, OC 22). Done: WP02, WP05, WP14. Partly done: WP01, WP04, WP09, WP10, WP13, WP17, WP18, WP19, WP20, WP21, WP23, WP25.
**Sequencing:** WP01 → (core OPEN/PARTLY in parallel) and Bible waves 1–4 (ANIM-1 ∥ ANIM-2 ∥ FEEL-1 ∥ AUD-1 → ANIM-3 ∥ ANIM-4 ∥ HOOK-1 ∥ VFX-1 → FEEL-2, ANIM-5, HOOK-2, STORY-1/2 → TRAIN-1..3, UI-1, VFX-2). WP26 runs continuously.

## 7. Studio test checklist per system
Run on a local server with 4 clients plus DevBots to 40. Record pass/fail in vault `Testing/`.
- **Round/ToP:** 2, 8, 24 and 40 players give 2/2/8/8 teams; countdown, teleport to the right U0i pads; timeout winner + tiebreak; ring resets; return to lobby; leaver mid-round; AFK kick to spectate.
- **Teams/party:** a party of 6 in 5-man teams splits 3/3; balance gap shown in output.
- **Character select:** duplicate blocked, budget enforced, locked card shows its level, NPCOnly, timer auto-pick.
- **Combat:** M1 string 4 hits, Heavy guard break, perfect guard 0.2 s stun, vanish i-frames, breaker in hitstun only, dash cancel, 1v1 and 3-way beam struggles, team combo chain, last energy gift in 2 s.
- **Stats:** Lv100 MUI vs Lv5 shows a ratio of 1.35; Ranked ratio 1; paid early forms clamp.
- **Races:** each race passive visible; Kaioken only in Base/SSB; Android can't charge; Zenkai stacks to +10%.
- **Fusion:** Dance and Potara; hit cancels; timeout restores; ring-out → both out; disconnect.
- **Spirit Bomb:** 4 donors max, 60 studs, the deflect by an S tier, arena damage.
- **Arena:** cracks → craters → falls; resize at 40; training areas undamaged.
- **Training:** each area teleport, gravity feel, XP tick every 10 s, HTC limit 3/day + 200 Zeni, bots never KO the player, lighting per area.
- **Beerus:** 5-step chain saves; Hakai 15% execute, 20 in PvP, 70 on bosses, vanish dodges.
- **Data:** leave and rejoin keeps everything; migration from a v7 profile; two servers same key → second is blocked.
- **Quests/daily:** 3+3 shown, claim, reroll once; day rollover at 00:00 UTC.
- **Dragon Balls:** 7 pickups, 8-stud check, summon once a week, disconnect during the wish.
- **Ranked:** queue widening, reserved server teleport, leaver loss, leaderboard writes.
- **Raids:** scaling for 1, 4 and 8 players; phases; odds UI; time limit.
- **Story:** missions unlock in order; goals (survive, hits, defeat); first-clear and replay rewards.
- **Store:** locked UI Sign refused before any prompt; receipt dedup; PolicyService hides crates.
- **HUD/UI:** every screen at phone, tablet, 720p, 1440p and with a gamepad.
- **Perf:** 40 players: server heartbeat ≥ 55 Hz, client ≥ 50 FPS on a mid PC and ≥ 30 FPS on a low phone, memory < 1.2 GB (phone < 700 MB), network < 50 KB/s per client.

---
## 8. Milestones
- **v1.2 playable alpha (target about 2 weeks after Studio is back):** WP01–WP12, WP14, WP21, WP22, WP25. ToP 2–40 with bots, all combat, races, fusion, Spirit Bomb, training + Beerus, onboarding, HUD, mobile controls, data v9, the store with test IDs. Exit: the Studio checklist for those systems is all green; a 40-bot stress test at target FPS; 10 friend playtests.
- **v1.3 beta (+3–4 weeks):** WP13 (real products), WP15–WP20, WP23, WP24 (EN). Dragon Pass S1, Dragon Balls UI, Ranked cross-server, raids, story (solo then co-op), audio, analytics. Exit: D1 retention ≥ 30% in the beta group, crash rate < 1%, no Sev-1 exploits.
- **Launch (+2 weeks):** RELEASE flag on, Max Players 40, product IDs set, localization ES/PT-BR/FR, store page with original art, the moderation pass, the performance pass on low-end phones, a 1-week soft launch then the public.
- **Live ops:** daily shop rotation; weekly Zeno's Festival (Fri), Double XP (Sat–Sun), Dragon Ball reset (Mon), raid rotation; biweekly a new champion or form; monthly a raid boss or story arc and a balance patch from analytics; 6–8 week Dragon Pass and Ranked seasons; seasonal events (Halloween Janemba, Winter Shenron); revisit playable Angels and clans (v2).

---
## 9. Risk register
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| IP / DMCA takedown (Toei, Shueisha, Bandai) | Medium | Very high | Original logo, UI, music and voices; no ripped models/audio (no FighterZ/Xenoverse/Sparking Zero/Legends/Budokai); Sketchfab models only with checked licences (CREDITS.md; CC-BY-SA attribution for Zeno and Piccolo); game name "Dragon Block Z" and no official logos; prepare a rename plan (character name variants) and a backup place; no ads using official art |
| Moderation (chat, custom titles, harassment, minors) | Medium | High | TextChatService filtering on all user text, report/block, no free-text clan names before filtering, Roblox age guidelines for content (no blood), PolicyService for paid random items |
| Performance at 40 players | High | High | Particle cap 2,000 (mobile half), aura LOD by distance, max 24 concurrent sounds, arena chunks pooled, server hit validation at 10 Hz buffers, streaming enabled for training areas, 40-bot stress test each milestone |
| Exploits (speed, teleport, remote spam, damage, duping Zeni, receipts) | High | High | Server authority; RateLimit token bucket on every remote; MoveGuard (WP06); session-locked DataStore; idempotent ProcessReceipt; anomaly flags at 4σ; DEV remotes stripped under RELEASE |
| DataStore loss / corruption | Low | Very high | Session lock, retries, BindToClose, versioned migrations with tests, backups by key version |
| Pay-to-win backlash | Medium | Medium | 1.35x cap, Ranked normalization, published odds, all power earnable |
| Studio PC offline (all integration blocked) | High (now) | High | Box-side tests; batch integration when the PC is back |
| Two AI tools editing the same file | Medium | Medium | WP file ownership (§6), CHANGES.md log, one WP per tool at a time |

---
## 10. Brainstorm and gap audit
> **Ownership update (18:21 ET):** the §10 items are now owned by **WP24** (analytics, localization), **WP17** (Dragon Ball/Shenron edge cases), **WP18** (Ranked), **WP19** (raids), **WP13** (store, private servers), **WP14** (data, disconnect saves), **WP04** (combat, struggle, Spirit Bomb, comeback) and **WP05** (fusion). Items already built by db-gameplay: AFK, disconnects, ties, the 3-beam struggle, fusion KO/ring-out, bot fill and the X/G/3 keys. Audio items go to WP-AUD-1 + WP23, feel items to WP-FEEL-1/2 and WP-HOOK-1/2.
Priority: **A** = must-have for alpha, **B** = beta, **L** = launch, (later) = live ops. The WP that covers each must-have is in brackets.

### 10.1 Edge cases by system
- **Disconnects:** a mid-round leave counts as an elimination, with no gift and no XP loss for the leaver (A, WP02); a mid-fusion leave defuses (A, WP05); during a Shenron wish the wish stays pending (B, WP17); Ranked leaver = loss (B, WP18); mid-raid the slot is freed and scaling isn't reduced until the next phase (B, WP19); a mid-purchase receipt is retried (A, WP13/14).
- **Mid-fusion KO / ring-out while fused:** both eliminated, no gift, both players to spectate (A, WP05).
- **Ties:** timeout tiebreak by HP% then a draw (A, WP02); simultaneous last KOs in the same tick → draw (A, WP02); a beam struggle tie |score|<3 → both take 15 (built).
- **Beam struggle between 3 players:** D18 (A, WP04).
- **AFK players:** 30 s in a fight → spectate; in the lobby, not queued; bots not counted as AFK (A, WP02).
- **Small teams / uneven:** bot fill under 4 (A, WP02); a team of 1 vs 5 gets the comeback boost for the last fighter (+15% damage reduction for 20 s, compressed) (A, WP04); budget per team size (built).
- **Controls:** mobile auto lock-on, layout editor, haptics; console bindings and the radial for forms (A mobile, B console, WP10).
- **Low-end devices:** VFX quality 1 auto-set by FPS < 30 for 5 s; aura LOD; shadows off; arena debris capped (A, WP22).
- **Others:** Spirit Bomb caster KO'd while charging → donated ki is refunded at 50% (A, WP04); Zeno Erase on a fused body → erases both (B, WP05); Final Explosion when the last 2 are on one team → no friendly kill (built); a joiner during a round → spectate until the next round (A, WP02); server shutdown → BindToClose saves (A, WP14).

### 10.2 Show-accurate touches
Power-up scream by form (A, WP23 placeholder SFX, B real); aura hum per form with distance attenuation (A, WP23); scouter PL readout reactions ("It's over 9000!" emote and a scouter crack effect when PL climbs past 9,000) (B, WP22); team callouts ("Universe 7, gather your energy!") (B, WP23); Zeno reactions to a universe wipe (laugh, clap) (A, WP23/WP25); the Grand Priest announcing eliminations by universe (A, WP23); Bulma's cheers from the stands after a ring-out or combo of 10+ (B, WP23); rock levitation and ground crack on charge (built in VFX); the Super Saiyan first-time cinematic, skippable (A, WP22); Zeno counting down the remaining universes (B); the ring shrinking as it breaks (built).

### 10.3 Accessibility
Shake slider, photosensitivity toggle, VFX intensity, colour-blind palettes (A, WP09); subtitles for all voice lines (A, WP23); control remapping (B, WP10); text scale (B, WP09); hold-vs-tap toggle for charge and donate (B, WP10).

### 10.4 Onboarding
First fight < 90 s, skippable tutorial, the next-unlock teaser, first-session 2x XP (A, WP11); contextual tips the first time a struggle, fusion or gift is possible (B, WP11); tutorial for training areas (B, WP12).

### 10.5 Retention hooks
Daily streak and 3+3 quests (A, WP16); level-up unlock cards (A, WP11/WP09); Dragon Ball hunt (B, WP17); Dragon Pass (B, WP15); Ranked seasons (B, WP18); weekly raid first-clear (B, WP19); comeback rewards after 3 days away (L, WP16); favourite characters (B, WP08).

### 10.6 Social and party
Party up to 6, friend join (built); party chat ping (B); team emotes and pings ("Gather ki here", "Fuse with me?") (B, WP10/WP09); MVP play-of-the-round (L, WP22); weekly leaderboards (B, WP18); clans (later); private servers (L, WP13).

### 10.7 Moderation
Filter all custom text, report/block, kick and log exploiters, no voice chat requirement, ban list DataStore for repeat exploiters (L, WP25; A for filtering if any custom text exists).

### 10.8 Exploits and server authority
Every remote type-checked and rate-limited (built; audit A, WP06); movement guard (A, WP06); lag rewind (B, WP04); damage-from-client never trusted (built); Zeni/XP anomaly flags (B, WP24); Dragon Ball positions server-only (built); store refuses locked items before prompting (built); DevBots and dev remotes disabled in RELEASE (A, WP25).

### 10.9 Performance budgets at 40 players
Client: ≤ 2,000 particles (1,000 on mobile), ≤ 24 sounds, ≤ 40 active auras with LOD (full within 80 studs, simple to 200, none beyond), ≤ 150 draw-call-heavy debris parts. Server: heartbeat ≥ 55 Hz, hit validation ≤ 2 ms per frame, ≤ 50 KB/s per client replication. (A, WP22/WP21; measured in §7.)

### 10.10 Analytics events
match_start/end, pick, transform, parry, struggle_end, gift, fusion, purchase, quest_complete, level_up, funnel_onboarding_step, plus: afk_kick, disconnect_mid_round, ring_out, spirit_bomb, hakai, raid_start/end, story_clear, ranked_result, shop_view, crate_open, settings_change, fps_bucket (A for funnel and match events, B for the rest; WP24).

### 10.11 Localization
All UI through Strings.lua (B, WP24); EN at alpha; ES, PT-BR, FR at launch; later DE, JA, ID, TH. Character names stay fixed. Numbers formatted per locale.

### 10.12 Audio
Layered hit sounds by tier (A, WP23); form screams (A placeholder / B final); dynamic music calm → intense (≤25% alive) → choir on UI (B); voice volume channel (A, WP09); original or licensed only (A, all).

---
## 11. Biggest gaps (as of v8)
1. Nothing has been run in Studio: every system is box-tested only.
2. No mobile controls (the PC/console keys are done) and no onboarding, yet the first-90-second goal and phone players depend on them.
3. No audio system at all (screams, auras, announcer).
4. Rigs for Shin, Zamasu, Broly and story enemies.
5. No movement anti-cheat, lag compensation, analytics or localization.
6. Product IDs are 0 and DEV_MODE is true; Studio Max Players needs to be set to 40 by hand.
7. The Dragon Pass is design only. The Radar, Shenron, Ranked, Raid and Story screens now exist in code but are untested in Studio.
