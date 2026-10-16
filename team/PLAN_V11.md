# Plan v11: from a working Episode 1 to the full Reborn look and feel

Status: **approved 2026-10-16**, Style B. Nothing below is built yet unless marked DONE.
Every step follows the same loop: **build → Studio play-test with screenshots → fix → you review → commit.**
A step is only "done" when it was seen working in Studio, never because the code looks right.

## Ground rules (from your brief and the v4 vault)
- **Story "1 to 1":** we follow the anime's arcs, turning points, battles and iconic shot compositions,
  recreated in-engine. Subtitles are written in our own words. No ripped footage, frames, music or voice,
  and no verbatim script lines. This keeps the option to ship; Dragon Ball rights still need clearance
  before any public release.
- **Screams / voice:** only original recordings or licensed packs. The plan adds VO *hooks* (cue names per
  move/emotion) so real audio drops in later.
- **Third-party assets:** scripts stripped, no `require(assetId)`, no `loadstring`, license recorded in
  `sketchfab/models/CREDITS.md` + `Shared/Credits.lua`. Creator Store items from impersonating accounts
  (e.g. "Roblox" padded with invisible characters) are never inserted.
- **Concept art in the vault** (`assets/reborn_concepts`) is AI-generated art direction, not gameplay.
  We use it as the quality target for skies, maps and lighting, not as in-game screenshots.

## Art style: DECIDED 2026-10-16, Style B (Roblox-anime R15 avatars)
Changed from A to B the same day ("since it's Roblox"). Consequences: every fighter is an R15 rig with
anime hair, face and outfit (accessories, layered clothing or MeshParts), matching the concept art and the
existing `AvatarSlots` anime style. The Sketchfab models become **likeness references**, not imports
(this replaces the old "import the Piccolo FBX" task; Piccolo becomes an R15 build like everyone else).

Original options considered:
The local library has ~60 anime-proportioned 3D models; the vault concept art shows Roblox block-style
fighters with anime hair. Mixing both looks incoherent, so pick one:
- **A. Anime-model style:** imported skinned MeshPart rigs (Sketchfab), closest to the show, heavier on
  mobile, needs a Blender retarget per character.
- **B. Roblox-anime style:** R15 avatars with custom anime hair, faces and outfits (the concept-art look),
  light and consistent, easier to animate, less like the show.

## Phase 1: finish Episode 1 (`saiyan_arrival_01`)
DONE so far (verified in Studio): [M] panel order, intro → training → arrival → phase 1, objectives,
parry / Combo Breaker / dash counters, KO → checkpoint with boss HP restored, camera return, specials
firing, tournament overlays gated off the episode. Remaining:
1. **Bug:** Raditz died during phase 1 despite the HP floor, so the clash had no boss. Find the damage
   path that bypasses `minHp` (evidence first), fix, add a guard so a boss act can never advance into a
   clash/hold without a boss.
2. **Bug:** main HUD's "Next match in" banner overlaps the episode title; hide round-only HUD pieces for
   `InRaid` players, keep HP/Ki/moves bar.
3. Play acts 5–11: clash (win + lose branch), phase 2, hold (win + break-free), Special Beam Cannon
   finisher, resolution, clear card.
4. Persistence: clear survives rejoin (`profile.episodes`, schema v10), replay pays 25%, Leave pays 0,
   previous fighter restored.
5. Difficulty: today the autopilot is KO'd every ~20 s while Raditz barely drops. Measure damage taken
   by source and dealt per minute, then tune `StoryEpisodes.lua` (boss hp, special damage/cd, clash and
   hold `bossRate`) for an ~8–10 min first clear by an average player.
6. Regressions with a 2-player local server: tournament round alongside an episode, Broly/Moro raids
   (now with working specials: check they are still fair), PvP beam clash, player Ki Blast projectile.
7. Lighting re-check (storm grade + clouds), then tick only the boxes seen working in `EPISODES.md` and
   update `CHANGES.md` (VERIFIED vs unverified).

## Phase 2: characters (after the style decision)
1. **Registry:** `CharacterVisualRegistry` (data only): id, model, rig type, scale, form variants,
   animation set, portrait, author credit, license, approval status. Missing art falls back safely.
2. **Per-character sourcing comparison (before any import).** For each character, compare the parts we
   can build or reuse (our Blender hair/outfit pipeline, existing `CharacterModels`, `AvatarSlots` styles)
   against the best online candidates: Creator Store hair/accessories/outfits from verified,
   non-impersonating creators, UGC items, and reputable marketplaces; use the Sketchfab models and online
   art as likeness references. Score each on: likeness to the show, art-style fit (A/B),
   rig quality (bones, weights, R15 retarget), textures, tri count / mobile cost, license and credit
   terms. Output: one comparison sheet per character (side-by-side renders + scores + links), you pick or
   approve the winner, then it goes through the pipeline below. Nothing is downloaded or inserted without
   your OK for that item.
