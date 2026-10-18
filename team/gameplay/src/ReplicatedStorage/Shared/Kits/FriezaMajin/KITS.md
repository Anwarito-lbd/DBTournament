# FriezaMajin kit: Frieza, Frost, Moro, Maji Kayo

Four fighters who share a cruel streak and nothing else. This file is the design sheet for each one, plus what the combat/VFX session still has to do. The data lives in `init.lua`, the effects in `VFX/`, and the clip sets in `Poses/`. The format is documented in `Kits/init.lua`. `tests/kit_friezamajin_tests.luau` checks the data.

Roster ids (from `Config.lua`): `u7_frieza` (forms FullPower, Golden, FriezaBlack), `u6_frost` (FullPower), `u7_moro` (MoroAwakened), `u3_maji_kayo` (FullPower). Frieza and Frost are the Frieza Race in `Races.lua`, Moro is Majin, and Maji Kayo has no race entry. The kit's `race = "FriezaMajin"` is only the folder's name. It does not change their race.

Grounding: the Dragon Ball Wiki pages for each fighter (techniques, forms, personality, Tournament of Power behaviour), plus the project's own `team/animation/movesets_v4.md`.

## How the game reads this kit

| Field | Reader | Effect |
|---|---|---|
| `powerUp` | `GameFeel` (hold-to-charge) | aura, crack colour and size, FOV push, scream stage |
| `forms[preset]` | `TransformCinematic` | replaces the shared `STYLE[preset]` for that fighter |
| `signatures[kind]` | `VFXRouter` | effect module for a server move kind (`Kamehameha` slot, `Heavy`, kit moves) |
| `cameras[kind]` | `VFXRouter` (local player only) | `FOVPunch(zoom)` + `CameraShake(shake)` |
| `clips` | `FightAnimator` | clip set in `Poses/`, which falls back to its parent set, then Goku, then Shared |
| `moves` | `Config` (merged into `Config.MOVES` when the id is free) | champion-gated kit moves of existing kinds |

## Frieza (`u7_frieza`): the emperor

**Who he is:** polite, composed and sadistic. He kills with one finger and treats a fight as something beneath him. His Nova Strike pushed Jiren out of the ring.

- **Power-up:** lilac, small FOV push (4). He never screams (stage 4): the composure is the threat. Cracks are slightly above normal (1.15) because the ground still breaks. No kit aura, so each form keeps its own.
- **Forms** (each preset now has a style; before this, `FriezaFullPower` had none):
  - `FriezaFullPower` "100% FULL POWER": violet, ground cracks, no lightning.
  - `GoldenFrieza` "GOLDEN FRIEZA": gold cocoon shell and calm rings. Regal, unhurried, with a slower orbit.
  - `FriezaBlack` "BLACK FRIEZA": black shell, the lights dim, slow-motion, the slowest orbit and the longest duration (3.2 s). On screen, he wins before anyone moves.
- **Signature slot: `FriezaDeathBeamVFX`.** Three Death Beams from one finger, 0.1 s apart, almost no charge. The first two land just off the mark and the third lands dead on. The colour follows his `Form` attribute: pink-violet in base and 100%, gold in Golden, crimson on black in Black. The camera barely moves (zoom 5, shake 0.2).
- **Heavy (tail lash):** a low crescent and one precise ring, with no crater.
- **Ki blast:** a fast, thin pink Death Bullet (260 studs/s).
- **Kit moves:**
  - `DeathSaucer` (ray, 9 s): a homing saw disc that cuts guard and can't be parried. Two discs fan out in Golden, and the disc is crimson on black in Black (`DeathSaucerVFX` on the shared `DestructoDiscVFX`).
  - `NovaStrike` (melee, range 14, 11 s): the energy-wrapped tackle. It is violet, gold in Golden, and in Black it becomes the Black Nova (a void swells on the target, then bursts). It uses `FriezaNovaVFX`, which flies the sphere to the hit point. The shared `NovaStrikeVFX` follows his root, so without a server dash it would explode where he stands.
- **Clips:** the shared Frieza set (upright poise, hand on hip, Death Beam finger), plus his own `Transform_SSJ`. Without it, his power-up and every transformation played Goku's Super Saiyan scream. His surge is composed: chin up, leaning back, then both arms spread wide with the palms out.

