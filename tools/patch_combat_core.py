import re, os

# 1. Upgrade Combat.lua
combat_path = 'team/gameplay/src/ServerScriptService/Modules/Combat.lua'
with open(combat_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace melee direction handling
old_melee = r'if mv\.kind == melee then\s*local toTarget = targetPos - root\.Position\s*local flatDist = math\.clamp\(toTarget\.Magnitude, 3, mv\.range\)\s*targetPos = root\.Position \+ root\.CFrame\.LookVector \* flatDist\s*else\s*local toTarget = targetPos - root\.Position\s*if toTarget\.Magnitude > mv\.range \+ 50 then\s*targetPos = root\.Position \+ toTarget\.Unit \* mv\.range\s*end\s*end'

new_melee = '''if mv.kind == melee then
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

m = re.search(old_melee, text)
if m:
    text = text[:m.start()] + new_melee + text[m.end():]
    with open(combat_path, 'w', encoding='utf-8') as f:
        f.write(text)
    print('Combat.lua updated with responsive melee facing!')
else:
    print('Combat.lua regex did not match old_melee')

# 2. Upgrade TrainingBots.lua
tb_path = 'team/gameplay/src/ServerScriptService/Modules/TrainingBots.lua'
with open(tb_path, 'r', encoding='utf-8') as f:
    tb_text = f.read()

# Remove training area gate in hitScan
old_gate = 'if not BOT_AREAS[att:GetAttribute(TrainingArea) :: any] then return nil, targetPos end'
new_gate = '-- Area gate removed: bots can be attacked anywhere in training/lobby'
if old_gate in tb_text:
    tb_text = tb_text.replace(old_gate, new_gate)
    print('TrainingBots.lua hitScan area gate removed!')

# Expand melee and ray hit tolerances
old_melee_check = 'if d <= (mv.range or 7) + 2.5 and (d < 2 or dir:Dot(rel.Unit) >= 0.3) and d < bestD then'
new_melee_check = 'if d <= (mv.range or 7) + 5.0 and (d < 4.5 or dir:Dot(rel.Unit) >= 0.12) and d < bestD then'
if old_melee_check in tb_text:
    tb_text = tb_text.replace(old_melee_check, new_melee_check)
    print('TrainingBots.lua melee hit tolerance expanded!')

old_ray_check = 'if perp <= (mv.width or 1) + 2.5 and along < bestD then'
new_ray_check = 'if perp <= (mv.width or 3.5) + 3.5 and along < bestD then'
if old_ray_check in tb_text:
    tb_text = tb_text.replace(old_ray_check, new_ray_check)
    print('TrainingBots.lua ray hit tolerance expanded!')

with open(tb_path, 'w', encoding='utf-8') as f:
    f.write(tb_text)
