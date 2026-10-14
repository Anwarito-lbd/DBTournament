with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'r', encoding='utf-8') as f:
    text = f.read()

anime_faces_block = '''
local ANIME_FACES: { [string]: { [string]: string } } = {
	goku = {
		Base = rbxassetid://33395283,
		KaioKen = rbxassetid://33397568,
		SuperSaiyan = rbxassetid://33397568,
		SuperSaiyan2 = rbxassetid://33397568,
		SuperSaiyan3 = rbxassetid://33397568,
		SuperSaiyanGod = rbxassetid://261218098,
		SuperSaiyanBlue = rbxassetid://261218098,
		SSBEvolved = rbxassetid://261218098,
		UltraInstinctSign = rbxassetid://33397568,
		MUI = rbxassetid://33397568,
	},
	vegeta = {
		Base = rbxassetid://222129434,
		SuperSaiyan = rbxassetid://222129434,
		SuperSaiyan2 = rbxassetid://222129434,
		SuperSaiyanGod = rbxassetid://222129434,
		SuperSaiyanBlue = rbxassetid://222129434,
		SSBEvolved = rbxassetid://222129434,
		UltraEgo = rbxassetid://222129434,
	},
	default = {
		Base = rbxassetid://33395283,
		SuperSaiyan = rbxassetid://33397568,
		SuperSaiyanBlue = rbxassetid://261218098,
		MUI = rbxassetid://33397568,
	}
}

local function applyFace(char: Model, charId: string, formId: string)
	local head = char:FindFirstChild(Head) :: BasePart?
	if not head then return end
	local decal = head:FindFirstChildOfClass(Decal)
	if not decal then
		decal = Instance.new(Decal)
		decal.Name = face
		decal.Face = Enum.NormalId.Front
		decal.Parent = head
	end
	local key = if charId:find(vegeta) then vegeta elseif charId:find(goku) then goku else default
	local set = ANIME_FACES[key] or ANIME_FACES.default
	decal.Texture = set[formId] or set.Base
end
'''

# Insert ANIME_FACES before cleanAnimeAssets
target = 'local function cleanAnimeAssets'
text = text.replace(target, anime_faces_block + '\n' + target)

# Call applyFace in applyAnimeStyle
target_style = 'return true\nend\n\nfunction AvatarSlots.applyForm'
repl_style = '	applyFace(char, charId, Base)\n\treturn true\nend\n\nfunction AvatarSlots.applyForm'
text = text.replace(target_style, repl_style)

# Call applyFace in applyForm
target_form = 'function AvatarSlots.applyForm(char: Model, charId: string?, formId: string)\n\tif not char or not char.Parent then return end'
repl_form = 'function AvatarSlots.applyForm(char: Model, charId: string?, formId: string)\n\tif not char or not char.Parent then return end\n\tapplyFace(char, charId or ", formId)'
text = text.replace(target_form, repl_form)

with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'w', encoding='utf-8') as f:
 f.write(text)

print('AvatarSlots.lua updated with anime face decals!')
