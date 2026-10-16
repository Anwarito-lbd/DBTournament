--!strict
-- ModuleScript: ReplicatedStorage.Shared.EpisodeLogic  (v10; PURE: no Roblox APIs, unit-tested in gameplay/tests)
-- Validates StoryEpisodes definitions and owns the episode run state machine: act order, objective progress,
-- checkpoints, skip policy and the reward decision. StoryEpisodeService performs the side effects.
local EpisodeLogic = {}

local KINDS = { cinematic = true, train = true, boss = true, clash = true, hold = true }
local SIGNALS = { storyHit = true, parry = true, vanish = true }

local function clampNum(v: any, lo: number, hi: number, default: number): number
	local n = tonumber(v)
	if not n or n ~= n then return default end
	return math.clamp(n, lo, hi)
end

-- Returns (normalized list sorted by order, error strings). Bad episodes are skipped, never crash.
function EpisodeLogic.normalize(raw: any): ({ any }, { string })
	local out, errs = {}, {}
	if type(raw) ~= "table" then return out, { "StoryEpisodes.LIST is not a table" } end
	local seen = {}
	for i, e in raw do
		local tag = "#" .. tostring(i)
		if type(e) ~= "table" or type(e.id) ~= "string" or e.id == "" then
			table.insert(errs, tag .. " missing id"); continue
		end
		if seen[e.id] then table.insert(errs, e.id .. " duplicate id"); continue end
		if type(e.title) ~= "string" or type(e.lead) ~= "string" then table.insert(errs, e.id .. " missing title/lead"); continue end
		if type(e.acts) ~= "table" or #e.acts == 0 then table.insert(errs, e.id .. " has no acts"); continue end
		local ok = true
		local hasBoss = false
		for j, a in e.acts do
			if type(a) ~= "table" or not KINDS[a.kind] then
				table.insert(errs, ("%s act %d bad kind"):format(e.id, j)); ok = false; break
			end
			if a.kind == "cinematic" and type(a.beats) ~= "table" then
				table.insert(errs, ("%s act %d cinematic without beats"):format(e.id, j)); ok = false; break
			end
			if a.kind == "boss" or a.kind == "clash" or a.kind == "hold" then hasBoss = true end
			if a.kind == "boss" and a.untilHp ~= nil and (type(a.untilHp) ~= "number" or a.untilHp <= 0 or a.untilHp >= 1) then
				table.insert(errs, ("%s act %d untilHp must be in (0,1)"):format(e.id, j)); ok = false; break
			end
		end
		if ok and hasBoss and type(e.boss) ~= "table" then table.insert(errs, e.id .. " boss acts without boss def"); ok = false end
		if ok and type(e.objectives) == "table" then
			for _, o in e.objectives do
				if type(o) ~= "table" or not SIGNALS[o.signal] then
					table.insert(errs, e.id .. " objective with unknown signal"); ok = false; break
				end
			end
		end
		if not ok then continue end
		seen[e.id] = true
		local r = type(e.rewards) == "table" and e.rewards or {}
		e.rewards = {
			xp = clampNum(r.xp, 0, 5000, 0),
			zeni = clampNum(r.zeni, 0, 5000, 0),
			title = if type(r.title) == "string" then r.title else nil,
		}
		e.replayFraction = clampNum(e.replayFraction, 0, 1, 0.25)
		e.order = clampNum(e.order, 0, 1e6, i)
		e.objectives = if type(e.objectives) == "table" then e.objectives else {}
		table.insert(out, e)
	end
	table.sort(out, function(a, b) return a.order < b.order end)
	return out, errs
end

-- Sequential unlock: an episode needs the previous one (by order) cleared. `records` = profile.episodes.
function EpisodeLogic.unlocked(list: { any }, id: string, records: { [string]: any }?): boolean
	local prev: string? = nil
	for _, e in list do
		if e.id == id then
			return prev == nil or (records ~= nil and records[prev] ~= nil and records[prev].cleared == true)
		end
		prev = e.id
	end
	return false
end

export type Run = {
	id: string,
	act: number,
	checkpoint: number,
	progress: { [string]: number },
	deaths: number,
	firstClear: boolean,
	finished: boolean,
	result: string?,
}

