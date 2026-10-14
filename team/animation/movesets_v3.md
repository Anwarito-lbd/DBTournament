# Dragon Block Z — v3 additions (DESIGN PROPOSAL)
> **Note (roblox lead decision):** db-gameplay `Config` numbers (form multipliers, unlock levels, base power) WIN over any numbers in this file. Values here are design proposals for feel/timing only. See `movesets_v3.md` §1 and `movesets_v4.md`.
All numbers are design proposals. Extends `movesets.md` (systems) and `movesets_v2.md` (roster).

## 1. ID alignment with db-gameplay `Config` (source: `team/gameplay/src/ReplicatedStorage/Shared/Config.lua`)
### Character IDs (`Config.ROSTER`, format `u<universe>_<name>`)
| Moveset name | Config id | Config forms | Status |
|---|---|---|---|
| Goku | `u7_goku` | KaioKen, SuperSaiyan, SuperSaiyan2, SuperSaiyan3, SuperSaiyanGod, SuperSaiyanBlue, UltraInstinct | ✅ |
| Vegeta | `u7_vegeta` | SuperSaiyan, SuperSaiyan2, SuperSaiyanGod, SuperSaiyanBlue | ✅ (Ultra Ego not in Config) |
| Gohan | `u7_gohan` | SuperSaiyan, SuperSaiyan2, Ultimate | ✅ (Beast not in Config) |
| Piccolo | `u7_piccolo` | FullPower | ✅ |
| Android 17 | `u7_android_17` | FullPower | ✅ |
| Android 18 | `u7_android_18` | FullPower | ✅ |
| Krillin | `u7_krillin` | FullPower | ✅ |
| Tien | `u7_tien` | FullPower | ✅ |
| Master Roshi | `u7_master_roshi` | FullPower | ✅ |
| Frieza | `u7_frieza` | FullPower, Golden | ✅ (Black not in Config) |
| Jiren | `u11_jiren` | FullPower | ✅ |
| Toppo | `u11_toppo` | FullPower | ✅ (GoD mapped to FullPower) |
| Dyspo | `u11_dyspo` | FullPower | ✅ |
| Hit | `u6_hit` | FullPower | ✅ |
| Cabba | `u6_cabba` | SuperSaiyan, SuperSaiyan2 | ✅ |
| Caulifla | `u6_caulifla` | SuperSaiyan, SuperSaiyan2 | ✅ |
| Kale | `u6_kale` | SuperSaiyan, Legendary | ✅ (Berserk → `Legendary`) |
| Kefla | `u6_kefla` | SuperSaiyan, SuperSaiyan2, KeflaPotara | ✅ decided (pending Config add) |
| Ribrianne | `u2_ribrianne` | FullPower | ✅ |
| Anilaza | `u3_anilaza` | FullPower | ✅ |
| Ganos | `u4_ganos` | FullPower | ✅ |
| Destroyer / Angel / Grand Priest / Zeno | `div_*` | — | decided ids (pending Config add) |

### Form IDs (`Config.FORMS`) → VFX preset (`TransformationVFX.FORM_ID_MAP`, `ResolveFormId(formId, charId)`)
| Config form | mult/level (Config) | VFX preset |
|---|---|---|
| Base | 1 / 1 | (none) |
| KaioKen | 1.5 / 5 | `KaioKen` |
| FullPower | 1.75 / 10 | `FullPower`; per char: u11_jiren → `JirenFullPower`, u11_toppo → `ToppoGoD` |
| SuperSaiyan | 2 / 15 | `SSJ` (Caulifla can use `CauliflaSSJ`) |
| SuperSaiyan2 | 2.5 / 30 | `SSJ2` (Kefla: `KeflaSSJ2`) |
| SuperSaiyan3 | 3 / 40 | `SSJ3` |
| Ultimate | 3.5 / 45 | `GohanUltimate` |
| Golden | 4 / 55 | `GoldenFrieza` |
| SuperSaiyanGod | 3.5 / 60 | `SSG` |
| SuperSaiyanBlue | 4.5 / 75 | `SSB` |
| Legendary | 4.5 / 75 | `Legendary` (Kale; alias of KaleBerserk look) |
| UltraInstinct | 6 / 100 | `MUI` (fixed per hero_goku.md) |
| UltraInstinctSign / UISign | (Config) | `UISign` |
| SuperSaiyanBlueEvolved / SSBEvolved | pending Config | `SSBEvolved` |
| UltraEgo | pending Config | `UltraEgo` |
| KeflaPotara | pending Config | `KeflaPotara` |
| BeastGohan | pending Config | `BeastGohan` (active) |
| FriezaBlack | pending Config | `FriezaBlack` (active) |
| MoroAwakened | pending Config | `MoroAwakened` |
Mapped/active per roblox lead: MUI, UltraEgo, KeflaPotara, SSBEvolved, BeastGohan, FriezaBlack, MoroAwakened. FullPower: u7_frieza → `FriezaFullPower` (purple).
**Note:** Config's multipliers/levels are authoritative and supersede the multipliers/levels in movesets v1/v2 (those were proposals). The `Multiplier` field in VFX presets is display-only.

