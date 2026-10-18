# Saiyan kits: design sheet

Ten fighters, one race. The kit table is `init.lua`; the field format is documented in `../init.lua`. Effects live in `VFX/`, clip sets in `Poses/` (authored with `ClipBuilder.lua`), and the data check is `team/gameplay/tests/kit_saiyan_tests.luau`.

Techniques and forms follow the Dragon Ball wiki and the repo's moveset research (`team/animation/movesets*.md`). The wiki returns HTTP 402 to automated fetches, so the less familiar U6 fighters were checked against the repo notes rather than fetched live. All titles and descriptions are in our own words.

## How the kit reaches the game

| Field | Read by | When |
|---|---|---|
| `powerUp` | GameFeel | holding charge: aura, ground cracks, camera punch, the stage at which the face screams (4 = never) |
| `forms[preset]` | TransformCinematic | transforming; replaces the shared STYLE entry for that preset |
| `signatures[kind]` | VFXRouter | a server move broadcast (`Kamehameha` = the key-2 signature beam, `Heavy`, kit move ids) |
| `cameras[kind]` | VFXRouter | the local player's own move: FOV punch and shake |
| `clips` | FightAnimator | every combat pose; missing clips fall back to Goku's set, then Shared |
| `moves` | Config.MOVES | merged at load when the id is free |

The race defaults give every Saiyan `SaiyanHeavyVFX` (a contact look per fighter), `SaiyanKiBlastVFX` (a ki colour per fighter), and base cameras.

## Fighters

### Goku (`u7_goku`)
- **Identity:** a fighter who loves the fight. Calm and focused, then everything at once.
- **Power-up:** warm gold, zoom 5, crack 1.0, scream only at full power (stage 3).
- **Forms:** SSJ through SSJ3 build with lightning and cracks, and SSJ3 is the longest (3.2 s, wide orbit). God and Blue are serene: calm rings and wisps, no cracks. SSJ4 is crimson with a gold flash. UI Sign and MUI use slow motion with silver wisps.
- **Signature:** Kamehameha (`KamehamehaVFX`), camera zoom 8, shake 0.35.
- **Heavy:** a clean gold burst with a bright afterimage and no crack. It's technique, not destruction.
- **Kit move:** Dragon Fist (melee, 18 dmg, 25 ki, 12 s). A gold coil climbs off the impact (`DragonFistVFX`), camera zoom 6, shake 0.5.
- **Clips:** Goku set.

### Vegeta (`u7_vegeta`)
- **Identity:** pride. Louder, harder and quicker to anger than Goku in every beat.
- **Power-up:** blue-white, zoom 7, crack 1.35, roars from stage 2.
- **Forms:** every form arrives fast (2.2 s for SSJ and SSJ2) with lightning and broken ground. His God and Blue crack the floor where Goku's stay calm. Blue Evolved and Ultra Ego darken the scene.
- **Signature:** Final Flash (`FinalFlashVFX`), camera zoom 10, shake 0.5, the hardest of the U7 pair.
- **Heavy:** blue-white double ring and a ground crack.
- **Kit move:** Big Bang Attack (ray, 18 dmg, 25 ki, 9 s, `BigBangAttackVFX`), camera zoom 7, shake 0.45.
- **Clips:** Vegeta set.

### Gohan (`u7_gohan`)
- **Identity:** the scholar with the deepest well of power. He was taught by Piccolo, and his anger is the real trigger.
- **Power-up:** pale white-gold, a gentle zoom 4, but the biggest crack of the U7 trio (1.5). Screams at stage 3.
- **Forms:** SSJ2 is the Cell Games moment, with slow motion and lightning. Ultimate is calm, white and grounded. Beast is a dark red storm.
- **Signature:** Masenko (`MasenkoVFX`): gold-yellow, quick charge, narrower than a Kamehameha. Camera zoom 7.
- **Heavy:** a white burst with a big crack, the anger showing through.
- **Clips:** Gohan set. Piccolo-style wide stance with the lead hand open. Rising-knee finisher, two-fisted hammer heavy. The Masenko is held overhead in the beam slot.

