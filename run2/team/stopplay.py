exec(open('install.py',encoding='utf-8').read().split('T=r"team"')[0])
print(call('start_stop_play',{'is_start':False}))
p.terminate()
