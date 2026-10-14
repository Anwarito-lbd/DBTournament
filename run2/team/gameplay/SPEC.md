# Dragon Block Z — Gameplay Systems Spec (v5; main mode: Tournament of Power)
Owner: db-gameplay. Code: `src/` (see README). The cross-team overview is in `../MASTER_DESIGN.md`.

**v3 changes:**
- Prestige and playable divine tiers.
- Spectate camera.
- Last energy gift.
- Team combos.
- Fusion (Dance and Potara).
- `u6_kefla`, and the forms MUI, UltraEgo and KeflaPotara.
- db-map integration: ArenaDamage, the new ring-out rules, tag spawns and Reset.
- Server-validated `RequestMove`.
- Data schema v4.

**v2:** queue/party, Power Level, show rosters, CharacterSelect.

> ⚠️ **IDs need agreeing with db-animation:** every character ID (`u<N>_<name>`, `div_*`), form ID, and move ID (`KiBlast`, `Kamehameha`), plus the `FORM_VFX` preset mapping. Divine IDs may be reused by db-animation for raid NPCs.

**v4 design change (from the user; overrides universe-locked picks):** universes are now just numbered teams (`Universe 1..N`), and any player can pick any unlocked champion. A champion's universe is lore only. Champions have tiers, but **skill must be able to beat stats**. Section 0 below is canonical wherever it conflicts with §6, §7 or §12.

## 0. v4 balance model and skill expression
### 0.1 Teams and picks
- **Teams:** `Universe 1..N`, with `N = min(n, clamp(floor(n/3), 2, 8))`. Spawns use the `ArenaSpawn` pad with `Universe="U0i"`.
- **Picks:** any unlocked champion (roster, bonus, or divine under its rules). Fusion-only results are excluded.
  - **Duplicates:** allowed across teams, but **only one of each champion per team**, first come first served. A rejected pick returns `PickResult(false, id, reason)`; reasons are `Invalid`, `Locked`, `NoTeam`, `TakenByTeammate`, `DivineCap` or `OverBudget`.
  - **Fallback:** the player keeps their previous pick if it's still valid. Otherwise they get the first valid entry in `DEFAULT_PICKS`, and failing that the cheapest valid unlocked champion.
  - **UI attributes:** each Team carries `Budget`, `BudgetUsed` and `Picks` so the UI can grey out taken champions.

### 0.2 Tiers and tier gap compression
- **Tier** comes from base power: `S ≥ 1000`, `A ≥ 850`, `B ≥ 750`, `C < 750`. Divine champions keep their own tier: `GoD`, `Angel`, `GrandPriest` or `Zeno`.
- **Combat stat ratio:** `ratio = clamp((PL_attacker / PL_victim)^0.25, 1/1.35, 1.35)`. This ratio scales damage (×ratio), knockback (×√ratio) and beam-struggle input weight (×ratio). **The total stat edge in any interaction, from tier, level, form, charge, gift and absorb combined, is capped at 1.35×.**
  - **Example:** Zeno at MUI ×6 against a base C-tier champion is ≥ 1.35× → capped at 1.35. Two Lv100 champions at 1000 vs 1200 base → (6000/6200)^0.25 ≈ 0.99.
- **Power Level** stays the big display number (`PowerLevel` attribute). It also feeds matchmaking.

### 0.3 Counterplay by tier (`Config.TIER_RULES`)
| Tier | Hurtbox | Ki regen | Recovery | Budget cost |
|---|---|---|---|---|
| C | 1.00 | 1.00 | 1.00 | 1 |
| B | 1.05 | 0.95 | 1.05 | 2 |
| A | 1.10 | 0.90 | 1.10 | 3 |
| S | 1.20 | 0.85 | 1.15 | 4 |
| GoD | 1.30 | 0.75 | 1.25 | 6 |
| Angel | 1.30 | 0.75 | 1.25 | 7 |
| GrandPriest | 1.35 | 0.70 | 1.30 | 9 |
| Zeno | 1.40 | 0.70 | 1.30 | 10 |
- **Hurtbox:** the hit radius is `2 × hurtbox` studs, added to melee range and to beam width. It is published as the `HurtboxScale` attribute so db-animation can scale the rig to match.
- **Ki regen:** `8/s × kiRegen`, ×3 while charging. The pool is 100.
- **Recovery:** `move.recovery × recovery`. No new move can start during recovery.

### 0.4 Team fairness
- **Matchmaking:** parties and solos are placed into the team with the lowest total Power Level that has room (`base + level·50`).
- **Team power budget:** `sum(tier cost of picks) ≤ 3 × teamSize + 1`. For example, a 3-player team has 10 points: S + A + B = 9 fits, but S + S + S = 12 does not.
- **Divine tiers:**
  - In normal matches they must fit the budget **and** the caps: 1 per team, GoD ≤ 2 and Angel ≤ 1 per match, and ≤ 3 total.
  - Grand Priest and Zeno are **event-mode only**.
  - `EventMode` (a special mode) waives the budget and the total cap.

### 0.5 Skill expression (all server-validated in `Modules/Combat.lua`)
| Mechanic | Rule |
|---|---|
| Block | `Block(true/false)` while facing the attacker (dot ≥ 0.2) takes 15% chip damage and no knockback. Guard meter: 100, with `guardDamage` taken per blocked hit, regenerating at 20/s while not blocking. |
| **Perfect block / parry** | Block pressed ≤ **0.20s** before a parryable hit, including about 80ms latency allowance. The hit deals 0 damage, the attacker is stunned for 0.8s, and the defender gains 10 ki. |
| **Guard break** | A `Heavy` (guardDamage 100, `guardBreak`) or the guard meter reaching 0 breaks guard: 1.2s stun, block disabled, 50% damage. |
| Hitstun | Each hit applies its `hitstun` (0.2–0.6s). While stunned the player cannot move-attack, block, dash or vanish. |
| **Dash / dash-cancel** | `Dash(dir)`: cooldown 0.8s, speed 70 (applied on the server). Dashing during recovery **cancels the recovery** for 15 ki. |
| **Vanish (i-frames)** | `Vanish(dir)`: 25 ki, cooldown 3s, **0.35s invulnerable**. The player teleports behind their last attacker if within 20 studs, otherwise 12 studs in the given direction, with a line-of-sight check and a 25-stud cap. Not usable while stunned. |
| **Combo breaker** | `ComboBreak()`: **only while in hitstun**. Costs 50 ki, cooldown 8s. Clears stun, gives 0.4s i-frames, pushes enemies within 10 studs (knockback 50) and resets the team-combo chain on the player. |
| **Beam struggle** | Two enemy beams fired at each other (each aimed within 20 studs of the other caster) within 0.2s lock into a struggle for up to 4s. `StruggleInput()` is rate-capped at 15/s. Each input scores 1, or **3 if within ±0.12s of the server pulse** (every 0.5s, sent as `StrugglePulse`), multiplied by the compressed ratio. Reaching ±30 wins: the winner's beam hits at **1.25×**. A final score between −3 and +3 is a tie: both players take 15. All beams resolve after a 0.2s clash window. |
| **Ring-out positioning** | `knockback = move.kb × (1 + 1.5 × missingHP%) × √ratio`, directed away from the attacker with a slight lift. The server takes network ownership for 0.5s, so low-HP players fly further toward the db-map ring-out rules. |
| Team combos | Unchanged from §10. |

