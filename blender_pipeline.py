# Runs on the PC. Drives Blender through the Blender MCP addon socket (localhost:9876):
# import glb -> join -> decimate (chars <20k tris, props/env <10k) -> apply transforms -> scale -> export FBX + preview PNG.
import json, os, socket, sys, time
ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "sketchfab", "models")
OUT = os.path.join(ROOT, "sketchfab_out")
os.makedirs(OUT, exist_ok=True)

PRIORITY = ["goku_from_dragon_ball_textured_and_rigge_43d397", "vegeta_from_dragon_ball_textured_and_rig_41a0b4",
    "dragon_ball_z_frieza_a335b7", "frieza_emperor_of_the_universe_84fa59", "zeno_sama_omni_king_60ff10",
    "shenron_dragon_ball_96e8ad", "the_dragon_balls_77baeb", "potara_earrings_dragon_ball_63cc2a",
    "free_pack_rocks_stylized_7c60b4", "low_poly_rocks_9823ec", "rocks_set2_62ab17", "altar_ruins_189d92",
    "ancient_ruins_105c85", "free_skybox_space_nebula_fa5c19", "throne_bfc6d2", "dragon_ball_z_vegeta_1c2513",
    "goku_rigged_animated_3ed060", "golden_frieza_315f9a"]
PROP_KW = ["radar", "scouter", "potara_earrings", "dragon_balls", "staff", "pot", "dummy", "capsule", "throne", "spaceship"]
ENV_KW = ["rock", "ruin", "altar", "house", "chamber", "skybox", "hdri", "corp", "explosion", "shockwave", "sparks", "panorama"]
def category(slug):
    if any(k in slug for k in ENV_KW): return "Environment"
    if any(k in slug for k in PROP_KW): return "Props"
    if "shenron" in slug: return "Creature"
    return "Character"

def send(code, timeout=600):
    s = socket.create_connection(("127.0.0.1", 9876), timeout=timeout)
    s.sendall(json.dumps({"type": "execute_code", "params": {"code": code}}).encode())
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
        try:
            res = json.loads(buf.decode()); break
        except Exception: continue
    s.close()
    return res

