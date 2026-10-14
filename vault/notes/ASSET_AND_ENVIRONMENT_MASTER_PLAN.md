# Asset, Character Roster & Environment Master Plan

## 1. Executive Summary & Asset Inventory
The project possesses a library of **103 high-quality Sketchfab 3D assets** (`C:\Users\issao\Documents\DBTournament\sketchfab_out\` and `sketchfab\models\`), fully licensed under Creative Commons (CC-BY, CC-BY-SA, Free Standard) with authors credited in `ReplicatedStorage.Shared.Credits.lua`.

This document establishes the end-to-end integration blueprint for:
1. **Character Roster:** 3D interactive models in `CharacterSelectUI` and in-game rigs.
2. **Tournament of Power Arena:** Kachi Katchin stone ruins, pillars, debris, and imperial viewing stands.
3. **Training & Hub Worlds:** Hyperbolic Time Chamber, Kame House, Capsule Corp, and Whis's Sacred Ground.
4. **Gameplay Props:** Dragon Balls, Shenron, Scouters, Whis Staff, Potara Earrings, and Dragon Radar.
5. **Mesh-Based VFX:** 3D anime shockwave meshes, explosive bursts, and particle meshes.

---

## 2. Character Model Mapping & Roster Coverage

### Universe 7 Team (The Protagonists)
| Character ID | Character Name | Matching Sketchfab Asset | Form Variants Available |
|---|---|---|---|
| `u7_goku` | Son Goku | `goku_from_dragon_ball_textured_and_rigge_43d397.fbx`<br>`dragon_ball_goku_super_sayayin_a4fbdb.fbx` | Base, SSJ, SSG, SSB, Ultra Instinct, Kid Goku, Nimbus |
| `u7_vegeta` | Vegeta | `dragon_ball_vegeta_64400d.fbx`<br>`dragon_ball_z_super_saiyan_vegeta_2c049d.fbx` | Base, SSJ, SSG, Ultra Ego |
| `u7_gohan` | Son Gohan | `gohan_43d67f.fbx`<br>`gohan_super_saiyan_8a133b.fbx`<br>`beast_gohan_b01f73.fbx` | Kid, Teen, SSJ, Beast Gohan |
| `u7_frieza` | Frieza | `freezer_final_form_ed2a69.fbx`<br>`golden_frieza_315f9a.fbx` | Final Form, Golden Frieza, Black Frieza |
| `u7_piccolo` | Piccolo | `dragon_ball_z_piccolo_1bcf92.fbx` | Base, Orange Piccolo palette |
| `u7_17` | Android 17 | `android_17_2a639c.fbx` | Ranger outfit |
| `u7_18` | Android 18 | `android_18_dbz_f2c5f2.fbx` | Classic DBZ outfit |
| `u7_krillin` | Krillin | `dragon_ball_z_krillin_2e7a69.fbx` | Tournament gi |
| `u7_tien` | Tien Shinhan | `dragon_ball_z_tien_119f29.fbx` | Dojo outfit |
| `u7_roshi` | Master Roshi | `dragon_ball_master_roshi_04b4f1.fbx`<br>`kame_sennin_lowpoly_de1210.fbx` | Turtle Hermit / Jackie Chun |

### Rival Universes & Major Combatants
| Character ID | Character Name | Matching Sketchfab Asset | Universe / Role |
|---|---|---|---|
| `u11_jiren` | Jiren the Gray | `jiren_a61c71.fbx` | Universe 11 Pride Trooper |
| `u6_hit` | Hit | `hit_82ce41.fbx` | Universe 6 Assassin (Time Skip) |
| `u6_kefla` | Kefla | `kefla_dragon_ball_super_04eac3.fbx`<br>`potara_kefla_ssj_71ef7b.fbx` | Universe 6 Potara Fusion |
| `u10_zamasu` | Zamasu | `zamasu_e00e98.fbx`<br>`supreme_kai_zamasu_lowpoly_afc409.fbx` | Universe 10 Apprentice Kai |
| `boss_broly` | Broly | `broly_super_saiyan_9c482f.fbx`<br>`broly_super_saiyan_3_f1784e.fbx`<br>`dragon_ball_zbroly_eafcd3.fbx` | Raid Boss / Legendary Saiyan |
| `boss_goku_black`| Goku Black | `goku_black_animated_76b37a.fbx`<br>`goku_black_ssr_low_poly_rigged_model_437daa.fbx` | Story / Raid Boss (Super Saiyan Rosé) |
| `boss_buu` | Majin Buu | `fat_majin_buu_34c553.fbx`<br>`kid_buu_a9e9ea.fbx`<br>`majin_buu_lowpoly_for_game_389328.fbx` | Story / Raid Boss |
| `fused_vegito` | Vegito | `vegetto_cf1732.fbx`<br>`vegito_super_saiyan_d5f7ad.fbx` | Potara Fusion (Goku + Vegeta) |
| `fused_gogeta` | Gogeta SSJ4 | `gogeta_ssj4_remade_998352.fbx` | Fusion Dance (SSJ4) |
| `fused_gotenks`| Gotenks | `dragon_ball_z_gotenks_1b3f76.fbx` | Fusion Dance (Goten + Trunks) |
| `guest_gomah` | Demon King Gomah | `demon_king_gomah_dragon_ball_daima_05d952.fbx` | Daima Special Guest Fighter |

### Divine NPCs & Officials
- **Omni-King Zeno:** `zeno_sama_omni_king_60ff10.fbx` (placed in imperial floating box overlooking the ring; laughs/claps on universe wipes).
- **Grand Priest:** `npc_grand_priest` (announces round start, countdown, and eliminations).
- **Whis:** Training master using `whis_staff_265194.fbx` / `whis_staff_db7334.fbx`.
- **Shenron:** `shenron_dragon_ball_96e8ad.fbx` (summoned when 7 Dragon Balls are gathered).
- **Bulma:** `bulma_low_poly_preview_24500d.fbx` / `bulma_v2_10d396.fbx` (cheers from Universe 7 bench).

---

## 3. Environment & Map Architecture

### 1. Tournament of Power (World of Void Arena)
- **Ring Rubble & Broken Pillars:**
  - `altar_ruins_189d92.fbx` & `ancient_ruins_105c85.fbx` placed as perimeter battlements, cracked pillars, and broken central dais.
  - Gives the arena authentic high-stakes anime battle damage rather than plain flat discs.
- **Destruction Physics & Debris:**
  - `free_pack_rocks_stylized_7c60b4.fbx`, `rocks_set2_62ab17.fbx`, and `low_poly_rocks_9823ec.fbx` integrated into `ArenaDamage.DamageAt` and `VFXCommon.DebrisBurst`.
  - When beams gouge the arena, genuine angular Kachi Katchin stone shards scatter, bounce, and fade over 2.5s.
- **Cosmic Skybox & Lighting:**
  - `free_skybox_space_nebula_fa5c19.fbx` and `inside_galaxy_skybox_hdri_360_panorama_96183e.fbx` applied to `Lighting.Sky`.
  - Deep violet-indigo ambient lighting with rim light highlights matching the anime's World of Void.

### 2. Specialized Hub & Training Arenas
1. **Hyperbolic Time Chamber (HTC):**
   - Uses `hyperbolic_time_chamber_cdb861.fbx` / `hyperbolic_time_chamber_ef6155.fbx`.
   - The iconic domed palace with two giant hourglasses resting in an infinite white void.
   - Dedicated for 10x gravity & stamina training drills.
2. **Kame House (Ocean Hub):**
   - Uses `kamehouse_34d497.fbx` / `kame_house_f055f8.fbx`.
   - Master Roshi's pink roof house on a small sandy atoll surrounded by animated water.
   - Serves as the peaceful social hub, character customization area, and sparring ring.
3. **Capsule Corp (Gravity Chamber):**
   - Uses `capsule_corp_adc950.fbx` and `capsule_corporation_spaceship_low_poly_f_3ca2d8.fbx`.
   - High-tech dome for heavy multiplier training (100x to 500x gravity).
4. **Whis's Sacred Training Ground:**
   - Cosmic floating ring with Whis's staff and `training_dummy_3c647d.fbx` / `training_dummy_9465a0.fbx` for onboarding drills.

---

## 4. Gameplay Props & Collectibles Integration

| Prop Asset | Game System | Mechanic & Interaction |
|---|---|---|
| `the_dragon_balls_77baeb.fbx` | WP17: Dragon Ball Hunt | 7 glowing spherical orbs with numbered star decals. Spawn randomly across arena or training grounds. |
| `dragon_ball_radar_540adc.fbx` | WP17: Dragon Radar Tool | Handheld device equipped by player; green radar screen blips and beeps faster when facing nearest ball. |
| `shenron_dragon_ball_96e8ad.fbx`| WP17: Shenron Summon | 3D serpent dragon rises into the darkened sky when all 7 balls are collected, granting wish choices. |
| `scouter_dragon_ball_14e781.fbx`| WP22: Scouter HUD | Saiyan head accessory with colored lens. Reading an enemy over 9,000 Power Level plays the "It's Over 9000!" SFX and triggers a glass-shattering screen VFX. |
| `potara_earrings_dragon_ball_63cc2a.fbx`| WP05: Potara Fusion | Green earrings weld to left ear of Player A and right ear of Player B during `FusionVFX.Potara`. |
| `mafuba_pot_dragon_ball_1692fc.fbx` | Combat / Roshi Kit | Evil Containment Wave trap; traps target inside jar for 4 seconds on successful hit. |
| `training_dummy_3c647d.fbx` | WP11 & WP12: Training | Wooden practice puppet in training zones for M1 combo testing and DPS tracking. |

---

## 5. 3D Mesh-Based VFX Integration

Rather than relying purely on 2D billboard particles, the Sketchfab VFX mesh pack elevates DBZ combat to AAA standards:

- **`heavy_metal_shockwave_f11d94.fbx`:**
  - Replacing procedural Neon parts in `VFXCommon.Shockwave` with 3D stylized shockwave geometry.
  - Scales radially outward with Quad Out easing for beam release muzzles and ground slams.
- **`vfx_explosion_724a95.fbx` & `sparks_explosion_c73eb2.fbx`:**
  - Volumetric 3D explosion burst meshes used for Big Bang Attack, Final Explosion, and Spirit Bomb detonation.
- **`cublosion_79ab69.fbx`:**
  - Anime blocky impact debris used for ground fractures and guard breaks.

---

## 6. Implementation & Ingestion Workflow

To import and activate these assets smoothly into Studio without exceeding performance budgets:

1. **Geometry & Polycount Capping:**
   - Ensure all character rigs have under 10,000 triangles for mobile performance.
   - Enable `Model.LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh` for distant arena ruins and HTC palace.
2. **Standard R15 Rig Structure:**
   - Every character model in `ReplicatedStorage.CharacterModels` must expose:
     - `HumanoidRootPart` (Root BasePart, CanCollide false, Transparency 1).
     - Standard R15 joint naming (`Head`, `UpperTorso`, `LowerTorso`, `LeftUpperArm`, etc.) or welded visual MeshParts to an R15 armature so that `PosePlayer.lua` keyframe sequences play smoothly.
3. **Texture Atlas & Material Optimizations:**
   - Combine character materials into single 1024x1024 diffuse/normal texture sheets.
   - Use `SurfaceAppearance` with roughness and metalness maps for Golden Frieza, Whis Staff, and Scouter glass.
4. **Automated Studio Ingestion:**
   - Models are imported to `ReplicatedStorage.CharacterModels` and `Workspace.WorldOfVoid.Decor`.
   - `CharacterSelectUI.client.lua` automatically reads any new model named matching `Config.ROSTER` IDs (`u7_gohan`, `u7_piccolo`, `u7_17`, `u11_jiren`, etc.) and renders them in the rotating 3D turntable preview.
