--!strict
-- LocalScript: compact quest tracker (daily/weekly quests + Beerus camp step). Reads attributes QuestsJson / BeerusStep,
-- claims via Remotes.ClaimQuest(scope, index). Toggle with J. Placeholder styling; UX owner may restyle.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local ClaimQuest = Remotes:WaitForChild("ClaimQuest") :: RemoteEvent
local lp = Players.LocalPlayer

local wanted = true

-- FOCUS MODE (2026-10-14): this only checked InTutorial, so the DAILY/WEEKLY panel stayed up over the
-- character-select grid and the Intro/Ending cutscenes.
local function focusHidden(): boolean
	local s = workspace:GetAttribute("RoundState")
	if s == "CharacterSelect" or s == "Intro" or s == "Ending" then
		return true
	end
	if lp:GetAttribute("InRaid") == true then -- v11: raids and story episodes own the screen
		return true
	end
	return lp:GetAttribute("InTutorial") == true
end

local gui = Instance.new("ScreenGui")
gui.Name = "QuestTracker"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 260)
frame.Position = UDim2.new(1, -310, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.25
frame.Parent = gui
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.Parent = frame
local BEERUS = { "Sparring", "Destruction energy", "Hakai", "God aura", "Ultra Ego" }

local function row(text: string, done: boolean, claimed: boolean, scope: string?, i: number?)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -8, 0, 26)
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = if claimed
		then Color3.fromRGB(120, 120, 120)
		elseif done then Color3.fromRGB(255, 220, 80)
		else Color3.new(1, 1, 1)
	b.BackgroundTransparency = 1
	b.Text = text
	b.Parent = frame
	if done and not claimed and scope and i then
		b.Activated:Connect(function()
			ClaimQuest:FireServer(scope, i)
		end)
	end
end

local function render()
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ok, view = pcall(HttpService.JSONDecode, HttpService, (lp:GetAttribute("QuestsJson") :: string?) or "{}")
	if ok and type(view) == "table" then
		for _, scope in { "daily", "weekly" } do
			row(string.upper(scope), false, false)
			for i, q in (view[scope] or {}) do
				local done = q.prog >= q.goal
				row(
					("%s  %d/%d%s"):format(
						q.text,
						q.prog,
						q.goal,
						if q.claimed then " ✓" elseif done then "  [CLAIM]" else ""
					),
					done,
					q.claimed,
					scope,
					i
				)
			end
		end
	end
	local step = (lp:GetAttribute("BeerusStep") :: number?) or 0
	row(
		if step >= #BEERUS
			then "Beerus camp: complete"
			else ("Beerus camp: %s (%d/%d)"):format(BEERUS[step + 1], step, #BEERUS),
		false,
		false
	)
end
lp:GetAttributeChangedSignal("QuestsJson"):Connect(render)
lp:GetAttributeChangedSignal("BeerusStep"):Connect(render)
UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.J then
		wanted = not wanted
		frame.Visible = wanted and not focusHidden()
	end
end)

-- FOCUS MODE (FTUE 2026-10-14): hidden while the Whis tutorial runs, and lifted from 0.3 to 0.12 so it stops
-- running into the HUD's controls panel at the bottom right (this panel's rows grow past its 260 px frame).
frame.Position = UDim2.new(1, -310, 0.12, 0)
lp:GetAttributeChangedSignal("InTutorial"):Connect(function()
	frame.Visible = wanted and not focusHidden()
end)
lp:GetAttributeChangedSignal("InRaid"):Connect(function()
	frame.Visible = wanted and not focusHidden()
end)
frame.Visible = wanted and not focusHidden()
render()