-- firstClear = the player has never cleared this episode (drives skip policy + reward size)
function EpisodeLogic.newRun(def: any, firstClear: boolean): Run
	return { id = def.id, act = 1, checkpoint = 1, progress = {}, deaths = 0, firstClear = firstClear, finished = false, result = nil }
end

function EpisodeLogic.current(run: Run, def: any): any?
	return def.acts[run.act]
end

-- Moves to the next act; entering a checkpoint act records it. Returns the new act, or nil when the episode is complete.
function EpisodeLogic.advance(run: Run, def: any): any?
	if run.finished then return nil end
	run.act += 1
	local a = def.acts[run.act]
	if a and a.checkpoint then run.checkpoint = run.act end
	if a and a.kind == "train" then table.clear(run.progress) end
	return a
end

-- Objective signal during a train act. Returns true once every objective is met.
function EpisodeLogic.onSignal(run: Run, def: any, signal: string): boolean
	local a = def.acts[run.act]
	if run.finished or not a or a.kind ~= "train" then return false end
	for _, o in def.objectives do
		if o.signal == signal then
			run.progress[o.id] = math.min(o.count or 1, (run.progress[o.id] or 0) + 1)
		end
	end
	return EpisodeLogic.objectivesDone(run, def)
end

function EpisodeLogic.objectivesDone(run: Run, def: any): boolean
	for _, o in def.objectives do
		if (run.progress[o.id] or 0) < (o.count or 1) then return false end
	end
	return true
end

-- KO: resume at the last checkpoint act. Returns that act index.
function EpisodeLogic.onDeath(run: Run): number
	run.deaths += 1
	run.act = run.checkpoint
	return run.act
end

-- Long cinematics may only be skipped after the first clear (repeat runs see a short summary instead).
function EpisodeLogic.canSkip(run: Run, act: any): boolean
	return act ~= nil and act.kind == "cinematic" and not run.firstClear
end

-- Ends the run exactly once. result: "clear" | "quit" | "disconnect" | "failed".
-- Returns the reward table to grant (nil = nothing), and whether this was the first clear.
-- Full rewards on the first clear, replayFraction on repeats, nothing for anything but a real clear.
function EpisodeLogic.finish(run: Run, def: any, result: string): ({ xp: number, zeni: number, title: string? }?, boolean)
	if run.finished then return nil, false end
	run.finished = true
	run.result = result
	if result ~= "clear" then return nil, false end
	local r = def.rewards
	if run.firstClear then
		return { xp = r.xp, zeni = r.zeni, title = r.title }, true
	end
	local f = def.replayFraction or 0.25
	return { xp = math.floor(r.xp * f), zeni = math.floor(r.zeni * f), title = nil }, false
end

-- Updates the persisted per-episode record (profile.episodes[id]) after a clear. Returns the record.
function EpisodeLogic.recordClear(rec: any?, elapsed: number): any
	local r = if type(rec) == "table" then rec else { cleared = false, clears = 0 }
	r.cleared = true
	r.clears = (tonumber(r.clears) or 0) + 1
	if elapsed > 0 and (r.bestTime == nil or elapsed < r.bestTime) then r.bestTime = math.floor(elapsed * 10) / 10 end
	return r
end

-- Struggle maths shared by clash/hold (server loop + tests). Boss pushes `bossRate` per second against the player.
-- mode "clash": first to +/- winScore (or best score at maxTime) wins. mode "hold": player loses at -winScore,
-- wins by keeping the grip until maxTime. Returns "win" | "lose" | nil (still running).
function EpisodeLogic.struggleOutcome(mode: string, score: number, elapsed: number, cfg: any): string?
	if mode == "hold" then
		if score <= -cfg.winScore then return "lose" end
		if elapsed >= cfg.maxTime then return "win" end
		return nil
	end
	if score >= cfg.winScore then return "win" end
	if score <= -cfg.winScore then return "lose" end
	if elapsed >= cfg.maxTime then return if score > 0 then "win" else "lose" end
	return nil
end

return EpisodeLogic