## Frost (`u6_frost`): Universe 6's "hero"

**Who he is:** the Peace Prize winner who starts the wars he ends. He plays the gentleman and fights dirty when he is losing, with a poison needle hidden in his wrist. His final form is a power he once couldn't control. Frieza "taught" him 100% Full Power and then threw him out of the ring.

- **Power-up:** icy blue-violet, FOV 6. He screams from stage 2 and cracks more ground than Frieza (1.3): he can't hold it in. The aura is `FriezaFullPower` (lilac), the 100% his senpai showed him. He has a single form, so a kit aura is allowed.
- **Form:** `FrostFinal` "FINAL FORM": blue, with lightning, cracks and a faster orbit (1.2). It is a loud, barely held transformation, the opposite of Golden Frieza's calm. **The preset is pending** (see server work 2).
- **Signature slot: `ChaosBeamVFX`.** One wider, colder finger beam (ice core, blue-violet glow), then two stray Chaos Shots sprayed to either side. It is the same technique as his senpai's, done louder and less exactly.
- **Heavy (poison needle):** a thin needle flicks from the wrist to the target, then a violet-green poison cloud lingers on them for about 1.2 s. The striker's camera barely moves (shake 0.15): it is a sneaky hit.
- **Ki blast:** a blue-violet Chaos Shot.
- **Kit move:** `DirtyBurst` (melee, range 8, 10 s). An afterimage smear, a point-blank ki flare in the palm, then a blast straight through the target and out the other side. It is ugly on purpose.
- **Clips (`Poses/Frost.lua`, on the shared Frieza set):**
  - Idle: hands clasped behind the back, head inclined politely.
  - Heavy: the wrist drawn back low, then driven out at full reach.
  - `Transform_SSJ`: hunched with fists at the hips, then a roar with the arms thrown back.
  - Beam stance: Frieza's Death Beam finger, which is the canon Chaos Beam stance.

## Moro (`u7_moro`): the Planet-Eater

**Who he is:** an ancient sorcerer who sees life as food and training as stupidity. He feigns weakness, drains you while you're busy fighting someone else, and copies what he absorbs. When part-restored his aura is purple. In his prime it is orange.

