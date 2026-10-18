--!nonstrict
-- Kit: tyrants and shapeshifters. Four fighters who share a cold, cruel streak and nothing else:
-- Frieza never raises his voice and kills with one finger; Frost plays the gentleman, can't hold his own power and
-- hides a poison needle; Moro is an old sorcerer who takes your energy instead of beating you for it; Maji Kayo is a
-- shining blue jelly that stretches, cuts and swallows. Design notes per fighter: KITS.md next to this file.
-- Effects named here live in ReplicatedStorage.VFX or in Kits/FriezaMajin/VFX; clip sets in Kits/FriezaMajin/Poses.
-- Fields are documented in Kits/init.lua. Form styles are keyed by TransformCinematic preset (Config.vfxFor).
-- powerUp.aura is only set for single-form fighters (a kit aura replaces the form aura while charging).
-- screamStage 4 = never screams. Colours fall back to plain values when Color3 is missing (plain-Luau data check).
local function rgb(r: number, g: number, b: number): Color3
	return if Color3 then Color3.fromRGB(r, g, b) else ({ r, g, b } :: any)
end
local function hex(h: string): Color3
	return if Color3 then Color3.fromHex(h) else (h :: any)
end

-- a TransformCinematic style: title card, colours, duration, camera orbit speed, beat flags
-- (lightning, crack, calmRings, wisps, slowmo, dark) and an optional cocoon shell colour
local function form(title: string, color: string, flash: string, dur: number, orbit: number, beats: any?): any
	local st = { title = title, color = hex(color), flash = hex(flash), dur = dur, orbit = orbit }
	for k, v in beats or {} do
		st[k] = if k == "shell" then hex(v) else v
	end
	return st
end

