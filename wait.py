import json
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
J=dict(frieza="a5d035d1-71c7-44f8-b055-711d4a074d77",zeno="f4588b24-fde0-4286-9119-34376db2f820",priest="c8ec6268-7cae-4d86-86db-01fca5d57bd7",shenron_green="3da557cf-3c69-4fa8-831b-6d38c0eab958",guard="6c1631be-175f-4051-9118-c30bdb9fd706",shenron_gold="b4219d0b-7285-4370-b71a-200b610c5d43",ball="42157b95-16ae-44cf-8615-81c164668f57")
for k,j in J.items(): print(k,"=>",str(call("wait_job_finished",{"jobId":j,"timeout":700}))[:300],flush=True)
print(call("execute_luau",{"code":'local o={} for _,c in workspace:GetChildren() do if c:IsA("MeshPart") or (c:IsA("Model") and c:FindFirstChildWhichIsA("MeshPart",true)) then local sz=c:IsA("Model") and c:GetExtentsSize() or c.Size table.insert(o,c:GetFullName().." | "..c.ClassName.." | "..tostring(sz).." | "..tostring(c:GetPivot().Position)) end end return table.concat(o,"\\n")'}))
p.terminate()
