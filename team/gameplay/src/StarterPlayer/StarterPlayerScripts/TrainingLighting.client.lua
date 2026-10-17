--!strict
-- LocalScript: applies training-area lighting on the client (Lighting is global, so this must be per-client).
-- Server sets player attributes TrainingArea + LightingPreset (TrainingRooms). Presets come from db-map's
-- TrainingAreas.LightingPresets if a copy is replicated (ReplicatedStorage.TrainingAreas or
-- ReplicatedStorage.Shared.TrainingLightingPresets); otherwise the built-in fallback below (mirrors map v1.2).
-- Leaving an area restores the lighting captured at startup (the lobby look), not the "Lobby" preset table.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local function rgb(r: number, g: number, b: number) return Color3.fromRGB(r, g, b) end
local FALLBACK = {
	Lobby = { ClockTime = 0, Ambient = rgb(70, 60, 110), FogColor = rgb(20, 18, 40), FogEnd = 4000 },
	HTC = { ClockTime = 12, Ambient = rgb(255, 255, 255), OutdoorAmbient = rgb(255, 255, 255), FogColor = rgb(255, 255, 255),
		FogStart = 50, FogEnd = 700, Brightness = 3 },
	GravityRoom = { ClockTime = 20, Ambient = rgb(180, 60, 60), FogColor = rgb(40, 0, 0), FogEnd = 2000 },
	KingKai = { ClockTime = 14, Ambient = rgb(200, 180, 120), FogColor = rgb(250, 220, 140), FogStart = 300, FogEnd = 2500 },
	BeerusPlanet = { ClockTime = 17, Ambient = rgb(140, 110, 170), FogColor = rgb(120, 90, 180), FogStart = 400, FogEnd = 3000 },
	-- v8b raid maps (mirror map/training/TrainingLightingPresets.lua)
	BrolyCrater = { ClockTime = 18.5, Ambient = rgb(150, 90, 60), OutdoorAmbient = rgb(170, 100, 60), FogColor = rgb(140, 80, 50), FogStart = 250, FogEnd = 1800, Brightness = 2.5 },
	MoroNamek = { ClockTime = 16, Ambient = rgb(110, 140, 130), OutdoorAmbient = rgb(120, 150, 140), FogColor = rgb(150, 170, 160), FogStart = 300, FogEnd = 2200, Brightness = 2 },
}
FALLBACK.Broly, FALLBACK.Moro = FALLBACK.BrolyCrater, FALLBACK.MoroNamek -- if a raid id is used as the preset name

local function loadPresets(): { [string]: any }
	-- v8: db-map ships map/training/TrainingLightingPresets.lua -> ReplicatedStorage.Shared.TrainingLightingPresets (training_spec.md);
	-- wait briefly for replication, then the legacy ReplicatedStorage.TrainingAreas, then FALLBACK.
	local shared = ReplicatedStorage:WaitForChild("Shared", 10)
	local presetsMod = shared and shared:WaitForChild("TrainingLightingPresets", 5)
	for _, inst in { presetsMod, ReplicatedStorage:FindFirstChild("TrainingAreas") } do
		if inst and inst:IsA("ModuleScript") then
			local ok, m = pcall(require, inst)
			if ok and type(m) == "table" then
				local t = (m :: any).LightingPresets or m
				if type(t) == "table" and next(t) then return t end
			end
		end
	end
	return FALLBACK
end
local PRESETS = loadPresets()

local KEYS = { "ClockTime", "Ambient", "OutdoorAmbient", "FogColor", "FogStart", "FogEnd", "Brightness" }
local startup: { [string]: any } = {}
for _, k in KEYS do startup[k] = (Lighting :: any)[k] end
-- v11: the arena art pass publishes its base look as Lighting attributes (Base_<key>); restore to those live values,
-- falling back to the join-time snapshot (which can predate the art pass and hold stale place values)
local function baseLook(): { [string]: any }
	local out = {}
	for _, k in KEYS do
		local v = Lighting:GetAttribute("Base_" .. k)
		out[k] = if v ~= nil then v else startup[k]
	end
	return out
end

local current: Tween? = nil
local function apply(props: { [string]: any }, time: number)
	if current then current:Cancel() end
	local goal = {}
	for _, k in KEYS do if props[k] ~= nil then goal[k] = props[k] end end
	-- ClockTime wraps; set instantly to avoid a 24h sweep
	if goal.ClockTime ~= nil then Lighting.ClockTime = goal.ClockTime; goal.ClockTime = nil end
	current = TweenService:Create(Lighting, TweenInfo.new(time, Enum.EasingStyle.Sine), goal)
	;(current :: Tween):Play()
end

local function refresh()
	local area = lp:GetAttribute("TrainingArea")
	local name = lp:GetAttribute("LightingPreset") :: string?
	local inRaid = lp:GetAttribute("RaidId") ~= nil -- v8b: raids set LightingPreset without a TrainingArea
	if (area == nil and not inRaid) or name == nil or name == "Lobby" then apply(baseLook(), 0.6); return end
	local preset = PRESETS[name] or FALLBACK[name]
	if preset then apply(preset, 0.6) else apply(baseLook(), 0.6) end
end
-- a new round re-runs the art pass: follow its base look while not inside a training area or raid
Lighting.AttributeChanged:Connect(function(attr)
	if attr:sub(1, 5) == "Base_" and lp:GetAttribute("TrainingArea") == nil and lp:GetAttribute("RaidId") == nil then
		apply(baseLook(), 0.6)
	end
end)
lp:GetAttributeChangedSignal("TrainingArea"):Connect(refresh)
lp:GetAttributeChangedSignal("LightingPreset"):Connect(refresh)
lp:GetAttributeChangedSignal("RaidId"):Connect(refresh)
refresh()
