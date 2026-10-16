# Legendary Episodes (v10): how they work and how to add one

Story Mode's main path is **saga episodes**: in-engine cinematics plus player-controlled fights, following the Reborn v4 direction (vault `REBORN_V4_CANON_STORY_EPISODES`). The 32 older missions (`gameplay/StoryMissions.lua`) stay in the [M] panel as **Quick Battles**.

**Status:** code complete for `saiyan_arrival_01`, **partly verified in Studio** (2026-10-16). See the checklist at the bottom: only ticked boxes were seen working.

## Files
| File | Role |
|---|---|
| `src/ReplicatedStorage/Shared/StoryEpisodes.lua` | Pure data: acts, beats (shots + original subtitles), boss kit, objectives, rewards |
| `src/ReplicatedStorage/Shared/EpisodeLogic.lua` | Pure state machine: validate, act order, objectives, checkpoints, skip policy, one-time rewards, struggle outcome. Unit-tested in `tests/episode_tests.luau` |
| `src/ReplicatedStorage/Shared/ShotLibrary.lua` | Client camera grammar: `establishingWide`, `pushIn`, `overShoulder`, `lowAngleReveal`, `skyDrop`, `smashZoom`, `dutchTilt`, `splitClash`, `orbitCharge`, `whiteOut` |
| `src/ServerScriptService/Modules/StoryEpisodeService.lua` | Server authority: arena, actors, acts, KO→checkpoint, save and rewards (`profile.episodes`, schema v10) |
| `src/StarterPlayer/StarterPlayerScripts/StoryEpisodeClient.client.lua` | Cinematics, storm grade + rain, objective HUD, boss HP, clash/grip/charge meters, parry flashes, grab escape, KO and clear cards, Reduce Motion toggle |

Other systems the episode leans on:
- **`BossNPC`**:
  - `def.visual` art from `ReplicatedStorage.CharacterModels`
  - telegraphed melee (`melee.windup`)
  - new specials `Rush`, `KiVolley`, `Grab`, `EnergyWave`
  - `setFrozen`, `minHp`, and the `onDamaged`/`onStrike` hooks
  - ground telegraphs for every special (raids included)
- **`Combat`**:
  - `startBossStruggle` (beam clash and grapple)
  - `isStunned`
  - a vanish signal via `ServerHooks.CombatSignal`
  - raid/story players are exempt from the global Intro/Ending freeze
- **`CutsceneDirector`**: `opts.shots`, `opts.canSkip`.
- **`VFXRouter`**: `KiBlast` now renders a projectile (for players too).

## Episode 1: `saiyan_arrival_01` (about 8 min)
1. Intro cinematic (storm canyon, pod crater, Piccolo).
2. **Training** (checkpoint): land 2 strikes, parry 1 telegraphed jab, vanish once. The guide shows on the first attempt only.
3. Arrival cinematic: meteor landing, smash zoom, Dutch tilt.
4. **Boss phase 1** (checkpoint) down to 50% HP. Raditz's kit, with the counter to each:
   - Rush: parry each flash
   - Ki Volley: keep moving
   - Grab: Combo Breaker [R]
   - Energy Wave: dash sideways

   Piccolo lands chip shots.
5. **Beam clash** (checkpoint): mash V / the button. A win deals 12% boss HP; a loss is a heavy hit and you go again.
6. **Boss phase 2** down to 20% HP.
7. **"Hold him!"** (checkpoint): keep the grip meter up for 7 s while Piccolo charges. If he breaks free, the hold re-arms after 6 s.
8. Special Beam Cannon finisher cinematic, then a short resolution.

**Rewards:** 600 XP, 800 Zeni and the title "Saiyan Arrival" on the first clear; 25% on replays. Quitting or disconnecting pays nothing. A KO respawns you at the last checkpoint with the boss HP restored.

## Adding an episode
1. Append an entry to `StoryEpisodes.LIST` with a new `id` and the next `order`. Unlocks are sequential.
2. Use act kinds `cinematic` / `train` / `boss` / `clash` / `hold`. Mark resume points with `checkpoint = true`.
3. Beats use ShotLibrary names, with `subject` set to `lead` / `ally` / `boss` / `anchor`. Write all subtitle text in **original words**.
4. Run `LUAU=<luau> sh tests/run.sh` (or `luau episode_tests.luau` inside `tests/`). `normalize` must report no skipped entries.

## Studio work (local session with the Roblox Studio MCP)
This part needs Studio, so it can't be done from a cloud session.
- **Characters** (`ReplicatedStorage.CharacterModels`):
  - `u7_goku`: verify the existing entry.
  - `u7_piccolo`: from `sketchfab_out/dragon_ball_z_piccolo_1bcf92.fbx`. It's CC-BY-SA, so add a credit line to `Shared/Credits.lua`.
  - `boss_raditz`: no model exists yet. Kitbash the Saiyan rig: long spiky hair, armour, scouter.

  For a **boss**, the model needs a `Humanoid` + `HumanoidRootPart`. Ally models can be static.

  Strip all scripts from imported assets. Until the art exists, everything falls back to generated rigs.
- **Map (optional)**: an authored canyon `Part` tagged `StoryArena` with `EpisodeId = "saiyan_arrival_01"`, plus pads tagged `StorySpawn`, `StoryBossPad` and `StoryAllyPad` (same attribute). Without it, a canyon is generated on a far instance platform.
- **Rights**: a fan game that uses Dragon Ball characters needs rights clearance before public release (see the vault's v4 notes). Never upload ripped anime footage, audio or dialogue.

## Studio acceptance checklist
- [x] Play Solo: no Output errors; [M] shows LEGENDARY EPISODES above QUICK BATTLES
- [x] All 8 acts play; the cinematic camera returns to the player after each one
- [x] Training counts strikes, parry and vanish; the guide only shows on the first attempt
- [x] Boss telegraphs are visible; parry, Combo Breaker escape and dash dodge all work
- [ ] Clash and hold are player-controlled (PC V, mobile button) and win/lose branches both work *(PC win branches seen; lose branches and mobile buttons not yet)*
- [ ] KO in phase 1, the clash and the hold resumes at the right checkpoint *(phase 1 and phase 2 -> clash seen; KO during clash/hold not yet)*
- [ ] Clear persists across rejoin; replay pays 25%; Leave pays nothing; your previous fighter is restored *(all seen except rejoin: unpublished place has no DataStore)*
- [ ] 2 clients: one in the episode, one in a tournament round, neither affects the other
- [ ] Raid bosses (Broly/Moro) still behave the same, now with ground telegraphs *(Broly runs with telegraphs, but specials now actually fire, so raids are harder; Moro not run)*
- [ ] PvP beam clash unchanged; player Ki Blast now shows a projectile *(Ki Blast VFX + projectile spawn seen in logs; PvP clash needs 2 clients)*
