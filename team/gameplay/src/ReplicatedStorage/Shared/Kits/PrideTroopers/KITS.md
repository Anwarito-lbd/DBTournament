# Universe 11 kits: the Pride Troopers

Design sheet for `Kits/PrideTroopers` (race `"PrideTroopers"`): Jiren and the eight troopers on the roster in
`Config.ROSTER[11]`. The kit format and how the game reads it are in `Kits/init.lua`; `Kits/Saiyan` is the reference.
Technique names come from each character's page on the Dragon Ball wiki (dragonball.fandom.com, read 2026-10-17);
no anime media or dialogue is used.

## What the kit gives every trooper (race defaults)

| Part | Default |
|---|---|
| Signature shot (`Kamehameha` slot) | `JusticeBlastVFX`: a compact red-and-white sphere, quick charge |
| Justice Pose (race power-up, Lv15) | `JusticePoseVFX`: the fighter's own pose clip, a red flash and light pillar, then a ground ring out to the 30-stud buff radius |
| Power-up | justice red, zoom 5, screams at stage 3, crack 1.0 |
| Cameras | signature zoom 6 / shake 0.3; Justice Pose zoom 4 / shake 0.15 |
| Clips | `Troopers` set; anything a fighter's set lacks falls back to it, then to the shared neutral clips |

`powerUp.screamStage = 4` means the fighter never screams (stages run 1-3).
Each fighter's colours and effect shapes live in the kit's own `look` field, read by the effects in `VFX/` via
`kit.lookFor(id, field)`, so identity stays in `init.lua`.

## Per character

### Jiren (`u11_jiren`)
Wiki: Power Impact (red-orange fireball that expands on impact), Grand Charge (shoulder charge in a purple barrier),
Meditation, Power Up with remarkable control, Full Power.
- **Feel:** silent and absolute. Never screams; the red full-power aura (`JirenFullPower`) shows from stage 1; the
  biggest cracks in the race (1.6); the heaviest camera.
- **Signature:** Power Impact (`PowerImpactVFX`), camera zoom 10 / shake 0.6.
- **Kit move:** `GrandCharge` (melee, 14 studs, guard break), effect `NovaStrikeVFX` (purple energy sphere rush).
- **Form:** `JirenFullPower` cinematic, "JIREN • FULL POWER": no lightning, no roar, a slow heavy reveal (2.8 s, orbit 0.6).
- **Clips (`Jiren`):** folded-arm idle; cross-legged meditation when hovering (`FlyIdle`); a power-up that only braces;
  Power Impact pushed from one open hand while the other arm stays folded; a folded-arm stare as his Justice Pose.

### Toppo (`u11_toppo`)
Wiki: Justice Flash (rapid ki blasts from his fingertips), Destructive Flare (its Destroyer-form version), Energy of
Destruction, Hakai, Justice Punch, his Justice pose.
- **Feel:** the loudest voice of justice. Roars from stage 2, warm gold power-up, crack 1.3.
- **Signature:** `JusticeFlashVFX`: five alternating finger shots in base form; in his `FullPower` (Destroyer) form the
  same button throws a dark violet Destructive Flare sphere.
- **Form:** `ToppoGoD` cinematic, "TOPPO • GOD OF DESTRUCTION": the world darkens, violet, 3.0 s.
- **Clips (`Toppo`):** chest-out roar for the power-up; two-finger aim with recoil on each Justice Flash shot; a Justice
  Pose with one fist thrown to the sky.

### Dyspo (`u11_dyspo`)
Wiki: Light Bullet (bursts thousands of times faster than his normal speed), Cannon Maximum, Justice Kick, Circle Flash,
Afterimage Technique.
- **Feel:** speed over power. Never screams; small power-up (zoom 3, crack 0.7); the lightest cameras in the race.
- **Signature:** quick violet Cannon Maximum (`JusticeWaveVFX`, 0.5 s charge).
- **Kit move:** `LightBullet` (melee, 16 studs, low recovery), effect `LightBulletVFX` (five fast violet afterimage strikes).
- **Clips (`Dyspo`):** a near-flat dash with both arms swept back; a sprinter's crouch as his Justice Pose.

### Kahseral (`u11_kahseral`)
Wiki: the Pride Troopers' leader; Cannon Maximum, Double Cannon Maximum with Dyspo, Justice Saber.
- **Feel:** the steady leader. Golden power-up, screams at full power.
- **Signature:** a golden Cannon Maximum (`JusticeWaveVFX`, wide beam with spiral), camera zoom 8.
- **Clips (`Kahseral`):** Cannon Maximum braced with the second hand on the wrist; a Justice Pose pointing his squad forward.

### Cocotte (`u11_cocotte`)
Wiki: Cocotte Zone (a purple dome that traps enemies in a separate dimension, also used for defence), Ki Bomb (a swirling
ki attack).
- **Feel:** calm and spatial. Never screams; violet power-up; small cracks.
- **Signature:** a violet Ki Bomb (`JusticeBlastVFX` with her `blast` look).
- **Justice Pose:** `CocotteZoneVFX`: she raises Cocotte Zone and strikes her pose (wrists crossed, hands out) inside it.
- **Kit move:** `CocotteZone` (server `barrier` kind); the server's `Barrier` effect becomes her purple dome.

