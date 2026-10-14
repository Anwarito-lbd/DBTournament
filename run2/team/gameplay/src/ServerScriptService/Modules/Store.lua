--!strict
-- ModuleScript: ServerScriptService.Modules.Store (v1.2)
-- Remotes.StoreRequest:InvokeServer? No - RemoteEvent StoreRequest(action, itemId) -> StoreResult(ok, itemId, message) to the client.
--   action "BuyZeni": server checks price/ownership, deducts Zeni, grants. action "BuyRobux": prompts the DevProduct/GamePass
--   when its id in Config is non-zero; placeholders (id 0) return "not on sale yet". action "Equip": aura/outfit owned -> wear.
-- Grants live in the profile (unlocks / owned / zeni / boostUntil / drinks) through PlayerData; no schema change.
-- Pay-to-win "stat" items set StoreStatBoost; Combat clamps (ratio x boosts) to Config.STAT_CAP and ignores it in Ranked.
-- Zeni earning: +win / +KO via leaderstats + attribute watchers, training camps call Training.addZeni.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.StoreCatalog)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)
local RateLimit = require(script.Parent.RateLimit)

local Store = {}
local Req = Net.remote("StoreRequest")
local Res = Net.remote("StoreResult")

local function prof(p: Player): any return PlayerData.get(p) end
local function owned(p: Player): { [string]: boolean }
	local pr = prof(p); if not pr then return {} end
	pr.owned = pr.owned or {}
	return pr.owned
end
local function sync(p: Player)
	local pr = prof(p); if not pr then return end
	p:SetAttribute("Zeni", pr.zeni or 0)
	local list = {}
	for id in owned(p) do table.insert(list, id) end
	for id in pr.unlocks do if Catalog.BY_ID[id] then table.insert(list, id) end end
	p:SetAttribute("StoreOwned", table.concat(list, ","))
	p:SetAttribute("StoreStatBoost", if pr.storeStat then pr.storeStat else nil)
	if pr.equipAura then p:SetAttribute("Aura", pr.equipAura) end
	if pr.equipOutfit then p:SetAttribute("Cosmetic", pr.equipOutfit) end
	p:SetAttribute("XPBoostUntil", pr.boostUntil or 0)
end
Store.sync = sync

local function isOwned(p: Player, it: any): boolean
	local pr = prof(p); if not pr then return false end
	if it.kind == "unlock" then return pr.unlocks[it.id] == true end
	if it.kind == "aura" or it.kind == "outfit" or it.kind == "stat" then return owned(p)[it.id] == true end
	return false -- consumables can always be bought
end

local function grant(p: Player, it: any)
	local pr = prof(p); if not pr then return end
	if it.kind == "unlock" then pr.unlocks[it.id] = true
	elseif it.kind == "aura" then owned(p)[it.id] = true; pr.equipAura = it.id
	elseif it.kind == "outfit" then owned(p)[it.id] = true; pr.equipOutfit = it.id
	elseif it.kind == "stat" then owned(p)[it.id] = true; pr.storeStat = math.min(it.mult, Config.STAT_CAP)
	elseif it.kind == "xpboost" then pr.boostUntil = math.max(pr.boostUntil or 0, os.time()) + it.minutes * 60
	elseif it.kind == "drink" then
		if (PlayerData :: any).grantDrinks then (PlayerData :: any).grantDrinks(p, it.count) else pr.drinks = (pr.drinks or 0) + it.count end
	end
	sync(p)
end

local function robuxInfo(it: any): (string?, number)
	if not it.robux then return nil, 0 end
	local gp = Config.GAMEPASSES[it.robux]
	if gp then return "pass", gp.id end
	local pd = Config.PRODUCTS[it.robux]
	if pd then return "product", pd.id end
	return nil, 0
end

