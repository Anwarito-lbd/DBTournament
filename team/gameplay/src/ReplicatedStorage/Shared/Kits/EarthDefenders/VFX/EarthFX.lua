--!nonstrict
-- EarthFX: shared helpers for the Earth defenders' kit effects (Kits/EarthDefenders/VFX). Not an effect itself:
-- the effect modules next to it require it by path. Client visuals only; nothing here touches combat or the arena.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))

local E = {}
E.C = C

function E.rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- the champion id on a character (same lookup as VFXRouter)
function E.championId(character: Model): string?
	local pl = Players:GetPlayerFromCharacter(character)
	local id = (pl and pl:GetAttribute("Character")) or character:GetAttribute("Character")
		or character:GetAttribute("ChampionModel")
	return if type(id) == "string" then id else nil
end

-- a world position for whatever the server sent as the target (Vector3, part or model), else a point ahead
function E.targetPos(character: Model, target: any, ahead: number?): Vector3?
	if typeof(target) == "Vector3" then return target end
	if typeof(target) == "Instance" then
		if target:IsA("Model") then return target:GetPivot().Position end
		if target:IsA("BasePart") then return target.Position end
	end
	local root = C.root(character)
	return root and root.Position + root.CFrame.LookVector * (ahead or 40)
end

-- onlookers feel a hit by distance; the caster's own kick comes from the kit's cameras entry
function E.shakeNear(pos: Vector3, intensity: number, reach: number?)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local k = 1 - math.clamp((cam.CFrame.Position - pos).Magnitude / (reach or 120), 0, 1)
	if k > 0 then C.CameraShake(intensity * k, 0.4) end
end

-- the ground point under pos (nil over the void)
function E.ground(pos: Vector3, exclude: { Instance }): Vector3?
	local res = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -20, 0), C.rayParams(exclude))
	return res and res.Position
end

-- a glowing sphere flown from `from` to `to` in its own thread; onArrive(to) runs when it lands.
-- o = {size, color, core, speed, arc? (studs of lift at mid-flight)}
function E.orb(folder: Instance, from: Vector3, to: Vector3, o: any, onArrive: ((Vector3) -> ())?)
	task.spawn(function()
		local ball = C.part(folder, Vector3.one * o.size, o.core, Enum.PartType.Ball)
		local shell = C.part(folder, Vector3.one * o.size * 1.7, o.color, Enum.PartType.Ball, 0.55)
		C.light(ball, o.color, o.size * 4, 3)
		local life = math.max((to - from).Magnitude / o.speed, 0.05)
		local t0 = os.clock()
		while true do
			local k = math.min(1, (os.clock() - t0) / life)
			local p = from:Lerp(to, k) + Vector3.new(0, math.sin(k * math.pi) * (o.arc or 0), 0)
			ball.Position, shell.Position = p, p
			if k >= 1 then break end
			RunService.Heartbeat:Wait()
		end
		ball:Destroy()
		shell:Destroy()
		if onArrive then onArrive(to) end
	end)
end

-- a burst sized in studs: flash sphere, two rings, ground crack (crack 0 = none), sparks and a distance shake
function E.burst(folder: Instance, pos: Vector3, size: number, color: Color3, core: Color3, crack: number?, shake: number?)
	local boom = C.part(folder, Vector3.one * 2, core, Enum.PartType.Ball)
	boom.Position = pos
	C.tween(boom, 0.4, { Size = Vector3.one * size, Transparency = 1, Color = color })
	C.light(boom, color, size * 2, 6)
	C.Shockwave(folder, CFrame.new(pos), 2, size * 1.6, color, 0.45)
	local a = C.worldAttachment(pos)
	local sparks = C.emitter(a, core, color, {
		Rate = 0,
		Lifetime = NumberRange.new(0.3, 0.7),
		Speed = NumberRange.new(20, 45),
		Size = NumberSequence.new(1.2, 0),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 4,
	})
	sparks:Emit(C.q(30))
	game:GetService("Debris"):AddItem(a, 1.2)
	if crack and crack > 0 then
		local g = E.ground(pos, { folder })
		if g then C.GroundCrack(folder, g, crack, math.floor(6 + crack), color, 2.5) end
	end
	E.shakeNear(pos, shake or 0.4)
end

return E
