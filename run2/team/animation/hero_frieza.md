# Dragon Block Z — Hero: Frieza (`u7_frieza`) — Tournament of Power era
Config.ROSTER forms: `FullPower, Golden`. Presets: `FullPower` (via `FULLPOWER_BY_CHAR.u7_frieza`), `GoldenFrieza`.
> ✅ "Final Form" is base. `FULLPOWER_BY_CHAR.u7_frieza = "FriezaFullPower"` (purple `#C77DFF`). Black Frieza active: preset `FriezaBlack`, signature `BlackFriezaVFX`.
No outfit — Frieza's body is his "armor". Tail is a key physical asset.

## Per-form look
| Form | Head / body | Eyes | Hex | Aura / particles |
|---|---|---|---|---|
| Final Form | Smooth, sleek, mostly white body `#F4F2F5`, **purple gem panels** on head dome, shoulders, forearms, shins, chest `#7A2E8E` (glossy), lean build, long tail with white tip | Red irises `#C21A2A`, black lips `#2A1A2A` | body `#F4F2F5`, gems `#7A2E8E` | Pale purple-pink aura `#C77DFF` thin, rarely visible; energy attacks pinkish |
| Golden | Entire body **gold** `#E8B020`, gem panels become **purple-violet** `#5B2C8F`, face/hands/feet slightly darker gold `#C99418`, chest bulks slightly | Red `#C21A2A` | body `#E8B020`, gems `#5B2C8F` | Bright gold aura `#FFC400` with white core `#FFF0A0`, glossy rim light, golden sparks; preset `GoldenFrieza` |
| Full Power (variant of Final) | Muscle-up body scale 1.15 | Red | same | Purple-pink flaring aura |

Build notes: custom rig = R15 + tail (4 bone segments, Motor6D chain, procedural sway via spring script). Gems = separate MeshParts with Glass/SmoothPlastic + Reflectance 0.2, color swap on Golden. Golden transform: body Color tween over 40f from feet up, gold light bloom.

## Signature poses
- **Death Beam**: one arm extended, index finger pointed, smirk.
- **Death Ball**: one finger raised overhead, other hand on hip.
- **Destructo Disc**: raised palm flat above head with spinning disc.
- **Hover poise**: arms crossed, floating, tail curled.
- **Golden reveal**: arms spread at sides, chest out, gold shell cracks off.

## Animation list (60 fps)
| # | Clip | Frames @60 | Priority | Loop | Notes |
|---|---|---|---|---|---|
| 1 | Idle | 120 | Idle | Loop |  |
| 2 | CombatIdle | 90 | Idle | Loop |  |
| 3 | Walk | 48 | Movement | Loop |  |
| 4 | Run | 32 | Movement | Loop |  |
| 5 | FlyIdle | 120 | Movement | Loop | hover bob 0.3 studs |
| 6 | FlyForward | 40 | Movement | Loop | body 70° forward lean |
| 7 | FlyDash | 18 | Action | No | burst, afterimage spawn f2 |
| 8 | Dash | 14 | Action | No | f0-3 crouch, f4 launch, f10 recover |
| 9 | Jump | 20 | Movement | No |  |
| 10 | Land | 12 | Movement | No |  |
| 11 | M1_1 | 16 | Action | No | hit frame f6 |
| 12 | M1_2 | 16 | Action | No | hit f6 |
| 13 | M1_3 | 18 | Action | No | hit f7 |
| 14 | M1_4 | 20 | Action | No | hit f8 |
| 15 | M1_5_Launcher | 28 | Action2 | No | hit f10, knockback |
| 16 | BlockStart | 8 | Action | No |  |
| 17 | BlockHold | 60 | Action | Loop |  |
| 18 | BlockBreak | 30 | Action3 | No | stagger |
| 19 | PerfectBlock | 14 | Action3 | No | parry flash f2 |
| 20 | HitLight | 14 | Action3 | No |  |
| 21 | HitHeavy | 26 | Action3 | No |  |
| 22 | KnockbackFly | 30 | Action3 | Loop |  |
| 23 | GetUp | 40 | Action2 | No | i-frames f0-24 |
| 24 | KiBlast_L | 14 | Action | No | release f5 |
| 25 | KiBlast_R | 14 | Action | No | release f5 |
| 26 | PowerUp_Start | 30 | Action2 | No |  |
| 27 | PowerUp_Loop | 60 | Action2 | Loop | scream hook |
| 28 | Transform | SEE FORM | Action4 | No | per-form sequence |
| 29 | Knockout_RingOut | 90 | Action4 | No | fall off arena |
| 30 | Victory | 150 | Action4 | No |  |
| 31 | DeathBeam_Fire | 10 | Action4 | No | index finger point, release f3 |
| 32 | DeathBeam_Rapid | 30 | Action4 | Loop | alternating fingers |
| 33 | DeathBall_Raise | 120 | Action4 | Loop | one finger up |
| 34 | DeathBall_Throw | 30 | Action4 | No | flick f12 |
| 35 | DestructoDisc | 40 | Action4 | No | raise hand f0-24, throw f28 |
| 36 | NovaStrike | 50 | Action4 | No | shoulder-charge dash, aura body |
| 37 | TailWhip | 20 | Action | No | tail sweep hit f8 |
| 38 | Taunt_Laugh | 90 | Action | No | hand to mouth |

Transform timings: Golden 180f — f0 arms out, f40 cocoon of gold light, f130 shell shatters with flash, f160 pose. Frieza's power-up is a menacing laugh, not a scream.

## Signature moves
| Move | VFX notes | Module |
|---|---|---|
| **Death Beam** | Thin pink-purple needle beam `#FF4FD8` with white core, near-instant (0.1s travel), tiny piercing hole impact + spark; rapid-fire variant alternates fingers. | `DeathBeamVFX` ✅ (`Rapid` variant) |
| **Death Ball** | Red-orange `#FF5A1E` sphere with dark core grows atop finger to massive size, slow ominous throw, rolling detonation + `ArenaDamage`. | `DeathBallVFX` ✅ |
| **Destructo Disc** (Frieza's version) | Flat pink-yellow saw disc `#FFB0E0` edge spinning, high-pitch whine, homing curve, cuts with a slash decal; can split into 2–3 (Golden). | `DestructoDiscVFX` ✅ (`Split` 2–3) |
| **Nova Strike** | Body enveloped in purple-pink energy sphere, shoulder-charge rush leaving trail, explosion on contact. | `NovaStrikeVFX` ✅ |

## Voice / scream cues
| Hook | Description |
|---|---|
| `VO_Frieza_DeathBeam` | Quiet amused "hmph" |
| `VO_Frieza_DeathBall_Laugh` | Rising cruel laugh while charging |
| `VO_Frieza_Disc_Throw` | Sharp sneering shout |
| `VO_Frieza_Nova` | Furious battle cry |
| `VO_Frieza_Golden_Reveal` | Smug declaration, laugh |
| `VO_Frieza_Rage` | High-pitched shriek (HP low) |
| `VO_Frieza_Taunt_Laugh` | Polite mocking laugh |
| `VO_Frieza_Hurt_L/H`, `VO_Frieza_Victory` | Pained hiss; triumphant laugh |
