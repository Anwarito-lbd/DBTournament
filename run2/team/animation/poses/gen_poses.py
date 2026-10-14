#!/usr/bin/env python3
"""Generator for Dragon Block Z pose data (Goku/Vegeta/Frieza/Shared .lua).
Edit the clip definitions here and re-run: python3 gen_poses.py
Convention (degrees, joint-local, applied as CFrame.Angles(rx,ry,rz) on Motor6D.Transform):
  arms/legs rx>0 = swing forward; arm rz>0 = raise outward (mirrored for left side by helper);
  elbow rx>0 = bend forearm forward; knee rx<0 = bend; waist ry = twist; Root pos in studs.
"""
import copy, os
J = ["Root","Waist","Neck","LeftShoulder","LeftElbow","LeftWrist","RightShoulder","RightElbow","RightWrist",
     "LeftHip","LeftKnee","LeftAnkle","RightHip","RightKnee","RightAnkle"]
Z=(0,0,0)
def P(**kw):
    """pose builder: keys like RS=(rx,ry,rz) (right-side anatomical), LS=... mirrored automatically, root=(x,y,z) pos"""
    m={"R":"Root","W":"Waist","N":"Neck","S":"Shoulder","E":"Elbow","Wr":"Wrist","H":"Hip","K":"Knee","A":"Ankle"}
    out={}
    for k,v in kw.items():
        if k=="root": out.setdefault("Root",{})["pos"]=v; continue
        if k in("R","W","N"): out.setdefault(m[k],{})["rot"]=v; continue
        side={"L":"Left","R":"Right"}[k[0]]; part=m[k[1:]]
        rx,ry,rz=v
        if side=="Left": ry,rz=-ry,-rz
        out.setdefault(side+part,{})["rot"]=(rx,ry,rz)
    return out
def add(a,b):
    o=copy.deepcopy(a)
    for j,d in b.items():
        t=o.setdefault(j,{})
        for key in("pos","rot"):
            if key in d:
                base=t.get(key,Z); t[key]=tuple(round(x+y,2) for x,y in zip(base,d[key]))
    return o
def full(p):
    return {j:{"pos":p.get(j,{}).get("pos",Z),"rot":p.get(j,{}).get("rot",Z)} for j in J}

# ---------------- stances (hero docs) ----------------
STANCE={
 # Goku fighting stance: left fist forward, right fist at chin, knees bent, wide
 "Goku":P(root=(0,-0.25,0),W=(0,-20,0),N=(0,15,0),LS=(70,10,10),LE=(50,0,0),RS=(40,-20,15),RE=(110,0,0),
          LH=(15,0,8),LK=(-25,0,0),LA=(10,0,0),RH=(-10,0,10),RK=(-20,0,0),RA=(10,0,0)),
 # Vegeta: tighter, more upright, chin up
 "Vegeta":P(root=(0,-0.15,0),W=(0,-15,0),N=(-5,10,0),LS=(60,10,8),LE=(70,0,0),RS=(35,-15,12),RE=(105,0,0),
          LH=(10,0,6),LK=(-18,0,0),LA=(8,0,0),RH=(-8,0,8),RK=(-15,0,0),RA=(8,0,0)),
 # Frieza: distinct upright poise, chest out, arms low & loose (hand near hip), narrow stance, slight lean back
 "Frieza":P(root=(0,0,0),W=(-6,-8,0),N=(-8,5,0),LS=(5,0,12),LE=(25,0,0),LWr=(0,0,10),RS=(15,0,10),RE=(35,0,0),RWr=(10,0,-10),
          LH=(4,0,3),LK=(-6,0,0),RH=(-4,0,3),RK=(-6,0,0)),
}
def K(t,ease,pose,markers=None): return {"t":t,"ease":ease,"pose":pose,"markers":markers}
def clip(length,frames,looped=False,priority="Action"): return {"length":length,"looped":looped,"priority":priority,"frames":frames}

