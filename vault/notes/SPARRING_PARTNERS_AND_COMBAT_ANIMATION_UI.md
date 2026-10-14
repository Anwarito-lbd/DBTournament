# Sparring Partners (Goku & Vegeta) and Combat Animation UI

## 1. Character Aesthetic Verdict: Unified Anime R15 Cel-Shaded Standard
- **The Choice**: Classic R15 anime cel-shaded stylization (the proven standard of *The Strongest Battlegrounds*, *Jujutsu Shenanigans*, and *Blox Fruits*) vs. heterogeneous external 3D meshes.
- **Verdict**: R15 Anime Blocky Standard is universally superior:
  - **100% Visual Cohesion**: All 103 fighters share the identical artistic proportions, anime clothing templates, and custom stylized 3D hair.
  - **Rock-Solid Performance**: 60 FPS locked in 40-player World of Void matches; zero skinned mesh draw-call degradation.
  - **Joint Animation Compatibility**: Full alignment with Eclipse Animator, Moon Animator, and standard 15-joint R15 motor rigs without bone-weight tearing or ragdoll glitches.
  - **Instant In-Match Transformations**: 1-frame dynamic hair color/mesh swapping (Black -> Golden -> Cyan -> Silver) with zero load hitch.

## 2. Zero Duplicate Roster Architecture
- Exactly **1 card per fighter** (1 Son Goku, 1 Prince Vegeta, 1 Frieza, 1 Gohan, 1 Broly, etc.).
- There are NO duplicate character slots (no "Kid Goku", no "SSJ Goku").
- Every transformation ladder (Base -> Kaio-Ken -> SSJ -> SSJ2 -> SSJ3 -> SSG -> SSB -> SSJ4 -> UI Sign -> MUI) is an active in-match ascension triggered through combat and Ki charge.

## 3. Adaptive Goku & Vegeta Sparring System (`TrainingBots.lua`)
- **Sparring Partners**:
  - **Son Goku** (`u7_goku`): Iconic orange Turtle Gi (`SaiyanGi`), spiky black hair, Kamehameha, Kaioken, and Ultra Instinct.
  - **Prince Vegeta** (`u7_vegeta`): Saiyan combat armor (`SaiyanArmor`), upright flame hair, Galick Gun, Big Bang, Final Flash, and Ultra Ego.
- **Adaptive Escalation ("The more you spar, the better they become")**:
  - **Tier 1 (Base Form - Warmup)**: Standard speed, 3-hit M1 strings, basic block.
  - **Tier 2 (Super Saiyan - Ascended Rival)**: Triggers at 50% HP or KO 1. Golden hair & aura, speed +25%, 4-hit launcher combo, Flash Step sidestep dashes.
  - **Tier 3 (Super Saiyan Blue - Divine Ki)**: Radiant cyan hair & God Ki aura, counter-parry, post-knockback beam combos (Kamehameha / Galick Gun), 0.15s reaction time.
  - **Tier 4 (Mastered Ultra Instinct & Ultra Ego - Multiverse Gods)**:
    - **Goku MUI**: Pure silver hair and divine aura. 50% chance to autonomously phase/vanish through attacks without blocking.
    - **Vegeta Ultra Ego**: Deep magenta destruction hair and purple flames. Pain-to-Power scaling (+8% damage per hit taken).

## 4. Combat Animation & Skill Hotbar UI (`CombatActionUI.client.lua`)
- **4-Slot Skill Hotbar (TSB Style)**:
  - `[1] KI BLAST BARRAGE` (Ki: 5 | CD: 1.5s)
  - `[2] BEAM CANNON` (Kamehameha / Galick Gun | Ki: 30 | CD: 6.0s)
  - `[G] HEAVY SMASH` (Gut strike / Launcher | Ki: 10 | CD: 4.0s)
  - `[E] VANISH STRIKE` (Flash step behind target | Ki: 15 | CD: 3.0s)
  - Dynamic dark sweep cooldown overlays with decimal countdown timers.
- **Awakening Transformation Bar ([G] / [X])**:
  - Fills from 0% to 100% with combat damage and Ki charge.
  - At 100%: Electric sparks, pulsing gold/crimson border, and `⚡ AWAKENING READY [G] / [X] ⚡`.
- **Dynamic Comic-Book Combo Counter**:
  - `COMBO x4` lettering with spring-bounce animation, color escalation, and punch hit sound effects.
- **Martial Arts Battle Stances Menu (`[B]`)**:
  - Opens procedural stance selector powered by `ReplicatedStorage.Poses.PosePlayer` (Turtle Combat Stance, Saiyan Pride Stance, Ultra Instinct Sway, Power Surge, Kamehameha Charge).
