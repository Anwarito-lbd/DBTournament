# World of Void — Layout Spec v1 (greybox)
Owner: db-map. Build script: `BuildArena.lua` (same folder). Units: studs. +Y up. Roblox default: 1 stud ≈ 0.28 m.

## Coordinate layout
| Area | Origin / center | Notes |
|---|---|---|
| Arena ring center | (0, 500, 0) — top surface at Y=500 | Floats in void |
| Universe stands | ring of radius 420 around (0,540,0) | 12 blocks, 30° apart; U01 at +X, counter-clockwise toward +Z |
| Zeno's viewing box | (0, 700, -520) | Faces ring center, above/behind stands |
| Lobby hub | (3000, 100, 0) | Far enough to be out of arena view (fog end 4000 — keep lobby in separate place for prod if desired) |

## Arena
- **Ring_Floor**: vertical cylinder, Ø300, 20 thick (Y 480–500), Slate.
- **Ring_Lip**: neon edge, Ø306, 2 thick, flush with top — visual only, does not block knockback.
- **Ring_Under_1..4**: stacked shrinking discs (Ø245/190/135/80, 15 thick) = floating rock underside.
- **Ring_Pillar_1..8**: 8×30×8, at r=130, angles 22.5°+45°n. Tag `ArenaCover` (destructible later).
- **Fighter spawns** `Spawn_Ring_U01..U12`: r=110, angle (u-1)·30°, Y=500.5. Attribute `Universe="Uxx"`. Disabled SpawnLocations; match code teleports.

## Universe stands (12 universes)
- Folder `Stand_Uxx` (attribute `Universe`=1..12), center at r=420, Y=540, facing ring.
- Base 80×4×40; 3 seating tiers 80 wide × 8 deep, heights 4/8/12, stepping back away from ring.
- Banner 40×20 neon in team hue (HSV hue=(u-1)/12), non-collide.
- `Spawn_Stand_Uxx` on the front of the base (eliminated players / spectators).
- Gap ring edge→stand front ≈ 250 studs: not jumpable, so stands are safe spectator space.

## Zeno's viewing box
- Floor 60×4×40, back wall 60×30, roof 64×44, front glass (Transparency 0.7), 2 thrones 6×8×6.
- `Spawn_Zeno` (tag `ZenoSpawn`) for admin/host cam.

## Collision / ring-out
| Part | Spec | Tag | Rule |
|---|---|---|---|
| Zone_RingOut_Floor | 4000×10×4000 at Y=420, invisible, CanCollide=false | `RingOutZone` | Touch ⇒ eliminated |
| Zone_RingBounds | cylinder r=175, Y 490–790, invisible | `RingBounds` | Attributes `Radius=175`, `MinY=420`. Server check: horizontal dist from (0,·,0) > 175 **and** not grounded ⇒ ring-out (gives 25-stud air grace past edge). Recommended to poll positions rather than rely on Touched. |
| Zone_Ceiling | 2000×4×2000 at Y=900, invisible, collidable | `ArenaCeiling` | Caps flight |
| Zone_LobbyFall | at lobby Y=20 | `LobbyFallZone` | Respawn to lobby |

Flight note: if fighters can fly (DBZ), ring-out should be "touch any surface outside ring" or "below Y=480 for >1 s" — gameplay decision for lead.

## Lobby hub (origin L=(3000,100,0))
- Lobby_Floor Ø240 marble; Lobby_Centerpiece Ø40 neon.
- Pads 30×30 (tag `LobbyPad`, attribute `PadType`): Queue_Solo L+(0,0,-80), Queue_Team L+(80,0,0), Shop L+(0,0,80), Training L+(-80,0,0).
- 24 semi-transparent wall segments 32×20 at r=118.
- `Spawn_Lobby_01..08` (enabled, tag `LobbySpawn`) at r=40.

