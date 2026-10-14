# Dragon Block Z — Hero: Vegeta (`u7_vegeta`) — Tournament of Power era
Config.ROSTER forms: `SuperSaiyan, SuperSaiyan2, SuperSaiyanGod, SuperSaiyanBlue, UltraEgo`.
Presets: `SSJ`, `SSB`, `UltraEgo`. 
> ✅ `SSBEvolved` preset added (Aura `#2A55E8`, Core `#9FB8FF`); form id `SSBEvolved` (alias `SuperSaiyanBlueEvolved`) — Config add pending in db-gameplay. Ultra Ego is post-ToP (manga Granolah arc) — included at user request as a "dream" form.

## Outfit (ToP)
- **Blue bodysuit** `#1E3FA8`, **white Saiyan armor** chestplate `#F2F2F2` with **gold/yellow shoulder & side trim** `#E2B53C` (ToP armor has no shoulder pads — rounded chest only), white gloves `#F5F5F5` and white boots with gold toe caps `#E2B53C`.
- Battle damage (HP<35%): armor cracked/removed left side, bodysuit torn at shoulder.
- Build: R15, armor as rigid MeshPart accessory, bodysuit layered clothing; hair swap MeshParts.

## Per-form look
| Form | Hair | Eyes | Hex | Aura / particles |
|---|---|---|---|---|
| Base | Black, tall flame-shaped upright, sharp **widow's peak** | Black | hair `#121212` | none / faint white on charge |
| SSJ | Gold, same upright shape, stiffer | Teal `#2FBF9F` | `#FFD84A` | Gold flame aura, preset `SSJ` |
| SSJ Blue | Cyan, upright widow's peak | Cyan `#3AD7FF` | hair `#33C6F2`, aura `#3AD7FF` | Blue flame + sparkles, preset `SSB` |
| Blue Evolved | **Darker royal blue**, spikier, more jagged, body bulkier | Dark blue `#1C3FBF` (pupil-less in burst) | hair `#1F4FD1`, aura `#2A55E8`, core `#9FB8FF` | Denser, darker blue aura with **crackling sparks** and violent flicker, stronger heat-haze. Needs preset `SSBEvolved` |
| Ultra Ego | **Dark purple/magenta**, upright, slightly wilder | Magenta `#E0388C`, sharp, eyebrows gone/faint | hair `#5A1E8A`, aura `#9A4AFF`, core `#FF78C8` | Purple **Hakai-style flame aura**, heavy, slow pulsing, magenta core; pink-purple sparks; grows stronger as he takes damage (scale aura size by damage taken). Preset `UltraEgo` |

## Signature poses
- **Final Flash**: arms spread fully to sides, palms out, then snap together forward.
- **Galick Gun**: body turned sideways, both palms stacked at chest side facing target.
- **Big Bang**: right arm straight forward, open palm, left hand at side.
- **Prideful cross**: arms crossed, chin up, scowl (idle variant / taunt).
- **Final Explosion**: knees bent, arms pulled in, then flung out with gold aura.

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
| 31 | GalickGun_Charge | 60 | Action4 | No | palms together at side |
| 32 | GalickGun_Fire | 22 | Action4 | No |  |
| 33 | FinalFlash_Charge | 90 | Action4 | No | arms spread wide, loop f50-90 |
| 34 | FinalFlash_Fire | 26 | Action4 | No | palms snap forward f6 |
| 35 | BigBang_Fire | 30 | Action4 | No | one arm extended, release f10 |
| 36 | FinalExplosion | 150 | Action4 | No | sacrificial self-detonation |
| 37 | UE_TankHit | 20 | Action4 | No | shrugs hit, grin |
| 38 | Taunt_Scoff | 60 | Action | No | arms crossed head turn |

Transform timings: SSJ 120f (fast, angry); SSB 140f (f80 burst); Blue Evolved 210f (f0 kneel/strain, f90 veins + sparks, f170 dark-blue burst, huge rocks); Ultra Ego 240f (f0 eyes closed, aura turns purple from the ground up f60–180, f200 magenta flash, grin).

## Signature moves
| Move | VFX notes | Module |
|---|---|---|
| **Galick Gun** | Purple-violet charge `#8A3CFF` with pink core, beam slightly ragged, purple crackle; impact purple-white flash + `ArenaDamage`. | `GalickGunVFX` ✅ (Kamehameha variant) |
| **Final Flash** | Two-hand charge with gold-yellow energy `#FFE45A` sparks gathering in each palm, palms join, colossal yellow-white beam (wider than Kame), screen-wide flash on fire. | `FinalFlashVFX` ✅ |
| **Big Bang Attack** | Single-palm bright blue-white `#9FD8FF` orb, short pause, fires a fast large sphere (not beam) → huge spherical explosion. | `BigBangAttackVFX` ✅ |
| **Final Explosion** (ToP-style moment) | Ultimate, self-KO: gold aura `#FFD84A` swells, cracks of light on body, white sphere expands 60 studs, lingering smoke; Vegeta knocked out after. | `FinalExplosionVFX` ✅ |
| Ultra Ego "absorb" | On hit while UE, purple pulse + aura grow. | `TransformationVFX.UltraEgoGrowth(char):Damaged(amount, maxHp)` ✅ |

## Voice / scream cues
| Hook | Description |
|---|---|
| `VO_Vegeta_Galick_Charge` / `_Fire` | Two-word growled charge, sharp yell |
| `VO_Vegeta_FinalFlash_Charge` / `_Fire` | Low build-up growl, explosive shout |
| `VO_Vegeta_BigBang` | Short proud shout |
| `VO_Vegeta_FinalExplosion` | Quiet line then blood-curdling final roar |
| `VO_Vegeta_SSJ_Scream` | Furious roar |
| `VO_Vegeta_BlueEvolved_Scream` | Strained, long, agonised scream with breaks |
| `VO_Vegeta_UE_Laugh` | Low menacing chuckle |
| `VO_Vegeta_Taunt` | Contemptuous scoff |
| `VO_Vegeta_Hurt_L/H`, `VO_Vegeta_Victory` | grunts; arrogant laugh |
