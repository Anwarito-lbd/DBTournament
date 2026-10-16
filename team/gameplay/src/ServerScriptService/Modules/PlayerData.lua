--!strict
-- ModuleScript: ServerScriptService.Modules.PlayerData
-- Session-locked profiles via UpdateAsync, retries w/ backoff, autosave, BindToClose,
-- schema migration, level/unlock checks, Game Pass multipliers, idempotent ProcessReceipt.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToPLogic = require(game:GetService("ReplicatedStorage").Shared.ToPLogic)
local Config = require(ReplicatedStorage.Shared.Config)

local SCHEMA_VERSION = 10
local STORE_NAME = "ToP_PlayerData_v1"
local LOCK_TIMEOUT = 1800 -- seconds; stale locks older than this can be stolen
local AUTOSAVE = 120
local MAX_RECEIPTS = 100

-- Unpublished place / API access off: fall back to an in-memory store (data not saved).
local store: any
do
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = ds
	else
		warn("[PlayerData] DataStore unavailable, using in-memory store (progress not saved): " .. tostring(ds))
		local mem = {}
		store = {
			UpdateAsync = function(_, k, fn)
				local v = fn(mem[k])
				if v ~= nil then
					mem[k] = v
				end
				return mem[k]
			end,
			GetAsync = function(_, k)
				return mem[k]
			end,
			SetAsync = function(_, k, v)
				mem[k] = v
			end,
		}
	end
end
local PlayerData = {}
local Quests = require(game:GetService("ReplicatedStorage").Shared.Quests)
local Races = require(game:GetService("ReplicatedStorage").Shared.Races)

local LevelUp = Instance.new("BindableEvent")
PlayerData.LevelUp = LevelUp.Event -- (player, newLevel, {unlockIds})

type Profile = {
	version: number,
	xp: number,
	level: number,
	totalXp: number,
	wins: number,
	kos: number,
	playtime: number,
	unlocks: { [string]: boolean },
	senzu: number,
	boostUntil: number,
	receipts: { string },
	prestige: number,
	drinks: number,
	dailyDay: number,
	lastDaily: number,
	zeni: number,
	passXp: number,
	quests: any,
	beerus: { step: number },
	early: { [string]: number },
	training: { htcDay: number, htcVisits: number, kkClears: number, whisStage: number },
	title: string?,
	ranked: any,
	dragonBalls: any,
	raids: any,
	story: any,
	episodes: any, -- v10: Legendary Episodes { [episodeId] = { cleared, clears, bestTime } }
	tutorialDone: boolean?,
	lock: { jobId: string, t: number }?,
}

local profiles: { [Player]: Profile } = {}
local saving: { [Player]: boolean } = {}

local function default(): Profile
	local p: Profile = {
		version = SCHEMA_VERSION,
		xp = 0,
		level = 1,
		totalXp = 0,
		wins = 0,
		kos = 0,
		playtime = 0,
		unlocks = {},
		senzu = 0,
		boostUntil = 0,
		receipts = {},
		prestige = 0,
		drinks = 1,
		dailyDay = 0,
		lastDaily = 0,
		zeni = 0,
		passXp = 0,
		quests = Quests.new(),
		beerus = { step = 0 },
		early = {},
		training = { htcDay = -1, htcVisits = 0, kkClears = 0, whisStage = 0, kk = 0, whis = 0 },
		ranked = { elo = 1000, games = 0, wins = 0, losses = 0, peak = 1000, season = 0, lastPlayed = 0 },
		dragonBalls = {
			week = -1,
			have = { false, false, false, false, false, false, false },
			summoned = false,
			lastCollect = 0,
		},
		raids = { firstClearWeek = {}, clears = 0 },
		story = { done = {}, badges = {} },
		episodes = {},
		tutorialDone = false,
		lock = nil,
	}
	for _, u in Config.UNLOCKS do
		if u.level <= 1 then
			p.unlocks[u.id] = true
		end
	end
	return p
end

