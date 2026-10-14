---
tags: [dragon-block-z, redesign, product-vision, combat, vfx, roadmap]
status: proposal
date: 2026-10-14
version: 0.1
---

# Dragon Block Z — REBORN: Design Reset

> **Pitch:** Don't make players *watch* a Dragon Ball episode. Make them *feel* they're fighting inside one.
>
> **Target emotion:** The moment just before a transformation, when everything goes silent, the camera closes in, the character screams, rocks begin to float, and an opponent realizes the fight has changed.

**Status:** New proposed vision, not a statement of what is implemented. Use the existing code and vault as raw material, not a constraint.

## 1. Why reset now?

The original project centers on a Tournament of Power loop: World of Void lobby, numbered teams, champion selection, combat, ring-outs, XP rewards and reset (`team/MASTER_DESIGN.md`, `team/GDD_FULL.md`). It also attempts enormous breadth: high player counts, dozens of champions, progression, story missions, training, raids, fusion, divine tiers, arena destruction, replays, cosmetics and more.

This is a good source of reusable systems but the **center of the experience must change** from “many implemented systems” to “extraordinary combat and emotional presentation.”

**Current-status caveat:** The vault is a collection of documents and changelogs, not the actual place file or source tree. The `team/CHANGES.md` log claims some systems were Play-tested in Studio on Oct. 14, including XP, round flow, UI and animation-marker output. It also documents recent repairs to animation routing, audio IDs, tutorial availability, menu layering, lighting and script installation. These claims are not an independent runtime audit. Multiple versions of the documents disagree on progression and scope (for example 100-level vs 500-level progression), so confirm actual config before touching balance.

## 2. The market and the anime moment

The enhanced `Dragon Ball Super: Beerus` anime began October 11, 2026. Official sources emphasize renewed battle presentation, redrawn cuts, sound and narrative structure. This is a creative benchmark, **not permission to reuse** the footage, music, characters, dialog or promotional material.

| Reference | Observed feature, based on public game descriptions / sources | What we can learn | Hypothesis to test, not an asserted flaw |
|---|---|---|---|
| Dragon Soul (Roblox) | Open-world anime RPG, quests/story, flying, blocking, charging, transformations and raids | Persistent fantasy of being a growing warrior | Players may value a tighter skill-first PvP mode with shorter access to meaningful fights |
| Dragon Ball Rage (Roblox) | Fighting, skills, transformations, very high stats, currency and progression | Long-term power fantasy and unlock excitement | A mode with normalized combat and no stat wall could appeal to players who dislike numerical gaps |
| Dragon Blox (Roblox) | Saiyan growth loop, stat multipliers, timed world spawns and wishes | Regular goals that make a world worth visiting | Replace passive grinding as the core activity with meaningful playable training |
| Final Stand: Remastered (Roblox) | Action RPG remaster organized around named expansions / level cap | Progression and recognizable world landmarks | We can make presentation, mastery and fights meaningful immediately instead of relying on a large endgame |
| Dragon Ball Sparking Battlegrounds (Roblox) | Lock-on, clash counter, ki, vanish, flying, transformations | Important that battle movement is actually 3D | Differentiate on choreography, accessibility, responsiveness and teamwork, not only number of moves |
| The Strongest Battlegrounds (Roblox) | Readable M1, block, dash, evasive, short skill kit, awaken | Simple controls + timing-depth is a strong competitive foundation | Add aerial pursuit and a memorable Dragon Ball-specific pacing arc |
| Jujutsu Shenanigans (Roblox) | Accessible skill kit, awaken and arena destruction | Destruction and dramatic ultimates create memorable stories | Treat effect clutter and heavy destruction as performance/visual-readability risks (Reddit discussions are anecdotal) |

**Research method:** Public Roblox game listings and selected Reddit player comments, not personal in-game testing. Avoid confident numerical market-share rankings from older vault documents.