# ---------------- generic builders (VFX_QUALITY_BAR §1 timings) ----------------
def m1(punch_side,ant,hold=4,rec=8,kick=False,tier="Light",finisher=False,heavy=False,smear_vfx=None):
    """anticipation(ant f, CubicIn) -> smear 1f -> contact(+2f Linear) -> hold(Constant) -> recovery(QuadOut)"""
    s=punch_side; o="L" if s=="R" else "R"
    if kick:
        wind=P(W=(0,25 if s=="R" else -25,0),**{s+"H":(-30,0,0),s+"K":(-60,0,0),o+"K":(-10,0,0)})
        strike=P(W=(-5,-30 if s=="R" else 30,0),**{s+"H":(85,0,15),s+"K":(0,0,0),s+"A":(-20,0,0),o+"K":(-15,0,0)},root=(0,0.1,-0.4))
    else:
        wind=P(W=(0,30 if s=="R" else -30,0),**{s+"S":(20,-20,10),s+"E":(130,0,0),o+"S":(60,0,0)})
        strike=P(W=(5,-35 if s=="R" else 35,0),**{s+"S":(90,20,5),s+"E":(0,0,0),s+"Wr":(0,0,0),o+"S":(30,0,10),o+"E":(110,0,0)},root=(0,0,-0.5))
    if heavy:
        wind=add(wind,P(W=(10,15,0),root=(0,-0.2,0.3))); strike=add(strike,P(W=(-10,0,0),root=(0,-0.1,-0.8)))
    hit={"hit":{"tier":tier,"hitstop":tier},"vfx":"VFXCommon.Hitstop:"+tier+(";VFXCommon.ImpactFrame:invert:2" if finisher else ""),"sound":"Hit_"+tier}
    contact=ant+2; L=contact+hold+rec
    return clip(L,[K(0,"Linear",{}),K(ant,"CubicIn",wind,{"sound":"Swing"}),
                  K(ant+1,"Linear",add(wind,P()) if False else strike,{"vfx":smear_vfx or "VFXCommon.Afterimage:0.5"}),
                  K(contact,"Linear",strike,hit),K(contact+hold,"Constant",strike),K(L,"QuadOut",{})])

