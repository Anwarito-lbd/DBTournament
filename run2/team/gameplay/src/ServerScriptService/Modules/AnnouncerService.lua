--!strict
-- ModuleScript: ServerScriptService.Modules.AnnouncerService (WP23)
-- Tournament of Power Announcer & Divine Reactions.
-- Features: Grand Priest elimination & stage calls, Zeno reactions, Bulma cheering from stands.
local Modules = script.Parent
local Net = require(Modules:WaitForChild("Net"))

local AnnouncerService = {}

local announcerRemote = Net.remote("AnnouncerEvent")

-- Line Catalogs
local GRAND_PRIEST_START = {
	"Warriors of the eight universes, let the Tournament of Power begin!",
	"Eighty warriors stand upon the stage. Fight with honor for your universe's survival!",
	"The Null Realm shall bear witness to the greatest battle in all creation. Begin!",
}

local GRAND_PRIEST_TIME = {
	HalfTime = "Half of the allotted time has elapsed. The battle intensifies!",
	OneMinute = "Only one minute remains in the Tournament of Power!",
	ThirtySeconds = "Thirty seconds remaining! All fighters, give everything you have!",
}

local ZENO_REACTIONS = {
	Eliminate = {
		"Sugoi! That was so fast!",
		"Whoa! Look at them fly!",
		"Hehehe! That was a really big hit!",
		"Did you see that? Clack clack clack!",
	},
	Wipe = {
		"Universe %d has no more fighters left! Bye-bye, Universe %d! Pshyuuu!",
		"All gone! Universe %d is erased! Poof!",
	},
	BeamClash = {
		"Waku waku! It's so bright!",
		"Push! Push! Which one's gonna win?!",
	},
}

local BULMA_CHEERS = {
	"Go Goku! Show them what Universe 7 can do!",
	"Vegeta, don't you dare get knocked out of the ring!",
	"Way to go! Keep it up, Universe 7!",
	"Gohan! Piccolo! Don't let your guard down!",
	"Finish them off, guys! We have to protect our universe!",
}

local lastBulmaCheer = 0
local lastZenoReaction = 0

local function pickRandom(list: { string }): string
	return list[math.random(1, #list)]
end

function AnnouncerService.announce(speaker: "GrandPriest" | "Zeno" | "Bulma", text: string, duration: number?)
	announcerRemote:FireAllClients({
		speaker = speaker,
		text = text,
		duration = duration or 3.5,
	})
end

function AnnouncerService.announceElimination(
	victimName: string,
	universe: number,
	killerName: string?,
	remaining: number
)
	local line = string.format(
		"Warrior %s of Universe %d has dropped out of the ring! %d fighters remain.",
		victimName,
		universe,
		remaining
	)
	AnnouncerService.announce("GrandPriest", line, 4.0)

	task.delay(1.8, function()
		if os.clock() - lastZenoReaction > 8.0 and math.random() < 0.45 then
			lastZenoReaction = os.clock()
			AnnouncerService.announce("Zeno", pickRandom(ZENO_REACTIONS.Eliminate), 3.0)
		end
	end)

	if universe ~= 7 and killerName and os.clock() - lastBulmaCheer > 12.0 then
		lastBulmaCheer = os.clock()
		task.delay(3.2, function()
			AnnouncerService.announce("Bulma", pickRandom(BULMA_CHEERS), 3.2)
		end)
	end
end

function AnnouncerService.announceUniverseWipe(universe: number)
	local gpLine = string.format(
		"All ten warriors of Universe %d have fallen. Universe %d will now be erased.",
		universe,
		universe
	)
	AnnouncerService.announce("GrandPriest", gpLine, 4.5)

	task.delay(2.2, function()
		local zenoLine = string.format(pickRandom(ZENO_REACTIONS.Wipe), universe, universe)
		AnnouncerService.announce("Zeno", zenoLine, 3.8)
	end)
end

function AnnouncerService.announceMatchStart()
	AnnouncerService.announce("GrandPriest", pickRandom(GRAND_PRIEST_START), 4.5)
	task.delay(2.5, function()
		AnnouncerService.announce("Zeno", "Waku waku! Let's watch! Yay!", 3.0)
	end)
end

function AnnouncerService.announceTimeWarning(kind: "HalfTime" | "OneMinute" | "ThirtySeconds")
	local line = GRAND_PRIEST_TIME[kind]
	if line then
		AnnouncerService.announce("GrandPriest", line, 4.0)
	end
end

function AnnouncerService.init()
	local eliminatedRemote = Net.remote("PlayerEliminated")
	eliminatedRemote.OnServerEvent:Connect(function() end)

	local roundStateRemote = Net.remote("RoundState")
	roundStateRemote.OnServerEvent:Connect(function() end)

	local roundStartedHook = Net.hook("RoundStarted")
	roundStartedHook.Event:Connect(function()
		AnnouncerService.announceMatchStart()
	end)

	local erasedHook = Net.hook("UniverseErased")
	erasedHook.Event:Connect(function(team: Team?, placement: number)
		local u = team and team:GetAttribute("Universe") or 0
		if typeof(u) == "number" and u > 0 then
			AnnouncerService.announceUniverseWipe(u)
		end
	end)
end

return AnnouncerService
