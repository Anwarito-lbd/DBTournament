# Task: Beerus training camp (destroyer path)
Read ANTIGRAVITY_HANDOFF.md, TASK_RACES.md (depends on Races/Modifiers), and the training-mode notes in UPGRADE_UX_PLAN.md. Plan first.

## Place
Beerus's planet zone in the training hub (pyramid, giant trees, fish-oracle NPC). Whis supervises. Solo, PvE.

## Progression (quest chain, saved in PlayerData)
1. **Sparring with Beerus** - survive 60 s of his attacks (dodge/vanish timing).
2. **Destruction energy** - learn the purple ki type: charge orbs, unlocks Destruction Sphere (Sphere of Destruction) move.
3. **Hakai** - mastery trial: Hakai executes only enemies under 15% HP in PvP (raids/bosses: big damage instead), long cooldown, 1 s windup, can be dodged/vanished.
4. **God aura** - passive: small defense bonus while ki >50%.
5. **Ultra Ego path** (Saiyan Vegeta-type only): unlocked after steps 1-3 + Blue; ties to the Ultra Ego modifier in TASK_RACES.md.
- Optional: "Destroyer candidate" title for Pride Trooper race (Toppo path).

## Rules
- All bonuses go through StatResolver; respect the 1.35x paid cap and Ranked normalization.
- Beerus/Whis use built models or placeholders (no ripped game models).
- Cutscenes short and skippable (players hate long cutscenes).
- VFX via VFXCommon (purple destruction aura, Hakai dissolve effect).

## Deliverables
BeerusCamp.lua (zone + quests), DestroyerMoves.lua (Hakai, Destruction Sphere), PlayerData fields, UI quest tracker. Playtest, report, stop.