local function migrate(d: any): Profile
	if type(d) ~= "table" then
		return default()
	end
	local v = d.version or 1
	if v < 2 then -- v1 had no senzu/boostUntil/receipts
		d.senzu = d.senzu or 0
		d.boostUntil = d.boostUntil or 0
		d.receipts = d.receipts or {}
	end
	if v < 3 then -- v3: race unlocks replaced by per-character roster IDs (regranted by level on load)
		for _, legacy in { "Saiyan", "Namekian", "Android", "FriezaRace", "PrideTrooper", "Kamehameha" } do
			if type(d.unlocks) == "table" then
				d.unlocks[legacy] = nil
			end
		end
	end
	if v < 4 then -- v4: prestige + divine unlocks; UltraInstinct form renamed MUI
		d.prestige = d.prestige or 0
		if type(d.unlocks) == "table" and d.unlocks.UltraInstinct then
			d.unlocks.UltraInstinct = nil
			d.unlocks.MUI = true
		end
	end
	if v < 6 then -- v6: energy drinks + daily streak
		d.drinks = d.drinks or 1
		d.dailyDay = d.dailyDay or 0
		d.lastDaily = d.lastDaily or 0
	end
	if v < 7 then -- v7: quests, Beerus chain, training progress, earned-early unlocks, zeni/passXp formalized
		d.zeni = tonumber(d.zeni) or 0
		d.passXp = d.passXp or 0
		if type(d.quests) ~= "table" then
			d.quests = Quests.new()
		end
		if type(d.beerus) ~= "table" then
			d.beerus = { step = 0 }
		end
		if type(d.early) ~= "table" then
			d.early = {}
		end
		if type(d.training) ~= "table" then
			d.training = { htcDay = -1, htcVisits = 0, kkClears = 0, whisStage = 0, kk = 0, whis = 0 }
		end
		for k, v in { htcDay = -1, htcVisits = 0, kkClears = 0, whisStage = 0, kk = 0, whis = 0 } do -- v1.2 Training.lua used {kk, whis}
			if d.training[k] == nil then
				d.training[k] = v
			end
		end
	end
	if v < 10 and type(d.episodes) ~= "table" then -- v10: Legendary Episodes progress (StoryEpisodeService)
		d.episodes = {}
	end
	if v < 9 then -- v9 (lead): the Shenron/Super Dragon Ball Power stat wish is gone (pre-release): reset any saved boost to 1.0
		d.statBoost = nil
	end
	if v < 8 then -- v8: ranked (Elo/season), Dragon Ball hunt, raids, story progress
		if type(d.ranked) ~= "table" then
			d.ranked = { elo = 1000, games = 0, wins = 0, losses = 0, peak = 1000, season = 0, lastPlayed = 0 }
		end
		if type(d.dragonBalls) ~= "table" then
			d.dragonBalls = {
				week = -1,
				have = { false, false, false, false, false, false, false },
				summoned = false,
				lastCollect = 0,
			}
		end
		if type(d.raids) ~= "table" then
			d.raids = { firstClearWeek = {}, clears = 0 }
		end
		if type(d.story) ~= "table" then
			d.story = { done = {}, badges = {} }
		end
	end
	if v < 5 and type(d.unlocks) == "table" then -- v5: id aliases (UISign->UltraInstinctSign, bonus_moro->u7_moro)
		for old, new in Config.ALIASES do
			if d.unlocks[old] then
				d.unlocks[old] = nil
				d.unlocks[new] = true
			end
		end
	end
	local base = default()
	for k, val in base do
		if d[k] == nil then
			d[k] = val
		end
	end
	d.version = SCHEMA_VERSION
	return d
end

local function retry<T>(fn: () -> T, tries: number?): (boolean, T | string)
	local n = tries or 5
	local delay = 1
	local ok, res
	for i = 1, n do
		ok, res = pcall(fn)
		if ok then
			return true, res
		end
		warn(("[PlayerData] attempt %d failed: %s"):format(i, tostring(res)))
		if i < n then
			task.wait(delay)
			delay = math.min(delay * 2, 16)
		end
	end
	return false, tostring(res)
end

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end

local function key(p: Player)
	return "u_" .. p.UserId
end

local function load(p: Player): Profile?
	local loaded: Profile? = nil
	for _ = 1, 6 do -- wait for other server's lock to release
		local stolen = false
		local ok = retry(function()
			return store:UpdateAsync(key(p), function(old)
				local d = migrate(old)
				local lock = d.lock
				local now = os.time()
				if lock and lock.jobId ~= game.JobId and now - lock.t < LOCK_TIMEOUT then
					stolen = true
					return nil -- abort write; locked elsewhere
				end
				d.lock = { jobId = game.JobId, t = now }
				loaded = d
				return d
			end)
		end)
		if not ok then
			return nil
		end
		if not stolen and loaded then
			return loaded
		end
		task.wait(5)
	end
	return nil
end

