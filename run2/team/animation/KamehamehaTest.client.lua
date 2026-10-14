-- LocalScript (StarterPlayerScripts). Requires Folder ReplicatedStorage.VFX with all VFX ModuleScripts.
-- Solo visual test. Clients ALWAYS pass ArenaDamage = false: arena damage is server-only
-- (ServerScriptService.ArenaDamage.DamageAt, called by db-gameplay's server on validated hits).
-- Keys:
--   K Kamehameha   F Final Flash   P Special Beam Cannon   B Death Ball   J Jiren Power Impact   T Hit Time Skip
--   hold G charge transform (release <35% cancels)   H one-shot transform   Q cycle form preset
--   V Barrier (17) [press again: hit ripple, X: shatter]
--   N Beam Struggle vs nearest other player/dummy ([ ] push, Enter end A wins, Backspace tie)
--   1 Instant Transmission to mouse   2 Spirit Bomb   3 Galick Gun   4 Big Bang   5 Final Explosion
--   6 Death Beam (x5 rapid)   7 Destructo Disc (split 3)   8 Nova Strike   9 MUI Rush on nearest   0 Black Nova
--   U Beast SBC   L Moro Absorb nearest   O Moro Planet Drain   C Ultra Ego growth (+100 dmg tick)
--   v5: F1/F2/F3 quality Low/Medium/High   F4 aura test   F5 impact-frame test   F6 Hakai   F7 Kaioken   F8 Solar Flare
--   Z Fusion Dance with nearest   Y Potara with nearest   M Merged team beam   R Sync Rush   E Energy Gift to nearest
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local VFX = RS:WaitForChild("VFX")
local function req(n)
	return require(VFX:WaitForChild(n))
end
local Kame, FinalFlash, SBC, DeathBall =
	req("KamehamehaVFX"), req("FinalFlashVFX"), req("SpecialBeamCannonVFX"), req("DeathBallVFX")
local PowerImpact, TimeSkip, Transform = req("PowerImpactVFX"), req("TimeSkipVFX"), req("TransformationVFX")
local IT, SpiritBomb, Galick, BigBang =
	req("InstantTransmissionVFX"), req("SpiritBombVFX"), req("GalickGunVFX"), req("BigBangAttackVFX")
local FinalExplosion, DeathBeam, Disc, Nova =
	req("FinalExplosionVFX"), req("DeathBeamVFX"), req("DestructoDiscVFX"), req("NovaStrikeVFX")
local MUIRush, BlackFrieza, BeastSBC = req("MUIRushVFX"), req("BlackFriezaVFX"), req("BeastSBCVFX")
local MoroAbsorb, MoroDrain = req("MoroAbsorbVFX"), req("MoroPlanetDrainVFX")
local Common = req("VFXCommon")
local auraKeys, auraIdx, auraHandle =
	{
		"SSJ",
		"SSJ2",
		"SSJ3",
		"SSG",
		"SSB",
		"SSBEvolved",
		"UISign",
		"MUI",
		"UltraEgo",
		"BeastGohan",
		"GoldenFrieza",
		"FriezaBlack",
	}, 0, nil
local Fusion, Team, Struggle, Barrier =
	req("FusionVFX"), req("TeamComboVFX"), req("BeamStruggleVFX"), req("Android17BarrierVFX")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
-- Config.FORMS ids (db-gameplay) first, then VFX-only presets
local forms = {
	"KaioKen",
	"SuperSaiyan",
	"SuperSaiyan2",
	"SuperSaiyan3",
	"Ultimate",
	"Golden",
	"SuperSaiyanGod",
	"SuperSaiyanBlue",
	"SSBEvolved",
	"Legendary",
	"UltraInstinctSign",
	"UltraInstinct",
	"UltraEgo",
	"BeastGohan",
	"FriezaFullPower",
	"FriezaBlack",
	"KeflaPotara",
	"MoroAwakened",
	"JirenFullPower",
	"ToppoGoD",
}
local ueGrowth = nil
local formIndex = 1
local charging, barrier, struggle = nil, nil, nil
local function C_merge(a, b)
	local t = table.clone(a)
	for k, v in pairs(b) do
		t[k] = v
	end
	return t
end
local base = {
	ArenaDamage = false,
	OnHit = function(pos, hit)
		print("VFX hit", hit and hit:GetFullName(), pos)
	end,
}

-- nearest other Humanoid model (players or test dummies in workspace)
local function nearest(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	local best, bd = nil, math.huge
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Humanoid") and m.Parent ~= char and m.Parent:FindFirstChild("HumanoidRootPart") then
			local d = (m.Parent.HumanoidRootPart.Position - root.Position).Magnitude
			if d < bd then
				best, bd = m.Parent, d
			end
		end
	end
	return best
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local k = input.KeyCode
	local target = mouse.Hit.Position
	if k == Enum.KeyCode.K then
		Kame.Play(char, target, base)
	elseif k == Enum.KeyCode.F then
		FinalFlash.Play(char, target, base)
	elseif k == Enum.KeyCode.P then
		SBC.Play(char, target, base)
	elseif k == Enum.KeyCode.B then
		DeathBall.Play(char, target, base)
	elseif k == Enum.KeyCode.J then
		PowerImpact.Play(char, target, base)
	elseif k == Enum.KeyCode.T then
		TimeSkip.Play(char, target, base)
	elseif k == Enum.KeyCode.G and not charging then
		charging = Transform.Start(char, forms[formIndex])
	elseif k == Enum.KeyCode.H then
		Transform.Play(char, forms[formIndex])
	elseif k == Enum.KeyCode.Q then
		formIndex = formIndex % #forms + 1
		print("Form:", forms[formIndex])
	elseif k == Enum.KeyCode.V then
		if barrier and barrier.Active then
			barrier:Hit(target)
		else
			barrier = Barrier.Start(char, { Duration = 6 })
		end
	elseif k == Enum.KeyCode.X and barrier then
		barrier:Shatter()
	elseif k == Enum.KeyCode.N then
		local other = nearest(char)
		if other then
			struggle = Struggle.Start(char, other, base)
		end
	elseif k == Enum.KeyCode.LeftBracket and struggle then
		struggle:Push("A", 0.15)
	elseif k == Enum.KeyCode.RightBracket and struggle then
		struggle:Push("B", 0.15)
	elseif k == Enum.KeyCode.Return and struggle then
		struggle:End("A")
		struggle = nil
	elseif k == Enum.KeyCode.Backspace and struggle then
		struggle:End(nil)
		struggle = nil
	elseif k == Enum.KeyCode.One then
		IT.Play(char, target)
	elseif k == Enum.KeyCode.Two then
		SpiritBomb.Play(char, target, base)
	elseif k == Enum.KeyCode.Three then
		Galick.Play(char, target, base)
	elseif k == Enum.KeyCode.Four then
		BigBang.Play(char, target, base)
	elseif k == Enum.KeyCode.Five then
		FinalExplosion.Play(char, base)
	elseif k == Enum.KeyCode.Six then
		DeathBeam.Rapid(char, target, 5, base)
	elseif k == Enum.KeyCode.Seven then
		Disc.Play(char, nearest(char) or target, C_merge(base, { Split = 3 }))
	elseif k == Enum.KeyCode.Eight then
		Nova.Play(char, target, base)
	elseif k == Enum.KeyCode.Nine then
		local o = nearest(char)
		if o then
			MUIRush.Play(char, o, base)
		end
	elseif k == Enum.KeyCode.Zero then
		BlackFrieza.Play(char, target, base)
	elseif k == Enum.KeyCode.U then
		BeastSBC.Play(char, target, base)
	elseif k == Enum.KeyCode.L then
		local o = nearest(char)
		if o then
			MoroAbsorb.Play(char, o)
		end
	elseif k == Enum.KeyCode.O then
		local o = nearest(char)
		MoroDrain.Play(char, C_merge(base, { Victims = o and { o } or nil }))
	elseif k == Enum.KeyCode.C then
		ueGrowth = ueGrowth
			or Transform.UltraEgoGrowth(char, {
				OnDamageGrow = function(frac)
					print("UE growth", frac)
				end,
			})
		ueGrowth:Damaged(100, 1000)
	elseif k == Enum.KeyCode.F1 then
		Common.SetQuality(1)
		print("Quality Low")
	elseif k == Enum.KeyCode.F2 then
		Common.SetQuality(2)
		print("Quality Medium")
	elseif k == Enum.KeyCode.F3 then
		Common.SetQuality(3)
		print("Quality High")
	elseif k == Enum.KeyCode.F4 then
		if auraHandle then
			auraHandle:Destroy()
		end
		auraIdx = auraIdx % #auraKeys + 1
		auraHandle = Common.AuraEmitter(char, auraKeys[auraIdx])
		auraHandle:Burst(30)
		print("Aura:", auraKeys[auraIdx])
	elseif k == Enum.KeyCode.F5 then
		Common.ImpactFrame("invert", 3, { char })
		Common.FOVPunch(12)
		Common.CameraShake(0.8)
		Common.SpeedLines(0.4)
	elseif k == Enum.KeyCode.F6 then
		local Hakai = req("HakaiVFX")
		Hakai.Play(char, mouse.Hit.Position, base)
	elseif k == Enum.KeyCode.F7 then
		local Kaioken = req("KaiokenVFX")
		Kaioken.Play(char, C_merge(base, { Multiplier = 10 }))
	elseif k == Enum.KeyCode.F8 then
		local SolarFlare = req("SolarFlareVFX")
		SolarFlare.Play(char, base)
	elseif k == Enum.KeyCode.Z then
		local o = nearest(char)
		if o then
			Fusion.Dance(char, o, {
				OnFused = function(a, b)
					print("Fused", a.Name, b.Name)
				end,
			})
		end
	elseif k == Enum.KeyCode.Y then
		local o = nearest(char)
		if o then
			Fusion.Potara(char, o, {
				OnFused = function(a, b)
					print("Potara", a.Name, b.Name)
				end,
			})
		end
	elseif k == Enum.KeyCode.M then
		local o = nearest(char)
		Team.MergedBeam(o and { char, o } or { char }, target, base)
	elseif k == Enum.KeyCode.R then
		local o = nearest(char)
		if o then
			Team.SyncRush({ char }, o, base)
		end
	elseif k == Enum.KeyCode.E then
		local o = nearest(char)
		if o then
			Team.EnergyGift(char, o, base)
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.G and charging then
		charging:Stop(true)
		charging = nil
	end
end)

-- Multiplayer flow:
--   client: Remotes.RequestMove:FireServer("FinalFlash", target)
--   server (db-gameplay): validate ki/cooldown/level -> resolve hit -> damage ->
--           require(ServerScriptService.ArenaDamage).DamageAt(hitPos, radius, power)
--           -> Remotes.PlayVFX:FireAllClients("FinalFlash", char, target)
--   clients: Module.Play(char, target, {ArenaDamage = false})