def base_set(h):
    fr=h=="Frieza"; vg=h=="Vegeta"
    a=5 if not vg else 4
    c={}
    c["Idle"]=clip(120,[K(0,"Sine",{}),K(60,"Sine",P(root=(0,-0.05,0),W=(2,0,0),N=(2,0,0))),K(120,"Sine",{})],True,"Idle")
    if vg: c["Idle_PridefulCross"]=clip(120,[K(0,"Sine",P(N=(-12,0,0),LS=(40,40,0),LE=(100,30,0),RS=(45,-40,0),RE=(100,-30,0))),
                                            K(60,"Sine",P(N=(-14,0,0),LS=(41,40,0),LE=(100,30,0),RS=(46,-40,0),RE=(100,-30,0),root=(0,-0.03,0))),
                                            K(120,"Sine",P(N=(-12,0,0),LS=(40,40,0),LE=(100,30,0),RS=(45,-40,0),RE=(100,-30,0)))],True,"Idle")
    c["M1_1"]=m1("L",a,kick=False)
    c["M1_2"]=m1("R",a,kick=fr)          # Frieza: tail-swipe-ish spin kick (tail is a separate rig chain)
    c["M1_3"]=m1("R",a+1,kick=not fr)    # Goku/Vegeta knee/kick
    c["M1_4"]=m1("L" if fr else "R",10 if not vg else 8,hold=8,rec=18,kick=fr,tier="Finisher",finisher=True,heavy=True)
    c["Heavy"]=m1("R",12,hold=10,rec=18,tier="Heavy",heavy=True,smear_vfx="VFXCommon.Afterimage:0.4;VFXCommon.SpeedLines:0.3")
    # Launcher: crouch -> uppercut rising
    crouch=P(root=(0,-0.6,0),W=(20,10,0),RS=(-20,0,15),RE=(120,0,0),LK=(-60,0,0),RK=(-60,0,0),LH=(40,0,0),RH=(40,0,0))
    upper=P(root=(0,0.6,-0.3),W=(-20,-15,0),N=(-20,0,0),RS=(170,0,10),RE=(10,0,0),LS=(20,0,20),LK=(-10,0,0),RH=(30,0,0),RK=(-70,0,0))
    c["Launcher"]=clip(36,[K(0,"Linear",{}),K(8,"CubicIn",crouch,{"sound":"Swing_Heavy"}),K(9,"Linear",upper,{"vfx":"VFXCommon.Afterimage:0.4"}),
                           K(10,"Linear",upper,{"hit":{"tier":"Heavy","launch":True},"vfx":"VFXCommon.Hitstop:Heavy;VFXCommon.Shockwave","sound":"Hit_Heavy"}),
                           K(20,"Constant",upper),K(36,"QuadOut",{})])
    # Air combo: 3 aerial strikes, legs tucked
    tuck=P(LH=(60,0,0),LK=(-90,0,0),RH=(40,0,0),RK=(-80,0,0))
    s1=add(tuck,P(W=(0,-30,0),RS=(90,20,0),RE=(0,0,0)))
    s2=add(tuck,P(W=(0,30,0),LS=(90,20,0),LE=(0,0,0)))
    s3=P(W=(30,0,0),N=(20,0,0),RS=(150,0,0),LS=(150,0,0),RE=(20,0,0),LE=(20,0,0),LH=(-20,0,0),RH=(-20,0,0),root=(0,0.3,0))
    s3b=P(W=(-35,0,0),RS=(10,0,0),LS=(10,0,0),LH=(30,0,0),RH=(30,0,0),root=(0,-0.3,-0.4))
    c["AirCombo"]=clip(66,[K(0,"Linear",tuck),K(5,"CubicIn",add(tuck,P(W=(0,20,0),RS=(30,0,0),RE=(120,0,0)))),
        K(7,"Linear",s1,{"hit":{"tier":"Light"},"vfx":"VFXCommon.Hitstop:Light","sound":"Hit_Light"}),K(11,"Constant",s1),
        K(17,"CubicIn",add(tuck,P(W=(0,-20,0),LS=(30,0,0),LE=(120,0,0)))),
        K(19,"Linear",s2,{"hit":{"tier":"Light"},"vfx":"VFXCommon.Hitstop:Light","sound":"Hit_Light"}),K(23,"Constant",s2),
        K(35,"CubicIn",s3,{"sound":"Swing_Heavy"}),K(37,"Linear",s3b,{"hit":{"tier":"Finisher","spike":True},"vfx":"VFXCommon.Hitstop:Finisher;VFXCommon.ImpactFrame:invert:2","sound":"Hit_Heavy"}),
        K(49,"Constant",s3b),K(66,"QuadOut",tuck)])
    # Ki volley: alternating palms x6
    kf=[K(0,"Linear",{})]; t=4
    blast="DeathBeamVFX.Play" if fr else "VFXCommon.KiBlast"
    for i in range(6):
        sd="R" if i%2==0 else "L"; od="L" if sd=="R" else "R"
        pose=P(W=(0,-15 if sd=="R" else 15,0),**{sd+"S":(90,15,0),sd+"E":(0,0,0),sd+"Wr":(-60,0,0),od+"S":(40,0,10),od+"E":(90,0,0)},root=(0,0,-0.15))
        kf.append(K(t,"CubicIn",add(pose,P(**{sd+"E":(50,0,0)})))); kf.append(K(t+2,"Linear",pose,{"vfx":blast,"sound":"KiBlast"})); t+=8
    kf.append(K(t+10,"QuadOut",{})); c["KiVolley"]=clip(t+10,kf)
    guard=P(root=(0,-0.2,0),W=(10,0,0),N=(10,0,0),LS=(80,30,0),LE=(130,0,0),RS=(80,-30,0),RE=(130,0,0),LK=(-20,0,0),RK=(-20,0,0))
    if fr: guard=P(root=(0,-0.1,0),W=(-5,0,0),RS=(85,-20,0),RE=(100,0,0),RWr=(-40,0,0),LS=(10,0,15),LE=(40,0,0))  # one-handed casual guard
    c["Guard"]=clip(30,[K(0,"Linear",{}),K(4,"CubicOut",guard),K(30,"Constant",guard)],True,"Action")
    pg=add(guard,P(root=(0,0,0.15),W=(-8,0,0),LS=(10,0,30),RS=(10,0,30),LE=(-60,0,0),RE=(-60,0,0)))
    c["PerfectGuard"]=clip(30,[K(0,"Linear",guard),K(2,"BackOut",pg,{"vfx":"VFXCommon.ImpactFrame:white:1;VFXCommon.Shockwave;VFXCommon.Hitstop:Medium","sound":"PerfectGuard"}),
                               K(12,"Constant",pg),K(30,"QuadOut",{})],False,"Action2")
    dash=P(root=(0,-0.2,-0.6),W=(35,0,0),N=(-25,0,0),LS=(-40,0,15),RS=(-40,0,15),LE=(10,0,0),RE=(10,0,0),LH=(-30,0,0),RH=(20,0,0),LK=(-50,0,0),RK=(-30,0,0))
    c["Dash"]=clip(24,[K(0,"CubicIn",{}),K(3,"Linear",dash,{"vfx":"VFXCommon.Afterimage:0.4;VFXCommon.SpeedLines:0.2","sound":"Dash"}),K(16,"Constant",dash),K(24,"QuadOut",{})],False,"Movement")
    fly=P(W=(5,0,0),LS=(10,0,15),RS=(10,0,15),LE=(30,0,0),RE=(30,0,0),LH=(10,0,3),RH=(25,0,3),LK=(-15,0,0),RK=(-50,0,0),LA=(-30,0,0),RA=(-30,0,0))
    if fr: fly=P(LS=(40,40,0),LE=(100,30,0),RS=(45,-40,0),RE=(100,-30,0),LH=(25,0,0),RH=(25,0,0),LK=(-60,0,0),RK=(-60,0,0))  # hover poise, arms crossed
    c["FlyIdle"]=clip(120,[K(0,"Sine",fly),K(60,"Sine",add(fly,P(root=(0,0.3,0),W=(2,0,0)))),K(120,"Sine",fly)],True,"Movement")
    hl=P(root=(0,0,0.2),W=(-20,10,0),N=(-25,0,0),LS=(-10,0,30),RS=(-10,0,20))
    c["HurtLight"]=clip(18,[K(0,"Linear",{}),K(2,"CubicOut",hl,{"vfx":"VFXCommon.Hitstop:Light"}),K(6,"Constant",hl),K(18,"QuadOut",{})],False,"Action2")
    hh=P(root=(0,-0.2,0.6),W=(-40,15,10),N=(-35,0,0),LS=(-30,0,60),RS=(-30,0,50),LE=(20,0,0),RE=(30,0,0),LH=(30,0,0),RH=(10,0,0),LK=(-30,0,0))
    c["HurtHeavy"]=clip(36,[K(0,"Linear",{}),K(2,"CubicOut",hh,{"vfx":"VFXCommon.Hitstop:Heavy;VFXCommon.CameraShake:0.35"}),K(14,"Constant",hh),K(36,"QuadOut",{})],False,"Action2")
    ko1=P(root=(0,-0.5,0.8),W=(-45,20,15),N=(-40,0,0),LS=(-40,0,80),RS=(-40,0,70),LH=(40,0,0),RH=(20,0,0),LK=(-40,0,0),RK=(-20,0,0))
    ko2=P(root=(0,-2.6,1.5),W=(-80,0,0),N=(-10,30,0),LS=(-10,0,95),RS=(-20,0,85),LE=(20,0,0),LH=(-10,0,10),RH=(5,0,8),LK=(-15,0,0))
    c["KO"]=clip(90,[K(0,"Linear",{}),K(3,"CubicOut",ko1,{"vfx":"VFXCommon.ImpactFrame:invert:3;VFXCommon.Hitstop:Ultimate","sound":"KO"}),
                     K(30,"QuadOut",ko2,{"vfx":"VFXCommon.DebrisBurst;VFXCommon.CameraShake:0.5","sound":"BodyFall"}),K(90,"Constant",ko2)],False,"Action2")
    return c

