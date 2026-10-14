--!nonstrict
-- PosePlayer (ModuleScript) — plays Dragon Block Z pose tables (poses/Goku.lua etc.).
-- Two paths:
--   1) Runtime procedural:  local h = PosePlayer.Play(character, clip, opts)  -> drives Motor6D.Transform each frame
--      opts: Speed (1), Loop (clip.looped), Weight (1, blends with current Transform), OnMarker(markerTable, keyframe, clipName),
--            Registry (table: "Module.Function" -> function(character, arg, marker)), OnFinished()
--      handle: h:Stop(fadeSeconds?), h.Playing, h.Time (frames)
--      NOTE: The Animator also writes Motor6D.Transform. Stop/lower conflicting AnimationTracks (same joints) while a
--      procedural clip runs, or prefer path 2 for production.
--   2) Asset pipeline:  PosePlayer.BuildKeyframeSequence(clip, name) -> KeyframeSequence (+ KeyframeMarkers for hit/vfx/sound)
--      In Studio: parent to ServerStorage/AnimSaves and publish with the Animation Editor, or for local testing use
--      KeyframeSequenceProvider:RegisterKeyframeSequence(kfs) -> temporary content id for an Animation.
local RunService = game:GetService("RunService")
local Shared = require(script.Parent:WaitForChild("Shared"))

local PosePlayer = {}

-- Ease name -> f(alpha) and -> Enum.PoseEasingStyle/Direction for KeyframeSequence export.
local EASE = {
	Linear = function(a) return a end,
	Constant = function(_) return 0 end, -- hold previous pose until next key
	Sine = function(a) return 0.5 - 0.5 * math.cos(math.pi * a) end,
	CubicIn = function(a) return a * a * a end,
	CubicOut = function(a) return 1 - (1 - a) ^ 3 end,
	QuadOut = function(a) return 1 - (1 - a) * (1 - a) end,
	BackOut = function(a) local c1 = 1.70158; local c3 = c1 + 1; return 1 + c3 * (a - 1) ^ 3 + c1 * (a - 1) ^ 2 end,
}
PosePlayer.EASE = EASE
local KFS_EASE = {
	Linear = {Enum.PoseEasingStyle.Linear, Enum.PoseEasingDirection.In},
	Constant = {Enum.PoseEasingStyle.Constant, Enum.PoseEasingDirection.In},
	Sine = {Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.InOut},
	CubicIn = {Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.In},
	CubicOut = {Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.Out},
	QuadOut = {Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.Out},
	BackOut = {Enum.PoseEasingStyle.Elastic, Enum.PoseEasingDirection.Out},
}

local function toCF(p)
	if not p then return CFrame.identity end
	local pos, rot = p.pos or {0, 0, 0}, p.rot or {0, 0, 0}
	return CFrame.new(pos[1], pos[2], pos[3]) * CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
end
PosePlayer.ToCFrame = toCF

-- Find Motor6Ds by joint name on an R15 rig.
function PosePlayer.GetMotors(character)
	local motors = {}
	for joint, partName in pairs(Shared.JOINT_PART) do
		local part = character:FindFirstChild(partName)
		local m = part and part:FindFirstChild(joint)
		if m and m:IsA("Motor6D") then motors[joint] = m end
	end
	return motors
end

-- Sample a clip at frame t -> {joint = CFrame}. Easing on key k applies to the segment ending at k (Roblox convention
-- is the opposite; we follow the data doc: "ease" describes how we ARRIVE at this keyframe).
function PosePlayer.Sample(clip, t)
	local kfs = clip.keyframes
	local n = #kfs
	if t <= kfs[1].t then
		local out = {}
		for _, j in ipairs(Shared.JOINTS) do out[j] = toCF(kfs[1].poses[j]) end
		return out
	end
	local a, b = kfs[n], kfs[n]
	for i = 1, n - 1 do
		if t >= kfs[i].t and t < kfs[i + 1].t then a, b = kfs[i], kfs[i + 1]; break end
	end
	local span = b.t - a.t
	local alpha = span > 0 and math.clamp((t - a.t) / span, 0, 1) or 1
	alpha = (EASE[b.ease] or EASE.Linear)(alpha)
	local out = {}
	for _, j in ipairs(Shared.JOINTS) do out[j] = toCF(a.poses[j]):Lerp(toCF(b.poses[j]), alpha) end
	return out
end

local function fireMarker(opts, character, mk, kf, clipName)
	if opts.OnMarker then task.spawn(opts.OnMarker, mk, kf, clipName) end
	if opts.Registry and mk.vfx then
		-- vfx = "A.B:arg;C.D:arg2" -> Registry["A.B"](character, "arg", mk)
		for call in string.gmatch(mk.vfx, "[^;]+") do
			local fname, arg = string.match(call, "^([%w_%.]+):?(.*)$")
			local fn = fname and opts.Registry[fname]
			if fn then task.spawn(fn, character, arg ~= "" and arg or nil, mk) end
		end
	end
