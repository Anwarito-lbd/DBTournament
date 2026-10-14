---
title: "Dragon Block Z: Reborn — MCP Agent Master Execution Plan"
tags: [dragon-block-z, reborn, agent, mcp, roadmap, execution]
status: READY FOR AGENT TAKEOVER — NO LIVE STUDIO ACTION VERIFIED
date: 2026-10-14
---

# DRAGON BLOCK Z: REBORN — AI AGENT MASTER EXECUTION PLAN
**Version:** 1.0 · **Approved creative direction:** Dual path, personal warriors + legendary fighters · **Build priority:** cinematic combat, emotional anime presentation, stable cross-platform play

> **Mission:** Make the player feel the tension, screams, speed, rivalries, transformation, and impact of an anime martial-arts episode. Implement one exceptional playable fight, then expand into Story, Training, Universe Battles and Divine events.

## 0. Read this before changing ANYTHING

### Sources and their authority
1. **Live Studio DataModel AND working local source repo** are the implementation truth. Neither this packet nor the vault alone proves a system works.
2. Read `team/AI_RULES.md`, current `team/CHANGES.md`, `team/PHASES.md`, `team/gameplay/SPEC.md`, `team/GDD_FULL.md`, `team/animation/README.md`, `team/animation/VFX_QUALITY_BAR.md`, `team/MASTER_PLAN.md`, and latest `notes/DRAGON_BLOCK_Z_REBORN_BLUEPRINT_V2.md` before major changes.
3. The new Reborn blueprint is a **proposal**, not a migration already approved down to every number. Make design conflicts explicit in `DECISION_LOG.md`. Do not silently replace code values from older specifications.
4. Supplied `vault.zip` contains Obsidian planning and changelog files but **not the actual source code**. The user says another agent can access real Studio, plugins and asset files via MCP and local filesystem. The agent must verify this, not assume it.
5. `Reborn_Combat_Prototype_v0_1.zip` is a standalone *isolated prototype*, **not** a drop-in replacement for existing Combat, Net, VFXRouter, RoundManager or PlayerData.
6. The historical local paths in vault docs (`C:\Users\issao\Documents\DBTournament\team`, `C:\Users\issao\Downloads\Place1.rbxl`, `sketchfab_out/`) are **hints only**. Discover actual current source, Studio place and assets.

### Three non-negotiable controls
- **Don't overwrite, reset or publish the live game.** Back up place + source + configs first. Never publish, spend Robux, buy or upload paid assets, overwrite DataStores, delete large folders, or alter live monetization without the user's explicit action/authorization for the specific step.
- **Single writer to Studio** at a time. Parallel read-only specialists are welcome, but one lead integrates code after review to avoid file ownership collisions.
- **Report truth:** label every result `VERIFIED IN STUDIO`, `CODE REVIEWED ONLY`, `DOCUMENTED IN VAULT`, `BLOCKED`, or `PROPOSED`. Never equate a tool invocation with a successful test.

## 1. Architecture and product goals

### One Roblox experience, multiple modes
- Living Hub: warrior creator, roster, mission board, trainers, portal selection.
- Story: first 1–4 player episode, cinematic sequences only when they retain agency, checkpoints and saving.
- Training: mentors, a believable dojo, parry/vanish/ki drills, readable mastery.
- Universe Battles: 1v1/2v2 testing, 4v4 milestone, later scale toward 40 only with performance evidence.
- Divine Realm: event/story-access to destroyers, angels, Zeno guards, Grand Priest, Zeno; no uncounterable erase in ranked.
- What-If: SSJ4/primal branch vs God/Super branch.
- One shared profile across modes, authoritatively saved; never trust teleport payload to grant unlocks. Defer splitting into multiple Roblox places until there is a real need; test teleports in published **test** experience.

### Two equal character identities
- **Custom warrior:** Saiyan, Earthling, Namekian, Frieza Clan initially; Android/Majin later. Appearance and mentor choice, curated technique loadouts, racial utility, unlockable transformations. Standard competitive hurtboxes.
- **Legendary fighter:** Goku, Vegeta, Gohan, Piccolo, Frieza, Jiren alpha targets. Each with a designed role, unique combat timing, own poses/beam, mastery cosmetics, signature forms. Unlock/ownership validation always on server.
- Shared fundamentals: identical authoritative combat state machine, move interface, input semantics and VFX/audio events. Custom and legend do not require two combat engines.
- Competitive fairness: ranked normalized core stats, short readable telegraphs, bounded casual stat gaps; the vault rule is ≤1.35× (review actual formula). No paid exclusive unstoppable attacks.

