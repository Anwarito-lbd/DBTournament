--!nonstrict
-- SaiyanHeavyVFX (Saiyan kit): the contact flourish on each Saiyan's Heavy (guard-break) strike. VFXRouter plays it
-- for the "Heavy" move kind with the server's hit position. One module, one look per fighter (STYLES below), so a
-- Broly smash and a Goku Black ki-blade thrust read differently at a glance. World effects only: the striker's
-- own camera kick comes from their kit's cameras.Heavy, and other clients get a small distance-scaled shake.
-- Play(character, target, config?) -- client visual only; never deals damage.
local Players = game:GetService("Players")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}

-- color/core: rings and cracks; size: shockwave reach (studs); rings: extra rings; crack: ground crack radius
-- (0 = none); debris: rock count; afterimage: smear colour (nil = none); slash: crescent cut instead of a burst
M.STYLES = {
	u7_goku = { color = rgb(255, 228, 130), core = rgb(255, 255, 240), size = 14, rings = 1, crack = 0, debris = 4,
		afterimage = rgb(255, 240, 190) },
	u7_vegeta = { color = rgb(170, 200, 255), core = rgb(240, 245, 255), size = 16, rings = 2, crack = 7, debris = 8 },
	u7_gohan = { color = rgb(255, 245, 225), core = rgb(255, 255, 255), size = 15, rings = 1, crack = 8, debris = 10 },
	u7_trunks = { color = rgb(170, 225, 255), core = rgb(255, 255, 255), size = 12, rings = 0, crack = 0, debris = 3,
		slash = true },
	u7_broly = { color = rgb(90, 255, 120), core = rgb(220, 255, 220), size = 22, rings = 2, crack = 13, debris = 18 },
	u6_cabba = { color = rgb(150, 130, 255), core = rgb(235, 230, 255), size = 12, rings = 1, crack = 0, debris = 4 },
	u6_caulifla = { color = rgb(255, 90, 180), core = rgb(255, 230, 245), size = 13, rings = 2, crack = 0, debris = 5,
		afterimage = rgb(255, 150, 210) },
	u6_kale = { color = rgb(110, 255, 100), core = rgb(230, 255, 220), size = 19, rings = 1, crack = 11, debris = 14 },
	u6_kefla = { color = rgb(190, 255, 70), core = rgb(250, 255, 220), size = 17, rings = 2, crack = 6, debris = 10,
		afterimage = rgb(220, 255, 140) },
	u10_goku_black = { color = rgb(255, 80, 170), core = rgb(255, 225, 240), size = 12, rings = 0, crack = 0,
		debris = 2, slash = true },
}
M.DEFAULT = { color = rgb(255, 230, 150), core = rgb(255, 255, 255), size = 13, rings = 1, crack = 0, debris = 4 }

local function championId(character: Model): string?
	local pl = Players:GetPlayerFromCharacter(character)
	local id = (pl and pl:GetAttribute("Character")) or character:GetAttribute("Character")
		or character:GetAttribute("ChampionModel")
	return if type(id) == "string" then id else nil
end

-- a thin neon crescent swept across the hit point (sword or ki-blade cut)
local function slash(f: Instance, root: BasePart, pos: Vector3, color: Color3, core: Color3)
	local look = root.CFrame.LookVector
	local base = CFrame.lookAt(pos, pos + look)
	for i = -3, 3 do
		local seg = C.part(f, Vector3.new(0.25, 0.25, 2.2), if i == 0 then core else color, nil, 0.1)
		seg.CFrame = base * CFrame.Angles(0, 0, math.rad(-35)) * CFrame.new(i * 1.6, -math.abs(i) * 0.35, 0)
			* CFrame.Angles(0, math.rad(90), 0)
		C.tween(seg, 0.25, { Transparency = 1, Size = Vector3.new(0.05, 0.05, 3.2) })
	end
end

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local s = M.STYLES[championId(character) or ""] or M.DEFAULT
	local pos = if typeof(target) == "Vector3" then target else root.Position + root.CFrame.LookVector * 4
	local f = C.folder("SaiyanHeavy", 4)
	if s.afterimage then C.Afterimage(character, s.afterimage, 0.3, 0.4) end
	if s.slash then
		slash(f, root, pos, s.color, s.core)
	else
		local face = CFrame.lookAt(pos, pos + root.CFrame.LookVector) * CFrame.Angles(math.rad(90), 0, 0)
		C.Shockwave(f, face, 1, s.size * 0.6, s.core, 0.25, 0.3)
	end
	C.Shockwave(f, CFrame.new(pos), 2, s.size, s.color, 0.4)
	for i = 1, s.rings do
		task.delay(0.07 * i, function()
			C.Shockwave(f, CFrame.new(pos), 1, s.size * (1 + 0.35 * i), s.color, 0.35, 0.2)
		end)
	end
	if s.crack > 0 or s.debris > 0 then
		local res = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), C.rayParams({ f, character }))
		if res then
			if s.crack > 0 then C.GroundCrack(f, res.Position, s.crack, math.floor(s.crack), s.color, 2.5) end
			if s.debris > 0 then C.DebrisBurst(f, res.Position, s.debris, 24 + s.size, nil, 2) end
		end
	end
	-- onlookers feel big hits nearby; the striker's own camera is handled by their kit camera
	local cam = workspace.CurrentCamera
	if cam and character ~= Players.LocalPlayer.Character then
		local d = (cam.CFrame.Position - pos).Magnitude
		if d < 60 then C.CameraShake(0.25 * (s.size / 14) * (1 - d / 60), 0.25) end
	end
end

return M
