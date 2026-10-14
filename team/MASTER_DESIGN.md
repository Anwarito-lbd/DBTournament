# Dragon Block Z — Master Design (v1–v4)

Game name: **Dragon Block Z**. "Tournament of Power" is the main mode/event name.

> **v4 design change (user):** universes are numbered teams (`Universe 1..N`). Any player can pick any unlocked champion, and a champion's universe is lore only. Only one of each champion per team; duplicates across teams are allowed. Skill beats stats: all stat gaps are compressed to ≤ 1.35×. Details are in `gameplay/SPEC.md` §0.
This is a consolidated overview of every system so far. Detailed specs live with each owner:
- **Gameplay:** `gameplay/SPEC.md` (v3) and the code in `gameplay/src/`, owned by db-gameplay.
- **Map:** `map/layout_spec.md` (v1.1), `map/BuildArena.lua` and `map/ArenaDamage.lua`, owned by db-map.
- **Story:** `story.md` (v1), owned by db-story.
- **Animation / VFX:** `animation/movesets.md`, `movesets_v2.md`, `README.md` and the VFX modules, owned by db-animation.
- **Lead:** roblox.

## 1. Core loop
1. **Lobby (World of Void):** the lobby hub sits at (3000, 100, 0), with Queue/Shop/Training pads.
2. **Queue:** players pick Random or Party.
3. **Teams:** players are split into 2–8 numbered teams (`Universe 1..N`), `min(n, clamp(floor(n/3), 2, 8))`. Parties stay together, and teams are balanced on total Power Level.
4. **CharacterSelect (12s):** each player picks any unlocked champion, subject to one per team (first come first served, with fallback picks) and the team power budget. Divine champions need event mode or must fit the budget and caps.
5. **Countdown, then teleport:** players move to db-map's `ArenaSpawn` pads (`Universe="U0i"` for team i). db-story's intro cutscene can play during this phase (hook `RoundStarted`).
6. **Fight (300s):**
   - **Elimination:** players are knocked out by KO or ring-out on the destructible floating ring (Ø300, 90 chunks).
   - **Abilities:** ki charge, transformations, team combos, fusion, and the last energy gift.
   - **Eliminated players** spectate from their universe's stand.
7. **Win:** last universe standing. On timeout, the most survivors wins. Then the db-story ending plays (Super Shenron, wish choice) through `RoundEnded`.
8. **Rewards and reset:** XP is awarded, the ring is reset (`ArenaDamage.Reset()`) and players return to the lobby.

## 1b. Lobby size and arena resize
- **Size:** up to **40 players**, as 8 teams × 5 (`Config.MAX_PLAYERS`, `MAX_TEAM_SIZE`). Max Players must also be set to 40 in Studio Game Settings.
- **Team count:** `min(n, clamp(max(floor(n/3), ceil(n/5)), 2, 8))`. 40 players gives 8×5, and 24 gives 8×3.
- **Resize:** RoundManager calls db-map's `Resize(teamCount, playerCount)` after team assignment, wrapped in `pcall`, then refreshes the arena references. Teammates are spread around their team's pad. The module path is pending db-map.

## 2. Progression
- **XP:** 10/min played, KO 15, placement 5 × rank, win 100, team-combo link 3.
- **XP multipliers:** passes, the boost product, and +5% per prestige.
- **Levels:** 1–100, with XP to next level `floor(100·L^1.5)`.
- **Prestige:** available at level 100, up to 10. It resets level and keeps unlocks.
- **Unlocks by level:**
  - roster characters (Lv 1–50);
  - forms: KaioKen 5, FullPower 10, SSJ 15, SSJ2 30, KeflaPotara 35, SSJ3 40, Ultimate 45, Golden 55, SSG 60, SSB/Legendary 75, UltraInstinctSign 85, SSBEvolved 90, MoroAwakened/BeastGohan/FriezaBlack 95, MUI/UltraEgo 100 (MUI and UltraInstinctSign are distinct);
  - power-ups: KiBlast 3, SignatureBeam 10, InstantTransmission 25, Potara 35.
