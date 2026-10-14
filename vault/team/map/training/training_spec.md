# Training Areas: Spec v1.2 (db-map)
Files: `TrainingAreas.lua` (ModuleScript → `ServerScriptService.TrainingAreas`), `BuildTraining.lua` (the same code plus a runner, for the Studio command bar; regenerate it if the module changes). No external assets: everything is Parts, materials, Neon, ForceField and SurfaceGui text.

## Hierarchy / conventions
`Workspace.WorldOfVoid.Training/<AreaId>` is a sibling of `Arena` and `Lobby`. Arena.Resize never touches it. `Build(areaId)` destroys and rebuilds only that folder, so it's idempotent. `BuildAll()` builds every area in `Order`.
Area folder attributes: `AreaId`, `Origin`, `PartCount`, `PartBudget`, `GravityMultiplier`, `LightingPreset`, plus area-specific ones (below). Names use the `Prefix_Thing_N` pattern from layout_spec. Tags are PascalCase.

| Tag | On | Attributes |
|---|---|---|
| TrainingSpawn | `Spawn_<AreaId>` (SpawnLocation, disabled, for teleport targets) | AreaId |
| TrainingPortal | `Portal_<Dest>/Pad` (touch pad) | Destination = AreaId or "TrainingHub" |
| TrainingZone | `Zone_<AreaId>` (invisible volume, no collision) | AreaId, GravityMultiplier, … |
| TrainingFallZone | `Zone_<AreaId>_Fall` (below area) | AreaId → respawn at that area's spawn |
| TrainingDummy | hub punching bags | MaxHealth 500 |
| GravityConsole | gravity room console | GravityMultiplier (live), GravityMin, GravityMax |
| TrainingBotSpawn | gravity room bot pads | AreaId |
| TrainingNPCSpot | NPC stand markers | NPC = KingKai/Bubbles/Whis/Beerus |
| ShopCounter / ShopNPCSpot / ShopItemSlot | shop | ShopId="CapsuleCorp" / NPC="Bulma" / Slot 1..6 |

The lobby itself is unchanged (Arena.BuildLobby). Building TrainingHub or Shop makes `Lobby_Wall_13` (west, behind the Training pad) and `Lobby_Wall_7` (+Z, behind the Shop pad) non-collidable and invisible, with attribute `OpenedFor`. If `BuildLobby(true)` runs again, rebuild those two areas. Build order: BuildArena (lobby) first, then BuildTraining.

## Layout (all centres; areas are ≥2,700 studs apart, beyond fog/stream range)
| AreaId | Centre | Access | Gravity | Other attrs | Parts (measured / budget) |
|---|---|---|---|---|---|
| TrainingHub | (2700,100,0), Ø160 disc | 104×20 bridge from lobby west wall (x 2882→2778) | 1 | portals to 4 areas, 6 dummies | 40 / 90 |
| Shop | (3000,100,270), 140×110 plaza | 20-wide walkway from lobby +Z wall (z 116→220) | 1 | Capsule Corp drum+dome HQ, CC logo, counter, 6 capsule slots | 34 / 80 |
| HyperbolicTimeChamber | (6000,100,0) | portal | 10 | TimeDilation 365, XPMultiplier 4, MaxStaySeconds 600; zone: TemperatureMin −40, TemperatureMax 50, AirDensity 0.25 | 31 / 70 |
| GravityRoom | (6000,100,3000), Ø90 room | portal | 1 (console-driven) | GravityMin 1, GravityMax 500, GravitySteps "1,10,50,100,150,300,500"; zone GravityDynamic=true | 52 / 90 |
| KingKaiPlanet | (9000,300,0), sphere r=60 | portal | 10 | XPMultiplier 2; house, red car (tag KingKaiCar), tree, road loop, Snake Way clouds | 48 / 70 |
| WhisGround | (9000,100,3000), Ø420 | portal | 1.5 | XPMultiplier 3; Beerus stepped temple + spire, 8 mushroom rocks, floating rocks, Whis sparring circle | 47 / 90 |
Total is about 250 parts for all six areas, well inside mobile limits. Lots of decor uses CanCollide/CanTouch/CanQuery=false. Budgets leave room for an art pass. The builder warns when an area goes over budget.

