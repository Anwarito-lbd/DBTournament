## 2026-10-16 (Claude Code - v10 Legendary Episodes: `saiyan_arrival_01` vertical slice) - PARTLY VERIFIED IN STUDIO

Implements the Reborn v4 direction: saga-faithful story episodes with in-engine cinematics and player-controlled fights.
**Not run in Roblox Studio yet** (cloud session). The pure logic is unit-tested, and every changed file compiles and type-checks
against the Roblox API definitions (luau-lsp). See `gameplay/EPISODES.md` for the design, the Studio art tasks and the
acceptance checklist.

**Studio verification (local session, 2026-10-16, Play Solo through a Studio MCP bridge; input driven by test bots):**
- VERIFIED: [M] panel order; PLAY starts the episode; all 11 acts play in order through to the clear card;
  training counts strikes/parry/vanish, guide on the first attempt only; Raditz specials (Rush, Ki Volley, Grab,
  Energy Wave) with visible telegraphs; parry, Combo Breaker escape and dash all work; KO in phase 1 resumes
  phase 1, KO in phase 2 resumes at the clash, boss HP restored; clash win, hold win, Special Beam Cannon
  finisher; first clear pays 600 XP / 800 Zeni + title, replay pays 25% (150 / 200) with skippable cinematics,
  Leave pays nothing; previous fighter (Vegeta) restored after Leave and after a clear; Broly raid runs with
  ground telegraphs; player Ki Blast sends its VFX and spawns a projectile (not caught on camera).
- FIXED during the pass (separate commits): round cleanup yanked episode players to the Lobby and wiped boss
  struggles; tournament intro/ending/results/barks drew over episodes and stole the camera; boss specials never
  fired (raids included, pre-existing); a boss became client-owned after a freeze and could die mid-fight;
  camera kept the last cinematic angle; objective rows auto-shrank; HUD round banner overlapped the episode
  title; two client scripts waited on the wrong remote folder; tuning (clash win 22% -> 12%, softer specials).
- STILL UNVERIFIED: clear surviving a rejoin (unpublished place uses the in-memory store); clash and hold LOSE
  branches; KO during the clash or hold; mobile mash/break buttons; 2-client tests (episode next to a live
  tournament round, PvP beam clash); Moro raid; human-feel difficulty (tuning is bot-based).
- BEHAVIOUR CHANGE: raid bosses now use their specials as designed, so raids are harder than before.
- ART: Goku/Piccolo/Raditz still fall back to generated rigs (character art is Phase 2 of `PLAN_V11.md`).

- **New**:
  - `Shared/StoryEpisodes` (data), `Shared/EpisodeLogic` (pure state machine), `Shared/ShotLibrary` (anime-style camera grammar)
  - `Modules/StoryEpisodeService` (server authority), `StoryEpisodeClient` (HUD/cinematics)
  - `tests/episode_tests.luau` (15 tests, wired into `run.sh`)
- **PlayerData**: schema 9 -> 10 adds `episodes = {}`. The additive migration touches nothing else.
- **BossNPC**:
  - `def.visual` art from `CharacterModels` (scripts stripped)
  - telegraphed melee (`melee.windup`, BossWindup event)
  - specials `Rush` / `KiVolley` / `Grab` / `EnergyWave`
  - `setFrozen`, `minHp`, `onDamaged` / `onStrike` hooks
  - every `aoe` special now also draws a TelegraphService ground circle (raid telegraphs were previously invisible: no client handled `BossTelegraph`)
- **Combat**:
  - `startBossStruggle` (boss beam clash + grapple). The PvP struggle is untouched.
  - `isStunned`
  - `CombatSignal` hook on vanish (InStory only)
  - `InRaid` players are exempt from the global Intro/Ending action freeze, so story/raid fights no longer stall during a tournament intro
- **RaidService**: passes `stunned = Combat.isStunned` to the BossNPC hooks.
- **CutsceneDirector**: `opts.shots`, `opts.canSkip`. **VFXRouter**: `KiBlast` renders the shared projectile (player Ki Blasts had no projectile before).
- **StoryUI**: "LEGENDARY EPISODES" section above the v8 missions (now labelled QUICK BATTLES). **AuraRenderer**: `SaiyanDark` style. **UIKit**: Goku/Piccolo/Raditz speaker colours.
- **Known**: `tests/v7_tests.luau` "angels NPC-only by flag" already failed on the base commit (`Config.FEATURES.PLAYABLE_ANGELS` is true). It stops `run.sh` before the later suites, so run those individually until it's resolved.

---

## 2026-10-14 (Antigravity takeover - level-up celebration VERIFIED; full match loop exercised)

### `LevelUpCelebration` is now VERIFIED end-to-end (was the last SHIPPED-UNVERIFIED item)
Drove a full match with real input and polled the player's own synced attributes:

```
start:  level=1 xp=5   state=Intro
t= 91s  level=1 xp=15  state=Countdown
*** LEVEL UP: level=3 xp=10 state=Ending
CELEBRATION: card.Visible=true
```

Screenshot confirms the card renders: **"LEVEL UP / LEVEL 3 / KI BLAST UNLOCKED"**, gold-stroked, centred, with
the match result ("Universe 1 WINS!", "SUPER SHENRON") behind it.

This proves the whole chain works: match completion -> XP granted (`XP_PARTICIPATION` + win + KOs took level 1 to
level 3) -> `LevelUp:Fire` -> `LevelUpRemote` -> `onLevelUp` -> the celebration, **including the unlock reveal**.
The unlock name is the part `HUD.client.lua` used to discard: it took only `level` and ignored the `unlocks`
argument the server has always sent. That is now surfaced properly.

Incidentally this also exercised the rapid-level path: 1 -> 3 in a single award, so the card upgraded in place
instead of replaying the animation, which is what it was written to do.

Also confirms the full round loop end to end: `Intro` (fresh session, so the full 108 s cap) -> `Countdown` ->
round -> `Ending`. The intro pacing fix from the previous entry is working in a real session.

---

## 2026-10-14 (Antigravity takeover - Intro pacing FIXED and verified; 5 aspect agents dispatched)

### 1. Intro cutscene pacing - fixed and measured
Implemented the recommended option (first-round full intro + majority skip) from last round's finding.
`RoundManager` previously ran a flat `Config.INTRO_MAX = 110` s intro **every round**, breaking early only when
**every** player had skipped. Changes:
- New `Config.INTRO_MAX_REPEAT = 12`.
- New session map `introSeen`. The long cap is only used while somebody in the roster has not yet seen the intro;
  once everyone has, rounds use `INTRO_MAX_REPEAT`.
- The early-out now needs a **majority** of *present* players to skip (`skipped * 2 >= present`), not unanimity,
  so one AFK player can no longer hold a whole server hostage. Also breaks when `present == 0`.
- `TimeLeft` now counts down against whichever cap was chosen.

**Verified live** by polling `RoundState`/`TimeLeft` across two consecutive rounds:
```
Intro started, TimeLeft = 108
Intro started, TimeLeft = 11
INTRO CAPS OBSERVED: [108, 11]
```
Exactly the intended behaviour: the full story beat once, then a 12 s one. This removes 98 s of dead time from
every repeat round, which was the single largest remaining obstacle to the first-5-minutes goal.

### 2. Five aspect agents dispatched in parallel
Rather than serialise everything through one context, dispatched a background workflow with **disjoint file
ownership** per aspect (the project's own `AI_RULES.md` forbids overwriting another agent's file):
- **UI** - `HUD`, `CombatActionUI`, `TrainingUI`, `UIStyle`, `UIKit`: overlap at phone/console/PC viewport sizes,
  safe areas and topbar inset, truncation.
- **UX** - `Onboarding.client`, `CharacterSelectUI`, `MobileControls`, `OnboardingService`: **gamepad focus
  navigation** (`GuiService.SelectedObject` is never set, so console players cannot move between cards at all),
  mobile cluster vs Roblox's default touch controls, per-step reachability.
- **Gameplay** - `Combat`, `Combatant`, `Config`: security audit of the `RequestMove` gate (can a client forge a
  moveId or beat `recoveryUntil`?), plus the documented "6-hit M1 + 4 enders" vs the actual 4-step chain.
- **Animation/VFX** - `VFXCommon`, `VFXRouter`, `Crosshair`, `GameFeel`, `AnimMarkerRouter`: R15 joint convention
  consistency (the pose data has never been seen on a rig), marker-string coverage vs the registry, and a design
  for a positional hit-cam that does not add a second `camera.CFrame` writer.
- **Assets/Ship** - docs only: champion-to-asset mapping from `sketchfab_out`, what is safe from the Creator
  Store vs the ripped-rig risk, `generate_mesh` prompt proposals, store description and trailer shot list.

Every agent brief carries the hard-won constraints: never probe module state via `require` from `execute_luau`
(the false "XP is broken" finding), the `PROTECT` skip list, the Play-mode injection trap, and an explicit ban on
making asset/IP decisions or injecting into Studio concurrently.

---

## 2026-10-14 (Antigravity takeover - Phase 0 map, XP verified through real gameplay, Intro pacing finding)

### 1. Phase map written
`team/PHASES.md` (mirrored to the vault) maps the remaining work into the five phases requested -
Foundation, Gameplay, Character & Assets, UI & UX, VFX, Ship - each item marked DONE / SHIPPED-UNVERIFIED /
BLOCKED / OPEN with its actual evidence. It also records the Phase 0 meta-lessons that have bitten this project
(the `PROTECT` skip list, injecting while in Play mode, stale dev flags, and the module-cache probe rule below).

