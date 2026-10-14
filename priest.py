import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def state(): return L('return tostring(workspace:GetAttribute("RoundState"))',"Server")
def shot(cid):
    r=L('local c=workspace.CurrentCamera.CFrame local p=c.Position local l=p+c.LookVector*20 return string.format("%f,%f,%f,%f,%f,%f",p.X,p.Y,p.Z,l.X,l.Y,l.Z)')
    v=[float(x) for x in r.strip().split(",")]
    print(cid, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":cid}), flush=True)
print(call("start_stop_play",{"is_start":True}))
t0=time.time()
while time.time()-t0<60 and state()!="Intro": time.sleep(0.3)
ti=time.time()
for t,n in [(19,"v2b_intro_03_priest"),(30,"v2b_intro_04_zenos_guards"),(34,"v2b_intro_05_zeno"),(37,"v2b_intro_06_future_zeno")]:
    while time.time()-ti<t: time.sleep(0.2)
    shot(n)
print(call("get_console_output",{})[-800:])
print(call("start_stop_play",{"is_start":False}))
print("DONE")
p.terminate()