### Future Trunks (`u7_trunks`)
- **Identity:** a swordsman from a ruined future: controlled, but angry underneath.
- **Power-up:** warm gold, zoom 5, small tidy cracks (0.9), shouts from stage 2.
- **Forms:** SSJ and SSJ2, both fast with lightning.
- **Signature:** Burning Attack (`BurningAttackVFX`): a small fast orange sphere after a run of hand signs. Camera zoom 6.
- **Heavy:** a pale-blue crescent cut instead of a burst.
- **Clips:** Trunks set. Side-on stance with the hand by the hilt. Horizontal slash finisher, rising-then-downward split heavy. The beam slot plays four hand signs, then the palm diamond.

### Broly (`u7_broly`)
- **Identity:** instinct and wrath, raised with no teacher. The opposite of technique.
- **Power-up:** red wrath aura (`KaioKen` preset) over green ki, zoom 9, the biggest crack in the race (1.8), roars from the very first stage.
- **Forms:** Full Power: green, dark, lightning, 3.2 s, the widest orbit. It waits on a preset mapping (see the list below).
- **Signature:** Gigantic Roar (`GiganticRoarVFX`): the widest, slowest beam in the kit. Camera zoom 12, shake 0.7.
- **Heavy:** a huge green double ring, crack 13 and 18 rocks.
- **Clips:** Broly set. Hunched, arms hanging wide. Shoulder-charge finisher, slow two-armed ground smash heavy. The beam slot is a chest-out roar.

### Cabba (`u6_cabba`)
- **Identity:** Universe 6's earnest soldier and Vegeta's student. Disciplined, modest, still finding his power.
- **Power-up:** cool lavender, zoom 4, small cracks (0.8), screams only at stage 3.
- **Forms:** SSJ is a clean first awakening with lightning and no cracks. SSJ2 adds the cracks.
- **Signature:** Galick Cannon (`GalickCannonVFX`): Vegeta's purple beam, but thinner, faster and cooler. Camera zoom 6.
- **Heavy:** a compact violet ring.
- **Clips:** Vegeta set (he learned from Vegeta).

### Caulifla (`u6_caulifla`)
- **Identity:** a gang boss with natural talent and no patience.
- **Power-up:** pink ki on gold, zoom 6, shouts from stage 2.
- **Forms:** her own Super Saiyan preset (`CauliflaSSJ`) is the fastest cinematic in the kit (2.0 s, wide orbit), with lightning and cracks. SSJ2 is the same temper.
- **Signature:** Crush Cannon (`CrushCannonVFX`): almost no charge, short, wide and hot pink. Camera zoom 5, shake 0.4.
- **Heavy:** a pink double ring with a pink afterimage.
- **Clips:** Caulifla set. Hand on hip, chin up. Spinning back-kick finisher, jumping axe-kick heavy. A one-armed hip shot in the beam slot.

### Kale (`u6_kale`)
- **Identity:** timid until something snaps.
- **Power-up:** green, zoom 8, crack 1.7. Quiet through stages 1 and 2, then the eruption at stage 3.
- **Forms:** SSJ is controlled (calm rings, no cracks). Berserk (`KaleBerserk`) is green, dark, enormous and long.
- **Signature:** Eraser Cannon (`EraserCannonVFX`): a green sphere pushed from one palm. Camera zoom 9, shake 0.55.
- **Heavy:** a big green ring with a heavy crack.
- **Clips:** Kale set. A shy stance, hands clasped low and eyes down. Her strikes inherit Broly's set; the beam slot is a one-arm push.

### Kefla (`u6_kefla`)
- **Identity:** Caulifla and Kale fused by Potara: one's swagger, the other's weight.
- **Power-up:** yellow-green, zoom 7, crack 1.3, shouts from stage 2.
- **Forms:** the Potara reveal is a calm flash with lightning (3.0 s). SSJ is quick and stormy. SSJ2 (`KeflaSSJ2`) is the biggest storm.
- **Signature:** Gigantic Ray (`GiganticRayVFX`): a wide, spiralled yellow-green ray. Camera zoom 9.
- **Heavy:** a yellow-green double ring with an afterimage.
- **Clips:** Kefla set. Squarer and taller than Caulifla, with a two-footed drop-kick heavy and a two-palm ray in the beam slot. The finisher is inherited from Caulifla.

