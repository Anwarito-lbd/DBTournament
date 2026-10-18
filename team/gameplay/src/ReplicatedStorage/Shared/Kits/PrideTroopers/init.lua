--!nonstrict
-- Kit: Universe 11, the Pride Troopers, plus Jiren (race JirenType in Races.lua, but he fights under the same banner).
-- Every trooper strikes their own Justice pose and fires a red justice blast unless their entry says otherwise; each
-- character entry is grounded in their techniques on the Dragon Ball wiki (see KITS.md in this folder):
--   Jiren     stoic meditation, Power Impact, Grand Charge, full-power red aura that never needs a scream
--   Toppo     Justice Flash finger shots; in Destroyer form the same button throws Destructive Flare energy
--   Dyspo     Light Bullet speed bursts and Cannon Maximum
--   Kahseral  the squad leader's Cannon Maximum
--   Cocotte   Cocotte Zone, a purple dimension dome (her Justice Pose and her barrier move)
--   Kunshi    Threaded Energy
--   Vuon      Dynamite Blaster and the Justice Whip lasso
--   Zoiray    Justice Spin
--   Tupper    a petrified, burning spin
-- Effects named here live in ReplicatedStorage.VFX or Kits/PrideTroopers/VFX; clip sets in Kits/PrideTroopers/Poses.
-- Registry fields are documented in Kits/init.lua. `look` is this kit's own field: the colours and shapes its VFX
-- modules read through lookFor(), so each fighter's identity stays in this one file.
-- powerUp.screamStage: power-up stages run 1-3, so 4 means the fighter never screams.
local Players = game and game:GetService("Players")

-- Color3 is a Roblox global; the plain-Luau data test (team/gameplay/tests/kit_pridetroopers_tests.luau) has none
-- and gets {r, g, b} triples instead.
local function rgb(r: number, g: number, b: number): any
	return if Color3 then Color3.fromRGB(r, g, b) else { r, g, b }
end

local JUSTICE_RED = rgb(235, 60, 60)
local WHITE = rgb(255, 245, 240)

