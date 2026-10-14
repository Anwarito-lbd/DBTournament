import bpy, sys, math, os
from mathutils import Vector
cid = sys.argv[sys.argv.index('--')+1]
OUT = r"C:\Users\issao\Documents\DBTournament\models"
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
MATS = {}
def mat(name, rgb, emit=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1); b.inputs["Roughness"].default_value = 0.6
    if emit:
        b.inputs["Emission Color"].default_value = (*rgb, 1); b.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = (*rgb, 1); MATS[name] = m; return m
PARTS = []
def add(kind, loc, scl, m, grp, rot=(0,0,0), coll=None, **kw):
    if kind == 'cube': bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    elif kind == 'sph': bpy.ops.mesh.primitive_uv_sphere_add(segments=kw.get('seg',12), ring_count=kw.get('rings',8), radius=0.5, location=loc, rotation=rot)
    elif kind == 'cyl': bpy.ops.mesh.primitive_cylinder_add(vertices=kw.get('seg',10), radius=0.5, depth=1, location=loc, rotation=rot)
    elif kind == 'cone': bpy.ops.mesh.primitive_cone_add(vertices=kw.get('seg',6), radius1=0.5, radius2=kw.get('r2',0), depth=1, location=loc, rotation=rot)
    elif kind == 'torus': bpy.ops.mesh.primitive_torus_add(major_segments=24, minor_segments=6, major_radius=0.5, minor_radius=kw.get('minor',0.06), location=loc, rotation=rot)
    o = bpy.context.object; o.scale = scl
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(m)
    vg = o.vertex_groups.new(name=grp); vg.add(range(len(o.data.vertices)), 1.0, 'REPLACE')
    PARTS.append((o, coll or 'Body')); return o
def spike(base, tip, r, m, coll):
    base, tip = Vector(base), Vector(tip); d = tip - base
    o = add('cone', (base+tip)/2, (r*2, r*2, d.length), m, 'Head', coll=coll, seg=5)
    o.rotation_mode='QUATERNION'; o.rotation_quaternion = Vector((0,0,1)).rotation_difference(d.normalized())
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False); o.select_set(False)

# R15 joint layout, scaled by k (height ~5.5 at k=1)
def humanoid(k, C, head_scale=1.0, bulk=1.0):
    J = {}
    S = lambda *v: tuple(x*k for x in v)
    sk, gi, gi2, belt, arm, glove, boot, leg = C['skin'],C['torso'],C.get('torso2',C['torso']),C['belt'],C.get('arm',C['skin']),C['glove'],C['boot'],C['leg']
    add('cube', S(0,0,2.65), S(1.05*bulk,0.6*bulk,0.55), belt, 'LowerTorso')
    add('cube', S(0,0,3.45), S(1.35*bulk,0.75*bulk,1.15), gi, 'UpperTorso')
    if 'chest' in C: add('cube', S(0,-0.05,3.55), S(1.0*bulk,0.7*bulk,0.75), C['chest'], 'UpperTorso')
    hs = head_scale
    add('sph', S(0,0,4.5+0.1*(hs-1)), S(0.78*hs,0.78*hs,0.9*hs), sk, 'Head')
    for e in (-1,1):
        add('sph', S(0.17*e,-0.36*hs,4.55), S(0.14,0.06,0.12), C.get('eye',mat('Eye',(0.02,0.02,0.02))), 'Head')
    for side,s in (('Left',1),('Right',-1)):
        x = 0.9*bulk*s
        add('cyl', S(x,0,3.55), S(0.42*bulk,0.42*bulk,0.85), gi2 if C.get('sleeve') else arm, side+'UpperArm')
        add('cyl', S(x,0,2.75), S(0.36*bulk,0.36*bulk,0.8), arm, side+'LowerArm')
        add('cyl', S(x,0,2.5), S(0.42,0.42,0.3), glove, side+'LowerArm')
        add('cube', S(x,0,2.15), S(0.34,0.3,0.4), glove if C.get('gloves') else sk, side+'Hand')
        lx = 0.32*s
        add('cyl', S(lx,0,1.85), S(0.52*bulk,0.55*bulk,1.0), leg, side+'UpperLeg')
        add('cyl', S(lx,0,0.95), S(0.46*bulk,0.48*bulk,0.85), leg, side+'LowerLeg')
        add('cube', S(lx,0,0.55), S(0.5,0.56,0.45), boot, side+'LowerLeg')
        add('cube', S(lx,-0.12,0.15), S(0.5,0.78,0.3), boot, side+'Foot')
        J[side+'UpperArm']=(S(x,0,3.95),S(x,0,3.15)); J[side+'LowerArm']=(S(x,0,3.15),S(x,0,2.35))
        J[side+'Hand']=(S(x,0,2.35),S(x,0,1.95)); J[side+'UpperLeg']=(S(lx,0,2.4),S(lx,0,1.35))
        J[side+'LowerLeg']=(S(lx,0,1.35),S(lx,0,0.3)); J[side+'Foot']=(S(lx,0,0.3),S(lx,-0.4,0.05))
    J['HumanoidRootPart']=(S(0,0,2.0),S(0,0,2.6)); J['LowerTorso']=(S(0,0,2.4),S(0,0,2.9))
    J['UpperTorso']=(S(0,0,2.9),S(0,0,4.05)); J['Head']=(S(0,0,4.05),S(0,0,5.0))
    return J