Req.OnServerEvent:Connect(function(p, action, itemId)
	if not RateLimit.allow(p, "store", 4, 6) then return end
	local it = type(itemId) == "string" and Catalog.BY_ID[itemId]
	if not it then Res:FireClient(p, false, itemId, "Unknown item"); return end
	local pr = prof(p)
	if not pr then Res:FireClient(p, false, itemId, "Profile not loaded"); return end
	-- v8 (lead-authorized, CHANGES.md): level-gated items (UI Sign) are refused before any Zeni/Robux is taken
	local locked, why = Catalog.lockedFor(it, pr)
	if locked and (action == "BuyZeni" or action == "BuyRobux") then Res:FireClient(p, false, it.id, "Locked: " .. tostring(why)); return end
	if action == "BuyZeni" then
		if isOwned(p, it) then Res:FireClient(p, false, it.id, "Already owned"); return end
		local z = pr.zeni or 0
		if z < it.zeni then Res:FireClient(p, false, it.id, ("Need %d more Zeni"):format(it.zeni - z)); return end
		pr.zeni = z - it.zeni
		grant(p, it)
		Res:FireClient(p, true, it.id, "Purchased " .. it.name)
	elseif action == "BuyRobux" then
		local kind, id = robuxInfo(it)
		if not kind then Res:FireClient(p, false, it.id, "Zeni only"); return end
		if id == 0 then Res:FireClient(p, false, it.id, "Robux purchase not on sale yet (placeholder ID)"); return end
		if kind == "pass" then MarketplaceService:PromptGamePassPurchase(p, id) else MarketplaceService:PromptProductPurchase(p, id) end
		Res:FireClient(p, true, it.id, "Opening Robux purchase...")
	elseif action == "Equip" then
		if not isOwned(p, it) then Res:FireClient(p, false, it.id, "Not owned"); return end
		if it.kind == "aura" then pr.equipAura = if pr.equipAura == it.id then nil else it.id; p:SetAttribute("Aura", pr.equipAura)
		elseif it.kind == "outfit" then pr.equipOutfit = if pr.equipOutfit == it.id then nil else it.id; p:SetAttribute("Cosmetic", pr.equipOutfit) end
		sync(p)
		Res:FireClient(p, true, it.id, "Equipped")
	end
end)

-- Game Pass bought in-session: grant matching catalog item immediately (ProcessReceipt handles DevProducts in PlayerData)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, bought)
	if not bought then return end
	for _, it in Catalog.ITEMS do
		local kind, id = robuxInfo(it)
		-- v8 safety net: a gated pass bought while locked is not granted now; pass ownership is permanent, so it is
		-- delivered by PlayerData's owned-pass check on a later join once the requirement is met (never consumed or lost)
		if kind == "pass" and id == passId and id ~= 0 then
			if Catalog.lockedFor(it, prof(p)) then Res:FireClient(p, false, it.id, "Owned - unlocks when you meet the level requirement")
			else grant(p, it) end
		end
	end
end)

-- ===== Zeni earning =====
local function watch(p: Player)
	task.spawn(function()
		for _ = 1, 40 do if prof(p) then break end; task.wait(0.25) end
		sync(p)
		local ls = p:WaitForChild("leaderstats", 30)
		local wins = ls and ls:FindFirstChild("Wins") :: IntValue?
		if wins then
			local last = wins.Value
			wins.Changed:Connect(function(v)
				if v > last then local pr = prof(p); if pr then pr.zeni = (pr.zeni or 0) + Catalog.EARN.win * (v - last); sync(p) end end
				last = v
			end)
		end
		local lastXP = (p:GetAttribute("XP") :: number?) or 0
		p:GetAttributeChangedSignal("XP"):Connect(function()
			local x = (p:GetAttribute("XP") :: number?) or 0
			if x > lastXP then
				local pr = prof(p)
				if pr then pr.zeni = (pr.zeni or 0) + math.floor((x - lastXP) / 10) * Catalog.EARN.perXP10; p:SetAttribute("Zeni", pr.zeni) end
			end
			lastXP = x
		end)
	end)
end

function Store.init()
	for _, p in Players:GetPlayers() do watch(p) end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5); sync(p) end) end)
	-- open the shop at the Capsule Corp counter (db-map tag ShopCounter)
	local function prompt(c: Instance)
		if not c:IsA("BasePart") or c:FindFirstChild("StorePrompt") then return end
		local pp = Instance.new("ProximityPrompt"); pp.Name = "StorePrompt"; pp.ActionText = "Open Store"; pp.ObjectText = "Capsule Corp."
		pp.HoldDuration = 0; pp.MaxActivationDistance = 14; pp.RequiresLineOfSight = false; pp.Parent = c
	end
	for _, c in CollectionService:GetTagged("ShopCounter") do prompt(c) end
	CollectionService:GetInstanceAddedSignal("ShopCounter"):Connect(prompt)
end
Store.grant = grant
return Store
