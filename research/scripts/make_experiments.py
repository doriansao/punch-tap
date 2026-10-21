from pathlib import Path
base=Path(__file__).parent
text=(base/'experiment.template.lua').read_text()
cases={'idle':('',3),'left_body':('b.a=true',3),'right_body':('b.b=true',3),'left_head':('b.a=true;b.up=true',3),'right_head':('b.b=true;b.up=true',3),'dodge_left':('b.left=true',3),'dodge_right':('b.right=true',3),'down':('b.down=true',3),'hold_left':('b.a=true',120)}
for name,(buttons,hold) in cases.items():
 (base/(name+'.lua')).write_text(text.replace('CASE',repr(name)).replace('HOLD',str(hold)).replace('BUTTONS',buttons))
