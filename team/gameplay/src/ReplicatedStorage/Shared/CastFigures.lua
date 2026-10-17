--!strict
-- ModuleScript: ReplicatedStorage.Shared.CastFigures
-- The Tournament of Power's ever-present cast as rigged Style B figures built in-engine from primitives (no imported
-- art): Zeno and Future Zeno, the Grand Priest, and Zeno's attendants. Designs follow the Dragon Ball wiki references:
--   Zeno: very short, large oval head that is sky blue down the middle and purple on the upper sides, small round eyes
--     where the colours meet, grey rounded "ears", magenta coat lined in yellow over a grey shirt with a stylised
--     kanji for "all", yellow pants, pointed magenta shoes.
--   Grand Priest: short angel, sky-blue skin, white swept-up hair, light-blue halo floating behind his head, petrol-blue
--     shirt with puffy shoulders and an orange triangle, red belt with a gold "Grand" buckle, baggy jodhpurs, white
--     boots, hands clasped behind his back.
--   Attendants: very tall, faceless, a long magenta coat with yellow trim and rows of gold clasps, grey bellows at the
--     shoulders, a cyan dome with an antenna on top.
-- build(kind, feet, height) -> Model. The model's Root (anchored, at the feet) is its PrimaryPart; everything else is
-- welded to bones joined by Motor6Ds named Waist, Neck, ShoulderL and ShoulderR, so anim() can pose them.
-- Attribute CastRig = kind. Kinds: "Zeno", "FutureZeno", "GrandPriest", "Attendant".
local TweenService = game:GetService("TweenService")

local CastFigures = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

type Builder = {
	m: Model,
	u: number,
	base: CFrame,
	bone: (name: string, at: Vector3) -> BasePart,
	joint: (name: string, parent: BasePart, child: BasePart, at: Vector3, rest: CFrame?) -> Motor6D,
	piece: (bone: BasePart, name: string, kind: string, size: Vector3, at: CFrame, color: Color3, mat: Enum.Material?) -> BasePart,
}

local function newBuilder(kind: string, feet: CFrame, u: number): Builder
	local m = Instance.new("Model")
	m.Name = "Story_" .. kind
	local b = {} :: Builder
	b.m, b.u, b.base = m, u, feet
	local function finish(p: BasePart)
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
	end
	function b.bone(name: string, at: Vector3): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.one * 0.2
		p.Transparency = 1
		p.CFrame = feet * CFrame.new(at * u)
		finish(p)
		return p
	end
	function b.joint(name: string, parent: BasePart, child: BasePart, at: Vector3, rest: CFrame?): Motor6D
		local j = Instance.new("Motor6D")
		j.Name = name
		local jcf = feet * CFrame.new(at * u)
		local c0 = parent.CFrame:ToObjectSpace(jcf)
		j:SetAttribute("BaseC0", c0)
		j.C0 = c0 * (rest or CFrame.identity)
		j:SetAttribute("RestC0", j.C0)
		j.C1 = child.CFrame:ToObjectSpace(jcf)
		j.Part0, j.Part1 = parent, child
		j.Parent = parent
		return j
	end
	-- kind: "ball" (ellipsoid), "block", "cyl" (round, along X), "wedge"
	function b.piece(bone: BasePart, name: string, kind: string, size: Vector3, at: CFrame, color: Color3, mat: Enum.Material?): BasePart
		local p = Instance.new(if kind == "wedge" then "WedgePart" else "Part") :: BasePart
		if kind == "cyl" then (p :: Part).Shape = Enum.PartType.Cylinder end
		if kind == "ball" then
			local sm = Instance.new("SpecialMesh")
			sm.MeshType = Enum.MeshType.Sphere
			sm.Parent = p
		end
		p.Name = name
		p.Size = size * u
		p.CFrame = feet * (CFrame.new(at.Position * u) * at.Rotation)
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		finish(p)
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = bone, p
		w.Parent = p
		return p
	end
	return b
end