### Relevant outside links
- Enhanced anime: https://en.dragon-ball-official.com/news/01_3976.html ; October premiere: https://en.dragon-ball-official.com/news/01_4425.html
- Dragon Soul: https://www.roblox.com/games/8246874626/Dragon-Soul-Anime-MMO
- Dragon Ball Rage: https://www.roblox.com/games/71315343/Dragon-Ball-Rage
- Dragon Blox: https://www.roblox.com/games/3177438863/Dragon-Blox
- Final Stand Remastered: https://www.roblox.com/games/7922773201/Final-Stand-Remastered
- Dragon Ball Sparking Battlegrounds: https://www.roblox.com/games/15295153296/Dragon-Ball-Sparking-Battlegrounds
- The Strongest Battlegrounds: https://www.roblox.com/games/10449761463/The-Strongest-Battlegrounds
- Jujutsu Shenanigans: https://www.roblox.com/games/9391468976/Jujutsu-Shenanigans
- Example *anecdotal* destruction/performance complaint: https://www.reddit.com/r/JujutsuShenanigans/comments/1wzk440/
- Performance recommendations: https://create.roblox.com/docs/performance-optimization/design

## 3. Proposed 5 pillars

### A. Emotion drives every major action
Each signature action is a designed sequence of **anticipation → release → consequence**. The beam matters because the player's charge creates suspense, its release pays it off with audio and visual impact, and the opponent or stage visibly reacts. Use contrast: silence before the scream, a fast zoom followed by stillness, thin energy arcs before a massive aura.

### B. Fighting is readable and responsive
- 4-step ground combo, with contextual launcher/downslam/chase.
- Guard, telegraphed heavy guard break, perfect guard, vanish, dash and escape.
- At least one viable counter to every flashy move.
- 0.15–0.25 s client-side input buffer as a starting tuning range, adjusted through tests.
- Instant local feedback where safe; server owns health, hit validation, movement bounds, cooldowns and resource spending.
- No unavoidable movie-length ultimates in routine PvP.
- Aim for fair 1v1 first; team mechanics follow later.

### C. Transformations are events, not skins
- Enter with a *player-triggered* build-up; clear enemy counterplay during windup.
- Cinematic: breath / heartbeat / pause → yell → aerial debris → color, aura and hair silhouette change → sonic release.
- Gameplay: change a few *verbs* (e.g., altered vanish, follow-up, ki property) rather than a giant stat multiplier.
- Optional 2–3 second signature transformation camera treatment, never repeatedly commandeer every opponent's camera.
- A separate **Last Stand**/determination mechanic provides dramatic comebacks without guaranteed wins or automatic extra damage.
- Original recorded voices or properly licensed assets only; no rips and no imitation of identifiable performers.

### D. Truly 3D Dragon Ball mobility
- Free flight in hub/story exploration.
- Combat flight has manageable vertical range, lock-on camera, resource cost and recovery so fights remain legible.
- Vanish afterimages, pursuit on heavy launch, air-to-ground smash.
- Always test target tracking, slopes, floor occlusion, and mobile camera behavior.

### E. A show-inspired world with clear visual hierarchy
- One hero-quality **World of Void** arena plus one small characterful training/hub zone at launch.
- Intentional sky art, silhouette, rim-light, gradients and color keys per battle.
- Stylized props and modular rock geometry; selective outlines/illustrated hit cards.
- Debris and craters are **pooled, capped and mostly client-side cosmetic**. Only server-approved destruction changes collision or match rules.
- Video options: Cinematic, Balanced, Low, accessibility screen-shake and flashing reduction.

## 4. The first five minutes (a playable episode)

| Time | Player experience | Design result |
|---|---|---|
| 0:00–0:10 | Lightweight title and punchy opening shot; skip is obvious | Emotional hook, quick entry |
| 0:10–0:40 | Sparring NPC taunts and teaches movement, punch and lock-on | No wall of tutorial text |
| 0:40–1:20 | NPC attacks; player learns guard + timed vanish | First meaningful mastery |
| 1:20–2:10 | Mini battle: light combo → launch → air chase → slam | Showcase core skill loop |
| 2:10–2:45 | Controlled low-stakes climax: transformation becomes available; environmental/audio buildup | **First “I feel like Goku” moment** |
| 2:45–3:30 | Use transformed technique and earn a cinematic but short finisher | Shareable spectacle |
| 3:30–4:15 | Clean reward reveal and choose Practice, Duel or Team Arena | Clear next action |
| 4:15–5:00 | One short spar/duel; visible mastery objective and return motivation | Loop begins |

This first encounter should be a guided **PvE** experience and should not fake a win in competitive PvP.

## 5. First combat vertical slice