local function save(p: Player, release: boolean): boolean
	local prof = profiles[p]
	if not prof or saving[p] then
		return false
	end
	saving[p] = true
	local ok = retry(function()
		return store:UpdateAsync(key(p), function(old)
			if type(old) == "table" and old.lock and old.lock.jobId ~= game.JobId then
				return nil -- we lost the lock; never overwrite
			end
			local out = deepCopy(prof)
			out.lock = if release then nil else { jobId = game.JobId, t = os.time() }
			return out
		end)
	end)
	saving[p] = false
	return ok
end

local function syncAttrs(p: Player, prof: Profile)
	p:SetAttribute("Level", prof.level)
	p:SetAttribute("XP", prof.xp)
	p:SetAttribute("XPToNext", Config.xpToNext(prof.level))
	p:SetAttribute("Senzu", prof.senzu)
	p:SetAttribute("EnergyDrinkStock", prof.drinks)
	p:SetAttribute("DailyDay", prof.dailyDay)
	p:SetAttribute("Prestige", prof.prestige)
	p:SetAttribute("TutorialDone", prof.tutorialDone == true)
	-- Super Dragon Ball wish rewards (v1.1)
	local x = prof :: any
	p:SetAttribute("Zeni", prof.zeni or 0)
	p:SetAttribute("PassXP", prof.passXp or 0)
	p:SetAttribute("RankedElo", prof.ranked and prof.ranked.elo or 1000)
	p:SetAttribute("BeerusStep", prof.beerus and prof.beerus.step or 0)
	p:SetAttribute("WhisStage", prof.training and prof.training.whisStage or 0)
	p:SetAttribute("KingKaiClears", prof.training and prof.training.kkClears or 0)
	if x.title then
		p:SetAttribute("Title", x.title)
	end
	p:SetAttribute("WishStatBoost", nil) -- v9: no wish stat boost exists anymore
	if x.aura then
		p:SetAttribute("Aura", x.aura)
	end
	if x.cosmetic then
		p:SetAttribute("Cosmetic", x.cosmetic)
	end
	local ls = p:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"
	local lv = (ls:FindFirstChild("Level") or Instance.new("IntValue")) :: IntValue
	lv.Name = "Level"
	lv.Value = prof.level
	lv.Parent = ls
	local w = (ls:FindFirstChild("Wins") or Instance.new("IntValue")) :: IntValue
	w.Name = "Wins"
	w.Value = prof.wins
	w.Parent = ls
	ls.Parent = p
end

-- v8: level-gated catalog items (StoreCatalog.requires). Pass ownership is permanent, so a gated pass is delivered on the
-- first join where the requirement is met; dev products for gated items return NotYetProcessed (Roblox retries the
-- receipt later) -- the item is never consumed while locked.
local StoreCatalog = require(game:GetService("ReplicatedStorage").Shared.StoreCatalog)
local function gatedLocked(id: string, prof: any): boolean
	local it = StoreCatalog.BY_ID[id]
	return it ~= nil and (StoreCatalog.lockedFor(it, prof)) == true
end

-- Game Pass ownership cache
local passCache: { [Player]: { [string]: boolean } } = {}
local function ownsPass(p: Player, name: string): boolean
	local c = passCache[p]
	if not c then
		c = {}
		passCache[p] = c
	end
	if c[name] == nil then
		local id = Config.GAMEPASSES[name].id
		if id == 0 then
			c[name] = false
		else
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, id)
			c[name] = ok and owns or false
		end
	end
	return c[name] :: boolean
end

function PlayerData.getMultiplier(p: Player): number
	local m = 1
	for name, gp in Config.GAMEPASSES do
		if gp.xpMult and ownsPass(p, name) then
			m *= gp.xpMult
		end
	end
	local prof = profiles[p]
	if prof and prof.boostUntil > os.time() then
		m *= 2
	end
	if prof then
		m *= 1 + prof.prestige * Config.PRESTIGE_XP_BONUS
	end
	return m
end

local function checkUnlocks(prof: Profile): { string }
	local new = {}
	for _, dv in Config.DIVINE do
		if not Races.isPlayable(dv.id, Config.FEATURES) then
			continue
		end -- Angels NPC-only (flag)
		local req = Config.DIVINE_TIERS[dv.tier].req
		local ok = prof.prestige >= req.prestige or prof.level >= req.level -- level OR prestige
		if ok and not prof.unlocks[dv.id] then
			prof.unlocks[dv.id] = true
			table.insert(new, dv.id)
		end
	end
	for id, lvl in prof.early do -- earned-early unlocks from training paths (UI Sign @70, Ultra Ego @85)
		if prof.level >= lvl and not prof.unlocks[id] then
			prof.unlocks[id] = true
			table.insert(new, id)
		end
	end
	for _, u in Config.UNLOCKS do
		if u.level <= prof.level and not prof.unlocks[u.id] then
			prof.unlocks[u.id] = true
			table.insert(new, u.id)
		end
	end
	return new
