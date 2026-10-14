-- LocalScript (v1.2): Training camps client. Area banner + XP rate, Lighting presets per area (db-map TrainingAreas presets),
-- Gravity Room slider (10x-100x), King Kai "Catch Bubbles" + Whis drill HUD and inputs (E = dodge, F = counter).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local UIKit = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIKit"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
-- v8 (lead-authorized, see CHANGES.md): TrainingRooms remotes via ClientAPI (StartDrill / SetGravity / DrillUpdate)
local ClientAPI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientAPI"))
local _ = Remotes
local STEPS = { 1, 10, 50, 100, 150, 300, 500 } -- server accepts console steps only
local function snap(v: number): number
	local best = STEPS[1]
	for _, s in STEPS do
		if math.abs(s - v) < math.abs(best - v) then
			best = s
		end
	end
	return best
end
local player = Players.LocalPlayer

local NAMES = {
	TrainingHub = "Training Hub",
	HyperbolicTimeChamber = "Hyperbolic Time Chamber",
	GravityRoom = "Gravity Room (Capsule Corp.)",
	KingKaiPlanet = "King Kai's Planet",
	WhisGround = "Beerus' Planet - Whis Training",
	Shop = "Capsule Corp. Store",
}
local gui = UIKit.gui("TrainingUI", 15)
local banner =
	UIKit.label(gui, "", UDim2.new(0, 600, 0, 34), UDim2.new(0.5, -300, 0, 70), 26, Color3.fromRGB(150, 220, 255))
banner.TextStrokeTransparency = 0
local sub = UIKit.label(gui, "", UDim2.new(0, 600, 0, 22), UDim2.new(0.5, -300, 0, 104), 17, Color3.new(1, 1, 1))
sub.TextStrokeTransparency = 0
local big = UIKit.label(gui, "", UDim2.new(0, 700, 0, 60), UDim2.new(0.5, -350, 0.32, 0), 40, UIKit.GOLD)
big.TextStrokeTransparency = 0
local actBtn =
	UIKit.button(gui, "", UDim2.new(0, 220, 0, 40), UDim2.new(0.5, -110, 1, -150), Color3.fromRGB(40, 120, 200))
actBtn.Visible = false

-- gravity slider
local slider = UIKit.frame(gui, UDim2.new(0, 420, 0, 70), UDim2.new(0.5, -210, 1, -160), UIKit.DARK, 0.1)
slider.Visible = false
local sLbl =
	UIKit.label(slider, "GRAVITY 10x", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 4), 20, Color3.fromRGB(255, 80, 80))
local track = UIKit.frame(slider, UDim2.new(1, -40, 0, 10), UDim2.new(0, 20, 0, 44), Color3.fromRGB(60, 60, 80), 0)
local knob = UIKit.frame(track, UDim2.new(0, 18, 0, 26), UDim2.new(0, -9, 0.5, -13), Color3.fromRGB(255, 60, 60), 0)
local G_MIN, G_MAX = 10, 100
local g = 10
local function setG(v: number, send: boolean)
	g = math.clamp(math.floor(v + 0.5), G_MIN, G_MAX)
	local k = (g - G_MIN) / (G_MAX - G_MIN)
	knob.Position = UDim2.new(k, -9, 0.5, -13)
	sLbl.Text = ("GRAVITY %dx   •   XP x%s"):format(g, tostring(player:GetAttribute("TrainingXPMult") or "?"))
	if send then
		ClientAPI.setGravity(snap(g))
	end
end
local dragging = false
track.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if dragging then
			dragging = false
			setG(g, true)
		end
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if
		dragging
		and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
	then
		local k = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		setG(G_MIN + k * (G_MAX - G_MIN), false)
	end
end)

-- v8 (lead-authorized, CHANGES.md): area lighting removed here; TrainingLighting.client.lua is the single owner.

local function hint(id: string?)
	actBtn.Visible = false
	slider.Visible = false
	if id == "GravityRoom" then
		slider.Visible = true
		setG(g, true)
	elseif id == "KingKaiPlanet" then
		actBtn.Visible = true
		actBtn.Text = "Catch Bubbles! (3 in 45 s)"
	elseif id == "WhisGround" then
		actBtn.Visible = true
		actBtn.Text = "Spar with Whis (drill)"
	end
end
actBtn.MouseButton1Click:Connect(function()
	local id = player:GetAttribute("TrainingArea")
	if id == "KingKaiPlanet" then
		ClientAPI.startDrill("CatchBubbles")
	elseif id == "WhisGround" then
		ClientAPI.startDrill("WhisDodge")
	end
end)
local lastArea = nil
local function refresh()
	local id = player:GetAttribute("TrainingArea")
	if id ~= lastArea then
		lastArea = id
		hint(id)
		if id then
			banner.Text = NAMES[id] or id
			local m = player:GetAttribute("TrainingXPMult")
			sub.Text = if m
				then ("XP x%s  •  training never grants stats beyond the level curve"):format(tostring(m))
				else ""
		else
			banner.Text = ""
			sub.Text = ""
		end
	else
		local m = player:GetAttribute("TrainingXPMult")
		if id and m then
			sub.Text = ("XP x%s"):format(tostring(m))
				.. (if id == "GravityRoom" then ("  •  Gravity %dx"):format(g) else "")
		end
		if id == "GravityRoom" then
			sLbl.Text = ("GRAVITY %dx   •   XP x%s"):format(g, tostring(m or "?"))
		end
	end
