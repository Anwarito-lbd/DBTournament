# AI_RULES - shared rules for Antigravity / OpenCode agents

## File ownership (do not edit files you don't own)
- Studio executor: Studio place + Lua in team\src, team\gameplay, install.py. Others: read only.
- Antigravity / OpenCode: only the files named in your TASK_*.md (e.g. TASK_RACES.md, TASK_BEERUS.md); new modules go in new files.
- team\map\ = map worker; team\animation\ = animation worker.
- Before installing into Studio, pull latest team\ files; never overwrite another agent's file - leave a note in team\HANDOFF instead.
- vault\team is a mirror; edit originals in team\ then run tools\sync-vault.ps1.

## Luau style
- `--!strict` on new modules; typed functions; ModuleScripts return a table.
- PascalCase modules/services, camelCase locals, UPPER_SNAKE constants.
- Server authoritative: never trust client for damage, currency, power level.
- Remotes validated + rate limited. No `wait()` - use `task.wait`/`task.spawn`.
- Tabs, double quotes, 120 cols (tools\stylua.toml). Don't mass-reformat existing files.

## Game rules
- Paid / Robux stat boosts total <= 1.35x. Ranked ignores all boosts (even stats).
- Skill beats stats: frame data and counters matter more than multipliers.
- Race -> form -> modifier stacking order (see TASK_RACES.md).

## Assets
- Only CC0, CC-BY, CC-BY-SA, Free Standard. No NC/ND. No models ripped from games
  (FighterZ, Xenoverse, Sparking Zero, Legends, Budokai...). Credit CC-BY authors in CREDITS.

## Handoff checklist
1. `tools\lint.ps1 <your files>` -> selene clean (no errors) and stylua --check reviewed.
2. Test in Studio Play (no output errors).
3. Write a short note: files changed, how to test.
4. Never publish, buy, or delete without anwar's OK. DEV_MODE off before release.