def three_phase(name,charge,hold,fire,ch_len,fire_len,vfx_charge,vfx_fire,vfx_end=None,charge_mid=None):
    c={}
    kf=[K(0,"Linear",{}),K(int(ch_len*0.4),"CubicIn",charge_mid or charge,{"vfx":vfx_charge,"sound":name+"_Charge"}),K(ch_len,"Sine",charge)]
    c[name+"_Charge"]=clip(ch_len,kf,False,"Action4")
    c[name+"_Hold"]=clip(60,[K(0,"Sine",charge),K(30,"Sine",add(charge,hold)),K(60,"Sine",charge)],True,"Action4")
    c[name+"_Fire"]=clip(fire_len,[K(0,"Linear",charge),K(2,"Linear",fire,{"vfx":vfx_fire,"sound":name+"_Fire"}),
                                   K(8,"Constant",fire),K(fire_len-20,"Sine",add(fire,P(root=(0,0,0.1)))),
                                   K(fire_len,"QuadOut",{},{"vfx":vfx_end} if vfx_end else None)],False,"Action4")
    return c

def transform(name,length,beats):
    kf=[] if beats[0][0]==0 else [K(0,"Linear",{})]
    for t,ease,pose,mk in beats: kf.append(K(t,ease,pose,mk))
    kf.append(K(length,"QuadOut",kf[-1]["pose"]))
    return {"Transform_"+name:clip(length,kf,False,"Action3")}

def scream(intensity=1.0):
    return P(root=(0,-0.4*intensity,0),W=(-25*intensity,0,0),N=(-35*intensity,0,0),LS=(-20,0,35*intensity),RS=(-20,0,35*intensity),
             LE=(60,0,0),RE=(60,0,0),LK=(-35,0,0),RK=(-35,0,0),LH=(10,0,15),RH=(10,0,15))
crouchP=P(root=(0,-0.7,0),W=(35,0,0),N=(30,0,0),LS=(30,40,0),RS=(30,40,0),LE=(120,0,0),RE=(120,0,0),LK=(-70,0,0),RK=(-70,0,0),LH=(45,0,15),RH=(45,0,15))

HEROES={}
# ---------------- Goku ----------------
g=base_set("Goku")
kame_ch=P(root=(0,-0.5,0.2),W=(5,70,0),N=(0,-60,0),RS=(20,-40,40),RE=(100,0,0),RWr=(0,0,40),LS=(30,-70,10),LE=(100,0,0),LWr=(0,0,-40),
          LH=(30,0,25),LK=(-50,0,0),RH=(-25,0,20),RK=(-20,0,0))
kame_fire=P(root=(0,-0.4,-0.3),W=(0,-10,0),N=(0,5,0),RS=(90,0,0),RE=(0,0,0),RWr=(-80,0,0),LS=(90,0,0),LE=(0,0,0),LWr=(-80,0,0),
            LH=(35,0,25),LK=(-45,0,0),RH=(-30,0,20),RK=(-15,0,0))
g.update(three_phase("Kamehameha",kame_ch,P(W=(0,3,0),root=(0,-0.03,0)),kame_fire,90,90,"KamehamehaVFX.Play:charge","KamehamehaVFX.Play:fire;VFXCommon.ImpactFrame:white:1;VFXCommon.FOVPunch:10;VFXCommon.SpeedLines","VFXCommon.Impact:Ultimate",
                     charge_mid=add(kame_ch,P(W=(0,-10,0)))))