BODY = r'''
import bpy, bmesh, json, math, os, mathutils
slug, src, out, cat = %r, %r, %r, %r
NOBAKE = ['frieza_emperor_of_the_universe_84fa59', 'goku_1b2295']
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.armatures, bpy.data.cameras, bpy.data.actions):
    for b in list(coll):
        if b.users == 0: coll.remove(b)
bpy.ops.import_scene.gltf(filepath=src)
for o in list(bpy.context.scene.objects):
    if o.type == "MESH" and ("mmd_tools_rigid" in o.name or o.name.startswith("Icosphere")):
        bpy.data.objects.remove(o, do_unlink=True)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
arm = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
def tris(objs):
    n = 0
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        m = o.evaluated_get(dg).to_mesh(); m.calc_loop_triangles(); n += len(m.loop_triangles); o.evaluated_get(dg).to_mesh_clear()
    return n
before = tris(meshes)
# clear parenting/armature so the result is a clean static mesh (rigid fallback; rigging happens in Studio)
# v3: bake the skinned rest pose (apply the armature modifier) so the bind/armature transform is kept
for a in arm:
    a.data.pose_position = "REST"
bpy.context.view_layer.update()
for o in meshes:
    if o.data.users > 1: o.data = o.data.copy()
    if o.data.shape_keys: o.shape_key_clear()
    bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
    for md in list(o.modifiers):
        if md.type == "ARMATURE":
            # only bake if the evaluated (deformed) mesh is sane; otherwise drop the modifier and keep the bind mesh
            dg = bpy.context.evaluated_depsgraph_get(); em = o.evaluated_get(dg).to_mesh()
            import numpy as _np
            ev = _np.array([v.co[:] for v in em.vertices]) if len(em.vertices) else _np.zeros((1, 3)); o.evaluated_get(dg).to_mesh_clear()
            bv = _np.array([v.co[:] for v in o.data.vertices]) if len(o.data.vertices) else _np.zeros((1, 3))
            ee = float((ev.max(0) - ev.min(0)).max()); be = float((bv.max(0) - bv.min(0)).max())
            if slug in NOBAKE or not _np.isfinite(ee) or ee < be / 8 or ee > be * 8:
                o.modifiers.remove(md); continue
            try: bpy.ops.object.modifier_apply(modifier=md.name)
            except Exception: o.modifiers.remove(md)
    pass
    mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
bpy.context.view_layer.update()
DBG = []
for o in meshes:
    if o.name not in bpy.data.objects: continue
    vv = [o.matrix_world @ v.co for v in o.data.vertices]
    if not vv: continue
    mn = [min(v[i] for v in vv) for i in range(3)]; mx = [max(v[i] for v in vv) for i in range(3)]
    DBG.append((o.name, len(vv), [round(mx[i] - mn[i], 3) for i in range(3)], [round((mx[i] + mn[i]) / 2, 2) for i in range(3)]))
print("DBG:" + json.dumps(DBG))
if cat == "Character" and len(DBG) > 1:
    ref = max(DBG, key=lambda d: d[1]); rext = max(ref[2]) or 1
    for nm, n, ex, ce in DBG:
        if max(ex) < rext / 12 or max(ex) > rext * 1.6:
            bpy.data.objects.remove(bpy.data.objects[nm], do_unlink=True)
for a in arm: bpy.data.objects.remove(a, do_unlink=True)
for o in list(bpy.context.scene.objects):
    if o.type not in ("MESH",): bpy.data.objects.remove(o, do_unlink=True)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1: bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
ob.name = slug
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
target = 20000 if cat in ("Character", "Creature") else 10000
cur = tris([ob])
if cur > target:
    d = ob.modifiers.new("Decimate", "DECIMATE"); d.ratio = max(0.02, target / cur * 0.97)
    bpy.ops.object.modifier_apply(modifier=d.name)
after = tris([ob])
# --- v2 fix: robust bounds, outlier cull, up-axis detection for humanoids ---
import numpy as np
def verts():
    me = ob.data; a = np.empty(len(me.vertices)*3, dtype=np.float64); me.vertices.foreach_get("co", a); return a.reshape(-1, 3)
fixinfo = {}
ROTATE = False
if cat in ("Character", "Creature") and len(ob.data.vertices) > 8:
    V = verts(); lo = np.percentile(V, 0.5, axis=0); hi = np.percentile(V, 99.5, axis=0); ext = hi - lo
    lo2 = lo - ext * 0.15; hi2 = hi + ext * 0.15
    bad = np.any((V < lo2) | (V > hi2), axis=1)
    if bad.sum() > 0:
        bm = bmesh.new(); bm.from_mesh(ob.data); bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[bm.verts[i] for i in np.nonzero(bad)[0]], context="VERTS"); bm.to_mesh(ob.data); bm.free()
    fixinfo["culled"] = int(bad.sum())
if cat == "Character" and len(ob.data.vertices) > 8 and ROTATE:
    V = verts(); lo = np.percentile(V, 1, axis=0); hi = np.percentile(V, 99, axis=0); ext = hi - lo
    thin = int(np.argmin(ext)); others = [i for i in range(3) if i != thin]
    a, b = others
    if ext[a] > ext[b] * 1.2: up = a
    elif ext[b] > ext[a] * 1.2: up = b
    else:
        # T-pose: arm span ~ height. widest horizontal slice sits at shoulders (upper body); pick axis whose width profile peaks off-centre
        def peak(ax, other):
            t = (V[:, ax] - lo[ax]) / max(ext[ax], 1e-9); bins = np.clip((t*20).astype(int), 0, 19); w = np.zeros(20)
            for k in range(20):
                sel = V[bins == k, other]
                if len(sel) > 3: w[k] = np.percentile(sel, 98) - np.percentile(sel, 2)
            return abs(np.argmax(w) - 9.5)
        up = a if peak(a, b) > peak(b, a) else b
    # sign: shoulders (widest slice) should be in upper half
    side = [i for i in others if i != up][0]
    t = (V[:, up] - lo[up]) / max(ext[up], 1e-9); bins = np.clip((t*20).astype(int), 0, 19); w = np.zeros(20)
    for k in range(20):
        sel = V[bins == k, side]
        if len(sel) > 3: w[k] = np.percentile(sel, 98) - np.percentile(sel, 2)
    sign = 1 if np.argmax(w) >= 10 else -1
    if up == 2 and ext[2] < max(ext) * 0.5: pass
    fixinfo.update({"up": "xyz"[up], "sign": sign, "thin": "xyz"[thin]})
    tgt = mathutils.Vector((0, 0, 1)); src_v = mathutils.Vector([0, 0, 0]); src_v[up] = sign
    q = src_v.rotation_difference(tgt)
    ob.data.transform(q.to_matrix().to_4x4()); ob.data.update()
    # face -Y (front) : put thin axis on Y
    V = verts(); e2 = np.percentile(V, 99, axis=0) - np.percentile(V, 1, axis=0)
    if e2[0] < e2[1] * 0.8:
        ob.data.transform(mathutils.Matrix.Rotation(math.pi/2, 4, "Z")); ob.data.update()
    V = verts()
    h_true = float(np.percentile(V[:, 2], 99.5) - np.percentile(V[:, 2], 0.5))
    fixinfo["h_src"] = round(h_true, 3)
# v3: rigged sources that come in lying down (Y-up bind) -> rotate +90 about X so +Y becomes +Z
if cat == "Character" and len(arm) > 0:
    V = verts(); e = np.percentile(V, 95, axis=0) - np.percentile(V, 5, axis=0)
    if e[2] < e[1] * 0.6:
        ob.data.transform(mathutils.Matrix.Rotation(math.pi / 2, 4, "X")); ob.data.update(); fixinfo["rot"] = "x+90"
# v3: drop stray islands far from the main body
if cat == "Character":
    bm = bmesh.new(); bm.from_mesh(ob.data); bm.verts.ensure_lookup_table()
    P = np.array([v.co[:] for v in bm.verts]); lo = np.percentile(P, 3, axis=0); hi = np.percentile(P, 97, axis=0); ext = hi - lo
    lo2 = lo - ext * 0.35; hi2 = hi + ext * 0.35
    seen = set(); kill = []
    for v in bm.verts:
        if v.index in seen: continue
        stack = [v]; isl = []; seen.add(v.index)
        while stack:
            x = stack.pop(); isl.append(x)
            for ed in x.link_edges:
                y = ed.other_vert(x)
                if y.index not in seen: seen.add(y.index); stack.append(y)
        c = np.array([q.co[:] for q in isl]).mean(0)
        if np.any(c < lo2) or np.any(c > hi2): kill += isl
    if kill: bmesh.ops.delete(bm, geom=kill, context="VERTS")
    bm.to_mesh(ob.data); bm.free(); ob.data.update(); fixinfo["island_cull_verts"] = len(kill)
# scale: humanoids 5.5 studs tall; props ~2 studs; creature 40; env keep proportions, ~20 studs max dim
ob.data.update(); bpy.context.view_layer.update()
_V = verts(); dims = mathutils.Vector((_V.max(0) - _V.min(0)).tolist())
h = float(np.percentile(_V[:, 2], 99.5) - np.percentile(_V[:, 2], 0.5)) if cat == "Character" else dims.z
if h <= 0: h = max(dims)
want = {"Character": 5.5, "Creature": 40.0, "Props": 2.0}.get(cat)
s = (want / h) if want else (20.0 / max(max(dims), 1e-6))
ob.scale = (s, s, s)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
# origin at feet centre, at world origin
bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
ob.location = (0, 0, ob.dimensions.z / 2)
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
fbx = os.path.join(out, slug + ".fbx")
bpy.ops.export_scene.fbx(filepath=fbx, use_selection=False, apply_scale_options="FBX_SCALE_UNITS", path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y")
# preview render (workbench, textured)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.light = "STUDIO"
sc.render.resolution_x = 512; sc.render.resolution_y = 512
cam_d = bpy.data.cameras.new("cam"); cam = bpy.data.objects.new("cam", cam_d); sc.collection.objects.link(cam); sc.camera = cam
size = max(ob.dimensions)
cam.location = (size * 1.1, -size * 1.6, ob.dimensions.z * 0.6 + size * 0.2)
cam.location = (0, -size * 2.0, ob.dimensions.z * 0.55)
c = mathutils.Vector((0, 0, ob.dimensions.z / 2))
cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = os.path.join(out, slug + "_preview.png")
bpy.ops.render.render(write_still=True)
dims = ob.dimensions
result = {"slug": slug, "cat": cat, "tris_before": before, "tris_after": after, "dims": [round(dims.x, 2), round(dims.y, 2), round(dims.z, 2)], "fbx": fbx, "rigged_src": len(arm) > 0, "fix": fixinfo}
print("RESULT:" + json.dumps(result))
'''

def run(slug):
    d = os.path.join(SRC, slug)
    glb = [f for f in os.listdir(d) if f.endswith(".glb")]
    if not glb: return {"slug": slug, "error": "no glb"}
    code = BODY % (slug, os.path.join(d, glb[0]), OUT, category(slug))
    t = time.time()
    try:
        r = send(code)
    except Exception as e:
        return {"slug": slug, "error": str(e)}
    r["secs"] = round(time.time() - t, 1)
    return r

if __name__ == "__main__":
    slugs = sys.argv[1:] or PRIORITY + sorted(x for x in os.listdir(SRC) if os.path.isdir(os.path.join(SRC, x)) and x not in PRIORITY)
    log = open(os.path.join(OUT, "pipeline_log.jsonl"), "a", encoding="utf-8")
    for s in slugs:
        if s.startswith("--"): continue
        if os.path.exists(os.path.join(OUT, s + ".fbx")) and "--force" not in sys.argv: continue
        r = run(s)
        print(json.dumps(r)[:600], flush=True)
        log.write(json.dumps(r) + "\n"); log.flush()
    print("PIPELINE DONE", flush=True)