- **Divine tiers (playable, top of progression):**
  - Gods of Destruction `div_destroyer_<name>`: level 100 or prestige 1.
  - Angels `div_angel_<name>`: prestige 3.
  - `div_grand_priest`: prestige 5, event only.
  - `div_zeno`: prestige 10, event only, ultra-rare. Non-combat; **Erase** eliminates one random enemy after an 8s warning, once per match, enforced by the server.
  - Caps: unique IDs, at most 1 per team, must fit the team budget outside event mode, GoD ≤ 2 and Angel ≤ 1 per match, at most 3 total outside event mode.

## 3. Rosters (stable IDs `u<N>_<name>`; the universe is lore only since v4)
- **U7:** Goku, Vegeta, Gohan, Piccolo, 17, 18, Krillin, Tien, Roshi, Frieza (Frieza stays in U7).
- **U11:** Jiren, Toppo, Dyspo and the Pride Troopers.
- **U6:** Hit, Cabba, Caulifla, Kale, Frost, Botamo, Magetta, Saonel, Pirina, and **Kefla** (`u6_kefla`: direct pick at Lv35, or through Potara with Caulifla + Kale).
- **U2, U3 (Anilaza), U4, U9, U10:** see SPEC §6.
- **Moro** `u7_moro` (alias `bonus_moro`): S tier, Lv90, guest. His kit is Absorb (drains ki, +PL capped at 25%) and Copy (the target's last move at 70%). Form: MoroAwakened.
- **Fusion-only results:** `fus_gogeta` (Dance) and `fus_vegito` (Potara), from Goku + Vegeta.
- **db-animation `movesets_v2.md`** covers 21 fighters with move sets. The rest use the standard ~30-clip set until they get their own.

## 4. Power Level, balance model and combat (v4)
- **Power Level (display and matchmaking):** `floor((base + level·50) · formMult · (1 + kiCharge + giftBoost + absorbBoost))`.
- **Tier gap compression:** in every interaction, `ratio = clamp((PL_att/PL_vic)^0.25, 1/1.35, 1.35)`. Damage scales ×ratio, knockback ×√ratio, and beam-struggle inputs ×ratio. **The maximum stat edge is 1.35×.**
- **Tiers:** S ≥ 1000 base, A ≥ 850, B ≥ 750, otherwise C. Divine tiers keep their own.
- **Counterplay by tier:**
  - **Hurtbox (×2-stud radius):** C 1.0, B 1.05, A 1.1, S 1.2, GoD/Angel 1.3, GP 1.35, Zeno 1.4.
  - **Ki regen (8/s base):** C 1.0, B 0.95, A 0.9, S 0.85, GoD/Angel 0.75, GP/Zeno 0.7.
  - **Recovery:** C 1.0, B 1.05, A 1.1, S 1.15, GoD/Angel 1.25, GP/Zeno 1.3.
- **Team fairness:**
  - **Matchmaking:** teams are filled by lowest total Power Level.
  - **Budget:** `Σ tier cost ≤ 3·teamSize + 1`, with costs C1, B2, A3, S4, GoD6, Angel7, GP9, Zeno10.
  - **Event mode** waives the budget.
- **Skill expression (server-validated):**
  - **Block:** 15% chip damage, guard meter of 100.
  - **Perfect block / parry:** within 0.2s. The attacker is stunned 0.8s and the defender gains 10 ki.
  - **Guard break:** a Heavy or an empty guard causes a 1.2s stun.
  - **Dash:** cooldown 0.8s. Dash-cancel out of recovery costs 15 ki.
  - **Vanish:** 25 ki, 0.35s i-frames.
  - **Combo breaker:** only in hitstun, 50 ki, cooldown 8s.
  - **Beam struggle:** won by mashing (≤ 15/s) or by timing on the 0.5s pulse (×3); the winner hits at 1.25×.
  - **Ring-out positioning:** knockback grows by +150% at 0 HP.
- **Team combos:** `1 + 0.1·links`, up to 5 links within 1.5s. db-map ArenaDamage is used for KiBlast (r6/p25), Kamehameha (r18/p120) and Final Explosion (r35/p220).
- **Final Explosion** (Vegeta, HP ≤ 25%, once per round): a 2s armoured server timer, then an 80-damage AoE at r35, arena damage, and a self-KO counted as the caster's elimination. The client's `OnDetonate` is ignored.
- **db-animation numbers:** their multipliers and proposals are visual or design input. **Gameplay Config numbers are canonical.**

## 5. New v3 features
- **Last energy gift:** a 2s window after a KO or ring-out to gift a boost to a teammate within 40 studs of the death position. Server-validated, one per round.
- **Spectate:** the server keeps `Spectating`/`SpectateTarget` state. The client has an orbit camera (Q/E to switch target) and a free camera (F).
- **Fusion:**
  - **Dance:** 3s still and vulnerable, 12 studs, lasts 60s.
  - **Potara:** needs earrings, 1.5s, 10 studs, lasts 90s.
  - **Fused character:** the stronger player controls it, with HP = average × 1.3. The other player is a passenger who spectates.
  - **Restore or eliminate:** both players are restored on timeout, and both are eliminated if the controller is eliminated.

## 6. Map integration (db-map v1.1)
- **Arena:** the ring is at (0, 500, 0). There are 12 stands at r=420 with `StandSpawn` pads, and a Zeno box at (0, 700, −520).
- **Ring-out (final rule):** touching any non-ring surface (`IsRingSurface == false`), or staying below Y 480 for more than 1s. Polled at 10 Hz on the server.
- **ArenaDamage:** server-only, rate-limited to 30 calls/s with a cap of 16 chunks per call. `Reset()` runs between rounds.
- **Spawns:** taken from CollectionService tags, with a folder fallback.

## 7. Story integration (db-story v1)
- **Cutscenes:** the intro (Grand Priest and Zenos, ~75s) and ending (Super Shenron, Power or Restoration wish) use `RoundStarted`/`RoundEnded`. The `ReplicatedStorage/StoryDialogue` module holds the lines.
- **Universe identity (lore):** universe lore, gods and angels match the divine IDs (Champa/Vados U6, Beerus/Whis U7, Belmod/Marcarita U11, Heles/Sour U2, Mosco/Campari U3, Quitela/Cognac U4).
- **Gaps:** the story covers 6 universes. U9 and U10 still need story lines.
- **Timer:** the story says 48 minutes, but the gameplay round is 300s. Lead to decide (suggest the story uses a "48 minutes" fiction with an accelerated clock).

## 8. Monetization (Roblox policy compliant)
- **Game Passes:** DoubleXP, VIP, EarlySuperSaiyan, EarlyBlue, EarlyJiren, PotaraEarrings.
- **Developer Products:** XPBoost30, XPPack500, SenzuBean.
- **Rules:**
  - No random paid items.
  - Divine tiers cannot be bought.
  - ProcessReceipt is idempotent.
  - Everything paid can also be earned by free players.
- **IDs:** placeholders (0) until they're created in the Creator Dashboard.

## 9. Data
- **Store:** DataStore `ToP_PlayerData_v1`, schema v4 (adds prestige).
- **Saving:** session lock through UpdateAsync, retries with backoff, autosave every 120s, BindToClose.
- **Migrations:** up to v4 (includes renaming `UltraInstinct` to `MUI`).

## 10. Open items and coordination
- **IDs (aligned with `animation/movesets_v4.md`):** `u6_kefla`, `u7_moro`, `div_destroyer_<name>`, `div_angel_<name>`, `div_grand_priest`, `div_zeno`, and the forms SSBEvolved, UltraEgo, KeflaPotara, BeastGohan, FriezaBlack, MoroAwakened, UltraInstinctSign and MUI. db-animation may reuse the divine IDs for raid NPCs. db-animation's divine and Moro kit proposals (Hakai, Angel auto-dodge, Planet Drain) are v5 candidates.
- **Move sets:** db-animation needs move sets for divine tiers, fusions (Gogeta/Vegito) and the remaining roster.
- **Open items:** the speed/teleport anti-cheat, UI and Angel auto-dodge, the Ultra Ego damage-growth passive, and Vegeta's Pride team buff after Final Explosion.
- **Map:** pillar destruction (map v2). Team i uses the stand and spawn `U0i` (teams 1–8 of the 12 pads).
