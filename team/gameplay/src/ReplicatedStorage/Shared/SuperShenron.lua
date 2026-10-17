--!strict
-- ModuleScript: ReplicatedStorage.Shared.SuperShenron
-- Builds the colossal Super Shenron for the Tournament of Power ending (CutsceneDirector "npc_shenron" fallback when
-- ReplicatedStorage.CharacterModels has no npc_shenron). Original in-engine recreation from primitives, no imported
-- art: a golden serpent coiling out of the void, shingled scales, cream belly plates, red-orange back spines and
-- mane, clawed arms, two vast glowing wings (as in the Tournament of Power summon), and a head with open jaws,
-- fangs, branching horns, long whiskers and red eyes. A gold Highlight gives the whole dragon the show's radiant glow.
-- build(root, scale): root is the tail base, its -Z (LookVector) the way the dragon faces. At scale 1 the body rises
-- about 930 studs and the head is about 470 studs in front of the root. The model is anchored and non-colliding;
-- PrimaryPart = "Head" and attribute FocusOnHead = true tell cutscene cameras to aim at the head. Eye parts are
-- named "Eye" (CutsceneDirector's reveal ignites them).
local SuperShenron = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local GOLD, GOLD_DARK, GOLD_LIGHT = rgb(236, 182, 46), rgb(190, 126, 26), rgb(255, 216, 100)
local BELLY, SPINE, SPINE_TIP = rgb(250, 232, 170), rgb(206, 58, 34), rgb(255, 130, 50)
local MANE, MANE_LIGHT, HORN = rgb(214, 76, 38), rgb(255, 150, 66), rgb(244, 222, 164)
local TOOTH, EYE, MOUTH, NOSTRIL = rgb(252, 250, 240), rgb(255, 26, 26), rgb(120, 24, 26), rgb(70, 34, 12)

-- spine control points in root space (studs at scale 1, -Z = forward): tail low at the back, two big coils, then
-- the neck arcs forward and down so the head hangs over whatever is in front of the root
local CONTROL = {
	Vector3.new(240, -40, 160), Vector3.new(310, 110, -10), Vector3.new(140, 250, -150), Vector3.new(-190, 360, -90),
	Vector3.new(-310, 500, 90), Vector3.new(-140, 650, 210), Vector3.new(150, 760, 140), Vector3.new(260, 860, -40),
	Vector3.new(150, 930, -230), Vector3.new(40, 910, -370), Vector3.new(0, 850, -470),
}

local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- body radius along the spine (0 = tail tip, 1 = neck end), as a fraction of the thickest point
local function girth(t: number): number
	if t < 0.4 then return 0.14 + 0.86 * math.sin(t / 0.4 * math.pi / 2) end
	return 1 - (t - 0.4) / 0.6 * 0.18
end

function SuperShenron.build(root: CFrame, scale: number?): Model
	local s = scale or 1
	local m = Instance.new("Model")
	m.Name = "Story_SuperShenron"
	local count = 0
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, mat: Enum.Material?, cls: string?): BasePart
		local p = Instance.new((cls or "Part") :: any) :: BasePart
		if shape and p:IsA("Part") then p.Shape = shape end
		p.Name = name
		p.Size = Vector3.new(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05))
		p.CFrame = cf
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		count += 1
		if count % 250 == 0 then task.wait() end
		return p
	end
	local function wedge(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
		return part(name, size, cf, color, nil, mat, "WedgePart")
	end
	-- cylinder from a to b (Roblox cylinders run along X)
	local function rod(name: string, a: Vector3, b: Vector3, d: number, color: Color3, mat: Enum.Material?): BasePart
		local len = (b - a).Magnitude
		return part(name, Vector3.new(len + d * 0.2, d, d), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), color,
			Enum.PartType.Cylinder, mat)
	end
	local function ball(name: string, at: Vector3, d: number, color: Color3, mat: Enum.Material?): BasePart
		return part(name, Vector3.one * d, CFrame.new(at), color, Enum.PartType.Ball, mat)
	end
	-- a part whose thick end sits at `from` and thin end points along `dir` (WedgePart thick side is +Z)
	local function spike(name: string, from: Vector3, dir: Vector3, len: number, w: number, h: number, up: Vector3, color: Color3): BasePart
		local d = dir.Unit
		local u = up - d * d:Dot(up)
		if u.Magnitude < 1e-3 then u = Vector3.yAxis end
		return wedge(name, Vector3.new(w, h, len), CFrame.lookAt(from + d * len / 2, from + d * len, u.Unit), color)
	end

	-- a flat triangle a-b-c from two wedges (wing membranes)
	local function tri(name: string, a: Vector3, b: Vector3, c: Vector3, color: Color3, mat: Enum.Material, transp: number)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		if ac:Cross(ab).Magnitude < 1e-3 then return end
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local thick = 1.2 * s
		local w1 = wedge(name, Vector3.new(thick, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), color, mat)
		local w2 = wedge(name, Vector3.new(thick, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color, mat)
		w1.Transparency, w2.Transparency = transp, transp
	end

	-- 1) spine: dense Catmull-Rom samples, re-spaced evenly by arc length
	local pts: { Vector3 } = {}
	for i, c in CONTROL do pts[i] = root:PointToWorldSpace(c * s) end
	local dense: { Vector3 } = {}
	for i = 1, #pts - 1 do
		local p0, p1, p2, p3 = pts[math.max(i - 1, 1)], pts[i], pts[i + 1], pts[math.min(i + 2, #pts)]
		for k = 0, 39 do table.insert(dense, catmull(p0, p1, p2, p3, k / 40)) end
	end
	table.insert(dense, pts[#pts])
	local cum = { 0 }
	for i = 2, #dense do cum[i] = cum[i - 1] + (dense[i] - dense[i - 1]).Magnitude end
	local total = cum[#cum]
	local N = 170
	local P: { Vector3 } = {}
	local j = 1
	for i = 0, N do
		local want = total * i / N
		while j < #dense - 1 and cum[j + 1] < want do j += 1 end
		local span = math.max(cum[j + 1] - cum[j], 1e-6)
		P[i + 1] = dense[j]:Lerp(dense[j + 1], math.clamp((want - cum[j]) / span, 0, 1))
	end
	local R0 = 52 * s
	local step = total / N

	-- 2) frames: T along the body (toward the head), U = back (dorsal, kept near world up), S = side
	local T: { Vector3 }, U: { Vector3 }, S: { Vector3 }, rad: { number } = {}, {}, {}, {}
	local prevU = Vector3.yAxis
	for i = 1, #P do
		local t = (P[math.min(i + 1, #P)] - P[math.max(i - 1, 1)]).Unit
		local want = Vector3.yAxis - t * t:Dot(Vector3.yAxis)
		local keep = prevU - t * t:Dot(prevU)
		local u = if want.Magnitude > 0.35 then (want.Unit * 0.35 + keep.Unit * 0.65) else keep
		u = (u - t * t:Dot(u)).Unit
		T[i], U[i], S[i] = t, u, t:Cross(u).Unit
		rad[i] = R0 * girth((i - 1) / N)
		prevU = u
	end

	-- 3) body: core tube, shingle scales on the back and flanks, belly plates, back spines, neck mane
	for i = 1, #P - 1 do
		local a, b, r = P[i], P[i + 1], rad[i]
		local tt = (i - 1) / N
		rod("Body", a, b, r * 2, GOLD, Enum.Material.Foil)
		ball("Joint", a, r * 2, GOLD, Enum.Material.Foil)
		local mid, t, u, sd = (a + b) / 2, T[i], U[i], S[i]
		for k, ang in { -95, -35, 35, 95 } do
			local dir = (u * math.cos(math.rad(ang)) + sd * math.sin(math.rad(ang))).Unit
			local col = if (i + k) % 2 == 0 then GOLD_DARK else GOLD
			wedge("Scale", Vector3.new(r * 0.62, r * 0.2, step * 1.35), CFrame.fromMatrix(mid + dir * r * 0.9, dir:Cross(-t), dir, -t), col,
				Enum.Material.Metal)
		end
		local down = -u
		part("Belly", Vector3.new(step * 0.86, r * 0.32, r * 1.3), CFrame.fromMatrix(mid + down * r * 0.8, t, down), BELLY)
		if i % 2 == 0 and tt > 0.04 and tt < 0.9 then
			local h = r * (0.75 + 0.35 * math.sin(i * 1.7))
			local base = mid + u * r * 0.85
			wedge("Spine", Vector3.new(r * 0.16, h, step * 2), CFrame.fromMatrix(base + u * h / 2, u:Cross(-t), u, -t), SPINE)
			wedge("SpineTip", Vector3.new(r * 0.1, h * 0.45, step * 1.1), CFrame.fromMatrix(base + u * (h + h * 0.2), u:Cross(-t), u, -t), SPINE_TIP,
				Enum.Material.Neon)
		end
		if tt > 0.84 then
			for k = -2, 2 do
				local dir = (u * 0.9 + sd * k * 0.35 - t * 0.9).Unit
				spike("Mane", mid + (u + sd * k * 0.4).Unit * r * 0.8, dir, r * (1.9 + 0.3 * ((i + k) % 3)), r * 0.22, r * 0.3, u,
					if (i + k) % 2 == 0 then MANE else MANE_LIGHT)
			end
		end
	end
	-- tail tuft
	local tip, tipT, tipU = P[1], T[1], U[1]
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		local dir = (-tipT * 1.4 + (tipU * math.cos(a) + S[1] * math.sin(a)) * 0.6).Unit
		spike("TailTuft", tip, dir, R0 * 1.4, R0 * 0.2, R0 * 0.3, tipU, if k % 2 == 0 then MANE else MANE_LIGHT)
	end

	-- 4) limbs: shoulder -> elbow -> wrist -> clawed hand; `reach` is where the hand points
	local forward = root.LookVector
	local function limb(name: string, at: number, side: number, elbowOff: Vector3, wristOff: Vector3, reach: Vector3, size: number)
		local i = math.floor(at * N) + 1
		local r = rad[i] * size
		local sh = P[i] + S[i] * side * rad[i] * 0.8 - U[i] * rad[i] * 0.2
		local el = sh + elbowOff * r
		local wr = el + wristOff * r
		ball(name .. "Shoulder", sh, r * 1.3, GOLD, Enum.Material.Foil)
		rod(name .. "Upper", sh, el, r * 1.05, GOLD, Enum.Material.Foil)
		ball(name .. "Elbow", el, r * 1.0, GOLD_DARK, Enum.Material.Foil)
		rod(name .. "Fore", el, wr, r * 0.85, GOLD, Enum.Material.Foil)
		for k = 0, 3 do -- elbow tuft
			local dir = ((el - sh).Unit * 0.4 - (wr - el).Unit * 0.8 + Vector3.yAxis * (k - 1.5) * 0.25).Unit
			spike(name .. "Tuft", el, dir, r * 1.3, r * 0.2, r * 0.3, Vector3.yAxis, if k % 2 == 0 then MANE else MANE_LIGHT)
		end
		local f = reach.Unit
		local up = (Vector3.yAxis - f * f:Dot(Vector3.yAxis))
		up = if up.Magnitude > 0.1 then up.Unit else S[i]
		local side3 = f:Cross(up).Unit
		ball(name .. "Wrist", wr, r * 0.8, GOLD, Enum.Material.Foil)
		local palm = wr + f * r * 0.55
		part(name .. "Palm", Vector3.new(r * 1.1, r * 0.45, r * 1.0), CFrame.fromMatrix(palm, side3, up), GOLD_LIGHT)
		for k = 1, 4 do -- splayed fingers, each bent once, ivory claw at the tip
			local spread = (k - 2.5) * 0.42
			local d1 = (f + side3 * spread + up * 0.15).Unit
			local k1 = palm + f * r * 0.4 + side3 * spread * r * 0.45
			local k2 = k1 + d1 * r * 0.75
			local d2 = (d1 - up * 0.7).Unit
			local k3 = k2 + d2 * r * 0.6
			rod(name .. "Finger", k1, k2, r * 0.3, GOLD, Enum.Material.Foil)
			ball(name .. "Knuckle", k2, r * 0.3, GOLD_DARK)
			rod(name .. "Finger", k2, k3, r * 0.26, GOLD, Enum.Material.Foil)
			spike(name .. "Claw", k3, (d2 - up * 0.6).Unit, r * 0.55, r * 0.16, r * 0.24, up, TOOTH)
		end
		local thumbBase = palm - f * r * 0.1 + side3 * -1.0 * r * 0.55
		rod(name .. "Thumb", thumbBase, thumbBase + (f - side3 * 0.6).Unit * r * 0.7, r * 0.28, GOLD, Enum.Material.Foil)
	end
	local Y = Vector3.yAxis
	limb("ArmR", 0.8, 1, (Y * -0.6 + forward * 0.9 + root.RightVector * 0.8), (forward * 1.6 + Y * -0.7), forward - Y * 0.45, 0.62)
	limb("ArmL", 0.8, -1, (Y * 0.5 + forward * 0.5 - root.RightVector * 0.9), (Y * 1.5 + forward * 0.6), (Y * 0.6 + forward).Unit, 0.62)
	limb("LegR", 0.43, 1, (Y * -0.9 + root.RightVector * 0.6), (Y * -1.2 + forward * 0.5), forward - Y * 0.8, 0.5)
	limb("LegL", 0.43, -1, (Y * -0.9 - root.RightVector * 0.6), (Y * -1.2 + forward * 0.5), forward - Y * 0.8, 0.5)

	-- 4b) wings: from the upper back, an arm bone sweeps out and up, five finger bones fan from the wrist, and glowing
	-- membranes stretch between them; spread wide and canted toward the viewers like the anime summon
	do
		local wi = math.floor(0.74 * N) + 1
		local wr = rad[wi]
		local span = 980 * s -- wider than the coiled body, like the anime summon
		for _, side in { -1, 1 } do
			local out = (root.RightVector * side + Y * 0.22 + forward * 0.2).Unit
			local upw = (Y - out * out:Dot(Y)).Unit
			local base = P[wi] + U[wi] * wr * 0.7 + S[wi] * side * wr * 0.35
			local elbow = base + (out * 0.75 + upw * 0.65).Unit * span * 0.32
			local wrist = elbow + (out * 0.95 + upw * 0.3).Unit * span * 0.3
			rod("WingArm", base, elbow, wr * 0.42, GOLD, Enum.Material.Foil)
			ball("WingJoint", elbow, wr * 0.48, GOLD_DARK, Enum.Material.Foil)
			rod("WingArm", elbow, wrist, wr * 0.32, GOLD, Enum.Material.Foil)
			ball("WingJoint", wrist, wr * 0.38, GOLD_DARK, Enum.Material.Foil)
			spike("WingClaw", wrist, (upw * 0.8 + out * 0.4).Unit, wr * 0.9, wr * 0.18, wr * 0.26, out, TOOTH)
			local tips: { Vector3 } = {}
			for k, deg in { 55, 22, -10, -42, -72 } do
				local d = (out * math.cos(math.rad(deg)) + upw * math.sin(math.rad(deg))).Unit
				local ftip = wrist + d * span * (0.62 - k * 0.045)
				-- each finger bends slightly back toward the body at the tip
				local mid = wrist + d * span * (0.33 - k * 0.02) + forward * span * 0.03
				rod("WingFinger", wrist, mid, wr * 0.2, GOLD, Enum.Material.Foil)
				rod("WingFinger", mid, ftip, wr * 0.13, GOLD_LIGHT, Enum.Material.Foil)
				tips[k] = ftip
			end
			local MEM = rgb(255, 214, 110)
			-- membrane: wrist fans between fingers, plus the inner panel back to the body
			for k = 1, #tips - 1 do
				local a, b = tips[k], tips[k + 1]
				local dip = wrist + ((a + b) / 2 - wrist) * 0.86 -- scalloped trailing edge
				tri("WingMembrane", wrist, a, dip, MEM, Enum.Material.Neon, 0.35)
				tri("WingMembrane", wrist, dip, b, MEM, Enum.Material.Neon, 0.35)
			end
			tri("WingMembrane", base, elbow, wrist, MEM, Enum.Material.Neon, 0.35)
			tri("WingMembrane", base, wrist, tips[#tips], MEM, Enum.Material.Neon, 0.35)
			tri("WingMembrane", base, tips[#tips], P[math.floor(0.62 * N) + 1] + U[wi] * wr * 0.6, MEM, Enum.Material.Neon, 0.35)
		end
	end

	-- 5) head, in head units (hu); its frame looks along the neck's end, tilted down toward the arena
	local nI = #P
	local hu = rad[nI] / 5.6
	-- face the way the neck travels, pitched about 25 degrees down so viewers below see the face, not the crown
	local flatT = Vector3.new(T[nI].X, 0, T[nI].Z)
	local hf = ((if flatT.Magnitude > 0.1 then flatT.Unit else forward) - Y * 0.47).Unit
	local hup = (U[nI] - hf * hf:Dot(U[nI])).Unit
	local H = CFrame.lookAt(P[nI] + hf * 10 * hu, P[nI] + hf * 11 * hu, hup)
	local function at(x: number, y: number, z: number): CFrame
		return H * CFrame.new(x * hu, y * hu, z * hu)
	end
	local function hv(x: number, y: number, z: number): Vector3
		return H:VectorToWorldSpace(Vector3.new(x, y, z)).Unit
	end
	local head = part("Head", Vector3.one * 22 * hu, at(0, 0, 0), GOLD, Enum.PartType.Ball, Enum.Material.Foil)
	part("Cranium", Vector3.new(20, 13, 22) * hu, at(0, 3, 1), GOLD, nil, Enum.Material.Foil)
	part("Snout", Vector3.new(14, 8, 30) * hu, at(0, 0.5, -20), GOLD, nil, Enum.Material.Foil)
	part("NoseBridge", Vector3.new(8, 3, 26) * hu, at(0, 5, -19) * CFrame.Angles(0.06, 0, 0), GOLD_LIGHT, nil, Enum.Material.Foil)
	part("ForeheadPlate", Vector3.new(7, 1.6, 9) * hu, at(0, 9.6, -2) * CFrame.Angles(0, math.rad(45), 0), GOLD_LIGHT, nil, Enum.Material.Foil)
	for _, x in { -1, 1 } do
		wedge("SnoutSide", Vector3.new(4, 6, 30) * hu, at(x * 8.4, 1.5, -20) * CFrame.Angles(0, 0, -x * 0.35), GOLD_DARK, Enum.Material.Metal)
		ball("Cheek", (at(x * 7.5, -1, -4)).Position, 14 * hu, GOLD, Enum.Material.Foil)
		-- heavy brow ridge overhanging an angry slanted eye
		wedge("Brow", Vector3.new(7, 5, 15) * hu, at(x * 7.4, 8.4, -9) * CFrame.Angles(0.15, x * 0.2, -x * 0.3), GOLD_DARK, Enum.Material.Metal)
		part("EyeSocket", Vector3.new(7.6, 4.4, 10) * hu, at(x * 7.6, 5, -10.5) * CFrame.Angles(0, x * 0.4, -x * 0.3), rgb(60, 18, 10))
		local eye = part("Eye", Vector3.new(6.6, 3, 9) * hu, at(x * 8, 5, -11) * CFrame.Angles(0, x * 0.4, -x * 0.3), EYE, nil,
			Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Color = EYE
		l.Range = 18 * hu
		l.Brightness = 4
		l.Parent = eye
		ball("Nostril", (at(x * 3.6, 4.3, -34)).Position, 2.6 * hu, NOSTRIL)
		part("NoseRidge", Vector3.new(3, 2.5, 8) * hu, at(x * 3.6, 4.6, -30), GOLD_DARK, nil, Enum.Material.Metal)
		-- upper teeth and fangs
		for k = 0, 5 do
			local z = -33 + k * 4.2
			local big = k == 0
			spike("Tooth", (at(x * 6.2, -3.4, z)).Position, hv(0, -1, 0), (if big then 7 else 3.4) * hu, (if big then 2.4 else 1.5) * hu,
				(if big then 2.6 else 1.6) * hu, hv(0, 0, -1), TOOTH)
		end
		-- cheek frills and side mane
		for k = 0, 2 do
			spike("CheekFrill", (at(x * 10, -2 + k * 3, 4 + k * 2)).Position, hv(x * 0.8, -0.2 + k * 0.25, 1), (12 - k * 2) * hu, 2 * hu,
				3 * hu, hv(0, 1, 0), if k % 2 == 0 then MANE else MANE_LIGHT)
		end
		-- main horns: branching, sweeping back and up
		local hp = (at(x * 6, 9, 5)).Position
		local dirs = { hv(x * 0.35, 0.85, 0.45), hv(x * 0.3, 0.55, 1), hv(x * 0.25, 0.25, 1), hv(x * 0.2, 0.05, 1), hv(x * 0.15, 0.1, 1) }
		local hr = 3 * hu
		for k, d in dirs do
			local nxt = hp + d * 8 * hu
			rod("Horn", hp, nxt, hr, HORN)
			ball("HornJoint", nxt, hr, HORN)
			if k == 2 then
				local bp = nxt
				for q, bd in { hv(x * 0.1, 1, 0.2), hv(x * 0.05, 1, 0.5), hv(0, 0.7, 1) } do
					local bn = bp + bd * 5.5 * hu
					rod("HornBranch", bp, bn, hr * (0.75 - q * 0.15), HORN)
					bp = bn
				end
			end
			hp = nxt
			hr *= 0.8
		end
		-- smaller back horns
		local sp = (at(x * 9, 5, 8)).Position
		rod("HornSmall", sp, sp + hv(x * 0.7, 0.3, 1) * 9 * hu, 2 * hu, HORN)
		-- long whiskers flowing back from the snout
		local wp = (at(x * 7, -0.5, -31)).Position
		local wd = 1.1 * hu
		for k = 1, 18 do
			local d = hv(x * (1 - k * 0.04), 0.25 * math.sin(k * 0.6) - 0.05, -0.6 + k * 0.14)
			local nxt = wp + d * 7 * hu
			rod("Whisker", wp, nxt, wd, GOLD_LIGHT)
			wp = nxt
			wd = math.max(wd * 0.94, 0.35 * hu)
		end
	end
	-- jaw: hinged open, tongue, lower fangs, chin beard
	local jaw = at(0, -4.2, 0) * CFrame.Angles(math.rad(-24), 0, 0)
	part("Jaw", Vector3.new(12, 4.5, 28) * hu, jaw * CFrame.new(0, -2.2 * hu, -14 * hu), GOLD, nil, Enum.Material.Foil)
	part("JawPlate", Vector3.new(9, 1.2, 24) * hu, jaw * CFrame.new(0, -4.6 * hu, -12 * hu), BELLY)
	part("Mouth", Vector3.new(10, 3, 27) * hu, at(0, -4.4, -15), MOUTH)
	part("Tongue", Vector3.new(6, 1.4, 22) * hu, jaw * CFrame.new(0, 0.2 * hu, -12 * hu), rgb(200, 60, 70))
	for _, x in { -1, 1 } do
		for k = 0, 4 do
			local p = (jaw * CFrame.new(x * 5.2 * hu, 0.4 * hu, (-26 + k * 4.5) * hu)).Position
			spike("LowerTooth", p, jaw.UpVector, (if k == 0 then 5.5 else 3) * hu, 1.4 * hu, 1.6 * hu, -jaw.LookVector, TOOTH)
		end
	end
	for k = -2, 2 do
		local p = (jaw * CFrame.new(k * 2 * hu, -4.5 * hu, -22 * hu)).Position
		spike("Beard", p, (-jaw.UpVector * 1 + jaw.LookVector * -0.4 + jaw.RightVector * k * 0.15).Unit, (8 - math.abs(k)) * hu, 2 * hu, 2.4 * hu,
			jaw.LookVector, if k % 2 == 0 then MANE else MANE_LIGHT)
	end
	-- crown mane fanning back from the skull
	for k = -4, 4 do
		local p = (at(k * 2, 9, 6)).Position
		spike("CrownMane", p, hv(k * 0.18, 0.55, 1), (20 - math.abs(k) * 1.5) * hu, 3 * hu, 4 * hu, hv(0, 1, 0), if k % 2 == 0 then MANE else MANE_LIGHT)
	end

	-- 6) glow: the dragon lights the void gold
	local aura = Instance.new("PointLight")
	aura.Color = GOLD_LIGHT
	aura.Range = 60
	aura.Brightness = 2
	aura.Parent = head
	for _, t in { 0.25, 0.5, 0.75 } do
		local seg = m:FindFirstChild("Body")
		local i = math.floor(t * N) + 1
		if seg then
			local glow = Instance.new("Attachment")
			glow.Parent = seg
			glow.WorldPosition = P[i]
			local l = Instance.new("PointLight")
			l.Color = GOLD_LIGHT
			l.Range = 60
			l.Brightness = 1.5
			l.Parent = glow
		end
	end
	local glow = Instance.new("Highlight")
	glow.Name = "DivineGlow"
	glow.FillColor = rgb(255, 210, 90)
	glow.FillTransparency = 0.72
	glow.OutlineColor = rgb(255, 244, 196)
	glow.OutlineTransparency = 0.15
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = m
	m.PrimaryPart = head
	m:SetAttribute("FocusOnHead", true)
	m.Parent = workspace
	return m
end

return SuperShenron