## Lighting
ClockTime 0, Brightness 2, Ambient (70,60,110), OutdoorAmbient (90,80,140), Fog (20,18,40) 800–4000, GlobalShadows on.
Sky `WOV_Sky`: StarCount 3000, no sun/moon (swap skybox asset ids for a real void sky). Atmosphere density .35, color (110,90,180), decay (30,20,60), haze 1.5. ColorCorrection tint (225,215,255) +0.1 contrast/sat. Bloom 0.8/30/1.5. All tagged with attribute `WorldOfVoid=true` so rebuilds replace them.

## Naming conventions
- Root: `Workspace.WorldOfVoid` → `Arena/{Ring,Spawns,Stands,ZenoBox,Zones}`, `Lobby`.
- Parts: `Area_Thing[_N]` PascalCase (`Ring_Pillar_3`, `Zeno_Glass`). Universes zero-padded `U01..U12`.
- Spawns `Spawn_<Area>[_Uxx|_NN]`. Zones `Zone_<Purpose>`.
- CollectionService tags (PascalCase): ArenaFloor, ArenaCover, ArenaSpawn, StandSpawn, ZenoSpawn, UniverseStand, ZenoBox, RingOutZone, RingBounds, ArenaCeiling, LobbyFloor, LobbyPad, LobbySpawn, LobbyFallZone.
- All parts Anchored, SmoothPlastic unless noted.

---
# v1.1 — Destructible ring + ring-out rules (lead decisions 2026-10-13)

## Ring-out (final)
Flight allowed. A fighter is rung out if EITHER:
1. They touch any surface that is not an attached ring chunk (`ArenaDamage.IsRingSurface(part) == false`) — stands, Zeno box, pillars-off-ring, the Y=420 kill floor, a falling chunk. Debris and FX have `CanTouch=false` and never count.
2. Their root part Y < 480 (`Zone_RingBounds.LowY`) continuously for > 1 s (`LowGrace`).
Server polls HumanoidRootPart each Heartbeat (or 10 Hz); `Humanoid.FloorMaterial`/raycast-down for rule 1 when grounded. The ring underside rock is non-collidable, so holes are real holes. Lobby stays in the same place.

## Chunk grid (replaces the single Ring_Floor)
Polar grid, 5 radial bands × sectors = **90 chunks**, folder `Arena/Ring/Chunks`, each a box approximating its annular sector, Y 480–500 (20 thick).
| Band | r (studs) | Sectors | Approx chunk (arc × depth) | MaxHealth |
|---|---|---|---|---|
| B1 | 0–30 | 6 | 32 × 30 | 80 |
| B2 | 30–60 | 12 | 24.6 × 30 | 100 |
| B3 | 60–90 | 18 | 27.2 × 30 | 120 |
| B4 | 90–120 | 24 | 28.5 × 30 | 140 |
| B5 | 120–150 | 30 | 29.3 × 30 | 160 |
Name `Chunk_B<band>_S<sector 2-digit>` (sector 1 starts at +X, CCW). Tags `RingChunk`, `ArenaFloor`. Attributes: `Band`, `Sector`, `MaxHealth`, `Health`, `HalfSpan`, `Detached`. Small overlaps (+1 stud arc, +0.5 depth) close seams; it's greybox — swap for MeshPart sectors later with same names/tags.
The Ring_Lip was removed (it would visually cover holes). Pillars are not yet destructible (they stay floating if their chunk falls — v2 item).

## ArenaDamage API (`ArenaDamage.lua` → ModuleScript `ServerScriptService.ArenaDamage`)
Server-only (asserts `RunService:IsServer()`); clients never call it — beams send intent via RemoteEvent, server validates and calls.
- `Init(root?)` — scans `RingChunk` tags, records home CFrame/colour/material. Auto-called on first use; BuildArena calls it if the module is installed.
- `DamageAt(pos, radius, power) -> number` — chunks within `radius + HalfSpan` take `power × (1 − 0.7·dist/reach)`. Returns chunks hit (0 if throttled). Radius clamped to 1–60.
  - health ≤ 75%: a neon crack strip on top
  - health ≤ 40%: crater, sinks up to 5 studs + tilt, darkens, Basalt
  - health ≤ 0: detach (unanchor, pushed outward, falls 4 s, then hidden), debris burst, its cracks removed