PARENT = {'LowerTorso':'HumanoidRootPart','UpperTorso':'LowerTorso','Head':'UpperTorso'}
for s in ('Left','Right'):
    PARENT.update({s+'UpperArm':'UpperTorso',s+'LowerArm':s+'UpperArm',s+'Hand':s+'LowerArm',
                   s+'UpperLeg':'LowerTorso',s+'LowerLeg':s+'UpperLeg',s+'Foot':s+'LowerLeg'})
def make_rig(J, chain=None):
    bpy.ops.object.armature_add(location=(0,0,0)); arm = bpy.context.object; arm.name = cid+'_Rig'
    bpy.ops.object.mode_set(mode='EDIT'); eb = arm.data.edit_bones; eb.remove(eb[0])
    names = chain or list(J)
    for n in names:
        b = eb.new(n); b.head, b.tail = J[n]
    for n in names:
        p = PARENT.get(n) if not chain else (names[names.index(n)-1] if names.index(n) else None)
        if p: eb[n].parent = eb[p]
    bpy.ops.object.mode_set(mode='OBJECT'); return arm
def finish(arm, variants_hidden=()):
    groups = {}
    for o, c in PARTS: groups.setdefault(c, []).append(o)
    objs = []
    for c, lst in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in lst: o.select_set(True)
        bpy.context.view_layer.objects.active = lst[0]; bpy.ops.object.join()
        o = bpy.context.object; o.name = cid+'_'+c
        bpy.ops.object.shade_flat()
        o.parent = arm; md = o.modifiers.new('Armature','ARMATURE'); md.object = arm
        if c in variants_hidden: o.hide_render = True; o.hide_set(True)
        objs.append(o)
    return objs
def tris(objs):
    return {o.name: sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs}
def export_and_render(objs, arm, fbxname, height):
    for o in objs: o.hide_set(False)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs+[arm]: o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, fbxname+'.fbx'), use_selection=True, object_types={'ARMATURE','MESH'},
        apply_scale_options='FBX_SCALE_UNITS', add_leaf_bones=False, bake_anim=False, mesh_smooth_type='FACE')
