# Dragon Block Z — v1 Move-Set Spec (DESIGN PROPOSAL)
> **Note (roblox lead decision):** db-gameplay `Config` numbers (form multipliers, unlock levels, base power) WIN over any numbers in this file. Values here are design proposals for feel/timing only. See `movesets_v3.md` §1 and `movesets_v4.md`.
All numbers below are **design proposals** for tuning in playtests. Frames are at 60 fps (1f ≈ 16.7 ms). Damage assumes base HP 1000.

## 1. What makes top Roblox DB / battlegrounds games feel good — and how we beat it
Based on public gameplay of Dragon Ball Rage, Dragon Ball Final Stand, Dragon Soul and the "Battlegrounds" genre (Strongest/ Z Battlegrounds style). No decompiling; observations are general.
| They do well | Common weaknesses | Our answer |
|---|---|---|
| Fast M1 chains with clear hit sounds (Battlegrounds) | Hits feel weightless; little hitstop | Per-hit hitstop (3–8f), finisher hitstop 10f + camera FOV punch |
| Beam struggles / big ki beams (Rage, Final Stand) | Beams are flat cylinders, laggy, server-rendered | Client-rendered layered beams (core + shell + tip + light), server only sends events |
| Flight & huge transformation progression (Final Stand, Rage) | Grind-gated; transforms are just stat boosts with recolor | Transforms change move properties (e.g. SSJ adds afterimage dash), unique aura + short cinematic |
| Dash/teleport counters (Battlegrounds) | Spam meta; unclear counterplay | Perfect block window, guard break meter, dash cooldown shared with vanish |
| Ragdoll/knockback spectacle | Desync, rubber-banding | Server-authoritative knockback with client prediction of own attacker animation |
**Pillars:** Responsiveness (input → anim ≤ 1 frame on client), Impact (hitstop + shake + VFX layered), Readability (every move has a distinct startup tell), Counterplay (every option has an answer).

## 2. Global systems
- **M1:** inputs buffered 10f; combo resets after 0.8 s idle; combo cooldown after finisher 1.0 s.
- **Hitstop:** light 3f, heavy 6f, finisher 10f, ultimate 14f (both attacker & victim freeze).
- **Camera shake** (intensity, duration): light (0.3, 0.1s), heavy (0.8, 0.2s), finisher (1.5, 0.3s), ultimate (3, 0.6s).
- **Dash:** 12f, 35 studs, 2.0 s cooldown, i-frames 4–9f. Vanish (dash during hitstun) costs 25 ki, 8 s cd.
- **Block:** -60% damage, 5 studs/s walk. **Perfect block**: first 6f after pressing → 0 dmg, attacker staggered 30f. **Guard meter** 100; each blocked hit drains (M1 10, specials 25); at 0 → guard break, 60f stun.
- **Ki:** 100 max, +8/s regen, charge (hold C) +30/s.
- **Animation priorities:** Idle/Walk=Core, Run/Fly=Movement, M1/Block/Dash=Action, Specials/Ultimates=Action4 (highest, overrides), Hitstun=Action3.
- **Knockback units:** studs/s applied via LinearVelocity for 0.2 s.

## 3. Shared M1 template (unless overridden)
5 hits: startup 6/6/7/7/10f, active 3f, recovery 8/8/9/9/18f; dmg 3/3/4/4/8; KB 0/0/0/0/60 (finisher launches). Finisher variants: hold Space = uppercut (launch up 50), hold S = downslam.

## 4. Roster
Format: Ki Blast | Special 1 | Special 2 | Ultimate (dmg / ki / cd / startup).

