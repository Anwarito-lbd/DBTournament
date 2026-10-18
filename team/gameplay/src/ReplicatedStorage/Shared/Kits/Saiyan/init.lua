--!nonstrict
-- Kit: Saiyans (the reference kit for Shared/Kits). Ten fighters of one race, each with their own temper:
-- Goku powers up calm and then explodes; Vegeta roars early with harder cameras; Gohan's anger cracks the ground
-- hardest; Trunks fights with a sword; Broly roars from the first breath; Cabba is Vegeta's disciplined student;
-- Caulifla is all speed and swagger; Kale is shy until she isn't; Kefla is both of them at once; Goku Black never
-- raises his voice. Design notes per fighter: KITS.md next to this file.
-- Effects named here live in ReplicatedStorage.VFX or in Kits/Saiyan/VFX; clip sets in the shared Poses folder or
-- Kits/Saiyan/Poses. Fields are documented in Kits/init.lua. Form styles are keyed by TransformCinematic preset
-- (Config.vfxFor) and replace the shared STYLE entry for that fighter. powerUp.aura is set only for fighters with
-- a single form, because a kit aura overrides the form's aura while charging. screamStage 4 = never screams.
-- Colours are Color3 in Roblox; the plain-Luau data check (tests/kit_saiyan_tests.luau) has no Color3, so there
-- they stay plain values ({r, g, b} or the hex string), like Config.lua's guard for `script`.
local function rgb(r: number, g: number, b: number): Color3
	return if Color3 then Color3.fromRGB(r, g, b) else ({ r, g, b } :: any)
end
local function hex(h: string): Color3
	return if Color3 then Color3.fromHex(h) else (h :: any)
end

-- a TransformCinematic style: title card, colours, beat flags (lightning, crack, calmRings, wisps, slowmo, dark,
-- shell), camera orbit speed and duration
local function form(title: string, color: string, flash: string, dur: number, orbit: number, beats: any?): any
	local st = { title = title, color = hex(color), flash = hex(flash), dur = dur, orbit = orbit }
	for k, v in beats or {} do
		st[k] = if k == "shell" then hex(v) else v
	end
	return st
end