**Moves:**
| Move | Kind | Cooldown | Range | Damage | Ki | Recovery | Knockback | Guard damage | Hitstun | Parryable | Arena r/p |
|---|---|---|---|---|---|---|---|---|---|---|---|
| M1 | melee | 0.3s | 7 | 5 | 0 | 0.10s | 8 | 8 | 0.35s | yes | – |
| Heavy | melee | 4s | 7 | 10 | 10 | 0.45s | 40 | 100 (break) | 0.6s | yes | – |
| KiBlast | ray, width 1.5 | 1.5s | 150 | 4 | 5 | 0.15s | 12 | 10 | 0.2s | yes | 6 / 25 |
| Kamehameha | beam, width 4 | 10s | 250 | 28 | 30 | 0.6s | 70 | 50 | 0.5s | no | 18 / 120 |
| Absorb (Moro) | melee | 6s | 9 | 6 | 0 | 0.4s | 5 | 20 | 0.5s | yes | – |
| FinalExplosion (Vegeta) | self AoE r35 | once/round, HP ≤ 25% | – | 80 | 50 | 2s charge | 90 | break | 0.6s | no | 35 / 220 |
| Erase (Zeno) | erase | once/match, event only | – | eliminate | 0 | 8s warning | – | – | – | – | – |
| Copy (Moro) | copy | 12s | 60 | – | 20 | 0.3s | – | – | – | – | – |

The client input script is `CombatInput.client.lua`:
- **Moves:** LMB is M1. G Heavy, 1 KiBlast, 2 Kamehameha, Z Absorb, X Copy, T Final Explosion, Y Erase.
- **Defence and movement:** hold F to block. Q dash, E vanish, R breaker.
- **Beam struggle:** V.

