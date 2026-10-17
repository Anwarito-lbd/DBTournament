--!nonstrict
-- Kit: Universe 11, the Pride Troopers (and Jiren, whose race is JirenType but who fights under the same banner).
-- Race defaults give every trooper the red-and-white justice look: a red justice blast in the signature slot, a
-- team-wide Justice Pose flash, and a disciplined power-up that never screams before full power. Each character entry
-- makes them their own fighter: Jiren is silent and crushing, Toppo roars and becomes a God of Destruction, Dyspo is
-- all speed, Kahseral shoots like a marksman, Cocotte fights from behind her dimension walls, and the big three
-- (Vuon, Zoiray, Tupper) are brawlers whose power-ups break the floor. Effects named here live in
-- ReplicatedStorage.VFX or in Kits/PrideTrooper/VFX. Fields are documented in Kits/init.lua.
-- powerUp.screamStage: power-up stages run 1-3, so 4 means the fighter never screams.
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local hex = Color3.fromHex

local JUSTICE_RED = rgb(235, 60, 60)

return {
	race = "PrideTrooper",
	defaults = {
		signatures = { Kamehameha = "JusticeBlastVFX", JusticePose = "JusticePoseVFX" },
		cameras = { Kamehameha = { zoom = 6, shake = 0.3 }, JusticePose = { zoom = 4, shake = 0.15 } },
		powerUp = { color = JUSTICE_RED, zoom = 5, screamStage = 3, crack = 1.0 },
	},
	characters = {
		u11_jiren = {
			-- silent and absolute: red aura from the first stage, never screams, the ground gives way around him
			signatures = { Kamehameha = "PowerImpactVFX" },
			cameras = { Kamehameha = { zoom = 10, shake = 0.6 }, JusticePose = { zoom = 3, shake = 0.1 } },
			powerUp = { aura = "JirenFullPower", color = rgb(255, 70, 60), zoom = 8, screamStage = 4, crack = 1.6 },
			forms = {
				-- no lightning, no roar: a slow, heavy reveal
				JirenFullPower = {
					title = "JIREN  •  FULL POWER",
					color = hex("FF3B3B"),
					flash = hex("FFAA78"),
					crack = true,
					orbit = 0.6,
					dur = 2.8,
				},
			},
		},
		u11_toppo = {
			-- the Pride Troopers' voice of justice: roars from stage 2; as a God of Destruction the world goes dark
			signatures = { Kamehameha = "ToppoDestructionVFX" },
			cameras = { Kamehameha = { zoom = 9, shake = 0.5 }, JusticePose = { zoom = 6, shake = 0.3 } },
			powerUp = { color = rgb(255, 200, 120), zoom = 6, screamStage = 2, crack = 1.3 },
			forms = {
				ToppoGoD = {
					title = "TOPPO  •  GOD OF DESTRUCTION",
					color = hex("8B3AFF"),
					flash = hex("C08AFF"),
					dark = true,
					crack = true,
					orbit = 0.8,
					dur = 3.0,
				},
			},
		},
		u11_dyspo = {
			-- the fastest trooper: a quick finger shot, light camera, a small power-up that does not slow him down
			signatures = { Kamehameha = "DeathBeamVFX" },
			cameras = { Kamehameha = { zoom = 3, shake = 0.15 } },
			powerUp = { color = rgb(200, 150, 255), zoom = 3, screamStage = 4, crack = 0.7 },
		},
		u11_kahseral = {
			-- the squad leader and marksman: a precise piercing shot with a tight push-in
			signatures = { Kamehameha = "SpecialBeamCannonVFX" },
			cameras = { Kamehameha = { zoom = 8, shake = 0.2 } },
			powerUp = { color = JUSTICE_RED, zoom = 5, screamStage = 3, crack = 1.0 },
		},
		u11_cocotte = {
			-- the dimension specialist: her Justice Pose raises a dimension wall instead of a flash; calm power-up
			signatures = { JusticePose = "DimensionWallVFX" },
			cameras = { JusticePose = { zoom = 5, shake = 0.1 } },
			powerUp = { color = rgb(150, 220, 255), zoom = 3, screamStage = 4, crack = 0.8 },
		},
		u11_kunshi = {
			-- composed and technical: a light camera and no scream
			cameras = { Kamehameha = { zoom = 5, shake = 0.2 } },
			powerUp = { color = JUSTICE_RED, zoom = 4, screamStage = 4, crack = 0.9 },
		},
		u11_vuon = {
			-- a giant brawler: shouts early and cracks the floor wide
			cameras = { Kamehameha = { zoom = 7, shake = 0.45 } },
			powerUp = { color = rgb(255, 150, 90), zoom = 6, screamStage = 1, crack = 1.5 },
		},
		u11_zoiray = {
			cameras = { Kamehameha = { zoom = 6, shake = 0.35 } },
			powerUp = { color = rgb(255, 120, 80), zoom = 5, screamStage = 2, crack = 1.2 },
		},
		u11_tupper = {
			-- the heaviest of the three: the biggest cracks of any trooper but Jiren
			cameras = { Kamehameha = { zoom = 7, shake = 0.5 } },
			powerUp = { color = rgb(255, 170, 110), zoom = 6, screamStage = 2, crack = 1.45 },
		},
	},
}
