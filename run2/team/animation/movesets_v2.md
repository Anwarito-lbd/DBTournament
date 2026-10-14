# Dragon Block Z — v2 Roster & Move Sets (DESIGN PROPOSAL)
> **Note (roblox lead decision):** db-gameplay `Config` numbers (form multipliers, unlock levels, base power) WIN over any numbers in this file. Values here are design proposals for feel/timing only. See `movesets_v3.md` §1 and `movesets_v4.md`.
All numbers are design proposals (60 fps, base HP 1000). Global systems (hitstop, shake, dash, block/perfect block/guard break, ki) are as in `movesets.md` §2. Transform multipliers apply to damage; speed gets half the bonus.

## Standard animation list (every fighter, ~30 clips)
`Idle, IdleCombat, Walk, Run, Sprint, Jump, Fall, Land, FlyIdle, FlyForward, FlyFast, DashF/B/L/R, Vanish, BlockStart, BlockHold, BlockHit, PerfectBlock, GuardBreak, M1_1..M1_5, M1_Uppercut, M1_Downslam, KiBlast_L, KiBlast_R, KiCharge (loop), Special1_Start/Loop/End, Special2_Start/Loop/End, Ultimate_Start/Loop/End, Transform_Charge (loop), Transform_Scream, Taunt, Hitstun_Light, Hitstun_Heavy, Launched, Knockdown, GetUp, KO, RingOut`.
Priorities: Core = idle/walk; Movement = run/fly; Action = M1/block/dash; Action2 = hitstun; Action3 = transform; Action4 = specials/ultimate.
Per-fighter **extra** clips are listed below.

## Show highlights (signature moments)
- **Ultra Instinct Sign / Mastered** — silver aura (`UISign`, `MUI` presets). Passive **Auto-Dodge**: UI Sign 15% / MUI 30% chance to auto-sidestep an incoming *non-grab, non-ultimate* hit if Goku is not in startup/recovery of his own attack; costs 8 ki per proc; 1.5 s internal cooldown; never procs while guard-broken or below 15 ki. MUI also auto-counters (6 dmg) on proc. UI form drains 3 ki/s (Sign) / 4 ki/s (MUI); reverts at 0 ki.
- **Goku vs Jiren clash / Beam Struggle** — when two beams' raycasts intersect within 0.2 s, both lock: a clash point spawns at the midpoint, each player mashes M1 (or holds the key with ki spend 10/s). Point moves by `(pressRateA*powerA − pressRateB*powerB)`; lasts max 4 s; winner's beam continues with +25% dmg, loser takes it; tie → both explode (15 dmg each). Cinematic: camera orbits clash point, shake 1.5 continuous, screen-edge aura colors.
- **Vegeta Ultra Ego** — purple aura (`UltraEgo` preset). Passive **Destruction Rage**: each 10% HP lost = +5% dmg (max +40%); cannot block (only perfect block), take +10% dmg.
- **Vegeta Final Explosion** — ultimate alt (low HP ≤ 25%): 2 s armored charge, 80 dmg r=35, Vegeta is KO'd after (counts as self-elimination, gives team "Pride" buff +15% dmg 20 s in team modes).
- **Kefla Potara fusion** — Caulifla + Kale players (or solo Caulifla using Kale summon in v2) within 10 studs both hold T for 1.5 s → `KeflaPotara` transform; earrings flash, fusion lasts 90 s; HP = average +30%.
- **Android 17 Barrier** — special: 360° barrier sphere 2.5 s, reflects ki blasts, blocks beams (takes 50%), detonate early for 12 dmg r=12 push.
- **Gohan Ultimate** — white aura (`GohanUltimate`), no ki drain, +20% combo damage on M1 chains.
- **Golden Frieza** — `GoldenFrieza`, drains 1 ki/s, Death Beam becomes 3-shot.
- **Jiren Full Power** — `JirenFullPower`, armor on M1 finishers, Power Impact size +50%.

## Universe 7
### Goku — balanced
M1: 5-hit template, finisher spinning kick. Ki: 3 rapid blasts 4 each (5 ki, 1.5 s). S1 Kamehameha (hold 0.5–1.5 s, 12–28 dmg, 30 ki, 10 s). S2 Instant Transmission strike (10, 20 ki, 12 s). Ult Spirit Bomb (45 AoE, 100 ki, 90 s); with UI: Silver Dragon Flash (40, 8 hits).
Transforms: Lv10 SSJ ×1.15 · Lv25 SSJ2 ×1.25 · Lv40 SSJ3 ×1.35 · Lv55 SSG ×1.45 · Lv70 SSB ×1.6 · Lv85 UI Sign ×1.75 · Lv100 MUI ×2.0.
Extra anims: `Kamehameha_Charge/Fire`, `IT_Fingers`, `SpiritBomb_Raise`, `UI_Dodge_L/R`, `UI_Counter`, `BeamStruggle_Push`.

