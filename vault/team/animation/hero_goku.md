# Dragon Block Z — Hero: Goku (`u7_goku`) — Tournament of Power era (DBS ep. 97–131)
Config.ROSTER forms: `KaioKen, SuperSaiyan, SuperSaiyan2, SuperSaiyan3, SuperSaiyanGod, SuperSaiyanBlue, UISign, UltraInstinct`.
Presets in `TransformationVFX.lua`: `SSJ`, `SSG`, `SSB`, `UISign`, `MUI` (resolve via `T.ResolveFormId`).
> ✅ Fixed: `FORM_ID_MAP.UltraInstinct = "MUI"`; `UltraInstinctSign`/`UISign` → `UISign`.
All content original; colors are design approximations of the show palette. No ripped models/audio.

## Outfit (all forms, ToP era)
- Orange gi top + pants `#F26B1D`, **dark navy undershirt** `#1F2A5A` (ToP: navy, not the old blue), navy wristbands `#1F2A5A`, navy obi belt `#1F2A5A`, navy/indigo boots `#2C3A7A` with yellow-tan straps `#E3B23C`. **No kanji** on chest in ToP-era (Whis-symbol gi is pre-ToP Future Trunks arc; ToP uses the plain orange gi with the Goku symbol on back optional — keep plain front, small original emblem on back).
- Battle damage stage (HP<35%): top torn off left shoulder, undershirt shredded → swap to `Goku_Torn` accessory set (late ToP / MUI look is shirtless with tattered navy undershirt remnants).
- Build: R15, layered-clothing gi; hair as MeshPart accessories per form (swap on transform at the flash frame), eyes via Decal swap on face.

## Per-form look
| Form | Hair | Eyes | Hex | Aura / particles |
|---|---|---|---|---|
| Base | Black spiky, 5 front spikes, signature left-swept bangs | Black `#111111` | hair `#141414` | Faint white flicker only while charging `#F0F0FF` |
| SSJ | Gold, spikes stand up & stiffen, one bang down front | Teal-green `#2FBF9F` | hair `#FFD84A`, aura `#FFD84A` | Flame-shaped gold aura, rising flickers, dust ring. Preset `SSJ` |
| SSJ God | Black-crimson, **slimmer**, base-like shape slightly lifted; body leaner | Red-magenta `#D6224E` | hair `#B3122E`, aura `#FF4A3A`, core `#FFB478` | Calm **candle-flame** aura, tall soft licks, rising ember sparks, no lightning. Preset `SSG` |
| SSJ Blue | SSJ shape but spikes slightly softer, cyan | Cyan `#3AD7FF` (pupils visible) | hair `#33C6F2`, aura `#3AD7FF`, core `#C8F5FF` | Translucent blue flame aura with **sparkle glitter** particles (tiny white star twinkles), inner white core outline. Preset `SSB` |
| UI Sign (Omen) | **Black hair**, spikes lifted slightly, faint blue-white edge glow | Silver-grey irises `#C9CED8` | aura `#DDE6FF`, core `#8CA0FF` | Aura looks like **heat-haze silver flame**, faint blue-purple rim; aura at body is thin, bright outline. Particles drift upward slowly. Preset `UISign` |
| UI Mastered | **Silver/white hair** `#E8EDF5`, same shape as UI Sign | Silver `#D8DEE8` | aura `#F0F5FF`, core `#FFFFFF` | **Silver flame wisps**: thin vertical flickering tendrils, rising white motes, soft rim light on body; aura is quiet (no roar), subtle sound. Preset `MUI` |

Build notes per form: aura = 2 ParticleEmitters (flame body, LightEmission 1, Rate 40) + sparkle emitter for Blue (Size 0.15, Rate 25, Lifetime 0.4) + PointLight tinted to aura. UI: add `Highlight` (OutlineColor silver, FillTransparency 1) and lower aura rate; MUI hair uses Material Neon low alpha.

