import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
S="stylized anime fighting-game character, cel-shaded look, full body standing A-pose, original design, "
P={
"u7_goku":(S+"muscular young martial artist, spiky black hair, orange gi with blue undershirt, blue wristbands and sash, blue boots",(4,6,2)),
"u7_vegeta":(S+"proud muscular warrior prince, tall flame-shaped black hair, navy blue bodysuit, white armored chestplate with yellow shoulder pads, white gloves and boots",(4,6,2)),
"u7_frieza":(S+"slender alien tyrant, white and purple glossy carapace, smooth domed purple head, long tail, red eyes",(4,6,3)),
"npc_zeno":(S+"tiny cute childlike alien deity, round blue head, large eyes, magenta and yellow royal robe with rounded collar",(2.5,3.5,2)),
"npc_grand_priest":(S+"tall serene attendant, light blue skin, tall white hair, black and blue long robe with white collar, holding staff, blue halo ring around neck",(3,7,2)),
"npc_shenron":(S+"giant serpentine eastern green dragon, long coiling scaled body, red eyes, golden horns and whiskers, four clawed legs",(30,30,30)),
}
jobs={}
for k,(t,s) in P.items():
    r=call("generate_mesh",{"textPrompt":t,"size":{"x":s[0],"y":s[1],"z":s[2]},"maxTriangles":20000,"segmentation":"none","async":True})
    print(k,str(r)[:300],flush=True); jobs[k]=r
for k,r in jobs.items():
    import re; m=re.search(r'[0-9a-f]{8}-[0-9a-f-]{27}|jobId["\x27: ]+([\w-]+)',str(r))
    jid=m.group(1) or m.group(0) if m else None
    print(k,"WAIT",jid, str(call("wait_job_finished",{"jobId":jid,"timeout":600}))[:600] if jid else "nojob",flush=True)
print(call("execute_luau",{"code":'local o={} for _,c in workspace:GetChildren() do if c:IsA("MeshPart") or (c:IsA("Model") and c:FindFirstChildWhichIsA("MeshPart",true)) then table.insert(o,c:GetFullName().." "..c.ClassName.." "..tostring(c:GetExtentsSize and c:GetExtentsSize() or c.Size)) end end return table.concat(o,"\\n")'}))
p.terminate()
