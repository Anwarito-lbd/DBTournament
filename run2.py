import subprocess,sys
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":'for _,id in {"u7_goku","u7_vegeta","u7_frieza"} do local s=game.ReplicatedStorage.CharacterModels[id]:FindFirstChild("Segments") if s then s:SetAttribute("FacingYaw",180) end end return "yaw set"',"datamodel_type":"Edit"}))
p.terminate()
subprocess.run([sys.executable,"install.py","AnimeStyle","AvatarSlots"])
subprocess.run([sys.executable,"anime_shots.py","after"])
subprocess.run([sys.executable,"priest.py"])
print("ALLDONE",flush=True)
