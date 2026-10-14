import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
S="stylized anime fighting-game character, cel-shaded look, original design, "
P={
"npc_zeno_guard":(S+"tall imposing armored royal guard, full body standing, purple and white plate armor, tall helmet, pale face, stoic, arms at sides",(3,8,2)),
"npc_shenron":("stylized anime giant serpentine eastern dragon, shining golden yellow scales, long coiling body, glowing red eyes, large antler horns, long whiskers, four clawed legs, original design",(40,30,40)),
"super_dragon_ball":("giant glossy golden-orange crystal sphere with red stars inside, magical glowing orb",(6,6,6)),
}
J=dict(goku="e7f85853-d520-4a5b-8753-f2f43ba489b8",vegeta="5a531457-f7e1-4e12-bbad-5d9047378985",frieza="a5d035d1-71c7-44f8-b055-711d4a074d77",zeno="f4588b24-fde0-4286-9119-34376db2f820",priest="c8ec6268-7cae-4d86-86db-01fca5d57bd7",shenron_green="3da557cf-3c69-4fa8-831b-6d38c0eab958")
for k,(t,s) in P.items():
    r=call("generate_mesh",{"textPrompt":t,"size":{"x":s[0],"y":s[1],"z":s[2]},"maxTriangles":20000,"segmentation":"none","async":True})
    print(k,r,flush=True); J[k]=json.loads(r)["jobId"] if r.strip().startswith("{") else None
for k,j in J.items():
    if j: print(k,"=>",str(call("wait_job_finished",{"jobId":j,"timeout":700}))[:500],flush=True)
print(call("execute_luau",{"code":'local o={} for _,c in workspace:GetChildren() do if c:IsA("MeshPart") or (c:IsA("Model") and c:FindFirstChildWhichIsA("MeshPart",true)) then local sz=c:IsA("Model") and c:GetExtentsSize() or c.Size table.insert(o,c:GetFullName().." | "..c.ClassName.." | "..tostring(sz).." | "..tostring(c:GetPivot().Position)) end end return table.concat(o,"\\n")'}))
p.terminate()
