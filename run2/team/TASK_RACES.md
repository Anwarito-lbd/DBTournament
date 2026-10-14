# Task: Race classification system (Dragon Block Z)
Read ANTIGRAVITY_HANDOFF.md, gameplay/SPEC.md, gameplay/Config and Combat first. Plan before editing; keep server authority; `--!strict` Luau; data-driven ModuleScript `gameplay/Races.lua` + `gameplay/Modifiers.lua`.

## Races (each: base stats mult, passive trait, ki model, unlockable forms)
| Race | Trait | Forms / power-ups |
|---|---|---|
| Saiyan | Zenkai: +2% stats per near-death survival (cap +10%/match) | SSJ1/2/3, God, Blue, UI Sign→Mastered, Ultra Ego (Vegeta path), Beast is Gohan-only (Half-Saiyan) |
| Half-Saiyan (Earthling/Saiyan) | Hidden potential: rage burst at <25% HP | Mystic/Ultimate, Beast |
| Frieza race | Natural space survival, high ki regen | Forms 1-4/Final, Golden, Black |
| Namekian | Regeneration (slow HP regen out of combat), stretch-limb range | Giant form, Orange |
| Majin | Absorb (heal on grab KO), regen | Super/Kid forms |
| Android | Infinite ki (no ki bar), but no ki-sense/no transformations; flat stat upgrades instead | Barrier, Energy absorb (19/20 type) |
| Pride Trooper / U11 human | Discipline: combo damage +, justice poses | Toppo-tier God of Destruction candidate path |
| Jiren-type | Raw power: huge stats, slow ki regen, Power Impact armor | Full Power, Limit Broken |
| Earthling | Technique: cheaper ki moves, Solar Flare, Kaioken access | Kaioken x2-x20, Wolf Fang, Destructo Disc |
| Kaioshin | Support: heal/teleport/Potara fusion | Potara grants fusion with another player |
| Angel | NPC/admin-only (Whis/Vados/Grand Priest): Autonomous dodge | none (not playable at launch) |
| Destroyer / God | Unlocked via TASK_BEERUS.md | Hakai, Destruction aura |

## Modifiers (stackable)
- Each modifier = {id, stat multipliers, kiDrainPerSec, hpDrainPerSec, allowedBaseForms}.
- Kaioken stacks only on Base and Blue (Blue Kaioken x10 = high HP drain). Not on SSJ1-3/UI.
- Ultra Ego: damage multiplier scales with damage taken (+1% per 2% HP lost, cap +40%); defense lowered.
- Beast: rage meter builds when allies are hit; release = burst.
- Android: infinite ki modifier is a race flag, not stackable.
- Energy drink, Zenkai and rage are temporary buffs.

## Stacking rules
1. finalMult = race × form × product(modifiers) × buffs, then clamp per mode.
2. Paid boosts (gamepasses) are applied as a separate factor capped at **1.35x** total; never exceed regardless of stacking.
3. Ranked: ignore paid factor and normalize form/race to an even stat budget (cosmetic forms only change moves/VFX).
4. Hard global cap (Config.MAX_STAT_MULT) to keep TTK sane; log clamps in DEV_MODE.

## Deliverables
Races.lua, Modifiers.lua, StatResolver.lua (pure, unit-testable), hook into PlayerData + Combat, character select shows race + traits, tests for stacking/clamp. Report and stop.
