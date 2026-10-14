# Dragon Block Z — Upgrade + UX Plan (v1.1 → v2)
Owners: **db-animation** (anim/VFX), **db-gameplay** (systems/UI/data), **db-map** (arena/hub), **db-story** (cutscenes/dialogue/modes). Lead: roblox.
Builds on MASTER_DESIGN.md, gameplay/SPEC.md v4, story.md, map/layout_spec.md v2, animation/movesets_v4.md, sketchfab/candidates.md.

## 1. GAME FEEL + VFX (priority #1 — "the best there is")
Benchmarks: The Strongest Battlegrounds (TSB) and Jujutsu Shenanigans (JJS) win on hit feel, not graphics. Target: every hit readable at 30 fps on phone.

### 1.1 Hit feedback spec (db-animation module `GameFeel.lua`, called from Combat on server-confirmed hit, client-predicted for attacker)
| Event | Hitstop (both) | Cam shake (amp / freq / dur) | Flash | FOV punch | Sound |
|---|---|---|---|---|---|
| Light M1 1-3 | 40 ms | 0.15 / 18 Hz / 0.08 s | none | 0 | punch_light (pitch ±8% random) |
| M1 4 (finisher/knockback) | 90 ms | 0.5 / 14 / 0.2 | white 8% 1 frame | +4° 0.15 s | punch_heavy + whoosh |
| Heavy / guard break | 120 ms | 0.8 / 12 / 0.25 | white 15% | +6° | crack + bass thump |
| Ki blast | 25 ms | 0.1 / 20 / 0.06 | — | 0 | blast_pop |
| Ultimate beam connect | 150 ms then slow-mo 0.4x 0.4 s | 1.2 / 10 / 0.6 | colour of beam 25% | +10° | beam_impact + crowd "ooh" |
| Perfect block / Instinct dodge (UI) | 60 ms + 0.25 s 0.5x time-dilation (client) | 0.3 | silver rim flash | -4° | "shing" |
| KO / ring-out | 250 ms freeze-frame + black/white impact frame (2 frames, inverted) | 1.5 / 8 / 0.8 | impact frame | +12° | KO sting + scream |
Rules: hitstop = freeze anim tracks (AdjustSpeed 0) on both actors only; never world freeze. Shake scaled by distance (falloff 60 studs) and a player "Screen shake" slider (0-100%). Max 1 impact frame / 1.5 s to avoid flashing (photosensitivity toggle disables).

### 1.2 Anime signature VFX (show-accurate)
- **Impact frames**: 2-frame inverted/high-contrast silhouette on KO, ultimate hit, beam-struggle win (ScreenGui ViewportFrame of the two rigs, black fill + white rim).
- **Speed lines**: radial UI overlay on dash, Instant Transmission, rush combos; aura-coloured.
- **Afterimages**: 4 ghost clones (0.08 s spacing, Transparency 0.5→1) on dash/vanish; "zanzoken" sound.
- **Auras**: per-form ParticleEmitter + Beam flames, 3 LODs. SSJ gold with sparks; SSB blue with cyan lightning-free calm; UI silver wisps + heat distortion; Ultra Ego purple flame with Beerus-style aura; Beast Gohan white-silver spiky + red eyes; Black Frieza black-purple cracks; Golden Frieza gold sheen.
- **Transformations**: 3-6 s cinematic, invulnerable, skippable after first view; camera orbit preset, scream, rock levitation, ground crater decal, white-out flash, form-name title card (show-style kanji-free font). Short 1 s "quick transform" in-combat after first watch (costs more ki).
- **Power-up scream**: hold charge → ground cracks, debris lift, aura grows in 3 stages, Power Level counter ticks up with digit-roll and Scouter beep; at max: lightning + "AAAAH" vocal layer.
- **Beam struggle**: two beams meet → clash sphere, camera side-on split framing, mash/rhythm meter, pushing sphere toward loser, explosion consumes loser + arena chunk.
- **Destruction**: ArenaDamage chunks get crack decals → debris physics (cap 150 active parts, pooled), dust clouds, persistent scorch decals; arena skybox shifts darker as damage % rises.
- **Ki trails** on fast flight; contrails stretch with speed.
- **Character look**: cel shading via SurfaceAppearance + Highlight outline (black, OutlineTransparency 0.2), face decal swap per expression (neutral/angry/scream/hurt/smirk).

