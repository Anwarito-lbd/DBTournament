# Dragon Block Z: handoff for Antigravity

## Project
Roblox game "Dragon Block Z". Its main mode is "Tournament of Power".
- Place file: C:\Users\issao\Downloads\Place1.rbxl
- Code: C:\Users\issao\Documents\DBTournament\team\

## Read these first
- MASTER_DESIGN.md: the full game vision.
- gameplay/SPEC.md: game systems. Config, RoundManager, Combat, Fusion, Party, PlayerData, TeamAssignment and DevBots are in gameplay/.
- UPGRADE_UX_PLAN.md and PLAYER_RESEARCH.md: the roadmap, the top 10 upgrades and the powers list.
- animation/VFX_QUALITY_BAR.md and animation/VFXCommon.lua: hitstop, camera shake, impact frames, auras and beam effects.
- story.md, StoryDialogue.lua and CutsceneDirector.lua: the intro and ending cutscenes.
- map/: BuildArena, ArenaDamage, Arena (Resize) and ArtPass.

## Models
- sketchfab_out\*.fbx: 103 exported models. CREDITS.md has the licences, and the CC-BY-SA ones are Zeno and Piccolo.
- They have to be brought in by hand with File > Import 3D. Skip Frieza Emperor and goku_1b2295, which are broken.

## Studio MCP
- StudioMCP.exe is registered as "Roblox_Studio", and mcp.py is a client for it.

## Blender
- The Blender MCP connection is on socket localhost:9876.
- team\blender_pipeline.py batch-processes models.

## Rules
- Pay-to-win is capped at 1.35x stats, and Ranked evens stats out.
- Turn Config.DEV_MODE off before release.
- Set Max Players to 40.
- Don't use models ripped from official games (FighterZ, Xenoverse, Sparking Zero, Legends, Budokai).

## Next tasks (v1.1)
1. Hook VFXCommon's hitstop, shake, impact frames and auras into Combat, so they work with the gameplay camera.
2. Add the Vanish dodge, the 3-stage screaming power-up with the power level readout, and lock-on.
3. Add the Dragon Block Z energy drink item: 40% ki and a 5 s speed boost, once per match.
4. Place the imported Sketchfab models in the intro, ending, fusion and arena.
5. Fix the guard being cut off at the edge of intro shots 05 and 06.
6. Add mobile controls and the Whis tutorial.
