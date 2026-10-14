--!strict
-- v1.2 Store catalog (shared by server Store + client StoreUI). Prices in Zeni (earned) and optional Robux.
-- ROBUX IDS ARE PLACEHOLDERS (0). Real Developer Products / Game Passes must be created on the Creator Dashboard and
-- the ids pasted here (or into Config.PRODUCTS / Config.GAMEPASSES). With id = 0 the Robux button is shown disabled.
local C = {}
C.AURA_COLORS = {
	Aura_Crimson = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(140, 0, 20) },
	Aura_Emerald = { Color3.fromRGB(80, 255, 140), Color3.fromRGB(0, 120, 60) },
	Aura_Violet = { Color3.fromRGB(190, 110, 255), Color3.fromRGB(80, 20, 160) },
	Aura_Ice = { Color3.fromRGB(200, 240, 255), Color3.fromRGB(90, 170, 255) },
}
C.OUTFITS = {
	Outfit_TurtleGi = { gi = Color3.fromRGB(255, 120, 20), belt = Color3.fromRGB(30, 60, 160), pants = Color3.fromRGB(255, 120, 20), symbol = "亀" },
	Outfit_SaiyanArmor = { gi = Color3.fromRGB(235, 235, 240), belt = Color3.fromRGB(230, 190, 60), pants = Color3.fromRGB(30, 50, 140) },
	Outfit_Whis = { gi = Color3.fromRGB(40, 40, 70), belt = Color3.fromRGB(220, 30, 40), pants = Color3.fromRGB(240, 240, 255) },
	Outfit_Gogeta = { gi = Color3.fromRGB(240, 240, 240), belt = Color3.fromRGB(30, 30, 40), pants = Color3.fromRGB(20, 20, 30) },
}
-- cat: Characters | Forms | Cosmetics | Boosts | Items
-- kind: unlock (id = roster/form id) | aura | outfit | xpboost (minutes) | drink (count) | stat (mult, capped by Config.STAT_CAP, ignored in Ranked)
-- robux: key into Config.PRODUCTS (consumables) or Config.GAMEPASSES (permanent), or nil
C.ITEMS = {
	{ id = "u11_jiren", name = "Jiren", cat = "Characters", kind = "unlock", zeni = 25000, robux = "EarlyJiren" },
	{ id = "u6_kefla", name = "Kefla", cat = "Characters", kind = "unlock", zeni = 18000 },
	{ id = "u7_gohan", name = "Gohan", cat = "Characters", kind = "unlock", zeni = 6000 },
	{ id = "SuperSaiyan", name = "Super Saiyan", cat = "Forms", kind = "unlock", zeni = 8000, robux = "EarlySuperSaiyan" },
	{ id = "SuperSaiyanBlue", name = "Super Saiyan Blue", cat = "Forms", kind = "unlock", zeni = 60000, robux = "EarlyBlue" },
	{ id = "UltraInstinctSign", name = "Ultra Instinct -Sign-", cat = "Forms", kind = "unlock", zeni = 90000,
		requires = { level = 85, earlyLevel = 70, whisStages = 10 } }, -- v8 (lead-authorized): Lv85, or Lv70 + 10 Whis stages
	{ id = "Golden", name = "Golden Frieza", cat = "Forms", kind = "unlock", zeni = 55000 },
	{ id = "Aura_Crimson", name = "Crimson Aura", cat = "Cosmetics", kind = "aura", zeni = 3000, robux = "AuraPack" },
	{ id = "Aura_Emerald", name = "Emerald Aura", cat = "Cosmetics", kind = "aura", zeni = 3000 },
	{ id = "Aura_Violet", name = "Violet Aura", cat = "Cosmetics", kind = "aura", zeni = 4500 },
	{ id = "Aura_Ice", name = "Ice Aura", cat = "Cosmetics", kind = "aura", zeni = 4500 },
	{ id = "Outfit_TurtleGi", name = "Turtle School Gi", cat = "Cosmetics", kind = "outfit", zeni = 2500 },
	{ id = "Outfit_SaiyanArmor", name = "Saiyan Armor", cat = "Cosmetics", kind = "outfit", zeni = 5000 },
	{ id = "Outfit_Whis", name = "Angel Robes", cat = "Cosmetics", kind = "outfit", zeni = 12000 },
	{ id = "Outfit_Gogeta", name = "Fusion Vest", cat = "Cosmetics", kind = "outfit", zeni = 9000, robux = "OutfitPack" },
	{ id = "XPBoost30", name = "2x XP (30 min)", cat = "Boosts", kind = "xpboost", minutes = 30, zeni = 1500, robux = "XPBoost30" },
	{ id = "XPBoost120", name = "2x XP (2 h)", cat = "Boosts", kind = "xpboost", minutes = 120, zeni = 5000, robux = "XPBoost120" },
	{ id = "Zenkai", name = "Zenkai Boost (+5% dmg, capped 1.35x, off in Ranked)", cat = "Boosts", kind = "stat", mult = 1.05, zeni = 20000, robux = "ZenkaiPass" },
	{ id = "Drink1", name = "Energy Drink x1", cat = "Items", kind = "drink", count = 1, zeni = 400 },
	{ id = "Drink5", name = "Energy Drink x5", cat = "Items", kind = "drink", count = 5, zeni = 1800, robux = "Drink5" },
}
C.BY_ID = {} :: { [string]: any }
for _, it in C.ITEMS do C.BY_ID[it.id] = it end
-- v8 (lead-authorized, see CHANGES.md): level gate for items with `requires`. prof = PlayerData profile (or nil).
-- Returns locked, reason. Server must refuse purchase when locked; UI should show the item as locked with the reason.
function C.lockedFor(it: any, prof: any): (boolean, string?)
	local r = it and it.requires
	if not r then return false, nil end
	if not prof then return true, "Profile not loaded" end
	local lvl, prestige = prof.level or 1, prof.prestige or 0
	local stages = (prof.training and prof.training.whisStage) or 0
	if prestige > 0 or lvl >= r.level or (lvl >= r.earlyLevel and stages >= r.whisStages) then return false, nil end
	return true, ("Requires Lv%d, or Lv%d + %d Whis stages"):format(r.level, r.earlyLevel, r.whisStages)
end
C.CATS = { "Characters", "Forms", "Cosmetics", "Boosts", "Items" }
-- Zeni earnings (server): per win, per KO, per 10 XP gained, training camps
C.EARN = { win = 250, ko = 40, perXP10 = 1 }
return C
