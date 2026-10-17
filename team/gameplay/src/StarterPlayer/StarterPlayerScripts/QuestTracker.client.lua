--!strict
-- LocalScript: quests (v11 kit). A compact "Today" card in the tracker zone (daily quests with progress bars and a
-- Claim button when finished) plus a full quests sheet (daily, weekly, Beerus camp) opened with J, the card's
-- "All quests" chip or the Quests entry of the menu rail. Reads attributes QuestsJson / BeerusStep, claims via
-- Remotes.ClaimQuest(scope, index). The card is lobby-only (hidden in the tutorial, raids / episodes, mid-fight).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
local SM = require(Shared:WaitForChild("ScreenManager"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimQuest = Remotes:WaitForChild("ClaimQuest") :: RemoteEvent
local lp = Players.LocalPlayer

local BEERUS = { "Sparring", "Destruction energy", "Hakai", "God aura", "Ultra Ego" }

local card = S.plate(SM.zone("tracker"), { size = UDim2.new(1, 0, 0, 0), auto = "Y", edge = S.C.gold, pad = 12 })
card.Name = "QuestTracker"
card.LayoutOrder = 1
S.stack(card, "Y", 8)
SM.lobbyOnly(card)

local sheet = S.plate(SM.layer("Panel"), { size = UDim2.new(0, math.floor(520 * S.textScale()), 0, 0), auto = "Y", alpha = 0.06, edge = S.C.gold, pad = 18 })
sheet.Name = "QuestSheet"
sheet.AnchorPoint = Vector2.new(0.5, 0.5)
sheet.Position = UDim2.fromScale(0.5, 0.5)
sheet.Visible = false
S.stack(sheet, "Y", 10)

local function clear(f: Instance)
	for _, c in f:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

local function header(parent: Instance, order: number, title: string, right: string, role: string?)
	local h = Instance.new("Frame")
	h.BackgroundTransparency = 1; h.Size = UDim2.new(1, 0, 0, S.px(role or "lead") + 4); h.LayoutOrder = order; h.Parent = parent
	S.text(h, role or "lead", title, {})
	local r = S.text(h, "caption", right, { font = S.F.bold, color = S.C.muted, align = "Right" })
	r.AnchorPoint = Vector2.new(1, 0.5); r.Position = UDim2.new(1, 0, 0.5, 0)
end

local function questRow(parent: Instance, order: number, q: any, scope: string, i: number)
	local done = q.prog >= q.goal
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 0); row.AutomaticSize = Enum.AutomaticSize.Y; row.LayoutOrder = order; row.Parent = parent
	S.stack(row, "Y", 4)
	local top = Instance.new("Frame"); top.BackgroundTransparency = 1; top.Size = UDim2.new(1, 0, 0, 0); top.AutomaticSize = Enum.AutomaticSize.Y; top.LayoutOrder = 1; top.Parent = row
	S.text(top, "label", q.text, { wrap = true, auto = "Y", size = UDim2.new(1, -78, 0, 0), font = S.F.bold, color = if q.claimed then S.C.muted else S.C.text })
	if done and not q.claimed then
		local b = S.chip(top, "Claim", nil, function() ClaimQuest:FireServer(scope, i) end)
		b.BackgroundColor3 = S.C.gold; b.BackgroundTransparency = 0
		;(b:FindFirstChild("Label") :: TextLabel).TextColor3 = S.C.ink
		b.AnchorPoint = Vector2.new(1, 0); b.Position = UDim2.fromScale(1, 0)
	else
		local n = S.text(top, "label", if q.claimed then "Done" else ("%d/%d"):format(q.prog, q.goal), { font = S.F.data, color = S.C.muted, align = "Right" })
		n.AnchorPoint = Vector2.new(1, 0); n.Position = UDim2.fromScale(1, 0)
	end
	if not q.claimed then
		local holder = Instance.new("Frame"); holder.BackgroundTransparency = 1; holder.Size = UDim2.new(1, 0, 0, 5); holder.LayoutOrder = 2; holder.Parent = row
		local _, set = S.meter(holder, { size = UDim2.fromScale(1, 1), color = if done then S.C.hp else S.C.gold, radius = 3 })
		set(q.prog / math.max(1, q.goal))
	end
end

local railItem: any
local notify: (boolean) -> () = function() end
local function setSheet(v: boolean?)
	local on = if v == nil then not sheet.Visible else v
	if on and SM.lobbyHidden() then on = false end
	sheet.Visible = on
	notify(on)
	if railItem then railItem.setOpen(on) end
end
notify = S.registerPanel(setSheet)
railItem = SM.railItem({ label = "Quests", key = "J", order = 6, onClick = function() setSheet() end })

local function render()
	clear(card)
	clear(sheet)
	local ok, view = pcall(HttpService.JSONDecode, HttpService, (lp:GetAttribute("QuestsJson") :: string?) or "{}")
	local daily = if ok and type(view) == "table" and type(view.daily) == "table" then view.daily else {}
	local weekly = if ok and type(view) == "table" and type(view.weekly) == "table" then view.weekly else {}
	local doneN = 0
	for _, q in daily do if q.prog >= q.goal then doneN += 1 end end

	-- card: today only
	header(card, 1, "Today", ("%d of %d done"):format(doneN, #daily))
	for i, q in daily do questRow(card, 1 + i, q, "daily", i) end
	S.chip(card, "All quests", S.keyFor("quests"), function() setSheet(true) end).LayoutOrder = 99

	-- sheet: everything
	header(sheet, 1, "Quests", "", "title")
	header(sheet, 2, "Today", ("%d of %d done"):format(doneN, #daily))
	local order = 3
	for i, q in daily do questRow(sheet, order, q, "daily", i); order += 1 end
	local wDone = 0
	for _, q in weekly do if q.prog >= q.goal then wDone += 1 end end
	header(sheet, order, "This week", ("%d of %d done"):format(wDone, #weekly)); order += 1
	for i, q in weekly do questRow(sheet, order, q, "weekly", i); order += 1 end
	local step = (lp:GetAttribute("BeerusStep") :: number?) or 0
	header(sheet, order, "Beerus camp", if step >= #BEERUS then "Complete" else ("%d of %d"):format(step, #BEERUS)); order += 1
	if step < #BEERUS then
		S.text(sheet, "label", "Next: " .. BEERUS[step + 1], { font = S.F.bold, color = S.C.muted }).LayoutOrder = order
		order += 1
	end
	S.text(sheet, "caption", if S.keyFor("quests") ~= "" then "Press J to close" else "Tap Quests to close", { color = S.C.muted, font = S.F.bold }).LayoutOrder = order
end

lp:GetAttributeChangedSignal("QuestsJson"):Connect(render)
lp:GetAttributeChangedSignal("BeerusStep"):Connect(render)
S.deviceChanged:Connect(render)
UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.J then setSheet() end
end)
render()