local function at(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

-- front (-Z) surface depth of an ellipsoid centred at c with radii r, at (x, y)
local function front(c: Vector3, r: Vector3, x: number, y: number): number
	local k = 1 - ((x - c.X) / r.X) ^ 2 - ((y - c.Y) / r.Y) ^ 2
	return c.Z - r.Z * math.sqrt(math.max(k, 0))
end

-- a thin flat triangle from two wedges, in builder units, welded to bone
local function tri(b: Builder, bone: BasePart, name: string, a: Vector3, bb: Vector3, c: Vector3, color: Color3, thick: number)
	local ab, ac, bc = bb - a, c - a, c - bb
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, bb = bb, a
	end
	ab, ac, bc = bb - a, c - a, c - bb
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local h = math.abs(ab:Dot(up))
	b.piece(bone, name, "wedge", Vector3.new(thick, h, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + bb) / 2, right, up, back), color)
	b.piece(bone, name, "wedge", Vector3.new(thick, h, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color)
end

local function outline(m: Model)
	local h = Instance.new("Highlight")
	h.Name = "Outline"
	h.FillTransparency = 1
	h.OutlineColor = rgb(24, 14, 36)
	h.OutlineTransparency = 0.3
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = m
end

-- ===== Zeno (about 9.9 units tall) =====
local function zeno(b: Builder, seated: boolean)
	local SKIN, CAP, EAR = rgb(96, 186, 244), rgb(122, 48, 186), rgb(150, 152, 162)
	local COAT, TRIM, PANTS, SHIRT = rgb(196, 32, 142), rgb(252, 210, 40), rgb(250, 206, 44), rgb(104, 104, 114)
	local root = b.bone("Root", Vector3.zero)
	root.Anchored = true
	local torso = b.bone("Torso", Vector3.new(0, 1.6, 0))
	local head = b.bone("Head", Vector3.new(0, 5.4, 0))
	local armL, armR = b.bone("ArmL", Vector3.new(-1.9, 4.9, 0)), b.bone("ArmR", Vector3.new(1.9, 4.9, 0))
	b.joint("Waist", root, torso, Vector3.new(0, 1.6, 0))
	b.joint("Neck", torso, head, Vector3.new(0, 5.4, 0))
	b.joint("ShoulderL", torso, armL, Vector3.new(-1.9, 4.9, 0), CFrame.Angles(0, 0, math.rad(-8)))
	b.joint("ShoulderR", torso, armR, Vector3.new(1.9, 4.9, 0), CFrame.Angles(0, 0, math.rad(8)))
	-- legs and pointed shoes (seated: legs straight out in front of the hips)
	for _, x in { -0.62, 0.62 } do
		if seated then
			b.piece(root, "Leg", "block", Vector3.new(0.85, 0.85, 1.4), at(x, 1.55, -0.8), PANTS)
			b.piece(root, "Shoe", "ball", Vector3.new(1.0, 1.5, 0.6), at(x, 1.75, -1.75), COAT)
			b.piece(root, "ShoeTip", "wedge", Vector3.new(0.5, 0.8, 0.45), at(x, 2.6, -1.77, -90, 180, 0), COAT)
		else
			b.piece(root, "Leg", "block", Vector3.new(0.85, 1.3, 0.85), at(x, 1.0, 0), PANTS)
			b.piece(root, "Shoe", "ball", Vector3.new(1.0, 0.6, 1.5), at(x, 0.3, -0.25), COAT)
			b.piece(root, "ShoeTip", "wedge", Vector3.new(0.5, 0.45, 0.8), at(x, 0.32, -1.2, 0, 180, 0), COAT)
		end
	end
	-- coat: back and sides, open front over the shirt, yellow lining, flared hem, standing collar
	b.piece(torso, "Coat", "block", Vector3.new(3.5, 3.8, 2.3), at(0, 3.35, 0.15), COAT)
	b.piece(torso, "CoatHem", "block", Vector3.new(3.9, 1.1, 2.6), at(0, 1.85, 0.12), COAT)
	b.piece(torso, "HemTrim", "block", Vector3.new(3.95, 0.24, 2.65), at(0, 1.3, 0.12), TRIM)
	b.piece(torso, "Shirt", "block", Vector3.new(1.9, 3.3, 0.2), at(0, 3.55, -1.06), SHIRT)
	for _, s in { -1, 1 } do
		b.piece(torso, "Lapel", "block", Vector3.new(0.95, 4.0, 0.24), at(s * 1.37, 3.3, -1.1), COAT)
		b.piece(torso, "LapelTrim", "block", Vector3.new(0.24, 4.0, 0.26), at(s * 0.92, 3.3, -1.12), TRIM)
		b.piece(torso, "Collar", "block", Vector3.new(0.35, 1.5, 1.3), at(s * 1.35, 5.55, 0.15, 0, 0, s * -18), TRIM)
	end
	b.piece(torso, "CollarBack", "block", Vector3.new(2.9, 1.1, 0.35), at(0, 5.5, 0.95), COAT)
	-- the shirt's stylised kanji: a black roof over three white bars
	for _, s in { -1, 1 } do
		b.piece(torso, "KanjiRoof", "block", Vector3.new(1.05, 0.2, 0.08), at(s * 0.36, 4.62, -1.18, 0, 0, s * -32), rgb(20, 20, 26))
	end
	for i, y in { 4.05, 3.45, 2.85 } do
		b.piece(torso, "KanjiBar" .. i, "block", Vector3.new(if i == 2 then 1.15 else 1.45, 0.22, 0.08), at(0, y, -1.18), rgb(244, 244, 248))
	end
	b.piece(torso, "KanjiStem", "block", Vector3.new(0.2, 1.2, 0.07), at(0, 3.45, -1.17), rgb(244, 244, 248))
	-- arms: magenta sleeves, yellow cuffs, small blue hands
	for _, a in { { bone = armL, s = -1 }, { bone = armR, s = 1 } } do
		local bone, s = a.bone, a.s
		local x = s * 1.9
		b.piece(bone, "Sleeve", "ball", Vector3.new(1.05, 2.4, 1.05), at(x, 3.8, 0), COAT)
		b.piece(bone, "Cuff", "cyl", Vector3.new(0.3, 0.95, 0.95), at(x, 2.75, 0, 0, 0, 90), TRIM)
		b.piece(bone, "Hand", "ball", Vector3.new(0.75, 0.85, 0.75), at(x, 2.3, 0), SKIN)
	end
	-- head: blue ellipsoid, purple upper sides, eyes on the seam, grey ears, small smile
	local hc, hr = Vector3.new(0, 7.6, 0), Vector3.new(3.2, 2.3, 2.4)
	b.piece(head, "Skull", "ball", hr * 2, at(hc.X, hc.Y, hc.Z), SKIN)
	for _, s in { -1, 1 } do
		-- sized to stay inside the head's silhouette, so the purple reads as markings, not a helmet
		b.piece(head, "Cap", "ball", Vector3.new(4.0, 3.6, 4.7), at(s * 1.25, hc.Y + 0.45, 0.05), CAP)
		local ex, ey = s * 1.3, hc.Y + 0.35
		local ez = math.min(front(hc, hr, ex, ey), front(Vector3.new(s * 1.25, hc.Y + 0.45, 0.05), Vector3.new(2.0, 1.8, 2.35), ex, ey))
		b.piece(head, "EyeWhite", "ball", Vector3.new(0.85, 0.85, 0.3), at(ex, ey, ez - 0.02), rgb(250, 250, 255))
		b.piece(head, "Eye", "ball", Vector3.new(0.5, 0.5, 0.28), at(ex, ey, ez - 0.1), rgb(16, 14, 24))
		b.piece(head, "Ear", "cyl", Vector3.new(0.8, 1.3, 1.3), at(s * 3.18, hc.Y + 0.1, 0.2), EAR)
		b.piece(head, "EarCap", "cyl", Vector3.new(0.15, 0.9, 0.9), at(s * 3.62, hc.Y + 0.1, 0.2), rgb(120, 122, 132))
	end
	for i, x in { -0.32, 0, 0.32 } do
		local y = hc.Y - 0.95 + (if i == 2 then -0.08 else 0)
		b.piece(head, "Mouth", "block", Vector3.new(0.34, 0.08, 0.08), at(x, y, front(hc, hr, x, y) + 0.02, 0, 0, (i - 2) * -22), rgb(30, 20, 40))
	end
	return root
end

-- ===== Grand Priest (about 10.4 units tall) =====
local function grandPriest(b: Builder)
	local SKIN, HAIR, SHIRT = rgb(140, 176, 232), rgb(244, 246, 252), rgb(34, 92, 112)
	local ORANGE, BELT, GOLD, BOOT, HALO = rgb(246, 120, 32), rgb(200, 32, 44), rgb(240, 196, 70), rgb(244, 244, 248), rgb(140, 206, 246)
	local root = b.bone("Root", Vector3.zero)
	root.Anchored = true
	local torso = b.bone("Torso", Vector3.new(0, 3.7, 0))
	local head = b.bone("Head", Vector3.new(0, 6.9, 0))
	local armL, armR = b.bone("ArmL", Vector3.new(-1.35, 6.3, 0)), b.bone("ArmR", Vector3.new(1.35, 6.3, 0))
	b.joint("Waist", root, torso, Vector3.new(0, 3.7, 0))
	b.joint("Neck", torso, head, Vector3.new(0, 6.9, 0))
	-- rest pose: hands clasped behind his back
	b.joint("ShoulderL", torso, armL, Vector3.new(-1.35, 6.3, 0), CFrame.Angles(math.rad(-32), 0, math.rad(14)))
	b.joint("ShoulderR", torso, armR, Vector3.new(1.35, 6.3, 0), CFrame.Angles(math.rad(-32), 0, math.rad(-14)))
	-- boots and baggy jodhpurs
	for _, x in { -0.56, 0.56 } do
		b.piece(root, "Boot", "cyl", Vector3.new(1.7, 0.95, 0.95), at(x, 0.95, 0, 0, 0, 90), BOOT)
		b.piece(root, "BootToe", "ball", Vector3.new(0.95, 0.6, 1.3), at(x, 0.3, -0.25), BOOT)
		b.piece(root, "Knee", "ball", Vector3.new(1.05, 1.1, 1.05), at(x, 1.95, 0), SHIRT)
		b.piece(root, "Thigh", "ball", Vector3.new(1.5, 2.3, 1.55), at(x * 1.08, 2.95, 0), SHIRT)
	end
	-- shirt, flat chest with the orange triangle, puffy shoulders, high collar, red belt with the gold buckle
	b.piece(torso, "Body", "ball", Vector3.new(2.5, 3.0, 1.75), at(0, 5.2, 0), SHIRT)
	b.piece(torso, "Waistband", "block", Vector3.new(2.25, 1.0, 1.5), at(0, 4.3, 0), SHIRT)
	b.piece(torso, "Chest", "block", Vector3.new(1.9, 1.9, 0.2), at(0, 5.55, -0.76), SHIRT)
	tri(b, torso, "Triangle", Vector3.new(-0.72, 6.15, -0.88), Vector3.new(0.72, 6.15, -0.88), Vector3.new(0, 5.05, -0.88), ORANGE, 0.06)
	for _, s in { -1, 1 } do
		b.piece(torso, "Shoulder", "ball", Vector3.new(1.55, 1.45, 1.55), at(s * 1.32, 6.3, 0), SHIRT)
	end
	b.piece(torso, "Collar", "cyl", Vector3.new(0.6, 1.25, 1.25), at(0, 6.8, 0, 0, 0, 90), SHIRT)
	b.piece(torso, "Belt", "block", Vector3.new(2.45, 0.45, 1.62), at(0, 3.85, 0), BELT)
	local buckle = b.piece(torso, "Buckle", "cyl", Vector3.new(0.2, 0.8, 0.8), at(0, 3.85, -0.86, 0, 90, 0), GOLD)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Right -- after the 90 degree turn the cylinder's +X face looks toward -Z (front)
	sg.CanvasSize = Vector2.new(100, 100)
	sg.LightInfluence = 0.5
	sg.Parent = buckle
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.8, 0.8)
	t.Position = UDim2.fromScale(0.1, 0.1)
	t.Text = utf8.char(0x5927)
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = BELT
	t.Parent = sg
	-- arms: puffy sleeves, small blue hands
	for _, a in { { bone = armL, s = -1 }, { bone = armR, s = 1 } } do
		local bone, s = a.bone, a.s
		b.piece(bone, "Sleeve", "ball", Vector3.new(0.85, 2.3, 0.85), at(s * 1.42, 5.1, 0), SHIRT)
		b.piece(bone, "Cuff", "cyl", Vector3.new(0.25, 0.7, 0.7), at(s * 1.42, 4.0, 0, 0, 0, 90), SHIRT)
		b.piece(bone, "Hand", "ball", Vector3.new(0.5, 0.62, 0.5), at(s * 1.42, 3.7, 0), SKIN)
	end
	-- head: face, purple eyes, hooked brows, small mouth
	local hc, hr = Vector3.new(0, 8.0, 0), Vector3.new(1.3, 1.45, 1.3)
	b.piece(head, "Neck", "cyl", Vector3.new(0.8, 0.7, 0.7), at(0, 7.0, 0, 0, 0, 90), SKIN)
	b.piece(head, "Skull", "ball", hr * 2, at(hc.X, hc.Y, hc.Z), SKIN)
	for _, s in { -1, 1 } do
		local ex, ey = s * 0.46, hc.Y + 0.05
		local ez = front(hc, hr, ex, ey)
		b.piece(head, "EyeWhite", "ball", Vector3.new(0.56, 0.34, 0.12), at(ex, ey, ez + 0.02), rgb(250, 248, 255))
		b.piece(head, "Eye", "ball", Vector3.new(0.3, 0.3, 0.1), at(ex + s * 0.03, ey - 0.01, ez - 0.03), rgb(122, 72, 176))
		b.piece(head, "Pupil", "ball", Vector3.new(0.12, 0.14, 0.06), at(ex + s * 0.03, ey - 0.01, ez - 0.07), rgb(24, 12, 36))
		b.piece(head, "Brow", "block", Vector3.new(0.48, 0.06, 0.06), at(s * 0.48, ey + 0.36, front(hc, hr, s * 0.48, ey + 0.36) - 0.02, 0, 0, s * -14), rgb(60, 70, 110))
		b.piece(head, "BrowHook", "block", Vector3.new(0.18, 0.06, 0.06), at(s * 0.76, ey + 0.27, front(hc, hr, s * 0.76, ey + 0.27) - 0.02, 0, 0, s * 40), rgb(60, 70, 110))
		b.piece(head, "Ear", "ball", Vector3.new(0.25, 0.55, 0.4), at(s * 1.28, hc.Y, 0.05), SKIN)
	end
	b.piece(head, "Nose", "ball", Vector3.new(0.16, 0.22, 0.14), at(0, hc.Y - 0.32, front(hc, hr, 0, hc.Y - 0.32) - 0.04), rgb(126, 160, 218))
	b.piece(head, "Mouth", "block", Vector3.new(0.34, 0.05, 0.05), at(0, hc.Y - 0.68, front(hc, hr, 0, hc.Y - 0.68) - 0.01), rgb(70, 50, 100))
	-- white hair: a cap plus swept-up spikes leaning back
	b.piece(head, "HairCap", "ball", Vector3.new(2.72, 1.7, 2.72), at(0, hc.Y + 0.75, 0.12), HAIR)
	for i = -4, 4 do
		local x = i * 0.24
		local tall = 1.35 + (4 - math.abs(i)) * 0.18
		local base = Vector3.new(x, hc.Y + 1.2, 0.05 + math.abs(i) * 0.03)
		local dir = Vector3.new(i * 0.07, 1, 0.42).Unit
		-- WedgePart: thick end (+Z) at the root, tip along dir
		b.piece(head, "HairSpike", "wedge", Vector3.new(0.34, 0.5, tall), CFrame.lookAt(base + dir * tall / 2, base + dir * tall, Vector3.zAxis), HAIR)
	end
	-- halo floating behind the head
	local n, R = 28, 1.8
	local c = Vector3.new(0, hc.Y + 0.3, 0.75)
	for i = 1, n do
		local a0, a1 = (i - 1) / n * math.pi * 2, i / n * math.pi * 2
		local p0, p1 = c + Vector3.new(math.cos(a0) * R, math.sin(a0) * R, 0), c + Vector3.new(math.cos(a1) * R, math.sin(a1) * R, 0)
		local p = b.piece(head, "Halo", "cyl", Vector3.new((p1 - p0).Magnitude + 0.05, 0.16, 0.16),
			CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.Angles(0, math.pi / 2, 0), HALO, Enum.Material.Neon)
		p.Transparency = 0.1
		p.CastShadow = false
	end
	return root
