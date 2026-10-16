--!strict
-- ModuleScript: ReplicatedStorage.Shared.ShotLibrary  (v10; client-side camera grammar for Legendary Episodes)
-- Anime-style compositions recreated IN-ENGINE with the game's own actors (no footage, frames or audio from the show):
-- establishing wides, push-ins, over-the-shoulder dialogue, low-angle hero reveals, sky drops, smash zooms, Dutch tilts,
-- split-screen beam clashes, charge orbits and white-outs. Each move is `(beat) -> (CFrame?, tweenTime?)` so it plugs
-- straight into CutsceneDirector (opts.shots); moves that animate the camera themselves return nil.
-- ShotLibrary.build(ctx) where ctx = {
--   subject: (role: string) -> CFrame?   -- actor root CFrame ("lead" | "ally" | "boss" | "spar"), nil if missing
--   anchor: CFrame                        -- arena centre (role "anchor")
--   fx: (name: string, beat: any, pos: Vector3) -> ()  -- impactFrame / shake / speedLines / whiteOut / meteor ...
--   alive: () -> boolean                  -- false once the cinematic stopped (ends orbit loops)
-- }
local RunService = game:GetService("RunService")
local ShotLibrary = {}

local UP = Vector3.yAxis

local function flatLook(cf: CFrame): Vector3
	local l = cf.LookVector
	local f = Vector3.new(l.X, 0, l.Z)
	return if f.Magnitude > 0.01 then f.Unit else Vector3.zAxis
end

function ShotLibrary.build(ctx: any): { [string]: (any) -> (CFrame?, number?) }
	local function where(role: string?): CFrame
		if role == nil or role == "anchor" then return ctx.anchor end
		return ctx.subject(role) or ctx.anchor
	end
	local function runFx(beat: any, pos: Vector3)
		for _, name in beat.fx or {} do
			task.spawn(ctx.fx, name, beat, pos)
		end
	end
	local function other(role: string?): string
		return if role == "lead" then "ally" else "lead"
	end

	local S: { [string]: (any) -> (CFrame?, number?) } = {}

	-- wide, high, slow: the place before the people
	S.establishingWide = function(beat)
		local a = where(beat.subject)
		runFx(beat, a.Position)
		local focus = a.Position + flatLook(a) * -20 + UP * 4
		return CFrame.lookAt(a.Position + a.RightVector * 70 + UP * 42 + flatLook(a) * 95, focus), 2.4
	end

	-- slow push toward the pod crater / threat behind the arena centre
	S.pushIn = function(beat)
		local a = where(beat.subject)
		runFx(beat, a.Position)
		local crater = a.Position - flatLook(a) * 52
		return CFrame.lookAt(a.Position + a.RightVector * 18 + UP * 10 + flatLook(a) * 30, crater + UP * 3), (beat.duration or 3) * 0.9
	end

	-- behind the listener's shoulder, framing the speaker
	S.overShoulder = function(beat)
		local s = where(beat.subject).Position
		local o = where(other(beat.subject)).Position
		local d = s - o
		local dir = if d.Magnitude > 0.1 then d.Unit else Vector3.zAxis
		local right = dir:Cross(UP)
		right = if right.Magnitude > 0.01 then right.Unit else Vector3.xAxis
		runFx(beat, s)
		return CFrame.lookAt(o - dir * 6 + right * 2.6 + UP * 2.8, s + UP * 1.8), 0.9
	end

	-- camera near the ground looking up: power, menace
	S.lowAngleReveal = function(beat)
		local cf = where(beat.subject)
		local p = cf.Position
		runFx(beat, p)
		return CFrame.lookAt(p + flatLook(cf) * 8 + cf.RightVector * 2 + UP * -1.8, p + UP * 4.5), 1.4
	end

	-- look up from the ground at a streak falling onto the subject's mark (client meteor fx sells the landing)
	S.skyDrop = function(beat)
		local cf = where(beat.subject)
		local p = cf.Position
		runFx(beat, p)
		task.spawn(ctx.fx, "meteor", beat, p)
		return CFrame.lookAt(p + flatLook(cf) * 34 + cf.RightVector * 10 + UP * 3, p + UP * 26), 0.5
	end

	-- instant snap into a tight face shot (pairs with impactFrame + shake)
	S.smashZoom = function(beat)
		local cf = where(beat.subject)
		local p = cf.Position
		runFx(beat, p)
		return CFrame.lookAt(p + flatLook(cf) * 4.5 + UP * 2.3, p + UP * 2.1), 0.12
	end

	-- tilted horizon: unease
	S.dutchTilt = function(beat)
		local cf = where(beat.subject)
		local p = cf.Position
		runFx(beat, p)
		local cam = CFrame.lookAt(p + flatLook(cf) * 12 + cf.RightVector * 5 + UP * 3, p + UP * 2)
		return cam * CFrame.Angles(0, 0, math.rad(14)), 0.8
	end

	-- profile view square-on between the lead and the subject: the beam-clash frame
	S.splitClash = function(beat)
		local a = where("lead").Position
		local b = where(beat.subject).Position
		local mid = (a + b) / 2
		local d = b - a
		local dir = if d.Magnitude > 0.1 then d.Unit else Vector3.zAxis
		local side = dir:Cross(UP)
		side = if side.Magnitude > 0.01 then side.Unit else Vector3.xAxis
		runFx(beat, mid)
		return CFrame.lookAt(mid + side * (math.max(24, d.Magnitude * 0.9)) + UP * 5, mid + UP * 2), 0.6
	end

	-- orbit the subject while energy builds; animates the camera itself for the beat's duration
	S.orbitCharge = function(beat)
		local cf = where(beat.subject)
		local p = cf.Position + UP * 2.5
		runFx(beat, p)
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		local t0, dur = os.clock(), beat.duration or 2.4
		local base = math.atan2(flatLook(cf).Z, flatLook(cf).X)
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local k = (os.clock() - t0) / dur
			if k >= 1 or not ctx.alive() then conn:Disconnect(); return end
			local ang = base + k * math.rad(110)
			local r = 13 - k * 4
			cam.CFrame = CFrame.lookAt(p + Vector3.new(math.cos(ang) * r, 1.5 + k * 2, math.sin(ang) * r), p)
		end)
		return nil, nil
	end

	-- medium shot that the whiteOut fx floods to white (finisher impact)
	S.whiteOut = function(beat)
		local cf = where(beat.subject)
		local p = cf.Position
		runFx(beat, p)
		return CFrame.lookAt(p + flatLook(cf) * 16 + cf.RightVector * 6 + UP * 5, p + UP * 2), 0.3
	end

	return S
end

return ShotLibrary