**Playable scope:** 1 arena, 1 short intro, 2 original/prototype fighter kits or properly licensed champions, 1 polished transformation, 1 beam, 1 full melee chain, guard, dash, vanish, midair pursuit, damage reactions, sound and one breakable arena prop.

**Signature encounter:**
1. Opponent blocks two strikes.
2. Player delays a third and lands the guard break; one strong impact frame.
3. Opponent vanishes behind the player; the camera pivots to preserve orientation.
4. Player perfect-guards the return hit; strong sound, short hitstop, and clear resource gain.
5. A knockback creates a chase through the air.
6. The defender charges a beam, the attacker counters with another.
7. Two-player clash shows a clean timing meter, ends decisively, and does not hold everyone else in cutscenes.
8. The loser hits the arena: dust, stone ripple, small persistent crater.
9. At low health, a dramatic-but-fair transformation opens a comeback option.

This *single scene* is the test for whether we have achieved the new identity.

## 6. What to retain / overhaul / postpone

| Vault system | Proposed treatment | Reason |
|---|---|---|
| Server-owned combat validation, match state and replay hooks | **Audit and retain** | Expensive foundations, but actual source review required |
| Animation markers and VFX routers | **Retain interface, overhaul content and direction** | Log reports marker routing recently repaired; polish cannot be judged by code alone |
| 40-player multi-universe Tournament of Power | **Later goal** | Begin with 2v2 or 4v4, later 8–12 player opt-in matches, expand after performance tests |
| Roster of dozens / divine tiers | **Postpone** | Better 2 exceptional kits than 30 incomplete kits |
| 100 vs 500 levels, prestige, broad power tiers | **Replace as primary progression concept** | Avoid the stat-wall fantasy; make mastery, forms, equipment visuals and experiences primary |
| Existing 1.35× stat compression + normalized ranked | **Retain fairness principle, revisit numbers** | PvP outcome should not be dictated by purchase or playtime |
| World of Void arena/destruction + hub | **Rebuild art direction; audit stage tech** | Lighting duplicates were removed but visuals still need an authored sky / art pass |
| Very long first-round intro | **Replace with opt-in story episode** | Even after bugfix, the logged 108 s first-time intro is too much before gameplay |
| Whis onboarding, mobile controls, console bindings | **Reuse foundations; redesign presentation, test every device** | Recent bugfixes reveal why actual device testing is mandatory |
| Fusion / Shenron / multiple raids / 32 missions / Zeno playable | **Postpone** | Scope explosion distracts from the core emotional promise |
| Pay-for-power / early competitive forms | **Remove** | Competitive trust is worth more than a minor revenue boost |

## 7. Visual and audio language

**Look:** Bold clear character shapes; stylized comic/anime impact frames; three or four intentional scene palettes; sharp, readable beams; sophisticated atmosphere but not excessive bloom. Keep combat silhouettes readable.

**Audio layers:** preparation (inhale/heartbeat) → voice/emotive effort → aura rumble → elemental energy hiss → bass impact → world reaction → release. Add distance attenuation, dynamic mix ducking and a voice budget. Original licensed recordings only.

**Cameras:** camera intent is data attached to abilities, but a single local camera director is the sole CFrame owner. Other systems request small impacts or short cinematics, instead of directly fighting over `CurrentCamera`.

**Animation:** blocking from real references with licensed/original poses; use Roblox AnimationTracks and markers, clear anticipation, recoil and recovery, and hold poses for decisive anime beats. The existing authored pose clips require side-by-side rig playback before promising quality.

**Performance:** budget mobile particle counts and light count; pool VFX; keep debris mostly visual; profile on a real lower-end mobile device and gamepad/console. Do not assume Studio emulator proves real device perf.

## 8. Proposed Roblox systems (high level)

Server:
- `CombatService` validates all attacks, cooldowns, stamina/ki, range, angles and hurtboxes.
- `MovementService` bounds flight, pursuits, dashes and vanishes and mitigates teleport/speed exploits.
- `TransformationService` authoritatively checks prerequisites, start/end states, cooldowns and resource cost.
- `ArenaService` manages only gameplay-impacting destruction and ring-out.
- `MatchService` supports Practice, Duel and small-team bouts first.
- `ProgressionService` stores masteries and cosmetics; it does not let purchased stat multipliers decide PvP.

Shared data:
- Config-driven movesets with startup, active, recovery, resource cost, hit reaction, markers, animation and effects.
- `ActionEvent` / animation marker names as contracts, not special-case per fighter code.