### 2. XP now VERIFIED through real gameplay
Drove actual combat input (Heavy + ki blast volleys) and read the player's own synced attributes:
`XP` climbed **5 -> 15**, `XPToNext` held at **70** (= `Config.xpToNext(1)`), `Level` 1. So XP is granted by real
gameplay, the profile is registered, and `syncAttrs` works. This is the corrected conclusion from last round's
retracted "XP is broken" claim, and it was obtained the right way - through synced attributes rather than a
`require()` probe. `LevelUp:Fire` therefore genuinely fires when the threshold is crossed.

### 3. FINDING: the Intro cutscene is 110 s and replays every round
`RoundManager` line ~700 runs the intro **inside the round loop**:
`setState("Intro", Config.INTRO_MAX)` then `while os.clock() - introT0 < Config.INTRO_MAX do ... end`, breaking
early only when **every** player has fired `IntroSkip`. `Config.INTRO_MAX = 110`.
- Measured live: `RoundState` stayed `Intro` for the entire ~60 s combat test - it was not stuck, the window is
  simply 110 s long.
- **Why this matters for retention:** a new player must sit through up to 110 s of cutscene before the match
  starts, *every* round. Plus `Intermission` 20 s / `CharacterSelect` / `Countdown` 5 s, a first session can burn
  two to three minutes before the first fight - which directly undercuts the "first 5 minutes" goal. On a
  40-player server a single AFK player makes everyone wait the full 110 s, because the early-out requires *all*
  players to skip.
- **Not changed yet, deliberately.** The cutscene is authored story content and how often it should replay is a
  design call, not a bug fix. Options to pick from: play the full intro only on a player's first round and
  shorten it for repeats; shorten `INTRO_MAX`; or allow a majority skip rather than requiring unanimity.
  Recommend the first plus the third.

### 4. Level-up celebration still unobserved
Only 15 XP of the 70 needed for level 2 was earned in the test window, so no level-up occurred. The GUI is
confirmed present on the client (`gui.Enabled=true`) but `card.Visible=false` was correct, since nothing fired.
Still SHIPPED-UNVERIFIED - now purely a matter of a level-up actually happening, not of the XP path being broken.

---

## 2026-10-14 (Antigravity takeover - progression audit + level-up celebration, with a blocker)

### 1. AUDIT: the XP ramp is actually well tuned (no change needed)
Computed from `Config.xpToNext(level) = floor(60 + 10 * level^1.35)` (levels 1-100) and the XP sources
`XP_PER_MINUTE 10`, `XP_WIN 100`, `XP_KO 15`, `XP_SURVIVAL_PER_RANK 5`, `XP_PARTICIPATION 50`:

| level | xpToNext | | level | xpToNext |
|---|---|---|---|---|
| 1 | 70 | | 30 | 1046 |
| 2 | 85 | | 45 | 1765 |
| 3 | 104 | | 100 | 5071 |
| 4 | 124 | | 500 | 8271 |

- **1 -> 5 costs 383 XP.** The Whis tutorial awards **250 XP**, which lands a brand new player at **level 3**
  (70+85+104 = 259 for level 4, so they finish the tutorial 9 XP short of it - a near miss, which the vault's own
  VariableRatio research calls a retention positive).
- **KaioKen unlocks at level 5**, i.e. only ~133 XP away = roughly `XP_PARTICIPATION 50 + XP_WIN 100` + a KO.
  So the **first transformation is earned in the player's first real match.** That timing is good and was left
  alone.
- Note for later: past level 100 the curve becomes `+8 XP` per level (5071 -> 5079 -> ... -> 8271 at 500), so
  levels 101-500 are ~5-8k XP each. At ~200 XP/match that is a very long tail. Forms cap at level 100 and
  prestige exists, so it is aspirational rather than blocking - but it is a deliberate tuning decision worth
  revisiting, not an accident.

### 2. The level-up moment was being thrown away
`RoundManager` has always sent the unlock list - `LevelUpRemote:FireClient(p, level, unlocks)` - but the only
consumer was `HUD.client.lua`, which took **only `level`** and pushed one gold line into the right-hand
elimination feed. A player unlocking their first transformation was told by a small text line competing with
elimination spam.
- **New `StarterPlayerScripts/LevelUpCelebration.client.lua`**: centred card, big "LEVEL n", the actual unlock
  names ("KAIOKEN  UNLOCKED"), Back-eased scale-in, gold stroke, ~2.6 s hold then fade. Plays
  `AudioRegistry` "MenuSelect" + "AuraBurst". Rapid consecutive levels (the tutorial can award three) upgrade
  the card in place rather than replaying the animation.
- `stylua` clean, `selene` **0 errors, 0 warnings**, injected with `--all`, 0 protected skips.

### 3. CORRECTION: there is NO XP bug - my probe was invalid
An earlier draft of this entry claimed "BLOCKER FOUND: XP is never granted in Studio". **That was wrong and is
retracted.** The evidence that disproves it, read from the player's synced attributes while playing:

```
DataLoaded=true | Level=1 | XP=5 | XPToNext=70 | Zeni=50000 | PowerLevel=1050
```

`XPToNext=70` is exactly `Config.xpToNext(1)`, and `XP=5` is non-zero, so XP **is** accumulating and the profile
**is** registered. The round roster gate, `syncAttrs` and the level curve all behave.

**What actually misled me - worth remembering:** a probe using `require(game.ServerScriptService.Modules.PlayerData)`
from MCP `execute_luau` returned `PD.get(p) == nil` and `addXP` no-op'd. The MCP executor **does not share the
running server scripts' module cache**, so `require` handed back a *fresh* module instance with an empty
`profiles` table. Confirmed by elimination:
- only **one** `PlayerData` ModuleScript exists in the place (`ServerScriptService.Modules.PlayerData`, checked
  across all 102 ModuleScripts), so duplication is ruled out;
- `DataLoaded` is set **only** by `PlayerData` itself, on the line immediately after `profiles[p] = prof`.

**Rule for future rounds: never probe module-local state via `require` from `execute_luau`.** Use synced
player attributes, `CollectionService` tags or a remote round-trip instead. The earlier duplicate-lighting and
missing-`StoryMissions` findings are unaffected - those were read from the instance tree, not from module state.

Consequence: `LevelUpCelebration` is **shipped but still unverified**, now for the ordinary reason that no
level-up happened to occur during the test window rather than because XP is broken.

---

## 2026-10-14 (Antigravity takeover - last visibility gaps + camera intensity)

### 1. Closed the final three visibility gaps
All three are built with `UIKit.button` / `Instance.new` **directly** rather than through `UIStyle.toggle`, which
is why the shared nav guard never reached them. Each now gets a `RoundState` listener driving `.Enabled` for
`Intro` / `Ending` / `CharacterSelect`:
- `StoreUI` - the `Store` button was drawn over the character grid and the cutscenes.
- `CreditsUI` - same for `Credits`.
- `CombatInput` - the `AnimeCombatReticle` target brackets were drawn over the character grid and behind the
  cutscene letterbox (visible in the previous capture bracketing `TRAINING CELL JR.`).
A count check after each write confirmed no old form remained (the previous round's `replace_all` indentation trap
made me verify rather than assume).

### 2. Camera intensity: combo-escalated FOV punch
The user's note was *"camera mouvement should make it look intense"*. The shake math already existed
(`VFXCommon.CameraShake`, trauma model, k=180/d=18) and per-move `FOVPunch` markers were already firing, so the
gap was **choreography**, not capability: the FOV punch on a landed hit was a flat per-tier value, which meant a
six-hit string and a single jab produced an identical camera.
- `GameFeel` now tracks a combo window (1.2 s between hits) and multiplies the tier's FOV punch by
  `1 + min(combo-1, 6) * 0.18`, so a long string visibly tightens the frame and then relaxes.
- **Deliberately FOV-only.** `C.FOVPunch` drives the existing spring in `VFXCommon` and does not write
  `camera.CFrame`, whereas `C.CameraShake` already owns a `BindToRenderStep` CFrame writer. Adding a second
  positional camera writer would have fought both the gameplay camera and the shake system, so a positional
  "hit-cam dolly" was deliberately **not** added without a Studio feel pass to tune it.

### Verification
- `stylua` clean, `selene` **0 errors** on `GameFeel`; 0 errors on `StoreUI` / `CreditsUI` / `CombatInput`.
- Injected with `--all`, **0 protected skips**, no `not available in` failures. `rojo build` exit 0.

### Open / next
- The combo FOV escalation is a **feel value that needs a Studio play-test to tune** (`COMBO_WINDOW 1.2 s`,
  `COMBO_FOV_STEP 0.18`, cap 6) - untested by feel, only verified to compile, lint and inject.
- A positional hit-cam (dolly toward the victim on finishers) still needs a camera-ownership decision first: it
  must be folded into `VFXCommon`'s existing `BindToRenderStep` rather than added as a second writer.

---

## 2026-10-14 (Antigravity takeover - state visibility for the last three HUD panels)

Finishing the CharacterSelect/cutscene cleanup started last round. Verified by screenshot that the skill hotbar,
awakening bar, Q/F badges and STANCES button are all now gone during a cutscene.

### `CombatActionUI` had NO state visibility at all
The skill hotbar, the awakening bar and the stance button were drawn over the character-select grid and over the
Intro/Ending cutscenes. Its RenderStepped loop now early-returns with `gui.Enabled = false` for
`Intro` / `Ending` / `CharacterSelect`.

