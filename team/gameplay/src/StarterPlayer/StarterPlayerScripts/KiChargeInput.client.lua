-- LocalScript: hold C (or gamepad X) to charge ki. Server validates (stand still, cap, rate limit).
local ContextActionService = game:GetService("ContextActionService")
local ClientAPI = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ClientAPI"))

ContextActionService:BindAction("ChargeKi", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ClientAPI.setCharging(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		ClientAPI.setCharging(false)
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.C, Enum.KeyCode.ButtonX)
