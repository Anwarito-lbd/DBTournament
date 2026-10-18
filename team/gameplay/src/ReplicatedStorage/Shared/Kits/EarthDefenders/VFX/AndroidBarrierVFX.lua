--!nonstrict
-- AndroidBarrierVFX (Earth defenders kit). The Android race's Barrier power-up, per android. The shared
-- Android17BarrierVFX only exposes Start/Hit/Stop, but VFXRouter calls Play, so the "Barrier" broadcast drew nothing;
-- this wrapper starts the hex dome for the server's duration (VFXRouter passes it as the target argument).
-- Android 17's barrier is his signature: bluish green, wider, more panels. Android 18's is a tighter pale-blue shell.
-- Play(character, duration, config?) -- client visual only; the server owns the barrier's protection.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local Dome = require(VFX:WaitForChild("Android17BarrierVFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local rgb = E.rgb

local M = {}
M.STYLES = {
	u7_android_17 = { Radius = 7.5, Color = rgb(70, 230, 190), EdgeColor = rgb(210, 255, 240), Rings = 6, PanelsPerRing = 14 },
	u7_android_18 = { Radius = 6, Color = rgb(150, 200, 255), EdgeColor = rgb(235, 245, 255), Rings = 5, PanelsPerRing = 12 },
}
M.DEFAULT = { Radius = 7, Color = rgb(80, 255, 140), EdgeColor = rgb(200, 255, 220), Rings = 5, PanelsPerRing = 12 }

function M.Play(character: Model, duration: any, _config: any?)
	local cfg = table.clone(M.STYLES[E.championId(character) or ""] or M.DEFAULT)
	cfg.Duration = if type(duration) == "number" and duration > 0 then duration else 2
	cfg.ShatterArenaDamage = false
	return Dome.Start(character, cfg)
end
return M
