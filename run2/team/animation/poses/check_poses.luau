-- Sanity check for pose data. Run from this folder:  luau check_poses.luau
-- Checks: every clip has keyframes, frames strictly increasing, first t == 0, last t <= length, every keyframe has all
-- 15 R15 joints with pos/rot triples of finite numbers, known ease names, fps == 60, markers are tables of strings/tables.
local JOINTS = {"Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
	"LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle"}
local EASES = {Linear = true, Constant = true, Sine = true, CubicIn = true, CubicOut = true, QuadOut = true, BackOut = true}
local files = {
	{"Goku", require("./Goku")}, {"Vegeta", require("./Vegeta")}, {"Frieza", require("./Frieza")},
	{"Shared", require("./Shared").clips},
}
local errors, clipsChecked, keysChecked = 0, 0, 0
local function err(msg) errors += 1; print("ERROR: " .. msg) end
local function triple(v)
	if type(v) ~= "table" or #v ~= 3 then return false end
	for i = 1, 3 do if type(v[i]) ~= "number" or v[i] ~= v[i] or math.abs(v[i]) > 1e4 then return false end end
	return true
end
for _, entry in ipairs(files) do
	local hero, clips = entry[1], entry[2]
	for name, clip in pairs(clips) do
		clipsChecked += 1
		local id = hero .. "." .. name
		if clip.fps ~= 60 then err(id .. " fps ~= 60") end
		if type(clip.length) ~= "number" or clip.length <= 0 then err(id .. " bad length") end
		local kfs = clip.keyframes
		if type(kfs) ~= "table" or #kfs < 2 then err(id .. " needs >= 2 keyframes") continue end
		if kfs[1].t ~= 0 then err(id .. " first keyframe t ~= 0") end
		local last = -1
		for i, kf in ipairs(kfs) do
			keysChecked += 1
			if kf.t <= last then err(("%s kf%d t=%s not sorted/unique"):format(id, i, tostring(kf.t))) end
			last = kf.t
			if not EASES[kf.ease] then err(("%s kf%d unknown ease %s"):format(id, i, tostring(kf.ease))) end
			for _, j in ipairs(JOINTS) do
				local p = kf.poses[j]
				if not p then err(("%s kf%d missing joint %s"):format(id, i, j))
				elseif not triple(p.pos) or not triple(p.rot) then err(("%s kf%d joint %s bad pos/rot"):format(id, i, j)) end
			end
			local count = 0
			for _ in pairs(kf.poses) do count += 1 end
			if count ~= #JOINTS then err(("%s kf%d has %d joints (expected %d)"):format(id, i, count, #JOINTS)) end
			if kf.markers ~= nil and type(kf.markers) ~= "table" then err(id .. " markers not table") end
		end
		if last > clip.length then err(id .. " last keyframe beyond length") end
	end
end
print(("checked %d clips, %d keyframes, %d errors"):format(clipsChecked, keysChecked, errors))
if errors > 0 then error("pose sanity check failed") end
