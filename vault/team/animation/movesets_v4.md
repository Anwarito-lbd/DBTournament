# Dragon Block Z — v4 additions (DESIGN PROPOSAL; db-gameplay Config numbers win)
Decisions from roblox lead: Kefla = `u6_kefla`; MUI/UltraEgo/KeflaPotara/SSBEvolved/BeastGohan/FriezaBlack active form ids; Gameplay `UltraInstinct` → MUI preset, `UltraInstinctSign`/`UISign` → UI Sign; divine tier playable (`div_*`); Moro `u7_moro` (pending gameplay).

## 1. New/active forms (VFX preset = form id)
| Form id | Who | Look | Preset notes |
|---|---|---|---|
| `SSBEvolved` | u7_vegeta | darker blue hair, veins | Aura `#2A55E8`, Core `#9FB8FF`, sparks, 210f transform |
| `UltraEgo` | u7_vegeta | purple hair, magenta eyes | Aura `#9A4AFF`; **damage-growth hook** `TransformationVFX.UltraEgoGrowth(char):Damaged(amount, maxHp)` grows aura per damage taken; pair with gameplay passive (+5% dmg per 10% HP lost, cap +40%) |
| `MUI` (= Config `UltraInstinct`) | u7_goku | silver hair | silver aura, auto-dodge 30% (rules in v2) |
| `UISign` (= `UltraInstinctSign`) | u7_goku | black hair, silver aura | auto-dodge 15% |
| `BeastGohan` | u7_gohan | **white, tall spiky hair, red eyes** | Aura red `#FF3C46` / white core, sparks |
| `FriezaFullPower` (FullPower for u7_frieza) | u7_frieza | veins, bulk | purple aura `#C77DFF` |
| `FriezaBlack` | u7_frieza | **black body**, purple-red aura | Aura `#96286E`, dark core |
| `KeflaPotara` | u6_kefla | fusion flash | via `FusionVFX.Potara` then preset |
| `MoroAwakened` | u7_moro | merged/awakened, horns grow, green-black | Aura `#78E65A` |

## 2. Signature modules (hero docs → modules)
| Character | Move | Module |
|---|---|---|
| Goku | Kamehameha / Instant Transmission / Spirit Bomb / MUI Rush | `KamehamehaVFX`, `InstantTransmissionVFX`, `SpiritBombVFX`, `MUIRushVFX` |
| Vegeta | Galick Gun / Final Flash / Big Bang / Final Explosion | `GalickGunVFX`, `FinalFlashVFX`, `BigBangAttackVFX`, `FinalExplosionVFX` |
| Frieza | Death Beam / Death Ball / Destructo Disc / Nova Strike / Black Nova | `DeathBeamVFX`, `DeathBallVFX`, `DestructoDiscVFX` (Split=2–3 in Golden), `NovaStrikeVFX`, `BlackFriezaVFX` |
| Beast Gohan | Special Beam Cannon (red) | `BeastSBCVFX` |
| Piccolo | Special Beam Cannon | `SpecialBeamCannonVFX` |
| Moro | Absorb / Planet Drain / copied IT | `MoroAbsorbVFX`, `MoroPlanetDrainVFX`, `InstantTransmissionVFX` |

### Beast Gohan kit (form-specific overrides on u7_gohan)
- M1: 5 hits, finisher sweeping kick that hair-flares (Beast idle), +1 hitstop frame on all hits.
- S1 → **Beast Special Beam Cannon** (`BeastSBCVFX`): 1.2 s charge, pierces, 30 dmg, 35 ki, 12 s.
- Ult → **Beast Kamehameha** (Kamehameha with Color red/white). Anims: `Beast_Transform_Roar`, `SBC_Beast_TwoFinger`, `Beast_Idle_Hairflow`.

### Black Frieza kit (form-specific overrides on u7_frieza)
- Passive: first hit after transform deals ×1.5 (one-shot "instant" surprise).
- Signature **Black Nova** (`BlackFriezaVFX`): near-instant dash strike, delayed void burst 28 + 12, 40 ki, 14 s.
- Death Beam becomes 5-shot rapid (`DeathBeamVFX.Rapid`). Anims: `Black_Arrive_Flash`, `Black_Nova_Dash`, `Smug_Idle`.

## 3. Divine tier — playable unlocks (proposed tuning; gameplay numbers win)
Unlock: special achievements, not level only. Ranked: banned; casual/event: allowed, max 1 per team.
| id | Base | Notes |
|---|---|---|
| `div_destroyer_<name>` (beerus, belmod, quitela, ...) | 1600 | Hakai becomes ult: 2 s lock-on, 70 dmg (not instant KO) to players; breakable by LOS. Sphere of Destruction S1 (40), Hakai Field S2. Destroyer passive: −20% ki blast damage taken. |
| `div_angel_<name>` (whis, vados, marcarita, ...) | 1400 | Auto-dodge 35% (UI-like rules), very low damage (×0.6), S1 Staff Tap ragdoll, S2 Time Rewind self (restore HP to 3 s ago, 30 s cd), Ult Angelic Barrier team shield. Support role. |
| `div_grand_priest` | 1500 | Support/controller: S1 Arena Command (pull all enemies 10 studs), S2 Rewind ally, Ult Elimination Ruling: marks one enemy, if they're hit 5× in 6 s they're ringed out. |
| `div_zeno` | 1 (!) | **Novelty/event only.** Zeno can't fight: M1 = cheerful wave (0 dmg). Ult **Erase**: 8 s full-screen cinematic warning, then erases a random *enemy* (not a team) — once per match, only allowed in "Zeno's Festival" mode. Invulnerable but movement ×0.6, can't capture/score. VFX: white sphere expanding (use `FinalExplosionVFX` with Color white, Radius 25, ArenaDamage off) + `FusionVFX` flash. Anims: `Zeno_Bounce_Idle`, `Wave`, `Erase_Point`, `Giggle`. |

## 4. Moro — `u7_moro` (pending gameplay)
Universe 7 roster as Galactic Patrol prisoner guest (non-canon for ToP — included at user request). Base proposal 1000, unlock Lv 60.
- M1: 4 hits (staff thrust, palm, palm, staff swing), finisher absorbs 3 ki from target.
- Ki blast: green orb triple shot.
- S1 **Energy Absorption Touch** (`MoroAbsorbVFX`): grab within 4 studs, channel 1.5 s: drains 20 ki + 15 HP over time, heals Moro for 50% of HP drained; breakable by hitting Moro 2×. 25 ki, 12 s.
- S2 **Copied Ability** — cycles each use: (a) Instant Transmission teleport (`InstantTransmissionVFX`), (b) Clone (spawns 1 decoy 4 s), (c) Cell-regen 10 HP. 20 ki, 10 s.
- Ult **Planet Drain** (`MoroPlanetDrainVFX`): r=30 zone, 3 s, 3 pulses: each drains 8 HP + 10 ki from every enemy inside, cracks the arena (ArenaDamage 30/35 per pulse, server-side). 100 ki, 90 s.
- Transform: `MoroAwakened` (merged with Seven-Three's copied powers), proposed Lv 85.
- Anims: Standard set + `Staff_Idle`, `Absorb_Grab_Loop`, `PlanetDrain_PalmDown`, `Clone_Split`, `Merge_Transform`, `Moro_Laugh`.