### Combat quality pillars
1. Control responsiveness BEFORE spectacle: test with effects turned off.
2. Distinct anticipation → impact → aftermath; do not spam every effect at once.
3. Cinematic components that never steal controls in ranked or hide hitboxes.
4. One camera director owns camera CFrame/FOV, including shake/hitcam.
5. Server validates damage, range, enemy state, cooldowns, resource, stun and invulnerability.
6. Cross-platform semantic input layer: PC, touch, gamepad. All gameplay and tutorial checks recognize server-accepted actions.
7. Distinct original licensed audio and a reduced-motion/photosensitivity setting.
8. Budget debris/particles and use local effect pools/LOD for mobile.

## 2. MCP and plugin tool contract

Use **official built-in Studio MCP** when available (current docs: https://create.roblox.com/docs/studio/mcp). The historical vault references `StudioMCP.exe`; it may be a different toolset and must be inventoried, not assumed equivalent.

### Setup / verify
A. In Studio: **Assistant → … → Manage MCP Servers → Enable Studio as MCP server**.
B. Prefer the quick-connect for the agent client; otherwise copy Studio's published stdio config (do not invent host ports).
C. `list_roblox_studios` → identify the right place, `studio_id` and play/edit state; pass `studio_id` on every Studio call.
D. `get_studio_state` + read-only `search_game_tree`, `inspect_instance`, `script_search`, `script_read`; run a non-mutating `execute_luau` only in a documented valid `datamodel_type` context to verify privileges.
E. Enumerate exact accessible tool names and any tool schema. If a tool is absent, use an equivalent proven route or mark the task blocked; do not fabricate calls.

### Verified official tool families (discover actual args at runtime)
- Discover: `list_roblox_studios`, `get_studio_state`, `search_game_tree`, `inspect_instance`, `script_search`, `script_grep`, `script_read`
- Write: `multi_edit` (Edit datamodel), `execute_luau` with appropriate `datamodel_type`
- Assets: `search_asset`, `insert_asset`, `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished`, `store_image`, `upload_image`
- Tests / evidence: `start_stop_play`, `get_console_output`, `character_navigation`, `user_keyboard_input`, `user_mouse_input`, `screen_capture`, `subagent` (explore/playtest)
- Docs: `http_get`, `skill`

**Avoid mutable reads in Play mode.** Old vault confirms `install.py` can return exit=0 while injecting nothing when Studio is playing. Ensure Edit state and compare Studio scripts after any installation. `install.py --all` was necessary for protected names historically; verify script behaviour, inspect output, and do not use it blindly.

### Plugins and local pipelines
The vault *historically* mentions Eclipse Animator, AnimationClipEditor, MaterialGenerator, Blender MCP, Rojo, StyLua, Selene and a set of agent skills. **Check what is actually installed**, its version, permissions and current project compatibility.
- Use animator plugins for authored R15 motion (keyframes + markers), not generic procedural poses as the final art.
- Use Studio materials and VFX tools to create original authored textures/geometry; optimize for client LOD.
- Rojo + source repo should remain source-of-truth when available. Prefer source-file edits and a reproducible sync; use MCP for live verification and carefully scoped Studio changes.
- If Blender MCP is available, import/repair original licensed rigs in a staging asset place before injecting into gameplay. No assumption of working socket or exporter.
- Never install new third-party plugins or scripts simply because their listing looks helpful. Review maintainer, exact requested permissions, script contents and trust.

## 3. Mandatory execution loop per task

For **each** task, follow exactly:
1. **DISCOVER** — read relevant source, existing instance state, current specs and prior test failures. Describe dependencies.
2. **PLAN** — state smallest file diff, instance changes, rollback, intended player behavior and acceptance criteria.
3. **BACKUP** — save local checkpoint/commit + copied `.rbxl`/`.rbxlx` before the first mutation in a task group.
4. **IMPLEMENT** — one small atomic diff; no mass rewrite; use typed `--!strict` new Luau modules, cleanup of connections, no `wait()`.
5. **STATIC QA** — `stylua --check`, `selene`, `rojo build` (if present), review compiler output, verify remotes and API use. The repo's documented commands are hints, inspect actual scripts before invoking.
6. **STUDIO SYNC** — stop Play; sync only intended modules; read them back using `script_read` and compare expected changes. Verify the script is enabled in the correct context.
7. **RUNTIME TEST** — solo and 2-client for combat; use action simulation, events/attributes, logs, screenshots. Test adverse paths, not only happy flow. A fresh `execute_luau require(Module)` may instantiate a DIFFERENT module state; inspect replicated Attributes/real remote round-trips instead.
8. **VISUAL/UX REVIEW** — screenshot actual player viewpoint, evaluate scale, material, silhouettes, readability, camera composition and reduced-effect mode; do not accept "no errors" as finished presentation.
9. **CROSS PLATFORM** — PC, mobile touch simulation and real-device review later, gamepad menu navigation and full tutorial completion.
10. **REPORT + COMMIT** — write `CHANGES.md` with screenshots/log references, exact files/instances changed, before/after, metrics, test outcome, pending failures. Mark TASK_BOARD checkboxes and update vault mirror only after source-of-truth updated.
11. **ROLL BACK IF FAILING** — preserve baseline before trying another fix. Don't layer changes onto an untrusted diff.

Write compact daily notes; proceed to next *approved milestone within stated scope* if all gates pass. Stop and request a decision for irreversible actions, new paid assets, publicity, IP licensing ambiguity, major product changes or unexpected migration risk.

## 4. Sequential build phases (deliverables, dependencies and gates)

### PHASE 0 — Reconnect, backup, truth audit (first mission; absolutely mandatory)
**Tasks P0.1–P0.8**
- Select the correct Studio instance/place with `list_roblox_studios`; record `studio_id`, current editing/play state and currently loaded place. If none connected, halt mutations and provide setup instructions.
- Find latest local source repo, Rojo mapping, installed plugins, `install.py`, lint tools, asset folders, existing private place backup. Check for external agent edit collisions.
- Create dated backup and source commit/zip; do not treat a `.rbxl` autosave as sole backup.
- Inspect (not overwrite) `Combat`, `Combatant`, `Net`, `ClientAPI`, `CombatInput`, `PosePlayer`, `AnimMarkerRouter`, `VFXRouter`, `VFXCommon`, `GameFeel`, `CameraShake`, `PlayerData`, `RoundManager`, `OnboardingService`, `CharacterSelectUI`, `ArenaDamage`.
- Inventory all combat remotes, who owns player movement, all camera writers, animation/hit marker hooks and current NPC rigs. Search for duplicate listeners and old placeholder scripts.
- Check runtime using 2 players: spawn, tutorial, melee, block/parry, vanish, beam, transform, a round, ring-out, progression reward, persistence (on a safe test account/place). Capture output/attributes and images.
- Record a current **baseline visual quality** score using actual screenshots: skyline, dojo, character model, combat camera, VFX, mobile HUD.
- Reconcile contradictory vault material. Example: `team/PHASES.md` ending says "fix PlayerData registration" although its opening table marks PlayerData **WORKS**; newer dated `team/CHANGES.md` has real XP/level-up evidence. Do not reintroduce a fixed bug.
**Deliverables:** `AUDIT_2026-10-14.md`, `SYSTEM_MAP.md`, `PLUGIN_INVENTORY.md`, `ASSET_REGISTER.csv`, baseline screenshots/logs, `DECISION_LOG.md`, confirmed backup paths.
**Gate:** existing place still runs, no changes made to prod, can explain which source maps to each Studio instance and prove 2-player baseline or document block.

### PHASE 1 — Two-fighter combat vertical slice
**Scope:** an isolated training/duel sandbox *inside a copy* of the existing game; Goku and Vegeta fighting styles and optional custom Saiyan stand-in.
- Decide actual M1 chain length by inspecting code; source vault says current 4-step vs 6-hit intended. Keep reliable hit timings and make **six-hit only if suitable after testing**.
- Audit intent→server authority→combat state→damage event→pose markers→VFX/audio→camera.
- Fix duplicated effect firing, lock-on, range, cooldowns, combos, recovery and hitstun. One server move state machine, no parallel prototype remotes in the final place.
- Implement distinctive Goku/Vegeta baseline kit: neutral jab sequence, heavy / launcher, vanish, parry/guard, ki blast, Kamehameha/Galick Gun or original-inspired equivalents where needed.
- Tune hit-confirm audio/visual with VFX disabled first; then enable restrained impact effects.
- Build reliable 1v1 test arena and dummy profiles, use damage and ki instrumentation.
**Gate:** 2 clients can play 10 consecutive short rounds; server health/ki match client display; no client-forged damage/cooldowns; 0 new Output errors. Evidence includes combat video or screenshots plus logs.

### PHASE 2 — Cinematic feel (signature feature)
- Real animation art pass on **R15** unless current project proves another canonical rig. Verify keyframe poses on actual rig, both player and opponent, not just successful playback.
- Marker taxonomy: `windup`, `hit_open`, `hit_close`, `whoosh`, `impact`, `freeze`, `shake`, `vfx`, `recover`. Adapt to existing `AnimMarkerRouter` rather than replacing it; **only server decides damage timing**, client markers visual only unless independently validated.
- One camera service handles lock-on, dynamic FOV, camera shake, directional hitcam and cutscene blends. No stacked CFrame writers; restore camera when interrupted/respawned.
- Goku/Vegeta signature beam choreography, cancel rules and **actual 1v1 beam clash** with timed pulse input. Competitive input max validated server-side; no client-selected winner.
- 2 transformation tempos: 2–3s interruptible match-use, 5–8s story version with genuine buildup/scream/release and opponent agency.
- Original audio registry, assets source notes, category mixer, accessible volume and intensity options. Do not use ripped Dragon Ball audio.
- VFX LOD: low/medium/high budgets and effect pooling, rate limits, debris cap, distant effects reduced or omitted.
**Gate:** screenshots/clip show emotion, effects not occluding enemy; reduced-motion toggle works; beam cannot be exploited; no duplicate camera script fights; 2-player test survives rapid interrupts.

### PHASE 3 — Dual-path characters + progression
- Audit PlayerData schema and migration **before** editing. Create migration tests and backup, avoid data loss.
- Add `SelectedIdentity` (`Custom` / `Legendary`), `CustomWarriors`, `UnlockedFighters`, `FighterMastery`, `FormsUnlocked`, `StoryFlags`, `TutorialFlags` behind an explicit schema migration or sidecar safe default.
- Existing IDs `u7_goku`, `u7_vegeta`, `u7_gohan`, `u7_piccolo`, `u7_frieza`, `u11_jiren` retained when present; no silent renaming.
- Custom start races: Saiyan, Earthling, Namekian, Frieza Clan. Three style identities; ability loadout validation server-side.
- Champion selection: roster ownership and 1-of-each-per-team rules validated server-side, preserving lore universe IDs.
- First-alpha roster: two **fully finished** fighters before adding the other four; every kit animation/VFX/audio/test complete.
- Proposed forms: SSJ→SSJ2→SSJ3→SSJ4 primal and SSJ→God→Blue→later divine. No SSJ4 as "always better" than Blue. Add special racial equivalents later.
- Ranked normalized, casual advantage within current documented power cap. Monetization only cosmetics/convenience after policy review.
**Gate:** switch custom⇄legendary, join/rejoin and preserve data; restricted forms cannot be requested via forged remote; two builds balanced in duel.

### PHASE 4 — The opening 5 minutes + Training
- Keep and audit existing Whis tutorial and `OnboardingService`; don't rebuild tested logic. The vault reports touch completion bugs were fixed; re-verify.
- Rework opening **flow, art and rewards**: spawn with immediate agency; practice movement, melee, vanish and ki; mini-boss; first **guided awakening**; choose next mode. More play, less waiting.
- Goku/Vegeta sparring stations, breakable rock aiming drills, ki-charge cues, readable tutorial prompts.
- PC/touch/gamepad full reachability. Include safe-area checks, console focus, no overlapping default mobile buttons.
- Use **first-minute telemetry**: join→first move, first hit, first vanish, first transformation, tutorial finish, first voluntary mode choice. Do not use manipulative paywalls.
**Gate:** a newcomer can complete with no explanation on all supported inputs; no involuntary 100-second waiting; clear HUD; user reviews actual screenshots.

### PHASE 5 — First story episode
- Build a single coherent original-warrior episode (mentor→challenge→boss→emotional climax→earned ability), plus optional legendary character perspective.
- Adaptive NPC AI state: readable attack tells, punish windows, no unavoidable one-shots.
- Story director separate from combat engine, input preserved on skip, checkpoints restored after reconnect.
- Narrative cinematics are shorter in replay, skippable and camera-safe.
**Gate:** complete episode solo and co-op without soft lock, repeat skips work, saved flags persist.

### PHASE 6 — Universe Battles
- Reuse existing RoundManager/Arena/TeamAssignment/Party/Queue/CharacterSelect; check recent round-loop fixes.
- Start with 2v2 test, 4v4 production milestone; ring-out, team roles, spectator, match timeout, tie resolution, end rewards.
- PvP fairness: no instant Zeno erase in ranked; 1 legendary instance per team, custom allowed with normalized stats.
- Destructible terrain is server-certified gameplay, client effects; no flood of physics debris.
- Profile with realistic device budgets before >8 players; 40 players remains long-term target.
**Gate:** 4v4 stable, no double rewards, no invalid ring-out, no team selection duplication, mobile FPS stays within tested budget.

### PHASE 7 — Divine Realm + What-If progression
- Add divine figures with explicit gameplay boundaries: Beerus/Champa/etc as special fighters; Angels as NPC mentors first (current vault D5) until *explicit redesign decision* authorizes playable angels. Zeno, Grand Priest, and guards only narrative/limited events by default.
- God trials, Angel counter/evasion training, themed original abilities, story encounters. Zeno erase never unrestricted in ranked.
- SSJ4 story trial and god-ki progression branch with lore/story prerequisites, meaningful skill challenges rather than pure XP grind.
- Confirm legal/IP clearance before distributing recognizable characters/models/audio publicly.
**Gate:** abilities fair within mode, asset provenance verified, explicit event rules displayed.

### PHASE 8 — Launch quality, performance, retention
- Device and server profiles, network stress, accessibility, UI localization readiness, creator credits, moderation, anti-cheat, cleanup, release config.
- Profile low-end physical mobile, not Studio emulator alone; VFX quality tiers; memory/particle/beam stress tests.
- DataStore migration rollback/retry and no writes in dummy staging place.
- Remove debug/test flags, unapproved plugins, dummy purchase IDs and dev powers; user reviews store, monetization, thumbnails/trailer.
- Publishing is **manual approval gate**.
**Gate:** full regression suite passes + documented playtest signoff; only then discuss public publish.

## 5. Engineering boundaries / minimal module map

Try to fit this into the ACTUAL project, not blindly impose a new structure.

- `ServerScriptService/Modules/Combat.lua`, `Combatant.lua`: authoritative hit/damage/state
- `Modules/Net.lua`, `RateLimit.lua`: remote schemas and limits
- `Shared/Config.lua`, `StatResolver.lua`: numbers, balance and mode modifiers
- `StarterPlayerScripts/CombatInput.client.lua`, `MobileControls.client.lua`: semantic input
- `Shared/AnimMarkerRouter.lua`, `PosePlayer.lua`: poses and marker visuals
- `VFXRouter.client.lua`, `VFXCommon.lua`, `GameFeel.client.lua`, camera owner: spectacle
- `PlayerData.lua`: schemas, migrations, transaction integrity
- `RoundManager.server.lua`, `ArenaDamage.lua`, `TeamAssignment.lua`: battle flow
- `OnboardingService.lua`, `Onboarding.client.lua`: first-five-minute progression

**Do not create a second `ProcessReceipt` owner, a second combat damage service or a second camera CFrame writer.**

## 6. Assets + licenses pipeline (quarantine first)

The vault references **103 Sketchfab model exports** and downloaded assets. The archive does **not** contain these `.fbx` files. Verify they exist at actual local paths before saying they are usable.

Pipeline: locate files → hash/deduplicate → per-file license and rights evidence → malware/script scan → import into sandbox staging place → verify rig R15, textures, normals, scale, collision and animation compatibility → optimize LOD → record attribution and asset ID → approve into game.

**Crucial:** CC-BY/CC-BY-SA/Free Standard claims on Sketchfab are NOT proof that the uploader had rights to Dragon Ball's underlying character designs. Do not publish/monetize those recognizable characters without suitable IP rights. Use original-inspired placeholders for public-safe staging where necessary.

Creator Store search should prioritize **generic, licensed-safe environment props**. Any inserted model with scripts stays quarantined/sandboxed until audited. Never trust obfuscated Scripts, unusual `require(assetId)` or hidden external loading. Obtain human approval before importing unknown complex scripted assets.

For each asset keep: origin URL, creator/uploader, license text and capture date, ownership verification, modification rights, attribution, file hash, import method, Studio asset ID, safety scan, polygon/material count, performance tier, visual acceptance, IP status.

## 7. Subagent decomposition (optional)

**Lead / Studio Integrator:** sole Studio writer; controls branch, imports, playtests and commits.
**Combat specialist:** review only in Phase 0, then scoped `Combat/Combatant` assignments.
**Animation/VFX specialist:** rig/marker/camera architecture and visually grounded test frames; does not edit Combat.
**Asset/art specialist:** inventory/licensing, safe staging, dojo/arena visual target; cannot inject unapproved models into live place.
**UI/UX specialist:** platform controls/HUD/tutorial flow, not the combat server.
**QA/Security specialist:** exploit scenarios, mobile+console, screenshots, before/after, perf.

Parallel workers receive the same project constraints, tool boundaries and disjoint files. No one directly edits the main Studio place except the integrator. Report discoveries and proposed diffs; the lead merges after tests.

## 8. Definition of done — no fake completion

For each milestone report:
- Source revision/commit, original and updated file paths + Instance paths
- `studio_id`, studio/place file name and current test state
- test clients, input sequences and observed expected state
- console errors/warnings, relevant player replicated attributes/remote acknowledgment
- screenshots of *actual running Studio* (not concept art)
- FPS/memory/latency or "not measured" (never fabricated)
- asset license/credit updates
- status label: `VERIFIED IN STUDIO`, `CODE REVIEWED ONLY`, `BLOCKED`, `PROPOSED`
- rollback instructions, unresolved defects, next single task

See `TASK_BOARD.md`, `MCP_TOOL_RUNBOOK.md`, `ASSET_REGISTER_TEMPLATE.csv`, `FIRST_MISSION.md`.

## 9. Existing known hazards to audit without re-breaking fixes
- `team/PHASES.md`: `install.py` once exited 0 even when nothing installed because Studio was in Play. Always stop Play, read tool output and compare scripts back.
- `team/PHASES.md`: a probe of `require(PlayerData)` in MCP obtained a fresh require cache and falsely concluded player profiles were missing. Use actual replicated player attributes and round-trips.
- `team/CHANGES.md`: intro formerly 110 s on every round; latest verified fix is 12-second repeat after majority skip. Preserve this.
- `team/CHANGES.md`: existing marker router repairs (521 keyframes / 99 clips) and ability to use champion-specific clips should be preserved but poses still require human visual inspection.
- `team/PHASES.md`: duplicates of Sky, Bloom, ColorCorrection were cleaned and backed up; future art pass should NOT add duplicates.
- Source vault conflicts: early docs say 1–100, later GDD/Config prefer 1–500; some older design suggests playable Angels, `team/MASTER_PLAN.md` says NPC-only at launch. Log and resolve rather than silently flip.

## 10. Reporting template

```
MILESTONE: P0.x / P1.x
STATUS: VERIFIED IN STUDIO | CODE REVIEWED ONLY | BLOCKED | PROPOSED
STUDIO: <studio_id, place>
BACKUP: <exact paths / commit>
CHANGED: <paths + intended behavior>
TOOLS USED: <successful tool names>
TESTS: <inputs, expected/observed, clients, logs, screenshots>
SECURITY: <server checks / exploit tests>
ASSETS: <IDs, provenance / pending>
PERFORMANCE: <actual measured metrics or unmeasured>
ROLLBACK: <actions>
NEXT TASK: <single prioritized item>
BLOCKERS / OWNER DECISIONS: <only genuinely necessary items>
```

## Documentation references
- Roblox Studio MCP: https://create.roblox.com/docs/studio/mcp
- Studio plugins: https://create.roblox.com/docs/studio/plugins
- Security, client/server boundary: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Third-party asset risk: https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities
- Performance design: https://create.roblox.com/docs/performance-optimization/design
- IP policy: https://create.roblox.com/docs/production/publishing/ip-guidelines

> **Do Phase 0 now.** Once the real sources and Studio scripts are inspected, reprioritize only based on verified evidence—not guesses. Then proceed P1 without asking about decisions already made here.