### 1.3 Animation quality bar (db-animation)
- Every move: anticipation ≥ 3 frames, smear frames on fast swings, recovery pose; root motion via server-authorized CFrame lerp.
- Required anim set per hero (Goku, Vegeta, Frieza first): idle(2), run, fly idle/forward/boost, dash 4-dir, M1×4 (2 variants), heavy, block, perfect-block, hurt×3, knockdown, getup, ki blast L/R, charge loop, 3 specials, ultimate, transform per form, taunt×2, victory, defeat, fusion dance (synced pair), Potara put-on.
- Character-specific signature: Vegeta crossed-arms idle + Final Flash pose; Frieza hover-only locomotion with tail; Goku Kamehameha 4-stage charge with voice timing.
- Anim events drive VFX/sounds (`GetMarkerReachedSignal`), never wait() timing.
- Performance: VFX budget per client 2,000 particles; mobile LOD halves rates; pool all effects.

### 1.4 Sound
Layered hits (transient + body + tail), per-character scream packs (original voice actors/soundalikes — no ripped anime audio), dynamic music (calm → intense when ≤ 25% players remain → Ultra Instinct-style choir on UI activation, original composition).

## 2. Top 10 upgrades (ranked impact ÷ effort)
| # | Upgrade | Impact | Effort | Owner |
|---|---|---|---|---|
| 1 | GameFeel module (hitstop, shake, flash, impact frames, sounds) | ★★★★★ | M | db-animation |
| 2 | Goku/Vegeta/Frieza full anim set + form auras/transform cinematics | ★★★★★ | L | db-animation |
| 3 | Mobile controls + auto-target/lock-on (≈60% Roblox players are mobile) | ★★★★★ | M | db-gameplay |
| 4 | 60-second onboarding (tutorial vs Whis) | ★★★★ | S | db-story + db-gameplay |
| 5 | Lobby hub redesign (Lookout/World of Void with pads, NPCs, Bulma) | ★★★★ | M | db-map |
| 6 | Character select screen with 3D preview + tier/role tags | ★★★★ | M | db-gameplay |
| 7 | Clean HUD (health/ki/PL/teammates/moves) | ★★★★ | S | db-gameplay |
| 8 | Retention loop: daily rewards, quests, Battle Pass ("Dragon Pass") | ★★★★ | M | db-gameplay |
| 9 | Training mode (Time Chamber, Gravity Room, King Kai, Whis) | ★★★ | M | db-map + db-story |
| 10 | Beam struggle + destruction polish | ★★★ | M | db-animation + db-map |

## 3. UX flow
### 3.1 First-time player journey (target: first fight < 90 s)
1. Join → 6 s cold open (Zeno+Future Zeno laugh, Grand Priest line, "Dragon Block Z" title) — skippable.
2. Spawn in Hyperbolic Time Chamber with Whis: 4 prompts (move/fly → M1 combo → block → ki blast + charge scream). Gets Goku free.
3. Whis: "Now, try it for real." → auto-queue into a bot-filled small match (2v2) — easy win.
4. Reward screen: XP bar fills, level 2, "Vegeta unlocks at Lv 3" teaser, daily reward claim.
5. Arrive at lobby hub with an arrow to "Tournament of Power" pad.
Returning players skip straight to hub.

### 3.2 Lobby hub (World of Void / Kami's Lookout style, db-map)
Central floating platform; Zeno+guards throne overlook (decor). Pads in a ring: **Tournament (Random)**, **Party Queue**, **Ranked** (Lv 15+), **Training** portal, **Raids**, **Story**. Booths: Capsule Corp shop (Bulma), Energy drink vending machine, Dragon Pass board, Quest board (King Kai), Leaderboard monolith, Scouter photo spot. Party UI: invite friends from top-left list; party members' rings glow same colour.

### 3.3 Character select (12 s)
Grid by universe tabs + "All" + "Favourites"; locked cards greyed with unlock level/price. Right panel: 3D ViewportFrame model doing idle, tier badge (S/A/B), role (Rusher/Zoner/Support/Tank), difficulty stars, form ladder (Base→SSJ→Blue→UI). Team strip at top shows teammates' picks live; duplicates blocked with clear reason. "Random" and "Last pick" buttons. Mobile: 4-column large cards.

### 3.4 HUD (see ux_wireframe.png)
- Top centre: universe scoreboard (pips per team alive), timer.
- Top-left: teammate portraits w/ HP; Gift-energy button appears when teammate low.
- Bottom-left: your HP (green) + Ki (yellow, segmented 5 bars) + Power Level readout in Scouter-green font.
- Bottom-centre: 4 skill slots + Ultimate (charged ring) + Transform button (shows next form).
- Right: kill feed; bottom-right mobile buttons.
- Combo counter mid-right (show-style "12 HITS!"). Damage numbers off by default.
### 3.5 Controls
| Action | PC | Mobile | Console |
|---|---|---|---|
| M1 | LMB | big Attack btn | X/□ |
| Block | F | Block btn | L1 |
| Dash | Q | Dash btn (+joystick dir) | B/○ |
| Fly toggle | Space×2 | Fly btn | A double-tap |
| Skills 1-4 | 1-4 | arc of 4 buttons | RB + face |
| Charge ki | C hold | Charge btn | Y hold |
| Transform | G | Transform | D-pad up |
| Lock-on | Middle mouse / T | auto + tap target | R3 |
Mobile: auto lock-on to nearest enemy in 40° cone, customisable button layout editor, haptics on hit.

