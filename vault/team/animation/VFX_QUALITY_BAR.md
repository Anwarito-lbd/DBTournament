# Dragon Block Z — VFX & Animation Quality Bar (v5)
Target: beat **The Strongest Battlegrounds (TSB)** and **Jujutsu Shenanigans (JJS)** on hit feel and DBZ spectacle.
All timings in frames @ **60 fps** (1f = 16.7 ms). All numbers are **design targets** to tune in Studio playtests. Implemented primitives live in `VFXCommon.lua` (names in `code`).

## 0. Benchmark (public gameplay + public reviews only; no decompiling)
| | TSB does well | JJS does well | Common gaps | Dragon Block Z rule |
|---|---|---|---|---|
| Hit contact | Weighty hitstop, ragdoll knockback, clean animation | Loud "crunch" audio, screen shake, particles on every hit | TSB: little VFX on plain M1s; JJS: hitboxes land before the visual contact | Damage frame == visual contact frame. Every hit has hitstop + sound + spark; heavies add shake/FOV |
| Crits | Black Flash: ~4f timing window, black distortion on impact | Same idea, bigger particles | — | Our "Ki Crit": 4f window, **inverted impact frame** (2f) + black-red sparks |
| Ultimates | Cutscene cameras | Domain blackout + scripted camera tweens; destruction | Long cutscenes stall gameplay | Cinematics ≤ 90f; player keeps camera except 20–40f punctuation |
| Destruction | Some | Debris that culls after a few seconds | Perf drops on laptops | `DebrisBurst` with hard caps + quality levels; debris fades at 2.5 s |
| Readability | Clean art | Cinematic, loud | Visual noise | Every move has a distinct anticipation pose ≥ 6f and a unique colour |
Sources: earnaldo.com TSB vs JJS (2026), mensy.studio JJS review, sabertoothgames TSB mechanics guide, bo3.gg JJS skill builder guide, r/JujutsuShenanigans discussion.

## 1. Anime keyframe timing (all character animations)
| Phase | Frames | Rule |
|---|---|---|
| Anticipation | M1 4–6f, heavy 8–12f, special 12–24f, ultimate 30–60f | Pull opposite to the strike (wind-up), squash 5% |
| Smear / strike | 1–2f | Limb "smear": spawn 1 `Afterimage` at 0.5 transparency over the strike limb arc; stretch 10–15% |
| Contact | 0f (exact) | Hitbox active **on** this frame; sound + spark same frame |
| Hold pose | M1 4f, finisher 8–12f, beam release 6f, transform 12f | Freeze on the strongest silhouette (impact pose) |
| Recovery | M1 8–10f, heavy 14–18f, ultimate 30f | Ease-out (Quad/Cubic), overshoot ≤ 5° |
Animation priorities: Core idle/walk · Movement run/fly · Action M1/block/dash · Action2 hitstun · Action3 transform · Action4 specials/ultimate.
Keyframe easing: anticipation EaseIn Cubic; strike Linear (2 keys); hold Constant; recovery EaseOut Quad.

## 2. Hitstop tiers (`C.Hitstop(chars, tier)`, `C.HITSTOP`)
| Tier | Frames | Used for |
|---|---|---|
| Light | 3 | M1 1–3, ki blasts, Death Beam |
| Medium | 5 | M1 4, Destructo Disc, dash strikes |
| Heavy | 8 | M1 finisher, Nova Strike, Big Bang hit |
| Finisher | 12 | Combo enders, MUI Rush last palm |
| Ultimate | 16 | Ultimates, beam-struggle win |
Attacker and victim both freeze (AnimationTracks speed 0). Gameplay registers `C.HitstopHook(fn)` to also pause velocity/physics. Never > 16f (feels laggy).

## 3. Impact frames (`C.ImpactFrame(mode, frames, subjects)`)
| Mode | Frames | Use |
|---|---|---|
| `white` | 1 | Beam release (Kamehameha), disc hit |
| `white` | 2 | Final Flash release |
| `black` | 1 | Death Ball release |
| `invert` | 2–3 | Ki Crit, finisher, transform flash, Final Explosion, beam-struggle resolve, Black Nova: frame A = black screen 88% + subjects white silhouette (Highlight AlwaysOnTop), frame B = white screen + black silhouettes |
Max one impact frame per 0.25 s per client (avoid strobe; photosensitivity setting can disable via `C.Quality.ImpactFrames=false`).