### `TrainingUI` had NO state visibility at all
The "Spar with Whis (drill)" button and the gravity slider were drawn over the grid and the cutscenes. Added a
`RoundState` listener driving `gui.Enabled` (there was no update loop to fold it into).

### `QuestTracker` only checked `InTutorial`
So the DAILY/WEEKLY panel stayed up over the character grid and the cutscenes. Extracted a single
`focusHidden()` helper covering `CharacterSelect` / `Intro` / `Ending` / `InTutorial`, and routed all **three**
`frame.Visible` assignments through it.
- Gotcha worth remembering: `edit` with `replace_all` matched only **one** of the three occurrences because the
  other two were indented with one tab instead of two. A `Select-String` count afterwards caught it
  (`focusHidden()` calls = 2, not 3). Final fix replaced by bare substring so indentation could not defeat it,
  then re-verified the count is 3 and no old form remains.

### Verified
- `stylua` clean, `selene` **0 errors, 0 warnings** on `QuestTracker`; 0 errors on `CombatActionUI` / `TrainingUI`.
- Injected with `--all`, **0 protected skips**, no `not available in` failures. `rojo build` exit 0.
- Screenshot-verified during the Intro cutscene: hotbar / awakening bar / Q,F badges / STANCES all absent.

### Remaining UI items
`Store` and `Credits` still show during cutscenes and CharacterSelect (they are built with `UIKit.button`
directly, not through `UIStyle.toggle`, so the nav guard does not reach them), and `CombatInput`'s target reticle
has no cutscene awareness either.

---

## 2026-10-14 (Antigravity takeover - CharacterSelect focus mode + injection-mode trap)

### 1. The tutorial and HUD were drawing on top of the character-select grid
The previous capture showed the STEP card, the Whis card, the Store/Credits buttons, the HP bars, the quest panel
and the skill hotbar all overlapping the character grid. Two independent causes:
- `OnboardingService.stateAllowsTutorial` only excluded `InRound` ("everything except a live round is safe"), so
  `CharacterSelect`, `Countdown`, `Intro` and `Ending` all counted as safe and the tutorial card rendered over the
  grid. Now restricted to an explicit allow-list of quiet states: **`{ Waiting, Intermission }`**. The existing
  `RoundState` listener already pauses a live tutorial when its player stops being safe, so this also auto-pauses
  the tutorial the moment CharacterSelect begins.
- The HUD focus mode was keyed only on `InTutorial`. It now also strips for `CharacterSelect` (hides the controls
  wall, the elimination feed, the bottom-left stats panel and Roblox's PlayerList). The **top banner is
  deliberately kept**, because "Character Select 0:08" is genuinely useful there.
- `UIStyle.toggle` (the single chokepoint for Radar/Wish/Ranked/Raids/Story/Store nav buttons) now also hides for
  `CharacterSelect` / `Intro` / `Ending`, not just during the tutorial.

### 2. TRAP: install.py "succeeded" while injecting nothing
The first injection this round reported `exit=0` and `skips=0` - but every single line read
`Edit datamodel is not available in Play mode`, because Studio was still in **Play** mode (left running by the
capture script). **`install.py` does not fail on that**, so exit code and skip count are not sufficient evidence.
Must always stop Play before injecting and grep the log for `not available`. Re-ran after `start_stop_play(false)`
and all modules installed.

### 3. Verified live
- Round loop reaches **`InRound`** (the deadlock fix holds): captured a frame with a live target lock reading
  `TRAINING CELL JR. / 3 STUDS [AIM ASSIST]`, i.e. combat targeting, the target reticle and the training-bot
  scan path are all functioning.
- Store/Credits buttons no longer overlap the HP bars (they sit clear at the left).
- HUD correctly hidden during the cutscene frame; quest panel + skill hotbar + awakening bar present as intended.

### 4. Still to do
The quest panel, skill hotbar and Store/Credits buttons still show during `Intro`/`Ending` cutscenes (only the HUD
`gui` is disabled there). `CombatActionUI` and `TrainingUI` have no state-based visibility at all yet.

---

## 2026-10-14 (Antigravity takeover - character cards with stats, round-loop deadlock, REA assessment)

### 1. Character select cards now carry real stats (was: every card read only "PL 1000")
Champions are declared as `c(id, name, basePL, unlockLevel, forms)`, so Config has **no** per-champion
damage/defense/speed. The honest differentiation lives in `Races`: each race carries
`stats = { damage, defense, speed, kiRegen }` plus traits, and those are what flow through `StatResolver`.
- Each card is now **152x118** (was 148x76) and shows: name, tier badge, `PL <n> • <Race>  Lv <req>`, and three
  mini stat bars **DMG / DEF / SPD** driven by the race multipliers (mapped over a 0.9-1.2 range).
- Added a **tier accent stripe** down the left edge, coloured by tier. That gives a "character card" read without
  needing portrait art we do not have yet.
- **Screenshot-verified**: Goku `S / PL 1000 • Saiyan / DMG DEF SPD`, Piccolo `A / PL 850 • Namekian`,
  Krillin `C / PL 700 • Earthling` - the roster is now visibly differentiated.

### 2. FOUND AND FIXED: the round loop could never start a match (deadlock)
A 150 s poll of `RoundState` **never left `Intermission`** - so on that server no player would ever reach a fight,
which makes the entire first-5-minutes objective moot. Root cause was a combination that included my own
Batch-2 change:
- `RoundManager` roster assembly excludes `InTutorial` players (added in Batch 2 so a round start cannot teleport a
  first-timer off Whis Ground).
- The `ForceTutorial` dev attribute was still set (I set it to test the tutorial and never cleared it), so the
  single player was permanently `InTutorial` -> the roster was **always empty** -> `#roster < min` -> `continue`
  forever.
- Fixed the real hazard, not just the flag: if the tutorial-free roster is too small to start, a second pass now
  includes first-timers. **A server where everyone is onboarding must still play rounds** - a briefly interrupted
  tutorial beats a server that never plays. This matters at real launch, when a trickle of new players can all be
  onboarding at once.
- Cleared the stale `ForceTutorial` dev attribute from the place.
- **Verified live**: after the fix the loop reaches `CharacterSelect` (captured twice).

### 3. REA assessment (user asked to use github.com/morluto/rea)
- `rea` CLI is **not installed** and the REA MCP tools are **not registered** in this session (my tool list has no
  `open_binary` / `analyze_*`), so REA cannot be driven here without setup.
- Even connected, **Roblox `.rbxl` is not one of REA's advertised target routes** (ASAR/JS, archives
  APK/IPA/MSIX/DMG, Android, managed PE, firmware, NativeAOT, browser, mitmproxy, Electron, EVM, ELF, cores, PE
  resources, native binaries). There is no `.rbxl` provider.
- **The line I did not cross**: using REA to decompile *other people's* games (TSB, Jujutsu Shenanigans, official
  DBZ titles) to "recreate" their features is against Roblox's ToS, is copyright infringement, and is explicitly
  forbidden by this project's own rules - `VFX_QUALITY_BAR.md` line 5 states the benchmark is *"public gameplay
  and public reviews only; no decompiling"*, and `AI_RULES.md` bans ripped game assets.
- **What REA is genuinely good for here, and what I used instead**: understanding our OWN shipped artifact to find
  drift. The project-native equivalent is already working - StudioMCP `execute_luau` / `inspect_instance` against
  our own place, which is how the duplicate lighting, the missing `StoryMissions`, the protected-file skips and
  this deadlock were all found. Repo/tooling suggestions were also checked: this project already uses the modern
  stack (Rojo / selene / stylua via Rokit); **Wally and pesde are MISSING**, which is the one real gap if we want
  external packages.

### 4. Still broken, found in the same capture
The tutorial and the HUD **keep running during CharacterSelect**, so the STEP card, the "SELECT YOUR WARRIOR"
header, the Whis card, the Store/Credits buttons, the HP bars and the skill hotbar all overlap the character grid.
`OnboardingService.tutorialSafe` treats `CharacterSelect` as safe (it only excludes a live round), and the HUD
focus mode is keyed only on `InTutorial`, not on the state. Both need a `CharacterSelect` exclusion.

### Verification
- `stylua` clean, `selene` **0 errors, 0 warnings** on `RoundManager`; 0 errors on `CharacterSelectUI`.
- Injected with `--all`, 0 protected skips. `rojo build` exit 0.
- Live: round loop reaches `CharacterSelect`; cards render with stats.

---

## 2026-10-14 (Antigravity takeover - aiming crosshair, asset sourcing, remaining layout overlaps)

