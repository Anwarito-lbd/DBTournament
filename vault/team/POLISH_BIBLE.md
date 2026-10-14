# DRAGON BLOCK Z — POLISH BIBLE v1.0
*2026-10-13. Owner: lead "roblox". Status: SPEC (nothing in this doc has been run in Studio). All numbers are design values. Tune them in Studio and log the changes in CHANGES.md.*

Frame convention: **60 fps** (matches `poses/*.lua` `fps = 60`). `f12` = frame 12 = 200 ms. Hitstop is given in ms and frames.
Coding agents: **Antigravity (AG)** and **OpenCode (OC)** only. No Claude Code.
Hard rules carried over from ANTIGRAVITY_HANDOFF.md: no ripped assets or audio (FighterZ, Xenoverse, Sparking Zero, Legends, Budokai), paid power capped at 1.35x, Ranked flattens stats, DEV_MODE off before release.

---
## 0. Research summary (sources)
| Finding | Use in DBZ | Source |
|---|---|---|
| Arc System Works "limited animation": no interpolation, every frame is a held pose, 1-frame snaps between poses, intentionally rough frames in close-ups | Add `ease="Constant"` "stepped" mode for supers and cinematics. Keep `Sine/Cubic` easing for locomotion only | GGXrd GDC talk (Motomura) https://www.gdcvault.com/play/1022031/GuiltyGearXrd · PDF https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf · Keo breakdown https://dkeodara.com/2017/06/19/dragonball-fighterz-more-than-meets-the-eye/ · Engadget https://www.engadget.com/2017-06-17-dragonball-fighterz-looks-dangerously-close-to-the-anime.html |
| FighterZ uses camera-angle cuts and lighting changes on supers and finishers | Camera choreography per move type (§1.4), plus a "Dramatic Finish" KO cam | Engadget (above), Cinemablend https://www.cinemablend.com/games/1671520/why-dragon-balls-latest-game-has-2d-combat |
| Sparking Zero: Vanishing Assault teleports behind at close range and closes the gap at mid range. Z-Counter chains. Beam Struggle is a mash plus a timed Ki boost | Vanish and Z-Counter chain (§1.5), beam struggle rules (§1.5) | Bandai Namco EU https://en.bandainamcoent.eu/dragon-ball/news/dragon-ball-sparking-zero-combos-and-features · IGN https://www.ign.com/wikis/dragon-ball-sparking-zero/Advanced_Combat_Tips · games.gg https://games.gg/dragon-ball-sparking-zero/guides/dragon-ball-sparking-zero-impact-qte-guide/ · Dexerto https://www.dexerto.com/gaming/dragon-ball-sparking-zero-how-to-sonic-sway-deflect-beams-more-2921518/ |
| TSB: 4 M1s, the last one ragdolls. The string resets after 1.5 s. Extenders: uppercut (jump+M1), downslam (air M1), wall combo. A perfect block makes the next M1 a crit. Skilled players use "techs" (delayed M1, dash cancels) | 6-hit string with 3 branch enders, perfect-guard crit, and deliberate tech room (§1.5, §1.7) | https://thestrongestbattlegrounds.miraheze.org/wiki/Basic_Combat · https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat · https://bloxodes.com/wiki/the-strongest-battlegrounds/techniques |
| JJS is forgiving and spectacle-first (awakenings, domains). TSB is the depth game | A friendly floor (input buffer, auto-face) with a deep ceiling (cancels, resets) | https://earnaldo.com/blog/the-strongest-battlegrounds-vs-jujutsu-shenanigans |
| Roblox best practice: split tracks M1_1..n, marker-driven hit and cancel frames, 0.15–0.3 s input buffer, hitstop of 2–4 frames via `AdjustSpeed(0)` on both rigs, Action priority, FadeTime 0.1–0.15 | Matches the PosePlayer marker design. Hitstop table in §1.2 | DevForum https://devforum.roblox.com/t/how-do-battlegrounds-games-handle-m1-combo-animations-single-animation-vs-split-tracks/4711717 · https://devforum.roblox.com/t/animationtrackadjustspeed0-not-pausing-animation/3065792 · https://kitsblox.com/blog/how-to-make-combat-system-roblox |
| Roblox audio: you need the rights. One track, mp3/ogg/wav/flac, <20 MB, <7 min, ≤48 kHz. Audio is always Restricted, so the experience needs permission | §3 audio pipeline | https://create.roblox.com/docs/audio/assets · https://en.help.roblox.com/hc/en-us/articles/23359485439124-Audio-Upload-License-Agreement · https://devforum.roblox.com/t/full-release-privacy-for-newly-created-image-mesh-and-decal-assets/4620416 |

Not verified directly (no page fetched; fill from YouTube in a review pass): Heroes Battlegrounds, Dragon Ball Rage and Anime Battlegrounds frame data. Their design patterns are summarized from community knowledge only: DB Rage puts transformations behind grind levels and has big beam clashes, and Heroes BG gates moves behind mastery. Treat these as patterns, not numbers.

---
## 1. ANIMATION THAT FEELS ADDICTING (TOP PRIORITY)

### 1.1 Principles (checklist for every clip)
1. **Anticipation**: 3–8 f wind-up for lights and 8–20 f for heavies and supers. The wind-up moves *opposite* the strike (cocked shoulder, waist twisted back 20–35°).
2. **Smear frame**: one frame on the contact-minus-1 key. Exaggerate the limb (pos offset 0.3–0.6 studs along the swing) and add the `VFXCommon.Afterimage` marker. In code: a key with `ease="Constant"` pushed one frame before contact.
3. **Stepped holds (ArcSys)**: supers and cinematics use `Constant` easing between keys at 2s or 3s (a new pose every 2 or 3 frames). Locomotion stays smooth.
4. **Contact pose overshoot**: on the contact key the limb overshoots its final extension by 5–10°, then settles back with `BackOut` within 4 f.
5. **Recovery reads**: a held follow-through for 4–10 f, then a fast return to stance. Recovery is where cancels live.
6. **Squash/stretch substitute**: rigs can't scale, so use Root pos dips of 0.15–0.3 studs on landing and impact, and a 0.2 stud Root lift on launch.
7. **Silhouette**: every contact frame has to read from the camera. Limbs off the torso, the head turned toward the target.
8. **Victim animation sells the hit**: HurtLight alternates left and right. HurtHeavy folds 25° at the waist. Every hurt key has to be shorter than the attacker's recovery.

### 1.2 Hitstop per hit tier
Both rigs freeze (`AdjustSpeed(0)` or PosePlayer `h.Speed=0`). The victim also gets a positional shake of ±0.08 studs at 30 Hz.
| Tier | Hitstop | Shake (cam) | FOV kick | Impact frame (screen flash) | Used by |
|---|---|---|---|---|---|
| Light | 50 ms (3 f) | 0.15 / 0.08 s | 0 | none | M1_1–M1_3 |
| Medium | 75 ms (4–5 f) | 0.25 / 0.10 s | -1 | none | M1_4–M1_5, ki blast |
| Heavy | 110 ms (7 f) | 0.45 / 0.14 s | -3 then back over 0.15 s | 1 f white silhouette | M1_6 enders, Heavy, Launcher |
| Crit / PerfectGuard counter | 140 ms (8 f) | 0.6 / 0.18 s | -4 | 2 f inverted B/W "impact frame" + crack SFX | perfect-guard crit |
| Super | 160 ms (10 f) | 0.8 / 0.25 s | -6 | 2 f B/W plus radial lines | supers, wall bounce |
| Ultimate / Finisher | 250 ms + 0.3x slow-mo for 400 ms | 1.0 / 0.4 s | -8 | 3 f B/W, chromatic aberration | ultimates, KO finisher |
Rules: hitstop never stacks (take the max). In Ranked, cap Ultimate to 160 ms (no slow-mo). Server time does not freeze, so hitstop is cosmetic; the server adds the same ms to the attacker's next-move availability so timing stays honest. Multi-hit victims (5+ targets in ToP) get 50% hitstop to keep large lobbies moving.