## 4. Camera shake + FOV punch (`C.CameraShake(trauma)`, `C.FOVPunch(deg)`)
- Shake = trauma model: angle = 4° × trauma² × Perlin(t·25); trauma decays 1.6/s. Old `shake(intensity, dur)` API maps intensity>1 → /5.
- FOV = spring k=180, d=18 (settles ~18f, ~8% overshoot). Positive = punch out, negative = slow zoom-in during charges.
| Event | Trauma | FOV |
|---|---|---|
| M1 hit | 0.10 | 0 |
| Heavy/finisher | 0.35 | +4 |
| Beam release | 0.25 | +10 (Final Flash +14) |
| Charge (per 0.25 s) | 0.1→0.5 ramp | −4…−6 at start |
| Ultimate impact | 1.0 | +12 |
| Transform flash | 0.9 | +14 |
| Final Explosion | 1.0 | +18 |

## 5. Speed lines (`C.SpeedLines(duration, color, count)`)
Radial ScreenGui frames, 40 lines (×quality scale), width 1–4 px, inner radius 18–30% of screen diag, 30% per-frame flicker, transparency 0.25→1 over duration. Duration: beam release 24f, Nova Strike = rush length, transform 27f, MUI final 24f. Off on Low quality.

## 6. Shockwave rings (`C.Shockwave(parent, cf, start, end, color, time, thickness)`)
Two layered Neon cylinders: outer (colour, transparency 0.1→1) + inner white (0.3→1, 70% size, 70% time). Easing Quart Out. Sizes: hit 1→6 studs/0.2 s; beam muzzle 1→3×width/0.3 s; ultimate impact 2→2×radius/0.45 s; transform 3→70/0.6 s.

## 7. Ground cracks (`C.GroundCrack(parent, center, radius, count, color, life)`)
Slate strip 0.35 wide (`#1C1614`) + neon glow strip 0.12 wide (aura colour, transparency 0.2→1 over 0.8 s). Grow 0→len in 7f. Count: medium 6, heavy 10, ultimate 14, Final Explosion 16. Life 3–5 s then fade 0.8 s.

## 8. Debris (`C.DebrisBurst(parent, pos, count, power, color, life)`)
Rock material, `#69 5C 50` (105,92,80), size 0.4–1.7, launch dir up-cone (y 0.8–1.4), speed power×(0.6–1.2), angular 20 rad/s, CanCollide true, CanQuery/CanTouch false. Life 2.5 s, fade+shrink last 0.5 s. Hard cap `C.Quality.MaxDebris` (40/24/10).

## 9. Auras (`C.AuraEmitter(character, formId, {Scale, Intensity})` → `:SetIntensity`, `:Burst`, `:Destroy`)
Shared layers (body flame, wisps, optional sparks, optional shimmer, PointLight with Perlin flicker 0.85–1.15):
| Layer | Rate | Lifetime | Speed | Size (NumberSequence) | Transparency | LightEmission | Drag | Spread | Accel |
|---|---|---|---|---|---|---|---|---|---|
| Body flame (Cylinder, Outward, Locked) | spec Rate (30–65) | 0.35–0.6 | 2–5 | 0:1.8, 0.5:2.4, 1:0.4 | 0:1, 0.15:0.35, 1:1 | 1 | 2 | 12° | (0,28,0) |
| Wisps (Squash −2.5) | 0.6×Rate | 0.25–0.4 | 10–16 | 0.25→0 | 0.2→1 | 1 | 0 | 8° | (0,40,0) |
| Sparks (Squash 4) | 18 | 0.06–0.12 | 0–1 | 0.18 | 0 | 1 | 0 | 180° | 0 |
| Shimmer (UI) | 25 | 0.5–0.9 | 0.5–1.5 | 0:0, 0.5:0.2, 1:0 | 0.2→1 | 1 | 0 | 180° | (0,4,0) |
Per form (Primary / Secondary / Core hex, extras):
| Form | Primary | Secondary | Core | Notes |
|---|---|---|---|---|
| SSJ | `#FFD84A` | `#FFF3B0` | `#FFFFFF` | Rate 45, sharp flame |
| SSJ2 | `#FFE15A` | `#FFF6C0` | `#FFFFFF` | + blue-white sparks `#BFE6FF` |
| SSJ3 | `#FFC828` | `#FFE88A` | `#FFFFFF` | Rate 65, sparks |
| SSG | `#FF4A3A` | `#FF9A6A` | `#FFE0C8` | Rate 35, calm, soft |
| SSB | `#3AD7FF` | `#9FEFFF` | `#FFFFFF` | sparks `#E0FAFF`, contained flame |
| SSB Evolved | `#2A55E8` | `#6F8CFF` | `#D8E2FF` | Rate 60, sparks `#9FB8FF`, heavier |
| UI Sign | `#C8D2FF` | `#8C9CFF` | `#FFFFFF` | Rate 30 + shimmer; silver outline Highlight |
| MUI | `#E8EEFF` | `#B8C4FF` | `#FFFFFF` | Rate 35 + shimmer, silver |
| Ultra Ego | `#9A4AFF` | `#FF78C8` | `#2A0A3A` | sparks `#FF78C8`; grows via `UltraEgoGrowth` |
| Beast | `#FF3C46` | `#FFFFFF` | `#FFFFFF` | red/white, sparks `#FF9AA0` |
| Golden Frieza | `#FFC400` | `#FFF0A0` | `#FFFFFF` | Rate 40, glossy |
| Black Frieza | `#96286E` | `#FF3C78` | `#140A19` | dark core, crimson sparks |
| Frieza Full Power | `#C77DFF` | `#FFB0F0` | `#FFFFFF` | thin |