## Signature poses
- **Kamehameha stance**: wide side stance, hands cupped at right hip, torso twisted back.
- **Instant Transmission**: index + middle finger to forehead, eyes closed.
- **Spirit Bomb**: both arms straight overhead, palms open, head tilted up.
- **UI stance**: relaxed upright, arms low and slightly forward, eyes calm — minimal motion, weight shifts only.
- **Fighting stance**: left fist forward, right fist guarding chin, knees bent.
- **Victory**: grin, thumbs-up or hand behind head scratch.

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
| 31 | Kamehameha_Charge | 72 | Action4 | No | hands cupped at hip, loop f30-72 while held |
| 32 | Kamehameha_Fire | 24 | Action4 | No | thrust f4 |
| 33 | InstantTransmission | 20 | Action4 | No | 2 fingers to forehead f0-10, vanish f12 |
| 34 | SpiritBomb_Raise | 180 | Action4 | Loop | arms up, loop while gathering |
| 35 | SpiritBomb_Throw | 40 | Action4 | No | release f22 |
| 36 | UI_Dodge_L | 10 | Action4 | No | lean, no step |
| 37 | UI_Dodge_R | 10 | Action4 | No |  |
| 38 | UI_Counter | 22 | Action4 | No | palm strike f8 |

Transform frame timings (hold `TransformationVFX.Start`, release `handle:Stop`):
- SSJ 150f: f0 clench, f30 scream begin, f110 flash + hair swap, f130 settle.
- SSG 180f: hands together (ritual-like stillness), f140 red flash, calm exhale.
- SSB 150f: legs apart, chest out, f90 blue burst (no long scream; short grunt).
- UISign 240f: shell-break — f0 kneeling dim, f120 silver silhouette, f200 burst of white, eyes reveal.
- MUI 210f: hair whitens f150 from roots upward over 30f, silent aura bloom.

UI rules (from movesets_v2): auto-dodge 35% (Sign) / 60% (Mastered) of M1s & ki blasts when not attacking; dodge clips `UI_Dodge_L/R` play with afterimage.

## Signature moves
| Move | VFX notes | Module |
|---|---|---|
| **Kamehameha** | Charge: blue-white orb `#7FD4FF`→core `#FFFFFF` grows between cupped hands, rotating sparks, pull-in particles, ground dust. Fire: cylindrical beam, outer `#3AA8FF` alpha 0.5, inner white core, spiral rings every 6 studs, slight beam wobble. Impact: dome explosion + `ArenaDamage.DamageAt`. Blue/MUI variants recolor (MUI: silver-white beam). | `KamehamehaVFX` ✅ |
| **Instant Transmission** | f10 fingers glow, f12 body flickers 3× (Transparency 0↔0.6), vanishes with a small vertical blur streak + soft "shimmer" sound; reappear behind target with inverse flicker. No big flash. | `InstantTransmissionVFX` ✅ |
| **Spirit Bomb** | Arms up; pale blue-white motes `#BFE9FF` stream inward from all directions (Beam-attached particles), sphere grows 5→40 studs over hold, swirling surface (Texture scroll), low hum. Throw: slow drift, on hit massive bright flash, long dome, heavy arena damage. ToP: built with U7 energy, purple-tinted outer layer optional. | `SpiritBombVFX` ✅ (DeathBall-based + inward mote field; `U7Tint` option) |
| Ultimate: MUI rush | Silver afterimage strikes + final palm burst (`UI_Counter`). | `MUIRushVFX` ✅ |

## Voice / scream cues (audio-hook names, original VO only)
| Hook | Description |
|---|---|
| `VO_Goku_Kame_Charge` | Syllable-by-syllable charge chant, rising pitch, ~1.2s |
| `VO_Goku_Kame_Fire` | Sharp explosive shout on release |
| `VO_Goku_SSJ_Scream` | Long rising roar, 2s, voice cracks at peak |
| `VO_Goku_SSG_Breath` | Calm deep exhale, no scream |
| `VO_Goku_SSB_Grunt` | Short determined grunt + burst |
| `VO_Goku_UI_Scream` | Desperate full-body scream breaking into silence at the flash |
| `VO_Goku_MUI_Silent` | No vocal; soft wind/whoosh SFX `SFX_MUI_Hum` |
| `VO_Goku_IT` | Light "huh" breath; `SFX_IT_Shimmer` |
| `VO_Goku_SpiritBomb_Call` | Earnest plea for energy, strained |
| `VO_Goku_Hurt_L/H`, `VO_Goku_Victory` | Grunts; cheerful laugh |
Wire via `TransformationVFX` cfg `OnScream` / `ScreamSoundId` (leave blank; plug in original recordings).
