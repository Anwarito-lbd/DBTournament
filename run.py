# usage: python run.py tool args.json  (same as mcp.py but full output) OR python run.py luau file.lua
import json,sys,time
sys.argv=[sys.argv[0]]+sys.argv[1:]
exec(open("install.py",encoding="utf-8").read().split("T=r\"team\"")[0])
if sys.argv[1]=="list":
    for t in rpc("tools/list",{})["result"]["tools"]: print(t["name"],"|",json.dumps(t.get("inputSchema",{}).get("properties",{}))[:400])
elif sys.argv[1]=="luau": print(call("execute_luau",{"code":open(sys.argv[2],encoding="utf-8").read()}))
elif sys.argv[1]=="play":
    print(call("start_stop_play",{"is_start":True})); time.sleep(float(sys.argv[2]) if len(sys.argv)>2 else 15)
    print(call("get_console_output",{}))
    if len(sys.argv)>3:
        print(call("screen_capture",json.load(open(sys.argv[3]))))
    print(call("start_stop_play",{"is_start":False}))
else: print(call(sys.argv[1],json.load(open(sys.argv[2],encoding="utf-8"))))
p.terminate()