## 4. Retention + monetization (fun-first)
- **Daily rewards** 7-day streak (Day 7 = Senzu/energy drink bundle + cosmetic aura).
- **Quests**: 3 daily (e.g. "win a beam struggle"), 3 weekly; from King Kai board.
- **Dragon Pass** (season 30 levels free/premium): auras, victory poses, titles, emotes; premium ~ 399 R$.
- **Collect the Dragon Balls**: find 7 scattered in hub/training per week → Shenron wish (pick: XP boost, cosmetic, re-roll).
- **Pay-to-win (user allowed), bounded**: gamepasses to unlock characters/forms early, 2× XP, extra loadout slots; stat gap still capped at 1.35× (SPEC §0.2) so skill wins. Energy drink: in-match consumable (refill 40% ki + 5 s speed), max 1 per match, earnable free in quests, also sold.
- UX rules: no pop-up ads mid-match; shop shown on result screen only once/session; clear prices; Robux purchases preview in 3D.
- **Social**: party queue, friend join, team emotes, Bulma cheers + crowd reactions, "MVP" play-of-the-round replay highlight, leaderboards (weekly).

## 5. New modes
- **Training (solo)**: Hyperbolic Time Chamber (2× XP, gravity increasing), Gravity Room (Capsule Corp; set 10G-500G = weighted movement, trains stamina stat cosmetic), King Kai planet (catch Bubbles/hit Gregory minigames → unlock Kaioken), Whis sparring (dodge-only drills → unlocks Ultra Instinct progress). db-map builds rooms, db-story writes NPC lines.
- **Ranked**: 1v1 and 3v3, Elo, ranks Earthling→Saiyan→Elite→God→Angel→Grand Priest; season rewards.
- **Story mode**: replay arcs as short co-op missions: Saiyan, Namek (vs Frieza), Androids, Buu, Super (Hit, Jiren), Moro, Super Hero (Beast Gohan). Narrated with StoryDialogue.
- **Raids**: 4-8 players vs giant boss: Legendary Broly (rage phases), Moro (absorbs abilities), Super Buu, Jiren. Drops cosmetics.
- **Event**: weekly "Zeno Erase" chaos night (divine champions allowed).

## 6. Roadmap
**v1.1 (1-2 weeks)**: GameFeel module; Goku/Vegeta/Frieza anim set + 5 auras; mobile controls; HUD redesign; onboarding with Whis; daily rewards; DBZ rename; energy drink.
**v1.2 (3-5 weeks)**: lobby hub v2 + Bulma + props; char select 3D; quests + Dragon Pass S1; Training mode; beam struggle polish; destruction LOD; transformation cinematics for UI/UE/Beast/Black Frieza.
**v2 (2-3 months)**: Ranked; Story mode (3 arcs first); Raids (Broly, Moro); full roster anim pass; Dragon Ball collection; leaderboards; console polish; voice packs.

## 7. Ownership summary
- db-animation: §1 all, beam struggle, transforms, fusion dance anim, auras.
- db-gameplay: HUD, controls, char select, retention, monetization, ranked, energy drink, data schema v6.
- db-map: hub, training rooms, raid arenas, destruction LOD, props (Radar/Scouter/Capsule Corp/Kame House).
- db-story: onboarding script, NPC lines (Whis, King Kai, Bulma), story mode, Shenron wish variants.

## 8. Risks
IP takedown risk for fan-art Dragon Ball models/names (see candidates.md); avoid ripped audio/logos. Photosensitivity: flash toggle. Mobile perf: VFX LOD.

## 9. Player research → Coolest Powers + complaint fixes (see PLAYER_RESEARCH.md for sources)
### 9.1 Universal abilities (everyone)
- **Vanish / Zanzoken** (teleport-behind on perfect-timed dodge, costs ki) — the #1 "anime" feeling.
- **Rush combo chase**: heavy hit knocks enemy far → tap to dash-chase and continue (Sparking/Budokai style).
- **Ki charge scream** (3 stages, power level rising), **Ki blast barrage**, **Guard/Ki shield**, **Super Dash** with sonic boom.
- **Beam struggle** auto-triggered when two beams meet.
- **Transform gauge**: forms unlocked by level, activated mid-fight when gauge fills (Sparking skill count).
- **Dramatic Finish**: special KO cinematic (≤ 3 s) for iconic matchups — Goku vs Frieza on Namek-like ring, Gohan vs Cell pose, Vegeta Final Explosion, Goku vs Jiren UI dodge.
- **Last energy gift**, **Senzu / Energy drink**.