it=P(N=(10,0,0),RS=(150,-40,-30),RE=(140,0,0),RWr=(0,0,20),LS=(5,0,10))
g["InstantTransmission"]=clip(30,[K(0,"Linear",{}),K(10,"CubicOut",it,{"vfx":"InstantTransmissionVFX.Vanish","sound":"IT"}),K(22,"Constant",it,{"vfx":"InstantTransmissionVFX.Appear"}),K(30,"QuadOut",{})],False,"Action4")
sb=P(root=(0,-0.1,0),W=(-10,0,0),N=(-40,0,0),LS=(175,0,10),RS=(175,0,10),LE=(5,0,0),RE=(5,0,0),LK=(-15,0,0),RK=(-15,0,0),LH=(5,0,12),RH=(5,0,12))
sb_throw=P(root=(0,-0.2,-0.5),W=(25,0,0),N=(0,0,0),LS=(100,0,10),RS=(100,0,10),LE=(0,0,0),RE=(0,0,0),LH=(30,0,10),LK=(-40,0,0))
g.update(three_phase("SpiritBomb",sb,P(N=(-3,0,0),root=(0,0.05,0)),sb_throw,120,60,"SpiritBombVFX.Play","SpiritBombVFX.Play:throw;VFXCommon.ImpactFrame:black:1","VFXCommon.Impact:Ultimate"))
ui=P(root=(0,0.05,0),W=(-3,0,0),N=(-3,0,0),LS=(15,0,8),RS=(15,0,8),LE=(25,0,0),RE=(25,0,0),LK=(-5,0,0),RK=(-5,0,0))
g["Idle_UI"]=clip(120,[K(0,"Sine",ui),K(60,"Sine",add(ui,P(root=(0.05,0,0),W=(0,0,1)))),K(120,"Sine",ui)],True,"Idle")
mui_strike=P(W=(0,-25,0),RS=(85,15,0),RE=(0,0,0),RWr=(-70,0,0),LS=(20,0,10),root=(0,0,-0.4))
g["MUIRush"]=clip(84,[K(0,"Linear",ui)]+[x for i in range(8) for x in [K(4+i*8,"CubicIn",add(ui,P(W=(0,25 if i%2 else -25,0)))),K(6+i*8,"Linear",mui_strike if i%2==0 else add(mui_strike,P(W=(0,50,0))),{"vfx":"MUIRushVFX.Play:strike;VFXCommon.Afterimage","hit":{"tier":"Light"}})]]+
                 [K(72,"Linear",add(mui_strike,P(root=(0,-0.2,-0.3))),{"vfx":"MUIRushVFX.Play:final;VFXCommon.ImpactFrame:invert:3;VFXCommon.Hitstop:Finisher","hit":{"tier":"Finisher"}}),K(84,"QuadOut",ui)],False,"Action4")