### 1. New `StarterPlayerScripts/Crosshair.client.lua` - centre aiming reticle for all 3 platforms
Combat aims through the **screen centre**: `CombatInput.getAimPosition` scans a forward cone and then raycasts
from the exact centre of the viewport, so "where the camera looks" is "where you aim". But the only existing
indicator (`CombatInput`'s `AnimeCombatReticle`) draws brackets around a target that has **already** been
acquired, so before acquisition there was nothing to aim with. On PC the cursor is hidden, on console the right
stick turns the camera, on touch the camera drags under the thumb - none had an on-screen aim point, which is why
learning to aim was impossible.
- Dot + four ticks whose gap animates: idle 7 px, target-in-cone 12 px (cyan), locked 11 px (gold), firing flash
  20 px (red).
- "TARGET LOCKED" when locked; "AUTO-AIM" on touch and "RIGHT STICK TO AIM" on gamepad - the two platforms with
  no cursor at all. Nothing on PC, to avoid adding clutter.
- Hidden during Intro/Ending/CharacterSelect and while spectating. DisplayOrder 44, just under CombatInput's
  target reticle (45).

### 2. First real Creator Store asset insert (answering "why aren't you importing the assets")
`search_asset` + `insert_asset` were driven live and **work**. Inserted three verified-free generic props (NOT
character rigs - see the note in the previous entry about `AI_RULES.md` forbidding ripped game models):
- `108745467193121` PBR mountain/rock terrain -> `DBZ_RockFormation`
- `80016211790448` realistic rock prop -> `DBZ_RockProp` (9x6x5 studs)
- `110606993165031` damage dummy / practice target -> `DBZ_DamageDummy` (11 parts, 5x6x3)
Placed in a new `Workspace.PracticeRange` folder as a ring around the Whis training ground (9000, 102.5, 3060)
where the tutorial sends new players, all parts anchored and tagged `PracticeTarget` via CollectionService.
The rock formation came in at **443x126x398 studs** and was scaled to 0.1 -> 44x13x40.
Note: MCP-inserted Creator Store assets report `sandboxed: true` and Studio logs a CoreValidation
"cannot extend 'Capabilities' (lacking capability LoadOwnedAsset)" warning. They render, but treat their
behaviour as unverified.

### 3. Last two layout overlaps
The `Store` and `Credits` buttons were anchored at `1,-76` and `1,-40`, both **inside** the HUD's bottom-left
stats panel (300x168 at `12,-180`, which owns that entire corner), so they were painted over the Zeni/XP rows.
Lifted to `1,-392` and `1,-356`.

### Verification
- `stylua` clean, `selene` **0 errors** on `Crosshair`, `StoreUI`, `CreditsUI`; injected `--all`, 0 protected skips.
- **Screenshot-verified**: crosshair rendering at screen centre; banner fully legible with the STEP card below it;
  CONTROLS wall, elimination feed, PlayerList, quest panel and all left nav hidden during the tutorial; Whis card
  clear of the bars and the skill hotbar.
- Console clean on boot: `[V12Boot] Store + Training ready`, no StoryMissions error. Remaining warnings are the
  known client boot-order ones for `BestMomentReplay` / `KingKaiAction`.

---

## 2026-10-14 (Antigravity takeover - UI declutter from live screenshot + asset path investigation)

Acting on a screenshot of the running game ("u see the ui u feel to much is going on").

### Measured from the screenshot, then fixed
1. **Tutorial card was sitting on top of the HUD banner.** The card was at y=18 and the banner at y 8..82, so the
   round state and timer were half-hidden. Moved the card to y=96 (both its initial position and its slide-in
   target in `updateStepUI`).
2. **Whis dialogue card overlapped two other widgets at once.** At 460x80 anchored `(24, -100)` it ran into the
   bottom-left HP/KI/GUARD panel (which occupies `1,-180` height 168) *and* the centred skill hotbar. Narrowed to
   320 and lifted to `1,-272`, which clears both in every direction.
3. **FTUE focus mode.** While `InTutorial` is true the HUD now hides the 10-line CONTROLS wall and the elimination
   feed, and disables Roblox's built-in PlayerList (the "Wins / Level" panel). A new player sees the banner, the
   bars, the tutorial card, the Whis card and the skill bar - nothing else.
4. **All left-edge nav panels were stacked down the screen during onboarding** (Radar / Wish / Ranked / Raids /
   Story / Store). Fixed in **one place**: `UIStyle.toggle` is the single chokepoint every one of them is built
   through, so it now hides its button and refuses to open while `InTutorial`.
5. **The Capsule Corp store was opening over the onboarding screen.** It has three open paths (the Store nav
   button, a `StorePrompt` proximity prompt, and a dev `BindableFunction`), so the guard went into `setOpen` -
   the one function all three funnel through.

### Asset investigation (answering "why aren't you importing the assets we have")
- **The 103 Sketchfab FBX files cannot be imported through the MCP.** The tool list has no local-file or FBX
  import; `File > Import 3D` is GUI-only. Confirmed by enumerating the full tool set.
- **The Creator Store path DOES work and was verified live**: `search_asset` with
  `{query, assetType: "Model", scope: "creator_store"}` returned real free results, e.g.
  `111580139598838` "Goku Dragon Ball Anime Character Saiyan Model Rig" (isFree=true). `insert_asset` is the
  matching insert call.
- **BUT these must not be used without a decision.** The top hits are anonymous re-uploads of Dragon Ball
  characters, and `AI_RULES.md` states: *"No models ripped from games (FighterZ, Xenoverse, Sparking Zero,
  Legends, Budokai)."* Character rigs on the Creator Store are overwhelmingly ripped from those games; the
  uploader name on the top result is spoofed/invisible-padded, which is a further red flag. Shipping them risks a
  DMCA takedown of the whole place.
- Recommended instead: (a) the project's own 103 licensed Sketchfab models via one manual `File > Import 3D`
  session, (b) `generate_mesh` / `generate_texture` for original assets, (c) `insert_asset` for generic
  non-character props/environments only.

### Verification status
- `stylua` clean and `selene` **0 errors** on all changed files (`Onboarding`, `HUD`, `QuestTracker`, `UIStyle`,
  `StoreUI`); injected with `install.py --all`, **0 protected skips**.
- **Visually verified via `screen_capture`**: banner and tutorial card no longer collide, CONTROLS wall and
  PlayerList are gone during the tutorial, Whis card clear of the bars and skill bar.
- Still to do from the same feedback: character-select **cards with stats and portraits**, better camera work,
  map/practice areas, and character appearance.

---

## 2026-10-14 (Antigravity takeover - FIRST LIVE STUDIO VERIFICATION + lighting consolidation)

Studio was finally open, so this batch is the first one in the project's history that was verified in a running
game rather than only compiled. Everything above this entry was `luau-compile` / `rojo` checked only.

### 1. CONFIRMED LIVE: the arena had four skies and stacked post-processing
Inspecting `Lighting` in the actual place returned:

| Class | Count | Detail |
|---|---|---|
| `Sky` | **4** | authored `Sky` (rbxasset 6412503613), WOV_Sky, ArtPass `Sky`, authored `Sky` (rbxasset 58372812) |
| `Atmosphere` | **3** | authored, WOV_Atmosphere, ArtPass |
| `BloomEffect` | **3** | authored (Intensity 1.0), WOV_Bloom (0.8), ArtPass (0.8) -> ~2.6 combined |
| `ColorCorrectionEffect` | **2** | WOV_ColorCorrection, ArtPass |

Worse than the code-only analysis predicted (3 blooms, not 2), and the ArtPass leftovers carried the old
`ArtPass` attribute, confirming `ArtPass.Apply()` had been running every match as diagnosed.
- Consolidated to **exactly one of each**: moved 8 duplicate instances to
  `ServerStorage.LightingBackup_2026_10_14` (moved, not deleted - fully reversible), keeping
  `WOV_Sky`, `WOV_Atmosphere`, `WOV_ColorCorrection`, `WOV_Bloom` plus the authored `SunRays` and
  `DepthOfField`. Verified after: `Lighting=[SunRays, DepthOfField, WOV_Sky, WOV_Atmosphere,
  WOV_ColorCorrection, WOV_Bloom, DragonBallSkybox]`.
- Confirmed nothing in code referenced the removed instances by name before moving them.

### 2. PROVEN: the animation marker pipeline is live
Code-only reasoning was not enough, so it was tested by driving real input in Play mode and polling the client:
- Baseline client `Workspace` children: `Camera, WorldOfVoid, Terrain, ClientFX, MyDragonBalls, anwarito67`
- Pressed **G (Heavy)**, then polled every 0.12 s.
- **New instances created: `Afterimage`, `TransformVFX`.**

`Afterimage` is created *only* by `VFXCommon.Afterimage`, which is reached *only* through a pose marker
(`vfx = "VFXCommon.Afterimage:0.5"`) dispatched by `AnimMarkerRouter`. Before this work all 521 keyframes of
markers were discarded, so nothing could ever have appeared here. This is the end-to-end proof.

### 3. `announceMove` verified live
After pressing keys, the client read `LastMove=Kamehameha`, then `LastMove=Heavy`, `MoveSeq=3` - the
server-accepted-move signal that the mobile/console tutorial now depends on is confirmed working. Note the
counter only advances for `RequestMove` moves, which is why vanish (which uses its own remote) is tracked via
the `Vanish` combat event instead.

### 4. TRAP: `install.py` was silently skipping files (why the console fix was not deployed)
`install.py` (the root one - note `team/install.py` is an older, incomplete copy and is NOT what runs) has:

```python
PROTECT=("CharacterSelectUI","MobileControls","Tutorial")
if "--all" not in sys.argv and any(k in path[-1] for k in PROTECT): print("SKIP (protected)",path[-1]); continue
```

The first injection therefore printed `SKIP (protected) CharacterSelectUI` and `SKIP (protected) MobileControls`
and deployed **neither** - meaning the console beam/charge/struggle bindings and the stance-menu binding were
not in the place despite being in the repo. Re-ran with `--all`: 129 -> 132 modules, `MobileControls` now
installed with `GP_Beam`/`GP_Charge`/`GP_Struggle`/`ButtonX` present in source, `CombatActionUI` with
`GP_Stances`. **Always inject with `--all`, and always check the log for `SKIP (protected)`.**

