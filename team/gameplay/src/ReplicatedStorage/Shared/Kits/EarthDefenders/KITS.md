# Earth defenders kits: design sheet

Seven Universe 7 fighters from four races: Piccolo (Namekian), Android 17 and 18 (Android), Krillin, Tien and Master Roshi (Earthling), and Shin (Kaioshin). The kit table is `init.lua`, and the field format is documented in `../init.lua`. Effects live in `VFX/`, clip sets in `Poses/` (authored with `ClipBuilder.lua`, the same builder as the Saiyan kit's). The data check is `team/gameplay/tests/kit_earthdefenders_tests.luau`.

Techniques follow the Dragon Ball wiki (dragonball.fandom.com), read in the browser because WebFetch gets HTTP 402. Pages used: Special Beam Cannon, Light Grenade, Explosive Demon Wave, Hellzone Grenade, Destructo Disc, Scattering Bullet, Solar Flare, Tri-Beam, Neo Tri-Beam, MAX Power Kamehameha, Max Power, Android Barrier, Power Blitz, Infinity Bullet, Sadistic 18, Super Electric Strike, Kai Kai, Energy's Last, Kiai and Invisible Eye Blast, plus the character pages. All titles and descriptions are in our own words. No dialogue or media is reproduced.

## How the kit reaches the game

| Field | Read by | When |
|---|---|---|
| `powerUp` | GameFeel | holding charge: aura, ground cracks, camera punch, the stage at which the face screams (4 = never) |
| `forms[preset]` | TransformCinematic | transforming; replaces the shared STYLE entry for that preset |
| `signatures[kind]` | VFXRouter | a server move broadcast: `Kamehameha` (the key-2 signature slot), `Heavy`, the race power-ups `Barrier` / `SolarFlare` / `KaiKai`, and kit move ids |
| `cameras[kind]` | VFXRouter | the local player's own move: FOV punch and shake |
| `clips` | FightAnimator | every combat pose; missing clips fall back to Goku's set, then Shared |
| `moves` | Config.MOVES | merged at load when the id is free |
| `race` | nobody (notes) | each entry's own race, checked against `Races.CHAMPION` by the test |

Race defaults give every fighter `EarthHeavyVFX` (one contact look per fighter), `EarthKiBlastVFX` (one ki colour per fighter) and `TaiyokenVFX` for the Earthlings' Solar Flare. No entry sets `powerUp.aura`, because `VFXCommon.AURAS` has no green, teal or lavender entry. Everyone gets the white Default aura, and the kit colour drives the cracks and shockwave.

## Fighters

### Piccolo (`u7_piccolo`, Namekian)
- **Identity:** the strategist and Gohan's teacher. Patient, dry, always a step ahead.
- **Power-up:** pale green cracks, zoom 6, crack 1.1. He meditates through the charge and only grunts at full power (stage 3).
- **Forms:** his Full Power is the weighted cape and turban hitting the ground. `PiccoloWeightsOff` ("WEIGHTS OFF") is a short, pale-green, cracked-ground cinematic. Pending a preset (see below).
- **Signature:** Special Beam Cannon (`PiccoloSBCVFX`, wrapping the shared `SpecialBeamCannonVFX`). Two fingers at the brow, then a straight core with a beam coiled around it. The charge is cut from 2.0 s to 1.3 s so it lands with the server's hit; it is still the longest charge on the team. Camera zoom 9 and shake 0.25: tight and precise, not explosive.
- **Kit move:** Light Grenade (ray, 20 dmg, 25 ki, 10 s, `LightGrenadeVFX`). Both palms gather a yellow sphere, which flies straight into a wide yellow blast. Camera zoom 6, shake 0.45.
- **Heavy:** a lunging full-reach straight, a pale green ring and a short crack.
- **Clips:** Piccolo set. Arms folded at rest, a high roundhouse finisher, a lunging straight for the heavy, and the brow-to-point Special Beam Cannon on the beam slot.

### Android 17 (`u7_android_17`, Android)
- **Identity:** the park ranger who won the Tournament of Power. Easygoing, sharp, with nothing to prove.
- **Power-up (the Android take):** androids have no ki to gather, so there is no build-up drama: a low teal hum, zoom 3, tiny cracks (0.6), never a scream (stage 4).
- **Signature:** the barrier trap (`BarrierTrapVFX`), from his Tournament of Power tricks with the Android Barrier. A teal shot lands, a small barrier snaps shut around the target, then bursts. Camera zoom 5.
- **Barrier (race power-up):** `AndroidBarrierVFX` draws his bluish-green hex dome, wider and denser than 18's, for the server's duration.
- **Kit move:** Barrier Punch (melee, 15 dmg, 15 ki, 9 s, `BarrierPunchVFX`). A fist sheathed in barrier that pops on contact. Camera zoom 4, shake 0.4.
- **Heavy:** a compact straight with a barrier shell flaring at the hit, no crack.
- **Clips:** Android17 set. Hip cocked, arms loose. A flat push-kick finisher, and a lazy open palm on the beam slot.

### Android 18 (`u7_android_18`, Android)
- **Identity:** composed, efficient, unimpressed. The best close-range fighter of the pair.
- **Power-up:** the same silent hum as her brother, but pink. Zoom 3.5, crack 0.55, never screams.
- **Signature:** Power Blitz (`PowerBlitzVFX`). The hand drawn back charges a swirling pink-and-blue sphere, then a narrow beam is thrown from that hand. It is the fastest beam on the team (0.6 s charge). Camera zoom 5.
- **Barrier (race power-up):** a tighter pale-blue dome.
- **Kit move:** Infinity Bullet (ray, 16 dmg, 15 ki, 9 s, parryable, `InfinityBulletVFX`). Ten pink bolts in a stream, cheap because she never runs out. Camera zoom 3.
- **Heavy:** a clean rising knee with a pink double ring and an afterimage.
- **Clips:** Android18 set. Hand on hip, a spinning heel-kick finisher, a rising-knee heavy, and the hip-to-palm throw on the beam slot.

### Krillin (`u7_krillin`, Earthling)
- **Identity:** the bravest Earthling. Outmatched in power, so he fights smart, and he gives everything every time.
- **Power-up:** warm gold, zoom 5, crack 0.8. He shouts from stage 2.
- **Signature:** Destructo Disc (`KrillinDiscVFX`, wrapping `DestructoDiscVFX` with Krillin's golden ki instead of Frieza's pink, slightly larger and steered). Camera zoom 7.
- **Solar Flare:** a warm-gold flash, mid-sized.
- **Kit move:** Scattering Bullet (ray, 14 dmg, 20 ki, 11 s, `ScatterBulletVFX`). One sphere lobbed over the target bursts into a ring of bolts that rain down around it. Camera zoom 5.
- **Heavy:** small and quick, a gold ring with an afterimage.
- **Clips:** Krillin set. A low Turtle School guard with a fast bounce, a jumping-elbow finisher and a two-palm shove heavy. The beam slot is the disc raised overhead, then a sidearm throw.

### Tien (`u7_tien`, Earthling)
- **Identity:** discipline and raw strength. A Crane School fighter who chose his own path.
- **Power-up:** a silent build that cracks the ground hardest on the team (1.4). Zoom 7, one shout at stage 3.
- **Signature:** Tri-Beam (`TriBeamVFX`). The hands form a triangle, and a wide pale-gold pressure beam leaves a crater of rings and a big crack instead of a fireball. Camera zoom 9, shake 0.5.
- **Solar Flare:** he invented it, so his flash is the widest and whitest and charges fastest.
- **Kit move:** Neo Tri-Beam (ray, 22 dmg, 35 ki, 14 s, `NeoTriBeamVFX`). Three Tri-Beams in a row, each a little dimmer. The life-force cost waits on the server (below).
- **Heavy:** a driving front kick, a gold double ring and the biggest Heavy crack.
- **Clips:** Tien set. Crane stance with both arms raised like wings, a knife-hand chop finisher and a chambered front-kick heavy. The beam slot is the triangle in front of the eyes in a wide braced stance.

### Master Roshi (`u7_master_roshi`, Earthling)
- **Identity:** the old hermit who invented the Kamehameha. A joke until he isn't.
- **Power-up:** a lazy start that turns serious late. Pale blue, the biggest zoom on the team (8) as the muscles arrive, crack 1.25, scream at stage 3.
- **Forms:** Max Power (`RoshiMaxPower`, "MAX POWER"): blue with lightning and cracks. Pending a preset.
- **Signature:** MAX Power Kamehameha (`MaxKamehamehaVFX`). A ring blows off his feet as he bulks, then the widest, heaviest blue wave on the team. Camera zoom 11, shake 0.55.
- **Solar Flare:** the smallest flash of the three Earthlings.
- **Kit move:** none. His real ToP technique, the Evil Containment Wave, needs a server mechanic (below).
- **Heavy:** a planted double palm, a pale-blue ring and a gust.
- **Clips:** Roshi set. Stooped with hands clasped behind the back, a fast palm finisher out of that posture and a double-palm heavy. The beam slot is the deepest Kamehameha crouch.

### Shin (`u7_shin`, Kaioshin)
- **Identity:** the Supreme Kai of Universe 7. Young, gentle, divine, not a front-line brawler.
- **Power-up:** lavender, zoom 3, barely any cracks (0.5), never screams.
- **Signature:** Energy's Last (`EnergysLastVFX`). Both hands forward charge a purple sphere, released as a clean violet wave with no spiral. Camera zoom 6.
- **Kai Kai (race power-up):** `KaiKaiVFX`. No fingers to the brow: a raised hand, a soft lavender column, and the same column where he lands. The flicker comes from `InstantTransmissionVFX`.
- **Kit move:** Kiai eye blast (ray, 10 dmg, 70 kb, 10 s, not parryable, `KiaiEyeBlastVFX`). A brief flare at the eyes and near-invisible rings of moving air. Little damage, big shove.
- **Heavy:** a two-palm shove, a lavender ripple and never a crack.
- **Clips:** Shin set. Upright with hands joined at the waist (the calmest idle on the team), an open-palm finisher and a two-palm heavy. The beam slot is both palms forward.

## Needs server work

For the combat/VFX session. None of these files were edited here.

1. **Kit ki blasts are never drawn.** `VFXRouter` draws every `KiBlast` with the shared projectile and returns before it asks the kit. It should ask `Kits.signature(id, "KiBlast")` first (and `Kits.camera`). `EarthKiBlastVFX` is ready with a ki colour per fighter. This is the same item as the Saiyan kit's list.
2. **Kit moves have no key.** `LightGrenade`, `BarrierPunch`, `InfinityBullet`, `ScatterBullet`, `NeoTriBeam` and `KiaiEyeBlast` merge into `Config.MOVES` and validate server-side (champion-gated), but `CombatInput` binds no key to them. They need a kit-move key and HUD cooldown that reads the active character's kit move, plus a pose: FightAnimator has no clip for an unknown move id. A suggested rule: play the set's clip named after the move id, else `Kamehameha_Fire` for rays and `Heavy` for melee.
3. **Two forms have no preset.** Piccolo's and Roshi's only form is `FullPower`, and `Config.vfxFor` returns nil for it. Add `Config.FORM_VFX_OVERRIDES.u7_piccolo = { FullPower = "PiccoloWeightsOff" }` and `u7_master_roshi = { FullPower = "RoshiMaxPower" }`. The kit styles are ready, and the test allows them as pending.
4. **Missing aura entries, and androids with no aura.** `VFXCommon.AURAS` lacks a Namekian green, a Kaioshin lavender and a Roshi blue, so their charge and cinematic use the white Default aura. Androids have no ki aura at all in canon: GameFeel could accept `powerUp.aura = false` and skip the flame emitter, keeping only the kit's cracks and camera. The kit already never screams and barely cracks for them.
5. **Shared effects missing from the Rojo project.** `SolarFlareVFX`, `KaiokenVFX` and `HakaiVFX` are not in `team/default.project.json`. A Rojo build has no Kaioken or Hakai effect, and any Solar Flare outside this kit has none either, unless the place file carries them. `TaiyokenVFX` is self-contained for this reason.
6. **`SolarFlareVFX` blinds the wrong people.** Its screen blind hits every client within 75 studs, the caster included, with no facing or line-of-sight check, for 2.2 s. The server (`RacePowerUps`) blinds fighters within 25 studs who face the flash, for 1.5 s, and sets `BlindUntil`. `TaiyokenVFX` shows the white-out from `BlindUntil` only. The shared module should do the same, or be retired.
7. **`Android17BarrierVFX` has no `Play`.** The router calls `Play`, so the Barrier and the angels' `AngelicBarrier` drew nothing. `AndroidBarrierVFX` fixes it for the androids only. The barrier's `Hit` ripple is also never called: the router keeps no handle, and no blocked-hit event reaches it.
8. **One signature move for very different techniques.** Every fighter's key-2 slot is the same server `Kamehameha` move (28 dmg, beam struggle). The techniques ask for different rules:
   - The Special Beam Cannon pierces: it should hit everyone on the line and take a longer charge.
   - The Destructo Disc is a homing cutter: a travelling projectile, high guard damage, no beam struggle.
   - The Tri-Beam presses down: a wide area at the target.
   - Power Blitz should be quick, with low recovery.
   - Roshi's MAX Power Kamehameha should be heavier, with a longer recovery.
   - Barrier trap and Energy's Last are fine as beams.

   This needs per-champion overrides for the signature move, e.g. `Kits` `signatureMove = { ... }` merged over `Config.MOVES.Kamehameha` for that champion.
9. **Neo Tri-Beam's cost.** The wiki is clear that it drains Tien's life force. Suggested: about 5% max HP per use, server-side, never lethal.
10. **Kai Kai needs its origin.** The server moves Shin before it broadcasts `KaiKai` with only the destination. The vanish column may draw at the landing point if the position replicates first. Send `{from, dest}`. Goku's Instant Transmission has the same gap.
11. **Techniques that need new server kinds** (not attempted, since the kit may only use existing kinds):
    - Piccolo's Hellzone Grenade: spheres placed around the target that converge on a delay.
    - Tien's Multi-Form: clones.
    - Roshi's Evil Containment Wave: a seal or ring-out with a heavy self-cost.
    - Shin's telekinetic hold.
    - Android 17's Tournament of Power barrier sacrifice: a once-per-round shield over allies.
    - The twins' Super Electric Strike: a team combo between 17 and 18.
12. **Shared clip builder.** This kit carries its own `ClipBuilder.lua`, the same as `Kits/Saiyan/ClipBuilder.lua` on the Saiyan branch. After both merge, one copy could move to `Kits/ClipBuilder.lua`.

## Verify in Studio

Nothing here has been seen in Studio. Angles, colours and timings are design values.

- Each clip set on its rig: Piccolo's folded arms and brow pose, the androids' relaxed stances, Krillin's bounce, Tien's crane wings and triangle, Roshi's stoop and deep crouch, Shin's upright idle. Watch for joint-axis surprises, especially the `Root` offsets and the wrist angles of the palm poses.
- Each signature fires from the right place and reads as its own colour and size: the brow for the SBC, the right hand for Power Blitz, overhead for the disc, the triangle for the Tri-Beam.
- `PiccoloSBCVFX`'s 1.3 s charge against the server's hit timing. Compare with Goku's Kamehameha.
- `AndroidBarrierVFX` for 17 and 18: it appears for the full 2 s and fades out, and the colours differ.
- Solar Flare: a blinded onlooker gets the white-out, the caster and anyone not facing the flash do not, and Tien's flash is visibly larger than Roshi's.
- `KaiKaiVFX`: one column at the start point and one at the landing point (see server item 10).
- `EarthHeavyVFX` on a Heavy hit for each fighter: crack size (Tien biggest, Shin none), the shell on 17, the afterimages on 18 and Krillin.
- Power-up charge for each fighter: scream stages (Krillin at 2; the androids and Shin never), crack sizes and colours.
- Kit-move effects once server item 2 gives them a key.