end

function PlayerData.get(p: Player): Profile?
	return profiles[p]
end
function PlayerData.getLevel(p: Player): number
	local prof = profiles[p]
	return if prof then prof.level else 1
end
-- Ultra Instinct Sign gate (lead): Lv85, or Lv70 with all 10 Whis stages; prestige earns it. Applies to every grant path.
local function uiSignAllowed(prof: Profile): boolean
	local r = Config.UI_SIGN_RULE
	if prof.prestige > 0 or prof.level >= Config.FORMS[r.id].level then
		return true
	end
	return prof.level >= r.earlyLevel and (prof.training and prof.training.whisStage or 0) >= r.whisStages
end
PlayerData.uiSignAllowed = uiSignAllowed

function PlayerData.hasUnlock(p: Player, id: string): boolean
	if not Races.isPlayable(id, Config.FEATURES) then
		return false
	end -- Angels NPC-only even in Studio dev mode
	if id == Config.UI_SIGN_RULE.id and not (Config.DEV_MODE and game:GetService("RunService"):IsStudio()) then
		local prof = profiles[p]
		return prof ~= nil and prof.unlocks[id] == true and uiSignAllowed(prof)
	end
	if Config.DEV_MODE and game:GetService("RunService"):IsStudio() then
		return true
	end -- v1 dev: everything unlocked in Studio
	local prof = profiles[p]
	local sf = Config.FORMS[id] :: any
	if sf and sf.story then -- D24 story-gated form (SSJ4): mission cleared + level; no paid/flag bypass
		return prof ~= nil
			and ToPLogic.storyFormOk(sf, prof.level, prof.prestige, (prof :: any).story and (prof :: any).story.done)
	end
	return prof ~= nil and prof.unlocks[id] == true
end

-- applyMult=false for purchased XP packs.
function PlayerData.addXP(p: Player, amount: number, applyMult: boolean?)
	local prof = profiles[p]
	if not prof or amount <= 0 then
		return
	end
	local gained = math.floor(amount * (if applyMult == false then 1 else PlayerData.getMultiplier(p)))
	prof.xp += gained
	prof.totalXp += gained
	local leveled = false
	while prof.level < Config.MAX_LEVEL and prof.xp >= Config.xpToNext(prof.level) do
		prof.xp -= Config.xpToNext(prof.level)
		prof.level += 1
		leveled = true
	end
	if prof.level >= Config.MAX_LEVEL then
		prof.xp = 0
	end
	if leveled then
		LevelUp:Fire(p, prof.level, checkUnlocks(prof))
	end
	syncAttrs(p, prof)
end

function PlayerData.addStat(p: Player, stat: "wins" | "kos" | "playtime", n: number)
	local prof = profiles[p]
	if prof then
		(prof :: any)[stat] += n
		syncAttrs(p, prof)
	end
end

-- Energy drink stock (bought, daily, quests).
function PlayerData.consumeDrink(p: Player): boolean
	local prof = profiles[p]
	if prof and prof.drinks > 0 then
		prof.drinks -= 1
		syncAttrs(p, prof)
		return true
	end
	return false
end
function PlayerData.grantDrinks(p: Player, n: number)
	local prof = profiles[p]
	if prof then
		prof.drinks += n
		syncAttrs(p, prof)
	end
end

-- Daily reward: one claim per UTC day; streak advances if claimed yesterday, else resets to day 1.
function PlayerData.claimDaily(p: Player): any?
	local prof = profiles[p]
	if not prof then
		return nil
	end
	local today = os.time() // 86400
	if prof.lastDaily == today then
		return nil
	end
	prof.dailyDay = if prof.lastDaily == today - 1 then prof.dailyDay % #Config.DAILY_REWARDS + 1 else 1
	prof.lastDaily = today
	local r = Config.DAILY_REWARDS[prof.dailyDay]
	if r.zeni then
		prof.zeni += r.zeni
	end
	if r.drinks then
		prof.drinks += r.drinks
	end
	if r.senzu then
		prof.senzu += r.senzu
	end
	if r.cosmetic then
		prof.unlocks[r.cosmetic] = true
	end
	if r.xp then
		PlayerData.addXP(p, r.xp, false)
	end
	syncAttrs(p, prof)
	task.spawn(save, p, false)
	return r