return {
	race = "FriezaMajin",
	defaults = {
		signatures = { Heavy = "FriezaMajinHeavyVFX", KiBlast = "FriezaMajinKiBlastVFX" },
		cameras = { Kamehameha = { zoom = 6, shake = 0.3 }, Heavy = { zoom = 3, shake = 0.25 } },
	},
	characters = {
		-- Frieza: the emperor. Composure is the threat: he never screams to power up, the camera barely moves on
		-- his Death Beam (three needles, one finger), and his tail lash is a clean cut, not a crater. Gold is
		-- regal and calm; Black arrives in the dark, and the world seems to stop.
		-- Kit moves: Death Saucer (homing disc, splits in Golden), Nova Strike (Black Nova in Black Frieza).
		u7_frieza = {
			clips = "Frieza",
			signatures = {
				Kamehameha = "FriezaDeathBeamVFX",
				DeathSaucer = "DeathSaucerVFX",
				NovaStrike = "FriezaNovaVFX",
			},
			powerUp = { color = rgb(205, 140, 255), zoom = 4, screamStage = 4, crack = 1.15 },
			cameras = {
				Kamehameha = { zoom = 5, shake = 0.2 },
				Heavy = { zoom = 2, shake = 0.2 },
				DeathSaucer = { zoom = 4, shake = 0.15 },
				NovaStrike = { zoom = 9, shake = 0.6 },
			},
			forms = {
				FriezaFullPower = form("100% FULL POWER", "C77DFF", "FFB0F0", 2.4, 1, { crack = true }),
				GoldenFrieza = form("GOLDEN FRIEZA", "FFC400", "FFF0A0", 2.8, 0.8,
					{ calmRings = true, shell = "FFC400" }),
				FriezaBlack = form("BLACK FRIEZA", "96286E", "FF3C78", 3.2, 0.6,
					{ dark = true, slowmo = true, shell = "140A19" }),
			},
			moves = {
				-- a spinning disc that bends toward the target: cuts through guard, can't be parried
				DeathSaucer = {
					kind = "ray",
					champion = "u7_frieza",
					cooldown = 9,
					range = 140,
					width = 3,
					damage = 16,
					ki = 20,
					recovery = 0.35,
					kb = 30,
					guardDamage = 70,
					hitstun = 0.45,
					parryable = false,
					arenaRadius = 4,
					arenaPower = 40,
				},
				-- wrapped in energy, shoulder first: the tackle that pushed Jiren out of the ring
				NovaStrike = {
					kind = "melee",
					champion = "u7_frieza",
					cooldown = 11,
					range = 14,
					damage = 20,
					ki = 25,
					recovery = 0.5,
					kb = 75,
					guardDamage = 50,
					hitstun = 0.5,
					parryable = true,
				},
			},
		},
		-- Frost: Universe 6's Frieza, the "hero" who starts the wars he ends. Polite at rest (hands behind his back),
		-- but his final form is more than he can hold: he screams from stage 2 and breaks more ground than Frieza.
		-- Chaos Beam is wider and colder than the Death Beam and sprays stray shots; his Heavy is the hidden poison
		-- needle in his wrist. Kit move: Dirty Burst (rush in, a blast through the chest).
		u6_frost = {
			clips = "Frost",
			signatures = {
				Kamehameha = "ChaosBeamVFX",
				DirtyBurst = "DirtyBurstVFX",
			},
			powerUp = { aura = "FriezaFullPower", color = rgb(120, 170, 255), zoom = 6, screamStage = 2, crack = 1.3 },
			cameras = {
				Kamehameha = { zoom = 6, shake = 0.3 },
				Heavy = { zoom = 3, shake = 0.15 },
				DirtyBurst = { zoom = 7, shake = 0.45 },
			},
			forms = {
				-- his true final form: a power he once could not control. Preset pending (KITS.md).
				FrostFinal = form("FINAL FORM", "5A82FF", "D6E2FF", 2.4, 1.2, { lightning = true, crack = true }),
			},
			moves = {
				-- point-blank: rush in, then one blast straight through the target
				DirtyBurst = {
					kind = "melee",
					champion = "u6_frost",
					cooldown = 10,
					range = 8,
					damage = 22,
					ki = 20,
					recovery = 0.45,
					kb = 65,
					guardDamage = 30,
					hitstun = 0.5,
					parryable = true,
				},
			},
		},
		-- Moro: the Planet-Eater, an ancient sorcerer who thinks training is for idiots. He does not power up so much
		-- as feed: purple aura (his part-restored colour), no scream, small cracks. His beam leaves his mouth; his
		-- Heavy drains through the palm; Absorb shows the life leaving the target. Awakened, the light dims and life
		-- energy streams into him. Kit move: Psycho Javelin (a tree trunk thrown by telekinesis).
		u7_moro = {
			clips = "Moro",
			signatures = {
				Kamehameha = "MoroMouthWaveVFX",
				Absorb = "MoroAbsorbTouchVFX",
				PsychoJavelin = "PsychoJavelinVFX",
			},
			powerUp = { aura = "ToppoGoD", color = rgb(170, 90, 255), zoom = 3, screamStage = 4, crack = 0.6 },
			cameras = {
				Kamehameha = { zoom = 8, shake = 0.5 },
				Heavy = { zoom = 2, shake = 0.1 },
				Absorb = { zoom = -4, shake = 0.05 },
				PsychoJavelin = { zoom = 5, shake = 0.35 },
			},
			forms = {
				MoroAwakened = form("AWAKENED MORO", "78E65A", "FF9A3C", 3.0, 0.7,
					{ dark = true, wisps = true, crack = true }),
			},
			moves = {
				-- a skewer of wood levitated, aimed, then launched
				PsychoJavelin = {
					kind = "ray",
					champion = "u7_moro",
					cooldown = 10,
					range = 160,
					width = 4,
					damage = 18,
					ki = 25,
					recovery = 0.5,
					kb = 45,
					guardDamage = 45,
					hitstun = 0.5,
					parryable = true,
					arenaRadius = 6,
					arenaPower = 50,
				},
			},
		},
		-- Maji Kayo: a protean blue jelly from Universe 3, cunning and cruel. No ki beam at all: his "beam" is the
		-- Mystic Attack, an arm stretched across the arena; his Heavy is the Giant Fist; his blasts are globs. He
		-- swells into his muscular form rather than powering up, so the camera pulls out and the ground barely cracks.
		-- Kit moves: Scissor Hands (fast cut), Submission (engulf and hold).
		u3_maji_kayo = {
			clips = "MajiKayo",
			signatures = {
				Kamehameha = "MysticAttackVFX",
				ScissorHands = "ScissorHandsVFX",
				Submission = "SubmissionVFX",
			},
			powerUp = { color = rgb(80, 190, 255), zoom = 8, screamStage = 2, crack = 0.5 },
			cameras = {
				Kamehameha = { zoom = 4, shake = 0.2 },
				Heavy = { zoom = 6, shake = 0.55 },
				ScissorHands = { zoom = 2, shake = 0.2 },
				Submission = { zoom = -3, shake = 0.1 },
			},
			forms = {
				-- the jelly closes into a shell and re-forms bigger. Preset pending (KITS.md).
				KayoMuscular = form("MUSCULAR FORM", "3AA8FF", "BFE8FF", 2.2, 1, { shell = "3AA8FF" }),
			},
			moves = {
				-- hands become blades: quick, cheap, chips guard
				ScissorHands = {
					kind = "melee",
					champion = "u3_maji_kayo",
					cooldown = 5,
					range = 8,
					damage = 9,
					ki = 10,
					recovery = 0.25,
					kb = 10,
					guardDamage = 25,
					hitstun = 0.35,
					parryable = true,
				},
				-- the body turns semi-liquid and wraps the target: little damage, a long hold
				Submission = {
					kind = "melee",
					champion = "u3_maji_kayo",
					cooldown = 14,
					range = 9,
					damage = 6,
					ki = 20,
					recovery = 0.6,
					kb = 0,
					guardDamage = 60,
					hitstun = 1.2,
					parryable = true,
				},
			},
		},
	},
}
