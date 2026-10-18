--!nonstrict
-- Kit: Earth's defenders (Universe 7's non-Saiyan fighters). Seven fighters from four races, so each entry notes
-- its own `race` (informational; Races.CHAMPION is the source of truth):
-- Piccolo meditates and then drops his weighted clothes; Android 17 and 18 have no ki to gather, so their power-up
-- is a cold, silent hum with no scream; Krillin shouts early and fights smart; Tien is discipline and raw force;
-- Master Roshi is a joke until he bulks to Max Power; Shin is a young god who never raises his voice.
-- Design notes per fighter and the "needs server work" list: KITS.md next to this file.
-- Effects named here live in ReplicatedStorage.VFX or Kits/EarthDefenders/VFX; clip sets in Kits/EarthDefenders/Poses.
-- Fields are documented in Kits/init.lua. Signature keys are server broadcast kinds: "Kamehameha" is the key-2
-- signature slot, "Heavy" the guard-break strike, "Barrier" / "SolarFlare" / "KaiKai" the race power-ups, and kit
-- move ids broadcast as themselves. powerUp.aura is left unset (the white Default aura), because VFXCommon.AURAS has
-- no green, teal or lavender entry yet; the colour still drives the cracks and shockwave. screamStage 4 = never.
-- Colours are Color3 in Roblox; the plain-Luau data check (tests/kit_earthdefenders_tests.luau) has no Color3, so
-- there they stay plain values ({r, g, b} or the hex string), like Config.lua's guard for `script`.
local function rgb(r: number, g: number, b: number): Color3
	return if Color3 then Color3.fromRGB(r, g, b) else ({ r, g, b } :: any)
end
local function hex(h: string): Color3
	return if Color3 then Color3.fromHex(h) else (h :: any)
end

-- a TransformCinematic style: title card, colours, beat flags (lightning, crack, calmRings, wisps, slowmo, dark),
-- camera orbit speed and duration
local function form(title: string, color: string, flash: string, dur: number, orbit: number, beats: any?): any
	local st = { title = title, color = hex(color), flash = hex(flash), dur = dur, orbit = orbit }
	for k, v in beats or {} do
		st[k] = v
	end
	return st
end

