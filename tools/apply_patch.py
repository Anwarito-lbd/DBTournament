with open('team/gameplay/src/ServerScriptService/Modules/Combat.lua', 'r', encoding='utf-8') as f:
    text = f.read()

target = '	if mv.kind == "melee" then\n\t\tlocal toTarget = targetPos - root.Position\n\t\tlocal flatDist = math.clamp(toTarget.Magnitude, 3, mv.range)\n\t\ttargetPos = root.Position + root.CFrame.LookVector * flatDist\n\telse\n\t\tlocal toTarget = targetPos - root.Position\n\t\tif toTarget.Magnitude > mv.range + 50 then\n\t\t\ttargetPos = root.Position + toTarget.Unit * mv.range\n\t\tend\n\tend'

replacement = '''	if mv.kind == "melee" then
		local toTarget = targetPos - root.Position
		local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
		if flat.Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
			targetPos = root.Position + flat.Unit * math.clamp(flat.Magnitude, 3, mv.range + 4)
		else
			targetPos = root.Position + root.CFrame.LookVector * (mv.range or 7)
		end
	else
		local toTarget = targetPos - root.Position
		if toTarget.Magnitude > 0.1 then
			local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
			if flat.Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
			end
			if toTarget.Magnitude > mv.range + 50 then
				targetPos = root.Position + toTarget.Unit * mv.range
			end
		end
	end'''

if target in text:
    text = text.replace(target, replacement)
    with open('team/gameplay/src/ServerScriptService/Modules/Combat.lua', 'w', encoding='utf-8') as f:
        f.write(text)
    print('Combat.lua upgraded!')
else:
    print('Target not found in Combat.lua!')

# TrainingBots.lua area gate removal
tb_path = 'team/gameplay/src/ServerScriptService/Modules/TrainingBots.lua'
with open(tb_path, 'r', encoding='utf-8') as f:
    tb_text = f.read()

import re
tb_text = re.sub(r'if not BOT_AREAS\[att:GetAttribute\("TrainingArea"\)[^\]]*\] then return nil, targetPos end', '-- Area gate bypassed: bots can be sparred anywhere in training', tb_text)

with open(tb_path, 'w', encoding='utf-8') as f:
    f.write(tb_text)
print('TrainingBots.lua updated!')