### 0.6 Top-tier forms, Moro, Final Explosion, Zeno Erase (aligned with `animation/movesets_v4.md`)
**Forms** (the VFX preset equals the form ID unless a mapping is shown). All of them sit inside the 1.35× compression cap.
| Form | Mult | Lv | Who | VFX preset |
|---|---|---|---|---|
| KeflaPotara | 2.5 | 35 | u6_kefla | KeflaPotara |
| UltraInstinctSign | 5 | 85 | u7_goku | UISign (alias `UISign` accepted) |
| SSBEvolved | 5.5 | 90 | u7_vegeta | SSBEvolved |
| MoroAwakened | 5.5 | 95 | u7_moro | MoroAwakened |
| BeastGohan | 6 | 95 | u7_gohan | BeastGohan |
| FriezaBlack | 6 | 95 | u7_frieza | FriezaBlack (Frieza's FullPower uses `FriezaFullPower`) |
| UltraEgo | 5.5 | 100 | u7_vegeta | UltraEgo |
| MUI | 6 | 100 | u7_goku | MUI |

MUI and UltraInstinctSign are separate forms.

**ID aliases** (`Config.ALIASES`; picks, transforms and save migration v5 resolve them): `bonus_moro→u7_moro`, `UISign→UltraInstinctSign`, `UltraInstinct→MUI`.

**Moro** (`u7_moro`, the primary ID per db-animation; base 1100 = **S tier**, unlock **Lv90**, guest in U7 lore):
- **Absorb** (melee, 6s cooldown): on a hit or guard break, drains up to **20 ki** from the target into Moro and gives Moro **+5% PL** per hit, capped at **+25%**, lasting 15s. This is still inside the 1.35× cap.
- **Copy** (12s cooldown, 20 ki): repeats the last move used in the past 10s by the enemy nearest the aim point (within 60 studs), excluding Absorb and Copy, at **70%** damage, knockback and arena power.
- Both moves are server-validated, and `champion` must equal `u7_moro`.

db-animation's Moro proposal (Absorption Touch channel, Planet Drain ultimate, base 1000 at Lv60) is a later item. Gameplay Config numbers are canonical.

**Final Explosion** (`u7_vegeta`, move `FinalExplosion`; anti-exploit by design):
- **Conditions** (all checked on the server): Vegeta is the active character, HP ≤ **25%**, **once per round**, costs 50 ki, and the player is not stunned, locked or struggling.
- **Charge:** the server runs a **2s armoured charge**: no hitstun or knockback, and all other actions are locked (moves, block, dash, vanish, breaker). Clients receive `PlayVFX("FinalExplosion")` and play `FinalExplosionVFX` with **`OnDetonate = nil` and `ArenaDamage = false`**. The client's detonate callback is never trusted.
- **Detonation:** if Vegeta is still alive, in the round, and on the same character model, the server applies **80 damage** (×ratio, guard break, knockback 90) to enemies within 35 studs plus hurt radius, then calls `ArenaDamage.DamageAt(pos, 35, 220)`.
- **Self-KO:** fires `EliminatePlayer(vegeta, nil, "SelfKO")` and sets HP to 0. This counts as **the caster's elimination**: no killer credit, no Senzu revive, no last gift.

**Zeno** (`div_zeno`): **special mode only** (`EventMode`, i.e. Zeno's Festival). Zeno is non-combat (`Config.NON_COMBAT`): he deals and takes no damage, and his only move is **Erase**.
- Erase is usable **once per match**, enforced by the server (consumed at cast, even if interrupted).
- It gives an **8s warning** (`EraseWarning`), then eliminates **one random living enemy** (`reason="Erased"`; no Senzu, no XP credit).
- The visuals are `FinalExplosionVFX` in white with radius 25 and arena damage off.


### 0.7 Big lobbies (up to 40) and arena resize
- **Player limit:** `Config.MAX_PLAYERS = 40` (8 teams × `MAX_TEAM_SIZE = 5`), and the roster is capped at 40.
- **Team count:** `teams = min(n, clamp(max(floor(n/3), ceil(n/5)), 2, 8))`. Players per team is `min(ceil(n/teams), 5)`.

| Players | Teams | Players per team (max) |
|---|---|---|
| 2 | 2 | 1 |
| 5 | 2 | 3 |
| 9 | 3 | 3 |
| 12 | 4 | 3 |
| 24 | 8 | 3 |
| 25 | 8 | 4 |
| 30 | 8 | 4 |
| 39 | 8 | 5 |
| 40 | 8 | 5 |

- **Parties of 6** are split by the existing oversized-party rule.
- **Budget:** at 5 players a team gets `3×5+1 = 16` points.
- **Spawns:** each team still uses its single `ArenaSpawn` pad (`U01..U08`; the map has 12). Teammates are spread on a circle of radius 7 around the pad, one slot each (72° apart for 5).
- **db-map `Resize(teamCount, playerCount)`:** called after team assignment and before CharacterSelect, so it runs before the teleport.
  - **Where the server looks:** first a ModuleScript named `ServerScriptService.Arena` with a `Resize` function, then `ArenaDamage.Resize`.
  - **Safety:** the call is wrapped in `pcall` and does nothing if neither exists.
  - **After a resize:** `ArenaDamage.Init()` re-scans the arena and the ring-out timers are cleared. Spawns and `RingBounds` (`LowY`/`LowGrace`) are read live from CollectionService every time they're needed, so a changed Y threshold applies straight away.
- **Status:** at the time of writing, `map/` does not contain `Resize` yet. The lookup above is our assumption, so db-map should confirm the module path and signature.


### 0.8 v5 (Dragon Block Z): progression to 500, paid cap, Ranked, energy drink, Training, daily
- **Levels 1–500** (`Config.MAX_LEVEL = 500`).
  - **XP curve:** `xpToNext(L) = floor(60 + 10·L^1.35)` for L ≤ 100, and `5071 + 8·(L−100)` above that.
  - **Cumulative XP:** Lv15 (SSJ) ≈ 3.1k, Lv100 ≈ 217k, Lv500 ≈ 2.9M.
  - **XP sources:** +50 participation per finished match, win or lose (`XP_PARTICIPATION`). There is no XP loss on death.
  - Forms keep their canonical levels, all ≤ 100.
  - **Divine unlocks** come by **level OR prestige**: Destroyer Lv250/P1, Angel Lv350/P3, Grand Priest Lv450/P5, Zeno Lv500/P10.
  - Prestige needs Lv500.
- **Paid stat cap** (`PAID_STAT_CAP = 1.35`, enforced in `Combatant.powerLevel`):
  - **What counts as paid:** a champion or form that is owned but not yet earned by level (prestige 0), plus the energy-drink boost.
  - **How it's capped:** each paid champion or form counts as its ratio over the best champion or form the player has earned. The product of all paid parts is clamped to 1.35. Divine champions are never paid.
  - **Then compression:** the result still goes through the 1.35× combat compression in §0.2.
- **Ranked** (`workspace.Ranked = true`): everyone has PL 3500, `statRatio = 1`, and C-tier counterplay rules.
  - **Disabled:** energy drinks, Senzu and divine picks (`RankedBanned`).
  - Only cosmetics differ. The matchmaking and Elo service is not implemented yet (GDD §7.2).
- **Dragon Block Z Energy Drink** (an original brand with no official logo):
  - **Effect:** +40% ki, **+10% Power Level for 8s** (counted as paid), and +30% speed for 5s.
  - **Limits:** at most 1 per match, used from stock (`EnergyDrinkStock`). It is free in Studio dev mode and disabled in Ranked.
  - **Sources:** the `EnergyDrink3` product (3 drinks, placeholder ID), the daily streak (day 3 and day 7) and quests.
- **Daily rewards** (`Remotes.ClaimDaily`): one claim per UTC day. The 7-day streak is Zeni 100 / 150 / drink / 250 / 500 XP / 400 / 2 drinks + Senzu + `Aura_Streak7`. Missing a day resets it to day 1.
- **Data schema v6:** adds `drinks`, `dailyDay` and `lastDaily`.
- **Solo Training** (Config only; server pending in v1.2): db-map's `map/training` areas with these XP multipliers:

  | Area | XP multiplier | Other |
  |---|---|---|
  | Hyperbolic Time Chamber | ×4 | max stay 600s, gravity 10, trainer Whis |
  | Gravity Room | ×1–2.5 | 1–500G steps, which slow movement |
  | King Kai Planet | ×2 | minigames that unlock KaioKen |
  | Whis Ground | ×3 | Whis UI path and Beerus Hakai / Ultra Ego path |

  Training only feeds the normal XP curve and never grants stats directly.
- **Gameplay-owned items from `UPGRADE_UX_PLAN.md`** (status in GDD §15):
  - **Implemented:** HUD (`HUD.client.lua`), energy drink, data schema v6, daily rewards, the Ranked rules layer.
  - **Spec only:** mobile controls and lock-on, the 3D character select, quests, Dragon Pass, Ranked Elo, lag compensation and the FFA anti-teaming rule.

## 0.9 v6: races, Destroyer path, team Spirit Bomb, training rooms, quests (schema v7)

**Pure modules** (`ReplicatedStorage/Shared`, no Roblox APIs; tests in `gameplay/tests`, run with `sh gameplay/tests/run.sh`, which uses the `luau` CLI; 25 tests):
- `Races.lua`: 12 races, the champion→race map (u11 → PrideTrooper, `div_destroyer_*` → Destroyer, `div_angel_*` → Angel, default Earthling), and `describe(charId)` for character select.
- `Modifiers.lua`: Kaioken x2/x3/x4/x10/x20 (Base and SSB only), UltraEgoGrowth, BeastRelease, RageBurst, Zenkai, GiantForm, GodAura and EnergyDrink (paid). Provides `canStack` and `prune`.
- `StatResolver.lua`: `resolve(ctx)` → total/combat/paid/drains, and `combatRatio`. The rules:
  1. Stats multiply: race × form × modifiers × buffs.
  2. The paid factor is capped at 1.35.
  3. Ranked sets every stat to 1 and ignores paid boosts.
  4. Caps: MAX_STAT_MULT 8 (total) and MAX_COMBAT_MULT 1.6.
- `Quests.lua`: daily/weekly definitions, deterministic roll, track, claim and reroll.

**Server modules:**
- `RaceRuntime`:
  - Modifier state and remotes `ActivateModifier(modId)` and `ReleaseBeast()`.
  - Trait logic driven by the `PlayerDamaged` hook: Zenkai, rage, Beast meter, regen gate.
  - The HP drain/regen tick, and pruning modifiers on `FormChanged`.
  - Attributes: Race, Modifiers, ZenkaiStacks, BeastMeter.
- `Combat` (changed):
  - `damageRatio` (PL × race/mods, compressed once).
  - Angel auto-dodge, Destroyer ki-blast resistance, Majin knockback resistance, Giant form hurtbox ×1.6 and knockback ×1.3, Namekian stretch limb +2.
  - Pride Trooper combo per link, Earthling ki/cooldown ×0.85, Android infinite ki, ki-regen/drain multipliers.
  - `Combat.registerKind`, `Combat.util`, `getKi`/`takeKi`.
  - Quest hooks: parry, struggleWin, teamCombo.
  - `freeForPrefix`/`races` move gating.
- `Combatant` (changed): Android cannot charge. Races with `canTransform=false` (Android, Angel, Destroyer, Kaioshin) can't transform. Quest hook on transform.
- `DestroyerMoves`: Hakai (kind `hakai`). DestructionSphere is a plain ray move.
- `SpiritBomb`: kind `spiritbomb`, remote `GiveKi(holding)`, `Config.SPIRIT_BOMB`.
- `TrainingRooms`:
  - **Owner mode:** teleports, zones, gravity, XP, the HTC limit and the console. **Passive mode** (the default): drills and quest tracking only, because `Training.lua` (v1.2) owns the base loop.
  - Remotes `StartDrill(id)`, `SetGravity(g)`, `DrillUpdate`.
  - Drills: WhisDodge, CatchBubbles, HitGregory, HTCEndure, and BeerusTrial (registered by `BeerusCamp`).
- `BeerusCamp`: the 5-step chain stored in `profile.beerus.step`; attribute `BeerusStep`.
- `QuestService`: remotes `ClaimQuest(scope, i)`, `RerollQuest(i)` and `QuestUpdate`; attribute `QuestsJson`.
  - Tracked keys: match, win, ko, ringout, parry, struggleWin, gift, teamCombo, transform, trainMinutes, gravity300, drill, spiritBombDonate.
- `PlayerData` schema **v7**:
  - Adds zeni, passXp, quests, beerus, early, training {htcDay, htcVisits, kkClears, whisStage, kk, whis}, and title. The migration fills them in.
  - New `early[id]=level`: earned-early unlocks granted by checkUnlocks; `isPaidUnlock` treats them as earned.
  - New helpers: addZeni, spendZeni, grantUnlock, grantEarly, grantReward, sync, saveSoon.
- `RoundManager`: requires and inits the above, plus quest hooks (match, win, ko, ringout, gift).
- **Client:** `QuestTracker.client.lua` (J); `ClientAPI` adds toggleModifier, releaseBeast, giveKi, startDrill, setGravity, claimQuest, rerollQuest, onDrill and onQuests.

## 0.10 v7: lead decisions, sparring bots, race power-ups, training lighting

**Decisions applied:**
- **Training ownership:** `Config.TRAINING_RUNTIME.owner = "TrainingRooms"`, so TrainingRooms is the single owner. It runs teleports, gravity, XP, the HTC limit, the console, drills and rewards, and builds the areas at runtime when they're missing.
  - **The one authorized edit to `Training.lua`:** `Training.init()` now returns immediately unless the owner is "Training".
  - **Save data:** `profile.training` carries both key sets ({kk, whis} and {kkClears, whisStage, htc*}), so either owner works.
- **Ultra Instinct Sign:** Lv85, or Lv70 with all 10 Whis stages (`Config.UI_SIGN_RULE`). `PlayerData.hasUnlock` enforces it for every grant path: store, old Training.lua, passes. Prestige counts as earned.
- **Angels:** `Config.FEATURES.PLAYABLE_ANGELS = false`. With the flag off, `checkPick` returns "NPCOnly", `checkUnlocks` skips `div_angel_*`, and `hasUnlock` returns false. The IDs are kept for NPCs. Grand Priest is unaffected.
- **Zenkai and Hakai:** tuning approved as it is.

**New:**
- **`TrainingBots.lua`:** Gravity Room sparring NPCs.
  - Spawned on TrainingBotSpawn pads while players are in the room; despawned 10 s after it empties.
  - Stats scale with gravity via `TrainingMath.botStats`; HP and damage scale by log10(G).
  - The AI chases and attacks through `Combat.npcHit`, which applies the same i-frames, Barrier, parry and block rules. Sparring never KOs the player.
  - Per KO: 40 XP × the step multiplier and 5 Zeni. Every 5 KOs counts as a "drill" quest tick.
  - Combat lets players act in the Gravity Room outside matches (bots only, no PvP).
- **`TrainingMath.lua`** (pure, tested): stepIndex, extraG and botStats.
- **`RacePowerUps.lua`:** the race power-ups below, all through Combat's validation (unlock, `mv.races`, ki, cooldown, recovery).

  | Power-up | Race | Level | Ki | Cooldown | Effect |
  |---|---|---|---|---|---|
  | Barrier | Android | 5 | 30 | 15 s | 2 s full block, caster locked |
  | JusticePose | Pride Trooper / Jiren-type | 15 | 25 | 30 s | After a 1 s pose, allies within 30 studs get JusticeBuff (+5% damage and defense for 5 s) through StatResolver: compressed, Ranked = 1 |
  | SolarFlare | Earthling | 8 | 20 | 20 s | Enemies facing the caster within 25 studs with line of sight are blinded for 1.5 s (0.75 s in Ranked): they can't fire ki rays; attribute BlindUntil |
  | KaiKai | Kaioshin | 60 | 30 | 25 s | Teleport to an ally within 150 studs or to a point within 80 studs in line of sight; 0.3 s i-frames |

- **Majin KO heal:** a melee KO heals 15% max HP (7.5% in Ranked). The pure logic is `Races.koHeal`, applied in RoundManager `eliminate`.
- **`TrainingLighting.client.lua`:** applies the LightingPreset when TrainingArea is set. It uses db-map's presets if they're replicated (`ReplicatedStorage.TrainingAreas` or `Shared.TrainingLightingPresets`), otherwise a built-in fallback. Lighting is restored on exit.
- **`gameplay/data/races_describe.json`:** 98 champions, with name, race, desc, traits, powerUps, playable and tier. Regenerate with `tests/gen_races_json.luau`.
- **Tests:** 32 in total (`tests/v7_tests.luau` added).

## 1. Round state machine
`Waiting` (fewer than 2 players) → `Intermission` 20s → `CharacterSelect` 12s → `Countdown` 5s → `InRound` (max 300s) → `Results` 8s → cleanup → Intermission.
- **CharacterSelect:** universes are assigned and default picks are set.
- **Countdown:** picks are re-validated and players are teleported to the arena.
- **Cleanup:** `Fusion.resetRound`, `Combat.resetRound`, **`ArenaDamage.Reset()`**, combat state is reset, and players are teleported to the lobby.

State is published through `workspace` attributes `RoundState`, `TimeLeft` and `EventMode`, and through `Remotes.RoundState`.

## 2. Universes, queue, balancing
`teams = min(n, clamp(floor(n/3), 2, 8))`. Teams are named `Universe 1..N` (v4), so there are fewer when player counts are low. Team cap is `ceil(n/teams)`.

**Queue modes:** `Random`, or `Party` (party max 6, invites from the leader only with a 60s TTL, plus auto-party from `GetJoinData().Members`).

**Oversized parties** are split into `ceil(size/cap)` near-equal chunks, snake-drafted by Power Level.

**Balancing:** units are placed largest first into the universe with the lowest total Power Level that still has room. If none fits, the unit is placed one member at a time. The balancing value is `base + level·50`.

## 3. Elimination, ring-out (db-map v1.1 rules), spawns
- **KO:** `Humanoid.Died`. KO credit comes from the `creator` tag, which `Combat.applyDamage` sets.
- **Ring-out** (`Modules/Arena.lua`, polled at 10 Hz), using either rule:
  1. **Surface rule:** the character's bounding box touches a collidable, touchable part where `ArenaDamage.IsRingSurface(part) == false`. Ignored: characters, the tags `Debris`, `RingOutZone`, `RingBounds` and `ArenaCeiling`, and `ArenaCover` pillars still on the ring (r ≤ 150, Y > 480).
  2. **Low rule:** root Y is below `LowY` (480) for more than `LowGrace` (1s). Both values are read from the `RingBounds` part's attributes.

  If the map is not installed, the check falls back to Y < −50.
- **Senzu Bean:** auto-revive at the player's universe arena spawn.
- **Fusion:** if the fused controller is eliminated, the passenger is eliminated too (reason `Fusion`).
- **Win:** last universe standing. On timeout, the most survivors wins; a tie is a draw.
- **Spawns** (CollectionService tags from db-map `BuildArena`, with attribute `Universe="U07"`):
  - Fighters use `ArenaSpawn` matched to their universe. The pad is jittered ±6 studs.
  - Eliminated players and spectators use `StandSpawn` for their universe.
  - The lobby uses `LobbySpawn`.
  - Fallbacks, in order: any pad with the tag, then the folders `ArenaSpawns`/`LobbySpawns`.

## 4. XP, levels, prestige
| Source | XP |
|---|---|
| Playtime | 10/min |
| KO | 15 |
| Placement | 5 × rank |
| Win | 100 |
| Team-combo link | 3 for each of the two players |

Multipliers: DoubleXP ×2, VIP ×1.25, Boost ×2, and **+5% per prestige**. The level curve is `floor(100·L^1.5)` up to level 100.

**Prestige** (`Remotes.Prestige`, only outside InRound): available at level 100, up to 10 prestiges. It resets level and XP and **keeps all unlocks**.

## 5. Power Level
`floor((base + level·50) · formMult · (1 + kiCharge + giftBoost))`, published as the `PowerLevel` attribute.
- **Ki charge:** +0.10/s, capped at +0.5, decays −0.05/s. The player must be alive and standing still (≤ 2 studs/s).
- **Gift boost:** see §9.

**Forms** (canonical multiplier and unlock level; the VFX preset name comes from db-animation `TransformationVFX`):
| Form | Mult | Lv | VFX |
|---|---|---|---|
| Base | 1 | – | – |
| KaioKen | 1.5 | 5 | – |
| FullPower | 1.75 | 10 | (JirenFullPower / ToppoGoD overrides) |
| SuperSaiyan | 2 | 15 | SSJ (CauliflaSSJ override) |
| SuperSaiyan2 | 2.5 | 30 | SSJ2 (KeflaSSJ2 override for Kefla) |
| SuperSaiyan3 | 3 | 40 | SSJ3 |
| KeflaPotara | 2.5 | 35 | KeflaPotara |
| Ultimate | 3.5 | 45 | GohanUltimate |
| Golden | 4 | 55 | GoldenFrieza |
| SuperSaiyanGod | 3.5 | 60 | SSG |
| SuperSaiyanBlue | 4.5 | 75 | SSB |
| Legendary | 4.5 | 75 | KaleBerserk |
| UltraInstinctSign | 5 | 85 | UISign |
| **MUI** | 6 | 100 | MUI |
| **UltraEgo** | 5.5 | 100 | UltraEgo |

- The form previously called `UltraInstinct` is now `MUI`. Save data is migrated in schema v4.
- **Later bonus, not in v3:** BeastGohan and FriezaBlack.
- **`Transform(formId)` is accepted only when:** the round is InRound, the player is alive, the form is in the character's `forms`, the form is unlocked, and the 3s cooldown has passed. On success the server broadcasts `PlayVFX("Transform", character, preset)`.

## 6. Rosters (`Config.ROSTER`, stable IDs)
| U | Characters (unlock level) |
|---|---|
| 7 | goku, vegeta, gohan, piccolo (1); android_17, android_18 (5); krillin, tien (8); master_roshi (12); **frieza (20, stays in U7)** |
| 11 | kahseral, cocotte, kunshi (1); vuon, zoiray, tupper (5); dyspo (10); toppo (20); jiren (50) |
| 6 | cabba, caulifla, kale (1); botamo, magetta (5); frost (8); saonel, pirina (10); hit (15); **kefla (35)** |
| 2 | ribrianne, rozie, kakunsa (1); vikal, hermila, prum (5); jimeze, zircor (8) |
| 3 | paparoni, koitsukai, panchia (1); bollarator, katopesla (5); maji_kayo, viara, nigrisshi (8); narirama (10); anilaza (25) |
| 4 | ganos, shantza, caway (1); majora, damom, gamisaras (5); monna, nink (8) |
| 9 | bergamo, lavenda, basil (1); hop, sorrel, oregano (5); roselle, comfrey (8) |
| 10 | rubalt, jilcol, murisam (1); napapa, jium, obuni (5); lilibeu (8) |

Every ID is prefixed `u<N>_`, so the table's `goku` is `u7_goku`.
- **`u6_kefla`** can be picked directly from level 35 and can also be reached through Potara (Caulifla + Kale). Her forms are KeflaPotara, SuperSaiyan and SuperSaiyan2.
- **`PickCharacter` (v4):** see §0.1. Universe-locked picks are removed, and the roster universe is lore only.
- **Fusion-only results** (`fus_gogeta`, `fus_vegito`) cannot be picked.

## 7. Divine tiers (playable unlocks at the top of progression)
| Tier | IDs | Unlock | Base | Limit |
|---|---|---|---|---|
| Gods of Destruction | `div_destroyer_beerus, _belmod, _champa, _quitela, _sidra, _rumsshi, _iwne, _heles, _mosco, _liquiir, _arak, _giin` | Level 100 **or** prestige 1 | 2000 | ≤ 2 per match |
| Angels | `div_angel_whis, _vados, _marcarita, _cognac, _cukatail, _kusu, _sour, _campari, _martinu, _mojito, _korn` | Prestige 3 | 2400 | ≤ 1 per match |
| Grand Priest | `div_grand_priest` | Prestige 5 | 2800 | 1, **event mode only** |
| Zeno (ultra-rare) | `div_zeno` | Prestige 10 | 3200 | 1, **event mode only** |

Each `_name` stands for the full ID, so `_belmod` is `div_destroyer_belmod` and `_vados` is `div_angel_vados`.
- Divine champions can be picked by anyone (v4), subject to the budget and caps in §0.4.
- **Caps:**
  - Each divine ID is unique per match.
  - At most 1 divine per team.
  - At most 3 divines per match in normal mode.
  - `workspace.EventMode=true` lifts the total cap and enables Grand Priest and Zeno.
- Divine characters have no transformations.
- Balance them as rare picks: high base, but no forms and capped numbers. db-animation may reuse the IDs for raid NPCs.
- When a pick is invalid, the player falls back to their universe's default character.

## 8. Spectate
- **Server:** when a player is eliminated, the server sets `Spectating=true` and `SpectateTarget=<userId>`, choosing a living teammate first and otherwise anyone alive. When the watched player is eliminated, spectators are retargeted. The spectating player is moved to their universe's `StandSpawn`.
- **`SpectateRequest(userId)` is accepted only when:** the requester is spectating, the target is alive and not a fusion passenger, and the target is a teammate unless no teammate is alive.
- **Client (`SpectateCamera`):** a wide orbit camera (distance 70, height 30) around the target. Q and E cycle targets. F toggles a free camera (WASD, Space/Shift, right mouse to look). Control returns to normal when spectating ends.

## 9. Last energy gift
- **Window:** when a player is eliminated by KO or ring-out (not when leaving or via fusion), they get **2s** to gift, provided an alive teammate is within 40 studs of their **death position**. The server fires `LastGift(2, candidateIds)`, and the player answers with `GiftEnergy(targetUserId)`.
- **Server checks:** the window is open, the player hasn't gifted this round (**one per round**), the target is alive, on the same team, within 40 studs of the death position, and not a fusion passenger.
- **Effect:**
  - The target gains `giftBoost += min(0.5, 0.25 + victimCharge·0.5)` for 20s, with the total capped at 0.5.
  - The target also gains `victimCharge·0.5` ki charge, capped.
  - The hook `LastGift(from, to)` fires.

The elimination is final at the moment of KO. The gift is a "dying breath", and the teleport to the stands waits until the window closes.

## 10. Team combos
`Combat.registerHit(attacker, targetModel, baseDamage) -> multiplier`. It is also available as the BindableFunction `ServerStorage.ServerHooks.RegisterHit` for combat code that doesn't require the module.
- **Links:** a hit from a *different teammate* on the same target within 1.5s of the last hit adds one link, up to 5 links. The multiplier is `1 + 0.10·links`.
- **Rewards:** each link gives both players 3 XP and fires the `TeamCombo` hook and remote.
- **Continuations:** the same attacker hitting again keeps the chain alive without adding a link.
- **Damage:** `Combat.applyDamage` uses this multiplier together with the Power Level ratio clamp (0.5–2×). There is no friendly fire.

## 11. Fusion
| | Fusion Dance | Potara |
|---|---|---|
| Requirement | Both players stand still (≤ 2 studs/s) within 12 studs | Either player has the `Potara` unlock (Lv35 power-up or the PotaraEarrings pass), within 10 studs |
| Channel | 3s, **vulnerable**: any damage taken or movement fails it | 1.5s (matches the db-animation Kefla spec), damage fails it |
| Duration | 60s | 90s |
| Pairs → result | goku+vegeta → `fus_gogeta` | goku+vegeta → `fus_vegito`; caulifla+kale → `u6_kefla` |

**Flow:**
1. Both players send `FusionRequest(method, partnerId)` to each other within 5s. The server validates: InRound, both alive, teammates, not busy, not on cooldown, a valid pair, in range, and earrings for Potara.
2. The channel runs.
3. On success, the player with the higher Power Level (excluding temporary boosts) **controls** the fused character, with HP = average × 1.3. The other player is the **passenger**: anchored at their universe stand, with `FusedPassenger` and `Spectating` set and the camera following the controller. Passengers are excluded from ring-out and combat checks.

**Endings:**
- **Timeout or round end:** both players are restored next to each other. Each gets the fused HP percentage of their own max HP, and their original picks are restored.
- **Controller eliminated:** the passenger is eliminated too.
- **Passenger leaves:** the fusion is undone early.
- **Failure:** a 10s cooldown applies to both players.

**Hooks:** `Fused(controller, passenger, id, method)` and `Defused(controller, passenger, reason)`. The VFX preset `KeflaPotara` plays on Kefla's fusion.

## 12. Combat moves and arena damage (db-map integration)
`RequestMove(moveId, targetPos, origin?)` is **validated on the server**:
- the round is InRound and the player is alive, not a passenger, and has the move unlocked;
- the move's cooldown has passed;
- a client-supplied `origin` must be within 8 studs of the root, and the server always casts from the root;
- the target must be within range;
- requests are rate-limited (4/s).

| Move | Unlock | Cooldown | Range | Damage | `DamageAt` radius / power |
|---|---|---|---|---|---|
| KiBlast | KiBlast (Lv3) | 1.5s | 150 | 4 | 6 / 25 |
| Kamehameha | SignatureBeam (Lv10) | 10s | 250 | 28 | 18 / 120 |

**Resolution:** raycast hit → `Combat.applyDamage` → `ServerScriptService.ArenaDamage.DamageAt(hitPos, r, p)` (wrapped in `pcall`; a no-op if the module is missing) → `PlayVFX:FireAllClients(moveId, character, hitPos)`. Clients play the visuals only, with **`{ ArenaDamage = false }`**, following the db-animation/db-map contract.

Ki cost is not modelled server-side yet. It's a v4 item, aligned with db-animation's `movesets` ki numbers.

## 13. Monetization (placeholder IDs = 0)
| Type | Key | Effect | Suggested R$ |
|---|---|---|---|
| Game Pass | DoubleXP | ×2 XP | 299 |
| Game Pass | VIP | ×1.25 XP | 149 |
| Game Pass | EarlySuperSaiyan | SuperSaiyan | 199 |
| Game Pass | EarlyBlue | SuperSaiyanBlue | 799 |
| Game Pass | EarlyJiren | `u11_jiren` | 499 |
| Game Pass | PotaraEarrings | `Potara` | 249 |
| Dev Product | XPBoost30 | 30 min ×2 XP | 49 |
| Dev Product | XPPack500 | +500 XP | 75 |
| Dev Product | SenzuBean | 1 revive | 25 |

- **Divine tiers are never sold.** They come from prestige and level only.
- There are no paid random items.
- ProcessReceipt is idempotent: purchases are deduplicated by `PurchaseId` in `receipts`, `Granted` is returned only after a successful save, and on failure the profile is rolled back from a snapshot.

## 14. Data (DataStore `ToP_PlayerData_v1`, key `u_<UserId>`, schema v5)
```
{ version=5, xp, level, totalXp, wins, kos, playtime, prestige,
  unlocks={[id]=true}, senzu, boostUntil, receipts={...}, lock={jobId,t}|nil }
```
**Migrations:**
- v1→v2: senzu, boostUntil, receipts.
- v2→v3: drop legacy race unlocks.
- v3→v4: add prestige, rename `UltraInstinct`→`MUI`.

**Session lock and saving:**
- The session lock uses UpdateAsync with a 30-minute stale timeout.
- Saves use retries with backoff.
- Autosave runs every 120s.
- BindToClose saves on shutdown.

## 15. Remotes and hooks
**Server→client:**
- `RoundState`
- `PlayerEliminated`
- `LevelUp`
- `QueueState`
- `PartyInvite`
- `LastGift`
- `FusionState(state, data)`
- `TeamCombo`
- `PlayVFX`

**Client→server** (type-checked, rate-limited and state-checked):
- `QueueRequest`
- `PickCharacter`
- `KiCharge`
- `Transform`
- `RequestMove`
- `GiftEnergy`
- `SpectateRequest`
- `FusionRequest`
- `FusionCancel`
- `Prestige`

**ServerHooks:**
- Bindables:
  - `EliminatePlayer`
  - `RoundStarted`
  - `RoundEnded`
  - `CharacterPicked(player, charId)`
  - `FormChanged`
  - `PlayerDamaged`
  - `TeamCombo`
  - `LastGift`
  - `Fused`
  - `Defused`
- BindableFunction: `RegisterHit`

**Attributes:**
- Progression: `Level`, `XP`, `XPToNext`, `Prestige`, `Senzu`
- Round: `Alive`, `Spectating`, `SpectateTarget`, `DataLoaded`
- Queue: `QueueMode`, `PartyLeader`
- Combat: `Character`, `Form`, `KiCharge`, `Charging`, `PowerLevel`, `GiftBoost`, `GiftWindow`
- Fusion: `Fused`, `FusedPassenger`, `FusionPartner`, `FusionState`

## 16. Anti-exploit
- **Server decides:** all damage, eliminations, XP, unlocks, fusions and gifts.
- **Clients send intent only.** Every remote is type-checked and rate-limited with a per-player token bucket.
- **Range checks** use server positions, and a client-claimed origin is checked to within 8 studs.
- **Game pass ownership** is checked on the server and cached.
- **Divine caps** are enforced at pick time.
- **TODO:** a speed/teleport sanity check, and ki costs on moves.

## 17. Integration
- **db-map:** see §3 and §12, `Arena.lua`, and `map/layout_spec.md` v1.1. `ArenaDamage` must be installed as a ModuleScript at `ServerScriptService.ArenaDamage`.
- **db-animation:**
  - The VFX presets are mapped in `Config.FORM_VFX` and `FORM_VFX_OVERRIDES`.
  - `VFXRouter.client.lua` plays `ReplicatedStorage.VFX.<Module>.Play(char, target, {ArenaDamage=false})`.
  - Hook `CharacterPicked` and `FormChanged` to swap rigs.
  - Agree the IDs (see the warning at the top).
  - db-animation's Kefla spec (hold T for 1.5s, 10 studs, 90s) matches the Potara numbers here.
- **db-story:**
  - Use `RoundStarted`/`RoundEnded` for the intro and ending cutscenes and the wish choice.
  - Use `Fused` for fusion lines and `LastGift` for sacrifice lines.
  - Divine IDs line up with the gods and angels in `story.md`.


## 0.11 v8 (2026-10-13): Dragon Balls, Ranked, Raids, Story, Kai Kai kit, cross-file edits

**Save schema 8** (migration `v < 8`) adds:
- `ranked { elo, games, wins, losses, peak, season, lastPlayed }`
- `dragonBalls { week, have[7 dense booleans], summoned, wishPending, lastCollect }`
- `raids { firstClearWeek{[raidId]=week}, clears }`
- `story { done{[tostring(id)]=true}, badges{} }`

`grantReward` now accepts `cosmetic` (it sets `unlocks[id]`).

**Kai Kai kit.**
- Added `u7_shin` "Shin" (760, Lv20) and `u10_zamasu` "Zamasu" (880, Lv60). Both are Kaioshin race (`Races.CHAMPION`). They need db-animation rigs.
- `Config.MOVES.KaiKai.freeForIds = {u7_shin, u10_zamasu}`. Combat's unlock gate now honors `freeForIds`, so the move is in their kit from Lv1 with no Lv60 unlock needed, independent of race.
- `races_describe.json` was regenerated with a new `kit` field.

**Dragon Balls.**
- **Modules:** `Shared/DragonBalls.lua` (pure) + `Modules/DragonBallService.lua`.
- **Remotes:**
  - s→c: `DragonBallState` (only that player's ball positions)
  - c→s: `CollectDragonBall(i)`, `SummonShenron()`
  - both ways: `ShenronWish(wishId, choice?)`
- **Ball positions:** anchors come from db-map tag `DragonBallSpawn` (≥7 BaseParts). Without it, 10 fallback anchors in the training areas are used.
- **Attribute:** `DragonBalls` (count).

**Ranked.**
- **Modules:** `Shared/Elo.lua` (pure) + `Modules/RankedService.lua`.
- **Remotes:** `RankedQueue(format)`, `RankedLeave`, `RankedUpdate`, `RankedLeaderboard`.
- **Attributes:** `RankedElo`, `RankedRank`, `RankedSeason`, `RankedGames`.
- **Ranked server:** teleport data sets `workspace.Ranked`/`RankedFormat`/`RankedSeason`. RoundManager waits for all expected players (after 90 s, it starts once at least 2 are present) and uses `RankedService.groups` for teams.

**Raids.**
- **Modules:**
  - `Modules/BossNPC.lua`: boss engine, arenas, AI, specials, phases.
  - `Modules/RaidService.lua`: queue, run and rewards.
  - `Shared/RaidMath.lua` (pure).
  - Config: `Config.RAIDS`, `Config.RAID_RUNTIME`.
- **Remotes:** `RaidJoin(id)`, `RaidLeave`, `RaidUpdate`, `RaidInfo` (published odds).
- **Attributes:** `InRaid`, `RaidId`.
- **Combat:**
  - `canAct` allows `InRaid` players outside rounds.
  - Hit fallback order is DevBots → TrainingBots → BossNPC.
  - `npcHit` gained `mv.lethal`.
  - New `Combat.lastMoveId`.
- **Other modules:**
  - RoundManager skips `InRaid` players when building a ToP roster.
  - Hakai uses `bossDamage` (70) on bosses. Spirit Bomb hits bosses.
- **Boss models:** attributes `BossId` and `AnimId` (`u7_moro`, `boss_broly`, `story_<enemy>`). Tag `Boss`.
- **Telegraph events:** CombatEvent `BossTelegraph`/`BossSpecial`/`BossPhase`/`BossDefeated`.
- **Arena:** db-map tag `RaidArena` (a BasePart floor) if present. Otherwise a 220×4×220 platform is generated at z=12000 (+800 per instance).

**Story.**
- **Modules:** `Modules/StoryMissionService.lua` + `Shared/StorySchema.lua` (pure).
- **Remotes:** `StoryList`, `StoryStart(id)`, `StoryUpdate`.
- **Status:** `/workspace/roblox/team/story/` does not exist. db-story's file is `gameplay/StoryMissions.lua`: 20+ missions in the format below.
- **Lookup:** the service requires the first ModuleScript named `StoryMissions` in `ServerScriptService.Modules`, `ServerScriptService`, `ServerStorage` or `ReplicatedStorage.Shared`. If none is found, it logs a warning and the story stays disabled (`StoryList → {available=false}`).
- **Expected schema** (bad entries are skipped with a warning):
```lua
return {
  { id = 1, arc = "Saiyan", name = "Raditz Ambush", scene = "Goku vs Raditz alongside Piccolo", character = "Goku",
    objective = "Survive 90s",               -- parsed into goal if `goal` is omitted
    goal = { type = "survive", seconds = 90 }, -- optional: defeat | survive{seconds} | hits{count} | timed{seconds}
    fail = "Goku KO'd", twist = "...",
    rewards = { xp = 300, zeni = 500, title = "Unlikely Allies", form = nil }, -- form = cosmetic badge only; xp/zeni clamped 0..5000
    dialogue = { "Piccolo: Keep him busy." } },
}
```
- **Enemy:** the text after "vs" in `scene` (cut at "while" or "beam clash").

**Cross-file edits:** `TrainingUI.client.lua` and `StoreCatalog.lua`, as authorized by the lead. See `/workspace/roblox/team/CHANGES.md`. Also, TrainingRooms `SetGravity` now works room-wide (the console range was dropped) to match the slider.

**Open issues / requests:**
- **Store owner:** call `Catalog.lockedFor(it, PlayerData.get(p))` in `Store.lua` BuyZeni and BuyRobux, and show the lock in StoreUI. Until then the UI Sign *purchase* goes through, but using it is still blocked by `PlayerData.hasUnlock`, so a player could spend Zeni on something they can't use yet.
- **TrainingUI vs TrainingLighting:** both apply area lighting. One should be removed. TrainingUI's owner decides.
- **db-map:** tags `DragonBallSpawn` (≥7) and `RaidArena`.
- **db-animation:** rigs for `u7_shin`, `u10_zamasu`, `boss_broly`, and `story_*` enemies. Boss anims for EraserCannon, Stomp, Absorb and PlanetDrain.
- **Rojo / db-story:** map `gameplay/StoryMissions.lua` to `ServerScriptService.Modules.StoryMissions`.
- **UI (client) owners:** Dragon Radar, Shenron wish picker, ranked queue/leaderboard panel, raid lobby (with odds) and story list. Remotes are ready in ClientAPI.
- **Ranked queue:** per server only. A cross-server MemoryStore queue is a follow-up. A leaver's Elo is written on PlayerRemoving; save ordering against PlayerData is best effort.
- **RaidService.init** also drives the BossNPC tick that Story uses, so it must stay initialized.


## 0.12 v8b (2026-10-13): client panels + ToP polish

**Lead approvals:** Shin/Zamasu and the Ranked, raid and story numbers are approved. The Store lock, TrainingUI lighting removal and StoryMissions goals are logged in `/workspace/roblox/team/CHANGES.md`.

**New client UI** (new files only; built in code; all calls go through ClientAPI):
- **Shared style:** `Shared/UIStyle.lua` carries the UIKit look: GothamBold/Black, navy panels, gold UIStroke, gradients, Back/Quad tweens. It provides:
  - scale-based panels with a size constraint (larger on touch devices)
  - `Activated` buttons (mouse, touch and gamepad)
  - a toggle key plus an on-screen touch button per panel
  - `S.remotes()`, which waits with a timeout so a missing remote never hangs and the script simply exits
- **Panels:**

  | Script | Key | Purpose |
  |---|---|---|
  | `DragonRadar` | N | rotating radar, local ball render, auto-collect on proximity |
  | `ShenronWishUI` | P | auto-opens on a wish window |
  | `RankedUI` | K | queue 1v1/3v3, Elo/rank/season, top 100 |
  | `RaidLobbyUI` | O | published drop odds, first-clear reward, queue/countdown |
  | `StoryUI` | M | arcs, locks, goal, enemy, rewards |
  | `ToPAnnouncer` | — | show clock plus erase/event/Shenron/Last Stand banners |

- **Server change:** `StoryList` now includes `enemy`.

**ToP polish:**
- **Pure rules (tested):** `Shared/ToPLogic.lua`, with tests in `tests/top_tests.luau`. It covers show clock, team scaling, comeback, erasure/win resolve, event scaling, and the ending-reward lint.
- **Team scaling:** TeamAssignment's team count and cap now delegate to ToPLogic. Verified for 2..40 players: up to 8 universes of at most 5, and capacity always ≥ n. The arena path is unchanged and verified: `Arena.resize(#universes, #fighters, universes)` runs before character select.
- **Remotes (s→c):**
  - `UniverseErased {team, universe, placement, by}`
  - `SurvivalEvent {phase Warn|Enter|Defeated|End, name, ...}`
  - `SuperShenron {phase Summon|Granted, winner, wish}`
- **Server hooks:** `UniverseErased`, `SurvivalEvent`, `SuperShenron`, `SpiritBombThrown`.
- **Attributes:** `workspace.ShowClock` (show-seconds left), player `LastStand`.
- **Modifier:** `LastStand` (paid bucket, damage 1.12).
- **Combat:**
  - `Combat.lastAttacker(p, within)`
  - `npcHit` gained `mv.inRound` (ToP event boss)
  - BossNPC `def.topEvent` lets it target and be hit by `Alive` fighters
- **Audit fixes:**
  1. A ring-out never credited a killer, so ringout quests and KO XP never counted. It now credits the last enemy hit within 6 s.
  2. The last-gift range for a ring-out was measured from the fall position. It now uses the last in-ring position.
  3. Bot-team wipes were never placed or erased. `checkWipes()` now runs after bot eliminations too.
  4. The Super Dragon Ball "Power" wish granted +10% stats. It is now cosmetic/Zeni only.
  5. A Spirit Bomb channel could leak into the next round. `SpiritBomb.resetRound()` now clears it.
  6. The event boss is despawned at round end.
- **Spectate audit:** no bugs found. It prefers teammates, allows enemies only once your team is out, retargets when the target is eliminated or leaves, and resets in cleanup.

**Requests:**
- **EndingUI owner:** the "Power" card still reads "+X% power" from `w.statBoost`, which is now nil, so it shows +0%. Switch it to the aura, title and 1000 Zeni.
- **Lead decision:** existing profiles may still hold a legacy `statBoost` 1.1 from past wins (PlayerData applies it). Keep it as grandfathered, or strip it with a migration?
- **db-animation / db-story:** hook `UniverseErased` (Zeno erase), `SurvivalEvent` (Jiren entrance) and `SuperShenron` (ending cinematic).
- **HUD owner:** optionally move the ShowClock display into HUD and drop the label in ToPAnnouncer.

## 0.13 v9 (2026-10-13): raid maps, DBSpawn, Power wish removal, HUD clock, Rojo
- **Raid maps:** db-map's raid maps live under `WorldOfVoid.Raid.{BrolyCrater,MoroNamek}`.
  - The `RaidArena` floor has attributes `Boss` (= our raidId Broly/Moro) and `RaidId` (the area/preset name). There are 8 `RaidSpawn` pads (RaidId, Index), a `RaidBossPad`, and a `RaidFallZone` (which returns the player to a pad).
  - Player attribute `LightingPreset` is set to the area id while in a raid.
  - TrainingRooms ignores zones that have a `RaidId`.
- **Dragon Balls:** anchors are db-map's `DBSpawn_NN` parts (tag `DragonBallSpawn`, attrs AreaId/Index), with the name and Config fallbacks kept.
- **Save schema 9:** clears `statBoost`. The Power wish is now cosmetic + 1000 Zeni, and no stat-wish code path remains.
- **HUD:** shows the 48:00 show clock in a round. ToPAnnouncer only shows banners now.
- **Rojo:** `/workspace/roblox/team/default.project.json` is validated with `rojo build` (Rojo 7.4.4). See CHANGES.md for the mapping and exclusions.

## Arena v3 integration
- Display universes: TeamAssignment renumbers teams via ToPLogic.universeNumbers(humanCounts): U7 = largest human team (first on tie, Bulma's cheer spot), others 1..6,8.. by team index. Team.Name "Universe N", attr Universe=N, UniverseIndex=i (HUD/announcer/UniverseErased read these). Arena.resize passes {[i]=N} as Resize's 3rd arg; spawns map N -> index.
- NPCs: after Resize, Arena.spawnNPCs places anchored placeholder models (tag ArenaNPC; attrs NPC/UniverseNumber/Team/Cheer) at ArenaNPCSpot parts in workspace.ArenaNPCs; Zeno-box spots (CutsceneId) left to cutscenes. cleanupRound -> Arena.clearNPCs.
- Chunk DamageStage: 3/Detached under a fighter = ring-out (ToPLogic.chunkRingOut; checked before the CanTouch filter since detached chunks are CanTouch=false). IsRingSurface already false for detached, so both agree. Stages 1-2 (Cracked/Cratered) are visual only: no hidden speed/footing penalties, which would be hard to read and unfair to whoever happens to stand there.

## v9 alpha edge cases + SSJ4 (MASTER_PLAN is canonical)
- SSJ4 (Daima/GT red fur): Config.FORMS.SuperSaiyan4 = mult 5, Lv80, story = 32 ("Mini Mayhem"); Goku (after SSB) and Vegeta (after SSB). Below MUI 6 / UE 5.5; normal compression (StatResolver 1.35x) applies. Gate (D24): PlayerData.hasUnlock -> ToPLogic.storyFormOk (mission 32 cleared AND Lv80, prestige counts as level); not in the level-only UNLOCKS list, so no paid/flag bypass. VFX preset id "SSJ4" (Config.FORM_VFX) - requested from db-animation; generic aura until it exists.
- Controls (D21): X / D-pad up = Transform (server "Next": next unlocked form in the ladder, Base after the top; ToPLogic.nextForm). G = Heavy. Moro Copy moved X -> 3.
- D17: time-up winner = most survivors, then summed HP fraction, else draw; draws give tied teams XP_WIN x0.5. 0 teams left with wipes in the same 0.15 s = draw between them (ToPLogic.resolveTimeout).
- §10.1 AFK: activity = >2 studs moved, a combat action (Combat.lastActiveT), or charging, sampled 1 Hz. 30 s idle in a fight -> eliminated "AFK" to spectate (no gift); 90 s idle in the lobby -> skipped by the roster (attr AFK). Bots never AFK. Known limit: knockback movement counts as activity.
- Disconnect: mid-round leave = elimination, no gift, no XP loss. Fused: leave defuses (Fusion.onLeave), partner keeps HP% (D20).
- D20 fusion: KO / ring-out / AFK of the fused body eliminates both, no gift; fusion refused in Ranked 1v1 ("Ranked1v1").
- D19: 2-3 humans -> ToPLogic.botFill adds DevBots up to 4 fighters, smallest team first (never Ranked); bot KOs give 50% XP, no quest ticks.
- D18: beam struggles are 1v1 plus at most one joining beam (3 max). A beam aimed within 20 studs of an enemy struggler joins on the opposite side at x0.5 input weight; a struggle that already has 3 beams can't be joined (ToPLogic.struggleCanJoin).
