--!strict
-- Creates/fetches RemoteEvents under ReplicatedStorage.Remotes and server BindableEvents under ServerStorage.ServerHooks.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Net = {}

local function folder(parent: Instance, name: string): Instance
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
	return f :: Instance
end

function Net.remote(name: string): RemoteEvent
	local f = folder(ReplicatedStorage, "Remotes")
	local r = f:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = f end
	return r :: RemoteEvent
end

function Net.hook(name: string): BindableEvent
	local f = folder(ServerStorage, "ServerHooks")
	local b = f:FindFirstChild(name)
	if not b then b = Instance.new("BindableEvent"); b.Name = name; b.Parent = f end
	return b :: BindableEvent
end

return Net
