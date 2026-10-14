--!strict
-- ModuleScript: ServerScriptService.Modules.TelegraphService (WP-STORY-2)
-- Server-side telegraph broadcaster and boss attack synchronizer.
-- Spawns ground indicators and yields until the exact attack contact frame.
local Modules = script.Parent
local Net = require(Modules:WaitForChild("Net"))
local Telegraphs = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Telegraphs"))

local TelegraphService = {}

local telegraphRemote = Net.remote("ShowTelegraph")

export type TelegraphData = {
	Shape: string,
	CFrame: CFrame,
	Color: Color3,
	Duration: number,
	Radius: number?,
	Angle: number?,
	Length: number?,
	Width: number?,
}

-- Broadcast a custom telegraph to all players
function TelegraphService.show(data: TelegraphData)
	telegraphRemote:FireAllClients(data)
end

-- Execute a boss attack with synchronized telegraph warning
function TelegraphService.cast(bossModel: Model, presetName: string, targetCFrame: CFrame, onFire: () -> ())
	local preset = Telegraphs.get(presetName)
	if not preset then
		onFire()
		return
	end

	local data: TelegraphData = {
		Shape = preset.Shape,
		CFrame = targetCFrame,
		Color = preset.Color,
		Duration = preset.Windup,
		Radius = preset.Radius,
		Angle = preset.Angle,
		Length = preset.Length,
		Width = preset.Width,
	}

	telegraphRemote:FireAllClients(data)

	-- Yield server execution until windup expires, then fire attack
	task.delay(preset.Windup, function()
		if bossModel.Parent then
			onFire()
		end
	end)
end

function TelegraphService.init()
	-- Ensure remote exists
	telegraphRemote.OnServerEvent:Connect(function() end)
end

return TelegraphService
