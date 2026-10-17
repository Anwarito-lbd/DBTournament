-- LocalScript: SkyCycle (PLAN_V11 Step A signature). Like the show's tournament, the void around the stage changes
-- colour as the match wears on: lavender for the first half of the 48:00 show clock, teal-green through the late game,
-- crimson for the final minute. Visual only and local: it drifts the arena's own Atmosphere and grade (the
-- WorldOfVoid-tagged ones from ServerScriptService.ArtPass) from their base values, and only while this player is in
-- a round (not in a raid, story episode or the tutorial). Outside a round it puts the base values back.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local SHOW_TOTAL = 48 * 60
-- remaining seconds -> look; lerped between neighbours. dens is added to the arena's base atmosphere density: the
-- haze thickens late so the void below the horizon (under the nebula skybox) glows the key colour
local KEYS = {
	{ t = SHOW_TOTAL / 2, dens = 0, atmo = Color3.fromRGB(150, 128, 196), decay = Color3.fromRGB(70, 46, 120), tint = Color3.fromRGB(246, 242, 255) },
	{ t = 300, dens = 0.1, atmo = Color3.fromRGB(96, 186, 168), decay = Color3.fromRGB(24, 96, 86), tint = Color3.fromRGB(238, 252, 248) },
	{ t = 60, dens = 0.18, atmo = Color3.fromRGB(214, 70, 86), decay = Color3.fromRGB(120, 18, 36), tint = Color3.fromRGB(255, 236, 238) },
}

local function lookAt(remaining: number): (Color3, Color3, Color3, number)
	if remaining >= KEYS[1].t then return KEYS[1].atmo, KEYS[1].decay, KEYS[1].tint, KEYS[1].dens end
	for i = 1, #KEYS - 1 do
		local a, b = KEYS[i], KEYS[i + 1]
		if remaining >= b.t then
			local k = (a.t - remaining) / (a.t - b.t)
			return a.atmo:Lerp(b.atmo, k), a.decay:Lerp(b.decay, k), a.tint:Lerp(b.tint, k), a.dens + (b.dens - a.dens) * k
		end
	end
	local z = KEYS[#KEYS]
	return z.atmo, z.decay, z.tint, z.dens
end

local function arenaLook(): (Atmosphere?, ColorCorrectionEffect?)
	local atm, cc = nil, nil
	for _, c in Lighting:GetChildren() do
		if c:GetAttribute("WorldOfVoid") then
			if c:IsA("Atmosphere") then atm = c elseif c:IsA("ColorCorrectionEffect") then cc = c end
		end
	end
	return atm, cc
end

local base: { [Instance]: { [string]: any } } = {}
local function remember(atm: Atmosphere?, cc: ColorCorrectionEffect?)
	if atm and not base[atm] then base[atm] = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density } end
	if cc and not base[cc] then base[cc] = { TintColor = cc.TintColor } end
end

local drifting = false
local ease = TweenInfo.new(1.5, Enum.EasingStyle.Sine)
while true do
	task.wait(1)
	local atm, cc = arenaLook()
	remember(atm, cc)
	local show = workspace:GetAttribute("ShowClock")
	local active = workspace:GetAttribute("RoundState") == "InRound" and type(show) == "number"
		and player:GetAttribute("InRaid") ~= true and player:GetAttribute("InTutorial") ~= true
	if active then
		drifting = true
		local a, d, t, dens = lookAt(show :: number)
		if atm then TweenService:Create(atm, ease, { Color = a, Decay = d, Density = base[atm].Density + dens }):Play() end
		if cc then TweenService:Create(cc, ease, { TintColor = t }):Play() end
	elseif drifting then
		drifting = false
		for inst, props in base do
			if inst.Parent then TweenService:Create(inst, ease, props):Play() end
		end
	end
end
