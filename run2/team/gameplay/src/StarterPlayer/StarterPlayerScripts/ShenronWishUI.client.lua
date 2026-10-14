-- LocalScript (v8, db-gameplay): Shenron wish picker. Opens automatically when the server grants a wish window
-- (ShenronWish s->c); [P] / touch button reopens it while a wish is pending. Wishes are cosmetic / title / Zeni only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("UIStyle"))
if not S.remotes({ "ShenronWish" }, 15) then
	return
end
local ClientAPI = require(Shared:WaitForChild("ClientAPI"))
local _ = Players

local gui = S.gui("ShenronWishUI", 30)
local panel = S.panel(gui, 0.5, 0.6, 640, 480)
panel.BackgroundColor3 = Color3.fromRGB(10, 30, 18)
S.title(panel, "SHENRON: SPEAK YOUR WISH")
local set = S.toggle(gui, panel, Enum.KeyCode.P, "Wish", 1)
S.close(panel, function()
	set(false)
end)
local timer = S.label(panel, "", UDim2.fromScale(0.9, 0.07), UDim2.fromScale(0.05, 0.13), S.MUTED)
local list = S.list(panel, UDim2.fromScale(0.94, 0.76), UDim2.fromScale(0.03, 0.22))
local deadline = 0
local offer: any = nil

local function render()
	S.clear(list)
	if not offer then
		S.label(list, "No wish pending. Gather all 7 Dragon Balls!", UDim2.new(1, -12, 0, 40), UDim2.new(), S.MUTED)
		return
	end
	for i, w in offer.wishes do
		local c = S.card(list, 64, i)
		S.label(c, w.text, UDim2.new(0.62, 0, 1, -8), UDim2.fromOffset(10, 4), Color3.new(1, 1, 1)).TextXAlignment =
			Enum.TextXAlignment.Left
		if w.rotating then
			for j, outfit in offer.rotation or {} do
				S.button(
					c,
					(string.gsub(outfit, "^Outfit_", "")),
					UDim2.fromScale(0.11, 0.7),
					UDim2.fromScale(0.63 + (j - 1) * 0.12, 0.15),
					S.BLUE,
					function()
						ClientAPI.makeWish(w.id, outfit)
					end
				)
			end
		else
			S.button(c, "WISH", UDim2.fromScale(0.3, 0.7), UDim2.fromScale(0.66, 0.15), S.GREEN, function()
				ClientAPI.makeWish(w.id)
			end)
		end
	end
end
render()

ClientAPI.onShenron(function(d)
	if d.wishes then
		offer = d
		deadline = os.clock() + (d.seconds or 60)
		render()
		set(true)
	elseif d.granted then
		offer = nil
		render()
		set(false)
		S.toast(gui, "Your wish has been granted!" .. (if d.timeout then " (Zeni)" else ""))
	elseif d.error then
		S.toast(gui, "Shenron: " .. tostring(d.error), S.RED)
	end
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		timer.Text = if offer
			then ("Shenron waits %d s (no choice = 3,000 Zeni)"):format(math.max(0, math.ceil(deadline - os.clock())))
			else ""
	end
end)
