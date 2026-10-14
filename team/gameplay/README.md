# Gameplay — install into Roblox Studio

Files (in `src/`, with Rojo-style naming):
| File | Studio location | Type |
|---|---|---|
| `ReplicatedStorage/Shared/Config.lua` | ReplicatedStorage › Folder `Shared` › `Config` | ModuleScript |
| `ServerScriptService/Modules/TeamAssignment.lua` | ServerScriptService › Folder `Modules` › `TeamAssignment` | ModuleScript |
| `ServerScriptService/Modules/PlayerData.lua` | ServerScriptService › `Modules` › `PlayerData` | ModuleScript |
| `ServerScriptService/Modules/Net.lua`, `RateLimit.lua`, `Party.lua`, `Combatant.lua`, `Arena.lua`, `Combat.lua`, `Fusion.lua` | ServerScriptService › `Modules` | ModuleScripts |
| `ReplicatedStorage/Shared/ClientAPI.lua` | ReplicatedStorage › `Shared` › `ClientAPI` | ModuleScript |
| `StarterPlayer/StarterPlayerScripts/KiChargeInput.client.lua`, `CombatInput.client.lua`, `SpectateCamera.client.lua`, `VFXRouter.client.lua` | StarterPlayer › StarterPlayerScripts | LocalScripts |
| `ServerScriptService/RoundManager.server.lua` | ServerScriptService › `RoundManager` | Script |

## Manual install
1. Create the folders and instances listed above, then paste in each file's contents.
2. Game Settings › Security: enable **Studio Access to API Services** so DataStores work in Studio.
3. **Map (db-map):** put `map/ArenaDamage.lua` in a ModuleScript at `ServerScriptService.ArenaDamage`, then run `map/BuildArena.lua` once in the command bar. This creates the tagged `ArenaSpawn`/`StandSpawn`/`LobbySpawn` pads and the `RingBounds` part. **VFX (db-animation):** put its modules in the folder `ReplicatedStorage.VFX`. Fallback with no map: in Workspace, add the Folder `ArenaSpawns` (Parts), the Folder `LobbySpawns` (Parts). With no map installed, ring-out falls back to Y < -50.
4. Create your Game Passes and Developer Products in the Creator Dashboard and put their IDs into `Config.GAMEPASSES` / `Config.PRODUCTS`. An ID of 0 means disabled.
5. Test › Clients and Servers › 2+ players › Start. Watch `workspace` attributes `RoundState`/`TimeLeft`.

## Rojo
Map `src/StarterPlayer` → StarterPlayer, `src/ReplicatedStorage` → ReplicatedStorage and `src/ServerScriptService` → ServerScriptService. `.server.lua` becomes a Script, and plain `.lua` becomes a ModuleScript.

## Notes
- **Max Players = 40:** set it in Studio under Game Settings > Places > Max Players. A script can't set it. It must match `Config.MAX_PLAYERS` (8 teams × 5).
- **Arena resize:** if db-map ships `Resize(teamCount, playerCount)` (as `ServerScriptService.Arena` or `ArenaDamage.Resize`), RoundManager calls it automatically. If it's missing, nothing happens.
- Event mode: set `workspace:SetAttribute("EventMode", true)` (or `Config.EVENT_MODE`) to enable Grand Priest and Zeno and lift the divine cap.
- To test fusion, put two clients on the same team, pick Goku and Vegeta (one per team still allows this pair), then call `ClientAPI.requestFusion("Dance", otherUserId)` on both clients.
- Only **one** script may set `MarketplaceService.ProcessReceipt`. That script is PlayerData.
- Test parties with Test › Clients and Servers (3+ players): call `ClientAPI.invite`/`acceptInvite` from each client's command bar.
- Syntax was checked with `luau-compile` (all files compile). The code has not been run inside Studio yet.