### Vegeta — rushdown
M1: 6-hit, startup 5f, finisher double-axe handle. Ki: big blast 8 (8 ki, 2 s). S1 Galick Gun (22, 30 ki, 10 s). S2 Big Bang Attack (18 r=10, 25 ki, 9 s). Ult Final Flash (50 beam, 100 ki, 90 s) — alt **Final Explosion** at ≤25% HP.
Transforms: Lv10 SSJ · Lv25 SSJ2 · Lv50 SSG · Lv70 SSB ×1.6 · Lv100 Ultra Ego ×1.8.
Extra: `GalickGun_Charge/Fire`, `FinalFlash_Spread/Fire`, `BigBang_Palm`, `FinalExplosion_Charge`, `Taunt_Prince`.

### Gohan — burst
M1: template, finisher grab-throw. Ki: Masenko pellets 5. S1 Masenko (20). S2 Rage Rush (6 hits, 16, armored). Ult Father-Son Kamehameha (48).
Transforms: Lv15 SSJ · Lv30 SSJ2 ×1.3 · Lv60 Ultimate ×1.5 · Lv100 Beast ×1.8.
Extra: `Masenko_Overhead`, `RageRush_Loop`, `FatherSon_Kame`, `Glasses_Taunt`.

### Piccolo — trickster/zoner
M1: 4 hits + stretch-arm finisher (range +6). Ki: Hellzone pellets stay floating, detonate on S2. S1 **Special Beam Cannon** (2 s charge, piercing 26, 35 ki, 14 s) — `SpecialBeamCannonVFX`. S2 Hellzone Grenade (orbs converge 20, 30 ki, 12 s). Ult Light Grenade (44, 100 ki, 90 s).
Transforms: Lv30 Power Awakening ×1.35 (orange glint) · Lv80 Orange Piccolo ×1.65 (#FF8A2A).
Extra: `SBC_TwoFinger`, `StretchArm`, `Hellzone_Toss`, `Cape_Throw` (taunt), `Regenerate`.

### Android 17 — defensive
M1: 5-hit, finisher slide kick. Ki: twin energy shots 3×2. S1 **Barrier** (see highlights; 25 ki, 12 s). S2 Ki net trap (root 1.2 s, 20 ki, 12 s). Ult Super Electric Strike (barrier collapse into 3 beams, 42).
Transforms: none — Lv40 "Ranger Limit" ×1.3 (no aura, green barrier tint), Lv80 Infinite Energy ×1.5 (ki regen ×2).
Extra: `Barrier_Cast/Hold/Detonate`, `Net_Throw`, `Hands_In_Pockets` (taunt).

### Android 18 — combo
M1: 6 fast kicks (4f startup), dmg 2/2/3/3/3/7. Ki: Destructo-disc 1 (cuts, 7). S1 Energy Sign rush (14). S2 Infinity Bullet (barrage 18). Ult Power Blitz (40). Transforms: Lv40 Unlocked ×1.3 · Lv80 Full Output ×1.5.
Extra: `Kick_Flurry`, `Hair_Flip` (taunt), `Disc_Throw`.

### Frieza — zoner
M1: 4 hits incl. tail swipe (+2 range). Ki: **Death Beam** hitscan 6. S1 Death Saucer (homing 15). S2 Psychokinesis hold (1.2 s stun). Ult **Death Ball** (55, slow travel) — `DeathBallVFX`.
Transforms: Lv10 2nd form · Lv25 Final ×1.25 · Lv50 Golden ×1.5 · Lv100 Black ×1.8.
Extra: `DeathBall_FingerRaise`, `DeathBeam_Point`, `Tail_Swipe`, `Laugh` (taunt), `Hover_Seated`.

### Krillin — utility
M1: template. Ki: Scattering Bullet. S1 Destructo Disc (25, pierces block, 30 ki, 14 s). S2 Solar Flare (blind 1.5 s r=20, 20 ki, 18 s). Ult Krillin Wild Barrage (38). Transforms: Lv50 Potential Unleashed ×1.35 (white #F0F0F0).
Extra: `SolarFlare_Hands`, `Disc_Raise`, `Afterimage`.

### Master Roshi — technician
M1: 4 hits with staff. Ki: weak blast. S1 Evil Containment Wave (seals for 2 s, costs 20% own HP). S2 Thunder Shock Surprise (stun 16). Ult Max Power Kamehameha (bulked body, 45). Transforms: Lv30 Max Power ×1.4 (muscle form).
Extra: `Staff_Twirl`, `MaxPower_Bulk`, `Mafuba_Swirl`, `Sunglasses_Adjust`.

### Tien — pressure
M1: template. Ki: Dodon Ray (hitscan 7). S1 Multi-Form (2 clones mimic M1s 4 s). S2 Kikoho (triangle blast 22, costs 5% HP). Ult Neo Tri-Beam (repeated 4×12 pin-down). Transforms: Lv40 Third Eye ×1.35.
Extra: `TriangleHands`, `Clone_Split`, `TriBeam_Repeat`.

## Universe 11
### Jiren — tank/counter
M1: 4 heavy hits (9f startup, 4f hitstop each). Ki: fist wave 10. S1 Glare counter (20). S2 **Power Impact** (24) — `PowerImpact` (via DeathBallVFX with red config). Ult Full Power Meteor (45). Transforms: Lv30 Strained ×1.3 · Lv70 Full Power ×1.6.
Extra: `Glare_Stance`, `Crossed_Arms_Idle`, `Meteor_Combo_1..3`, `BeamStruggle_Push`.
### Toppo — grappler
M1: 4 hits + grab. Ki: Justice Flash. S1 Justice Crusher (grab 18). S2 Justice Tornado (pull 14). Ult Hakai Sphere (55 unblockable). Transforms: Lv35 Justice Mode · Lv75 God of Destruction ×1.65 (`ToppoGoD`).
Extra: `Justice_Pose` (taunt), `Hakai_Orb_Raise`, `Grab_Slam`.
### Dyspo — speedster
M1: 6 hits (3f startup), low dmg 2 each, finisher 6. Ki: Light bullet. S1 Super Maximum Light Speed Mode (dash chain ×3, 15). S2 Justice Kick (14, guard-break 40). Ult Light Speed Barrage (40). Transforms: Lv40 Max Light Speed ×1.35 (purple-white).
Extra: `LightSpeed_Blur`, `Ears_Twitch`, `Pose_Justice`.

## Universe 6
### Hit — assassin
M1: 5 jabs (4f). Ki: invisible punch 6. S1 **Time Skip** (12, 2 hits) — `TimeSkipVFX`. S2 Time Cage trap. Ult Death Blow (40, ignores block). Transforms: Lv40 Pure Progress ×1.35 · Lv80 Time Lord ×1.6.
Extra: `HandsInCoat_Idle`, `TimeSkip_Vanish/Appear`, `Coat_Adjust`.
### Kefla — fusion brawler
M1: template, −2f recovery. Ki: Gigantic Ray volley. S1 Gigantic Ray (20). S2 Kefla Rush (15). Ult Ultimate Spark Burst (46). Transforms: Lv15 SSJ · Lv45 SSJ2 ×1.4 (`KeflaSSJ2`). Obtained via **Potara** (highlights).
Extra: `Potara_Earring`, `Fusion_Flash`, `Spark_Burst_360`.
### Cabba — student
M1: template. Ki: Galick-style shots. S1 Galick Cannon (18). S2 Charge Rush. Ult Final Flash (Cabba ver., 38). Transforms: Lv20 SSJ ×1.2 · Lv60 SSJ2 ×1.35.
Extra: `Salute`, `Rush_Shoulder`.
### Caulifla — hothead
M1: 5 hits, aggressive. Ki: Crush Cannon. S1 Super Dash. S2 Crush Cannon (20). Ult Spirit Burst (40). Transforms: Lv15 SSJ (`CauliflaSSJ`) · Lv35 SSJ2 ×1.35 · fusion with Kale.
Extra: `Smirk`, `Flex_Taunt`, `Potara_Earring`.
### Kale — berserker
M1: 4 slow huge hits. Ki: Eraser blast. S1 Berserk Grab. S2 Gigantic Meteor (28). Ult Eraser Cannon (50). Transforms: Lv25 Berserk ×1.4 (lose control: auto-run toward nearest enemy) · Lv60 Controlled Berserk ×1.55 (`KaleBerserk`).
Extra: `Berserk_Roar`, `Shy_Idle`, `Muscle_Grow`.

## Universe 2
### Ribrianne — support/zoner
M1: 4 hits with heart staff. Ki: heart shots. S1 Rabu-Rabu Arrow (homing 16). S2 Love Prison (cage 2 s). Ult Pretty Black Hole (gravity zone 40). Transforms: Lv20 Ribrianne Form (pink #FF7AD0) · Lv60 Giant Heart ×1.4.
Extra: `Magical_Girl_Transform` (long), `Heart_Pose`, `Wink` (taunt).

## Universe 3
### Anilaza — giant (boss-tier, unlock Lv70)
M1: 3 huge swings r=10. Ki: finger cannon. S1 Hearing Radar (reveals, + next hit +50%). S2 Anilaza Punch (warp-punch from distance 26). Ult Anilaza Clap (shockwave 50). Size ×3, HP ×1.8, no dash (stomp instead).
Extra: `Stomp`, `Radar_Ears`, `Warp_Punch`, `Roar`.

## Universe 4
### Ganos — scaling fighter
M1: 5 claws, each consecutive combo +2% dmg (stack 10). Ki: wing blade. S1 Shock Nails (14). S2 Wing Dive (18). Ult Ganos Charge (42). Transforms: Lv30 Awakened Ganos ×1.35 (blue #3A7BFF).
Extra: `Wing_Spread`, `Claw_Flurry`, `Awaken_Roar`.