for_render = []
def render(name, height, hide=()):
    for o in bpy.data.objects:
        if o.type=='MESH': o.hide_render = any(h in o.name for h in hide)
    if 'Cam' not in bpy.data.objects:
        bpy.ops.object.camera_add(); cam = bpy.context.object; cam.name='Cam'; sc.camera = cam
        bpy.ops.object.light_add(type='SUN', rotation=(math.radians(50),0,math.radians(30))); bpy.context.object.data.energy=4
        w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes=True
        w.node_tree.nodes['Background'].inputs[0].default_value=(0.25,0.27,0.35,1)
        tgt = bpy.data.objects.new('Tgt', None); sc.collection.objects.link(tgt)
        c = cam.constraints.new('TRACK_TO'); c.target = tgt
    cam = bpy.data.objects['Cam']; tgt = bpy.data.objects['Tgt']
    tgt.location = (0,0,height*0.5); d = height*1.9
    cam.location = (d*0.6, -d*0.8, height*0.7)
    for e in ('BLENDER_EEVEE','BLENDER_EEVEE_NEXT'):
        try: sc.render.engine = e; break
        except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = 800, 1000
    sc.render.filepath = os.path.join(OUT, name+'_preview.png'); bpy.ops.render.render(write_still=True)

M = lambda n,c,e=0: mat(n,c,e)
SKIN = M('Skin',(0.95,0.72,0.55)); BLACK=M('HairBlack',(0.02,0.02,0.03))
GOLD = M('HairSSJ',(1.0,0.85,0.15),0.6); BLUE=M('HairBlue',(0.1,0.65,1.0),0.8)
def hair_spikes(k, m, coll, style):
    S = lambda *v: tuple(x*k for x in v)
    if style=='goku':
        sp = [((0,0.1,5.0),(0,0.5,5.9)),((0.3,0.1,4.9),(0.9,0.6,5.6)),((-0.3,0.1,4.9),(-0.9,0.6,5.6)),
              ((0.4,0,4.7),(1.1,0.1,5.0)),((-0.4,0,4.7),(-1.1,0.1,5.0)),((0.3,0.3,4.5),(0.9,0.9,4.4)),
              ((-0.3,0.3,4.5),(-0.9,0.9,4.4)),((0,0.35,4.6),(0,1.0,4.6)),((0.15,-0.25,4.95),(0.3,-0.55,4.85)),
              ((-0.1,-0.28,4.95),(-0.35,-0.5,4.75)),((0,-0.2,5.0),(0.05,-0.45,4.7))]
        if coll!='Body':  # SSJ/Blue: taller, upswept
            sp = [(b,(t[0]*1.1,t[1]*0.6,t[2]+0.35)) for b,t in sp]
    else:  # vegeta flame
        sp = [((x,0.1,4.9),(x*1.3,0.25,6.0+0.0*x - abs(x)*0.6)) for x in (-0.3,-0.15,0,0.15,0.3)]
        sp += [((x,0.25,4.75),(x*1.6,0.5,5.6-abs(x))) for x in (-0.35,0,0.35)]
    add('sph', S(0,0.05,4.75), S(0.82,0.8,0.7), m, 'Head', coll=coll)
    for b,t in sp: spike(S(*b),S(*t),0.22*k,m,coll)