end

-- ===== attendant (about 11.4 units tall) =====
local function attendant(b: Builder)
	local COAT, TRIM, CLASP, GREY, DOME = rgb(150, 38, 170), rgb(252, 214, 44), rgb(236, 186, 52), rgb(150, 150, 162), rgb(64, 204, 222)
	local root = b.bone("Root", Vector3.zero)
	root.Anchored = true
	local torso = b.bone("Torso", Vector3.new(0, 4.4, 0))
	local head = b.bone("Head", Vector3.new(0, 9.3, 0))
	b.joint("Waist", root, torso, Vector3.new(0, 4.4, 0))
	b.joint("Neck", torso, head, Vector3.new(0, 9.3, 0))
	for _, x in { -0.42, 0.42 } do
		b.piece(root, "Leg", "block", Vector3.new(0.55, 1.4, 0.55), at(x, 0.7, 0), rgb(40, 28, 52))
		b.piece(root, "Shoe", "ball", Vector3.new(0.65, 0.4, 1.0), at(x, 0.2, -0.15), rgb(28, 20, 36))
	end
	-- long coat, split at the front hem, yellow edges, standing collar to the top of the head
	b.piece(torso, "CoatLow", "block", Vector3.new(2.4, 4.4, 1.6), at(0, 3.6, 0), COAT)
	b.piece(torso, "CoatHigh", "block", Vector3.new(2.15, 4.2, 1.45), at(0, 7.5, 0), COAT)
	b.piece(torso, "Split", "wedge", Vector3.new(0.6, 2.0, 0.1), at(0, 2.35, -0.82, 0, 180, 0), rgb(44, 18, 58))
	b.piece(torso, "Hem", "block", Vector3.new(2.45, 0.24, 1.65), at(0, 1.42, 0), TRIM)
	b.piece(torso, "CollarRim", "block", Vector3.new(2.2, 0.26, 1.5), at(0, 9.62, 0), TRIM)
	b.piece(torso, "CollarDark", "block", Vector3.new(1.6, 0.12, 1.0), at(0, 9.7, 0), rgb(36, 16, 48))
	for _, s in { -1, 1 } do
		b.piece(torso, "FrontEdge", "block", Vector3.new(0.16, 8.0, 0.06), at(s * 0.32, 5.6, -0.82), TRIM)
		b.piece(torso, "SideEdge", "block", Vector3.new(0.06, 4.2, 0.16), at(s * 1.09, 7.5, -0.6), TRIM)
		for i = 0, 6 do -- gold clasps down the chest
			b.piece(torso, "Clasp", "block", Vector3.new(0.36, 0.16, 0.12), at(s * 0.62, 9.0 - i * 0.62, -0.78), CLASP, Enum.Material.Foil)
			b.piece(torso, "Stud", "ball", Vector3.new(0.18, 0.18, 0.1), at(s * 0.9, 9.0 - i * 0.62, -0.78), CLASP, Enum.Material.Foil)
		end
		for i = 0, 5 do -- grey bellows at the shoulders
			b.piece(torso, "Bellows", "cyl", Vector3.new(0.22, if i % 2 == 0 then 0.78 else 0.68, if i % 2 == 0 then 0.78 else 0.68),
				at(s * 1.32, 7.3 + i * 0.3, 0.1, 0, 0, 90), if i % 2 == 0 then GREY else rgb(120, 120, 132), Enum.Material.Metal)
		end
	end
	-- cyan dome and antenna above the collar
	b.piece(head, "Dome", "ball", Vector3.new(1.5, 1.0, 1.4), at(0, 9.95, 0), DOME)
	b.piece(head, "Antenna", "cyl", Vector3.new(1.3, 0.1, 0.1), at(0, 11.05, 0, 0, 0, 90), rgb(200, 210, 220), Enum.Material.Metal)
	b.piece(head, "AntennaTip", "ball", Vector3.new(0.24, 0.24, 0.24), at(0, 11.75, 0), DOME, Enum.Material.Neon)
	return root