Every far area has a `Portal_Return` (Destination "TrainingHub"). The hub has `Portal_<AreaId>` for each far area. Shop and Hub are reached on foot from the lobby.

## Gameplay hooks (owned by db-gameplay)
- Teleport: on Pad touch (server), debounce, then move the HumanoidRootPart to `Training/<Destination>/Spawn_<Destination>` + (0,3,0). Use `Spawn_Lobby_01` if Destination is "Lobby".
- Gravity: apply `GravityMultiplier` from the TrainingZone the player is inside, e.g. a VectorForce of −(m·g·(mult−1)), or a stamina/speed debuff. In the gravity room, read `GravityConsole.GravityMultiplier` and write it back to the zone/console when the console is used (via a server-validated RemoteEvent), and update the `GR_Readout` text.
- HTC: XP/time progress × TimeDilation (or XPMultiplier), with MaxStaySeconds per visit.
- Lighting: Lighting is global, so the client applies `TrainingAreas.LightingPresets[folder.LightingPreset]` when it enters a zone and restores "Lobby" when it leaves.
- Fall zones: respawn at that area's TrainingSpawn.

## Look notes
- HTC: white endless floor, cream tiled platform, a long white house with three domes, hourglass, pillars and steps down into the void, and a white high-fog preset.
- Gravity Room: Capsule Corp ship interior. 16 white wall panels with blue portholes, a dome, a central column with a red neon ring, a console with a red "1G" readout, weights and legs.
- King Kai: tiny grass sphere with a cream round house, red dome roof and chimney, a curved dirt road, the red car with a white top, a tree, and yellow Snake Way clouds.
- Beerus planet: teal grass, purple-capped mushroom rock spires, a sandstone stepped temple with a tall spire and cyan orb, floating rocks, and Whis's sparring circle and staff.
- Shop: white Capsule Corp drum and half-dome with a blue band and roof disk, "CAPSULE CORP." banner, blue CC logo, glass storefront, and red/white capsules on pedestals.

## v1.2.1 additions
### Lighting presets → `ReplicatedStorage.Shared.TrainingLightingPresets`
- A ModuleScript that returns `{ [presetName]: { [LightingProperty]: value } }` directly, with no wrapper key. That's the shape `gameplay/.../TrainingLighting.client.lua` expects: it does `m.LightingPresets or m`, then `PRESETS[name]`. Preset names: Lobby, HTC, GravityRoom, KingKai, BeerusPlanet. Keys: ClockTime, Ambient, OutdoorAmbient, FogColor, FogStart, FogEnd, Brightness.
- Standalone file: `training/TrainingLightingPresets.lua`, generated from `TrainingAreas.PresetsSource()`. Sync it with Rojo, or paste it.
- `TrainingAreas.PublishLightingPresets()` is called by `BuildAll()`. It creates the `Shared` folder if it's missing and creates or updates the module. Setting `.Source` only works in Studio (command bar or plugin). In a live server it leaves an existing module alone and warns if there is none, so ship the file as part of the place.

### ArenaDamage isolation
`ArenaDamage.Init` only registers parts tagged `RingChunk` that are descendants of `Workspace.WorldOfVoid.Arena` (and of the optional `root`). `DamageAt` returns 0 for hits more than `Radius + radius + 60` from the ring axis or more than 400 from Y=500. Training areas (at least 2,700 studs away, under `WorldOfVoid.Training`) can never be hit.

### Sparring bot placeholder
- `TrainingBotSpawn` pads: `GR_BotSpawn_1..4` (AreaId GravityRoom) and `Whis_BotSpawn_1..2` (AreaId WhisGround).
- `TrainingAreas.CreatePlaceholderBot(pad, parent?) -> Model` makes a default R15 rig with `Players:CreateHumanoidModelFromDescription(HumanoidDescription, R15)` (server only, red/white colours). If that call isn't available (for example in edit mode), it falls back to a welded block rig with HumanoidRootPart, UpperTorso, Head and a Humanoid.
  - Output: Model `SparringBot` with PrimaryPart HumanoidRootPart, tag `TrainingBot`, attributes `TrainingBot=true`, `AreaId` and `RigType` ("R15" or "Block"). It's pivoted 4 studs above the pad, parented to the pad's folder, and network owner is set to the server.