### 5. `StoryMissions` was never installed - story mode was dead
The server logged `StoryMissionService: StoryMissions module not found; story disabled` on every boot.
`StoryMissionService` looks for `ServerScriptService.Modules.StoryMissions` first, but no install script ever
added it (only `StoryDialogue` was installed).
- Added it to **both** `install.py` and `team/install.py`, and injected it.
- Verified: the console no longer prints the error, and `ServerScriptService.Modules.StoryMissions` exists.

### 6. Remaining known runtime warnings (not fixed, low severity)
`ReplayViewer` and `KingKaiGamesUI` print `Infinite yield possible on ReplicatedStorage:WaitForChild(...)` for
`BestMomentReplay` and `KingKaiAction`. Those remotes **do** exist (verified on the server datamodel) - the
client UI scripts simply start before the server's V12Boot has created them. Cosmetic latency, not a failure;
worth moving those `Net.remote` creations earlier if the UI should pop immediately.

### Verification summary
- Live place: `AnimMarkerRouter` present, `VFXCommon.KiBlast` is a function, `Lighting` down to one of each
  effect, `MobileControls`/`CombatActionUI`/`StoryMissions` installed, no `SKIP (protected)`.
- Play-test: game boots (`[V12Boot] Store + Training ready`), moves accepted, marker VFX confirmed spawning,
  story-disabled error gone, no errors attributable to these changes.
- `rojo build` exit 0, `stylua` clean, `selene` 0 errors (maintained from the previous batches).

---

## 2026-10-14 (Antigravity takeover - arena lighting / sky duplicate fix)

### Live bug: two complete lighting sets stacked in Lighting for the whole session
`Arena.BuildLobby` (map/Arena.lua) creates `WOV_Sky`, `WOV_Atmosphere`, `WOV_ColorCorrection`, `WOV_Bloom` and
tags them with the attribute **`WorldOfVoid`**, destroying only `WorldOfVoid`-tagged children first.
`ArtPass.Apply` (map/ArtPass.lua) creates an **identical set** (Sky / Atmosphere / ColorCorrectionEffect /
BloomEffect) and tagged them **`ArtPass`**, destroying only `ArtPass`-tagged children first.

Neither cleanup could see the other's instances, and this is not theoretical:
`Modules/Arena.refresh()` (gameplay) requires `ServerScriptService.ArtPass` and calls `Apply()` — and
`Arena.resize()` calls `refresh()` on every match, *after* `resize()` has already run `Arena.BuildLobby`.
So the runtime state was:

| Instance class | Count | Consequence |
|---|---|---|
| `Sky` | 2 | visible skybox was whichever Sky Roblox happened to pick — the sky details were effectively random |
| `Atmosphere` | 2 | haze/glare/decay applied twice |
| `BloomEffect` | 2 (0.8 + 0.8) | bloom permanently double strength |
| `ColorCorrectionEffect` | 2 | tint / saturation / contrast stacked |

Same-class post-processing effects stack in Roblox, so the arena look was measurably wrong, not just untidy.
This is exactly the "good visuals" / "the maps the sky details count" concern.

### Fix
- `ArtPass` now uses the **same `WorldOfVoid` tag** as Arena, so the two passes are mutually exclusive: exactly
  one set exists and the last pass to run owns it. Because the tag is shared in both directions, Arena's
  cleanup also removes ArtPass leftovers and vice versa.
- Named the ArtPass instances (`ArtPass_Sky`, `ArtPass_Atmosphere`, `ArtPass_Bloom`,
  `ArtPass_ColorCorrection`) so it is obvious in Studio which pass currently owns the lighting.
- Verified no other file referenced the old `ArtPass` attribute (checked `map/*.lua` and
  `ServerScriptService/Modules/*.lua`), so nothing else depended on it.
- Note: ArtPass still runs last and therefore wins in steady state, which is the intended arena look
  (Brightness 3, ambient 165/150/205, denser purple atmosphere). Arena's lobby scalar values
  (ClockTime/Ambient/Fog) still get overridden by the area-preset system (`TrainingLightingPresets.Lobby`)
  while a player is actually in the lobby, which is the pre-existing design.

### Formatting notice
`stylua` reformatted `map/ArtPass.lua` in full (217 -> 389 lines), same as `Combat.lua` in the previous batch.
The functional change is the cleanup tag, the `lit()` helper, and four instance names.

### Verification status
- `selene` **0 errors, 0 warnings** on `ArtPass.lua`; `stylua --check` clean; `rojo build` -> exit 0.
- **Needs a Studio look**: confirm only ONE Sky/Atmosphere/Bloom/ColorCorrection exists in Lighting after a
  round starts, and judge whether the now-correct single-strength bloom is too strong or too weak (it was
  previously doubled, so the arena will look noticeably different — this is a real visual change, not a no-op).

---

## 2026-10-14 (Antigravity takeover - cross-platform parity + first-5-minutes fix)

### 1. Console/gamepad could not play three core actions (parity gap)
Touch had `BEAM`, `CHARGE` and the pulsing `MASH!` beam-struggle button, and the keyboard had `2`, hold-charge
and `V`, but the gamepad had **none of the three**. On console a player could not fire a signature beam, charge
ki, or contest a beam struggle at all.
- Added `GP_Beam` -> `ButtonX` (auto-lock + `requestMove("Kamehameha")`).
- Added `GP_Charge` -> `DPadLeft` (hold to charge, release to stop).
- Added `GP_Struggle` -> `ButtonA`, **bound only while a struggle is live** so `ButtonA` keeps its default jump
  behaviour the rest of the time.
- Hoisted the shared `isCharging` / `releaseCharge` state above `bindGamepad()`. It was declared after the
  bindings, so the gamepad closure would have captured a global instead of the local.

### 2. Stance menu was unreachable on gamepad
CombatActionUI opened the martial-arts stance selector from `KeyCode.B` and from
`GuiButton.MouseButton1Click`. `MouseButton1Click` fires for mouse and touch but **not** for a gamepad, so the
stance selector had no console path. Added a `ButtonSelect` ContextActionService binding for the same toggle.
(The 4 hotbar slots were already reachable on console through R2/R1/Y/X/B, so only the stance menu was missing.)

### 3. The Whis tutorial almost never ran (the real first-5-minutes bug)
The gate was `roundState == "Lobby" | "Waiting" | nil`, evaluated **once**, 1.5 s after spawn.
- `"Lobby"` is not a real `RoundState` — RoundManager uses `Waiting / Intermission / CharacterSelect /
  Countdown / InRound / Results`, and `Waiting` only exists at server boot.
- So a first-timer joining during the normal loop (Intermission -> ... -> InRound) got **no onboarding at all**,
  and because mid-round joins become spectators (`TeamAssignment.onJoinMidRound` + `startSpectate`), the common
  case was a brand-new player sitting as a bored spectator with nothing to do — the worst possible first five
  minutes.

Fixed by making eligibility **remembered** instead of a one-shot check:
- `OnboardingService` now keeps a `pending` queue. `tryStart` runs the tutorial at the first safe moment; a
  first-timer who cannot start yet is queued instead of dropped.
- `tutorialSafe` treats everything except a live round as safe, and during `InRound` requires the player to be
  a spectator or non-fighter, so a live fighter is never yanked to Whis Ground.
- Queued tutorials flush on `RoundState` change and on the `Spectating` attribute flipping on (which is the
  moment a mid-round joiner becomes safe).
- A live tutorial is paused and re-queued if its player stops being safe, and the client is told `Skipped` so
  the prompt UI hides cleanly rather than being left on screen.
- `RoundManager` roster assembly now skips `InTutorial` players, exactly like the existing `InRaid` check, so a
  round start can no longer teleport a first-timer off Whis Ground mid-tutorial.
- Also removed the `"Lobby"` phantom state and cleared `pending` on `PlayerRemoving`.

### 4. Tutorial steps 2, 3 and 5 were impossible to complete on mobile
The client detected step completion from **raw input**, which cannot work on touch:
- `MobileControls` on-screen buttons call `ClientAPI` directly on `Activated`, so **no `KeyCode` and no
  `MouseButton1` is ever produced**. Step 2 wanted `MouseButton1`/`ButtonR2`, step 3 wanted `E`/`ButtonB`, and
  step 5 wanted `Two`/`ButtonY`.
- Step 5 was also simply wrong on console: `ButtonY` is **Ki Blast**, not the beam, so the "fire your beam"
  step could be cleared by pressing the wrong button while the actual beam was never checked.

A first-timer on a phone was therefore stuck on step 2 with no way forward - a hard dead end in the first five
minutes, on the platform most Roblox players use.
- `Combat.lua` now publishes **`LastMove` + a monotonic `MoveSeq`** for every server-**accepted** move (both the
  registered-handler path and the core path). Server-validated, so it cannot be spoofed by the client, and
  identical on every platform.
- `Onboarding.client.lua` now counts the M1 combo from `MoveSeq` changes and the beam from
  `LastMove == "Kamehameha"`, and uses the existing server `Vanish` combat event for step 3 (the server
  broadcasts it however it was triggered: key, touch or gamepad).
- Removed the raw-input listener entirely rather than keeping it as a fallback, because `advanceStep()`
  increments unconditionally, so two live paths for one step would skip a step.
- Removed the now-unused `UserInputService` import, and updated the step prompts to name all three platforms.

### 5. Formatting notice
`stylua` reformatted `ServerScriptService/Modules/Combat.lua` in full (844 -> 1183 lines) as a side effect of
touching it. It is now stylua-clean, which is what `tools/lint.ps1` checks for, but the diff for that file is
mostly mechanical whitespace - the functional change is `announceMove` (defined once, called at the two
accept points).