- `Reset()` — restores every chunk to its home state, clears cracks, returns all debris to the pool, invalidates pending timers (round counter). Call between rounds.
- `IsRingSurface(part) -> boolean` — for ring-out rule 1.
- `GetStats()` — chunks/alive/cracks/debris/falling/tokens.
- `Config` table is tunable at runtime.
Example: `ArenaDamage.DamageAt(hitPos, 18, 120)` for a full Kamehameha, `(hitPos, 6, 25)` for a ki blast.

## Performance budget (hard caps, in `Config`)
| Item | Cap |
|---|---|
| DamageAt calls | 30/s token bucket, excess dropped |
| Chunks affected per call | 16 (nearest first) |
| Ring chunks (static) | 90 |
| Crack parts | 150 |
| Debris parts | 60 pooled (oldest recycled), 4 per hit, 3 s life, CanTouch/CanQuery off |
| Simultaneously falling chunks | 20 (over cap → vanish instantly) |
Worst case ≈ 90 + 150 + 60 = 300 extra parts; physics bodies ≤ 80. Damage is O(90) per call.

---
# v2 — Scalable arena (supersedes fixed dimensions above where they conflict)

## Ownership / contract
- **`ServerScriptService.Arena`** (ModuleScript, source `Arena.lua`) owns `Resize(teamCount, playerCount)`. ArenaDamage does NOT resize.
- RoundManager flow per round: `Arena.Resize(T, P)` → `ArenaDamage.Init()` → reread spawns/bounds from Workspace. Arena never calls ArenaDamage. `ArenaDamage.Init()` is safe to call repeatedly (bumps round counter, destroys old cracks/debris/pool, rescans `RingChunk`). `Reset()` still restores within the same layout.
- `BuildArena.lua` = same code as Arena.lua + a runner (default 8 teams × 40 players) for Studio edit mode. Regenerate it if Arena.lua changes.
- Other API: `Arena.ComputeLayout(T,P)` (pure math), `Arena.GetInfo()`, `Arena.BuildLobby(force?)`, `Arena.Config`.

## Scaling formulas (Arena.Config)
- Inputs clamped: T 2–12 (game uses 2–8), P T–40.
- Ring radius `R = min(400, 150 + 12·P)` → reaches cap at 21 players.
- Chunk bands `B = clamp(round(R / (30 + 0.08·(R−150))), 5, 8)`, band depth `R/B`; band 1 = 6 slices, band b ≈ `2π·r_mid / depth` slices. Chunk HP = 60 + 20·band + (depth−30). Cap 220 chunks (auto-drops a band if over).
- Stands: T stands at radius `R + 250 + 20`, centred on each team's spawn arc ((t−0.5)/T·360°), width clamp(0.6·arc, 80, 160), Y=540.
- Zeno box: (0, 700 + 0.25R, −(standR + 120)), faces ring.
- Pillars: 8 + 2·floor((R−150)/50) at r = R−20.
- Bounds radius R+25; ceiling Y = 500 + max(400, 1.5R); kill floor Y=420 sized standR·2+2000; Fog 800·R/150 → 4000·R/150.
- Lobby fixed at (3000,100,0), built once (not touched by Resize).

| P | R | Bands | Chunk depth | Chunks | Stand radius |
|---|---|---|---|---|---|
| 2 | 174 | 5 | 35 | 81 | 444 |
| 4 | 198 | 6 | 33 | 116 | 468 |
| 8–10 | 246–270 | 7 | 35–39 | 157 | 516–540 |
| 16 | 342 | 8 | 43 | 204 | 612 |
| ≥21 (incl. 40) | 400 | 8 | 50 | 204 | 670 |