3. **Local library baseline** (previews reviewed 2026-10-16; usable unless noted):
   - Goku: `goku_rigged_animated_3ed060` (base), `goku_super_saiyan_c2cff8`, `goku_ssj_blue_e4f2ec`,
     `goku_ultra_instinct_3bf8a4`. Broken: `goku_1b2295`, `son_goku_026e34/4f8914` (no textures).
   - Vegeta: `vegeta_from_dragon_ball_textured_and_rig_41a0b4`, `the_saiyajin_vegeta_582b18`,
     `vegeta_ssj_god_52eb94`. Broken: `dragon_ball_vegeta_64400d`, `vegeta_mui_ultra_ego` (no texture).
   - Piccolo `dragon_ball_z_piccolo_1bcf92` (CC-BY-SA), Gohan `gohan_70a9fc` / `gohan_super_saiyan_8a133b`,
     Krillin, Trunks, Frieza `freezer_final_form_ed2a69`, Android 17/19, Broly `dragon_ball_zbroly_eafcd3`,
     Kid Buu, Fat Buu, Hit, Jiren, Zeno. Broken: `golden_frieza_315f9a` (pixel art),
     `frieza_emperor_84fa59`, `bulma_v2_10d396`.
   - **Raditz:** no model exists. R15 rig with very long spiky black hair, dark Saiyan armour and a
     scouter (accessories/MeshParts built in Blender), Humanoid + HumanoidRootPart.
4. **Per character pipeline** (Blender MCP + Studio): build/fit hair, face, outfit pieces on the R15 rig →
   check scale/tri count → export → Studio import (File → Import 3D needs one click from you per batch, or
   computer-use with your OK) → strip scripts → place in `ReplicatedStorage.CharacterModels` →
   test idle/run/jump/block/combo/vanish/beam/hit-react in the episode storm lighting → screenshot sheet.
5. Batch order: Goku, Piccolo, Raditz (Episode 1) → Vegeta, Nappa (Episode 2) → the rest by saga.

## Phase 3: Universe Battle character cards
Reference takeaways: a grid beats a long scrolling list; fold transformations into the base fighter's
card (form toggle) instead of separate slots; cards need real artwork, not icons.
1. Card spec: portrait (in-engine render of the real model, rim-lit), name, universe badge, tier frame,
   3 signature-move chips, form pips, lock/cost state. Sizes for phone, tablet, desktop.
2. Portrait pipeline: render each approved model in a fixed Studio "photo booth" (same lens, light,
   background) so all cards match.
3. Select screen: grid with search/filter by universe, focused-card detail panel with live 3D model
   (ViewportFrame), keyboard/gamepad/touch navigation, readable contrast, reduced motion.
4. Hook into the existing `CharacterSelectUI` / `Combatant` pick flow (no second source of truth).

## Phase 4: maps and skies (concept-art quality bar)
1. Saiyan canyon arena from the rock packs (`free_pack_rocks_stylized_*`, `low_poly_rocks_*`,
   `rocks_set2_*`) with a smoking pod crater; tags `StoryArena` / `StorySpawn` / `StoryBossPad` /
   `StoryAllyPad` + `EpisodeId`; adjust `ShotLibrary` offsets on the real map.
2. Sky pass per area: skybox, clouds, atmosphere, sun/rays, floating islands and distant set pieces for
   World of Void and the training grounds (targets: `story_960x540`, `divine_960x540`).
3. Performance budget per map (parts, tris, lights) checked on a mobile emulation.

## Phase 5: combat feel (destruction, emotion, combos)
1. Audit the existing animation/VFX modules (`team/animation/*`, VFX quality bar) before adding anything.
2. Combo animations: chainable strings with contact frames, hit-stop, camera kick, launch → air combo →
   ground slam, clean cancels.
3. Destruction: crater/debris/terrain scars from heavy hits and beams through `ArenaDamage`, capped for
   performance, cleaned per round.
4. Emotion: face swaps (angry/scream/hurt), power-up cut-ins, aura escalation, VO cue hooks per moment.

## Phase 6: transformations that feel great
Cinematic per form (short, skippable, camera-safe), visual escalation (hair, aura, lightning, ground
pressure), and a satisfying unlock path tied to existing progression. Forms stay server-authoritative.

## Phase 7: next canon episodes
Episode 2 (Saiyan battle: Nappa / Vegeta, Kaio-ken pressure, energy exchange), then Namek/Frieza, using
the same episode pipeline, each through the full Phase 1 checklist.

## Phase 8: release gates
Rights clearance for Dragon Ball characters/story, every third-party license recorded, no ripped media,
mobile FPS/memory pass, 2-client regression, DataStore save/load on a published test place.
