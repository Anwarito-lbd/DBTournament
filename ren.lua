local lib = game.ReplicatedStorage.CharacterModels
if lib:FindFirstChild("u7_frieza_alt") and not lib:FindFirstChild("npc_shenron_gen_alt") then
lib.u7_frieza.Name = "u7_frieza_tmp"; lib.u7_frieza_alt.Name = "u7_frieza"; lib.u7_frieza_tmp.Name = "u7_frieza_alt"
lib.npc_shenron.Name = "npc_shenron_gen_alt"
lib.super_dragon_ball.Name = "super_dragon_ball_gen_alt" end
local n = {} for _, c in lib:GetChildren() do table.insert(n, c.Name) end return table.concat(n, ",")
