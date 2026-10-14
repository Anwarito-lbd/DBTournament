# Dragon Block Z — Animation / VFX (v5)
Game: **Dragon Block Z**. Client-side ModuleScripts, built-in Instances only (optional sound/texture ids via config). All compile with `luau-compile`.

| File | What |
|---|---|
| `VFXCommon.lua` | Shared helpers + ArenaDamage hook + **v5 primitives**: `ImpactFrame`, `Hitstop`/`HitstopHook`, spring `CameraShake` + `FOVPunch` (`shake` aliased), `SpeedLines`, `Shockwave`, `GroundCrack`, `DebrisBurst`, `Afterimage`, `AuraEmitter(formId)`, `BeamCore`, `Impact(tier)`, quality budget `SetQuality(1..3)` |
| `VFX_QUALITY_BAR.md` | Quality bar: frame timings, hitstop tiers, impact frames, shake/FOV curves, particle settings, aura hexes, beam layers, per-move specs for Goku/Vegeta/Frieza, perf budget; benchmark vs TSB/JJS |
| `KamehamehaVFX.lua` | Goku Kamehameha (standalone) |
| `FinalFlashVFX.lua` | Vegeta Final Flash |
| `SpecialBeamCannonVFX.lua` | Piccolo SBC (piercing spiral) |
| `DeathBallVFX.lua` | Frieza Death Ball |
| `PowerImpactVFX.lua` | Jiren Power Impact (red preset over DeathBallVFX) |
| `TimeSkipVFX.lua` | Hit Time Skip |
| `TransformationVFX.lua` | Transformations: `Play` one-shot / `Start` + `handle:Stop(bool)` hold-to-charge; power-level readout; presets incl. Config.FORMS ids via `FORM_ID_MAP` / `ResolveFormId(formId, charId)` |
| `FusionVFX.lua` | `Dance(a, b, cfg)` 3-pose Fusion Dance + fingertip beam; `Potara(a, b, cfg)`; hooks `OnPose(step, a, b)`, `OnFused(a, b, cframe) -> Model?` |
| `TeamComboVFX.lua` | `MergedBeam(chars, target)`, `SyncRush(chars, target)`, `EnergyGift(giver, receiver)` (Last Energy Gift, `OnGiftComplete`) |
| `BeamStruggleVFX.lua` | `Start(a, b)` → `:SetProgress(-1..1)`, `:Push(side, amt)`, `:End("A"/"B"/nil)` |
| `Android17BarrierVFX.lua` | `Start(char)` → `:Hit(pos)`, `:Shatter()`, `:Stop()` (green hex-panel dome) |
| `InstantTransmissionVFX.lua` | Goku/Moro IT: finger glow, 3× flicker, blur streak, `Vanish`/`Appear`/`Play` |
| `SpiritBombVFX.lua` | Spirit Bomb (DeathBall-based + inward motes, `U7Tint`) |
| `MUIRushVFX.lua` | MUI silver afterimage rush + palm burst |
| `GalickGunVFX.lua` | Purple Kamehameha variant |
| `BigBangAttackVFX.lua` | Fast blue-white sphere + big explosion |
| `FinalExplosionVFX.lua` | Self-KO gold swell, body cracks, 60-stud white sphere, smoke; `OnDetonate` |
| `DeathBeamVFX.lua` | Needle beam; `Rapid(char, target, n)` |
| `DestructoDiscVFX.lua` | Homing saw disc, slash on hit, `Split` 1–3 |
| `NovaStrikeVFX.lua` | Energy-sphere rush + trail + explosion; `NovaStrikeVFX.BLACK` preset |
| `BlackFriezaVFX.lua` | Black Frieza signature "Black Nova" (Nova + delayed void burst) |
| `BeastSBCVFX.lua` | Beast Gohan red Special Beam Cannon |
| `MoroAbsorbVFX.lua` | Moro absorb touch: tendrils, victim drain, `Start`/`Stop`/`Play` |
| `MoroPlanetDrainVFX.lua` | Moro AoE drain: rune ring, darkening ground, rising motes, pulses (`OnPulse`) |
| `hero_goku.md` / `hero_vegeta.md` / `hero_frieza.md` | Hero art/anim docs (module references updated) |
| `KamehamehaTest.client.lua` | Test LocalScript (key list in header) |
| `movesets.md` … `movesets_v4.md` | Specs (db-gameplay Config numbers win). v3: ID mapping + divine kits; v4: new forms, Beast Gohan, Black Frieza, playable divine tier incl. Zeno, Moro (`u7_moro`) |