## Instances RoundManager rereads after Resize
- `Workspace.WorldOfVoid.Arena` attributes: `TeamCount, PlayerCount, Radius, Bands, ChunkCount, StandRadius, ZenoPos, CeilingY, BoundsRadius`.
- Fighter spawns `Arena/Spawns/Spawn_Ring_01..P` (tag `ArenaSpawn`, disabled), attrs `Team` (1..T, contiguous arcs), `Universe` ("U01"..), `Slot`. Placed at r=0.65R, Y=500.5. **Renamed from v1 `Spawn_Ring_Uxx`.**
- Stand spawns `Arena/Stands/Stand_Uxx/Spawn_Stand_Uxx` (tag `StandSpawn`), attrs `Team`, `Universe`. Stand folders carry `Team`, `Universe`.
- `Arena/ZenoBox/Spawn_Zeno` (tag `ZenoSpawn`).
- `Arena/Zones/Zone_RingBounds` (tag `RingBounds`) attrs: `Radius` (R+25), `RingRadius` (R), `MinY` 420, `LowY` 480, `LowGrace` 1, `CeilingY`, `Center` (0,500,0).
- `Zone_RingOut_Floor` (tag `RingOutZone`), `Zone_Ceiling` (tag `ArenaCeiling`).

## Budget at max size (R=400, 8–12 teams)
Chunks 204 + pillars 18 + stands 12×6 + Zeno ~8 + zones 3 + spawns ≤53 ≈ 360 static parts. ArenaDamage caps unchanged except radius: 30 calls/s, 16 chunks/call, MAX_RADIUS 80 (bigger chunks), 150 cracks, 60 debris, 20 falling. Worst case ≈ 570 parts total, ≤80 physics bodies; DamageAt is O(chunks) ≤ 204 distance checks.

## Known follow-up
`ArtPass.lua` (decor pass) assumes the v1 fixed 150-radius / 5×30-band layout and 12 stands; it needs to read `Arena` attributes to scale. Its lighting is overwritten only by `BuildLobby(true)`, not by Resize.

---
# v3: Show-accurate Tournament of Power upgrade (2026-10-13)
All v2 names, tags and attributes are unchanged: Spawn_Ring_NN, Spawn_Stand_Uxx, Spawn_Zeno, Zone_RingBounds and its attributes, the RingChunk attributes, and the Arena folder attributes. Everything below is additive.

## API addition
`Arena.Resize(teamCount, playerCount, universes?)`: the optional `universes` list maps team index → displayed universe number (for example `{7, 11, 2}`). Without it, team t is labelled "UNIVERSE t". Gameplay's existing 2-argument call still works. `Arena.UniverseColors[1..12]` is the palette.

## Universe stands (`Arena/Stands/Stand_Uxx`)
- Folder attributes: `Team`, `Universe` (= team index, unchanged), plus new `UniverseNumber` and `UniverseColor`.
- Parts: `Base` (marble, tag UniverseStand), `Underside` (floating rock), `FrontTrim` (neon in the universe colour), `Tier_1..4` (stepped rows alternating universe colour and white), `BackWall`, `Banner` (neon in the universe colour with SurfaceGui `UniverseLabel` "UNIVERSE\nN" on both faces, attribute UniverseNumber), `BannerPole_L/R`, `Spawn_Stand_Uxx`.
- NPC spots (tag `ArenaNPCSpot`, invisible, non-colliding): `NPC_God`, `NPC_Angel`, `NPC_Kaioshin`, with attributes `NPC`, `UniverseNumber`, `Team`.
- **Bulma:** `NPC_BulmaCheer` in the stand whose UniverseNumber == 7 (front corner). Tags `ArenaNPCSpot` + `BulmaCheerSpot`, attributes NPC="Bulma", UniverseNumber=7, Team. It only exists if universe 7 is present: with default numbering that means ≥7 teams, otherwise pass `universes`.

## Zeno's box (`Arena/ZenoBox`)
- Existing parts kept: `Zeno_Floor` (tag ZenoBox), `Zeno_BackWall`, `Zeno_Roof`, `Zeno_Glass`, `Zeno_Throne_1/2`, `Spawn_Zeno`.
- New parts: `Zeno_Platform` and gold `Zeno_PlatformTrim`, a purple `Zeno_Carpet`, `Zeno_ThroneBack_1/2` (gold), and `Zeno_ThroneArm_i_j`. Throne 1 (left, x=−6) is Zeno and throne 2 (x=+6) is Future Zeno. The thrones moved to z=4.5 so the seated spots line up.
- NPC spots (tag `ArenaNPCSpot`, attributes `NPC` and `CutsceneId`). Offsets are measured from Spawn_Zeno facing the ring (x to the right, −z toward the ring) and match `CutsceneDirector.SPOTS` exactly:

