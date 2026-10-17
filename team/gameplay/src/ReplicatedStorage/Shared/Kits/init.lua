--!nonstrict
-- ModuleScript: ReplicatedStorage.Shared.Kits (registry)
-- Every fighter's identity in one place: each race family is a child ModuleScript (Kits/<Race>/init.lua) with
-- race-wide defaults plus a per-character entry, so Goku and Vegeta stay different even though both are Saiyans.
-- A race folder may carry its own effects (Kits/<Race>/VFX/<Module>.lua) and clip sets (Kits/<Race>/Poses/<Set>.lua),
-- so kit work never edits the shared game files. Everything falls back to the existing tables (TransformCinematic
-- STYLE, VFXRouter overrides, FightAnimator clip sets, Config.MOVES) when a kit says nothing.
--
-- A kit module returns:
-- {
--   race = "Saiyan",
--   defaults = <CharKit>,                -- race-wide; any field
--   characters = { [charId] = <CharKit> }, -- per fighter; wins over defaults field by field
-- }
-- CharKit fields (all optional):
--   clips      = "Vegeta"                 -- clip-set module in <Race>/Poses (or the shared Poses folder)
--   signatures = { [moveKind] = "FinalFlashVFX" } -- effect module for a server move kind (VFX folder or <Race>/VFX)
--   cameras    = { [moveKind] = { zoom = 8, shake = 0.4, slowmo = 0 } } -- local player's camera on that move
--   powerUp    = { aura = "Default", color = Color3, zoom = 6, screamStage = 3, crack = 1.0 } -- hold-to-charge look
--   forms      = { [vfxPreset] = <TransformCinematic style> } -- title, color, flash, lightning, crack, orbit, dur, ...
--   moves      = { [moveId] = <Config.MOVES entry> } -- extra kit moves using existing server kinds
local Kits = {}

type Entry = { kit: any, inst: Instance }
local entries: { Entry } = {}
local byChar: { [string]: Entry } = {}

for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, kit = pcall(require, child)
		if ok and type(kit) == "table" then
			local e = { kit = kit, inst = child }
			table.insert(entries, e)
			for id in (kit.characters or {}) do
				byChar[id] = e
			end
		elseif not ok then
			warn(string.format("[Kits] %s failed to load: %s", child.Name, tostring(kit)))
		end
	end
end

local function field(charId: string?, name: string): any
	local e = charId and byChar[charId]
	if not e then return nil end
	local c = e.kit.characters[charId]
	local d = e.kit.defaults
	local v = c and c[name]
	if v ~= nil then return v end
	return d and d[name]
end

-- a keyed sub-table lookup with the character's entry winning over the race default (e.g. signatures.Kamehameha)
local function keyed(charId: string?, name: string, key: string): any
	local e = charId and byChar[charId]
	if not e then return nil end
	local c = e.kit.characters[charId]
	local t = c and c[name]
	if t and t[key] ~= nil then return t[key] end
	local d = e.kit.defaults and e.kit.defaults[name]
	return d and d[key]
end

function Kits.race(charId: string?): string?
	local e = charId and byChar[charId]
	return e and e.kit.race
end

function Kits.signature(charId: string?, kind: string): string?
	return keyed(charId, "signatures", kind)
end

function Kits.camera(charId: string?, kind: string): any
	return keyed(charId, "cameras", kind)
end

function Kits.powerUp(charId: string?): any
	return field(charId, "powerUp")
end

function Kits.formStyle(charId: string?, preset: string): any
	return keyed(charId, "forms", preset)
end

-- the clip-set ModuleScript for a character: <Race>/Poses/<name>, else nil (callers fall back to the shared Poses)
function Kits.clipModule(charId: string?): ModuleScript?
	local e = charId and byChar[charId]
	local name = field(charId, "clips")
	if not e or type(name) ~= "string" then return nil end
	local folder = e.inst:FindFirstChild("Poses")
	local m = folder and folder:FindFirstChild(name)
	return if m and m:IsA("ModuleScript") then m else nil
end

-- the clip-set name a kit asks for (for sets that live in the shared Poses folder)
function Kits.clipName(charId: string?): string?
	local name = field(charId, "clips")
	return if type(name) == "string" then name else nil
end

-- an effect module shipped inside a kit folder (<Race>/VFX/<name>)
function Kits.findModule(name: string): ModuleScript?
	for _, e in entries do
		local folder = e.inst:FindFirstChild("VFX")
		local m = folder and folder:FindFirstChild(name)
		if m and m:IsA("ModuleScript") then return m end
	end
	return nil
end

-- every extra move the kits define (merged into Config.MOVES when an id is free)
function Kits.moves(): { [string]: any }
	local out = {}
	for _, e in entries do
		local d = e.kit.defaults
		for id, mv in (d and d.moves) or {} do
			out[id] = mv
		end
		for _, c in e.kit.characters or {} do
			for id, mv in c.moves or {} do
				out[id] = mv
			end
		end
	end
	return out
end

return Kits
