--!strict
-- Client-side hook for UI (ModuleScript: ReplicatedStorage.Shared.ClientAPI). Thin wrappers over remotes;
-- the server validates everything. UI reads player attributes: PowerLevel, KiCharge, Character, Form,
-- QueueMode, PartyLeader, Prestige, GiftBoost, GiftWindow, Fused, FusedPassenger, FusionState,
-- SpectateTarget, Ki, Guard, Blocking, Stunned, Tier, HurtboxScale, Level,
-- Team attributes: Budget, BudgetUsed, Picks (comma list; one per team), Level, XP, XPToNext, Alive, Spectating; workspace: RoundState, TimeLeft.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local function r(name: string): RemoteEvent return Remotes:WaitForChild(name) :: RemoteEvent end

local ClientAPI = {}
function ClientAPI.setQueueMode(mode: "Party" | "Random") r("QueueRequest"):FireServer("SetMode", mode) end
function ClientAPI.invite(userId: number) r("QueueRequest"):FireServer("Invite", userId) end
function ClientAPI.acceptInvite(leaderId: number) r("QueueRequest"):FireServer("Accept", leaderId) end
function ClientAPI.declineInvite(leaderId: number) r("QueueRequest"):FireServer("Decline", leaderId) end
function ClientAPI.leaveParty() r("QueueRequest"):FireServer("Leave") end
function ClientAPI.kick(userId: number) r("QueueRequest"):FireServer("Kick", userId) end
function ClientAPI.pickCharacter(charId: string) r("PickCharacter"):FireServer(charId) end
function ClientAPI.setCharging(on: boolean) r("KiCharge"):FireServer(on) end
function ClientAPI.transform(formId: string) r("Transform"):FireServer(formId) end
function ClientAPI.requestMove(moveId: string, targetPos: Vector3, origin: Vector3?) r("RequestMove"):FireServer(moveId, targetPos, origin) end
function ClientAPI.giftEnergy(targetUserId: number) r("GiftEnergy"):FireServer(targetUserId) end
function ClientAPI.spectate(targetUserId: number) r("SpectateRequest"):FireServer(targetUserId) end
function ClientAPI.requestFusion(method: "Dance" | "Potara", partnerUserId: number) r("FusionRequest"):FireServer(method, partnerUserId) end
function ClientAPI.cancelFusion() r("FusionCancel"):FireServer() end
function ClientAPI.block(down: boolean) r("Block"):FireServer(down) end
function ClientAPI.dash(dir: Vector3) r("Dash"):FireServer(dir) end
function ClientAPI.vanish(dir: Vector3?) r("Vanish"):FireServer(dir) end
function ClientAPI.comboBreak() r("ComboBreak"):FireServer() end
function ClientAPI.struggleInput() r("StruggleInput"):FireServer() end
function ClientAPI.useItem(item: string) r("UseItem"):FireServer(item) end
function ClientAPI.claimDaily() r("ClaimDaily"):FireServer() end
ClientAPI.onDailyReward = r("ClaimDaily").OnClientEvent -- (reward, day)
function ClientAPI.prestige() r("Prestige"):FireServer() end

