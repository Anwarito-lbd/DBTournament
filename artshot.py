import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":open(r"team\map\ArtPass.lua",encoding="utf-8").read()}))
for cid,cp,la in [("v11_art_wide",[0,620,330],[0,500,0]),("v11_art_ring",[60,512,110],[-30,500,-60]),("v11_art_zeno",[0,705,-430],[0,710,-520]),("v11_art_stands",[150,560,150],[380,545,40])]:
    print(cid,call("screen_capture",{"camera_position":cp,"look_at_position":la,"capture_id":cid}))
p.terminate()
