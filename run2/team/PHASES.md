# Dragon Block Z — Phase Map

Owner: single agent (Antigravity takeover). Live place: `C:\Users\issao\Downloads\Place1.rbxl` (Studio showed
`Place1_AutoRecovery_0.rbxl`). Source of truth: `team\`. Vault mirror: `vault\team\` + `vault\notes\`.

Status legend: **DONE** = fixed, injected and verified live. **SHIPPED-UNVERIFIED** = written, lint-clean and
injected, but not confirmable in runtime yet. **BLOCKED** = cannot proceed until a dependency is resolved.
**OPEN** = not started.

---

## Phase 0 — Foundation (must hold before any phase can be trusted)

| Item | Status | Evidence |
|---|---|---|
| `install.py` injects what we think it does | **DONE** | Root `install.py` has a `PROTECT=("CharacterSelectUI","MobileControls","Tutorial")` list that **silently skips** those files. Must always run `--all` and grep the log. |
| Injection actually happens | **DONE** | `install.py` reports `exit=0` while injecting **nothing** if Studio is in Play mode (`Edit datamodel is not available in Play mode`). Always stop Play first and grep for `not available in`. |
| Round loop can start a match | **DONE** | Was deadlocked in `Intermission` forever (roster skipped `InTutorial` players -> empty roster). Fixed + verified reaching `CharacterSelect` and `InRound`. |
| Quality gates | **DONE** | `stylua --check` clean, `selene` 0 errors in install scope, `rojo build` exit 0. Verified every batch. |
| Dev flags left set are hazardous | **DONE** | A stale `ForceTutorial` attribute caused the deadlock above. Cleared. **Never leave force/dev attributes set.** |
| Probing module state via MCP | **DONE** | MCP `execute_luau` does **not** share the server scripts' `require` cache, so `require(Module).someTable` returns a *fresh* instance. A probe on this basis produced a false "XP is broken" finding that had to be retracted. **Probe synced player attributes / tags / remote round-trips instead.** |
| `PlayerData` profile registration | **WORKS** | Confirmed via synced attributes: `DataLoaded=true, Level=1, XP=5, XPToNext=70` (exactly `Config.xpToNext(1)`), `Zeni=50000`, `PowerLevel=1050`. No bug. |

---

## Phase 1 — Gameplay

| Item | Status | Notes |
|---|---|---|
| Animation marker pipeline (VFX + sound from clips) | **DONE** | Was 100% dead: `PosePlayer.Play` drops all markers without `opts.Registry`. New `Shared/AnimMarkerRouter.lua` routes 10 `VFXCommon` primitives + 16 module entry points. **Proven live**: pressing Heavy spawned an `Afterimage`. |
| `VFXCommon.KiBlast` | **DONE** | Called 18x by the clips, never defined. Implemented. |
| Champion-specific poses | **DONE** | Everything played `GokuPoses.*`; Vegeta/Frieza clip sets were dead content. Now champion-resolved with a `Shared.clips` roster fallback. |
| Hit reactions | **DONE** | `HurtLight`/`HurtHeavy`/`KO` existed but nothing played them. Wired to combat events. |
| Directional enders | **DONE** | `AirCombo` / `Launcher` clips now used when airborne. |
| Deadlock: server with everyone onboarding never plays | **DONE** | Roster falls back to including first-timers if the tutorial-free roster is too small. |
| Progression curve | **AUDITED** | 1->5 = 383 XP; tutorial gives 250 -> level 3; KaioKen at L5 lands in the first match. Good, left alone. 101->500 tail is ~5-8k XP/level. |
| **XP / level / unlock runtime** | **WORKS** | Verified via synced attributes: XP accumulates, `XPToNext` matches the curve. (An earlier blocker claim here was a probe artefact - retracted.) |
| XP granted by real gameplay | **DONE** | Verified: `XP` rose 5 -> 15 through actual combat input, `XPToNext` held at 70. |
| Intro cutscene pacing | **DONE** | Was 110 s every round with unanimity-skip. Now full intro only while someone has not seen it (`introSeen`), repeats use `INTRO_MAX_REPEAT = 12`, early-out needs a **majority**. **Verified live: caps `[108, 11]` across two rounds.** |
| Match rules, ring-out, beam struggles | Not audited | Existing systems believed working from earlier battle passes. |

---

## Phase 2 — Character & Assets

| Item | Status | Notes |
|---|---|---|
| Character cards show real stats | **DONE** | Cards were "PL 1000" for everyone. Now name, tier, `PL • Race`, and DMG/DEF/SPD bars from `Races` multipliers + tier accent stripe. Screenshot-verified. |
| Aiming crosshair (all 3 platforms) | **DONE** | None existed; only a reticle around an already-acquired target. New `Crosshair.client.lua`. Screenshot-verified. |
| Creator Store sourcing proven | **DONE** | `search_asset` + `insert_asset` driven live. Inserted rock/dummy props into `Workspace.PracticeRange` at Whis Ground. |
| **Character models / appearance** | **BLOCKED ON USER** | Choices: (a) one manual `File > Import 3D` for the 103 licensed Sketchfab models, (b) `generate_mesh`/`generate_texture` originals, (c) Creator Store rigs. **(c) is near-certainly ripped DBZ rigs — `AI_RULES.md` forbids it and it risks a takedown.** `insert_asset` output also comes back `sandboxed:true`. |
| Map / arena / **sky detail** | PARTIAL | Was 4x Sky, 3x Atmosphere, 3x Bloom, 2x ColorCorrection all active at once — consolidated to one of each, 8 duplicates preserved in `ServerStorage.LightingBackup_2026_10_14`. Sky/atmosphere art itself still default. |
| Practice dojo (Goku/Vegeta/Whis stations, aim targets) | **OPEN** | A practice range exists at Whis Ground; the sparring stations and rock-aiming loop are not built. |
| Portraits / card art | **OPEN** | Cards use a tier stripe as a stand-in. Needs either uploaded images or model renders. |

---

## Phase 3 — UI & UX

| Item | Status | Notes |
|---|---|---|
| Tutorial card covering the HUD banner | **DONE** | Card was at y=18 over the banner (y 8..82). Moved to y=96. |
| Whis card overlapping HP bars + skill bar | **DONE** | Was 460x80 at `24,-100`. Now 320x80 at `1,-272`. |
| Tutorial completable on mobile | **DONE** | Steps 2/3/5 read raw input; touch buttons emit no keycode, so they were **uncompletable**. Server now publishes `LastMove`/`MoveSeq`. |
| Tutorial reliably runs | **DONE** | Only fired in the phantom `"Waiting"` state, once. Now queued and fires at the first safe state. |
| Focus mode during onboarding | **DONE** | Controls wall, elimination feed, PlayerList, all left nav, quest panel, and the store all suppressed. |
| Focus mode during CharacterSelect / cutscenes | **DONE** | Extended to `CombatActionUI`, `TrainingUI`, `QuestTracker`, `StoreUI`, `CreditsUI`, `CombatInput`'s reticle, `UIStyle.toggle`. |
| `Store`/`Credits` over the HP panel | **DONE** | Were anchored inside the bottom-left stats panel. Lifted. |
| Console could not play beam/charge/struggle | **DONE** | Touch and keyboard had them, gamepad had none. Added `ButtonX` beam, `DPadLeft` charge, contextual `ButtonA` struggle, `ButtonSelect` stances. |
| Level-up celebration | **DONE** | Was one line in the elimination feed and the client discarded the `unlocks` payload. **Verified live**: level 1 -> 3 on match completion, card showed "LEVEL UP / LEVEL 3 / KI BLAST UNLOCKED". |
| Full gamepad focus navigation for menus | **OPEN** | Character select has some support; other panels are mouse/touch only. |
| Mobile button cluster vs Roblox default touch controls | **OPEN** | Not yet checked for overlap with the default jump/thumbstick. |

---

## Phase 4 — VFX

| Item | Status | Notes |
|---|---|---|
| Dead audio IDs (`Vanish`, `Dash`, `Parry`, `Block`, grunts) | **DONE** | Verified against the Creator Store API: `9114330400` is a *Decal*, the other six return nothing. Replaced with verified free audio. |
| 36 clip sound-marker names resolving | **DONE** | Clips said `Hit_Light`, catalogue said `HitLight`. Added `MARKER_ALIASES` + `resolve`/`playMarker`. |
| `VFXRouter` missing move kinds | **DONE** | Covered 15 of ~40. `"GalickGun"` (broadcast by the Vegeta sparring bot) had no mapping at all. |
| Duplicate arena lighting/post-processing | **DONE** | Two passes used different cleanup tags so neither removed the other. Now one shared tag + legacy purge. |
| Camera intensity | **SHIPPED-UNVERIFIED** | FOV punch was flat per tier, so a 6-hit combo looked like a single jab. Now escalates with the combo. **Feel values need a play-test**: `COMBO_WINDOW 1.2`, `COMBO_FOV_STEP 0.18`, cap 6. |
| Positional hit-cam (dolly toward victim) | **OPEN** | `C.CameraShake` already owns a `BindToRenderStep` CFrame writer; a second writer would fight it. Must be folded **into** `VFXCommon`, not added alongside. |
| Per-move VFX wired to real profiles | PARTIAL | Markers now dispatch. `animation/README.md` notes the pose angles were never viewed on a rig, so poses still need a Studio look. |

---

## Phase 5 — Ship

| Item | Status | Notes |
|---|---|---|
| Store description + authorization text | **OPEN** | Can be written now, no dependency. |
| Icon / thumbnails | **BLOCKED ON USER** | User offered to supply art; needed rather than generated. |
| Trailer from in-game captures | PARTIAL | `screen_capture` works (returns **JPEG**, so saved `.png` files need renaming). Not yet assembled. |
| Store listing metadata, credits, licences | OPEN | `team/audio/LICENSES/README.md` and `Shared/Credits.lua` exist. |

---

## Immediate next step

**Fix the `PlayerData` profile registration bug.** It is the single blocker gating Phase 1 progression, the
Phase 3 level-up celebration, and any confidence in Phase 5 retention claims. Everything else can proceed
independently of it.
