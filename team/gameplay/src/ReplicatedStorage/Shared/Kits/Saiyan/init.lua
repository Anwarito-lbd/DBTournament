--!nonstrict
-- Kit: Saiyans (the reference kit for Shared/Kits). Race defaults give every Saiyan the gold battle-aura build-up and
-- a camera push on their signature beam; each character entry makes them their own fighter. Goku powers up calm
-- then explodes; Vegeta roars earlier, his aura runs blue-white and the camera hits harder on his Final Flash.
-- Effects named here live in ReplicatedStorage.VFX or in Kits/Saiyan/VFX; clip sets in the shared Poses folder or
-- Kits/Saiyan/Poses. Fields are documented in Kits/init.lua.
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

return {
	race = "Saiyan",
	defaults = {
		powerUp = { color = rgb(255, 226, 120), zoom = 5, screamStage = 3, crack = 1.0 },
		cameras = { Kamehameha = { zoom = 6, shake = 0.3 } },
	},
	characters = {
		u7_goku = {
			clips = "Goku",
			signatures = { Kamehameha = "KamehamehaVFX" },
			-- calm focus, then the explosion: scream only at full power
			powerUp = { color = rgb(255, 236, 150), zoom = 5, screamStage = 3, crack = 1.0 },
			cameras = { Kamehameha = { zoom = 8, shake = 0.35 } },
		},
		u7_vegeta = {
			clips = "Vegeta",
			signatures = { Kamehameha = "FinalFlashVFX" },
			-- prideful: roars from stage 2, blue-white aura, bigger cracks, harder camera on the Final Flash
			powerUp = { color = rgb(176, 200, 255), zoom = 7, screamStage = 2, crack = 1.35 },
			cameras = { Kamehameha = { zoom = 10, shake = 0.5 } },
		},
	},
}