### Goku — balanced
- M1: template; finisher spinning kick (KB 70).
- Ki blast: 3 rapid shots, 4 dmg each, 5 ki, 1.5 s cd.
- S1 **Kamehameha**: hold-charge 0.5–1.5 s, beam 12–28 dmg, 30 ki, 10 s cd, 18f startup. (VFX: KamehamehaVFX.lua)
- S2 **Instant Transmission strike**: teleport behind target ≤40 studs, 10 dmg, 20 ki, 12 s.
- Ult **Spirit Bomb**: 2.5 s charge (armored), 45 dmg AoE r=25, 100 ki, 90 s.
- Transforms: Lv10 SSJ (x1.15 dmg, x1.1 spd, gold #FFD84A) · Lv25 SSJ2 (x1.25, sparks) · Lv40 SSJ3 (x1.35, drain 2 ki/s) · Lv60 SSG (x1.45, red #FF4A3A) · Lv80 SSB (x1.6, cyan #3AD7FF) · Lv100 Ultra Instinct Sign (x1.75, auto-dodge 15%, silver #DDE6FF).

### Vegeta — aggressive rushdown
- M1: 6 hits (faster: startup 5f), dmg 3×5 + 9 finisher (double-axe handle).
- Ki blast: big single blast 8 dmg, 8 ki, 2 s.
- S1 **Galick Gun**: 22 dmg beam, 30 ki, 10 s, 15f startup.
- S2 **Big Bang Attack**: projectile 18 dmg, explosion r=10, 25 ki, 9 s.
- Ult **Final Flash**: 50 dmg wide beam, 100 ki, 90 s, 40f startup.
- Transforms: Lv10 SSJ · Lv25 SSJ2 · Lv50 SSG · Lv70 SSB (x1.6) · Lv100 Ultra Ego (x1.8; gains dmg when hit, purple #9A4AFF).

### Gohan — combo/burst
- M1: template; finisher grabs and throws (KB 80).
- Ki blast: Masenko pellets 5 dmg, 6 ki, 1.8 s.
- S1 **Masenko**: 20 dmg beam, 25 ki, 9 s.
- S2 **Rage Rush**: 6-hit armored rush, 16 total, 25 ki, 12 s.
- Ult **Father-Son Kamehameha**: 48 dmg beam, 100 ki, 90 s.
- Transforms: Lv15 SSJ · Lv30 SSJ2 (x1.3, sparks) · Lv60 Ultimate (x1.5, white #FFFFFF) · Lv100 Beast (x1.8, silver-violet #C7B8FF).

### Frieza — zoner
- M1: 4 hits incl. tail swipe, longer range (+2 studs), dmg 4/4/5/9.
- Ki blast: Death Beam (fast hitscan) 6 dmg, 6 ki, 1.2 s.
- S1 **Death Saucer**: homing disc 15 dmg, 25 ki, 10 s.
- S2 **Psychokinesis Hold**: 1.2 s stun r=20 cone, 0 dmg, 30 ki, 15 s.
- Ult **Supernova**: 50 dmg huge ball, 100 ki, 90 s.
- Transforms: Lv10 2nd form · Lv25 Final Form (x1.25) · Lv50 Golden (x1.5, gold #FFC400, drain 1 ki/s) · Lv100 Black (x1.8, #2B1A3A).

### Jiren — tank/counter
- M1: 4 slow heavy hits (startup 9f), dmg 5/5/6/12, all with 4f hitstop.
- Ki blast: Power Impact fist wave 10 dmg, 10 ki, 2.5 s.
- S1 **Glare**: counter stance 0.6 s; on hit → 20 dmg + KB, 20 ki, 12 s.
- S2 **Power Impact**: giant energy ball 24 dmg, 30 ki, 12 s.
- Ult **Full Power Meteor**: 3-hit cinematic 45 dmg, 100 ki, 90 s.
- Passive: +20% guard meter. Transforms: Lv30 Strained (x1.3, red #FF3B3B) · Lv70 Full Power (x1.6, armor on specials).

### Hit — assassin
- M1: 5 jabs (startup 4f) dmg 2/2/3/3/8; finisher "pressure point" 0.3 s slow.
- Ki blast: Time-cancel jab (invisible punch) 6 dmg, 5 ki, 1.5 s.
- S1 **Time Skip**: 0.5 s pseudo-stop, 2 hits 12 dmg, 30 ki, 14 s.
- S2 **Time Cage** (trap): 2 s root, 25 ki, 16 s.
- Ult **Death Blow**: 40 dmg + ignores block, 100 ki, 90 s.
- Transforms: Lv40 Pure Progress (x1.35, purple #7A3BFF) · Lv80 Time Lord (x1.6, Time Skip cd −30%).

### Kefla — mobile brawler
- M1: template, faster recovery (−2f).
- Ki blast: Gigantic Ray volley 3×4 dmg, 6 ki, 1.5 s.
- S1 **Gigantic Ray**: thin beam 20 dmg, 25 ki, 9 s.
- S2 **Kefla Rush**: dash-strike chain 15 dmg, 20 ki, 10 s.
- Ult **Ultimate Spark Burst**: 360° burst + beam 46 dmg, 100 ki, 90 s.
- Transforms: Lv15 SSJ (x1.2) · Lv45 SSJ2 (x1.4, green-gold #C8FF3A) · Lv80 Full (x1.6).

### Toppo — grappler
- M1: 4 hits + grab finisher, dmg 4/5/5/10.
- Ki blast: Justice Flash 5 shots ×3 dmg, 8 ki, 2 s.
- S1 **Justice Crusher**: command grab 18 dmg, 25 ki, 12 s.
- S2 **Justice Tornado**: spin pulls in r=12, 14 dmg, 25 ki, 10 s.
- Ult **Hakai Sphere**: slow orb 55 dmg, unblockable, 100 ki, 100 s.
- Transforms: Lv35 Justice Mode (x1.3, red #FF5A2A) · Lv75 God of Destruction (x1.65, purple #8B3AFF).

## 5. Feel checklist per move
Startup tell (anim + sound) → active (hitbox Shapecast, server validated) → hitstop → shake → VFX → recovery. Client plays own anim instantly; server confirms hit and broadcasts VFX via RemoteEvent.