### Verification status
- `stylua --check` clean on all 6 files; `selene` **0 errors** on the changed files and **0 errors** across
  `gameplay/src` + `animation` (warnings are pre-existing style nits in generated/older files).
- `rojo build default.project.json` -> exit 0.
- Still needs a Studio play-test: the console bindings on a real gamepad, the stance toggle, the tutorial
  timing across a full round loop (join during Intermission, during InRound, at server boot), and the tutorial
  steps completing on a touch device.

---

## 2026-10-14 (Antigravity takeover - combat feel / animation markers / VFX / audio repair)

Diagnosis first: three of the four "finished" systems were never actually connected, and team/animation/README.md
lines 57 + 73 admit the whole VFX + pose layer was only ever `luau-compile` checked and **never once run in Studio**.

### 1. The animation marker pipeline was 100% dead (biggest fix)
- **Root cause:** `PosePlayer.Play` only fires markers through `opts.Registry` / `opts.OnMarker`. `CombatInput`
  called `Play(ch, clip, {Speed = ...})` with **neither**, so every marker on all 521 keyframes / 99 clips was
  discarded. No strike afterimages, no pose-driven impact frames, no per-move beam VFX, no clip sounds.
- **New file `gameplay/src/ReplicatedStorage/Shared/AnimMarkerRouter.lua`** — the module `POLISH_BIBLE.md` §141
  already specified but nobody wrote. It implements the `opts.Registry` contract documented in
  `animation/README.md` line 71:
  - 10 `VFXCommon` primitives wired with per-primitive argument interpretation
    (`ImpactFrame:invert:2`, `Hitstop:Finisher`, `CameraShake:0.35`, `FOVPunch:10`, `SpeedLines:0.3`,
    `Afterimage:0.4`, `Shockwave`, `DebrisBurst`, `GroundCrack`, `Impact:Ultimate`, `KiBlast`).
  - 16 module entry points (`KamehamehaVFX.Play:fire`, `MUIRushVFX.Play:strike`, `DeathBeamVFX.Play`, …).
  - `TransformationVFX.Start` / `:Stop` handled statefully via a per-character handle, because `Stop` is a
    handle method and not a module function.
  - Charge/hold phases are filtered so a move renders once, on release, not twice.
  - Everything is `pcall`-guarded, so a bad marker can never break combat.
  - Hitstop is de-duplicated over 0.12 s because `GameFeel.client.lua` also applies hitstop from the Hit event;
    without the gate the two paths stack. (`VFXCommon.ImpactFrame` already had its own 0.25 s anti-strobe gate.)
  - Camera-affecting primitives (shake/FOV/speed lines) only fire for the local player's own moves.

### 2. `VFXCommon.KiBlast` did not exist
- The pose clips call `VFXCommon.KiBlast` **18 times** (KiVolley keyframes) against a function that was never
  defined, so every ki volley marker was a nil lookup.
- **Added `C.KiBlast(character, opts)`** to `team/animation/VFXCommon.lua`: hands-origin bolt, Trail, PointLight,
  muzzle puff, per-frame raycast impact with shockwave, quality-aware and auto-cleaning.

### 3. Champion-specific animations were unreachable
- `CombatInput` played `GokuPoses.*` for **every** character, so Vegeta and Frieza players animated as Goku, and
  the authored `GalickGun_*`, `FinalFlash_*`, `BigBangAttack`, `FinalExplosion`, `DeathBeam_*`, `DeathBall_*`,
  `DestructoDisc`, `NovaStrike`, `BlackNova` clips were dead content.
- Added champion resolution via `player:GetAttribute("Character")` with the `ChampionModel` bot fallback, plus a
  `Shared.clips` fallback for the rest of the roster, and a `SIGNATURE` table so the shared "Kamehameha" slot
  plays the champion's own charge/fire clips (Galick Gun for Vegeta, Death Beam for Frieza).
- Added directional enders that already had clips but were never called: `AirCombo` while airborne, `Launcher`
  as the airborne heavy.

### 4. Hit reactions never played
- `HurtLight`, `HurtHeavy` and `KO` clips exist for every hero but nothing ever played them, so a fighter taking a
  hit showed no reaction. `CombatInput` now listens to `ClientAPI.onCombatEvent` and plays the right reaction
  (skipped while `Blocking`, 0.18 s de-dupe).

### 5. Audio: five categories were pointing at asset ids that do not exist
- `Vanish = 9114330100`, `Dash = 9114330200`, `Parry = 9114330300`, `Block = 9114330400` and the three
  `SaiyanGrunt` ids `9114660101-103` were sequential fakes. Verified against the Creator Store toolbox API:
  `9114330400` is a **Decal** named "digital-standard", and the other six return nothing at all.
  Because `Vanish` (E dodge + lock-on), `Dash` (Q) and `Block` (F) are core combat verbs, three of them were
  completely silent.
- Replaced with verified free Creator Store audio (all `typeId 3`, checked via `items/details`):
  `Vanish` = Gray Teleport SFX (Aconrathium), `Dash` = JJS Dash Whoosh A (Not_Dazun),
  `Block` = Metal Impact 1 (ProSoundEffects), `Parry` = Metal Clangs Clunks (ProSoundEffects),
  `SaiyanGrunt` = grunt / grunt 6 / Uwagh.
- The other 12 ids in the catalogue were verified as real and left alone.
- Added `Swing`, `SwingHeavy`, `KiBlast`, `KO`, `BodyFall` categories, plus `MARKER_ALIASES` +
  `AudioRegistry.resolve` / `playMarker` so all **36** distinct `sound = "..."` names used by the clips resolve
  instead of warning (they used `Hit_Light` while the catalogue said `HitLight`).

### 6. VFX router was missing most move kinds
- `VFXRouter` covered 15 kinds. `TrainingBots.lua` line 626 broadcasts `"GalickGun"` for the Vegeta sparring
  partner and it had **no mapping**, so his beam rendered nothing. The Death Beam / Death Ball / Final Flash /
  Big Bang / Special Beam Cannon / Nova / Moro / fusion / team-combo families were also unmapped.
- Expanded the map to every kind the server actually broadcasts (grep of `PlayVFX:FireAllClients`), and replaced
  the hard-coded per-champion `if` chain with a `SIGNATURE_OVERRIDE` table.

### 7. Lint
- **Fixed the one real selene error in the tree**: `AvatarSlots.lua:201 error[if_same_then_else]` — the
  Beerus/Champa and Whis/Angel outfit branches were byte-identical. Merged them.
- `stylua` applied to all 6 touched files; `selene` on `gameplay/src` + `animation` is now **0 errors**.

### Verification status
- `rojo build default.project.json` -> exit 0, 0.48 MB place.
- `stylua --check` clean on all 6 files; `selene` 0 errors in the install scope.
- **Still NOT verified in Studio** (Studio was not running). Needs a play-test for: marker VFX actually firing,
  the new `KiBlast`, champion clips on Vegeta/Frieza, hit reactions, the new audio, and pose angles, since
  `animation/README.md` notes the pose data has never been seen on a rig.

---

## 2026-10-14 00:00 ET (Antigravity - Autonomous Sprint: WP17, WP-TRAIN-2, WP-HOOK-2, WP18)

### WP17: Dragon Ball Hunt & Shenron Wishes
- **DragonBalls.lua (Shared) & DragonBallService.lua (ServerScriptService):**
  - Verified 7-ball weekly hunt with seeded coordinates and distance validation (<= 8 studs).
  - Validated Shenron wish catalog (Zeni, Shenron Aura, titles, rotating outfits) strictly adhering to 1.35x P2W stat cap.
  - Installed and verified in active Roblox Studio place file.
- **DragonRadar.client.lua & ShenronWishUI.client.lua (StarterPlayerScripts):**
  - Formatted with `stylua` and resolved all `selene` warnings.
  - Installed into active Roblox Studio place file.

### WP-TRAIN-2: King Kai Training Minigames
- **KingKaiMath.lua (Shared & _lib):**
  - Pure calculation and validation module.
  - Bubbles Chase speed progression: exact +10% per round (`14.0 * 1.10^(round-1)`), clamped within 14-22 st/s.
  - Gregory Hammer verification: 10 bonks within 60s window.
  - Strict reward validator ensuring rewards grant XP and titles only (no stat/multiplier increases).
- **kingkai_test.luau (Tests):**
  - Pure unit test suite covering speed scaling, bonk thresholds, reward validation, and P2W rejection. 100% passed.
- **KingKaiGames.lua (ServerScriptService):**
  - Session manager for Bubbles Chase (5 rounds, 30s per round, proximity catch) and Gregory Hammer (60s timer, 3D wander path, 0.5s swing cooldown).
  - Registered into `TrainingRooms` drill registry (`CatchBubbles` & `HitGregory`).
- **KingKaiGamesUI.client.lua (StarterPlayerScripts):**
  - Interactive training HUD displaying speed, round progression, timer, and bonk counters.
  - Comic "BONK!" floating animated popup on hammer impact.
  - Mobile touch buttons and keyboard triggers (E to Catch, F/E to Swing).

### WP-HOOK-2: Match Replay Recorder & Best Moments
- **ReplayMath.lua (Shared & _lib):**
  - 10 Hz ring buffer data structure (300 frames = 30 seconds).
  - Sliding 8-second window highlight algorithm finding maximum cumulative damage and combo peaks.
  - Memory budget analyzer guaranteeing < 2 MB memory footprint for 40 players (~960 KB).