-- Signals for UI: QueueState(state), PartyInvite(fromUserId, fromName), RoundState, PlayerEliminated, LevelUp
ClientAPI.onQueueState = r("QueueState").OnClientEvent
ClientAPI.onPartyInvite = r("PartyInvite").OnClientEvent
ClientAPI.onRoundState = r("RoundState").OnClientEvent
ClientAPI.onEliminated = r("PlayerEliminated").OnClientEvent
ClientAPI.onLevelUp = r("LevelUp").OnClientEvent
ClientAPI.onLastGift = r("LastGift").OnClientEvent -- (windowSeconds, candidateUserIds) -> show gift picker
ClientAPI.onFusionState = r("FusionState").OnClientEvent -- (state, data)
ClientAPI.onTeamCombo = r("TeamCombo").OnClientEvent -- (attackerId, partnerId, links, mult)
ClientAPI.onCombatEvent = r("CombatEvent").OnClientEvent -- (kind, data): Parry, GuardBreak, Dodged, DashCancel, Vanish, ComboBreaker, StruggleStart/Pulse/End, Absorb, Copy, Hit(vic,att,dmg,kb,ko), EnergyDrink
ClientAPI.onPickResult = r("PickResult").OnClientEvent -- (ok, charId, reason?) for character select UI
ClientAPI.onPlayVFX = r("PlayVFX").OnClientEvent -- (moveId|"Transform", character, target|preset)
-- v6: races/modifiers, Spirit Bomb, training drills, quests
function ClientAPI.toggleModifier(modId: string) r("ActivateModifier"):FireServer(modId) end -- e.g. "Kaioken_x10", "GiantForm"
function ClientAPI.releaseBeast() r("ReleaseBeast"):FireServer() end
function ClientAPI.giveKi(holding: boolean) r("GiveKi"):FireServer(holding) end -- Spirit Bomb donor (hold)
function ClientAPI.startDrill(id: string) r("StartDrill"):FireServer(id) end -- WhisDodge, CatchBubbles, HitGregory, HTCEndure, BeerusTrial
function ClientAPI.setGravity(g: number) r("SetGravity"):FireServer(g) end
function ClientAPI.claimQuest(scope: string, index: number) r("ClaimQuest"):FireServer(scope, index) end
function ClientAPI.rerollQuest(index: number) r("RerollQuest"):FireServer(index) end
function ClientAPI.onDrill(fn: (string, any) -> ()) return r("DrillUpdate").OnClientEvent:Connect(fn) end
function ClientAPI.onQuests(fn: (any) -> ()) return r("QuestUpdate").OnClientEvent:Connect(fn) end

-- v8: Dragon Balls / Shenron
function ClientAPI.collectDragonBall(i: number) r("CollectDragonBall"):FireServer(i) end
function ClientAPI.summonShenron() r("SummonShenron"):FireServer() end
function ClientAPI.makeWish(wishId: string, choice: string?) r("ShenronWish"):FireServer(wishId, choice) end
function ClientAPI.onDragonBalls(fn: (any) -> ()) return r("DragonBallState").OnClientEvent:Connect(fn) end
function ClientAPI.onShenron(fn: (any) -> ()) return r("ShenronWish").OnClientEvent:Connect(fn) end
-- v8: Ranked
function ClientAPI.queueRanked(format: string) r("RankedQueue"):FireServer(format) end -- "1v1" | "3v3"
function ClientAPI.leaveRanked() r("RankedLeave"):FireServer() end
function ClientAPI.requestLeaderboard() r("RankedLeaderboard"):FireServer() end
function ClientAPI.onRanked(fn: (any) -> ()) return r("RankedUpdate").OnClientEvent:Connect(fn) end
function ClientAPI.onLeaderboard(fn: (any) -> ()) return r("RankedLeaderboard").OnClientEvent:Connect(fn) end
-- v8: Raids
function ClientAPI.joinRaid(id: string) r("RaidJoin"):FireServer(id) end -- "Broly" | "Moro"
function ClientAPI.leaveRaid() r("RaidLeave"):FireServer() end
function ClientAPI.requestRaidInfo() r("RaidInfo"):FireServer() end
function ClientAPI.onRaid(fn: (any) -> ()) return r("RaidUpdate").OnClientEvent:Connect(fn) end
function ClientAPI.onRaidInfo(fn: (any) -> ()) return r("RaidInfo").OnClientEvent:Connect(fn) end
-- v8: Story
function ClientAPI.requestStory() r("StoryList"):FireServer() end
function ClientAPI.startStory(id: number) r("StoryStart"):FireServer(id) end
function ClientAPI.onStoryList(fn: (any) -> ()) return r("StoryList").OnClientEvent:Connect(fn) end
function ClientAPI.onStory(fn: (any) -> ()) return r("StoryUpdate").OnClientEvent:Connect(fn) end


-- WP11: Onboarding / Whis Tutorial
function ClientAPI.tutorialProgress(step: number, action: string) r("OnboardingAction"):FireServer("Progress", step, action) end
function ClientAPI.skipTutorial() r("OnboardingAction"):FireServer("Skip") end
function ClientAPI.onTutorial(fn: (string, any) -> ()) return r("OnboardingEvent").OnClientEvent:Connect(fn) end

return ClientAPI

