--!nonstrict
-- TaiyokenVFX (Earth defenders kit). Solar Flare, the Crane School's blinding light (the Earthling race power-up),
-- per fighter: Tien invented it and his flash is the widest and whitest; Krillin's is warm gold; Master Roshi's is
-- the smallest. Hands spread at the face, a point of light swells at the brow, then a sunburst.
-- Self-contained on purpose: the shared SolarFlareVFX is not mapped in default.project.json, and its screen blind
-- hits every client within 75 studs (the caster too) while the server blinds only fighters within its radius who
-- face the flash. Here the white-out follows the server: it shows only while the local player's BlindUntil
-- attribute (set by RacePowerUps) is in the future.
-- Play(character, config?) as VFXRouter calls it for "SolarFlare"; Play(character, target, config?) also works.
-- Client visual only.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
-- color/core: the burst; charge: brow swell (s); burst: flash sphere size; ring: ground ring (studs);
-- rays: sunburst spokes; whiteout: tint of the server-confirmed blind
M.STYLES = {
	u7_tien = { color = rgb(255, 252, 235), core = rgb(255, 255, 255), charge = 0.35, burst = 46, ring = 50, rays = 12,
		whiteout = rgb(255, 255, 250) },
	u7_krillin = { color = rgb(255, 236, 170), core = rgb(255, 255, 240), charge = 0.45, burst = 38, ring = 40, rays = 10,
		whiteout = rgb(255, 248, 225) },
	u7_master_roshi = { color = rgb(255, 244, 205), core = rgb(255, 255, 245), charge = 0.5, burst = 32, ring = 34,
		rays = 8, whiteout = rgb(255, 250, 235) },
}
M.DEFAULT = { color = rgb(255, 250, 220), core = rgb(255, 255, 255), charge = 0.45, burst = 38, ring = 40, rays = 10,
	whiteout = rgb(255, 255, 250) }

-- white-out for as long as the server says the local player is blind (polls briefly for the attribute to land)
local function whiteout(color: Color3)
	local lp = Players.LocalPlayer
	local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local untilT: number? = nil
	for _ = 1, 12 do
		local u = lp:GetAttribute("BlindUntil")
		if type(u) == "number" and u > workspace:GetServerTimeNow() then
			untilT = u
			break
		end
		task.wait(0.05)
	end
	if not untilT then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SolarFlareWhiteout"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.ResetOnSpawn = false
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = color
	fill.Parent = gui
	gui.Parent = pg
	local left = math.max(0.2, untilT - workspace:GetServerTimeNow())
	C.tween(fill, left, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	game:GetService("Debris"):AddItem(gui, left + 0.1)
end

local function burst(character: Model, s: any)
	local root = C.root(character)
	if not root then return end
	local head = C.limb(character, { "Head" })
	local f = C.folder("TaiyokenVFX", s.charge + 2)
	local flare = C.part(f, Vector3.one * 0.5, s.core, Enum.PartType.Ball)
	local lt = C.light(flare, s.color, 8, 2)
	local t0 = os.clock()
	while os.clock() - t0 < s.charge and character.Parent do
		local k = (os.clock() - t0) / s.charge
		flare.Position = head.Position + head.CFrame.LookVector * 0.9
		flare.Size = Vector3.one * (0.5 + k * 2.5)
		lt.Range, lt.Brightness = 8 + k * 40, 2 + k * 8
		RunService.Heartbeat:Wait()
	end
	local origin = flare.Position
	flare.Size = Vector3.one * s.burst * 0.35
	C.tween(flare, 0.4, { Size = Vector3.one * s.burst, Transparency = 1 })
	C.Shockwave(f, CFrame.new(origin), 2, s.ring, s.color, 0.5, 0.5)
	C.Shockwave(f, CFrame.new(origin), 1, s.ring * 0.65, s.core, 0.35, 0.4)
	for i = 1, C.q(s.rays) do -- sunburst spokes in the facing half
		local ang = math.rad(-80 + 160 * (i - 1) / math.max(1, s.rays - 1))
		local dir = (root.CFrame * CFrame.Angles(math.rad(math.random(-25, 25)), ang, 0)).LookVector
		local ray = C.part(f, Vector3.new(0.3, 0.3, 4), s.core, nil, 0.1)
		ray.CFrame = CFrame.lookAt(origin, origin + dir) * CFrame.new(0, 0, -2)
		C.tween(ray, 0.35, { Size = Vector3.new(0.05, 0.05, s.ring * 0.6), Transparency = 1,
			CFrame = CFrame.lookAt(origin, origin + dir) * CFrame.new(0, 0, -s.ring * 0.3) })
	end
end

function M.Play(character: Model, _a: any?, _b: any?)
	if not C.root(character) then return end
	local s = M.STYLES[E.championId(character) or ""] or M.DEFAULT
	task.spawn(burst, character, s)
	local lp = Players.LocalPlayer
	if lp and lp.Character ~= character then
		task.spawn(whiteout, s.whiteout)
	end
end
return M