### 1.3 Cancel windows, buffer, priority, motion
- **Input buffer:** 200 ms (12 f) for attacks, 120 ms for dash and vanish. Keep the last input only. Hold-M1 auto-chains.
- **Cancel windows (markers `cancel={into=...}`):**
  - M1_n → M1_n+1: from contact+2 f to contact+14 f.
  - Any M1 → Dash/Vanish: contact+1 f to end (*dash cancel*). Costs 1 dash stock.
  - M1_3/M1_5 → Special (ki move): contact+4 f to end.
  - Special → Vanish: on hit only, costs 25 ki (Z-Counter style).
  - Beam Fire → nothing (commitment). Charge → Guard/Vanish is allowed (the charge is lost).
- **String reset:** 1.2 s with no M1 (TSB uses 1.5 s; ours is faster).
- **Animation priority map:** Idle/FlyIdle=`Idle` · locomotion/dash=`Movement` · M1/heavy/guard=`Action` · ki moves=`Action2` · hurt/knockback=`Action3` · transformation/ultimate/cinematic=`Action4`. PosePlayer `BuildKeyframeSequence` already reads `clip.priority`, so set these strings in gen_poses.py.
- **Root motion vs physics:** animations are *in place* (the Root pos is cosmetic and ≤0.5 studs). Real displacement comes from the server: `LinearVelocity`/`AlignPosition` impulses fired by markers `move={dist, time, curve}`. Knockback and launch are physics with ragdoll (`Humanoid:ChangeState(Physics)` and BallSocket constraints) for HurtHeavy+ only. Lunges snap to the target with `AlignOrientation` (12 f) when it is within 8 studs (soft lock).
- **Netcode feel:** the client plays the swing on input at once. The server validates the hit (≤ 250 ms rewind window). VFX on hit is client-predicted for the attacker and server-confirmed for the others.

### 1.4 Camera choreography by move type
| Move type | Camera | Shake | FOV (base 70) |
|---|---|---|---|
| M1 1–5 | Gameplay cam, 2° roll toward the swing side per hit | Light/Med | — |
| M1 6 ender | 0.1 s push-in of 1.5 studs, then a pull back with the target | Heavy | 70→66→72 |
| Dash | Lag 0.12 s behind the HRP, speed lines | none | 70→80 for 0.2 s, ease back over 0.3 s |
| Vanish | 2 f cut: cam stays, the player blinks; recentres over 0.15 s | 0.1 | 70→64 snap, back over 0.2 s |
| Launcher/uppercut | Tilt up 15° following the target | Heavy | 72 |
| Ground slam | Tilt down 20° onto the crater, then a slight dolly-out | Super | 76 |
| Beam charge | Over-the-shoulder 3/4 front, slow dolly-in 2 studs per second of charge | rumble 0.05 rising to 0.2 | 70→60 |
| Beam fire | Snap to side-profile 90° for 0.4 s (local player only, opt-out setting), then the gameplay cam | 0.6 sustained, decaying | 60→85 |
| Beam struggle | Locked side-profile midway between casters, pushing toward the losing side | 0.3 sustained, pulsing with mashes | 75 |
| Transformation | Client cinematic (TransformCinematic.client.lua): low-angle orbit, 120° over 1.8 s | 0.4 build, 1.0 burst | 55→80 on burst |
| Ultimate | Letterbox 2.35:1, 3-cut sequence (face close-up, wide, impact) | 1.0 | per cut |
| KO finisher | 0.3x slow-mo, orbit the victim 90° | Ultimate | 65 |
Accessibility settings: "Reduce shake" (x0.3), "No cinematic cuts" (gameplay cam only), "Flash reduction" (impact frames swapped for a 30% white tint). All three default ON for mobile.

### 1.5 Frame-by-frame specs (60 fps)
Notation: `fN` keyframe at frame N · **mk** markers (PosePlayer format: `sound`, `vfx="Module.Fn:arg"`, `hit={tier,hitstop}`, `cancel`, `move`, `cam`).
New marker keys needed (gap): `cancel`, `move`, `cam`, `shake`, `fov`. See §1.9.

**M1 string (6 hits, alternating arms, damage 3/3/3/4/4/7 %)**
| Hit | Length | Anticip. | Smear | Contact | Recovery/cancel | Motion | Cam/shake/FOV | VFX | SFX |
|---|---|---|---|---|---|---|---|---|---|
| M1_1 L jab | 22 f | f0–5 shoulder back 25°, waist -15° | f6 | f7 Light | f9–21 → M1_2 | lunge 1.5 st over 6 f | roll +2°, Light | small white ring impact, dust puff | Swing_Light, Hit_Light (±8% pitch) |
| M1_2 R straight | 22 f | f0–5 | f6 | f7 Light | f9–21 | 1.5 st | roll -2° | ring + 4 spark lines | Swing_Light, Hit_Light |
| M1_3 L hook | 24 f | f0–6 waist wind 30° | f7 | f8 Light | f10–23; Special-cancel from f12 | 1 st | roll +3° | arc smear trail | Swing_Med, Hit_Light |
| M1_4 knee | 26 f | f0–7 Root dip 0.2 | f8 | f9 Medium | f11–25 | 1 st, victim lifted 0.5 st | Medium | shock ring, yellow sparks | Swing_Med, Hit_Med |
| M1_5 spin kick | 28 f | f0–8 360° coil (Root rot Y keyed at 2s) | f9 | f10 Medium | f12–27; Special-cancel | 2 st | roll -4°, Medium | wind arc, afterimage 0.4 | Whoosh_Spin, Hit_Med |
| M1_6 ENDER (branch) | 34 f | f0–12 big wind-up, ki flash on fist at f10 | f13 | f14 Heavy | f16–33 Dash/Vanish only | see the branches below | Heavy, 70→66→72 | impact frame, shock dome, debris | Charge_Short, Hit_Heavy, Crowd "oh" (ToP) |
Ender branches (TSB-style, input held on the 6th press): **neutral** = knockback (straight blast, 40 st) · **jump+M1** = Launcher (up 25 st, chase window 0.6 s) · **air M1** = Ground slam · **wall within 6 st** = Wall bounce, then 0.5 s of free follow-up.

**Dash** (Q, 2 stocks, 1.2 s recharge): f0–2 crouch (Root -0.2), f3 burst pose leaning 35°, f3–14 travel 18 studs (LinearVelocity, QuadOut), f15–20 brake skid (Root -0.15, dust). Cancel into M1 from f8. Cam: FOV 70→80 f3, back by f30. VFX: ki burst at the feet, speed lines, 3 afterimages. SFX: Dash_Burst, Dash_Skid.

**Vanish** (Z-Counter style; 25 ki): f0 pose snapshot, f0–1 body transparency 1, "zip" streak VFX. f2–7 invisible (i-frames f0–9). f8 reappear behind or beside the target (close range) or in front (mid range, ≤25 st). f8–12 reappear flare and a 0.15 s slow-down for the attacker. Counter chain: if the victim presses vanish within 12 f of the reappear, they counter-vanish (both cost 25 ki, +10% damage per exchange, max 4). Cam: FOV 70→64 snap, back over 12 f. SFX: Vanish_Zip (and Vanish_Whiff on a miss). VFX: afterimage that dissolves in 10 f, a white ring at the reappear.

**Guard** (hold F): f0–4 arms cross (Shoulders 70°, Elbows 110°), held. Block hit: victim pushback of 1.5 st, Block_Impact SFX, blue hex shards. **PerfectGuard** = guard pressed ≤ 8 f before a hit: 140 ms hitstop on the attacker, attacker stun 30 f, defender's next M1 is a Crit (x1.8, crack SFX, B/W impact frame). Guard break after 6 blocked hits or 1 heavy: 50 f stagger, glass-break SFX.

**Knockback (victim)**: f0 HurtHeavy fold 25°, f1–3 ragdoll on, flight 40 st over 18 f (QuadOut), air trail. Landing: bounce 2x (0.5 and 0.2 studs), dust cloud, 30 f down, then wake-up with 20 f of i-frames (or tech-roll: press dash within 10 f of landing, no i-frames but instant).

