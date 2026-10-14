--!strict
-- ModuleScript: ReplicatedStorage.Shared.Telegraphs (WP-STORY-2)
-- Visual danger zones, windup timings, and shape definitions for raid and story bosses.
local Telegraphs = {}

export type ShapeType = "Cone" | "Circle" | "Line" | "Ring"

export type TelegraphPreset = {
	Shape: ShapeType,
	Color: Color3,
	Windup: number, -- Duration before impact (seconds)
	Radius: number?, -- For Circle, Cone, Ring
	Angle: number?, -- For Cone (degrees)
	Length: number?, -- For Line
	Width: number?, -- For Line
}

Telegraphs.PRESETS = {
	-- Jiren the Gray: Power Impact
	JirenPowerImpact = {
		Shape = "Cone",
		Color = Color3.fromRGB(255, 40, 40),
		Windup = 1.0,
		Radius = 65,
		Angle = 45,
	},

	-- Broly: Gigantic Eraser
	BrolyEraserCannon = {
		Shape = "Circle",
		Color = Color3.fromRGB(70, 255, 90),
		Windup = 1.2,
		Radius = 32,
	},

	-- Beerus: Sphere of Destruction
	BeerusSphere = {
		Shape = "Circle",
		Color = Color3.fromRGB(160, 40, 240),
		Windup = 1.5,
		Radius = 45,
	},

	-- Frieza: Death Beam Snipe
	FriezaDeathBeam = {
		Shape = "Line",
		Color = Color3.fromRGB(255, 30, 80),
		Windup = 0.6,
		Length = 140,
		Width = 4,
	},

	-- Moro: Planet Drain Zone
	MoroDrainZone = {
		Shape = "Ring",
		Color = Color3.fromRGB(80, 240, 90),
		Windup = 1.4,
		Radius = 50,
	},
} :: { [string]: TelegraphPreset }

function Telegraphs.get(presetName: string): TelegraphPreset?
	return Telegraphs.PRESETS[presetName]
end

return Telegraphs