return {
	race = "Saiyan",
	defaults = {
		powerUp = { color = rgb(255, 226, 120), zoom = 5, screamStage = 3, crack = 1.0 },
		signatures = { Heavy = "SaiyanHeavyVFX", KiBlast = "SaiyanKiBlastVFX" },
		cameras = { Kamehameha = { zoom = 6, shake = 0.3 }, Heavy = { zoom = 3, shake = 0.3 } },
	},
	characters = {
		-- Goku: the joy of a good fight. Calm focus, then the explosion; blue-sky Kamehameha; his own forms build
		-- slow and bright, the divine ones serene. Kit move: Dragon Fist.
		u7_goku = {
			clips = "Goku",
			signatures = { Kamehameha = "KamehamehaVFX", DragonFist = "DragonFistVFX" },
			powerUp = { color = rgb(255, 236, 150), zoom = 5, screamStage = 3, crack = 1.0 },
			cameras = {
				Kamehameha = { zoom = 8, shake = 0.35 },
				Heavy = { zoom = 3, shake = 0.3 },
				DragonFist = { zoom = 6, shake = 0.5 },
			},
			forms = {
				SSJ = form("SUPER SAIYAN", "FFD84A", "FFF6C0", 2.6, 1, { lightning = true, crack = true }),
				SSJ2 = form("SUPER SAIYAN 2", "FFE15A", "FFF6C0", 2.4, 1, { lightning = true, crack = true }),
				SSJ3 = form("SUPER SAIYAN 3", "FFC828", "FFF6C0", 3.2, 1.3, { lightning = true, crack = true }),
				SSG = form("SUPER SAIYAN GOD", "FF4A3A", "FFE0C8", 2.6, 0.6, { calmRings = true, wisps = true }),
				SSB = form("SUPER SAIYAN BLUE", "3AD7FF", "E0FBFF", 2.4, 0.7, { calmRings = true }),
				SSJ4 = form("SUPER SAIYAN 4", "C8282D", "FFD84A", 2.8, 1.1, { lightning = true, crack = true }),
				UISign = form("ULTRA INSTINCT -SIGN-", "C8D2FF", "FFFFFF", 2.8, 0.5,
					{ wisps = true, slowmo = true, calmRings = true }),
				MUI = form("ULTRA INSTINCT", "E8EEFF", "FFFFFF", 3.0, 0.5, { wisps = true, slowmo = true }),
			},
			moves = {
				-- one fist driven through the target; guard-heavy, no beam struggle
				DragonFist = {
					kind = "melee",
					champion = "u7_goku",
					cooldown = 12,
					range = 10,
					damage = 18,
					ki = 25,
					recovery = 0.5,
					kb = 60,
					guardDamage = 60,
					hitstun = 0.6,
					parryable = true,
				},
			},
		},
		-- Vegeta: pride. Roars from stage 2, blue-white aura, bigger cracks, the hardest beam camera of the
		-- U7 pair; every form arrives with lightning and broken ground. Kit move: Big Bang Attack.
		u7_vegeta = {
			clips = "Vegeta",
			signatures = { Kamehameha = "FinalFlashVFX", BigBangAttack = "BigBangAttackVFX" },
			powerUp = { color = rgb(176, 200, 255), zoom = 7, screamStage = 2, crack = 1.35 },
			cameras = {
				Kamehameha = { zoom = 10, shake = 0.5 },
				Heavy = { zoom = 4, shake = 0.45 },
				BigBangAttack = { zoom = 7, shake = 0.45 },
			},
			forms = {
				SSJ = form("SUPER SAIYAN", "FFE15A", "FFF6C0", 2.2, 1.2, { lightning = true, crack = true }),
				SSJ2 = form("SUPER SAIYAN 2", "FFE15A", "FFF6C0", 2.2, 1.2, { lightning = true, crack = true }),
				SSG = form("SUPER SAIYAN GOD", "FF4A3A", "FFE0C8", 2.4, 0.9, { crack = true }),
				SSB = form("SUPER SAIYAN BLUE", "3AD7FF", "E0FBFF", 2.4, 1, { lightning = true, crack = true }),
				SSJ4 = form("SUPER SAIYAN 4", "B4232D", "FFE15A", 2.6, 1.2, { lightning = true, crack = true }),
				SSBEvolved = form("SUPER SAIYAN BLUE EVOLVED", "2A55E8", "D8E2FF", 2.8, 1,
					{ lightning = true, crack = true, dark = true }),
				UltraEgo = form("ULTRA EGO", "9A4AFF", "FF78C8", 2.8, 1.1,
					{ lightning = true, crack = true, dark = true }),
			},
			moves = {
				-- one palm, one fast sphere, one big explosion
				BigBangAttack = {
					kind = "ray",
					champion = "u7_vegeta",
					cooldown = 9,
					range = 160,
					width = 6,
					damage = 18,
					ki = 25,
					recovery = 0.4,
					kb = 50,
					guardDamage = 40,
					hitstun = 0.4,
					parryable = false,
					arenaRadius = 10,
					arenaPower = 90,
				},
			},
		},
		-- Gohan: the scholar with the deepest well of power. A quiet build, then the ground breaks hardest of
		-- anyone at full charge; Piccolo's Masenko is his beam; Ultimate is calm, Beast is fury.
		u7_gohan = {
			clips = "Gohan",
			signatures = { Kamehameha = "MasenkoVFX" },
			powerUp = { color = rgb(255, 245, 220), zoom = 4, screamStage = 3, crack = 1.5 },
			cameras = { Kamehameha = { zoom = 7, shake = 0.35 }, Heavy = { zoom = 5, shake = 0.5 } },
			forms = {
				SSJ = form("SUPER SAIYAN", "FFD84A", "FFF6C0", 2.4, 1, { lightning = true, crack = true }),
				SSJ2 = form("SUPER SAIYAN 2", "FFE15A", "FFF6C0", 2.8, 0.9,
					{ lightning = true, crack = true, slowmo = true }),
				GohanUltimate = form("ULTIMATE GOHAN", "FFFFFF", "E8F0FF", 2.4, 0.6, { calmRings = true, crack = true }),
				BeastGohan = form("BEAST", "FF3C46", "FFFFFF", 3.0, 1.2, { lightning = true, crack = true, dark = true }),
			},
		},
		-- Future Trunks: a swordsman from a ruined timeline. Angry early (scream from stage 2) but tidy cracks;
		-- sword cuts for strikes, the Burning Attack as his signature.
		u7_trunks = {
			clips = "Trunks",
			signatures = { Kamehameha = "BurningAttackVFX" },
			powerUp = { color = rgb(255, 215, 110), zoom = 5, screamStage = 2, crack = 0.9 },
			cameras = { Kamehameha = { zoom = 6, shake = 0.3 }, Heavy = { zoom = 3, shake = 0.35 } },
			forms = {
				SSJ = form("SUPER SAIYAN", "FFC94A", "FFF6C0", 2.2, 1, { lightning = true, crack = true }),
				SSJ2 = form("SUPER SAIYAN 2", "FFD84A", "FFF6C0", 2.4, 1.1, { lightning = true, crack = true }),
			},
		},
		-- Broly: instinct and wrath. Roars from the first stage, red wrath aura over green ki, the biggest cracks
		-- and cameras in the race; the Gigantic Roar beam. Only form: FullPower (preset pending, see KITS.md).
		u7_broly = {
			clips = "Broly",
			signatures = { Kamehameha = "GiganticRoarVFX" },
			powerUp = { aura = "KaioKen", color = rgb(90, 255, 110), zoom = 9, screamStage = 1, crack = 1.8 },
			cameras = { Kamehameha = { zoom = 12, shake = 0.7 }, Heavy = { zoom = 7, shake = 0.8 } },
			forms = {
				BrolyFullPower = form("FULL POWER", "4AFF6E", "E6FFE6", 3.2, 1.4,
					{ lightning = true, crack = true, dark = true }),
			},
		},
		-- Cabba: Universe 6's earnest soldier and Vegeta's student. Vegeta's stance and a cooler Galick Cannon;
		-- a modest build with small cracks, a clean first awakening.
		u6_cabba = {
			clips = "Vegeta",
			signatures = { Kamehameha = "GalickCannonVFX" },
			powerUp = { color = rgb(200, 190, 255), zoom = 4, screamStage = 3, crack = 0.8 },
			cameras = { Kamehameha = { zoom = 6, shake = 0.25 }, Heavy = { zoom = 2, shake = 0.25 } },
			forms = {
				SSJ = form("SUPER SAIYAN", "FFD84A", "FFF6C0", 2.4, 0.8, { lightning = true }),
				SSJ2 = form("SUPER SAIYAN 2", "FFE15A", "FFF6C0", 2.4, 0.9, { lightning = true, crack = true }),
			},
		},
		-- Caulifla: gang boss, natural talent, no patience. Shouts from stage 2, fastest transformations in the
		-- kit, the Crush Cannon fired from the hip; pink ki on gold.
		u6_caulifla = {
			clips = "Caulifla",
			signatures = { Kamehameha = "CrushCannonVFX" },
			powerUp = { color = rgb(255, 170, 215), zoom = 6, screamStage = 2, crack = 1.0 },
			cameras = { Kamehameha = { zoom = 5, shake = 0.4 }, Heavy = { zoom = 3, shake = 0.4 } },
			forms = {
				CauliflaSSJ = form("SUPER SAIYAN", "FFD23C", "FFE6F2", 2.0, 1.3, { lightning = true, crack = true }),
				SSJ2 = form("SUPER SAIYAN 2", "FFE15A", "FFE6F2", 2.2, 1.3, { lightning = true, crack = true }),
			},
		},
		-- Kale: timid until something snaps. The build stays quiet and then erupts at full charge; Super Saiyan
		-- is controlled and calm, Berserk is green, dark and enormous; the Eraser Cannon sphere.
		u6_kale = {
			clips = "Kale",
			signatures = { Kamehameha = "EraserCannonVFX" },
			powerUp = { color = rgb(120, 255, 100), zoom = 8, screamStage = 3, crack = 1.7 },
			cameras = { Kamehameha = { zoom = 9, shake = 0.55 }, Heavy = { zoom = 6, shake = 0.65 } },
			forms = {
				SSJ = form("SUPER SAIYAN", "FFD84A", "FFF6C0", 2.4, 0.7, { calmRings = true }),
				KaleBerserk = form("BERSERK", "78FF5A", "E6FFC8", 3.0, 1.4, { lightning = true, crack = true, dark = true }),
			},
		},
		-- Kefla: Caulifla and Kale fused by Potara. Caulifla's swagger, Kale's weight: early shout, big cracks,
		-- the Gigantic Ray; the fusion reveal is a calm flash, her Super Saiyan 2 a storm.
		u6_kefla = {
			clips = "Kefla",
			signatures = { Kamehameha = "GiganticRayVFX" },
			powerUp = { color = rgb(200, 255, 80), zoom = 7, screamStage = 2, crack = 1.3 },
			cameras = { Kamehameha = { zoom = 9, shake = 0.5 }, Heavy = { zoom = 4, shake = 0.5 } },
			forms = {
				KeflaPotara = form("KEFLA", "C8FF3A", "FFFFC8", 3.0, 1, { calmRings = true, lightning = true }),
				SSJ = form("SUPER SAIYAN", "DCF050", "FFFFC8", 2.2, 1.2, { lightning = true, crack = true }),
				KeflaSSJ2 = form("SUPER SAIYAN 2", "C8FF3A", "FFFFC8", 2.6, 1.3, { lightning = true, crack = true }),
			},
		},
		-- Goku Black: a god in a stolen body. Never screams, barely cracks the ground, rose aura, slow cold
		-- cameras; the Black Kamehameha. Only form: FullPower (Rose preset pending, see KITS.md).
		u10_goku_black = {
			clips = "GokuBlack",
			signatures = { Kamehameha = "BlackKamehamehaVFX" },
			powerUp = { aura = "FriezaFullPower", color = rgb(255, 110, 190), zoom = 4, screamStage = 4, crack = 0.7 },
			cameras = { Kamehameha = { zoom = 7, shake = 0.3 }, Heavy = { zoom = 2, shake = 0.2 } },
			forms = {
				BlackRose = form("SUPER SAIYAN ROSE", "FF5AAA", "FFE1F0", 2.8, 0.6, { calmRings = true, wisps = true }),
			},
		},
	},
}