end

local HEIGHT_UNITS = { Zeno = 9.9, FutureZeno = 9.9, GrandPriest = 10.4, Attendant = 11.9 }

-- feet: the spot between the feet (seated: the top of the seat), LookVector = the way the figure faces; height in
-- studs when standing. seated is supported for the Zenos (on their thrones).
function CastFigures.build(kind: string, feet: CFrame, height: number, seated: boolean?): Model
	local units = HEIGHT_UNITS[kind] or 10
	local u = height / units
	local isZeno = kind == "Zeno" or kind == "FutureZeno"
	local sit = seated == true and isZeno
	-- seated: drop the body so the hips (1.6 units up) rest just above the seat
	local b = newBuilder(kind, if sit then feet * CFrame.new(0, -1.3 * u, 0) else feet, u)
	local root
	if isZeno then
		root = zeno(b, sit)
	elseif kind == "GrandPriest" then
		root = grandPriest(b)
	else
		root = attendant(b)
	end
	outline(b.m)
	b.m.PrimaryPart = root
	b.m:SetAttribute("CastRig", kind)
	return b.m
end

-- ===== poses =====
local function joint(m: Model, name: string): Motor6D?
	local j = m:FindFirstChild(name, true)
	return if j and j:IsA("Motor6D") then j else nil