- **Power-up:** purple (his part-restored colour), the smallest FOV push (3). He never screams and his cracks are small (0.6): he takes from the ground rather than breaking it. The aura is `ToppoGoD` as a purple stand-in until a Moro aura exists (server work 3).
- **Form:** `MoroAwakened` "AWAKENED MORO": green (the project's moveset spec, `#78E65A`) with an orange flash (his prime aura). The lights dim, life-energy wisps stream into him, and the ground cracks. The orbit is slow and the duration long.
- **Signature slot: `MoroMouthWaveVFX`.** The Mouth Energy Wave he used on Buu and on Ultra Instinct Goku. Green motes rise from the ground into his jaw, then a ragged purple-green beam with a dark haze leaves his mouth. It fires from the head, not the hands, so it never reads as a Kamehameha. His camera hits the hardest of the four on his beam (zoom 8, shake 0.5).
- **Heavy (drain palm):** a dark ring at the palm, and green motes pulled from the target back into his hand.
- **Ki blast:** three slow green orbs in a fan (the moveset spec's "triple shot").
- **Absorb (`MoroAbsorbTouchVFX`):** finds the character standing at the hit position and runs the shared `MoroAbsorbVFX` drain on them for 1.2 s. The camera closes in slightly (zoom -4). This also fixes the router's default `Absorb` mapping, which passes the hit position where `MoroAbsorbVFX` expects a Model.
- **Kit move:** `PsychoJavelin` (ray, 10 s). A sharpened tree trunk rises beside him in a purple telekinetic glow, swings round to aim, hangs for a breath, is thrown, and splinters on impact. It is sorcery, not ki.
- **Clips (`Poses/Moro.lua`, on Shared rather than Goku):**
  - Idle: hunched elder, hands behind the back, head pushed forward.
  - `Kamehameha_*`: the mouth-wave stance. The head goes back with the arms spread low, then snaps forward.
  - Heavy: the drain palm.
  - `Transform_SSJ`: feeding, with arms wide, palms up and head back.

## Maji Kayo (`u3_maji_kayo`): the protean jelly

**Who he is:** a shining blue jelly from Universe 3 with three shapes: formless, slim, and muscular. He is cunning, sadistic and arrogant. He restrained Super Saiyan Goku, feigned surrender to trap Dyspo in his liquid body, and regenerates in moments. His wiki techniques are Shapeshifting, Regeneration, Submission, Mystic Attack, Scissor Hands and Giant Fist. **He has no ki beam.**

- **Power-up:** shining blue. He swells rather than powers up, so he has the biggest FOV push (8) and the smallest cracks (0.5). He is arrogant and picks fights, so he screams from stage 2. No kit aura.
- **Form:** `KayoMuscular` "MUSCULAR FORM": the jelly closes into a blue shell and re-forms bigger. It is quick (2.2 s) with no lightning. **The preset is pending** (see server work 2).
- **Signature slot: `MysticAttackVFX`.** The Mystic Attack: his right arm stretches across the arena as a chain of glassy blue segments with a swollen fist on the end. It sags slightly in the middle, splashes on contact and snaps back. It is elastic, not energetic.
- **Heavy (Giant Fist):** a jelly fist swells at the point of impact, splashes droplets and cracks the ground. His camera kick is the heaviest of the four on a Heavy (zoom 6, shake 0.55).
- **Ki blast:** a slow blue jelly glob (120 studs/s).
- **Kit moves:**
  - `ScissorHands` (melee, 5 s): two blue blades cross in an X. Quick and cheap, and it chips guard.
  - `Submission` (melee, 14 s): a jelly sphere closes over the target, wobbles for the hold (hitstun 1.2 s, matched by `SubmissionVFX.STYLE.Hold`), then bursts into droplets.
- **Clips (`Poses/MajiKayo.lua`, on Shared):**
  - Idle: a wide, loose jelly sway.
  - Heavy: an overhead Giant Fist slam.
  - `Kamehameha_*`: the arm cocked back, then thrown out at full stretch.
  - `Transform_SSJ`: a double-biceps flex that grows on each pulse.

## Distinctness at a glance

| | Frieza | Frost | Moro | Maji Kayo |
|---|---|---|---|---|
| Scream | never | from stage 2 | never | from stage 2 |
| Charge FOV / cracks | 4 / 1.15 | 6 / 1.3 | 3 / 0.6 | 8 / 0.5 |
| Signature | 3 Death Beam needles | Chaos Beam + strays | Mouth Energy Wave | stretching arm |
| Heavy | tail crescent | poison needle | drain palm | Giant Fist |
| Ki blast | fast pink needle | blue-violet shot | 3 green orbs | slow jelly glob |
| Form beat | calm shell / dark slow-mo | lightning, loss of control | dark, life wisps | jelly shell |

## Needs server work

For the combat/VFX session. None of these were edited here.

1. **Kit ki blasts are never drawn.** `VFXRouter` draws every `KiBlast` with the shared projectile and returns before asking the kit. It should ask `Kits.signature(id, "KiBlast")` first (and `Kits.camera`). `FriezaMajinKiBlastVFX` is ready: Moro's three-orb fan and Kayo's slow glob only appear once it is called. The Saiyan kit needs the same change.
2. **Two forms have no preset.** Frost's and Maji Kayo's only form is `FullPower`, and `Config.vfxFor` returns nil for it, so they get no cinematic. The kit styles are ready, and the test allows these two as pending. Add:
   - `Config.FORM_VFX_OVERRIDES.u6_frost = { FullPower = "FrostFinal" }`
   - `Config.FORM_VFX_OVERRIDES.u3_maji_kayo = { FullPower = "KayoMuscular" }`
3. **Auras.**
   - `VFXCommon.AURAS` has no `MoroAwakened`, `FrostFinal` or `KayoMuscular` entries, so those cinematics fall back to the white Default aura. The moveset spec gives Moro `#78E65A`.
   - Moro's charge uses `ToppoGoD` as a purple stand-in. Add a Moro purple aura and switch `powerUp.aura` to it.
   - Separately, `GameFeel.formId()` checks the `Form` attribute (a form id such as `Golden`) against `AURAS`, which is keyed by preset (`GoldenFrieza`). Golden and Black Frieza therefore charge in the Default aura. Mapping through `Config.vfxFor(cid, form)` there would fix every fighter with a preset.
4. **Kit moves have no key.** `DeathSaucer`, `NovaStrike` (Frieza), `DirtyBurst` (Frost), `PsychoJavelin` (Moro), `ScissorHands` and `Submission` (Maji Kayo) merge into `Config.MOVES` and validate server-side (champion-gated). `CombatInput` binds no key to them. They need a kit-move key and HUD cooldown that read the active character's kit moves. The clips have no dedicated poses for them yet either: Frieza's shared set does carry `DestructoDisc` and `NovaStrike` clips that could play there.
5. **Nova Strike doesn't move Frieza.** It resolves as a range-14 melee in place. A server dash toward the target (like `Dash`) would make the tackle real. `FriezaNovaVFX` flies the sphere on its own until then.
6. **Frost's poison is only a look.** The Heavy shows a needle and a poison cloud but applies nothing. A short server-side "poisoned" debuff (slower ki regen or brief dizziness) would make the needle Frost's. Keep it mild, since he was disqualified for it in canon.
7. **Submission is a long hitstun, not a grab.** A real engulf would pin the victim and allow a mash-out (the boss grab's Combo Breaker pattern). `SubmissionVFX.STYLE.Hold` must match whatever hold time the server uses.
8. **Moro's Planet Drain needs an AoE kind.** `MoroPlanetDrainVFX` exists, but its API is `Play(moro, config)`, unlike the router's `Play(character, target, opts)`. The router would pass the hit position as `config`, so it needs a wrapper or a special case once a zone kind exists.
9. **Copy shows Moro's look, not the victim's.** A copied move is broadcast with the copied move's kind and Moro's character. `VFXRouter` then resolves Moro's own kit signature for that kind, so a copied Kamehameha plays his Mouth Wave. The broadcast would need the source fighter's id for the copy to look like the original.
10. **The router's default `Absorb` is broken for anyone without this kit.** `MODULES.Absorb = "MoroAbsorbVFX"` is called with a Vector3 where a Model is expected. Moro is fixed here through `MoroAbsorbTouchVFX`. Pointing the default at the same lookup would fix bosses or copies too.
11. **Possible duplicate entries.** The `kits-u6-u2` and `kits-u3-u4-u9-u10` sessions cover Universes 6 and 3. If either also defines `u6_frost` or `u3_maji_kayo`, `Kits` keeps whichever module loads last. Check when merging.

## Verify in Studio

Nothing here has been seen in Studio. Angles, colours and timings are design values.

- Each clip set on its rig: Frost's hands-behind-back idle and needle jab, Moro's hunch and mouth-wave stance, Kayo's sway, Giant Fist and arm stretch, and every `Transform_SSJ` surge (looped while charging, and as the transform clip). Watch for joint-axis surprises on the arms-behind-back and overhead poses.
- `FriezaDeathBeamVFX` in each Frieza form (pink, gold, crimson) and the three-needle rhythm. `ChaosBeamVFX` strays not hitting Frost's own feet.
- `MoroMouthWaveVFX` origin on Moro's head (it uses the `Head` part's LookVector) and the beam layers' wobble. `MysticAttackVFX` starting at the right shoulder and the sag reading as an arm.
- `FriezaMajinHeavyVFX` for each fighter: tail crescent orientation, needle line from the wrist, drain motes reaching the hand, Giant Fist size.
- `FriezaNovaVFX` flight and the Black Nova void. `DeathSaucerVFX` split in Golden. `PsychoJavelinVFX` trunk orientation (the long axis should point at the target) and splinters. `SubmissionVFX` following the victim.
- `MoroAbsorbTouchVFX` finding the victim at the hit position.
- Power-up per fighter: Frieza and Moro silent, Frost and Kayo screaming from stage 2, Kayo's wide FOV push, Moro's small cracks, Frost's lilac aura.
- Form cinematics: `FriezaFullPower` (new), Golden and Black (kit styles replace the shared ones), `MoroAwakened`. The two pending ones once server work 2 lands.
- The kit moves, once server work 4 gives them a key.
