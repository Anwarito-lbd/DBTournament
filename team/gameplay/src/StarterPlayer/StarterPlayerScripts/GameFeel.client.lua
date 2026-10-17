-- LocalScript (v1.1): gameplay camera + game feel, built on db-animation's VFXCommon.
--  * Hit feedback: hitstop, camera shake, FOV punch, impact burst / impact frame on KO (only for hits I'm part of or near).
--    This is the ONLY hit-feedback path (fight plan P0): it runs on the server's confirmed Hit / GuardBreak / Parry
--    events, so feedback fires once per landed hit. Clip markers and AnimeStyle no longer add their own.
--  * Vanish (E): afterimage at the old spot, speed lines + whoosh for the vanisher.
--  * Power-up scream (hold C): 3 stages driven by server KiCharge -> aura grows, ground cracks + debris on each stage,
--    camera rumble, and a big Power Level readout with digit roll.
--  * Lock-on (L or middle mouse): nearest enemy in front; camera keeps them framed, attacks aim at them. Exposes
--    LocalPlayer attribute "LockTargetId" (client-local) for CombatInput.
--  * Energy drink (B handled in CombatInput): green burst + speed lines.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientAPI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientAPI"))
local VFX = ReplicatedStorage:WaitForChild("VFX", 10)
local C = VFX and require(VFX:WaitForChild("VFXCommon"))
local player = Players.LocalPlayer
if not C then
	warn("[GameFeel] VFXCommon missing")
	return
end

local function charOf(uid: any): Model?
	if typeof(uid) == "Instance" then
		return uid :: Model
	end -- dev bots
	local p = Players:GetPlayerByUserId(uid)
	return p and p.Character
end
local function rootOf(m: Model?): BasePart?
	return m and m:FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function fx(): Instance
	local f = workspace:FindFirstChild("GameFeelFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "GameFeelFX"
		f.Parent = workspace
	end
	return f
end

-- ===== hit feedback =====
local lastHeavyFrame = 0
-- CAMERA INTENSITY (2026-10-14): the FOV punch used to be a flat per-tier value, so a six-hit combo and a single
-- jab produced an identical camera. Tracking the combo lets the frame tighten as a string builds.
local COMBO_WINDOW = 1.2 -- seconds between hits for them to count as one string
local COMBO_FOV_STEP = 0.18 -- extra punch per additional hit, capped below
local combo, comboUntil = 0, 0
ClientAPI.onCombatEvent:Connect(function(kind, data)
	if kind == "Hit" then
		local vic, att = charOf(data[1]), charOf(data[2])
		local vr = rootOf(vic)
		if not vr then
			return
		end
		local mine = data[1] == player.UserId or data[2] == player.UserId
		local my = rootOf(player.Character)
		local dist = my and (my.Position - vr.Position).Magnitude or 999
		if not mine and dist > 60 then
			return
		end
		local kb, ko = data[4] or 0, data[5]
		local tier = if ko then "Ultimate" elseif kb >= 40 then "Heavy" elseif kb >= 15 then "Medium" else "Light"
		C.Hitstop(
			{ vic :: Model, att :: Model },
			if ko then "Finisher" elseif tier == "Heavy" then "Heavy" elseif tier == "Medium" then "Medium" else "Light"
		)
		local falloff = if mine then 1 else math.clamp(1 - dist / 60, 0, 1)
		C.CameraShake(C.IMPACT_TIERS[tier].Shake * falloff, 0.4)
		-- Escalating punch for hits I land. FOV only: C.FOVPunch drives the existing spring in VFXCommon, so this
		-- cannot fight the gameplay camera or the separate CFrame writer inside C.CameraShake.
		if mine then
			local now = os.clock()
			combo = if now < comboUntil then combo + 1 else 1
			comboUntil = now + COMBO_WINDOW
			C.FOVPunch(C.IMPACT_TIERS[tier].Fov * (1 + math.min(combo - 1, 6) * COMBO_FOV_STEP))
		end
		-- impact frames: max 1 / 1.5 s (photosensitivity rule in the plan)
		local allowFrame = (tier == "Ultimate" or tier == "Heavy") and os.clock() - lastHeavyFrame > 1.5
		if allowFrame then
			lastHeavyFrame = os.clock()
		end
		local pos = vr.Position
		local size = if tier == "Ultimate" then 6 elseif tier == "Heavy" then 4 elseif tier == "Medium" then 2.5 else 1.5
		C.Shockwave(fx(), CFrame.new(pos), 1, size * 2, Color3.fromRGB(255, 240, 200), 0.3)
		if allowFrame and mine then
			C.ImpactFrame("invert", C.IMPACT_TIERS[tier].Frames, { vic :: Model, att :: Model })
		end
		if tier ~= "Light" then
			local res = workspace:Raycast(pos, Vector3.new(0, -8, 0), C.rayParams({ vic :: Model, fx() }))
			if res then
				C.DebrisBurst(fx(), res.Position, if tier == "Medium" then 4 else 10, 30, nil, 2)
			end
		end
	elseif kind == "Vanish" then
		local m = charOf(data[1])
		if not m then
			return
		end
		C.Afterimage(m, Color3.fromRGB(200, 230, 255), 0.45, 0.35)
		local r = rootOf(m)
		if r then
			C.Shockwave(fx(), CFrame.new(r.Position), 1, 6, Color3.fromRGB(220, 240, 255), 0.25)
		end
		if data[1] == player.UserId then
			C.SpeedLines(0.25, Color3.new(1, 1, 1), 30)
			C.FOVPunch(6)
		end
	elseif kind == "GuardBreak" or kind == "Parry" then
		-- the guard shatters / the strike is turned aside: both fighters freeze, impact frame if I'm involved
		local a, b = charOf(data[1]), charOf(data[2])
		local subjects = {}
		for _, m in { a, b } do
			if m then
				table.insert(subjects, m)
			end
		end
		if #subjects == 0 then
			return
		end
		C.Hitstop(subjects, if kind == "GuardBreak" then "Heavy" else "Medium")
		if data[1] == player.UserId or data[2] == player.UserId then
			C.CameraShake(C.IMPACT_TIERS.Heavy.Shake * (if kind == "GuardBreak" then 1 else 0.6), 0.4)
			if os.clock() - lastHeavyFrame > 1.5 then
				lastHeavyFrame = os.clock()
				C.ImpactFrame("invert", 2, subjects)
			end
		end
		local r = rootOf(a)
		if r then
			C.Shockwave(fx(), CFrame.new(r.Position), 1, if kind == "GuardBreak" then 12 else 7, Color3.fromRGB(200, 230, 255), 0.3)
		end
	elseif kind == "Dodged" then
		local m = charOf(data[1])
		if m then
			C.Afterimage(m, Color3.fromRGB(230, 230, 255), 0.3, 0.4)
		end
	elseif kind == "EnergyDrink" then
		local m = charOf(data[1])
		local r = rootOf(m)
		if not r then
			return
		end
		C.Shockwave(fx(), CFrame.new(r.Position), 1, 10, Color3.fromRGB(120, 255, 140), 0.4)
		if data[1] == player.UserId then
			C.SpeedLines(0.6, Color3.fromRGB(170, 255, 180), 36)
			C.FOVPunch(8)
		end
	end
end)

-- ===== power-up scream: 3 stages =====
local gui = Instance.new("ScreenGui")
gui.Name = "PowerUpGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")
local pl = Instance.new("TextLabel")
pl.Name = "PowerReadout"
pl.AnchorPoint = Vector2.new(0.5, 0)
pl.Position = UDim2.fromScale(0.5, 0.14)
pl.Size = UDim2.fromOffset(560, 70)
pl.BackgroundTransparency = 1
pl.Font = Enum.Font.GothamBlack
pl.TextScaled = true
pl.TextColor3 = Color3.fromRGB(255, 220, 90)
pl.TextStrokeTransparency = 0
pl.TextStrokeColor3 = Color3.fromRGB(80, 30, 0)
pl.Visible = false
pl.Parent = gui
local st = pl:Clone()
st.Name = "StageLabel"
st.Position = UDim2.fromScale(0.5, 0.235)
st.Size = UDim2.fromOffset(420, 34)
st.TextColor3 = Color3.new(1, 1, 1)
st.Parent = gui
local STAGE_NAMES = { "STAGE 1  •  POWERING UP", "STAGE 2  •  RISING", "STAGE 3  •  MAX POWER" }
local function fmt(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
local aura, stage, shown = nil, 0, 0
local stageCap = (
	ReplicatedStorage.Shared:FindFirstChild("Config") and require(ReplicatedStorage.Shared.Config).KI_CHARGE_CAP
) or 0.5
local function formId(): string
	local f = player:GetAttribute("Form")
	return if type(f) == "string" and C.AURAS[f] then f else "Default"
end
RunService.Heartbeat:Connect(function(dt)
	local charging = player:GetAttribute("Charging") == true
	local ch = player.Character
	local target = (player:GetAttribute("PowerLevel") :: number?) or 0
	if charging and ch then
		local k = ((player:GetAttribute("KiCharge") :: number?) or 0) / stageCap
		local ns = if k >= 0.66 then 3 elseif k >= 0.33 then 2 else 1
		if not aura then
			aura = C.AuraEmitter(ch, formId(), { Scale = 1 })
			stage = 0
		end
		if ns ~= stage then
			stage = ns
			aura:SetIntensity(0.5 + 0.5 * ns)
			local r = rootOf(ch)
			if r then
				local res = workspace:Raycast(r.Position, Vector3.new(0, -10, 0), C.rayParams({ ch, fx() }))
				local g = if res then res.Position else r.Position - Vector3.new(0, 3, 0)
				C.GroundCrack(fx(), g, 3 + 3 * ns, 4 + 3 * ns, Color3.fromRGB(255, 230, 140), 2.5)
				C.DebrisBurst(fx(), g, 3 + 4 * ns, 18 + 8 * ns, nil, 2)
				C.Shockwave(fx(), CFrame.new(g), 2, 8 + 6 * ns, Color3.fromRGB(255, 230, 150), 0.4)
			end
			C.CameraShake(0.2 + 0.15 * ns, 0.4)
			C.FOVPunch(2 + 2 * ns)
			if ns == 3 then
				C.SpeedLines(0.5, Color3.fromRGB(255, 240, 180), 40)
			end
			st.Text = STAGE_NAMES[ns]
			ch:SetAttribute("Charging", true) -- AnimeStyle reads this for the angry/scream face
		end
		if ns == 3 then
			C.CameraShake(0.06, 0.1)
		end
		pl.Visible = true
		st.Visible = true
		shown += (target - shown) * math.min(1, dt * 6) -- digit roll
		pl.Text = "POWER LEVEL  " .. fmt(shown)
	else
		if aura then
			aura:Destroy()
			aura = nil
		end
		if stage > 0 and ch then
			ch:SetAttribute("Charging", nil)
		end
		stage = 0
		shown = target
		pl.Visible = false
		st.Visible = false
	end
end)
