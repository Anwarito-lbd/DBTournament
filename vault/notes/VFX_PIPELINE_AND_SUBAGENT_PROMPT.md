# VFX Pipeline & Subagent Master Specification

## 1. Tool Evaluation: Finding the Best VFX Pipeline for Dragon Block Z

To achieve the anime combat spectacle and weighty hit feel of **The Strongest Battlegrounds (TSB)** and **Jujutsu Shenanigans (JJS)**, we evaluated the primary VFX tooling options in the Roblox ecosystem:

| Tool / Technology | Strengths | Weaknesses | Best Use in DBZ |
|---|---|---|---|
| **Eclipse Animator (Moon Animator)** | - Industry standard for complex combat choreography.<br>- Multi-part rig keyframing, Welds, CFrame camera tracks.<br>- Direct placement of frame-accurate event markers (`hit`, `shake`, `vfx`, `freeze`). | - Authoring tool only; does not generate runtime procedural particle physics. | **Cinematics & Markers:** Staging ultimate cutscenes (Zeno Erase, Hakai, Spirit Bomb), multi-character camera moves, and embedding hit markers. |
| **Roblox Native Flipbook Particle System** | - Native GPU particle acceleration.<br>- 8x8 or 4x4 animated flipbook textures (OneShot/Loop).<br>- Curve-driven NumberSequence/ColorSequence. | - Billboard orientation can look flat from extreme camera angles. | **High-Density Combat Effects:** Energy motes, aura wisps, electric sparks, smoke, and directional smears at 60 FPS. |
| **Blender (DCC Mesh Engine)** | - Custom 3D stylized VFX geometry (curved crescent slashes, hollow shockwave toruses, helical drill meshes).<br>- Procedural vertex displacement & custom UV animation. | - Requires import/export asset pipeline. | **Volumetric 3D VFX:** Special Beam Cannon spiral drills, expanding shockwave rings, and aura mesh shells. |
| **Runtime Procedural Anime Engine (`VFXCommon.lua`)** | - **Instantaneous, frame-perfect hitstop**.<br>- Dual-frame inverted impact frames (`C.ImpactFrame("invert", 2)`).<br>- Dynamic spring camera trauma & FOV punch.<br>- Procedural Neon cylinder shockwaves & slate ground fracture geometry.<br>- Dynamic performance LOD scaling. | - Requires strict Luau engineering and memory management. | **In-Game Combat Feedback:** The primary runtime backbone for every strike, beam clash, form transformation, and explosion. |
| **Roblox Studio MCP (`StudioMCP.exe`)** | - Direct headless execution (`execute_luau`).<br>- Instant script injection via `install.py`.<br>- Subagent autonomous exploration and audit. | - Restricted to local machine environment. | **Development Velocity:** Hot-reloading VFX modules and running automated DataModel audits without restarting Studio. |

### The Winning Verdict: The Unified Hybrid Pipeline
The industry standard used by top combat games is a **Hybrid Pipeline**:
1. **Authoring & Staging:** Use **Eclipse Animator** for camera framing, keyframe pacing, and event markers; use **Blender** for custom 3D VFX meshes.
2. **Runtime Execution:** Use the **In-Engine Procedural Engine (`VFXCommon.lua`)** to drive Neon geometry, inverted impact frames, screen shakes, and GPU particles.
3. **Performance Governance:** Use **`VFXLODManager.lua`** to enforce strict budget caps (2,000 particles max, 3-tier aura LOD, 150 debris parts).

---

## 2. Detailed Subagent Prompt Specification

Below is the master prompt created and dispatched to the subagent to audit and execute the VFX package:

```markdown
# MISSION: ROBOTS STUDIO VFX & POLISH SPECIALIST (WP22)

## Role & Objectives:
You are the Senior Roblox VFX & Technical Artist subagent for Dragon Block Z.
Your objective is to inspect, design, and implement high-impact anime visual effects that match The Strongest Battlegrounds (TSB) quality bar while adhering strictly to performance budgets (<2,000 particles at 60 FPS for 40 players).

## Technical Constraints & Standards:
1. Luau Standard: Use `--!strict` or `--!nonstrict` matching existing modules, zero `selene` warnings/errors, formatted with `stylua`.
2. Architecture: All VFX modules reside in `ReplicatedStorage.VFX` and export a clean table API (`Play(character, target, config?)` or `Start(...)`).
3. Shared Utilities: All modules must consume `VFXCommon.lua` for:
   - `C.ImpactFrame("invert" | "white" | "black", frames, subjects)`
   - `C.CameraShake(trauma)` and `C.FOVPunch(degrees)`
   - `C.Shockwave(parent, cframe, startRadius, endRadius, color, duration)`
   - `C.GroundCrack(parent, center, radius, count, color, life)`
   - `C.DebrisBurst(parent, pos, count, power, color, life)`
   - `C.Hitstop(characters, tier)`
4. Server Authority: Visual modules must NEVER apply direct damage or terrain destruction unless running on server. Always pass `{ ArenaDamage = false }` on clients.

## Specific Deliverables:
1. `HakaiVFX.lua`:
   - God of Destruction palm-concentrated void sphere with dark core (`Color3.fromRGB(20, 5, 35)`).
   - Inward suction motes, inverted silhouette impact frame, dual shockwaves, purple ground cracks, and disintegration particles.
2. `KaiokenVFX.lua`:
   - Goku's crimson multiplier surge with double-layer aura (inner white-hot surge + outer crimson flame).
   - Support `Start(char, mult)` and `Play(char, cfg)`. FOV punch, red speed lines, and heart-thump PointLight pulsing.
3. `SolarFlareVFX.lua`:
   - Tien's Taiyoken forehead star flare charging -> massive radial sunburst shockwave.
   - Screen whiteout ScreenGui with smooth quadratic fade for nearby facing clients.
4. `VFXLODManager.lua`:
   - WP22 performance guardian: monitors client FPS, auto-degrades to Quality 1 (Low) if FPS < 30 for 5 seconds.
   - Aura distance culling: Tier 1 Full (<= 80 studs), Tier 2 Simple (80-200 studs), Tier 3 Culled (> 200 studs).
5. Router & Testing:
   - Update `VFXRouter.client.lua` to route all new abilities.
   - Update `KamehamehaTest.client.lua` with test keybinds (`F6` Hakai, `F7` Kaioken, `F8` Solar Flare).
```