**Wall bounce**: on contact with a part tagged `Bounceable` (or any anchored wall) while ragdolled at >20 st/s: Super hitstop (160 ms), crack decal (radial, 4 st), debris 8 parts, victim rebounds 6 st toward the attacker. Follow-up window 0.5 s. Each combo gets 1 wall bounce max.

**Ground slam (air M1 ender)**: f0–8 overhead hammer-fist wind (both arms up), f9 smear, f10 contact Heavy, victim driven down at 80 st/s. On landing: crater (6 st radius, ArenaDamage-safe decal-only in training), Super shake, ring dust, rock debris. Victim bounce 3 st (a juggle-able "OTG"). Attacker lands at f20, recovery to f34.

**Flight** (double jump / Space hold): takeoff f0–6 crouch → leap with an aura flare. FlyIdle: legs trailing, 2 s bob. Fast flight (Shift): body pitched 70° forward, one arm forward (Goku) or arms crossed (Vegeta), with a sonic cone VFX at > 60 st/s. Turns bank the Root up to 25°. Landing: f0–4 brake (legs forward), Root dip 0.3, dust.

**Beam charge → fire (Kamehameha template)**
- `_Charge` (0.6–2.0 s, loop after f40): f0–10 stance widens, hands draw to the hip (Root dip 0.25), f10–40 ki sphere grows 0.2→1.6 st, aura flares at 33%, 66% and 100% (each flare: shake +0.1, SFX tier). Voice line on f12.
- `_Fire`: f0–3 thrust (Constant step), f3 beam spawns with a 0.05 s white flash. Beam head travels 300 st/s. Cam side-profile, FOV 60→85. f3–60 sustain pose, arms shaking ±1° at 30 Hz.
- `_Hold`: looped sustain, victim-side hit every 6 f (Light hitstop at 50%).
- End: f0–12 recoil (arms back 15°), smoke from the palms.
- Beam = cylinder core plus a rim plus a head sphere plus a ground scorch trail. Colours in §2.

**Beam struggle**: triggered when two beam heads come within 4 studs. A collision orb plus a lightning ring. Both players go to `BeamStruggle_Push` (gap: new clip). Mash M1 (each press +1 push, max 12/s counted; mobile = a big button) plus a **Ki Boost** (R, once, 30 ki): +15 push if used while the orb is within ±20% of the centre, +5 otherwise (Sparking Zero logic). 3–6 s duration. Push bar on the HUD, the camera shifts toward the loser. The winner's beam continues at 70% damage. Ties after 6 s: both explode, 50% knockback for each. Three-way struggles: the orb point is the weighted centre, and the vector sum decides who takes it.

**Transformation** (template `Transform_X`, 1.8 s, Action4, i-frames, interruptible only by Hakai and Ultimates):
f0–20 hunch, fists clenched (stepped 3s) · f20 scream starts (voice) · f20–60 power-up: aura grows, rocks rise (12 parts), ground cracks · f60 hair/aura colour snap (1 f flash in the form colour) · f60–80 burst pose, arms out · f80–108 settle into the new idle. Cam: low orbit 120°, FOV 55→80 at f60. Shake 0.4 rising to 1.0 at f60. Light: global ColorCorrection tint toward the form colour at 30% for 0.5 s. Nearby players are pushed back 8 st.

**Ultimate** (template, 3–4 s, letterboxed, Action4): cut A face close-up 0.6 s (voice line), cut B wide charge 1.2 s, cut C impact 1.2 s (Ultimate hitstop + slow-mo), return. Only the caster and the target get the full cutscene; others see it in the world with 40% shake. In ToP with 20+ players, skip cut A for spectators.