## 10. Beams (`C.BeamCore(parent, {Width, Core, Inner, Outer})` → `:Update(origin, dir, len, t)`, `:Fade(t)`)
| Layer | Width × | Material | Transparency | Motion |
|---|---|---|---|---|
| Core | 0.45 | Neon white | 0 | pulse 6% @ 55 rad/s |
| Inner | 1.0 | Neon colour | 0.15 | pulse 6% |
| Outer | 1.35 | Neon colour | 0.55 | pulse 10% @ 31 rad/s, rotates 6 rad/s |
| Heat haze | 1.7 | Glass | 0.85 | Medium+ quality only |
| Spiral rings | 1.5 | Neon colour | 0.6 | every 6 studs, scroll 60 studs/s |
Beam growth 400–450 studs/s; release = 1–2 white impact frames + FOV punch + speed lines + muzzle shockwave. Fade 15f with width collapse to 20%.
**Beam struggle clash:** orb `OrbSize` 9, shell lerps between beam colours by progress; shockwave ring every 21f perpendicular to beams; sparks Rate 120 Speed 30–60 Squash 3 Drag 2; small debris pops (30%/ring); resolve = invert impact frame 3f + FOV +12 + Ultimate impact.

## 11. Teleport afterimages (`C.Afterimage(character, color, life, startT)`)
Clone visible parts → Neon, colour tint, transparency 0.35–0.5 → 1 over 15–20f. IT: on vanish (0.3 s, `#C8EBFF`) and 7f after reappear. Nova Strike: every 4f during rush. MUI Rush: one per strike. Cap `MaxAfterimages` 24/14/6.

## 12. Power-up scream + rock levitation (TransformationVFX)
| Frame | Event |
|---|---|
| 0 | FOV −4 zoom-in, scream sound/`OnScream`, aura Rate 40 |
| 0–charge | Aura rate 40→200 (cubic ease), shell grows 1→1.5×, light 8→24, cracks grow radially, rocks rise 2–10 studs and orbit (0.3–0.9 rad/s, ×3 by end), shake trauma ramp, power-level counter eases |
| flash | **Invert impact frame 3f**, FOV +14, speed lines 27f, double shockwave 3→70 studs/36f, `GroundCrack` + `DebrisBurst` 14, rocks blast outward 30 studs, layered `AuraEmitter` burst then settle |
| +2.5 s | Aura off unless `KeepAura` |

---
# Hero sections (per-move specs)