---

## 3. Implemented Modules Overview

### 1. `HakaiVFX.lua`
- **Technique:** God of Destruction Void Erasure.
- **Palette:** Void Core (`Color3.fromRGB(20, 5, 35)`), Outer Flame (`Color3.fromRGB(150, 30, 220)`), Aura Aura (`Color3.fromRGB(210, 80, 255)`).
- **Phases:**
  1. *Anticipation:* Hand raised, dark sphere swells with negative speed suction particles.
  2. *Impact Frame:* 2 frames of inverted black/white silhouette strobe (`C.ImpactFrame("invert", 2)`).
  3. *Detonation:* Dual expanding Neon shockwaves + glowing purple slate ground cracks (`C.GroundCrack`).
  4. *Target Dissolution:* 80 upward launch disintegration particles and `Ultimate` tier hitstop (16 frames).

### 2. `KaiokenVFX.lua`
- **Technique:** Goku's Crimson Multiplier Surge.
- **Palette:** Inner Surge (`Color3.fromRGB(255, 230, 210)`), Outer Flame (`Color3.fromRGB(255, 25, 45)`).
- **Phases:**
  1. *Activation:* Explosive burst with red radial speed lines (`C.SpeedLines`) and FOV punch (+6 deg).
  2. *Sustained Aura:* Dual-layer particle emitter attached to root with vertical acceleration (35 studs/s²).
  3. *Dynamic Rumble:* Heartbeat pulse oscillator modifying PointLight brightness in sync with heartbeat audio.
  4. *Scaling:* `:SetMultiplier(n)` seamlessly adjusts emission rates and light range for x3, x4, x10, x20.

### 3. `SolarFlareVFX.lua`
- **Technique:** Tien Shinhan's Taiyoken.
- **Palette:** Core White (`Color3.fromRGB(255, 255, 255)`), Solar Glow (`Color3.fromRGB(255, 250, 220)`).
- **Phases:**
  1. *Charge:* 0.45s rapid flare swell at forehead attachment.
  2. *Burst:* Expanding 45-stud Neon star shockwave and high-frequency camera trauma.
  3. *Client Screen Blind:* LocalPlayer within 75 studs receives a full-screen whiteout ScreenGui that smoothly fades out over 2.2 seconds via Quad Out easing.

### 4. `VFXLODManager.lua` (WP22 Performance Guardian)
- **Auto Quality Detection:** Evaluates rolling FPS every 1.0s. If FPS drops below 30 for 5 consecutive seconds, auto-switches to `Quality 1` (Low), reducing global particle rates to 35% and disabling speed lines.
- **3-Tier Aura Distance Culling:**
  - `Distance <= 80 studs`: **Full Detail** (100% emission rate, PointLight enabled, Perlin flicker active).
  - `80 < Distance <= 200 studs`: **Simple Detail** (40% emission rate, PointLights disabled to eliminate shadow draw calls).
  - `Distance > 200 studs`: **Culled** (Rate = 0, no particle updates, zero overhead).
- **Hard Performance Caps:** Particle budget capped at 2,000 (1,000 on mobile), debris parts capped at 150.

---

## 4. How to Test in Studio

1. Open `Place1.rbxl` in Roblox Studio.
2. Press **Play** (or start Local Simulation).
3. The test suite is bound in `StarterPlayer.StarterPlayerScripts.KamehamehaTest`:
   - **`F6`**: Casts **Hakai** at current mouse hit point (erasure sphere, inverted frame, ground cracks).
   - **`F7`**: Toggles **Kaioken x10** (crimson double-aura, speed lines, pulsing light).
   - **`F8`**: Fires **Solar Flare** (forehead charge, blinding flash, and screen whiteout).
   - **`F1` / `F2` / `F3`**: Toggle Low / Medium / High VFX Quality tiers.
   - **`F4`**: Cycle through all 12 SSJ/God/Divine form auras.
   - **`F5`**: Test anime impact frame strobe + FOV punch.
