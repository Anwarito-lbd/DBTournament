# Variable-Ratio (VR) Reinforcement Architecture & Player Retention Engine

## 1. Operant Conditioning: Why Variable-Ratio Keeps Players Hooked
In behavioral psychology (B.F. Skinner's reinforcement research), a **Variable-Ratio (VR) schedule** provides reinforcement after an unpredictable number of responses (actions).
- **Fixed Schedules (FI / FR):** Predictable schedules (like a daily login or fixed 1,000 XP tier) suffer from the **"Post-Reinforcement Pause"** — players log off or feel fatigued right after earning the reward.
- **Variable-Ratio Schedules (VR):** Because the player *never knows* whether the next match, combo, or capsule contains a jackpot, dopamine remains constantly elevated. This schedule generates:
  1. The **highest rate of engagement** (fastest match rematching).
  2. The **highest resistance to extinction** ("one more game" syndrome).
  3. Continuous player retention across session lengths.

---

## 2. The 3-Tier Variable-Ratio Architecture for Dragon Block Z

```
┌────────────────────────────────────────────────────────┐
│             VARIABLE-RATIO RETENTION LAYERS            │
├─────────────────────┬──────────────────────────────────┤
│ Layer 1: Macro VR   │ "Divine Favor" / Zeno's Burst    │
│                     │ (VR-4 Average + 6-Match Pity)    │
├─────────────────────┼──────────────────────────────────┤
│ Layer 2: Micro VR   │ In-Combat Sensory Spikes         │
│                     │ (VR-8 Super Impact, Clutch Aura) │
├─────────────────────┼──────────────────────────────────┤
│ Layer 3: Cognitive  │ "Near-Miss" Framing Hook         │
│                     │ (<=18% Remaining Flash Banner)   │
└─────────────────────┴──────────────────────────────────┘
```

---

### Layer 1: Macro VR Schedule — "Zeno's Divine Favor"
- **Schedule:** Variable-Ratio with an average expectation of **1 in 4.5 matches** (baseline $22\%$ chance, dynamically climbing $+4\%$ per match with bad luck, and guaranteed pity at match 6).
- **Non-P2W Compliance:** Strictly compliant with D13 and the $1.35	imes$ stat cap. Rewards are **purely currency, XP bursts, titles, and cosmetic auras**.
- **Payout Tiers:**
  1. **Common (60% of triggers):** *"Zeni Surge"* — $1.5	imes$ to $2.5	imes$ match Zeni multiplier (+500–1,500 bonus Zeni).
  2. **Uncommon (25% of triggers):** *"Whis's Insight"* — Sudden $+600	ext{--}1,800$ bonus XP surge toward character progression.
  3. **Rare (12% of triggers):** *"Capsule Corp Mystery Drop"* — Drops 2,000 Zeni + an exclusive tournament title (*"Arena Veteran"*, *"Ki Prodigy"*, *"Void Breaker"*).
  4. **Jackpot (3% of triggers):** *"Zeno's Divine Blessing"* — 5,000 Zeni, $+3,500$ XP, exclusive animated title *"Omni-Blessed"*, and sparkling divine aura `Aura_ZenoSparkle`.

---

### Layer 2: Micro VR Schedule — In-Match Combat Sensory Spikes
- **Super Impact Frame (VR-8 / ~12% Chance):**
  - On heavy attacks, guard breaks, and combo enders, a variable-ratio roll triggers a **Super Impact Frame**.
  - **Sensory Explosion:** Screen flashes in inverted black-and-gold silhouette, time freezes for $0.12	ext{ s}$, a resonant sub-bass gong chimes, and a comic `"IMPACT!"` decal explodes.
- **Clutch Adrenaline Trigger (VR-5 / ~20% Chance):**
  - When fighting below $20\%$ HP and landing a parry or counter-vanish, a VR trigger fires Lord Zeno's delighted voice line (*"Waku waku!"*) accompanied by crowd cheering from the stands.

---

### Layer 3: Cognitive "Near-Miss" Framing
- **The Psychology:** Neurological studies demonstrate that near-misses (feeling like you were *almost* there) stimulate the exact same dopamine centers as a jackpot win.
- **Implementation in [DivineFavorUI.client.lua](file:///C:/Users/issao/Documents/DBTournament/team/gameplay/src/StarterPlayer/StarterPlayerScripts/DivineFavorUI.client.lua):**
  - When a player is within $18\%$ of leveling up or unlocking a signature transformation (e.g. Kaioken at Lv5, SSJ at Lv15, SSB at Lv75, MUI at Lv100):
  - The UI flashes a pulsing crimson and gold banner:
    ```
    ⚡ ONLY 1 MATCH AWAY FROM UNLOCKING SUPER SAIYAN!
    ```
  - This immediately breaks the player's urge to leave the server and guarantees a rematch.

---

## 3. Technical Implementation & DataModel State

1. **[VariableRatio.lua](file:///C:/Users/issao/Documents/DBTournament/team/gameplay/src/ReplicatedStorage/Shared/VariableRatio.lua):**
   - Pure math engine implementing `shouldTrigger()`, `rollReward()`, `checkNearMiss()`, and `validateReward()`.
2. **[variable_ratio_test.luau](file:///C:/Users/issao/Documents/DBTournament/team/gameplay/tests/variable_ratio_test.luau):**
   - Verified 100% green tests covering dynamic odds, pity guarantees, and non-P2W safety.
3. **[DivineFavorService.lua](file:///C:/Users/issao/Documents/DBTournament/team/gameplay/src/ServerScriptService/Modules/DivineFavorService.lua):**
   - Server-side evaluator connected to `RoundEnded.Event`. Evaluates streaks, rolls payouts, grants rewards via `PlayerData`, and fires remotes.
4. **[DivineFavorUI.client.lua](file:///C:/Users/issao/Documents/DBTournament/team/gameplay/src/StarterPlayer/StarterPlayerScripts/DivineFavorUI.client.lua):**
   - Smooth celebratory modal with card pop animations, Zeno praise quotes, and near-miss alerts.
5. **[V12Boot.server.lua](file:///C:/Users/issao/Documents/DBTournament/team/gameplay/src/ServerScriptService/V12Boot.server.lua):**
   - Initialized in the core server boot sequence.