### 1.6 Signature kits (clip names → PosePlayer)
| Char | M1 flavor | Specials (clips) | Transform | Ultimate | Signature feel |
|---|---|---|---|---|---|
| Goku | Fast, open-hand palm strikes on hits 3 and 5 | Kamehameha (have), KiVolley (have), InstantTransmission (have), DragonFist (NEW) | SSJ / SSB / UI (have) | MUIRush (have) → Spirit Bomb (have) | IT behind the target → free M1 restart (a 1-per-combo reset) |
| Vegeta | Heavier, short hops, elbows | GalickGun (have), BigBang (have), FinalFlash (have), FinalExplosion (have) | SSJ / SSB / UltraEgo (have) | FinalExplosion (sacrifice: 35% self HP) | Prideful taunt (Idle_PridefulCross) gives a 3% damage buff for 5 s if not hit |
| Frieza | Tail sweeps, finger flicks, gliding (no foot plants) | DeathBeam (have), DestructoDisc (have), NovaStrike (have), DeathBall (have) | Golden / Black (have) | BlackNova (have) | DeathBeam pierce flinch at 2 f startup, the fastest poke in the game |
| Jiren (NEW file) | Minimal motion, arms folded until contact, "invisible" hits (smear only) | PowerImpact (VFX exists), Glare (NEW: a 0.5 s stun cone), Barrier counter (NEW) | Full Power (NEW) | PowerImpact Max | Passive "Meditate": stands still 1.5 s, next hit +20%. Animation is mostly HOLDS |
| Broly (NEW file) | Wild, two-handed clubbing, grabs | Gigantic Roar (NEW), EraserCannon (NEW), Grab-Slam (NEW) | Wrath / LSSJ (NEW) | Gigantic Meteor (NEW) | Rage meter: anim speed x1.0→1.25 as HP drops (within the 1.35 cap) |
| Gohan (NEW file) | Precise, kicks heavy, beast-like crouch | Masenko (NEW), FatherSon Kamehameha (NEW; uses Goku's ghost), SpecialBeamCannon (VFX exists) | SSJ2 / Ultimate / Beast (BeastSBCVFX exists) | Beast SBC | "Hidden potential": a perfect guard charges Beast faster |

### 1.7 Mastery feel and "one more match" hooks
- **Combo counter** (HUD, right side): number pop at 1.3x scale with a BackOut 0.15 s, colour stepping white→yellow (5)→orange (10)→red (15)→Kaioken red with flames (20+). Damage % below it. Drop: 0.8 s fade plus a "DROP" text if broken.
- **Style rank** (DMC-like, letters D→C→B→A→S→SS→Z): points for variety (a repeated move counts 50% less), cancels (+), wall bounce (+), vanish counters (+++), getting hit (−40%). A Z-rank match gives +15% Zeni (cosmetic badge, not stats).
- **Finishers:** when the last hit would KO, the 6th M1 or an ultimate triggers the KO cam (slow-mo 0.3x, orbit, a white flash, the victim silhouetted). Per-character finisher poses (victory taunts) unlock through mastery.
- **Mastery tracks** per character, levels 1–50: unlock alt M1 enders, KO cam styles, aura trails, voice lines and titles. Cosmetic only (respects the 1.35 cap).
- **Replays:** server-recorded event log (position + clip + time at 10 Hz, ≤ 30 s of buffer). "Best moment" auto-pick = highest combo and damage window → 8 s replay at the end of the round with free-cam. Share button = a screenshot only (Roblox `CaptureService`).
- **Post-match loop:** XP bar fill animation (0.6 s per level with chime), a "Next unlock at X" teaser, the daily quest tick, and a "Rematch" button highlighted (default focus) with a 10 s auto-queue.
- **Techs we intentionally leave in:** delayed M1, dash-cancel M1 reset (once per combo), IT reset, vanish counter chains. Document them in the in-game "Dojo" tips.

### 1.8 Mapping onto the existing PosePlayer and poses format
- Clips are tables `{fps, length, looped, priority, keyframes={{t, ease, markers, poses}}}`, generated by `team/animation/poses/gen_poses.py`. **Edit the generator, not the .lua files.**
- Markers go through `opts.OnMarker` or `opts.Registry["Module.Fn"]`. Register `Hit`, `Cancel`, `Move`, `Cam`, `Shake`, `Fov` handlers in a new `AnimMarkerRouter` (client) and a `CombatMarkers` validation table (server).
- Hitstop: add `PosePlayer` handle method `h:Freeze(ms)` (sets Speed 0, restores). The VFXCommon.Hitstop marker already exists; make it call `h:Freeze` using the §1.2 table.
- Stepped mode: `ease="Constant"` already exists. Add a clip flag `stepped=2|3` in the generator to auto-insert holds.
- Export: `PosePlayer.BuildKeyframeSequence` → KeyframeSequence with KeyframeMarkers → upload as Animation assets (owned by the user/group) → IDs in `Config.ANIM_IDS`.

### 1.9 Gaps in the current poses files (audited 2026-10-13)
Present: `Shared, Goku, Vegeta, Frieza`, each with Idle, Dash, FlyIdle, Guard, PerfectGuard, Heavy, Launcher, AirCombo, KiVolley, HurtLight/Heavy, KO, M1_1–M1_4, plus the specials and transforms listed in §1.6.
Missing:
1. **M1_5, M1_6** (and the ender branches `M1_6_Knockback`, `M1_6_Uppercut`, `M1_6_Slam`, `M1_6_WallCombo`) in all files. The string is 4 hits today and the design is 6.
2. **Vanish_Out, Vanish_In, VanishCounter**. Only Goku has InstantTransmission.
3. **GuardBreak, GuardHit, TechRoll, WakeUp, Knockback_Air, WallBounce_Victim, GroundBounce_Victim, Grabbed**.
4. **FlyFast, FlyTakeoff, FlyLand, FlyBank_L/R, Flight_Dash**.
5. **BeamStruggle_Push, BeamStruggle_Win, BeamStruggle_Lose**, plus a generic `Beam_Charge/Fire/Hold` for characters without a signature beam.
6. **PowerUp_Stage1–3** (the 3-stage scream from the handoff task list), **Taunt**, **Victory_1–3**, **Defeat**, **KO_Finisher_Victim**.
7. **Kaioken_Toggle, Giant_Toggle, Beast_Release, Barrier, SolarFlare, JusticePose, KaiKai, Hakai** (gameplay systems exist with no clips).
8. **Characters:** no `Jiren.lua`, `Broly.lua`, `Gohan.lua` (plus Shin, Zamasu, Moro, the raid bosses). The raid bosses need `Boss_Telegraph_*` clips (§4).
9. **Marker vocabulary:** no `cancel`, `move`, `cam`, `shake`, `fov`, `iframe`, `armor` keys. Priority strings use only Idle/Action, so map them to §1.3.
10. **Training clips:** `GravityStrain_Walk/Idle`, `Pushup`, `Sparring_Dodge`, `Bubbles_Chase`, `Gregory_Swing`, `Whis_Dodge_L/R/Duck/Jump`, `Meditate` (§5).

---
## 2. VFX & COLOR

### 2.1 Form palette (aura core / aura rim / hair / lightning / beam core / beam rim)
| Form | Aura core | Aura rim | Hair | Sparks | Beam core | Beam rim |
|---|---|---|---|---|---|---|
| Base (Goku-type ki) | #FFFFFF | #8FD3FF | char default | — | #E8FBFF | #2FA8FF |
| Kaioken | #FF3B2F | #8B0000 | char default | — | #FFD6D0 | #FF2A1A |
| SSJ | #FFF27A | #FFB300 | #FFE14D | — | #FFFCE0 | #FFC400 |
| SSJ2 | #FFF27A | #FFB300 | #FFE14D | #9AE8FF | #FFFCE0 | #FFC400 |
| SSJ3 | #FFE45C | #E89B00 | #FFD733 (long) | #9AE8FF | #FFF6C8 | #FFAA00 |
| SSJ4 | #FF6A5C | #B3121E | #1A1A1A | — | #FFE3E0 | #E3263B |
| SSJ God | #FF8A4C | #D7263D | #C8102E | — | #FFE9DB | #FF4F3A |
| SSJ Blue | #7FE7FF | #0D6EFD | #33C6FF | — | #E9FCFF | #0A84FF |
| SSB Kaioken | #6FD8FF core + #FF2E2E rim | #FF2E2E | #33C6FF | — | #E9FCFF | #FF2E2E |
| Rosé | #FF8FD8 | #A2007D | #FF69C8 | — | #FFE3F6 | #D6006F |
| UI Sign | #E6F2FF silver | #5B7CFF | char default (dark) | — | #FFFFFF | #A9B8FF |
| MUI | #FFFFFF | #C7D3E8 silver | #DDE3EA | — | #FFFFFF | #B8C4D6 |
| Ultra Ego | #B57BFF | #3B0A6E | #6E2DB5 | — | #F1E3FF | #7A1FD1 |
| Beast | #F3EDFF | #9B6BFF | #EDE8F7 white-violet | #C9A8FF | #FFFFFF | #8A4DFF |
| Golden Frieza | #FFD24A | #B8860B | — (gold skin #F2C230) | — | #FFF4C2 | #E0A800 |
| Black Frieza | #2B1A3F core + #A64DFF rim | #A64DFF | — (skin #1C1426) | #FF4DD2 | #F0D9FF | #8F00FF |
| Hakai | #5B2A86 | #1A0A2A | — | #C77DFF | sphere #2A0F3D | #9D4EDD |
| God Aura (Beerus camp) | #A97CFF flame | #3A1E66 | — | — | — | — |
| Jiren Full Power | #FF4040 | #6B0F1A | — | — | #FFE0E0 | #FF2A2A |
| LSSJ / Broly | #8BFF6A | #1F7A1F | #C6FF7A | #B7FF5A | #E8FFE0 | #33CC33 |
| Majin mark (Majin Vegeta) | #FFF27A | #FFB300 | — | #FF4D4D sparks | — | — |
| Android (infinite ki) | none (no aura) | heat shimmer #CFE8FF | — | — | #F0FBFF | #7FCBFF |
| Spirit Bomb | #E6FAFF | #45B6FF | — | — | sphere #FFFFFF | #3FA9F5 |

### 2.2 Aura styles
- **Flame aura (Z era: SSJ/SSJ2/3/Kaioken):** 3 ParticleEmitters (core 40/s, rim 20/s, spark 6/s), size 4→6, upward 12 st/s, a teardrop shape, LightEmission 1. SSJ2 adds lightning Beams (2 per second, 0.08 s).
- **God aura (God/Blue/Rosé):** a calmer flame plus inner sparkles (12/s, size 0.2), an outer glow shell (Highlight FillTransparency 0.85).
- **UI/MUI:** a thin silver shimmer and a 0.4 st heat-haze. **Motion:** 0.15 s afterimage trail on every dodge. Ambient sound drops 6 dB (calm).
- **Ultra Ego:** a violet heavy flame with a "smoke" layer (dark rim particles) whose height grows +5% per 10% HP lost (ties to the Modifiers.lua Ultra Ego scaling).
- **Beast:** a white-violet spiky crown aura, fast flicker (12 Hz) with electric violet sparks.
- **Black Frieza:** no flame. Lightning arcs (#FF4DD2) plus a dark distortion ring every 1.5 s.
- **Budget:** ≤ 80 live particles per aura at Medium quality. In ToP with 20+ players, other players' auras drop to 25% rate and lose sparks. `AuraRenderer.client.lua` reads `Config.VFX.AURA_PALETTE` (new) instead of hard-coded values.

### 2.3 Beams
Core cylinder Neon at core hex, rim Beam (texture: a soft gradient) at rim hex, Transparency 0.25. Head = Neon sphere 1.4x the core radius. Width: light 1.5 st, signature 3 st, ultimate 6 st. The beam pulses ±6% width at 15 Hz. Ground scorch: decal #1A1208 alpha 0.6, fades over 8 s. The hit point gets a bloom flash and debris.

### 2.4 Lighting presets (owner: db-map `TrainingLightingPresets`, read by `TrainingLighting.client.lua`)
| Preset | Ambient | OutdoorAmbient | ClockTime | Brightness | ColorCorrection (tint/sat/contrast) | Bloom (int/size) | Atmosphere (density/color/haze) | Notes |
|---|---|---|---|---|---|---|---|---|
| Lobby | #8A8FA8 | #9AA3C0 | 14 | 2.2 | #FFFFFF/0.05/0.05 | 0.6/24 | 0.30/#C7D7FF/1 | bright and friendly |
| Hub | #7F8AA0 | #8FA0BF | 15 | 2.0 | #F4F8FF/0.05/0.05 | 0.6/24 | 0.30/#D0E0FF/1 | |
| CapsuleCorp | #B5C4D6 | #C8D6E6 | 12 | 2.4 | #FFFFFF/0.10/0.00 | 0.4/20 | 0.20/#E8F2FF/0 | clean whites with CC blue #1E6FD9 accents |
| HTC (Time Chamber) | #FFFFFF | #F2F2F2 | 12 | 3.0 | #FFFDF5/-0.30/0.15 | 1.2/40 | 0.55/#FFFFFF/2.5 | near-white void; a 6 s "breathing" brightness 2.8↔3.2 |
| GravityRoom | #3A1414 | #551C1C | 0 | 1.2 | #FF9C9C/-0.05/0.20 | 0.8/30 | 0.35/#8A2B2B/1 | red emergency light, intensity scales with G (Contrast +0.001×G) |
| KingKai | #9CC46A | #B0D67A | 13 | 2.4 | #FFF8E0/0.15/0.05 | 0.5/24 | 0.40/#FFE3A3/1.5 | small yellow-green planet, warm |
| WhisBeerus | #6E5A8C | #8B79B0 | 17.5 | 1.8 | #EBDDFF/0.10/0.10 | 0.7/30 | 0.35/#B9A2E8/1.5 | dusk purple, floating rock islands |
| ToP_Arena | #6F7FA6 | #8090C0 | 14 | 2.2 | #E6EEFF/0.10/0.12 | 0.9/32 | 0.25/#9FB3FF/1 | the World of Void: starfield skybox, crystalline pillars #B8C7FF |
| ToP_LastStand | — | — | — | — | #FFD0D0/0.0/0.20 | 1.1/40 | — | blend 2 s when ≤ 2 universes remain |
| BrolyCrater | #4A3A2A | #6A4F33 | 18.5 | 1.6 | #FFD6A8/-0.10/0.20 | 0.9/34 | 0.50/#C27B3E/2 | (db-map has this) green flash on Broly roars |
| MoroNamek | #3F5A4A | #5A7D66 | 16 | 1.5 | #D8FFE6/-0.20/0.15 | 0.7/28 | 0.45/#6FA588/2 | (db-map has this) drains toward grey during Planet Drain |
| Story_Saiyan | #9E8A6A | #BFA57A | 16 | 2.0 | #FFF0D6/0.05/0.05 | 0.5/24 | 0.30/#E6CFA0/1 | wasteland |
| Story_Namek | #6FA0A0 | #8FC8B8 | 13 | 2.2 | #E0FFF2/0.10/0.05 | 0.6/24 | 0.30/#9FE0C8/1 | three suns, green-blue sky |
| Story_CellGames | #9AA0A8 | #B8C0C8 | 15 | 2.2 | #FFFFFF/0.0/0.10 | 0.6/24 | 0.25/#CFD8E0/1 | |
| Story_Buu | #A08AA0 | #C0A8C0 | 16 | 2.0 | #FFE6F6/0.05/0.08 | 0.7/24 | 0.35/#E8C3E0/1 | |
| Story_Super | #7F8AC0 | #A0B0E0 | 14 | 2.2 | #F0F4FF/0.10/0.10 | 0.8/28 | 0.25/#B0C0FF/1 | |
| Story_Daima | #7A5A9A | #9A7AC0 | 18 | 1.8 | #F6E6FF/0.15/0.10 | 0.8/30 | 0.40/#C9A6FF/1.5 | demon realm |
Transform overrides: on a transform burst, tween the ColorCorrection tint to the form's aura core at 30% for 0.5 s, then back over 1 s.

### 2.5 UI colours and type
- **Palette:** Ink #0B0F1A · Panel #141B2D at 0.15 transparency · Stroke #2B3A5C · Primary (DB orange) #FF8A00 · Secondary (Capsule blue) #1E6FD9 · Gold #FFC93C · Ki bar #3FB6FF→#BDEBFF gradient · HP #3DDC84→#FFD23F→#FF3B30 (by %) · Danger #FF3B30 · Success #3DDC84 · Rare #A64DFF · Text #F5F7FF / #9AA6C4.
- **Type:** headers and damage numbers **Fredoka One** (or `Enum.Font.FredokaOne`) with a 2 px black stroke. Body **Gotham SSm** (Enum.Font.GothamMedium/Bold). Numbers in combos: FredokaOne, size 48–96 scaled by tier. Announcer banners: **Bangers**, or LuckiestGuy as the fallback.
- **Motion:** buttons scale to 1.05 on hover, 0.95 on press, TweenInfo 0.08 s Quad. Panels slide 24 px plus fade over 0.18 s. Respect `UIStyle.lua` (db-gameplay) as the single source, adding these tokens there.

---
## 3. VOICES & AUDIO

### 3.1 Legal and pipeline rules
- **No show, game, or dub audio. No sound-alikes impersonating a specific real voice actor.** Characters get *original* performances in the archetype only.
- Upload rules: rights owned · single track mp3/ogg/wav/flac · <20 MB · <7 min · ≤48 kHz · mono/stereo (https://create.roblox.com/docs/audio/assets). Audio assets are Restricted, so grant the experience permission (inserting the asset in Studio does this) and upload under the same owner as the place (user or group).
- **AI voices:** only from services whose license allows commercial use in games, with **stock or consented voices (no cloning of real people)**. Keep the license PDFs in `team/audio/LICENSES/`. Disclose in the credits ("Additional voices generated with X").
- **Human VAs:** a work-for-hire contract with buyout for Roblox and promotion. Brief per character below. Record 48 kHz/24-bit, deliver at -16 LUFS-I with peaks at -1 dBTP; we downmix to mono ogg at 44.1/48 kHz.
- **Filename scheme:** `vo_<char>_<category>_<nn>.ogg`, `sfx_<move>_<layer>_<nn>.ogg`, `mus_<mode>_<state>.ogg`. The ID registry lives in `Config.AUDIO` (new table) → `AudioRegistry.lua`.

### 3.2 Voice briefs (original characters-in-spirit; English + optional Japanese-style "ganbare" energy)
| Char | Age / tone | Brief | Must-record set |
|---|---|---|---|
| Goku-type | Adult male, light baritone, cheerful and boyish; serious drop in fights | "Happy-go-lucky fighter who loves a strong opponent" | 6 attack kiai (short "Ha!", "Hyah!", "Dah!") · 4 grunts hurt-light · 3 hurt-heavy · 2 KO · 3 charge screams (2/4/8 s) · 1 transformation scream (12 s, layered) · beam call original names: "Ka… me… ha… me… HA!" **is a show line, so avoid it**. Use the in-game name "Turtle Wave" call or a wordless charge-roar → *the user decides* (see §3.6) · 6 taunts · 4 victory · 3 defeat |
| Vegeta-type | Adult male, sharp tenor-baritone, arrogant | "A proud prince who never admits he's tired" | the same set + 6 prideful barks ("Is that all?", "Pathetic.") |
| Frieza-type | Androgynous, smooth, polite menace; rises to a shriek | "Soft-spoken emperor, polite until angry" | the same set; laughs ×4 (polite chuckle → maniacal) |
| Jiren-type | Deep bass, minimal words, slow | "Silent warrior, every word heavy" | grunts only (low "Hm."), 3 lines max per match, a power-up roar |
| Broly-type | Gravelly bass, feral | "Gentle giant turned berserker" | roars ×8 (short/long), heavy breathing loop, 2 quiet lines |
| Gohan-type | Young adult male, earnest tenor; cold fury in Beast | "Scholar who becomes terrifying when protecting family" | the same set + a calm-to-rage transform scream |
| Grand Priest (announcer) | Calm, cheerful, high-pitched elder | "Polite referee of the gods" | universe eliminated ×8 (one per universe: "Universe 3 has been eliminated."), countdowns, rule reminders, "Begin." / "That's the match." |
| Zeno (reactions) | Childlike, cute, short | "Innocent omnipotent kid" | ×10 reactions: "Ooh!", "Amazing!", "Bye-bye~" (on erase), giggles |
| Bulma (cheer, lobby, shop) | Adult female, bright | "Genius engineer, sassy" | shop greetings ×6, cheers ×6 |
| Whis / Beerus (training) | Whis: soft, amused; Beerus: grumpy, sleepy | — | drill callouts ×20 each |
Scream construction (when budget allows): base scream VO + a −12 dB sub-rumble + an aura "whoosh" swell, sidechained (ducked) under the voice.

### 3.3 SFX lists per move (layers: transient / body / tail)
- **M1:** Swing_Light (air whip ×4 var), Swing_Med, Whoosh_Spin; Hit_Light (meat-slap + glove pop), Hit_Med (+low thump), Hit_Heavy (+ sub boom 50 Hz + debris tail), Crit (glass crack + reverse cymbal).
- **Movement:** Dash_Burst (ki whoosh + air pressure), Dash_Skid (dirt scrape), Vanish_Zip (high "tsch"), Vanish_Appear, Flight_Loop (wind bed, pitch by speed), Sonic_Boom, Land_Light/Heavy.
- **Guard:** Block_Impact (dull thud + ki fizz), PerfectGuard (bell ping + time-slow whoosh), GuardBreak (glass shatter + bass drop).
- **Ki:** Ki_Charge_Loop (rumble + crackle, 3 intensity layers), Aura_Up (whoosh swell), Ki_Blast_Fire (pew-thump), Ki_Blast_Hit (pop + fizz).
- **Beams:** Beam_Charge (rising tonal hum per character, Goku blue ~ 220→440 Hz sweep), Beam_Fire (white-noise blast + tonal core), Beam_Loop, Beam_Hit_Loop, Beam_End (tail), BeamStruggle_Loop (two hums detuned + crackle), BeamStruggle_Win (explosion).
- **Transform:** Rock_Rise, Ground_Crack, Transform_Build (riser 1.6 s), Transform_Burst (boom + shimmer), plus form tags: SSJ (electric), Blue (glassy chime), UI (silence then a heartbeat), UltraEgo (deep growl), Beast (screech + crystal), Black (distortion).
- **Specials:** Hakai_Charge (deep inhale tone), Hakai_Erase (crumble + reverse wind), SpiritBomb_Gather (choir pad, original), Kaioken_Toggle ("whoomp" + heartbeat), SolarFlare (bright flash pop + ringing), Barrier (glass hum).
- **World:** Wall_Impact, Crater, Debris_Fall, RingChunk_Break, Ring_Out (wind-out + bell), Universe_Erased (sub-bass suck, silence 0.5 s, sparkle), Zeno_Giggle.
- Sources: record originals, Roblox Creator Store sounds (licensed for Roblox use), or royalty-free libraries with game licensing (keep receipts). Run 4–6 variations per frequent SFX with ±8% pitch randomization.

### 3.4 Music per mode (original compositions; brief to a composer or a licensed AI music tool)
| Mode | Style | BPM | Stems |
|---|---|---|---|
| Lobby/Hub | Upbeat J-rock lite, guitars, brass stabs | 128 | base / +drums / +lead |
| Capsule Corp shop | Funky lounge, slap bass | 105 | 1 loop |
| Training (per camp) | HTC: ambient pad + ticking clock · Gravity Room: industrial pulse that speeds up with G · King Kai: cartoon bouncy marimba · Whis/Beerus: calm koto/flute + low strings | var | 2 layers |
| ToP | Epic orchestral + rock drums, 3 intensity layers | 150 | L1 (opening), L2 (≤ 50% players), L3 (last 2 universes) + a 48:00 clock tick motif |
| Ranked | Darker hybrid trap/orchestral | 140 | 2 layers |
| Raids | Broly: heavy metal choir (original) · Moro: eerie synth + choir | 160 / 120 | phase stems 1–3 |
| Story | Arc themes (Saiyan, Namek, Androids/Cell, Buu, Super, Daima) as 60–90 s loops + a stinger set | var | |
| Stingers | victory 6 s, defeat 5 s, level-up 2 s, rank-up 3 s, Shenron summon 8 s | | |

### 3.5 Mixing and ducking
SoundGroups: Master → Music (-14 LUFS target, vol 0.5) · SFX (0.8) · Voice (1.0) · Announcer (1.0) · UI (0.6) · Ambience (0.4).
- Announcer (Grand Priest/Zeno) ducks Music by -9 dB and SFX by -4 dB (attack 50 ms, release 400 ms; CompressorSoundEffect sidechain or a scripted tween).
- Own-character VO ducks own-SFX by -3 dB. Other players' VO is capped at 6 concurrent voices; nearest wins (RollOffMaxDistance 120).
- Transformation and Ultimate: Music -6 dB for the duration, then a stinger.
- Hitstop: pitch-down the global SFX bus by 3% during freeze (subtle "weight").
- The concurrent SFX cap is 48; drop the farthest. In ToP, distance roll-off for others: Linear, 10→200 studs.
- Settings sliders for each group. Mobile default Music 0.4.

### 3.6 Open decision for anwar
Signature attack *names* such as "Kamehameha" are trademarks and lines from the show. Recommended: original call-outs ("Turtle Wave!", "Galaxy Gun!") or wordless kiai so audio stays original. The on-screen names can stay as in the GDD. This is the user's call, and it's flagged in §6 WP-AUD-1.

---
## 4. STORY POLISH (32 missions, StoryMissions.lua by db-story)

### 4.1 Cutscene language (CutsceneDirector.lua)
- **Shot grammar:** establishing wide (2 s) → two-shot (dialogue) → close-ups on emotional beats → a "manga panel" freeze (screen split into 2–3 tilted panels, a speed-line BG, 1.2 s) for the big moments.
- **Dialogue:** 2 lines max per beat. Text boxes in the bottom third, the speaker portrait left/right, a 30 cps typewriter with a voice blip per 3 chars. Skippable after 0.5 s (hold Space 0.6 s for the whole cutscene). Total pre-mission ≤ 20 s, post ≤ 10 s.
- **Transitions:** white flash for power, a black dip for time skips (TimeSkipVFX exists), a horizontal "wipe" in the form colour for transformations.
- **Letterbox** 2.35:1 during cutscenes; HUD hidden.

### 4.2 Mission pacing template (5–8 min)
0:00 intro cutscene (≤ 20 s) → 0:20 warm-up fight (minions, teaches the arc mechanic) → 2:00 mid-beat (a twist cutscene ≤ 8 s) → 2:10 boss phase 1 → boss 50% HP "manga panel" + phase 2 (new telegraphs) → final 15% = a scripted signature moment (beam struggle, sacrifice, transform) with a QTE → victory cutscene ≤ 10 s → reward screen.
Fail: a checkpoint at boss phase 2. The retry restarts there in ≤ 3 s.

### 4.3 Rewards curve
Mission n (1–32): XP = round(300 + 2500·((n-1)/31)^1.3) → 300…2800 (matches db-story's range). Zeni = 200 + 40n. Stars per mission: clear / no-KO / time or style S. Each star +25% XP. Every 3 stars → a cosmetic. Arc completion: a title + an aura colour swatch. Form unlocks keep db-story's order. **No stat rewards** (respects the cap).

### 4.4 Boss telegraph language (all bosses)
- **Colour code:** red ground decal = AoE, it will hit · yellow line = beam path · purple swirl = grab/unblockable (Hakai-type) · white flash on the body = "vanish incoming".
- **Timing:** windup ≥ 0.6 s (normal), ≥ 1.0 s (unblockable), ≥ 1.5 s (ultimate). An audio cue at telegraph start. The eye-glint VFX 0.2 s before release.
- **Per arc:**
| Arc | Boss | Telegraphs |
|---|---|---|
| Saiyan | Nappa, Vegeta (Oozaru) | Nappa: raises 2 fingers (yellow cone) → ground eruption; Oozaru: mouth glow 1.2 s → mouth beam (yellow line), stomp (red circle 12 st) |
| Namek | Ginyu Force, Frieza | Ginyu pose = a 1.5 s body-swap grab (purple); Frieza: finger glow → DeathBeam (a thin yellow line, 0.6 s), raise arm → Death Ball (giant red circle, 2.5 s) |
| Androids/Cell | 19/20, Cell, Cell Jr. | 20: palm glow = an absorb grab (purple); Cell: "Kame" crouch → beam struggle QTE; self-destruct inflate 5 s countdown → escape zone |
| Buu | Majin Buu, Super Buu, Kid Buu | Antenna sway → candy beam (yellow); Kid Buu: ball overhead (red 30 st, 3 s) |
| Super (Beerus/Golden F./Hit/Zamasu) | — | Beerus: finger tap → Hakai (purple, unblockable, must vanish); Hit: time-skip = a 0.3 s screen grey → hit from behind (dodge forward); Zamasu: halo flare → blade rain (red stripes) |
| ToP | Jiren | Arms unfold (any motion = danger) → Power Impact (red cone 1.0 s); glare → stun cone |
| Moro / Granolah | Moro, Gas | Moro: planet drain = a slowly shrinking safe ring; copy = mimics your last special (shows your move's icon) |
| Super Hero | Cell Max | Giant: a shadow shrinking under the player for stomps; a mouth beam sweep (yellow arc) |
| Broly | Broly | Roar (camera shake + stun if within 10 st, a 1.0 s red ring); grab (purple, 1.0 s); green Eraser Cannon ball (red circle) |
| Daima | Demon king | A purple rune circle → magic pillar (1.2 s) |

---
## 5. TRAINING POLISH (owner of runtime: TrainingRooms.lua by db-gameplay; map: db-map)

### 5.1 Gravity Room (1–500G)
- **Strain animation:** a `GravityStrain` layer (Weight = clamp((G-1)/150,0,1)), additive. Waist pitch +12°, knees bent 15°, head down 8°, a ±1° tremble at 8 Hz. Walk speed × (1 - 0.6·w). Jump height × (1-0.8·w).
- **Visuals:** a red vignette alpha = 0.15 + 0.35w. Floor dust pushed downward. Heat-haze above 200G. Character sweat particles (0.5/s) after 60 s at > 100G.
- **Audio:** machine hum pitch = 0.8 + G/600. Heartbeat layer > 300G.
- **Bots:** TrainingBots scaling as implemented. Add a "spar rank" display (E→S) over the bot's head.
- **Juice:** every +50G a console chime and a "GRAVITY 250x" stamp on screen.

### 5.2 Hyperbolic Time Chamber
- **Time dilation visual:** a HUD clock that runs 365x (a day counter "Day 37"). The world's ambient particles move at 0.25x speed while the player is 1x. Each player's afterimage trail is lengthened. An endless white ground with heat shimmer.
- **Breathing light** (§2.4). Air-thin effect: stamina regen -20%, shown by a faint blue frost on the HUD edges.
- **Exit:** the door spins, a white flash, a "1 year of training" stamp, an XP tally (count-up 1.2 s).

### 5.3 King Kai's Planet
- **10G** strain (fixed w=0.06 → slight lean). Tiny planet curvature: a camera tilt follows the surface normal.
- **Bubbles chase:** Bubbles (monkey NPC) runs a randomized path at 14–22 st/s, stopping and dodging. Catch = touch within 30 s (5 rounds, speed +10% per round). Animations: `Bubbles_Run`, `Bubbles_Dodge`, `Bubbles_Taunt` (arm-wave). Player: `Chase_Grab` (both arms forward, 0.3 s). Reward: XP + a "Monkey Business" title at 5/5.
- **Gregory hammer:** Gregory (cricket NPC) flies an erratic path (Perlin noise, 3D, ±6 st). The player swings a hammer (`Gregory_Swing`: 18 f wind, f19 contact, 12 f recovery). Hit = 1 bonk (comic "BONK" text, a cartoon star VFX). 10 bonks in 60 s.
- **Feel:** cartoon SFX set (slide whistle, bonk), bouncy marimba music, a car around the house as decor.

### 5.4 Whis dodge drills
- Whis stands calmly, the staff tapping. Drill: a 30 s sequence of staff jabs with a **0.5 s → 0.25 s** telegraph (white staff glint). The player must dodge left/right/duck/jump (the matching direction is shown by the jab angle). Each correct dodge = 1 point. 3 misses = fail.
- **10 stages** (UI Sign rule: Lv70 + all 10 stages per db-gameplay). Stages 8–10 add feints (a glint without a jab) and the UI "auto-dodge" preview: a successful perfect dodge slows time 0.5x for 0.3 s with a silver afterimage (teaching the UI feel).
- Whis lines: "Too slow~", "Don't think, move." Animations `Whis_Jab_L/R/Low/High`, player `Dodge_L/R/Duck/Jump` (8 f each, i-frames f1–6).

### 5.5 Beerus trials (BeerusCamp.lua: Sparring → Sphere → Hakai → God Aura → Ultra Ego Lv85)
- **Sparring:** Beerus fights at 30% speed with 1 attack per 1.5 s. The player must land 10 hits. Beerus yawns between waves (`Beerus_Yawn` idle).
- **Destruction Sphere:** charge a sphere (hold) while Beerus throws small spheres; keep the charge > 50% for 20 s. The sphere colour shifts #9D4EDD→#5B2A86 as it grows.
- **Hakai trial:** targets (rocks → cliffs) shimmer purple. The player must hold the Hakai input for 1.2 s *without being hit*. Success = the target erodes into particles upward (Hakai_Erase VFX: 1.5 s dissolve, purple embers). Failure (hit while channeling) = a "backlash" stagger.
- **God Aura:** meditate (`Meditate` clip, cross-legged float) through 3 rounds of distraction (Beerus throws pudding cups; touching one resets). A calm ambient bed, with the aura swirling into the God aura #A97CFF.
- **Ultra Ego (Vegeta-types, Lv85):** survive while taking damage. The Ultra Ego aura grows with HP lost (scaling ties to Modifiers.lua). The trial ends at 10% HP with a "destroyer's instinct" stamp.

---
## 6. WORK PACKAGES (Antigravity = AG, OpenCode = OC)

**Ownership rules (from the PC's team\AI_RULES.md and CHANGES.md):** AG and OC edit only the files named in their package (it counts as their TASK file), and new modules go in new files. `team/map` belongs to the map worker, `team/animation` to the animation worker, and `team/src`, `team/gameplay` and install.py to the Studio executor/db-gameplay. Edits to another owner's file need a note in `team/HANDOFF` plus lead sign-off, logged in CHANGES.md. Use `--!strict` on new modules, run `tools\lint.ps1` (selene and stylua), do a Studio Play test, and write a handoff note. Edit originals in `team/`, never in `vault\team` (run tools\sync-vault.ps1). Assets must be CC0, CC-BY, CC-BY-SA or Free Standard only. Never publish, buy or delete without anwar's OK. AG and OC must never edit the same file in the same wave.

| WP | Agent | Scope | Files (touch only these) | Acceptance tests |
|---|---|---|---|---|
| **WP-ANIM-1** 6-hit M1 + enders | AG | Add M1_5, M1_6 and 4 ender branches to Shared/Goku/Vegeta/Frieza, per §1.5 | `team/animation/poses/gen_poses.py` (generator), regenerated `poses/{Shared,Goku,Vegeta,Frieza}.lua` | `luau check_poses.luau` passes. Every clip has all 15 joints per key. Contact keys carry `hit` markers with the §1.2 tier. M1_6 length = 34 f. Studio: 6 hits chain with hold-M1 in < 2.6 s |
| **WP-ANIM-2** Marker vocab + Freeze | OC | Add the `cancel/move/cam/shake/fov/iframe/armor` markers, `h:Freeze(ms)`, the stepped flag, priority mapping | `team/animation/poses/PosePlayer.lua`, new `team/animation/AnimMarkerRouter.lua`, `team/animation/poses/check_poses.luau` (validator only) | A unit test (plain Luau mock) shows that Freeze(110) holds Time ±1 frame. Unknown marker keys produce a warning, not an error. The priority string maps to the Enum |
| **WP-ANIM-3** Movement and defense clips | AG | Vanish_Out/In/Counter, GuardHit/GuardBreak, TechRoll, WakeUp, Knockback_Air, WallBounce_Victim, GroundBounce_Victim, Fly* set, PowerUp_Stage1-3, Taunt, Victory/Defeat | `gen_poses.py` (a **new section after WP-ANIM-1 is merged**, sequential, not parallel), `poses/Shared.lua` | check_poses passes. Vanish i-frame markers on f0–9. Clip lengths as in §1.5 |
| **WP-ANIM-4** New characters | OC | Jiren, Broly, Gohan pose files + signature clips (§1.6) | new `team/animation/poses/gen_poses_ext.py`, new `poses/{Jiren,Broly,Gohan}.lua` | check_poses passes. Each has Idle, M1_1–6, Dash, Guard, 3 specials, a transform, an ultimate, hurt and KO |
| **WP-ANIM-5** Beam struggle clips + VFX | AG | BeamStruggle_Push/Win/Lose, the collision orb | `team/animation/BeamStruggleVFX.lua` (existing animation-owned file; log it in CHANGES.md), `gen_poses_ext.py` **after WP-ANIM-4** | The collision orb appears ≤ 4 st from the heads. The push bar visual follows a mock push value -1..1 |
| **WP-FEEL-1** Hitstop/shake/FOV tables | OC | The §1.2 table as data + camera choreography presets | new `gameplay/src/ReplicatedStorage/Shared/FeelTables.lua`, new `gameplay/tests/feel_tables_test.lua` | Tests: tiers are monotonic (ms, shake, FOV); the Ranked cap is applied; the multi-target 50% rule works |
| **WP-FEEL-2** Combat wiring (needs a db-gameplay sign-off) | AG | Input buffer 200 ms, cancel windows, string reset 1.2 s, ender branches, perfect-guard crit | `gameplay/src/StarterPlayer/StarterPlayerScripts/CombatInput.client.lua`, `GameFeel.client.lua` (**owner sign-off + CHANGES.md**). The server side is a request to db-gameplay (Combat.lua), not edited by AG | Studio: a buffered press 150 ms early chains. A 6-hit string in a dummy test. A perfect guard within 8 f triggers a Crit. The 25+ existing tests still pass (`sh gameplay/tests/run.sh`) |
| **WP-HOOK-1** Combo counter + style rank + KO cam | OC | §1.7 HUD and KO cam | new `StarterPlayerScripts/ComboHUD.client.lua`, new `StarterPlayerScripts/KOCam.client.lua`, new `Shared/StyleRank.lua` + test | Tests: style points with variety decay; rank thresholds. Studio: counter colours at 5/10/15/20, KO slow-mo 0.3x ≤ 400 ms |
| **WP-HOOK-2** Replays + post-match loop | AG | Event recorder (10 Hz, 30 s ring) + best-moment replay + Rematch focus | new `ServerScriptService/Modules/ReplayRecorder.lua`, new `StarterPlayerScripts/ReplayViewer.client.lua`; the EndingUI hook is a **request** to the EndingUI owner | Memory ≤ 2 MB per 40 players. The best moment = the max damage window in tests |
| **WP-VFX-1** Form palette + auras | OC | §2.1/2.2 as data + an AuraRenderer read | new `Shared/FormPalette.lua` + test; `AuraRenderer.client.lua` (**owner sign-off**) | Every form in Modifiers/forms has a palette entry (the test enumerates them). Particle budget ≤ 80 at Medium. ToP LOD at 20+ players |
| **WP-VFX-2** Lighting presets | AG | Add the §2.4 presets for Story_*, ToP_Arena, ToP_LastStand, Lobby, Hub, CapsuleCorp | **Request to db-map**: `team/map/training/TrainingLightingPresets.lua`. AG writes a proposed diff file `team/proposals/lighting_presets_patch.lua` only | db-map merges. TrainingLighting reads all keys without error |
| **WP-UI-1** UI tokens + fonts | OC | §2.5 tokens | `Shared/UIStyle.lua` (**db-gameplay sign-off + CHANGES.md**) | Contrast ≥ 4.5:1 for the text tokens (a test computes it). Existing UIs render unchanged |
| **WP-AUD-1** Audio registry + mixer | AG | SoundGroups, ducking, variation picker, ID registry with placeholders (0) | new `Shared/AudioRegistry.lua`, new `StarterPlayerScripts/AudioMixer.client.lua`, new `team/audio/VO_BRIEFS.md` (§3.2), `team/audio/LICENSES/README.md` | Tests: ducking math; the variation picker never repeats twice in a row; a missing ID logs once, no error. Hard rule: no asset whose license isn't in LICENSES/ |
| **WP-STORY-1** Cutscene grammar | OC | Manga-panel freeze, letterbox, typewriter, skip | `Shared/CutsceneDirector.lua` (**owner sign-off**), new `StarterPlayerScripts/MangaPanel.client.lua` | A cutscene skips after 0.5 s hold. Pre-mission ≤ 20 s in all 32 missions (a static check on the dialogue lengths) |
| **WP-STORY-2** Boss telegraphs | AG | Telegraph decal/line/swirl module + per-boss data from §4.4 | new `Shared/Telegraphs.lua`, new `ServerScriptService/Modules/TelegraphService.lua`; the BossNPC call is a **request** to db-gameplay | Tests: windup ≥ 0.6/1.0/1.5 s by type. Studio: Jiren Power Impact shows a red cone 1.0 s before |
| **WP-TRAIN-1** Gravity strain + HTC visuals | OC | §5.1, §5.2 client visuals | new `StarterPlayerScripts/TrainingFeel.client.lua` | Strain weight = clamp((G-1)/150). The HTC day counter runs 365x. No server edits |
| **WP-TRAIN-2** King Kai minigames | AG | Bubbles chase + Gregory hammer | new `ServerScriptService/Modules/KingKaiGames.lua`, new `StarterPlayerScripts/KingKaiGamesUI.client.lua`, new test; the TrainingRooms registration is a **request** to db-gameplay | Tests: Bubbles speed +10%/round; 10 bonks in 60 s gives success; the reward is XP plus a title only |
| **WP-TRAIN-3** Whis drills + Beerus trial feel | OC | §5.4/5.5 visuals and clips | new `StarterPlayerScripts/WhisBeerusFeel.client.lua`, clips in `gen_poses_ext.py` **after WP-ANIM-5** | Telegraph 0.5→0.25 s across stages. Feints in stages 8–10. The perfect-dodge slow-mo is 0.3 s |

**Sequencing:** wave 1 in parallel: ANIM-1 (AG) ∥ ANIM-2 (OC) ∥ FEEL-1 (OC, after ANIM-2) ∥ AUD-1 (AG after ANIM-1). Wave 2: ANIM-3 (AG) ∥ ANIM-4 (OC) ∥ HOOK-1 (OC) ∥ VFX-1. Wave 3: FEEL-2, ANIM-5, HOOK-2, STORY-1/2. Wave 4: TRAIN-1..3, UI-1, VFX-2.
**Definition of done (all WPs):** compiles (`luau-compile`/selene) · `sh gameplay/tests/run.sh` green · a CHANGES.md entry for any owned-file edit · no new ripped assets · DEV_MODE untouched · a short note in `team/vault` (Obsidian) linking the WP.

**Decisions anwar must make:** (1) original call-out names vs. show attack names in voice (§3.6) · (2) AI voices vs. human VAs (budget) · (3) cinematic camera cuts default ON for PC? (recommend ON, OFF on mobile).