### Goku Black (`u10_goku_black`)
- **Identity:** a god in a stolen body: unhurried, contemptuous, never raises his voice.
- **Power-up:** rose aura (`FriezaFullPower` preset, the closest lavender-pink), zoom 4, barely cracks the ground (0.7), never screams (stage 4).
- **Forms:** Super Saiyan Rosé: calm rings and rose wisps, no cracks. It waits on a preset mapping (see the list below).
- **Signature:** Black Kamehameha (`BlackKamehamehaVFX`): Goku's beam in rose over near-black. Camera zoom 7, shake 0.3.
- **Heavy:** a rose crescent cut (a ki blade). The camera barely moves (zoom 2, shake 0.2).
- **Clips:** GokuBlack set. Upright, left hand behind the back. Palm-strike finisher, ki-blade thrust heavy. The beam slot falls through to Goku's cupped hands, on purpose.

## Needs server work

For the combat/VFX session. None of these were edited here.

1. **Kit ki blasts are never drawn.** `VFXRouter` draws every `KiBlast` with the shared projectile and returns before asking the kit. Ask `Kits.signature(id, "KiBlast")` first (and `Kits.camera`). `SaiyanKiBlastVFX` is ready and gives each fighter their own colour.
2. **Vegeta's beam stance.** `FightAnimator.beamClips` picks clips by id substring, so Vegeta plays `GalickGun_*` while his signature is the Final Flash. The Vegeta set already has `FinalFlash_*`. Suggested fix: a kit field, e.g. `beamClips = { "FinalFlash_Charge", "FinalFlash_Fire" }`.
3. **Two forms have no preset.** Broly's and Goku Black's only form is `FullPower`, and `Config.vfxFor` returns nil for it, so they get no cinematic. Add `Config.FORM_VFX_OVERRIDES.u7_broly = { FullPower = "BrolyFullPower" }` and `u10_goku_black = { FullPower = "BlackRose" }`. The kit styles are ready, and the test allows them as pending.
4. **Missing aura entries.** `VFXCommon.AURAS` lacks a green Legendary aura (Broly), a rose aura (Goku Black), and auras for `CauliflaSSJ`, `KaleBerserk`, `KeflaSSJ2`, `KeflaPotara`, `GohanUltimate` and `SSJ4`. Their cinematics fall back to the white Default aura. Once a green and a rose entry exist, switch Broly's and Black's `powerUp.aura` to them.
5. **Kit moves have no key.** `DragonFist` (Goku) and `BigBangAttack` (Vegeta) merge into `Config.MOVES` and validate server-side (champion-gated), but `CombatInput` binds no key to them. They need a kit-move key (and a HUD cooldown) that reads the active character's kit move.
6. **Form-aware signatures.** Beast Gohan should fire the red Special Beam Cannon (`BeastSBCVFX`) instead of the Masenko, and MUI Goku could use a different beam. The kit format has one signature per move kind; this needs something like `formSignatures = { [formId] = { [kind] = module } }` in `Kits/init.lua` and `VFXRouter`.
7. **Kale's berserk behaviour.** The moveset notes describe losing control (auto-run at the nearest enemy) in Berserk. That's a server mechanic, not a visual one.
8. **Trunks' sword.** His clips and Heavy slash assume a sword on the rig. That needs an accessory or prop from art.

## Verify in Studio

Nothing here has been seen in Studio yet. Angles and colours are design values.

- Each clip set on its rig: the new idles, finishers, heavies and beam-slot stances (Gohan, Trunks, Broly, Kale, Caulifla, Kefla, Goku Black). Watch for joint-axis surprises.
- Each signature beam or sphere fires from the hands and reads as its own colour and size.
- `SaiyanHeavyVFX` on a Heavy hit for each fighter: burst vs crescent, crack size, and the onlooker shake.
- Power-up charge for each fighter: scream stage (Black never screams, Broly from stage 1), crack size, and Broly's red aura with green cracks.
- Form cinematics, including SSG and SSJ4 for Goku and Vegeta, which had no shared style before.
- `DragonFistVFX` and the Big Bang Attack once item 5 gives them a key.