local kit = {
	race = "PrideTroopers",
	defaults = {
		clips = "Troopers",
		signatures = { Kamehameha = "JusticeBlastVFX", JusticePose = "JusticePoseVFX" },
		cameras = { Kamehameha = { zoom = 6, shake = 0.3 }, JusticePose = { zoom = 4, shake = 0.15 } },
		powerUp = { color = JUSTICE_RED, zoom = 5, screamStage = 3, crack = 1.0 },
		look = {
			blast = { Color = JUSTICE_RED, CoreColor = WHITE, CoronaColor = rgb(255, 130, 120) },
			pose = { Color = JUSTICE_RED, CoreColor = WHITE },
		},
	},
	characters = {
		u11_jiren = {
			-- silent and absolute: meditates instead of posing, red aura from the first stage, never screams,
			-- and the ground gives way around him
			clips = "Jiren",
			signatures = { Kamehameha = "PowerImpactVFX", GrandCharge = "NovaStrikeVFX" },
			cameras = {
				Kamehameha = { zoom = 10, shake = 0.6 },
				GrandCharge = { zoom = 8, shake = 0.5 },
				JusticePose = { zoom = 3, shake = 0.1 },
			},
			powerUp = { aura = "JirenFullPower", color = rgb(255, 70, 60), zoom = 8, screamStage = 4, crack = 1.6 },
			forms = {
				-- no lightning, no roar: a slow, heavy reveal
				JirenFullPower = {
					title = "JIREN  •  FULL POWER",
					color = rgb(255, 59, 59),
					flash = rgb(255, 170, 120),
					crack = true,
					orbit = 0.6,
					dur = 2.8,
				},
			},
			moves = {
				-- Grand Charge: a shoulder charge inside a purple barrier
				GrandCharge = {
					kind = "melee",
					champion = "u11_jiren",
					cooldown = 9,
					range = 14,
					damage = 14,
					ki = 20,
					recovery = 0.4,
					kb = 60,
					guardDamage = 60,
					guardBreak = true,
					hitstun = 0.6,
					parryable = true,
				},
			},
		},
		u11_toppo = {
			-- the troopers' loudest voice of justice: roars from stage 2; as a God of Destruction candidate the world
			-- goes dark and his Justice Flash becomes destruction energy
			clips = "Toppo",
			signatures = { Kamehameha = "JusticeFlashVFX" },
			cameras = { Kamehameha = { zoom = 7, shake = 0.4 }, JusticePose = { zoom = 6, shake = 0.3 } },
			powerUp = { color = rgb(255, 200, 120), zoom = 6, screamStage = 2, crack = 1.3 },
			forms = {
				ToppoGoD = {
					title = "TOPPO  •  GOD OF DESTRUCTION",
					color = rgb(139, 58, 255),
					flash = rgb(192, 138, 255),
					dark = true,
					crack = true,
					orbit = 0.8,
					dur = 3.0,
				},
			},
			look = {
				flash = { Color = rgb(255, 90, 70), CoreColor = WHITE, Width = 0.5, Shots = 5 },
				destroyer = {
					ChargeTime = 1.2,
					TravelSpeed = 70,
					BallSize = 12,
					Height = 8,
					Color = rgb(139, 58, 255),
					CoreColor = rgb(26, 10, 42),
					CoronaColor = rgb(192, 138, 255),
					ImpactSize = 50,
				},
			},
		},
		u11_dyspo = {
			-- the fastest trooper: Light Bullet bursts, a quick Cannon Maximum, a light camera, a power-up that does
			-- not slow him down
			clips = "Dyspo",
			signatures = { Kamehameha = "JusticeWaveVFX", LightBullet = "LightBulletVFX" },
			cameras = { Kamehameha = { zoom = 3, shake = 0.15 }, LightBullet = { zoom = 2, shake = 0.1 } },
			powerUp = { color = rgb(200, 150, 255), zoom = 3, screamStage = 4, crack = 0.7 },
			look = {
				wave = {
					Core = rgb(250, 240, 255),
					Glow = rgb(190, 120, 255),
					Haze = rgb(120, 60, 220),
					Width = 4.5,
					Charge = 0.5,
					Duration = 0.9,
					Spiral = true,
					ImpactSize = 28,
					Shake = 2.5,
					ChargeAt = "hands",
					Speed = 600,
				},
				rush = { Color = rgb(200, 150, 255), CoreColor = WHITE, Hits = 5, Interval = 0.05, FinalSize = 24 },
			},
			moves = {
				-- Light Bullet: a burst thousands of times faster than his normal speed
				LightBullet = {
					kind = "melee",
					champion = "u11_dyspo",
					cooldown = 6,
					range = 16,
					damage = 9,
					ki = 15,
					recovery = 0.2,
					kb = 20,
					guardDamage = 20,
					hitstun = 0.4,
					parryable = true,
				},
			},
		},
		u11_kahseral = {
			-- the squad leader: a steady, golden Cannon Maximum and a tight push-in
			clips = "Kahseral",
			signatures = { Kamehameha = "JusticeWaveVFX" },
			cameras = { Kamehameha = { zoom = 8, shake = 0.35 }, JusticePose = { zoom = 5, shake = 0.2 } },
			powerUp = { color = rgb(255, 200, 90), zoom = 5, screamStage = 3, crack = 1.0 },
			look = {
				wave = {
					Core = rgb(255, 250, 220),
					Glow = rgb(255, 200, 60),
					Haze = rgb(230, 140, 20),
					Width = 6,
					Charge = 1.0,
					Duration = 1.3,
					Spiral = true,
					ImpactSize = 36,
					Shake = 3.5,
					ChargeAt = "hands",
					Speed = 440,
				},
			},
		},
		u11_cocotte = {
			-- the dimension specialist: Cocotte Zone is both her Justice Pose and her barrier; her shot is a
			-- swirling Ki Bomb; calm power-up
			clips = "Cocotte",
			signatures = { JusticePose = "CocotteZoneVFX", Barrier = "CocotteZoneVFX" },
			cameras = { JusticePose = { zoom = 5, shake = 0.1 }, Barrier = { zoom = 5, shake = 0.15 } },
			powerUp = { color = rgb(190, 120, 255), zoom = 3, screamStage = 4, crack = 0.8 },
			look = {
				blast = { Color = rgb(200, 110, 255), CoreColor = WHITE, CoronaColor = rgb(240, 180, 255) },
				zone = { Color = rgb(150, 70, 230), EdgeColor = rgb(225, 190, 255), Radius = 7 },
			},
			moves = {
				-- Cocotte Zone used for defence (the server's barrier kind)
				CocotteZone = {
					kind = "barrier",
					champion = "u11_cocotte",
					cooldown = 18,
					range = 0,
					ki = 30,
					recovery = 0,
				},
			},
		},
		u11_kunshi = {
			-- composed and technical: a thin thread of solid energy, no scream
			clips = "Kunshi",
			signatures = { Kamehameha = "JusticeWaveVFX" },
			cameras = { Kamehameha = { zoom = 5, shake = 0.15 } },
			powerUp = { color = rgb(120, 230, 255), zoom = 4, screamStage = 4, crack = 0.9 },
			look = {
				wave = {
					Core = rgb(235, 255, 255),
					Glow = rgb(120, 230, 255),
					Haze = rgb(40, 150, 220),
					Width = 0.7,
					Charge = 0.35,
					Duration = 0.6,
					Spiral = false,
					ImpactSize = 12,
					Shake = 1,
					ChargeAt = "finger",
					Speed = 800,
				},
			},
		},
		u11_vuon = {
			-- a giant brawler: shouts from the first stage, cracks the floor wide, a heavy Dynamite Blaster and a
			-- Justice Whip that holds the target in place
			clips = "Vuon",
			signatures = { Kamehameha = "JusticeWaveVFX", JusticeWhip = "JusticeWhipVFX" },
			cameras = { Kamehameha = { zoom = 7, shake = 0.45 }, JusticeWhip = { zoom = 4, shake = 0.2 } },
			powerUp = { color = rgb(255, 150, 90), zoom = 6, screamStage = 1, crack = 1.5 },
			look = {
				wave = {
					Core = rgb(255, 240, 210),
					Glow = rgb(255, 140, 40),
					Haze = rgb(220, 70, 20),
					Width = 7,
					Charge = 1.2,
					Duration = 1.4,
					Spiral = false,
					ImpactSize = 40,
					Shake = 4.5,
					ChargeAt = "hands",
					Speed = 380,
				},
				whip = { Color = rgb(255, 160, 60), CoreColor = WHITE, Width = 0.6 },
			},
			moves = {
				-- Justice Whip: an energy lasso that binds; long range, long hitstun, little damage
				JusticeWhip = {
					kind = "melee",
					champion = "u11_vuon",
					cooldown = 12,
					range = 20,
					damage = 4,
					ki = 20,
					recovery = 0.3,
					kb = 0,
					guardDamage = 10,
					hitstun = 1.0,
					parryable = true,
				},
			},
		},
		u11_zoiray = {
			-- spins himself into a whirlwind
			clips = "Zoiray",
			signatures = { JusticeSpin = "JusticeSpinVFX" },
			cameras = { Kamehameha = { zoom = 6, shake = 0.35 }, JusticeSpin = { zoom = 3, shake = 0.3 } },
			powerUp = { color = rgb(255, 120, 80), zoom = 5, screamStage = 2, crack = 1.2 },
			look = {
				spin = { Color = rgb(255, 150, 120), CoreColor = WHITE, Duration = 0.8, Radius = 9 },
			},
			moves = {
				JusticeSpin = {
					kind = "melee",
					champion = "u11_zoiray",
					cooldown = 7,
					range = 9,
					damage = 8,
					ki = 15,
					recovery = 0.35,
					kb = 35,
					guardDamage = 25,
					hitstun = 0.5,
					parryable = true,
				},
			},
		},
		u11_tupper = {
			-- the heaviest trooper: a stone-grey power-up with the biggest cracks of any trooper but Jiren, and a
			-- petrified spin that catches fire
			clips = "Tupper",
			signatures = { BurningSpin = "JusticeSpinVFX" },
			cameras = { Kamehameha = { zoom = 7, shake = 0.5 }, BurningSpin = { zoom = 4, shake = 0.45 } },
			powerUp = { color = rgb(170, 160, 150), zoom = 6, screamStage = 2, crack = 1.45 },
			look = {
				spin = {
					Color = rgb(150, 140, 130),
					CoreColor = rgb(255, 140, 40),
					Duration = 1.0,
					Radius = 11,
					Debris = true,
				},
			},
			moves = {
				-- Self Petrification plus Self Ignition: a burning stone wheel
				BurningSpin = {
					kind = "melee",
					champion = "u11_tupper",
					cooldown = 9,
					range = 10,
					damage = 10,
					ki = 15,
					recovery = 0.45,
					kb = 45,
					guardDamage = 40,
					hitstun = 0.5,
					parryable = true,
				},
			},
		},
	},
}

-- the character id behind a model: player attribute first, then the model's own (bots, story NPCs)
function kit.idOf(character: Instance?): string?
	if not character then
		return nil
	end
	local pl = Players and Players:GetPlayerFromCharacter(character)
	local id = (pl and pl:GetAttribute("Character"))
		or character:GetAttribute("Character")
		or character:GetAttribute("ChampionModel")
	return if type(id) == "string" then id else nil
end

-- this kit's `look` entry for a character, the character's own winning over the race default
function kit.lookFor(id: string?, field: string): any
	local c = id and kit.characters[id]
	local own = c and c.look and c.look[field]
	if own ~= nil then
		return own
	end
	return kit.defaults.look[field]
end

return kit
