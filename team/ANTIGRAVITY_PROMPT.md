ANTIGRAVITY'S TASKS (Oct 13, 5:48 PM). Grok Bot is building the shop, the training camps, the pose animations and the transformation VFX at the same time. Do NOT edit those files (Shop*, Training*, animation/poses/*, TransformationVFX, GameFeel). Your scope: (1) Mobile and console controls: on-screen buttons for attack, ki blast, vanish, power-up, lock-on and the drink, with auto lock-on on mobile. Put them in a new MobileControls.client.lua. (2) A 60-second Whis tutorial for first-time players: move, attack, vanish, power-up, beam, then an easy bot match. Put it in a new Tutorial.server.lua and Tutorial.client.lua. Save progress in PlayerData. (3) Character select screen with a 3D preview and tier tags, in a new CharacterSelect.client.lua. Plan first, play-test each one, and list every file you changed at the end.

UPDATE (Oct 13, 5:40 PM): v1.1 tasks 1, 2, 3 and 5 are DONE: GameFeel.client.lua, Vanish visuals, the 3-stage power-up, lock-on, the energy drink and the guard framing. Do not redo them. Start with task 6 (mobile controls and the Whis tutorial). Also check the lobby banner: it should read DRAGON BLOCK Z, not TOURNAMENT OF POWER. Read the code first.

# Paste this into Antigravity (Agent Manager / agy). Model: Gemini 4 Argon if your plan has it (Ultra), otherwise Gemini 3.8 Flash or Claude Opus 5.5.

You are working on the Roblox game **Dragon Block Z** (main mode: Tournament of Power).
Workspace: C:\Users\issao\Documents\DBTournament\team\   Place file: C:\Users\issao\Downloads\Place1.rbxl

1. Read `ANTIGRAVITY_HANDOFF.md` fully, then `gameplay/SPEC.md`, `animation/VFX_QUALITY_BAR.md`, `animation/VFXCommon.lua` and the Combat script in `gameplay/`. Follow every rule in the handoff (1.35x P2W cap, Ranked evens stats, no ripped game models, DEV_MODE stays on during dev).
2. Start **v1.1 task 1**: hook VFXCommon's hitstop, camera shake, impact frames and auras into Combat so they fire on hits/forms and play nicely with the gameplay camera (no camera fights, restore CFrame/FOV after shake; client-side VFX triggered via RemoteEvent from server-validated hits).
3. Luau rules: `--!strict` where practical, ModuleScripts in ReplicatedStorage/ServerScriptService, server authority for damage, no `wait()` (use `task.wait`), clean up connections/instances (Debris or Maid), keep per-hit cost low for 40 players.
4. Use the `Roblox_Studio` MCP tools to inspect the open place and insert/update scripts; keep the .lua files in this folder in sync with what you put in Studio.
5. Before editing, show me a short plan (files + changes). After editing, playtest in Studio, report what works, what is untested, and stop. Do not start task 2 until I say so.