- `TrainingAreas.SpawnPlaceholderBots(areaId?) -> {Model}` spawns one bot per pad, for testing.
- db-gameplay `TrainingBots.build()` can call `CreatePlaceholderBot(pad)` and then set its own Humanoid stats. TrainingBots currently only spawns at pads with `AreaId == "GravityRoom"`; Whis pads need that filter extended.

## v1.3 Dragon Ball anchors and Raid arenas
### DragonBallSpawn anchors (`Training/DragonBallSpawns`, `Build("DragonBallSpawns")`)
- 12 invisible 2×2×2 parts: CanCollide, CanTouch and CanQuery are all false, and they're anchored. Tag `DragonBallSpawn` (= `Config.DRAGON_BALLS.anchorTag`). Attributes `AreaId` and `Index` 1–12. Named `DBSpawn_01..12`.
- DragonBallService reads `BasePart.Position` and needs at least 7 anchors; it sorts them by x, then z.
- Spread: Lobby ×2, TrainingHub ×2, Shop, HTC, GravityRoom, KingKaiPlanet ×2, WhisGround ×3 (one is on the temple).

### Raids (`Workspace.WorldOfVoid.Raid/<RaidId>`)
Two separate sub-areas, each with its own `RaidArena` floor, so BossNPC.allocArena can hand them out independently.
| RaidId | Centre | Boss | Look | Parts / budget |
|---|---|---|---|---|
| BrolyCrater | (0,100,−12000) | Broly | Wasteland crater: 240×240 floor, basalt bowl, glowing lava fissures, 20 rim slabs (collidable wall), spires, boulders (`RaidCover`), green aura marker | 62 / 120 |
| MoroNamek | (1600,100,−12000) | Moro | Ruined New Namek: plateau in a drained sea, 6 broken dome houses, withered ajisa trees, purple drain cracks, mesas, cover rubble | 66 / 120 |
Both sit 12,000 studs from the arena and far from BossNPC's fallback slots (z=+12000).

Each raid area has:
- `Raid_Floor`: tag `RaidArena`, attributes `RaidId`, `Boss`. 240×4×240 with its top at the centre Y. BossNPC spawns at floor.CFrame + (0, 5, 0) and sets `InUse`.
- `Raid_BossPad`: tag `RaidBossPad`, attributes `Boss` ("Broly"/"Moro", matching `Config.RAIDS` keys) and `RaidId`. At centre + (0,0,−70).
- `Raid_Spawn_01..08`: tag `RaidSpawn`, attributes `RaidId`, `Index`. In a row at centre + (−42..42, 0, +80).
- `Zone_<RaidId>`: tag `TrainingZone`, attributes `AreaId`, `RaidId`.
- `Zone_<RaidId>_Fall`: tag `RaidFallZone`, at centre − 60.
- `Zone_<RaidId>_Ceiling`: tag `RaidCeiling`, collidable, at centre + 200.
- Folder attributes `RaidId`, `LightingPreset` (= RaidId) and `GravityMultiplier` 1.

Lighting presets `BrolyCrater` (dusk orange) and `MoroNamek` (pale teal) are in `TrainingLightingPresets.lua` (regenerated).

**ArenaDamage isolation:** raid parts are never tagged `RingChunk` and are outside `WorldOfVoid.Arena`. `DamageAt` positions near the raids (12,000 studs away) return 0, so any `arenaRadius`/`arenaPower` calls from boss specials do nothing there.

**db-gameplay notes:**
- `allocArena` takes the first free `RaidArena`. To keep each boss in its matching arena, filter on `a:GetAttribute("Boss") == raidId`.
- Teleport players to `RaidSpawn` pads (same `RaidId`) and spawn the boss on the `RaidBossPad`.
- Set the player `LightingPreset` attribute to the RaidId so TrainingLighting.client applies the preset.