return {
	race = "EarthDefenders",
	defaults = {
		powerUp = { color = rgb(255, 240, 200), zoom = 4, screamStage = 3, crack = 1.0 },
		signatures = { Heavy = "EarthHeavyVFX", KiBlast = "EarthKiBlastVFX", SolarFlare = "TaiyokenVFX" },
		cameras = { Kamehameha = { zoom = 6, shake = 0.3 }, Heavy = { zoom = 3, shake = 0.3 } },
	},
	characters = {
		-- Piccolo: the strategist. Meditates through the charge, grunts only at full power, and his Full Power is the
		-- weighted cape and turban hitting the ground. Special Beam Cannon on the signature slot (long, tight,
		-- precise camera); kit move: Light Grenade.
		u7_piccolo = {
			race = "Namekian",
			clips = "Piccolo",
			signatures = { Kamehameha = "PiccoloSBCVFX", LightGrenade = "LightGrenadeVFX" },
			powerUp = { color = rgb(205, 255, 190), zoom = 6, screamStage = 3, crack = 1.1 },
			cameras = {
				Kamehameha = { zoom = 9, shake = 0.25 },
				Heavy = { zoom = 3, shake = 0.35 },
				LightGrenade = { zoom = 6, shake = 0.45 },
			},
			forms = {
				PiccoloWeightsOff = form("WEIGHTS OFF", "DFFFD0", "FFFFFF", 2.2, 0.8, { crack = true }),
			},
			moves = {
				-- both palms, one heavy yellow sphere, a wide blast
				LightGrenade = {
					kind = "ray",
					champion = "u7_piccolo",
					cooldown = 10,
					range = 160,
					width = 6,
					damage = 20,
					ki = 25,
					recovery = 0.45,
					kb = 55,
					guardDamage = 45,
					hitstun = 0.45,
					parryable = false,
					arenaRadius = 12,
					arenaPower = 100,
				},
			},
		},
		-- Android 17: the park ranger. No ki to gather and nothing to prove: a low teal hum, tiny cracks, never a
		-- scream. His barrier is his signature, so the beam slot is a barrier trap and the kit move a
		-- barrier-sheathed punch.
		u7_android_17 = {
			race = "Android",
			clips = "Android17",
			signatures = { Kamehameha = "BarrierTrapVFX", Barrier = "AndroidBarrierVFX", BarrierPunch = "BarrierPunchVFX" },
			powerUp = { color = rgb(70, 230, 190), zoom = 3, screamStage = 4, crack = 0.6 },
			cameras = {
				Kamehameha = { zoom = 5, shake = 0.3 },
				Heavy = { zoom = 3, shake = 0.3 },
				Barrier = { zoom = 3, shake = 0.15 },
				BarrierPunch = { zoom = 4, shake = 0.4 },
			},
			moves = {
				-- the Android Barrier wrapped around a fist: guard-heavy, parryable
				BarrierPunch = {
					kind = "melee",
					champion = "u7_android_17",
					cooldown = 9,
					range = 9,
					damage = 15,
					ki = 15,
					recovery = 0.4,
					kb = 50,
					guardDamage = 70,
					hitstun = 0.5,
					parryable = true,
				},
			},
		},
		-- Android 18: cool and efficient. Same silent hum as her brother but pink, no scream; the quickest beam on
		-- the team (Power Blitz from one hand) and a volley for her kit move (Infinity Bullet).
		u7_android_18 = {
			race = "Android",
			clips = "Android18",
			signatures = { Kamehameha = "PowerBlitzVFX", Barrier = "AndroidBarrierVFX", InfinityBullet = "InfinityBulletVFX" },
			powerUp = { color = rgb(255, 150, 210), zoom = 3.5, screamStage = 4, crack = 0.55 },
			cameras = {
				Kamehameha = { zoom = 5, shake = 0.25 },
				Heavy = { zoom = 2.5, shake = 0.25 },
				Barrier = { zoom = 2.5, shake = 0.15 },
				InfinityBullet = { zoom = 3, shake = 0.2 },
			},
			moves = {
				-- a stream of ki bolts; cheap because she never runs out, parryable because it is many small hits
				InfinityBullet = {
					kind = "ray",
					champion = "u7_android_18",
					cooldown = 9,
					range = 150,
					width = 4,
					damage = 16,
					ki = 15,
					recovery = 0.5,
					kb = 20,
					guardDamage = 40,
					hitstun = 0.5,
					parryable = true,
					arenaRadius = 6,
					arenaPower = 40,
				},
			},
		},
		-- Krillin: the bravest man on Earth. Shouts from stage 2 because he has to give it everything; small,
		-- quick hits; the golden Destructo Disc is his signature and the Scattering Bullet his trick.
		u7_krillin = {
			race = "Earthling",
			clips = "Krillin",
			signatures = { Kamehameha = "KrillinDiscVFX", ScatterBullet = "ScatterBulletVFX" },
			powerUp = { color = rgb(255, 225, 140), zoom = 5, screamStage = 2, crack = 0.8 },
			cameras = {
				Kamehameha = { zoom = 7, shake = 0.3 },
				Heavy = { zoom = 2.5, shake = 0.3 },
				SolarFlare = { zoom = 3, shake = 0.15 },
				ScatterBullet = { zoom = 5, shake = 0.3 },
			},
			moves = {
				-- one sphere over the target, a rain of small bolts around it
				ScatterBullet = {
					kind = "ray",
					champion = "u7_krillin",
					cooldown = 11,
					range = 140,
					width = 10,
					damage = 14,
					ki = 20,
					recovery = 0.4,
					kb = 25,
					guardDamage = 30,
					hitstun = 0.4,
					parryable = false,
					arenaRadius = 10,
					arenaPower = 70,
				},
			},
		},
		-- Tien: discipline and raw strength. A silent build that cracks the ground hard, one shout at the top; the
		-- Tri-Beam presses a crater into the floor; the Neo Tri-Beam fires again and again at a cost. He invented
		-- the Solar Flare, so his is the widest.
		u7_tien = {
			race = "Earthling",
			clips = "Tien",
			signatures = { Kamehameha = "TriBeamVFX", NeoTriBeam = "NeoTriBeamVFX" },
			powerUp = { color = rgb(255, 232, 150), zoom = 7, screamStage = 3, crack = 1.4 },
			cameras = {
				Kamehameha = { zoom = 9, shake = 0.5 },
				Heavy = { zoom = 4, shake = 0.45 },
				SolarFlare = { zoom = 4, shake = 0.2 },
				NeoTriBeam = { zoom = 6, shake = 0.4 },
			},
			moves = {
				-- three Tri-Beams in a row; the life cost waits on the server (KITS.md)
				NeoTriBeam = {
					kind = "ray",
					champion = "u7_tien",
					cooldown = 14,
					range = 180,
					width = 7,
					damage = 22,
					ki = 35,
					recovery = 0.7,
					kb = 60,
					guardDamage = 70,
					hitstun = 0.5,
					parryable = false,
					arenaRadius = 14,
					arenaPower = 110,
				},
			},
		},
		-- Master Roshi: the old hermit who invented the Kamehameha. A lazy charge that turns serious late (scream
		-- at stage 3, big zoom when the muscles arrive); Max Power is his only form; his beam is the original
		-- Kamehameha at maximum output, wider and slower than any student's.
		u7_master_roshi = {
			race = "Earthling",
			clips = "Roshi",
			signatures = { Kamehameha = "MaxKamehamehaVFX" },
			powerUp = { color = rgb(170, 215, 255), zoom = 8, screamStage = 3, crack = 1.25 },
			cameras = {
				Kamehameha = { zoom = 11, shake = 0.55 },
				Heavy = { zoom = 3.5, shake = 0.35 },
				SolarFlare = { zoom = 2.5, shake = 0.15 },
			},
			forms = {
				RoshiMaxPower = form("MAX POWER", "8CC8FF", "FFFFFF", 2.6, 1.0, { crack = true, lightning = true }),
			},
		},
		-- Shin: the Supreme Kai of Universe 7. Calm and divine: barely any cracks, never screams, lavender light.
		-- Energy's Last on the signature slot; Kai Kai as his teleport; kit move: the Kiai eye blast.
		u7_shin = {
			race = "Kaioshin",
			clips = "Shin",
			signatures = { Kamehameha = "EnergysLastVFX", KaiKai = "KaiKaiVFX", KiaiEyeBlast = "KiaiEyeBlastVFX" },
			powerUp = { color = rgb(210, 180, 255), zoom = 3, screamStage = 4, crack = 0.5 },
			cameras = {
				Kamehameha = { zoom = 6, shake = 0.25 },
				Heavy = { zoom = 2, shake = 0.2 },
				KaiKai = { zoom = 2, shake = 0.1 },
				KiaiEyeBlast = { zoom = 3, shake = 0.3 },
			},
			moves = {
				-- an unseen shove of ki from the eyes: little damage, big knockback, can't be parried
				KiaiEyeBlast = {
					kind = "ray",
					champion = "u7_shin",
					cooldown = 10,
					range = 90,
					width = 6,
					damage = 10,
					ki = 15,
					recovery = 0.3,
					kb = 70,
					guardDamage = 25,
					hitstun = 0.35,
					parryable = false,
				},
			},
		},
	},
}