end

-- Paid-unlock detection for the 1.35x paid cap: owned but not yet earned by level (prestige earns all non-divine).
function PlayerData.isPaidUnlock(p: Player, id: string, earnLevel: number): boolean
	local prof = profiles[p]
	if not prof or not prof.unlocks[id] then
		return false
	end
	local e = prof.early[id]
	if e and prof.level >= e then
		return false
	end -- earned through training, not paid
	return prof.level < earnLevel and prof.prestige == 0
end

-- ===== v7 helpers (quests, training, Beerus camp) =====
function PlayerData.sync(p: Player)
	local prof = profiles[p]
	if prof then
		syncAttrs(p, prof)
	end
end
function PlayerData.saveSoon(p: Player)
	task.spawn(save, p, false)
end
function PlayerData.addZeni(p: Player, n: number)
	local prof = profiles[p]
	if prof and n > 0 then
		prof.zeni += math.floor(n)
		syncAttrs(p, prof)
	end
end
function PlayerData.spendZeni(p: Player, n: number): boolean
	local prof = profiles[p]
	if not prof or n < 0 or prof.zeni < n then
		return false
	end
	prof.zeni -= n
	syncAttrs(p, prof)
	return true
end
function PlayerData.grantUnlock(p: Player, id: string)
	local prof = profiles[p]
	if prof and not prof.unlocks[id] then
		prof.unlocks[id] = true
		LevelUp:Fire(p, prof.level, { id })
		syncAttrs(p, prof)
	end
end
-- Earned-early unlock: id unlocks at `level` instead of its normal level (never a stat grant).
function PlayerData.grantEarly(p: Player, id: string, level: number)
	local prof = profiles[p]
	if not prof then
		return
	end
	prof.early[id] = math.min(prof.early[id] or math.huge, level)
	local new = checkUnlocks(prof)
	if #new > 0 then
		LevelUp:Fire(p, prof.level, new)
	end
	syncAttrs(p, prof)
end
-- Generic reward table: { xp?, zeni?, drinks?, unlock?, early = {id, level}?, title?, passXp? }
function PlayerData.grantReward(p: Player, r: any)
	local prof = profiles[p]
	if not prof or type(r) ~= "table" then
		return
	end
	if r.zeni then
		prof.zeni += r.zeni
	end
	if r.drinks then
		prof.drinks += r.drinks
	end
	if r.passXp then
		prof.passXp += r.passXp
	end
	if r.title then
		prof.title = r.title
	end
	if r.cosmetic then
		prof.unlocks[r.cosmetic] = true
	end
	if r.unlock then
		PlayerData.grantUnlock(p, r.unlock)
	end
	if r.early then
		PlayerData.grantEarly(p, r.early.id, r.early.level)
	end
	if r.xp then
		PlayerData.addXP(p, r.xp)
	end
	syncAttrs(p, prof)
	task.spawn(save, p, false)
end

-- Prestige: at max level, reset level/xp to 1/0, keep all unlocks, +1 prestige (divine unlocks, XP bonus).
function PlayerData.prestige(p: Player): boolean
	local prof = profiles[p]
	if not prof or prof.level < Config.MAX_LEVEL or prof.prestige >= Config.MAX_PRESTIGE then
		return false
	end
	prof.prestige += 1
	prof.level = 1
	prof.xp = 0
	local new = checkUnlocks(prof)
	LevelUp:Fire(p, prof.level, new)
	syncAttrs(p, prof)
	task.spawn(save, p, false)
	return true
end

function PlayerData.consumeSenzu(p: Player): boolean
	local prof = profiles[p]
	if prof and prof.senzu > 0 then
		prof.senzu -= 1
		syncAttrs(p, prof)
		return true
	end
	return false
end

local function applyPassUnlocks(p: Player, prof: Profile)
	for name, gp in Config.GAMEPASSES do
		if gp.unlock and ownsPass(p, name) and not gatedLocked(gp.unlock, prof) then
			prof.unlocks[gp.unlock] = true
		end
	end
end

local function onAdded(p: Player)
	local prof = load(p)
	if not prof then
		p:Kick("Could not load your data (it may be open on another server). Please rejoin.")
		return
	end
	if not p.Parent then -- left during load: release lock
		profiles[p] = prof
		save(p, true)
		profiles[p] = nil
		return
	end
	profiles[p] = prof
	applyPassUnlocks(p, prof)
	checkUnlocks(prof)
	syncAttrs(p, prof)
	p:SetAttribute("DataLoaded", true)