| Part | NPC | CutsceneId | Offset (x, z) |
|---|---|---|---|
| NPC_Zeno | Zeno | npc_zeno | (−6, 2) |
| NPC_FutureZeno | FutureZeno | npc_zeno_future | (6, 2) |
| NPC_ZenoGuard_1/2 | ZenoGuard | npc_zeno_guard_1/2 | (∓15, 9) |
| NPC_GrandPriest | GrandPriest | npc_grand_priest | (−20, −6) |

## Ring-out void (`Arena/Void`, visual only)
- `Void_Plane` (tag `VoidPlane`): a dark neon plane at Y=300, (standR·2+1500) square.
- `Void_Swirl_1..3`: transparent purple rings.
- `Void_Haze`: a ForceField sheet at Y=405, just under the kill floor.

None of these collide, touch, query or cast shadows. The kill zone is still `Zone_RingOut_Floor` at Y=420. Fog still scales with R. Ring-out rules are unchanged (touch a non-ring surface, or Y<480 for >1 s).

## Staged chunk destruction (ArenaDamage)
Each `RingChunk` carries `DamageStage` (0–3) and `DamageStageName`. They are set at build and Init, and reset by `Reset()`. `ArenaDamage.Stages` holds the names.

| Stage | Name | Trigger (Health/MaxHealth) | Visual |
|---|---|---|---|
| 0 | Intact | > 0.75 | as built |
| 1 | Cracked | ≤ 0.75 | 1 neon crack strip |
| 2 | Cratered | ≤ 0.40 | 2nd crack; sinks up to CRATER_MAX_DEPTH (8) with tilt, darkens to Basalt |
| 3 | Detached | ≤ 0 | unanchored, pushed outward, falls 4 s then hidden; `Detached`=true; cracks removed; debris burst |

Other attributes stay the same: `Health`, `MaxHealth`, `Detached`, `Band`, `Sector`, `HalfSpan`. Current Config (another agent raised these in v1.2): DEBRIS_PER_HIT 8, MAX_DEBRIS 90, DEBRIS_LIFETIME 5, CRATER_MAX_DEPTH 8.

## ArtPass (`ServerScriptService.ArtPass`, Apply() after every resize)
- Reads `Radius`/`Bands` and stand `UniverseNumber`/`UniverseColor`.
- Skips its own banner text when Arena already added `UniverseLabel`.
- Dropped its duplicate ThroneBack parts.
- Grout circles are capped at 36 per band (was 72), for the mobile budget.

## Part budget (measured with a mock Resize + ArtPass.Apply + 400 max-power DamageAt calls)
| Teams × players | R | Chunks | Arena static | ArtPass decor | Dynamic peak (cracks+debris) | NPC spots |
|---|---|---|---|---|---|---|
| 2 × 2 | 174 | 81 | 154 | 210 | 90 debris | 11 |
| 8 × 8 | 246 | 157 | 329 | 303 | 96 | 30 |
| 8 × 40 | 400 | 204 | 416 | 397 | 110 | 30 |
| 12 × 40 | 400 | 204 | 476 | 401 | 110 | 42 |

**Hard caps:**
- Worst-case dynamic is 150 cracks + 90 debris = 240 parts.
- Falling chunks (≤20) are counted in the static figure.
- Worst case at 8 × 40 is about 416 + 397 + 240 ≈ **1,050 parts**, of which only about 420 collide; at 12 × 40 it's about 1,120.
- Decor and FX have no collision and no shadows. Physics bodies are ≤ 20 chunks + 90 debris.
- Reset() restored 100% of chunks and 0 cracks in every run.