end
player:GetAttributeChangedSignal("TrainingArea"):Connect(refresh)
player:GetAttributeChangedSignal("TrainingXPMult"):Connect(refresh)

local function flash(text: string, color: Color3?, t: number?)
	big.Text = text
	big.TextColor3 = color or UIKit.GOLD
	big.TextTransparency = 0
	task.delay(t or 1.2, function()
		if big.Text == text then
			TweenService:Create(big, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		end
	end)
end
local drillOn = false
ClientAPI.onDrill(function(kind, d)
	d = d or {}
	if kind == "Start" then
		drillOn = false
		flash(
			("%s%s"):format(tostring(d.id), if d.stage then (" — stage %d"):format(d.stage) else ""),
			Color3.fromRGB(180, 230, 255),
			2
		)
	elseif kind == "Progress" then
		if d.got then
			flash(("%d / %d"):format(d.got, d.total), Color3.fromRGB(255, 230, 120), 0.6)
		end
	elseif kind == "Hit" then
		flash("Hit!", Color3.fromRGB(255, 110, 110), 0.5)
	elseif kind == "Dialogue" then
		flash(tostring(d.text), Color3.fromRGB(220, 230, 255), d.seconds or 3)
	elseif kind == "HTCDenied" then
		flash(("Time Chamber: %d Zeni needed"):format(d.cost or 0), Color3.fromRGB(255, 160, 160), 2)
	elseif kind == "Result" then
		flash(
			if d.ok
				then "Drill clear!"
				else ("Drill failed" .. (if d.reason then " (" .. tostring(d.reason) .. ")" else "")),
			if d.ok then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(255, 160, 160),
			2
		)
	end
end)
local function legacy(kind, a, b, c)
	if kind == "ChaseStart" then
		flash("CATCH BUBBLES!  (" .. a .. " s)")
	elseif kind == "ChaseHit" then
		flash(("Caught! %d / 3"):format(a), Color3.fromRGB(255, 230, 120))
	elseif kind == "ChaseClear" then
		flash(("Cleared!  King Kai: %d / %d"):format(a, b), Color3.fromRGB(120, 255, 140), 2)
	elseif kind == "ChaseFail" then
		flash("Bubbles got away... (" .. tostring(a) .. "/3)", Color3.fromRGB(255, 120, 120))
	elseif kind == "DrillStart" then
		drillOn = true
		flash("Whis: dodge (E) or counter (F) when I strike!", Color3.fromRGB(180, 230, 255), 2)
	elseif kind == "DrillTelegraph" then
		flash(
			if a == "Dodge" then "DODGE!  [E]" else "COUNTER!  [F]",
			if a == "Dodge" then Color3.fromRGB(120, 220, 255) else Color3.fromRGB(255, 160, 60),
			0.9
		)
	elseif kind == "DrillResult" then
		flash(
			if a then ("Good! %d / 10"):format(b) else "Too slow!",
			if a then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(255, 110, 110),
			0.6
		)
	elseif kind == "DrillClear" then
		drillOn = false
		flash(("Drill clear!  Ultra Instinct path %d / %d"):format(a, b), Color3.fromRGB(220, 230, 255), 2.5)
	elseif kind == "DrillFail" then
		drillOn = false
		flash("Whis: let's try again.", Color3.fromRGB(255, 160, 160), 2)
	elseif kind == "Unlocked" then
		flash("UNLOCKED: " .. tostring(a), UIKit.GOLD, 3)
	elseif kind == "Teleported" then
		refresh()
	end
end
local _legacy = legacy -- old TrainingEvent kinds kept for reference; TrainingEvent is no longer fired
UserInputService.InputBegan:Connect(function(i, processed)
	if processed or not drillOn then
		return
	end
	-- WhisDodge is a movement drill now (no E/F inputs)
end)
-- dev/test hook
local bf = Instance.new("BindableFunction")
bf.Name = "TrainingTest"
bf.Parent = script
bf.OnInvoke = function(cmd, arg)
	if cmd == "gravity" then
		setG(arg, true)
	elseif cmd == "chase" then
		ClientAPI.startDrill("CatchBubbles")
	elseif cmd == "drill" then
		ClientAPI.startDrill("WhisDodge")
	end
	return big.Text
end

-- STATE VISIBILITY (2026-10-14): this panel had no state awareness, so the "Spar with Whis (drill)" button and
-- the gravity slider were drawn over the character-select grid and the Intro/Ending cutscenes.
local function syncTrainingVisibility()
	local s = workspace:GetAttribute("RoundState")
	gui.Enabled = s ~= "Intro" and s ~= "Ending" and s ~= "CharacterSelect"
end
workspace:GetAttributeChangedSignal("RoundState"):Connect(syncTrainingVisibility)
syncTrainingVisibility()