if cid in ('u7_goku','u7_vegeta','u7_frieza','u7_frieza_golden'):
    if cid=='u7_goku':
        C=dict(skin=SKIN,torso=M('GiOrange',(1.0,0.42,0.05)),chest=M('Undershirt',(0.05,0.15,0.6)),belt=M('BeltBlue',(0.05,0.15,0.6)),
               glove=M('WristbandBlue',(0.05,0.15,0.6)),boot=M('BootBlue',(0.05,0.15,0.6)),leg=M('GiOrange',(1,0.42,0.05)))
        J=humanoid(1,C)
        add('cube',(0,-0.04,3.4),(1.38,0.7,1.1),C['torso'],'UpperTorso')  # gi top over shirt (front V)
        add('cube',(0,-0.4,3.75),(0.5,0.1,0.6),C['chest'],'UpperTorso')
        add('sph',(0.38,-0.38,3.6),(0.25,0.03,0.25),M('Kanji',(0.95,0.95,0.95)),'UpperTorso')
        hair_spikes(1,BLACK,'Body','goku'); hair_spikes(1,GOLD,'Hair_SSJ','goku'); hair_spikes(1,BLUE,'Hair_Blue','goku')
        hidden=('Hair_SSJ','Hair_Blue')
    elif cid=='u7_vegeta':
        W=M('White',(0.95,0.95,0.95)); NAVY=M('SuitBlue',(0.08,0.12,0.5))
        C=dict(skin=SKIN,torso=NAVY,arm=NAVY,belt=NAVY,glove=W,gloves=True,boot=W,leg=NAVY)
        J=humanoid(0.96,C)
        k=0.96; add('cube',(0,-0.1*k,3.6*k),(1.42*k,0.7*k,0.9*k),W,'UpperTorso')  # armor-style chest (Super era shows suit; kept light)
        add('cube',(0,-0.12*k,3.3*k),(1.3*k,0.68*k,0.6*k),NAVY,'UpperTorso')
        hair_spikes(k,BLACK,'Body','vegeta'); hair_spikes(k,GOLD,'Hair_SSJ','vegeta'); hair_spikes(k,BLUE,'Hair_Blue','vegeta')
        hidden=('Hair_SSJ','Hair_Blue')
    else:
        gold = cid.endswith('golden')
        WH = M('FriezaGold',(1,0.78,0.15),0.3) if gold else M('FriezaWhite',(0.96,0.96,0.98))
        PU = M('FriezaGem',(0.55,0.15,0.75))
        C=dict(skin=WH,torso=WH,belt=WH,glove=WH,boot=WH,leg=WH,eye=M('EyeRed',(0.7,0.0,0.05)))
        J=humanoid(0.9,C,head_scale=0.95,bulk=0.85); k=0.9
        add('sph',(0,0.02,4.75*k),(0.72*k,0.72*k,0.55*k),PU,'Head',seg=12,rings=6)
        for s in (1,-1):
            add('sph',(0.88*s*k*0.85,0,3.95*k),(0.42*k,0.42*k,0.3*k),PU,('Left' if s>0 else 'Right')+'UpperArm')
            add('sph',(0.32*s*k,-0.25*k,1.55*k),(0.3*k,0.12*k,0.25*k),PU,('Left' if s>0 else 'Right')+'UpperLeg')
        add('sph',(0,-0.32*k,3.6*k),(0.5*k,0.15*k,0.45*k),PU,'UpperTorso')
        for i in range(8):  # tail curling behind
            a=i/7; add('cyl',(0.25*k*math.sin(a*3),(0.4+a*1.4)*k,(2.5-a*1.9+ (a**2)*1.2)*k),((0.32-0.25*a)*k,(0.32-0.25*a)*k,0.5*k),WH,'LowerTorso',rot=(math.radians(60),0,0))
        hidden=()
    arm=make_rig(J); objs=finish(arm,hidden)
    export_and_render(objs,arm,cid,5.5)
    if cid=='u7_goku': render('u7_goku',5.5,('Hair_SSJ','Hair_Blue'));
    elif cid=='u7_vegeta': render('u7_vegeta',5.5,('Hair_SSJ','Hair_Blue'))
    else: render(cid,5.5)
elif cid=='npc_zeno':
    k=0.6; BL=M('ZenoBlue',(0.3,0.55,0.95)); WR=M('ZenoRobe',(0.95,0.95,0.98)); MG=M('ZenoTrim',(0.85,0.2,0.6)); GD=M('Gold',(1,0.8,0.2))
    C=dict(skin=BL,torso=MG,torso2=MG,sleeve=True,belt=WR,glove=BL,boot=WR,leg=WR,arm=MG)
    J=humanoid(k,C,head_scale=1.9,bulk=1.1)
    add('cone',(0,0,1.6*k),(1.9*k,1.6*k,3.0*k),WR,'LowerTorso',seg=12,r2=0.35)  # robe
    add('cube',(0,-0.42*k,3.4*k),(0.5*k,0.08*k,1.0*k),GD,'UpperTorso')
    for s in (1,-1): add('sph',(0.3*s*k,-0.7*k,4.75*k),(0.35*k,0.08*k,0.3*k),M('Eye',(0.02,0.02,0.02)),'Head')
    arm=make_rig(J); objs=finish(arm); export_and_render(objs,arm,cid,3.3); render(cid,3.6)