## Studio setup
1. ReplicatedStorage → Folder `VFX`; one ModuleScript per `.lua` above (name without extension).
2. StarterPlayerScripts → LocalScript from `KamehamehaTest.client.lua`. Keys: K/F/P/B/J/T effects, hold G transform, H one-shot, Q cycle form, V barrier (again = hit, X shatter), N beam struggle with nearest dummy ([ ] push, Enter/Backspace end), Z fusion dance, Y potara, M merged beam, R sync rush, E energy gift. New in v5: F1/F2/F3 quality, F4 aura cycle, F5 impact-frame test. New in v4: 1 IT, 2 Spirit Bomb, 3 Galick, 4 Big Bang, 5 Final Explosion, 6 Death Beam rapid, 7 Destructo Disc, 8 Nova, 9 MUI Rush, 0 Black Nova, U Beast SBC, L Moro Absorb, O Planet Drain, C Ultra Ego growth. Put an R15 dummy in Workspace for the 2-character effects.

## Arena damage (confirmed with roblox / db-map)
- Module: **`ServerScriptService.ArenaDamage`** (`team/map/ArenaDamage.lua`), `DamageAt(pos: Vector3, radius: number, power: number): number` (radius clamped 1–60, rate-limited, **server-only**, asserts `IsServer`).
- **Clients always play VFX with `ArenaDamage = false`.** Default is also off on clients (`ArenaDamage = nil` → enabled only when `RunService:IsServer()`).
- db-gameplay's server calls `DamageAt` on validated hits. Suggested values used by the modules' server path: Kamehameha (18, 120), Final Flash (22, 150), SBC (6, 60), Death Ball (30, 180), merged beam (30, 200), beam-struggle (20, 140 / tie 25, 160).
- Config keys: `ArenaDamage`, `ArenaDamagePath` (default `{"ServerScriptService","ArenaDamage"}`), `ArenaRadius`, `ArenaPower`, `OnArenaDamage(pos, r, p)`.

Flow: client `RequestMove:FireServer` → server validates + damages + `ArenaDamage.DamageAt` → `PlayVFX:FireAllClients` → clients `.Play(..., {ArenaDamage = false})`.

## Forms (TransformationVFX)
Config `UltraInstinct` → `MUI`; `UltraInstinctSign`/`UISign` → `UISign`. Active ids: `SSBEvolved`, `UltraEgo`, `KeflaPotara`, `BeastGohan` (white hair/red eyes, red-white aura), `FriezaBlack`, `MoroAwakened`; Frieza `FullPower` → `FriezaFullPower` (purple). Ultra Ego growth: `TransformationVFX.UltraEgoGrowth(char, {OnDamageGrow})` → `:Damaged(amount, maxHp)`, `:Stop()`.

## IDs
Character/form IDs follow db-gameplay `Config.ROSTER` / `Config.FORMS`; see `movesets_v3.md` §1. Decided: Kefla `u6_kefla`, Moro `u7_moro`, divine `div_destroyer_<name>`, `div_angel_<name>`, `div_grand_priest`, `div_zeno` — pending Config additions in db-gameplay.

## v5 upgrade notes
- Upgraded to primitives: Kamehameha (optional VFXCommon; still standalone), Galick Gun (via Kamehameha), Final Flash, Big Bang / Spirit Bomb / Death Ball (via DeathBall + `explosion`→`Impact`), Final Explosion, Instant Transmission, MUI Rush, Death Beam, Destructo Disc, Nova Strike, Black Nova, Transformation (layered aura, `KeepAura`), Beam Struggle. Every module using `C.explosion` now gets impact frame + shockwave + cracks + debris + FOV automatically.
- APIs unchanged. `C.shake(intensity, duration)` still works (routes to spring shake).
- Limits: nothing has been run in Studio — only `luau-compile` syntax checks. Untested: Highlight-based inverted silhouettes, Glass heat-haze look, DebrisBurst physics/collision group, speed-line layout on varied resolutions, BindToRenderStep camera interplay with gameplay camera scripts, AdjustSpeed hitstop with gameplay animation controller. `MaxParticles` is advisory (rates scale by quality; not hard-counted).