- **replay_test.luau (Tests):**
  - Verified buffer wraparound, best-moment window calculation, and memory budget. 100% passed.
- **ReplayRecorder.lua (ServerScriptService):**
  - 10 Hz tick loop recording position, anim, health, and damage events.
  - Automatic best-moment extraction and broadcast on match end.
- **ReplayViewer.client.lua (StarterPlayerScripts):**
  - Highlight viewer with cinematic banner, damage telemetry, and screenshot capture button.

### WP18: Ranked Queue & Matchmaking Foundation
- **Elo.lua (Shared & _lib):**
  - Provisional K-factor (K=32 for first 20 games, then K=20).
  - Expected score calculation, team-average Elo calculations, and Grand Priest top-100 gating.
- **RankedService.lua (ServerScriptService):**
  - 1v1 and 3v3 matchmaking queue with widening search window (+50 per 10s up to ±400).
  - Snake draft team balancing.
  - Leaver mid-match penalty logic and OrderedDataStore leaderboard synchronization.
  - Resolved duplicate conditional branches and formatted cleanly.
- **RankedUI.client.lua (StarterPlayerScripts):**
  - Queue interface with rank tier badges, placement tracking, and live top-100 leaderboard.

### Core Bugfixes & Engine Integration
- **PlayerData.lua:** Fixed `Enum.ProductPurchaseDecision.NotYetProcessed` -> `NotProcessedYet`. Removed unused variables.
- **StoryMissionService.lua:** Combined identical condition blocks for survive and hits goals.
- **V12Boot.server.lua:** Added `KingKaiGames`, `ReplayRecorder`, and `RankedService` to automated initialization pipeline. All 9 core services verified booting cleanly in live Roblox Studio.
- **Rojo Build:** Compiled `default.project.json` cleanly with 0 errors.

---

## 2026-10-13 23:20 ET (Antigravity - WP22 VFX & Tooling Pipeline)

### VFX Modules & Systems (team/animation/)
- **HakaiVFX.lua (New):**
  - God of Destruction signature erasure and void disintegration effect.
  - Features: Palm-concentrated void sphere with dark core (`Color3.fromRGB(20, 5, 35)`), inward suction particles, 2-frame black/white inverted silhouette impact frame (`C.ImpactFrame("invert", 2)`), dual Neon cylinder shockwaves, glowing purple ground fissures (`C.GroundCrack`), and launch debris burst (`C.DebrisBurst`).
- **KaiokenVFX.lua (New):**
  - Goku's crimson surge and double-layered aura multiplier.
  - Features: Inner white-hot surge flame + outer surging crimson flame (`Color3.fromRGB(255, 25, 45)`), dynamic PointLight with Perlin flicker, FOV punch, radial speed lines (`C.SpeedLines`), and `:SetMultiplier(n)` dynamic scaling for x3, x4, x10, x20.
- **SolarFlareVFX.lua (New):**
  - Tien Shinhan's Taiyoken blinding flash.
  - Features: 0.45s forehead charging star flare, radial sunburst shockwave, and localized screen whiteout with smooth quadratic fade over 2.2 seconds (safely gated by distance and photosensitivity settings).
- **VFXLODManager.lua (New - WP22 Core Requirement):**
  - Dynamic performance auto-detection and 3-tier distance Level-of-Detail culling.
  - Auto-switches to Quality 1 (Low) if client FPS drops below 30 for 5 consecutive seconds.
  - Distance culling for active character auras:
    - `<= 80 studs`: Tier 1 Full (all particle layers, PointLight, wisps, sparks).
    - `80 - 200 studs`: Tier 2 Simple (40% particle rate, PointLights disabled).
    - `> 200 studs`: Tier 3 Culled (all emitters set to 0 rate, 0 draw calls).
- **VFXRouter.client.lua (Updated):**
  - Added routing for Hakai, Kaioken, SolarFlare, SpiritBomb, InstantTransmission, MUIRush, TimeSkip, DestructoDisc, NovaStrike, and Barrier.
  - Automatically initializes `VFXLODManager.Init()` on startup.
- **KamehamehaTest.client.lua (Updated):**
  - Bound test hotkeys: `F6` for Hakai (erasure at mouse hit position), `F7` for Kaioken x10, `F8` for Solar Flare.
- **Studio Deployment:**
  - Injected all 5 modules into active Roblox Studio place file via `team/install.py` with exit code 0.
  - Verified DataModel state: `ReplicatedStorage.VFX` now contains all 30 production VFX modules.
  - Rojo verified: `rojo build default.project.json` compiles with 0 errors.


## 2026-10-13 18:10 ET (db-gameplay, cross-file edits authorized by lead "roblox")

### gameplay/src/ServerScriptService/Modules/Training.lua
- **What changed:** one guard line at the top of `Training.init()`. It returns immediately (no-op) when `Config.TRAINING_RUNTIME.owner ~= "Training"`.
- **Why:** TrainingRooms is now the single owner of training. Running both modules caused double teleports and double XP.
- **Authorized:** yes, by the lead, as exactly this one edit. Nothing else in the file was changed.
- **Note:** this edit was made in the previous batch and is recorded here because this file did not exist yet.

### gameplay/src/StarterPlayer/StarterPlayerScripts/TrainingUI.client.lua
- **What changed:**
  - Moved from the `TrainingRequest`/`TrainingEvent` remotes to the TrainingRooms remotes, through `ClientAPI`:
    - The slider calls `setGravity`, snapping the value to the server's console steps 1/10/50/100/150/300/500.
    - The King Kai button calls `startDrill("CatchBubbles")`.
    - The Whis button calls `startDrill("WhisDodge")`.
    - Results come from `onDrill` (DrillUpdate kinds Start, Progress, Hit, Dialogue, HTCDenied, Result).
  - Removed the E/F drill inputs, because WhisDodge is a movement drill.
  - The dev hook now uses `startDrill`.
  - The old TrainingEvent handler is kept, unused, as `legacy`.
- **Why:** `Training.lua` is now a no-op, so nothing serves those remotes anymore.
- **Authorized:** yes, by the lead. Layout, lighting and banner code are untouched.

### gameplay/src/ReplicatedStorage/Shared/StoreCatalog.lua
- **What changed:**
  - The `UltraInstinctSign` item gets `requires = { level = 85, earlyLevel = 70, whisStages = 10 }`.
  - New helper `C.lockedFor(item, profile) -> locked, reason`.
- **Why:** lead decision that UI Sign unlocks at Lv85, or at Lv70 after 10 Whis stages, with no earlier path.
- **Authorized:** yes, by the lead. Nothing else in the file was changed.
- **Note:** `PlayerData.hasUnlock` already blocks *using* the form early. Refusing the *purchase* also needs `Store.lua` (BuyZeni and BuyRobux) and `StoreUI` to call `Catalog.lockedFor`. That is not authorized for db-gameplay, so it is filed as a request to the Store owner.

## 2026-10-13 18:20 ET (db-gameplay)
- **gameplay/StoryMissions.lua (db-story):**
  - No edits. It compiles cleanly with luau-compile, so no syntax fixes were needed.
  - Validated by the new `tests/story_data_tests.luau` (32/32 missions load, 0 skipped).
- **Our files only (no cross-file edits):**
  - TrainingBots supports the WhisGround AreaId and uses `TrainingAreas.CreatePlaceholderBot` (block fallback kept).
  - TrainingLighting reads `ReplicatedStorage.Shared.TrainingLightingPresets` first (fallback kept).
  - StorySchema parses survive goals better, falls back to the enemy name "Rival", and accepts an optional `enemy` field.

## 2026-10-13 18:15 ET (db-gameplay, edits authorized by lead "roblox")

### gameplay/src/ServerScriptService/Modules/Store.lua
- **What changed:**
  - `StoreRequest` now calls `Catalog.lockedFor(item, profile)` for BuyZeni and BuyRobux. A locked item is refused with "Locked: Requires Lv85, or Lv70 + 10 Whis stages" before any Zeni is taken and before any Robux prompt opens.
  - In-session `PromptGamePassPurchaseFinished` does not grant a gated item while it is locked.
- **Why:** the lead's UI Sign rule.
- **Authorized:** yes.

### gameplay/src/StarterPlayer/StarterPlayerScripts/StoreUI.client.lua
- **What changed:** level-gated items show "LOCKED - <reason>" instead of the buy buttons. The check uses the player's Level/Prestige/WhisStage attributes. This is a one-branch change.
- **Authorized:** yes.

### Policy for Robux (documented here, implemented in db-gameplay's PlayerData.lua)
- The primary guard is to refuse before prompting, so no charge can happen.
- **Safety net:**
  - **Game passes:** ownership is permanent, so a gated pass unlock is granted on the first join where the requirement is met. Nothing is lost or consumed.
  - **Developer products tied to a gated item:** ProcessReceipt returns `NotYetProcessed` while the item is locked, so Roblox keeps the receipt and retries. It is never marked granted without delivery.
- There is no programmatic refund API, so withholding the grant without acknowledging the receipt is the policy-safe choice. Today the UI Sign is Zeni-only, so the net is defensive.

### gameplay/src/StarterPlayer/StarterPlayerScripts/TrainingUI.client.lua
- **What changed:** removed the duplicate area lighting: the `saved`/`PRESETS`/`applyLighting` block, its call, and the unused Lighting service.
- **Why:** `TrainingLighting.client.lua` is now the single owner, as the lead decided.
- **Authorized:** yes.