### Kunshi (`u11_kunshi`)
Wiki (as K'nsi): Threaded Energy (solid threads of energy), his Justice pose.
- **Feel:** composed and technical. Never screams; cyan power-up.
- **Signature:** a thin, fast thread of cyan energy (`JusticeWaveVFX` with a 0.7-wide finger beam).
- **Clips (`Kunshi`):** a one-finger shot; a high-guard Justice Pose on one leg.

### Vuon (`u11_vuon`)
Wiki (as Vewon): Dynamite Blaster (energy wave), Justice Whip (an energy lasso that binds), his Justice pose.
- **Feel:** a giant who shouts from stage 1 and cracks the floor wide (1.5).
- **Signature:** a heavy orange Dynamite Blaster (`JusticeWaveVFX`, width 7).
- **Kit move:** `JusticeWhip` (melee, 20 studs, 1.0 s hitstun, little damage), effect `JusticeWhipVFX` (orange lasso line).
- **Clips (`Vuon`):** a double-arm flex as his Justice Pose.

### Zoiray (`u11_zoiray`)
Wiki (as Zoire): Justice Spin (spins into a whirlwind), Double Pride Spin with Tupper, his Justice pose.
- **Feel:** a whirlwind fighter; roars at stage 2.
- **Kit move:** `JusticeSpin` (melee, 9 studs), effect `JusticeSpinVFX` (pale-red rings whipping around him for 0.8 s).
- **Clips (`Zoiray`):** a Justice Pose wound up for the spin, torso twisted.

### Tupper (`u11_tupper`)
Wiki: Self Petrification, Self Ignition while spinning, Weight Control, Spinning, Bear Hug, Double Pride Spin with Zoiray.
- **Feel:** the heaviest trooper. Stone-grey power-up, crack 1.45 (second only to Jiren).
- **Kit move:** `BurningSpin` (melee, 10 studs), effect `JusticeSpinVFX` with a stone wheel, burning core and thrown debris.
- **Clips (`Tupper`):** a deep wide squat with hands on knees as his Justice Pose.

## Needs server work (combat session)

1. **Kit moves have no input yet.** `GrandCharge`, `LightBullet`, `CocotteZone`, `JusticeWhip`, `JusticeSpin` and
   `BurningSpin` merge into `Config.MOVES` and pass the server's champion gate, but `CombatInput.KEYMOVES` is a fixed
   table, so no key or hotbar slot sends them. They need a binding (a per-character skill slot would fit every kit).
2. **Kit move numbers are first-pass values.** Cooldowns, damage, knockback and hitstun in `init.lua` need a balance pass.
3. **No body clip for kit melee moves.** The server broadcasts the move id, so the effects play, but `AnimeStyle` and
   `CombatInput` only map the core kinds to clips. A `GrandCharge` or `JusticeSpin` currently has no body motion.
4. **Light Bullet does not move Dyspo.** The `melee` kind hits at range without moving the attacker; a real burst needs
   server movement like the Dash.
5. **Justice Whip only approximates a bind** with a 1.0 s hitstun; a real hold or pull needs a server kind.
6. **Cocotte Zone uses the generic barrier.** The `barrier` kind always lasts `RACE_POWERUPS.Barrier.duration` (2 s) and
   fires the `Barrier` effect. Trapping a target inside the zone (its real use) needs its own kind.
7. **Toppo's Hakai is missing.** It should exist only in his Destroyer form; moves cannot be gated by form today.
8. **More wiki techniques left out for want of a server kind:** Jiren's Kiai / Invisible Eye Blast and Overheating
   Blast (a no-self-KO `selfblast`), Dyspo's Circle Flash trap, Tupper's petrified guard and Weight Control, and the team
   attack United Justice Stream (could ride on the team-combo system).
9. **Pre-existing, found while building this:** `VFXRouter` routes `Barrier` and `AngelicBarrier` to
   `Android17BarrierVFX`, which has only `Start`, not `Play`, so those barriers show nothing for anyone without a kit
   override.
10. **Race naming:** `Kits.race()` returns `"PrideTroopers"` for all nine; `Races.raceOf()` says `"PrideTrooper"` for the
    troopers and `"JirenType"` for Jiren. Use `Races` for gameplay and treat the kit race as a label.

## Needs checking in Studio

- Each fighter's signature shot plays the right effect and colour, and Toppo's switches to the violet sphere in his
  Destroyer form (it reads the player's `Form` attribute as `"FullPower"`).
- The Justice Pose: each fighter strikes their own pose for the 1 s lock, the ring reaches 30 studs, and Cocotte raises
  her dome instead.
- The Jiren Full Power and Toppo God of Destruction cinematics.
- Power-up scream stages, aura (Jiren's red aura from stage 1), crack sizes and camera zoom per fighter.
- Every clip's joint angles: they are hand-set design values, likely to need tuning on the real rigs. Watch Jiren's
  meditation legs, Vuon's flex and Tupper's squat.
- Kit move effects, once the moves are bound to an input.

## Tests

`team/gameplay/tests/kit_pridetroopers_tests.luau` (plain Luau, not in `run.sh`):
`cd team/gameplay/tests && luau kit_pridetroopers_tests.luau`.
