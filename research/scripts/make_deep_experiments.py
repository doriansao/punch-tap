from pathlib import Path
base=Path('research/scripts/fight_policy_confirm.lua').read_text()
start=base.index(' if n>=2300 then');end=base.index(' emu.setInput(b,0)',start)
policies={
 'body_stars':''' if n>=2300 then local t=n-2300;if t%45<3 then
 if r(0x342)>0 then b.start=true else if math.floor(t/45)%2==0 then b.a=true else b.b=true end end end end
''',
 'normal_knockdowns':''' if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
''',
 'player_getup':''' if n>=4000 then if n%4==0 then b.a=true elseif n%4==2 then b.b=true end end
''',
 'head_stars':''' if n>=3050 then local t=n-3050;if t%45<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/45)%2==0 then b.a=true else b.b=true end end end end
'''
}
for name,policy in policies.items():
 s=base[:start]+policy+base[end:]
 s=s.replace("local case='fight_policy_confirm'",f"local case='{name}'").replace('n==7000','n==12000')
 s=s.replace('local addresses={','local addresses={0x341,0x343,0xBC,0xC0,0xC4,0x3CA,0x8F,')
 Path('research/scripts/'+name+'.lua').write_text(s)
