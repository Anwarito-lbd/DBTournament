import json,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
S="stylized anime fighting-game character, cel-shaded look, original design, "
P={"u7_frieza":(S+"full body standing A-pose, slender humanoid alien emperor, smooth white armor-like skin with glossy purple dome on head and purple chest and shoulder plates, long thin tail, red eyes",(4,6,3)),
"npc_shenron":("stylized anime giant serpentine eastern dragon, shining golden yellow scales, long coiling body, glowing red eyes, large antler horns, long whiskers, four clawed legs, original design",(40,30,40))}
for k,(t,s) in P.items():
    r=None
    for attempt in range(4):
        r=call("generate_mesh",{"textPrompt":t,"size":{"x":s[0],"y":s[1],"z":s[2]},"maxTriangles":20000,"segmentation":"none"})
        print(k,attempt,str(r)[:200],flush=True)
        if "Too Many" not in str(r) and "error" not in str(r).lower(): break
        time.sleep(60)
p.terminate()
