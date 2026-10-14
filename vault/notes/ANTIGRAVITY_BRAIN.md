# Antigravity Brain — Dragon Block Z Development

## 1. Project Overview
- **Game Title:** Dragon Block Z
- **Primary Game Mode:** Tournament of Power (Battle Royale up to 40 players across 8 Universe teams)
- **Place File:** `C:\Users\issao\Downloads\Place1.rbxl`
- **Source Code:** `C:\Users\issao\Documents\DBTournament\team\`
- **Obsidian Vault:** `C:\Users\issao\Documents\DBTournament\vault\`

---

## 2. Completed Work Packages (Antigravity Scope)

### WP10: Mobile & Console Controls
- **Script:** `team/gameplay/src/StarterPlayer/StarterPlayerScripts/MobileControls.client.lua`
- **Status:** Complete & Installed in Studio
- **Features:**
  - **Ergonomic Right-Thumb Cluster:**
    - `M1 (Strike)`: Primary 76px attack button with glowing gold stroke.
    - `Heavy (Guard Break)`: 56px break button with red stroke.
    - `Ki Blast`: 54px cyan blast button.
    - `Beam (Kamehameha)`: 58px special beam button.
    - `Vanish (Dodge)`: 52px blue-white glow evasion button.
    - `Dash (Burst)`: 50px rapid movement button.
    - `Block (Guard)`: 56px hold-to-guard button (tap before hit for perfect guard).
    - `Charge (Ki)`: 58px hold-to-charge aura power-up button.
    - `Transform (Form)`: 52px form progression button.
    - `Lock-On`: 48px target toggle button with active red target indicator.
    - `Drink`: 48px Energy Drink utility slot.
  - **Mobile Auto Lock-On:**
    - Automatically sweeps a 40-degree forward cone up to 120 studs when executing attacks or firing beams without a target.
    - Sets `LockTargetId` (for players) or `LockTargetName` (for dev bots) on `LocalPlayer` so camera and attacks automatically snap to target.
  - **Dynamic Beam Struggle Button:**
    - Listens to `ClientAPI.onCombatEvent("StruggleStart")` and displays a large pulsing `MASH!` button at screen center.
  - **Console Gamepad Parity:**
    - M1: `ButtonR2` | Heavy: `ButtonR1` | Block: `ButtonL2` | Dash: `ButtonL1` | Vanish: `ButtonB` | Ki Blast: `ButtonY` | Transform: `DPadUp` | Drink: `DPadDown` | Combo Break: `ButtonL3`.

---

### WP11: Whis Onboarding Tutorial
- **Server:** `team/gameplay/src/ServerScriptService/Modules/OnboardingService.lua`
- **Client:** `team/gameplay/src/StarterPlayer/StarterPlayerScripts/Onboarding.client.lua`
- **Data:** `PlayerData.lua` updated with `tutorialDone` tracking, `PlayerData.completeTutorial(p)`
- **Status:** Complete & Installed in Studio
- **Features:**
  - Automatically triggers for level 1 / first-time players upon spawning in the Lobby.
  - Teleports player to Whis's sacred training ground (`CFrame.new(9000, 102.5, 3060)`).
  - **6-Step Progressive Mastery:**
    1. *Movement:* Walk 30 studs across the arena.
    2. *Basic Combat:* Chain a 4-hit strike combo (M1 x4).
    3. *Evasion:* Execute a Vanish dodge (E).
    4. *Ki Charge:* Hold charge to gather divine aura for 2 seconds.
    5. *Energy Beam:* Unleash a Kamehameha beam (Key 2 / Beam button).
    6. *Sparring Test:* Fight and defeat the Whis Training Dummy (50 HP wood dummy).
  - **Whis Dialogue & UI:**
    - Top-center prompt card with step title, description, and 6 visual progress pips (green = completed, gold = active, grey = upcoming).
    - Whis subtitle dialogue card at bottom-left.
    - "SKIP TUTORIAL" button at top-right for experienced players.
  - **Rewards:**
    - +250 XP
    - +1,000 Zeni
    - 30-Minute 2x XP Boost (`prof.boostUntil = now + 1800`)
    - Smooth teleport back to the Lobby Spawn.
  - **Dev Testing Hook:** Set `workspace:SetAttribute("ForceTutorial", true)` to test on any player anytime.

---

### WP08: Character Select Screen with 3D Preview
- **Script:** `team/gameplay/src/StarterPlayer/StarterPlayerScripts/CharacterSelectUI.client.lua`
- **Status:** Complete & Installed in Studio
- **Features:**
  - **3D ViewportFrame Turntable:**
    - Clones character models from `ReplicatedStorage.CharacterModels` (`u7_goku`, `u7_vegeta`, `u7_frieza`, `npc_zeno`, etc.).
    - Smooth 35 deg/sec turntable rotation with anime lighting (warm key light + cool ambient fill).
    - Dynamic camera distance framing based on model bounding box.
  - **Tier Badges & Tags:**
    - Real-time tier labels with canonical palette (`C`, `B`, `A`, `S`, `GoD`, `Angel`, `GrandPriest`, `Zeno`).
    - Base Power Level display.
    - Level requirement lock tags (`Lv X Required`).
  - **Team Budget & Roster Status:**
    - Team budget tracker (`BudgetUsed/Budget`).
    - Duplicate pick blocking with "PICKED" indicator.
    - "CONFIRM PICK" button.

---

### WP22: VFX & Polish (Anime Quality & Performance LOD)
- **Modules Created:**
  - 	eam/animation/HakaiVFX.lua: God of Destruction erasure with inverted impact frame, dual shockwaves, and ground fracture.
  - 	eam/animation/KaiokenVFX.lua: Goku's crimson multiplier surge with double-layer aura, speed lines, and FOV kick.
  - 	eam/animation/SolarFlareVFX.lua: Tien's Taiyoken blinding flash and smooth screen whiteout fade.
  - 	eam/animation/VFXLODManager.lua: WP22 Performance LOD manager with auto FPS degradation (<30 fps for 5s) and 3-tier aura distance culling.
- **Router & Test Integration:**
  - VFXRouter.client.lua: Mapped new moves and initialized LOD manager.
  - KamehamehaTest.client.lua: Added F6 (Hakai), F7 (Kaioken), F8 (Solar Flare) hotkeys.
- **Documentation:** Full pipeline analysis and subagent prompt documented in [[VFX_PIPELINE_AND_SUBAGENT_PROMPT]].
- **Status:** Complete & Injected in Studio (ReplicatedStorage.VFX now has 30 modules).

---

## 3. Tooling, Plugins & Animation Pipeline

### Animation & Eclipse Animator
- **Eclipse Animator (Moon Animator)** installed in Studio:
  - Used for Battlegrounds-style combat animations: stepped keyframes, impact frames, camera shake, freeze markers.
  - Rigs can be imported from `ReplicatedStorage.CharacterModels` directly into Eclipse Animator.
  - Marker conventions from `POLISH_BIBLE.md`: `hit`, `freeze`, `cam`, `shake`, `iframe`.

### 3D Assets & Environment Pipeline (Sketchfab Library)
- **Asset Library:** 103 high-quality Sketchfab FBX models in sketchfab_out/ and sketchfab/models/ (all CC-BY / Free Standard, attributed in Credits.lua).
- **Comprehensive Master Plan:** Full mapping of all 103 models across the roster, environments, props, and VFX meshes is documented in [[ASSET_AND_ENVIRONMENT_MASTER_PLAN]].
- **Key Mappings:**
  - *Universe 7 Roster:* Goku, Vegeta, Gohan (Kid/Teen/Beast), Frieza (Final/Golden/Black), Piccolo, Android 17, Android 18, Krillin, Tien, Master Roshi.
  - *Rival Universes:* Jiren, Hit, Kefla (Base/Potara), Zamasu, Broly, Goku Black, Majin Buu, Gotenks, Vegito, Gogeta SSJ4, Demon King Gomah.
  - *Arenas & Hubs:* Tournament of Power Altar/Ancient Ruins, Hyperbolic Time Chamber, Kame House, Capsule Corp, Whis Training Ground.
  - *Props & VFX:* Dragon Balls, Shenron, Scouters, Dragon Radar, Whis Staff, Potara Earrings, 3D Mesh Shockwaves, and Explosion meshes.

### Installed Agent Skills
1. `roblox-luau`: Luau type checking, strict idioms, task scheduler.
2. `roblox-datastores`: Session locking, exponential backoff, profile schema migrations.
3. `roblox-building`: Prototyping, parts, terrain, and geometry.
4. `roblox-lighting`: Atmospheric lighting presets, anime color correction.
5. `roblox-luau-patterns`: State machines, service patterns, signal handling.
6. `roblox-game-development`: Game design, engagement loops, combat math.
7. `roblox-gui`: Responsive layouts, safe areas, gamepad focus navigation.
8. `roblox-animation-vfx`: Particle budgets, LOD scaling, combat VFX.
9. `roblox-npc-ai`: AI state machines, distance/FOV/LOS targeting.
10. `roblox-studio-mcp`: Studio bridge workflows.
11. `find-skills`: On-demand discovery of open agent skills.

4. **VFX Testing (KamehamehaTest):**
   - Press F6: Casts **Hakai** at mouse position (dark void sphere, 2-frame inverted screen silhouette, dual shockwaves, purple ground fissures).
   - Press F7: Toggles **Kaioken x10** (surging crimson double-aura, red speedlines, heartbeat light pulse).
   - Press F8: Fires **Solar Flare** (forehead charge, blinding flash, and smooth screen fade).
   - Press F1/F2/F3: Switches Low/Medium/High VFX quality tiers on the fly.
   - Press F4: Cycles through 12 form auras (SSJ through Ultra Ego, Beast, Black Frieza).

---

## 4. Test Checklist for Anwar (Tomorrow)

### In Roblox Studio (Press Play):
1. **Lobby & Mobile Controls:**
   - Verify lobby banner reads `"DRAGON BLOCK Z • Lobby"`.
   - Toggle mobile emulator (Device Simulation in Studio):
     - Verify right-thumb button arc appears (M1, Heavy, Ki Blast, Beam, Vanish, Dash, Block, Charge, Form, Lock, Drink).
     - Tap M1 or Beam near a DevBot: verify auto lock-on automatically acquires target.
     - Hold Block: verify shield stance; Hold Charge: verify power-up aura and stage progression.
2. **Whis Onboarding Tutorial:**
   - In Studio command bar or Attributes panel on `Workspace`, run:
     ```lua
     workspace:SetAttribute("ForceTutorial", true)
     ```
   - Verify:
     - Player teleports to Whis's training ground.
     - Whis dialogue card appears bottom-left; prompt card appears top-center.
     - Complete Step 1 (walk) -> Step 2 (4 strikes) -> Step 3 (vanish) -> Step 4 (charge) -> Step 5 (beam).
     - Step 6: Training dummy spawns; defeat it.
     - Fanfare screen awards +250 XP, +1,000 Zeni, 30-min 2x XP boost, and teleports back to Lobby.
3. **Character Select Screen:**
   - Trigger character select (or set `workspace:SetAttribute("RoundState", "CharacterSelect")`):
     - Verify character grid on left with Tier badges (C/B/A/S/GoD).
     - Click characters: verify right pane displays live rotating 3D model in ViewportFrame.
     - Click "CONFIRM PICK" to lock in warrior.


### WP17: Dragon Ball Hunt & Shenron Wishes
- **Modules:** `ReplicatedStorage.Shared.DragonBalls`, `ServerScriptService.Modules.DragonBallService`
- **UI:** `StarterPlayerScripts.DragonRadar`, `StarterPlayerScripts.ShenronWishUI`
- **Status:** Complete & Verified in Studio
- **Features:**
  - 7-ball weekly hunt per player (seeded positions, 8-stud server validation).
  - Weekly reset on Mondays at 00:00 UTC.
  - Shenron wish ceremony with 60s timer (Zeni, Shenron Aura, titles, outfits).
  - Zero P2W violations: strictly cosmetic/currency rewards, 100% compliant with 1.35x stat cap.

---

### WP-TRAIN-2: King Kai Training Minigames
- **Modules:** `ReplicatedStorage.Shared.KingKaiMath`, `ServerScriptService.Modules.KingKaiGames`
- **UI:** `StarterPlayerScripts.KingKaiGamesUI`
- **Tests:** `gameplay/tests/kingkai_test.luau`
- **Status:** Complete & Verified in Studio
- **Features:**
  - **Bubbles Chase:** 5 rounds, 30s per round, speed scaling by exact +10% per round (`14.0 * 1.10^(r-1)`), touch proximity catch. Reward: +2500 XP and "Monkey Business" title.
  - **Gregory Hammer:** 60s timer, 3D erratic wander path, 0.5s swing cooldown, comic "BONK!" floating animated popup. Reward: +3000 XP and "Cricket Whacker" title on 10 bonks.
  - Registered into `TrainingRooms` drill registry (`CatchBubbles` & `HitGregory`).
  - Unit tests: 100% passed (speed progression, bonk threshold, P2W reward rejection).

---

### WP-HOOK-2: Match Replay Recorder & Best Moments
- **Modules:** `ReplicatedStorage.Shared.ReplayMath`, `ServerScriptService.Modules.ReplayRecorder`
- **UI:** `StarterPlayerScripts.ReplayViewer`
- **Tests:** `gameplay/tests/replay_test.luau`
- **Status:** Complete & Verified in Studio
- **Features:**
  - **10 Hz Ring Buffer:** Records 30s rolling combat telemetry (300 frames per player) across up to 40 players.
  - **Memory Footprint:** Guaranteed <= 2 MB memory footprint (~960 KB for 40 players).
  - **Best Moment Auto-Detection:** Sliding 8-second window identifying peak damage accumulation and max combo finisher.
  - **Cinematic Viewer:** Post-match highlight overlay with animated banner, damage telemetry, and screenshot capture button.
  - Unit tests: 100% passed (ring buffer wrap-around, 8s max-damage window, memory verification).

---

### WP18: Ranked Queue & Matchmaking Foundation
- **Modules:** `ReplicatedStorage.Shared.Elo`, `ServerScriptService.Modules.RankedService`
- **UI:** `StarterPlayerScripts.RankedUI`
- **Status:** Complete & Verified in Studio
- **Features:**
  - **Elo Engine:** Provisional K=32 (first 20 games) then K=20, team average ratings, Grand Priest top-100 gating.
  - **Queue System:** 1v1 and 3v3 solo queue with expanding window (±100 widening +50 per 10s up to ±400).
  - **Team Balancing:** Snake draft on player Elo.
  - **DataStore Sync:** OrderedDataStore seasonal leaderboards, mid-match leaver penalty, and soft season resets.
  - **Ranked UI:** Rank tier badges, Elo/wins/losses counters, live top-100 leaderboard.

---