elif cid=='npc_grand_priest':
    k=1.18; BL=M('PriestSkin',(0.35,0.55,0.9)); RB=M('PriestRobe',(0.15,0.2,0.45)); WH=M('PriestHair',(0.97,0.97,1.0)); RG=M('Halo',(0.6,0.9,1.0),2.0)
    ORG=M('PriestSash',(0.95,0.4,0.1))
    C=dict(skin=BL,torso=RB,torso2=RB,sleeve=True,belt=ORG,glove=RB,boot=RB,leg=RB,arm=RB)
    J=humanoid(k,C,bulk=0.9)
    add('cone',(0,0,1.25*k),(1.5*k,1.1*k,2.5*k),RB,'LowerTorso',seg=10,r2=0.6)
    add('cube',(0,-0.3*k,3.45*k),(0.2*k,0.1*k,1.1*k),WH,'UpperTorso')
    for i in range(5):  # tall swept mohawk
        add('cube',(0,(0.1+i*0.12)*k,(5.1+i*0.1)*k),(0.2*k,0.35*k,(0.8-i*0.08)*k),WH,'Head')
    add('torus',(0,0.35*k,4.6*k),(1.6*k,1.6*k,1.6*k),RG,'Head',rot=(math.radians(90),0,0),minor=0.04)
    arm=make_rig(J); objs=finish(arm); export_and_render(objs,arm,cid,6.5); render(cid,6.8)
elif cid=='npc_shenron':
    GD=M('ShenronGold',(1,0.75,0.12),0.15); BEL=M('ShenronBelly',(1,0.9,0.5)); RED=M('ShenronEye',(1,0,0),4.0); WH=M('Horn',(0.95,0.9,0.8))
    N=16; pts=[]
    for i in range(N+1):
        t=i/N; a=t*math.pi*3.2; r=6*(1-t*0.5)
        pts.append(Vector((r*math.cos(a), r*math.sin(a), t*22)))
    J={}; chain=[]
    for i in range(N):
        n='Seg%02d'%i; chain.append(n); J[n]=(tuple(pts[i]),tuple(pts[i+1]))
        d=pts[i+1]-pts[i]; mid=(pts[i]+pts[i+1])/2; rr=1.5*(0.55+0.45*(i/N))
        o=add('cyl',mid,(rr,rr,d.length*1.05),GD,n,seg=10)
        o.rotation_mode='QUATERNION'; o.rotation_quaternion=Vector((0,0,1)).rotation_difference(d.normalized())
        bpy.context.view_layer.objects.active=o; o.select_set(True); bpy.ops.object.transform_apply(rotation=True,location=False,scale=False); o.select_set(False)
        o2=add('cone',mid+Vector((0,0,rr*0.6)),(0.6,0.6,1.4),GD,n,seg=4)  # dorsal fin
        if i%4==2:
            for s in (1,-1): add('cone',mid+Vector((s*rr*1.3,0,0)),(1.6,0.3,3.0),M('Fin',(1,0.55,0.1)),n,rot=(0,s*math.radians(70),0),seg=4)
    h=pts[-1]; J['Head']=(tuple(h),tuple(h+Vector((0,-3,0.5)))); chain.append('Head')
    add('cube',h+Vector((0,-1.2,0.4)),(2.6,4.2,2.0),GD,'Head'); add('cube',h+Vector((0,-3.2,-0.1)),(1.9,2.2,1.0),BEL,'Head')
    for s in (1,-1):
        add('sph',h+Vector((s*0.9,-2.4,0.95)),(0.5,0.4,0.35),RED,'Head')
        spike(h+Vector((s*0.8,0.3,1.2)),h+Vector((s*1.6,2.8,3.0)),0.25,WH,'Body')
        spike(h+Vector((s*1.0,-3.8,-0.2)),h+Vector((s*3.0,-4.5,-1.5)),0.1,GD,'Body')
    for o,c in PARTS:  # whisker/horn spikes were grouped Head already
        pass
    arm=make_rig(J,chain); objs=finish(arm); export_and_render(objs,arm,cid,25); render(cid,24)
print('TRIS', cid, tris(objs))

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, cid+'.blend'))