## Goku
| Move | Anticipation | Active | Hold / recovery | VFX spec | Hitstop | Shake/FOV | Impact frame |
|---|---|---|---|---|---|---|---|
| M1 ×5 | 5/5/6/6/10f | 2f each | 4f / 8–18f | white spark burst 10 particles Speed 15–25, Lifetime 0.1–0.2, Size 0.6→0 | L/L/L/M/Finisher | 0.1 …0.35/+4 | finisher: invert 2f on Ki Crit |
| Kamehameha | 54–90f charge ("Ka-me-ha-me") | beam 90f | 6f hold, 20f recovery | Charge orb `#7FD4FF`→`#FFFFFF`, pull-in Rate 60 Speed −12…−8; BeamCore Width 4 (`#3AA8FF` outer, white core) | Ultimate on hit | release 0.25/+10; impact 1.0/+12 | white 1f (release), invert 3f (impact) |
| Instant Transmission | 10f fingers glow | 3× flicker 6f | reappear 6f | afterimage `#C8EBFF` 0.3 s, vertical streak 15f | — | — | — |
| Spirit Bomb | 240f (hold) | throw drift 28 studs/s | 30f | motes `#BFE9FF` Rate 120 Speed −60…−45 inward, sphere 5→40 studs, corona `#7FD4FF` | Ultimate | zoom −6 then 1.0/+12 | black 1f release, invert 3f impact |
| MUI Rush | 6f | 8 strikes × 5f | 12f hitstop + palm | silver afterimages `#DDE6FF`, hit sparks, palm ring 35 studs | Light ×8 + Finisher | 0.6 ticks, final 1.0 | invert 3f |
| Transform | see §12 | | | aura per §9 | | | invert 3f |

## Vegeta
| Move | Anticipation | Active | Hold / recovery | VFX spec | Hitstop | Shake/FOV | Impact frame |
|---|---|---|---|---|---|---|---|
| M1 ×6 | 4–5f | 2f | 3f / 8f | gold sparks | L ×5, Finisher | as Goku | Ki Crit invert |
| Galick Gun | 60f (purple crackle) | 80f | 6f | `#8A3CFF` beam / `#F0C8FF` core via Kamehameha BeamCore | Ultimate | release 0.25/+10 | white 1f / invert 3f |
| Final Flash | 96f (arms spread, two orbs `#FFE45A`) | 108f | 8f | BeamCore Width 9 + spinning outer, muzzle shockwave ×4 width | Ultimate | 0.4 sustain, +14 release | white 2f / invert 3f |
| Big Bang Attack | 36f palm | sphere 160 studs/s | 10f | `#9FD8FF` orb, explosion 45 | Heavy | +12 | invert 3f |
| Final Explosion | 120f (gold swell, body cracks) | blast 72f to 60-stud radius | self-KO | gold `#FFD84A`, cracks, white sphere, smoke 40 particles | — | 1.0 / +18 | invert 3f |
| Ultra Ego growth | — | per hit | — | purple pulse 21f, aura Rate +150 at 100% damage taken | — | — | — |

## Frieza
| Move | Anticipation | Active | Hold / recovery | VFX spec | Hitstop | Shake/FOV | Impact frame |
|---|---|---|---|---|---|---|---|
| M1 ×4 (+tail) | 5f | 2f | 4f / 10f | pink sparks `#FF4FD8` | L, L, M, Heavy | | |
| Death Beam | 4f point | 6f travel | 4f | needle `#FF4FD8` width 0.35 + white core, hit shockwave 0.3→3, spark Squash 3 | Light | 0.12 | — |
| Death Ball | 132f (finger raise) | drift 45 studs/s | 30f | `#FF5A1E` sun, corona `#FF8C3C`, dome 2.2× | Ultimate | zoom −6, 1.0 / +12 | black 1f / invert 3f |
| Destructo Disc | 12f raise | homing 70 studs/s | — | disc `#FFB0E0`, edge `#FFF080`, slash on hit, Split 2–3 Golden | Medium | 0.35 | white 1f |
| Nova Strike | 8f | rush 54f | 10f | sphere `#C77DFF`, Trail, afterimage /4f, speed lines | Heavy | +8 | — |
| Black Nova | 6f | rush 30f | void 21f + burst | `#96286E` / `#140A19`, void sphere 18 studs | Heavy | 1.0 | invert 3f |

## Perf budget (`C.Quality`, `C.SetQuality(1..3)`)
| Level | Scale | MaxParticles | MaxDebris | MaxAfterimages | Speed lines | Heat haze |
|---|---|---|---|---|---|---|
| 3 High (PC default) | 1.0 | 1500 | 40 | 24 | on | on |
| 2 Medium | 0.65 | 900 | 24 | 14 | on | on |
| 1 Low (touch default) | 0.35 | 400 | 10 | 6 | off | off |
`C.q(n)` scales particle rates/emit counts. All VFX are client-side; server only sends events.
