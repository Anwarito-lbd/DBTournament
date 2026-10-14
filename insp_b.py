import sys,json
sys.path.insert(0,r"C:\Users\issao\Documents\DBTournament")
from blender_pipeline import send, SRC
import os
for slug in sys.argv[1:]:
    d=os.path.join(SRC,slug); g=[f for f in os.listdir(d) if f.endswith(".glb")][0]
    code='''
import bpy
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=%r)
bpy.context.view_layer.update()
for o in bpy.context.scene.objects:
    if o.type in ("MESH","ARMATURE"):
        print("OBJ", o.type, o.name[:30], [round(x,3) for x in o.dimensions], len(o.data.vertices) if o.type=="MESH" else len(o.data.bones), o.parent.name[:20] if o.parent else None, [m.type for m in o.modifiers] if o.type=="MESH" else "")
''' % os.path.join(d,g)
    r=send(code); out=r.get("result",{}).get("result","")
    print(slug); print("\n".join(l for l in out.splitlines() if l.startswith("OBJ"))[:3000])
