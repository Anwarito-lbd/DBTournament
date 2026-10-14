--!strict
-- ModuleScript: ReplicatedStorage.Shared.ReplayMath (WP-HOOK-2)
-- Pure math and sliding-window logic for match replays and best-moment highlight detection.
-- Guarantees: 10 Hz ring buffer (300 frames = 30s), sliding 8s max-damage window, < 2 MB memory for 40 players.
local ReplayMath = {}

ReplayMath.SAMPLE_RATE = 10 -- 10 Hz (every 100 ms)
ReplayMath.BUFFER_DURATION = 30 -- 30 seconds
ReplayMath.MAX_FRAMES = ReplayMath.SAMPLE_RATE * ReplayMath.BUFFER_DURATION -- 300 frames
ReplayMath.HIGHLIGHT_DURATION = 8 -- 8 seconds sliding window
ReplayMath.HIGHLIGHT_FRAMES = ReplayMath.SAMPLE_RATE * ReplayMath.HIGHLIGHT_DURATION -- 80 frames
ReplayMath.MAX_PLAYERS = 40

export type CompactFrame = {
	t: number,
	x: number,
	y: number,
	z: number,
	anim: string?,
	hp: number?,
}

export type DamageEvent = {
	t: number,
	attacker: string,
	victim: string,
	damage: number,
	combo: number,
}

export type HighlightWindow = {
	startTime: number,
	endTime: number,
	totalDamage: number,
	maxCombo: number,
	attacker: string,
	victim: string,
}

export type RingBuffer = {
	frames: { CompactFrame },
	head: number,
	count: number,
	maxSize: number,
}

function ReplayMath.newRingBuffer(maxSize: number?): RingBuffer
	local size = maxSize or ReplayMath.MAX_FRAMES
	return {
		frames = table.create(size) :: { CompactFrame },
		head = 1,
		count = 0,
		maxSize = size,
	}
end

function ReplayMath.pushFrame(buf: RingBuffer, frame: CompactFrame)
	buf.frames[buf.head] = frame
	buf.head = (buf.head % buf.maxSize) + 1
	if buf.count < buf.maxSize then
		buf.count += 1
	end
end

function ReplayMath.getFrames(buf: RingBuffer): { CompactFrame }
	local res: { CompactFrame } = table.create(buf.count)
	if buf.count < buf.maxSize then
		for i = 1, buf.count do
			res[i] = buf.frames[i]
		end
	else
		local startIdx = buf.head
		for i = 1, buf.maxSize do
			local idx = ((startIdx - 1 + (i - 1)) % buf.maxSize) + 1
			res[i] = buf.frames[idx]
		end
	end
	return res
end

-- Finds the 8-second window with the highest accumulated damage
function ReplayMath.findBestMoment(events: { DamageEvent }, duration: number?): HighlightWindow?
	if #events == 0 then
		return nil
	end
	local windowDur = duration or ReplayMath.HIGHLIGHT_DURATION

	local bestStart = events[1].t
	local bestDmg = -1
	local bestCombo = 0
	local bestAttacker = events[1].attacker
	local bestVictim = events[1].victim

	for i = 1, #events do
		local t0 = events[i].t
		local tEnd = t0 + windowDur
		local sumDmg = 0
		local maxC = 0
		local curAttacker = events[i].attacker
		local curVictim = events[i].victim

		for j = i, #events do
			local ev = events[j]
			if ev.t <= tEnd then
				sumDmg += ev.damage
				if ev.combo > maxC then
					maxC = ev.combo
				end
			else
				break
			end
		end

		if sumDmg > bestDmg then
			bestDmg = sumDmg
			bestStart = t0
			bestCombo = maxC
			bestAttacker = curAttacker
			bestVictim = curVictim
		end
	end

	return {
		startTime = bestStart,
		endTime = bestStart + windowDur,
		totalDamage = bestDmg,
		maxCombo = bestCombo,
		attacker = bestAttacker,
		victim = bestVictim,
	}
end

-- Computes estimated memory in bytes for 40 players at 300 frames each
function ReplayMath.estimateMemoryBytes(playerCount: number, framesPerPlayer: number): number
	-- Approx: table overhead (32 bytes) + 6 fields in compact frame (approx 48 bytes) = 80 bytes/frame
	local bytesPerFrame = 80
	return playerCount * framesPerPlayer * bytesPerFrame
end

return ReplayMath