end

local function onRemoving(p: Player)
	if profiles[p] then
		save(p, true)
	end
	profiles[p] = nil
	passCache[p] = nil
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, bought)
	if not bought then
		return
	end
	for name, gp in Config.GAMEPASSES do
		if gp.id == passId then
			local c = passCache[p] or {}
			c[name] = true
			passCache[p] = c
			local prof = profiles[p]
			if prof and gp.unlock and not gatedLocked(gp.unlock, prof) then
				prof.unlocks[gp.unlock] = true
				syncAttrs(p, prof)
			end
		end
	end
end)

-- ProcessReceipt: grant only when profile loaded; dedupe via purchase history saved in profile,
-- and only return PurchaseGranted after a successful save.
local productById: { [number]: any } = {}
for _, pr in Config.PRODUCTS do
	if pr.id ~= 0 then
		productById[pr.id] = pr
	end
end

MarketplaceService.ProcessReceipt = function(info)
	local p = Players:GetPlayerByUserId(info.PlayerId)
	local prof = p and profiles[p]
	if not p or not prof then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local pr = productById[info.ProductId]
	if not pr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(prof.receipts, info.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- v8 safety net: a product tied to a level-gated catalog item is never granted while locked (Store refuses the
	-- prompt first; this only triggers if a prompt slipped through). NotYetProcessed = Roblox re-delivers later.
	for _, it in StoreCatalog.ITEMS do
		if it.robux and Config.PRODUCTS[it.robux] == pr and StoreCatalog.lockedFor(it, prof) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	local snapshot = deepCopy(prof)
	if pr.xp then
		PlayerData.addXP(p, pr.xp, false)
	end
	if pr.senzu then
		prof.senzu += pr.senzu
	end
	if pr.drinks then
		prof.drinks += pr.drinks
	end
	if pr.boostMinutes then
		prof.boostUntil = math.max(prof.boostUntil, os.time()) + pr.boostMinutes * 60
	end
	table.insert(prof.receipts, info.PurchaseId)
	while #prof.receipts > MAX_RECEIPTS do
		table.remove(prof.receipts, 1)
	end
	syncAttrs(p, prof)
	if save(p, false) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- save failed: restore snapshot so Roblox's retry re-grants exactly once
	for k in prof do
		(prof :: any)[k] = nil
	end
	for k, v in snapshot do
		(prof :: any)[k] = v
	end
	syncAttrs(p, prof)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function PlayerData.init()
	do
		local f = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") or Instance.new("Folder")
		f.Name = "Remotes"
		f.Parent = game:GetService("ReplicatedStorage")
		local r = f:FindFirstChild("ClaimDaily") :: RemoteEvent?
		if not r then
			local n = Instance.new("RemoteEvent")
			n.Name = "ClaimDaily"
			n.Parent = f
			r = n
		end
		local last: { [Player]: number } = {}
		(r :: RemoteEvent).OnServerEvent:Connect(function(p)
			if last[p] and os.clock() - last[p] < 2 then
				return
			end
			last[p] = os.clock()
			local reward = PlayerData.claimDaily(p)
			if reward then
				(r :: RemoteEvent):FireClient(p, reward, (profiles[p] :: Profile).dailyDay)
			end
		end)
	end
	Players.PlayerAdded:Connect(onAdded)
	Players.PlayerRemoving:Connect(onRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onAdded, p)
	end
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			for p in profiles do
				task.spawn(save, p, false)
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for p in profiles do
			pending += 1
			task.spawn(function()
				save(p, true)
				pending -= 1
			end)
		end
		local t = os.clock()
		while pending > 0 and os.clock() - t < 25 do
			task.wait()
		end
	end)
end

function PlayerData.isTutorialDone(p: Player): boolean
	local prof = profiles[p]
	return prof ~= nil and prof.tutorialDone == true
end

function PlayerData.completeTutorial(p: Player)
	local prof = profiles[p]
	if not prof or prof.tutorialDone then
		return
	end
	prof.tutorialDone = true
	prof.zeni = (prof.zeni or 0) + 1000
	local now = os.time()
	prof.boostUntil = math.max(prof.boostUntil or 0, now) + 1800 -- 30 min 2x XP boost
	syncAttrs(p, prof)
	PlayerData.addXP(p, 250, false)
	task.spawn(save, p, false)
end

return PlayerData
