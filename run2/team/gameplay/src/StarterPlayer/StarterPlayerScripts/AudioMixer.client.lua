--!strict
-- LocalScript: StarterPlayer.StarterPlayerScripts.AudioMixer (WP-AUD-1)
-- SoundGroup routing, battle dynamic ducking, and active sound budgeting (<= 24 sounds).
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_CONCURRENT_SOUNDS = 24
local activeSounds: { Sound } = {}

-- SoundGroup Architecture
local function getOrCreateGroup(name: string, parentGroup: SoundGroup?): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local sg = Instance.new("SoundGroup")
	sg.Name = name
	sg.Volume = 1.0
	sg.Parent = parentGroup or SoundService
	return sg
end

local MasterGroup = getOrCreateGroup("Master", nil)
local BGMGroup = getOrCreateGroup("BGM", MasterGroup)
local SFXGroup = getOrCreateGroup("SFX", MasterGroup)
local VoiceGroup = getOrCreateGroup("Voice", MasterGroup)
local AmbienceGroup = getOrCreateGroup("Ambience", MasterGroup)

local AudioMixer = {}

local bgmBaseVolume = 0.8
local currentDucking = 1.0

-- Dynamic Ducking Engine
-- Target fraction: e.g. 0.4 = ducks BGM by 60%
function AudioMixer.duckBGM(fraction: number, duration: number)
	currentDucking = math.clamp(fraction, 0.1, 1.0)
	local tw = TweenService:Create(BGMGroup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Volume = bgmBaseVolume * currentDucking,
	})
	tw:Play()

	task.delay(duration, function()
		if currentDucking == fraction then
			currentDucking = 1.0
			local restore =
				TweenService:Create(BGMGroup, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Volume = bgmBaseVolume,
				})
			restore:Play()
		end
	end)
end

-- Sound Budget Enforcer: Prunes oldest or lowest-priority sounds if count > 24
function AudioMixer.trackSound(sound: Sound)
	table.insert(activeSounds, sound)

	if #activeSounds > MAX_CONCURRENT_SOUNDS then
		local oldest = table.remove(activeSounds, 1)
		if oldest and oldest.Parent and oldest.IsPlaying then
			oldest:Stop()
			oldest:Destroy()
		end
	end

	sound.Ended:Once(function()
		local idx = table.find(activeSounds, sound)
		if idx then
			table.remove(activeSounds, idx)
		end
	end)
end

-- Listen to Remotes for battle and dialogue ducking cues
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)

-- When Announcer talks, duck BGM by 40%
task.spawn(function()
	local announcerRemote = Remotes and Remotes:WaitForChild("AnnouncerEvent", 15)
	if announcerRemote and announcerRemote:IsA("RemoteEvent") then
		announcerRemote.OnClientEvent:Connect(function(data)
			local dur = (typeof(data) == "table" and data.duration) or 3.5
			AudioMixer.duckBGM(0.6, dur)
		end)
	end
end)

-- When heavy Ultimate or Beam Struggle occurs, duck BGM by 65% for huge hit feel
task.spawn(function()
	local vfxRemote = Remotes and Remotes:WaitForChild("PlayVFX", 15)
	if vfxRemote and vfxRemote:IsA("RemoteEvent") then
		vfxRemote.OnClientEvent:Connect(function(kind)
			if kind == "FinalExplosion" or kind == "Hakai" or kind == "SpiritBomb" then
				AudioMixer.duckBGM(0.35, 2.5)
			end
		end)
	end
end)

return AudioMixer