end
local function to(j: Motor6D?, rot: CFrame, t: number, fromRest: boolean?)
	if not j then return end
	local base = (if fromRest then j:GetAttribute("RestC0") else j:GetAttribute("BaseC0")) :: CFrame
	TweenService:Create(j, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { C0 = base * rot }):Play()
end
local function rest(m: Model, t: number)
	for _, d in m:GetDescendants() do
		if d:IsA("Motor6D") then
			TweenService:Create(d, TweenInfo.new(t, Enum.EasingStyle.Sine), { C0 = d:GetAttribute("RestC0") :: CFrame }):Play()
		end
	end
end

-- action: "Wave", "Clap", "Bow", "RaiseHands", "Look", "Rest"; returns immediately, the motion plays over ~1-3 s
function CastFigures.anim(m: Model, action: string)
	if not m:GetAttribute("CastRig") then return end
	local L, R = joint(m, "ShoulderL"), joint(m, "ShoulderR")
	task.spawn(function()
		if action == "Wave" then
			to(R, CFrame.Angles(0, 0, math.rad(150)), 0.35)
			to(joint(m, "Neck"), CFrame.Angles(0, 0, math.rad(-8)), 0.35)
			task.wait(0.35)
			for i = 1, 4 do
				to(R, CFrame.Angles(0, 0, math.rad(if i % 2 == 1 then 125 else 165)), 0.22)
				task.wait(0.22)
			end
			rest(m, 0.4)
		elseif action == "Clap" then
			for i = 1, 4 do
				to(L, CFrame.Angles(math.rad(75), 0, math.rad(if i % 2 == 1 then 28 else 8)), 0.16)
				to(R, CFrame.Angles(math.rad(75), 0, math.rad(if i % 2 == 1 then -28 else -8)), 0.16)
				task.wait(0.18)
			end
			rest(m, 0.4)
		elseif action == "Bow" then
			to(joint(m, "Waist"), CFrame.Angles(math.rad(-24), 0, 0), 0.5, true)
			to(joint(m, "Neck"), CFrame.Angles(math.rad(-10), 0, 0), 0.5, true)
			task.wait(1.2)
			rest(m, 0.5)
		elseif action == "Look" then
			-- idle: glance to one side and back
			local neck = joint(m, "Neck")
			to(neck, CFrame.Angles(math.rad(math.random(-6, 6)), math.rad(math.random(-28, 28)), 0), 0.6, true)
			task.wait(1.6 + math.random() * 1.2)
			to(neck, CFrame.identity, 0.6, true)
		elseif action == "RaiseHands" then
			to(L, CFrame.Angles(0, 0, math.rad(-155)), 0.5)
			to(R, CFrame.Angles(0, 0, math.rad(155)), 0.5)
			to(joint(m, "Neck"), CFrame.Angles(math.rad(10), 0, 0), 0.5)
		else
			rest(m, 0.4)
		end
	end)
end

return CastFigures