g.update(transform("SSJ",120,[(20,"CubicIn",crouchP,{"sound":"Scream_Build","vfx":"TransformationVFX.Start:SuperSaiyan"}),
                              (60,"Sine",scream(0.8),{"vfx":"VFXCommon.CameraShake:0.4"}),(100,"CubicIn",scream(1.2),None),
                              (104,"BackOut",scream(1.0),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3","sound":"Transform_Flash"})]))
g.update(transform("SSB",140,[(30,"CubicIn",P(root=(0,-0.3,0),W=(10,0,0),N=(10,0,0),LS=(10,0,20),RS=(10,0,20),LE=(90,0,0),RE=(90,0,0)),{"vfx":"TransformationVFX.Start:SuperSaiyanBlue"}),
                              (80,"Linear",scream(0.6),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3","sound":"Transform_Flash"}),(110,"Sine",P(N=(-5,0,0)),None)]))
g.update(transform("UI",180,[(30,"Sine",P(N=(15,0,0),W=(8,0,0),LS=(5,0,5),RS=(5,0,5)),{"vfx":"TransformationVFX.Start:UltraInstinct","sound":"UI_Hum"}),
                             (120,"Sine",add(ui,P(N=(5,0,0))),None),(150,"Linear",ui,{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3"})]))
HEROES["Goku"]=g

# ---------------- Vegeta ----------------
v=base_set("Vegeta")
ff_ch=P(root=(0,-0.2,0),W=(-10,0,0),N=(-15,0,0),LS=(0,0,90),RS=(0,0,90),LE=(0,0,0),RE=(0,0,0),LWr=(0,0,70),RWr=(0,0,70),LH=(5,0,15),RH=(5,0,15),LK=(-20,0,0),RK=(-20,0,0))
ff_fire=P(root=(0,-0.3,-0.3),W=(5,0,0),N=(0,0,0),LS=(90,-5,0),RS=(90,-5,0),LE=(0,0,0),RE=(0,0,0),LWr=(-80,0,0),RWr=(-80,0,0),LH=(25,0,12),LK=(-35,0,0),RH=(-20,0,12),RK=(-15,0,0))
v.update(three_phase("FinalFlash",ff_ch,P(LS=(0,0,3),RS=(0,0,3)),ff_fire,96,108,"FinalFlashVFX.Play:charge","FinalFlashVFX.Play:fire;VFXCommon.ImpactFrame:white:2;VFXCommon.FOVPunch:14","VFXCommon.Impact:Ultimate"))
gg_ch=P(root=(0,-0.35,0.1),W=(0,85,0),N=(0,-75,0),RS=(70,-60,0),RE=(60,0,0),RWr=(-60,0,0),LS=(70,-80,0),LE=(70,0,0),LWr=(-60,0,0),LH=(25,0,20),LK=(-40,0,0),RH=(-20,0,15),RK=(-15,0,0))
gg_fire=add(gg_ch,P(root=(0,0,-0.2),RE=(-50,0,0),LE=(-60,0,0),W=(0,-10,0)))
v.update(three_phase("GalickGun",gg_ch,P(W=(0,2,0)),gg_fire,60,80,"GalickGunVFX.Play:charge","GalickGunVFX.Play:fire;VFXCommon.ImpactFrame:white:1;VFXCommon.FOVPunch:10","VFXCommon.Impact:Ultimate"))
bb=P(W=(0,-20,0),RS=(90,0,0),RE=(0,0,0),RWr=(-80,0,0),LS=(0,0,10),LE=(20,0,0),root=(0,-0.1,-0.2))
v["BigBangAttack"]=clip(70,[K(0,"Linear",{}),K(24,"CubicIn",add(bb,P(RE=(40,0,0),root=(0,0,0.2))),{"vfx":"BigBangAttackVFX.Play:charge"}),K(36,"Linear",bb,{"vfx":"BigBangAttackVFX.Play:fire","sound":"BigBang"}),K(46,"Constant",bb),K(70,"QuadOut",{})],False,"Action4")
fe_in=P(root=(0,-0.6,0),W=(25,0,0),N=(20,0,0),LS=(40,50,0),RS=(40,50,0),LE=(130,0,0),RE=(130,0,0),LK=(-60,0,0),RK=(-60,0,0),LH=(40,0,15),RH=(40,0,15))
fe_out=P(root=(0,-0.2,0),W=(-30,0,0),N=(-40,0,0),LS=(0,0,100),RS=(0,0,100),LE=(0,0,0),RE=(0,0,0),LH=(0,0,20),RH=(0,0,20),LK=(-10,0,0),RK=(-10,0,0))
v["FinalExplosion"]=clip(200,[K(0,"Linear",{}),K(30,"CubicIn",fe_in,{"vfx":"FinalExplosionVFX.Play","sound":"FinalExplosion_Charge"}),K(110,"Sine",add(fe_in,P(root=(0,-0.05,0)))),
                              K(120,"BackOut",fe_out,{"vfx":"VFXCommon.ImpactFrame:invert:3;VFXCommon.FOVPunch:18","sound":"FinalExplosion_Blast"}),K(200,"Constant",fe_out)],False,"Action4")
v.update(transform("SSJ",120,[(18,"CubicIn",crouchP,{"vfx":"TransformationVFX.Start:SuperSaiyan","sound":"Scream_Build"}),(90,"Sine",scream(1.1),None),
                              (100,"BackOut",scream(1.0),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3"})]))
v.update(transform("SSB",140,[(30,"CubicIn",P(root=(0,-0.25,0),N=(-10,0,0),LS=(10,0,25),RS=(10,0,25),LE=(80,0,0),RE=(80,0,0)),{"vfx":"TransformationVFX.Start:SuperSaiyanBlue"}),
                              (80,"Linear",scream(0.7),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3"}),(115,"Sine",P(N=(-12,0,0),LS=(40,40,0),LE=(100,30,0),RS=(45,-40,0),RE=(100,-30,0)),None)]))
v.update(transform("UltraEgo",240,[(0,"Linear",P(N=(15,0,0)),{"vfx":"TransformationVFX.Start:UltraEgo"}),(60,"Sine",P(root=(0,-0.1,0),N=(20,0,0),LS=(5,0,15),RS=(5,0,15),LE=(60,0,0),RE=(60,0,0)),None),
                                   (180,"CubicIn",add(crouchP,P(N=(-20,0,0))),{"vfx":"VFXCommon.CameraShake:0.6"}),
                                   (200,"BackOut",P(root=(0,0,0),W=(-10,0,0),N=(-15,0,0),LS=(5,0,30),RS=(5,0,30),LE=(30,0,0),RE=(30,0,0)),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3","sound":"UltraEgo_Flash"}),
                                   (225,"Sine",P(N=(-10,10,0),LS=(5,0,25),RS=(5,0,25)),None)]))
HEROES["Vegeta"]=v

# ---------------- Frieza ----------------
f=base_set("Frieza")
db_point=P(W=(0,-25,0),N=(0,15,0),RS=(90,10,0),RE=(0,0,0),RWr=(-10,0,0),LS=(5,0,10),LE=(90,30,0),LWr=(0,0,20))  # other hand on hip
f.update(three_phase("DeathBeam",add(db_point,P(RE=(20,0,0))),P(RWr=(-2,0,0)),db_point,6,30,"DeathBeamVFX.Play:aim","DeathBeamVFX.Play;VFXCommon.Hitstop:Light"))
f["DeathBeam_Charge"]["length"]=6  # near-instant
dball=P(root=(0,0.05,0),W=(-10,0,0),N=(-25,0,0),RS=(175,0,-5),RE=(0,0,0),RWr=(0,0,0),LS=(5,0,10),LE=(90,30,0),LWr=(0,0,20),LH=(0,0,3),RH=(0,0,3))
dball_throw=P(W=(15,-10,0),N=(5,0,0),RS=(110,0,0),RE=(10,0,0),RWr=(-40,0,0),LS=(5,0,10),LE=(90,30,0),root=(0,-0.05,-0.2))
f.update(three_phase("DeathBall",dball,P(N=(-2,0,0)),dball_throw,132,60,"DeathBallVFX.Play:charge;VFXCommon.FOVPunch:-6","DeathBallVFX.Play:throw;VFXCommon.ImpactFrame:black:1","VFXCommon.Impact:Ultimate"))
disc=P(N=(-15,0,0),RS=(170,0,0),RE=(10,0,0),RWr=(-90,0,0),LS=(5,0,10),LE=(90,30,0))
f["DestructoDisc"]=clip(48,[K(0,"Linear",{}),K(12,"CubicOut",disc,{"vfx":"DestructoDiscVFX.Play:raise"}),K(30,"Constant",disc),
                            K(32,"Linear",P(W=(10,-30,0),RS=(80,30,0),RE=(0,0,0),RWr=(0,0,0),LS=(5,0,10),LE=(90,30,0)),{"vfx":"DestructoDiscVFX.Play:throw","sound":"Disc_Throw"}),K(48,"QuadOut",{})],False,"Action4")
nova=P(root=(0,-0.1,-0.6),W=(30,-30,0),N=(-20,0,0),RS=(-10,-40,30),LS=(60,40,0),LE=(110,0,0),LH=(20,0,0),RH=(-30,0,0),RK=(-60,0,0))
f["NovaStrike"]=clip(72,[K(0,"Linear",{}),K(8,"CubicIn",nova,{"vfx":"NovaStrikeVFX.Play","sound":"Nova"}),K(62,"Constant",nova,{"hit":{"tier":"Heavy"},"vfx":"VFXCommon.Hitstop:Heavy"}),K(72,"QuadOut",{})],False,"Action4")
f["BlackNova"]=clip(60,[K(0,"Linear",{}),K(6,"CubicIn",nova,{"vfx":"BlackFriezaVFX.Play","sound":"BlackNova"}),K(36,"Constant",nova,{"hit":{"tier":"Heavy"}}),
                         K(57,"Constant",add(nova,P(N=(10,0,0))),{"vfx":"VFXCommon.ImpactFrame:invert:3"}),K(60,"QuadOut",{})],False,"Action4")
f.update(transform("Golden",180,[(0,"Linear",P(LS=(0,0,70),RS=(0,0,70),W=(-15,0,0),N=(-15,0,0)),{"vfx":"TransformationVFX.Start:Golden","sound":"Frieza_Laugh"}),
                                 (40,"Sine",P(root=(0,0.3,0),LS=(0,0,80),RS=(0,0,80),W=(-20,0,0),N=(-20,0,0),LH=(0,0,5),RH=(0,0,5)),{"vfx":"VFXCommon.CameraShake:0.3"}),
                                 (130,"BackOut",P(root=(0,0.2,0),LS=(-5,0,90),RS=(-5,0,90),W=(-25,0,0),N=(-25,0,0)),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3","sound":"Golden_Shatter"}),
                                 (160,"CubicOut",P(W=(-8,-10,0),N=(-10,10,0),LS=(5,0,12),LE=(90,30,0),RS=(20,0,10),RE=(60,0,0)),None)]))
f.update(transform("Black",90,[(0,"Linear",{},{"vfx":"TransformationVFX.Start:FriezaBlack"}),(20,"Sine",P(N=(15,0,0),W=(5,0,0)),None),
                               (40,"Linear",P(W=(-5,0,0),N=(-10,0,0)),{"vfx":"TransformationVFX.Stop:true;VFXCommon.ImpactFrame:invert:3","sound":"Black_Arrive"}),
                               (70,"Sine",P(N=(-12,-10,0),LS=(5,0,12),LE=(90,30,0)),None)]))
HEROES["Frieza"]=f

# ---------------- emit ----------------
def lua_num(x):
    return ("%g"%x)
def emit_pose(p,indent):
    lines=[]
    for j in J:
        d=p[j]
        lines.append(f'{indent}{j} = {{pos = {{{", ".join(lua_num(x) for x in d["pos"])}}}, rot = {{{", ".join(lua_num(x) for x in d["rot"])}}}}},')
    return "\n".join(lines)
def emit_markers(m):
    if not m: return "nil"
    parts=[]
    for k,v in m.items():
        if isinstance(v,dict):
            inner=", ".join(f'{a} = {("true" if b is True else ("\"%s\""%b if isinstance(b,str) else lua_num(b)))}' for a,b in v.items())
            parts.append(f"{k} = {{{inner}}}")
        else: parts.append(f'{k} = "{v}"')
    return "{"+", ".join(parts)+"}"
def emit_hero(name,clips,stance):
    out=[f"--!nonstrict\n-- poses/{name}.lua — GENERATED by gen_poses.py (edit the generator, not this file).",
         "-- Dragon Block Z keyframe pose data. Format: clip -> {fps, length, looped, priority, keyframes = {{t, ease, poses = {[joint] = {pos, rot}}, markers}}}",
         "-- pos in studs, rot in degrees (CFrame.Angles order X,Y,Z) applied to Motor6D.Transform. All 15 R15 joints present on every keyframe.",
         "-- Markers name VFX/module calls (\"Module.Function:arg\"), resolved by PosePlayer opts.OnMarker / VFX registry.",
         f"-- Stance baked in (hero doc pose). Numbers are DESIGN values; tune visually in Studio.","local clips = {}",""]
    for cn,c in clips.items():
        out.append(f'clips.{cn} = {{fps = 60, length = {c["length"]}, looped = {"true" if c["looped"] else "false"}, priority = "{c["priority"]}", keyframes = {{')
        for k in sorted(c["frames"],key=lambda k:k["t"]):
            pose=full(add(stance,k["pose"]))
            out.append(f'\t{{t = {k["t"]}, ease = "{k["ease"]}", markers = {emit_markers(k["markers"])}, poses = {{')
            out.append(emit_pose(pose,"\t\t"))
            out.append("\t}},")
        out.append("}}"); out.append("")
    out.append("return clips")
    return "\n".join(out)+"\n"
here=os.path.dirname(os.path.abspath(__file__))
for h,c in HEROES.items():
    # sanity: unique sorted t, last t <= length
    for cn,cl in c.items():
        ts=[k["t"] for k in cl["frames"]]
        assert len(ts)==len(set(ts)), (h,cn,ts)
        assert max(ts)<=cl["length"], (h,cn,ts,cl["length"])
    open(os.path.join(here,h+".lua"),"w").write(emit_hero(h,c,STANCE[h]))
    print(h,len(c),"clips")

# ---------------- Shared.lua: joint metadata + neutral common clips (for any R15 hero) ----------------
shared_clips={k:v for k,v in base_set("Shared").items() if k in("Idle","Dash","Guard","PerfectGuard","FlyIdle","HurtLight","HurtHeavy","KO","KiVolley","Launcher","AirCombo","Heavy","M1_1","M1_2","M1_3","M1_4")}
body=emit_hero("Shared",shared_clips,{}).replace("local clips = {}","""local clips = {}
local Shared = {}
-- R15 Motor6D joint names (pose keys) and the Part that owns each Motor6D (its Part1).
Shared.JOINTS = {"Root", "Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
	"LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle"}
Shared.JOINT_PART = {Root = "LowerTorso", Waist = "UpperTorso", Neck = "Head",
	LeftShoulder = "LeftUpperArm", LeftElbow = "LeftLowerArm", LeftWrist = "LeftHand",
	RightShoulder = "RightUpperArm", RightElbow = "RightLowerArm", RightWrist = "RightHand",
	LeftHip = "LeftUpperLeg", LeftKnee = "LeftLowerLeg", LeftAnkle = "LeftFoot",
	RightHip = "RightUpperLeg", RightKnee = "RightLowerLeg", RightAnkle = "RightFoot"}
-- KeyframeSequence Pose hierarchy (child part -> parent part); HumanoidRootPart is the root Pose.
Shared.PART_PARENT = {LowerTorso = "HumanoidRootPart", UpperTorso = "LowerTorso", Head = "UpperTorso",
	LeftUpperArm = "UpperTorso", LeftLowerArm = "LeftUpperArm", LeftHand = "LeftLowerArm",
	RightUpperArm = "UpperTorso", RightLowerArm = "RightUpperArm", RightHand = "RightLowerArm",
	LeftUpperLeg = "LowerTorso", LeftLowerLeg = "LeftUpperLeg", LeftFoot = "LeftLowerLeg",
	RightUpperLeg = "LowerTorso", RightLowerLeg = "RightUpperLeg", RightFoot = "RightLowerLeg"}
-- Quality-bar timing constants (VFX_QUALITY_BAR.md section 1), frames @60
Shared.TIMING = {M1Anticipation = 5, HeavyAnticipation = 12, Smear = 1, M1Hold = 4, FinisherHold = 8, M1Recovery = 8, HeavyRecovery = 18}
Shared.clips = clips""").replace("\nreturn clips\n","\nreturn Shared\n")
open(os.path.join(here,"Shared.lua"),"w").write(body)
print("Shared",len(shared_clips),"clips")