Client:
- `InputController` maps semantic abilities to keyboard, controller and touch.
- `CombatFXController`, `CameraDirector`, `AudioDirector`, `VFXBudgeter`, `PresentationSettings`.
- Predicted presentation with server reconciliation, not client-trusted hit/damage reports.

## 9. Acceptance gates, not fake deadlines

**Gate A — Core feel:** 2 players can have a compelling 2-minute duel without the transformation. No broken block/vanish states. Every hit confirms clearly. Video reviewed frame by frame.

**Gate B — Anime power:** one transformation causes a strong reaction in blind user tests and remains readable with effects lowered. One beam duel is both fair and exciting.

**Gate C — Replayable 5 minutes:** a new player gets to a controllable fight quickly and reaches the first power moment inside ~3 minutes without outside instruction. Measure tutorial completion and time to first fight.

**Gate D — Stability:** repeated tests with simulated latency, multiple live players, low-end hardware, respawn resets and clean state restoration. No client can submit damage amounts, bypass cooldowns or invent transformations.

**Gate E — Small public beta:** initial sessions of practice, 1v1 and small teams work; player feedback judges responsiveness, wow moment and fairness. Expand roster and 40-player Tournament of Power **only after** these gates.

## 10. Prioritized production backlog

**P0 — preserve and audit:** backup `Place1.rbxl` and the source repository; determine the actual version of `Config`, `Combat`, `RoundManager`, `AnimMarkerRouter`, `VFXRouter`, `CameraShake`, `AudioRegistry`, character rig and player-data schema; record a current 60-second fight video.

**P1 — visual target:** define three reference images and one aesthetic lane; create a sky/lighting look-dev room and hero-quality training zone. Confirm R6 vs R15 and chosen animation rig.

**P2 — combat slice:** two kits, hit reaction and verified marker/camera/audio budget; one 1v1 loop and playable bot.

**P3 — emotional set piece:** one fully voiced/licensed or original scream, two-stage power-up, one beam, one clash, one breakable prop and a fair comeback mechanic.

**P4 — onboarding and accessibility:** integrate 5-minute guided battle and parity on keyboard, touch and controller; settings for reduced effects and camera shake.

**P5 — small public beta:** 2v2 / 4v4, fair rewards and strong first-time return goals, crash/perf/latency testing.

## 11. Critical IP / licensing decision

Roblox requires the rights or an applicable license for third-party franchise material. A Sketchfab file being downloadable, or an asset appearing in the Creator Store, does **not** establish rights to reproduce its copyrighted Dragon Ball character or scene. Do not rip anime/game music, actor performances, logos, or models. Roblox has a formal IP licensing catalog, but do not assume Dragon Ball is available in it.

Options:
1. Obtain the relevant Dragon Ball license / written permission before using protected content.
2. Release an **original anime energy-fighter** inspired by general tropes, with original fighters, setting, story, names, soundtrack and visual design; don't merely rename infringing copies.

Sources: https://create.roblox.com/docs/ip-licensing/creators ; https://create.roblox.com/docs/ip-licensing/faq ; https://create.roblox.com/docs/production/publishing/ip-guidelines

## 12. Decisions needed from creator

1. **Main mode:** skill-first arena fighter, story/open-world RPG, or a deliberately small hybrid?
2. **Cast:** preset named champions or an original fully customizable protagonist (licensed/original route affects this)?
3. **Rigs and art:** existing R15/R6, custom rig, owned/cleared models, or new original art?
4. **Resources:** solo, small team, available time, and current working `.rbxl`/Rojo source or a 60-second gameplay clip?

**Default recommendation:** A **skill-first cinematic arena fighter** with a guided PvE opening, 1v1 and 2v2 at beta, and the Tournament of Power as the *future marquee team event*. Do not build the open-world RPG or giant roster until the first signature battle is beautiful and genuinely fun.

---
**Related existing vault:** `team/MASTER_DESIGN.md`, `team/GDD_FULL.md`, `team/PLAYER_RESEARCH.md`, `team/POLISH_BIBLE.md`, `team/CHANGES.md`, `team/PHASES.md`, `notes/COMPETITIVE_ANALYSIS_AND_AUDIO_PIPELINE.md`, `notes/ASSET_AND_ENVIRONMENT_MASTER_PLAN.md`.
