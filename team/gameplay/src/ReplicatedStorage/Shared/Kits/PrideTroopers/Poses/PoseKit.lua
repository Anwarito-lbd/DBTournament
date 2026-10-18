--!nonstrict
-- PoseKit (Pride Troopers kit, not a clip set): builds clips in the team/animation/poses format (team/animation/README.md)
-- from a few joint overrides, so each set in this folder only states what makes its fighter's pose theirs.
-- An override table maps a joint to {rx, ry, rz} degrees (joint-local, the generated files' convention: arm/leg rx > 0
-- swings forward, arm rz raises outward and is negative on the left side); Root takes a position {x, y, z} instead.
-- Joints left out stay at rest. Numbers are design values: tune them in Studio. No markers: the kit's VFX play from
-- the server's move events, never from clips.
local PoseKit = {}

PoseKit.JOINTS = {
	"Root",
	"Waist",
	"Neck",
	"LeftShoulder",
	"LeftElbow",
	"LeftWrist",
	"RightShoulder",
	"RightElbow",
	"RightWrist",
	"LeftHip",
	"LeftKnee",
	"LeftAnkle",
	"RightHip",
	"RightKnee",
	"RightAnkle",
}

-- body pieces several troopers share
PoseKit.CROSSED_ARMS = { -- the same fold as Vegeta's Idle_PridefulCross
	LeftShoulder = { 100, -50, -8 },
	LeftElbow = { 170, -30, 0 },
	RightShoulder = { 80, -55, 12 },
	RightElbow = { 205, -30, 0 },
}
PoseKit.PLANTED = {
	LeftHip = { 6, 0, -8 },
	LeftKnee = { -10, 0, 0 },
	LeftAnkle = { 4, 0, 0 },
	RightHip = { -4, 0, 8 },
	RightKnee = { -8, 0, 0 },
	RightAnkle = { 4, 0, 0 },
}
PoseKit.WIDE_STANCE = {
	LeftHip = { 15, 0, -25 },
	LeftKnee = { -50, 0, 0 },
	LeftAnkle = { 10, 0, 0 },
	RightHip = { 15, 0, 25 },
	RightKnee = { -50, 0, 0 },
	RightAnkle = { 10, 0, 0 },
}

-- merge override tables left to right (later ones win)
function PoseKit.with(...: any): any
	local out = {}
	for _, t in { ... } do
		for k, v in t do
			out[k] = v
		end
	end
	return out
end

-- a full 15-joint pose from an override table
function PoseKit.pose(over: any): any
	local p = {}
	for _, j in PoseKit.JOINTS do
		local v = over[j]
		if j == "Root" then
			p[j] = { pos = v or { 0, 0, 0 }, rot = { 0, 0, 0 } }
		else
			p[j] = { pos = { 0, 0, 0 }, rot = v or { 0, 0, 0 } }
		end
	end
	return p
end

-- clip(length, looped, priority, { {t, ease, overrides}, ... }) in frames at 60 fps
function PoseKit.clip(length: number, looped: boolean, priority: string, keys: any): any
	local kfs = {}
	for _, k in keys do
		table.insert(kfs, { t = k[1], ease = k[2], markers = nil, poses = PoseKit.pose(k[3]) })
	end
	return { fps = 60, length = length, looped = looped, priority = priority, keyframes = kfs }
end

-- a looped hold with a slow breathing bob of the Root (idles)
function PoseKit.hold(over: any, length: number, priority: string, bob: number?): any
	local r = over.Root or { 0, 0, 0 }
	local low = PoseKit.with(over, { Root = { r[1], r[2] - (bob or 0.04), r[3] } })
	return PoseKit.clip(
		length,
		true,
		priority,
		{ { 0, "Sine", over }, { length / 2, "Sine", low }, { length, "Sine", over } }
	)
end

-- a Justice Pose: snap in, hold through the server's 1 s pose lock (60 frames), ease back to rest
function PoseKit.justice(over: any): any
	return PoseKit.clip(72, false, "Action4", {
		{ 0, "Sine", {} },
		{ 8, "BackOut", over },
		{ 60, "Constant", over },
		{ 72, "QuadOut", {} },
	})
end

-- a set falls back to `parent` (another set, or the shared neutral clips) for clips it does not define
function PoseKit.set(clips: any, parent: any): any
	if parent then
		setmetatable(clips, { __index = parent })
	end
	return clips
end

-- the shared neutral clips (ReplicatedStorage.Poses.Shared), nil outside Roblox
function PoseKit.sharedClips(): any
	local folder = game and game:GetService("ReplicatedStorage"):FindFirstChild("Poses")
	local m = folder and folder:FindFirstChild("Shared")
	local ok, res = pcall(function()
		return m and require(m)
	end)
	return if ok and type(res) == "table" then res.clips else nil
end

return PoseKit