### 9.2 Signature moves per character
| Character | Signature kit (4 skills + ult) | Forms |
|---|---|---|
| Goku | Kamehameha (charge-hold), Instant Transmission (to locked target or teammate), Kaioken x20 burst, Dragon Fist; ULT: Spirit Bomb (team charge — teammates hold "give ki" to grow it) | SSJ, SSJ3, God, Blue, Blue Kaioken, UI Sign, Mastered UI (auto-dodge window) |
| Vegeta | Galick Gun, Big Bang Attack, Final Flash; Final Explosion (sacrifice, removes self); ULT: Final Flash max | SSJ, Majin, Blue, Blue Evolved, Ultra Ego (damage taken → damage up) |
| Frieza | Death Beam (fast snipe), Death Ball, Nova Strike, telekinesis throw (rocks); ULT: Death Ball planet-buster (arena chunk destroyed) | Final form, Golden, Black Frieza |
| Gohan | Masenko, Father-Son Kamehameha (with Goku teammate), Special Beam Cannon (Beast); ULT: Beast Special Beam Cannon | Mystic/Ultimate, Beast |
| Piccolo | Special Beam Cannon, Hellzone Grenade, stretch arm grab, regen | Orange Piccolo (giant) |
| Krillin / Tien | Destructo Disc, **Solar Flare** (blind cone 2 s), Tri-Beam, Multi-Form | — |
| Trunks | Burning Attack, sword combo, Heat Dome | SSJ, Rage |
| Gotenks / fusions | Super Ghost Kamikaze Attack (homing ghosts), Galactic Donut | SSJ3 |
| Gogeta / Vegito | Stardust Breaker, Big Bang Kamehameha, Final Kamehameha, Spirit Sword | SSJ Blue |
| Broly | Gigantic Meteor, Eraser Cannon, grab slam; rage meter | Legendary SSJ |
| Jiren | Power Impact, Eye-glare stun, counter stance, Infinity Rush | Full Power |
| Hit | **Time Skip** (0.6 s world freeze for enemies near, cooldown 20 s), Time Cage | Pure Progress |
| Kefla/Caulifla/Kale | Gigantic Ray, Berserk rage | SSJ2, Berserk |
| Moro | Energy absorb (steal ki), copy ability (borrows last enemy skill) | Fused Moro |
| Goku Black | Rosé scythe, Divine Lasso | Rosé |
| Beerus/Destroyers (divine) | **Hakai** (instant KO only on enemies under 15% HP, long charge, interruptible), Sphere of Destruction | — |
| Whis/Vados/Angels | Auto-dodge, staff rewind (rewind own HP 3 s) | — |
| Zeno (event only) | Erase (event mode) | — |
| Fusion Dance / Potara | Dance pair cinematic (2 s, both vulnerable), Potara instant but needs earring item; fused timer 30-60 s | Gogeta / Vegito / Kefla |

### 9.3 Fixing the top complaints
| Complaint | Our fix | Owner |
|---|---|---|
| Slow grind | SSJ within first session (≤ 20 min); XP from every match incl. losses; no XP loss on death | db-gameplay |
| Pay-to-win anger | Paid = time-saver + cosmetics; 1.35× cap; Ranked fully normalized; every char earnable free | db-gameplay |
| Lag / hitboxes | Server-authoritative, client-predicted hits, lag-comp ≤ 200 ms, visible hitbox debug in Training | db-gameplay |
| Teaming in FFA | Team mode is native; FFA queue gets anti-team (targeting a player hit by others reduces damage) | db-gameplay |
| Long cinematics | In-combat cinematics ≤ 3 s; full versions skippable; "seen once" quick transform | db-animation |
| Visual overload | VFX intensity slider + custom aura colours | db-animation |
| Bad tutorial | 60-s Whis tutorial + Training hitbox lab | db-story |
| Beam spam vs melee | Beams chargeable but interruptible; vanish counters beams; struggles reward timing | db-gameplay |
| Camera clipping | Camera collision with arena pieces + auto-pull-back | db-animation |
| Repetition | Weekly mini-updates (one character/form), monthly raid boss, build/private server modifiers | lead |