## 2. Divine tier — **playable unlocks** (decision: ids `div_destroyer_<name>`, `div_angel_<name>`, `div_grand_priest`, `div_zeno`). Below kits are the boss-tuned versions; playable tuning in `movesets_v4.md` §3.
Proposed ids: `div_destroyer_<name>` (e.g. `div_destroyer_beerus`), `div_angel_<name>` (`div_angel_whis`), `div_grand_priest`.
Balance philosophy: they are **referees / raid bosses**, not fighters. Base 2000–5000, uninterruptible tells, every attack telegraphed ≥ 0.8 s so players can react; rewards for surviving, not for killing.

### Destroyer (e.g. Beerus, Belmod, Quitela) — raid boss
HP ×10 (scales with players), takes −50% knockback, immune to stun/grab.
- M1: 3 slow open-palm hits, 15 each, r=7 cone, 12f startup.
- Ki: Destruction orb (slow homing, 25).
- S1 **Sphere of Destruction**: giant orb, 60 dmg, 1.2 s tell, 20 s cd.
- S2 **Hakai Field**: ring that shrinks toward Destroyer over 4 s; ring-out risk.
- Ult **Hakai (erasure)**: 2 s targeting beam on one player; if not broken by line-of-sight (pillar) or 3 players hitting him (≥ 60 total dmg) → instant KO for that player (no damage number; counts as elimination). 90 s cd, max once per minute.
- Phase 2 at 50% HP: aura purple `#8B3AFF`, attack speed ×1.25 (reuse `ToppoGoD` aura preset).
- Anims: `Idle_Bored`, `Yawn`, `Palm_Strike_1..3`, `Hakai_Point`, `Orb_Raise`, `Phase2_Roar`, `Defeated_Sit`.

### Angel (e.g. Whis, Vados, Marcarita) — trainer / referee
Not damageable (auto-dodge 100%; uses UI dodge animations). Training mini-game NPC.
- Staff Tap: 1 dmg, ragdoll 1.5 s (comedic punish for spam).
- Time Rewind: rewinds an arena area 3 s (cosmetic + restores ArenaDamage chunks → `ArenaDamage.Reset()` server-side, admin only).
- Training challenge "Touch the Angel": 60 s, players gain XP per near-miss.
- Anims: `Staff_Idle`, `Float_Idle`, `Dodge_L/R/Back`, `Staff_Tap`, `Rewind_Gesture`, `Snack_Taunt`.

### Grand Priest — admin / event host
No combat. Admin commands: start round, Zeno-erasure of eliminated universe (cutscene: white sphere expanding, use `FusionVFX` flash with white color + `TransformationVFX` flash), announce, reset arena.
- Anims: `Hands_Behind_Back`, `Announce`, `Bow`, `Point_Eliminate`.
- Balance: invulnerable; only usable from server admin panel.

### Divine-tier rewards (proposal)
Survive Destroyer raid: 1500 XP + title; defeat phase 2: badge. Angel training: up to 400 XP/day.