end

function PosePlayer.Play(character, clip, opts)
	opts = opts or {}
	local motors = PosePlayer.GetMotors(character)
	local h = {Playing = true, Time = 0}
	local speed = opts.Speed or 1
	local loop = opts.Loop
	if loop == nil then loop = clip.looped end
	local weight = opts.Weight or 1
	local fps = clip.fps or 60
	local nextMarker = 1
	local conn
	-- Stepped runs before physics and after the Animator has stepped in most setups; we write Transform here.
	conn = RunService.Stepped:Connect(function(_, dt)
		if not character.Parent then h:Stop() return end
		local prevT = h.Time
		h.Time += dt * fps * speed
		-- markers crossed this frame
		local kfs = clip.keyframes
		while nextMarker <= #kfs and kfs[nextMarker].t <= h.Time do
			local kf = kfs[nextMarker]
			if kf.markers and kf.t >= prevT - 1e-6 then fireMarker(opts, character, kf.markers, kf, opts.Name) end
			nextMarker += 1
		end
		if h.Time >= clip.length then
			if loop then
				h.Time = h.Time % clip.length
				nextMarker = 1
			else
				h.Time = clip.length
			end
		end
		local pose = PosePlayer.Sample(clip, h.Time)
		for j, m in pairs(motors) do
			local cf = pose[j]
			m.Transform = weight >= 1 and cf or m.Transform:Lerp(cf, weight)
		end
		if not loop and h.Time >= clip.length then
			conn:Disconnect()
			h.Playing = false
			if opts.OnFinished then task.spawn(opts.OnFinished) end
		end
	end)
	function h:Stop(fade)
		if not h.Playing and not conn.Connected then return end
		conn:Disconnect()
		h.Playing = false
		if fade and fade > 0 then
			for _, m in pairs(motors) do
				local start = m.Transform
				task.spawn(function()
					local t0 = os.clock()
					while os.clock() - t0 < fade do
						m.Transform = start:Lerp(CFrame.identity, EASE.QuadOut((os.clock() - t0) / fade))
						RunService.Stepped:Wait()
					end
					m.Transform = CFrame.identity
				end)
			end
		else
			for _, m in pairs(motors) do m.Transform = CFrame.identity end
		end
	end
	return h
end

-- Build a KeyframeSequence (Studio / plugin / RegisterKeyframeSequence testing).
function PosePlayer.BuildKeyframeSequence(clip, name)
	local kfs = Instance.new("KeyframeSequence")
	kfs.Name = name or "DBZClip"
	kfs.Loop = clip.looped and true or false
	local okP, prio = pcall(function() return Enum.AnimationPriority[clip.priority] end)
	if okP and prio then kfs.Priority = prio end
	local fps = clip.fps or 60
	for idx, kf in ipairs(clip.keyframes) do
		-- Roblox Pose easing describes the segment FROM this key to the next, our data's ease describes arriving AT a key,
		-- so we take the next keyframe's ease.
		local nextKf = clip.keyframes[idx + 1]
		local k = Instance.new("Keyframe")
		k.Time = kf.t / fps
		local rootPose = Instance.new("Pose")
		rootPose.Name = "HumanoidRootPart"
		rootPose.Weight = 0
		rootPose.Parent = k
		local poseByPart = {HumanoidRootPart = rootPose}
		-- create in hierarchy order (parents first): JOINTS list is already ordered parent->child
		for _, joint in ipairs(Shared.JOINTS) do
			local partName = Shared.JOINT_PART[joint]
			local p = Instance.new("Pose")
			p.Name = partName
			p.CFrame = toCF(kf.poses[joint])
			local e = KFS_EASE[nextKf and nextKf.ease or "Linear"] or KFS_EASE.Linear
			p.EasingStyle, p.EasingDirection = e[1], e[2]
			p.Weight = 1
			poseByPart[partName] = p
		end
		for partName, p in pairs(poseByPart) do
			if partName ~= "HumanoidRootPart" then p.Parent = poseByPart[Shared.PART_PARENT[partName]] end
		end
		if kf.markers then
			for key, val in pairs(kf.markers) do
				local m = Instance.new("KeyframeMarker")
				m.Name = key
				if typeof(val) == "table" then
					local parts = {}
					for a, b in pairs(val) do table.insert(parts, a .. "=" .. tostring(b)) end
					m.Value = table.concat(parts, ",")
				else
					m.Value = tostring(val)
				end
				k:AddMarker(m)
			end
		end
		k.Parent = kfs
	end
	return kfs
end

return PosePlayer