## v1.2 — Keyframe pose data (`poses/`)
| File | What |
|---|---|
| `poses/gen_poses.py` | **Source of truth** generator (Python 3). Edit clip definitions here, run `python3 gen_poses.py` to regenerate the .lua files |
| `poses/Goku.lua` (28 clips) | M1_1–4, Heavy, Launcher, AirCombo, KiVolley, Guard, PerfectGuard, Dash, FlyIdle, HurtLight/Heavy, KO, Idle, Idle_UI, Kamehameha_Charge/Hold/Fire, SpiritBomb_Charge/Hold/Fire, InstantTransmission, MUIRush, Transform_SSJ/SSB/UI |
| `poses/Vegeta.lua` (28) | base set + Idle_PridefulCross, FinalFlash_*, GalickGun_*, BigBangAttack, FinalExplosion, Transform_SSJ/SSB/UltraEgo |
| `poses/Frieza.lua` (27) | base set (distinct upright poise, hand-on-hip, one-handed guard, arms-crossed hover) + DeathBeam_*, DeathBall_*, DestructoDisc, NovaStrike, BlackNova, Transform_Golden/Black |
| `poses/Shared.lua` | `JOINTS`, `JOINT_PART`, `PART_PARENT`, `TIMING`, and 16 neutral common clips (`Shared.clips`) for other R15 heroes |
| `poses/PosePlayer.lua` | `Play(character, clip, opts)` drives Motor6D.Transform with easing (Linear/Constant/Sine/CubicIn/CubicOut/QuadOut/BackOut), markers → `opts.OnMarker` or `opts.Registry["Module.Function"](char, arg, marker)`; `BuildKeyframeSequence(clip, name)` exports a KeyframeSequence with KeyframeMarkers |
| `poses/check_poses.luau` | Sanity check: `cd poses && luau check_poses.luau` (all 15 joints on every key, sorted unique frames, eases, lengths). Current: 99 clips, 521 keyframes, 0 errors |

Format: `clip = {fps = 60, length, looped, priority, keyframes = {{t, ease, markers, poses = {[joint] = {pos = {x,y,z}, rot = {rx,ry,rz}}}}}}`. Degrees, joint-local, `CFrame.Angles(X,Y,Z)`; `ease` = how the pose is reached. Markers: `hit = {tier,...}`, `vfx = "KamehamehaVFX.Play:fire;VFXCommon.ImpactFrame:white:1"`, `sound = "Hit_Light"`. Timings follow VFX_QUALITY_BAR §1 (anticipation 4–12f CubicIn, 1f smear with Afterimage marker, contact frame carries `hit`, Constant holds 4–12f, QuadOut recovery).
Studio: put `poses/` as a Folder `Poses` in ReplicatedStorage (ModuleScripts named Shared, PosePlayer, Goku, Vegeta, Frieza). Example: `PosePlayer.Play(char, require(Poses.Goku).Kamehameha_Charge, {Registry = {["KamehamehaVFX.Play"] = function(c, phase) ... end}})`.

**Limits (v1.2):** nothing has been viewed in Studio. Angles are hand-authored design values from the hero docs' signature poses — expect visual tuning (R15 joint axis conventions vary by rig; mirrored-left convention documented in the generator). No facial/finger/tail data (R15 has no finger joints; Frieza's tail chain from hero_frieza.md is not included). Procedural `Play` competes with the Animator for Motor6D.Transform — stop overlapping AnimationTracks or export via `BuildKeyframeSequence` and publish. KFS easing mapping is approximate (Sine→Cubic InOut, BackOut→Elastic Out).