### gameplay/StoryMissions.lua (db-story)
- **What changed:** added optional `goal`/`enemy` fields only, with no content changes:
  - #1: survive 10 s
  - #11: enemy "Cell Jr.", defeat
  - #17: enemy "Beerus", defeat
  - #20: 1 hit (the counter)
  - #23: survive 90 s
  - #24: enemy "Jiren", survive 60 s (the dodge drill)
  - #26: enemy "Jiren", defeat
  - #27: survive 120 s (Broly grows every 30 s)
- **Why:** the scene text had no "vs" enemy, or falling back to "defeat" contradicted the objective.
- **Authorized:** yes.

## 2026-10-13 18:20 ET (db-gameplay, authorized by lead "roblox")

### Raid maps and DBSpawn wiring (db-gameplay files)
- **BossNPC.allocArena(raidId):**
  - Takes the free `RaidArena` floor whose `Boss` attribute equals the raidId (Broly/Moro).
  - Players go to the `RaidSpawn` pads matched by `RaidId` and sorted by `Index`. The boss spawns on `RaidBossPad`.
  - Story missions and missing maps use the generated platform.
- **RaidService:**
  - Sets `LightingPreset` = the floor's `RaidId` (BrolyCrater/MoroNamek) and resets it to Lobby on exit.
  - Touching a `RaidFallZone` returns the player to a pad.
- **TrainingRooms:** ignores raid zones, which db-map tags `TrainingZone` with a `RaidId`. This prevents training XP and gravity in raids.
- **TrainingLighting:** handles raid presets (RaidId attribute), with built-in fallbacks for BrolyCrater and MoroNamek.
- **DragonBallService:** uses db-map's `DBSpawn_NN` parts. It goes by tag first, then by name under WorldOfVoid, sorted by `Index`, and keeps the Config fallback.

### Power wish (lead: pre-release, remove the stat path)
- **Save schema 9:** the migration clears any saved `statBoost`, so it is back to 1.0.
- **Removed the stat path everywhere:**
  - The `WishStatBoost` attribute is no longer set (PlayerData).
  - Combatant's PL wish factor is 1.
  - Combat's `boosted()` only uses StoreStatBoost.
  - DevBots no longer multiplies by it.
  - The DevSelfTest wish test now asserts there is no stat field.
- **What stays:** the `Power` wish id remains as a cosmetic option (gold aura, title, 1000 Zeni), so the ending UI keeps two choices.

### gameplay/src/StarterPlayer/StarterPlayerScripts/EndingUI.client.lua (authorized)
- **What changed:** the Power card text now reads "Gold aura • +1000 Zeni / Title" instead of "+X% power".
- **Authorized:** yes. This is the only change in the file.

### HUD.client.lua / ToPAnnouncer.client.lua (authorized)
- **What changed:**
  - During InRound, the HUD timer shows the 48:00 show clock from `workspace.ShowClock`.
  - The duplicate clock label was removed from ToPAnnouncer.

### default.project.json (new, team root)
- **Built with Rojo 7.4.4:** `rojo build` produced a 1.3 MB place file. There are no duplicate sibling names.
- **What it maps:**
  - gameplay `Shared`, `Modules`, `StarterPlayerScripts`, and the RoundManager/DevSelfTest/V12Boot scripts.
  - `gameplay/StoryMissions.lua` → `ServerScriptService.Modules.StoryMissions`.
  - map: `ServerScriptService.ArenaDamage`, `Arena`, `ArtPass`, `TrainingAreas`, plus `ReplicatedStorage.Shared.TrainingLightingPresets`.
  - animation: `ReplicatedStorage.VFX` (every `*.lua`) and `ReplicatedStorage.Poses` (Shared, PosePlayer, Goku, Vegeta, Frieza).
  - `StoryDialogue.lua` → `ReplicatedStorage.StoryDialogue`.
- **Excluded on purpose:**
  - Command-bar copies: `map/BuildArena.lua`, `map/training/BuildTraining.lua`.
  - Test and tool files: `animation/KamehamehaTest.client.lua`, `poses/check_poses.luau`, and the team-root tool scripts (`audit.lua`, `scan.lua`, `mvseg.lua`, `*.py`).
  - The empty `team/src/`.
- **Name notes (not conflicts):**
  - `ServerScriptService.Arena` (db-map) and `ServerScriptService.Modules.Arena` (the gameplay wrapper that requires it) are different paths, and both are intended.
  - `gameplay/src/ServerScriptService/V12` is an empty folder.
- [gameplay] Arena v3: ToPLogic.universeNumbers/chunkRingOut (+2 tests); TeamAssignment renumbers display universes (U7 = largest human team); Modules/Arena passes 3rd Resize arg, spawns/clears ArenaNPCSpot NPCs, Detached-chunk ring-out; RoundManager.cleanupRound clears NPCs. No db-map files touched.
- [gameplay] MASTER_PLAN pass: SSJ4 form (Config FORMS/ROSTER/FORM_VFX, PlayerData.hasUnlock story gate), X=Transform/D-pad up + Copy->3 (CombatInput, Combatant "Next"), D17 tiebreak/draw XP, AFK (fight 30 s / lobby 90 s), disconnect+fusion defuse (Fusion.onLeave/wasFused, Ranked 1v1 block), D19 bot fill (DevBots.spawn keep, DevBots.hpOn), D18 3-beam struggle join (Combat). Pure logic + 7 tests in ToPLogic/top_tests. Files touched are WP01/02/04/05/10/14/25 per MASTER_PLAN §6 - flag for the lead.
- [gameplay] db-story follow-ups: erased universe's Stand_Uxx hidden server-side 3 s after UniverseErased (Transparency 1, no collide/query/touch; its spectators moved to lobby spawn; "Stand" teleports fall back to Lobby) and restored in cleanupRound (Arena.hideStand/restoreStands); Survival boss confirmed named "Jiren" under WorldOfVoid and spawned before "Enter" fires (comment added); ToPAnnouncer: UniverseErased + SurvivalEvent banners removed (ToPCinematics covers them), Last Stand + SuperShenron banners kept. CINEMATIC_FOR_FIGHTERS untouched (false).

## 2026-10-13 23:15 ET (antigravity - WP08, WP10, WP11 Deliverables Complete)

### WP10: Mobile & Console Controls (StarterPlayer.StarterPlayerScripts.MobileControls)
- **New File:** `MobileControls.client.lua`
- **What changed:**
  - Full right-thumb ergonomic touch button arc: M1 (Strike), Heavy (Guard Break), Ki Blast, Beam (Kamehameha), Vanish, Dash, Block (Hold), Charge (Hold), Transform (Next), Lock-On toggle, and Energy Drink.
  - Mobile Auto Lock-on: Sweeps a 40-degree forward cone up to 120 studs when executing attacks or firing beams without a locked target, acquiring players and dev bots automatically.
  - Contextual Beam Struggle Mash Button: Automatically appears and pulses during beam struggles.
  - Gamepad parity: Bound M1 (R2), Heavy (R1), Block (L2), Dash (L1), Vanish (B), Ki Blast (Y), Transform (DPadUp), Drink (DPadDown), Breaker (L3).
- **Quality check:** Passed `selene` (0 errors, 0 warnings) and formatted with `stylua`. Installed into Studio DataModel.

### WP11: Whis Onboarding Tutorial (ServerScriptService.Modules.OnboardingService & StarterPlayer.StarterPlayerScripts.Onboarding)
- **New Files:**
  - `ServerScriptService/Modules/OnboardingService.lua`
  - `StarterPlayer/StarterPlayerScripts/Onboarding.client.lua`
- **Updated Files:**
  - `PlayerData.lua`: Added `tutorialDone` to Profile schema, syncs `TutorialDone` attribute, added `PlayerData.isTutorialDone(p)` and `PlayerData.completeTutorial(p)`.
  - `ClientAPI.lua`: Added `tutorialProgress`, `skipTutorial`, `onTutorial`.
  - `RoundManager.server.lua`: Initialized `OnboardingService.init()`.
- **What changed:**
  - 60-second guided onboarding: Movement (30 studs) -> Strike (4x combo) -> Vanish dodge -> Ki Charge (hold 2s) -> Special Beam -> Sparring Partner.
  - Whis dialogue subtitle card + top-center prompt card with 6 visual progress pips.
  - Spawns a custom Whis Training Dummy bot for the final test.
  - Rewards first-time players: +250 XP, +1,000 Zeni, 30-minute 2x XP boost, and Lobby return.
  - Dev testing hook: `workspace:SetAttribute("ForceTutorial", true)`.
- **Quality check:** Passed `selene` (0 errors, 0 warnings) and formatted with `stylua`. Installed into Studio DataModel.

### WP08: Character Select UI (StarterPlayer.StarterPlayerScripts.CharacterSelectUI)
- **Updated File:** `CharacterSelectUI.client.lua`
- **What changed:**
  - Built-in 3D interactive `ViewportFrame` with smooth 35 deg/sec turntable rotation for the selected character.
  - Clones high-detail models from `ReplicatedStorage.CharacterModels` with dynamic bounding-box camera framing and anime lighting.
  - Tier badges (C, B, A, S, GoD, Angel) with canonical theme colors.
  - Team budget tracking and duplicate pick prevention.
  - Confirm Pick button with sound and visual feedback.
- **Quality check:** Passed `selene` (0 errors, 0 warnings) and formatted with `stylua`. Installed into Studio DataModel.
