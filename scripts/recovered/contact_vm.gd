extends RefCounted
## Restricted decoded-routine executor for contact/combo/count selection.
## No ROM or opcode bytes are loaded. Unknown operations/reads fail explicitly.
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/contact_program.json"))
var m:=PackedInt32Array()
var error:=""
var a:=0
var x:=0
var y:=0
var carry:=0
var zero:=false
var negative:=false
func nz(v: int) -> int:
 v&=255;zero=v==0;negative=bool(v&128);return v
func read(address: int) -> int:
 if address<2048:return m[address]
 if data.tables.has(str(address)):return int(data.tables[str(address)])
 error="Unrecovered contact table %04X" % address;return 0
func write(address: int,v: int) -> void:
 if address<2048:m[address]=v&255
 elif address!=0xafff:error="Unsupported contact write %04X" % address
func step(entry: int=0x805d) -> void:
 error="";a=0;x=0;y=0;carry=0;zero=false;negative=false
 var pc:=entry
 var stack: Array[int]=[]
 for budget in 10000:
  if not error.is_empty():return
  if not data.operations.has(str(pc)):
   error="Unrecovered contact operation %04X" % pc;return
  var n: Dictionary=data.operations[str(pc)]
  var op: String=n.op
  var mode: String=n.mode
  var address:=int(n.arg)
  pc=int(n.next)
  match mode:
   "abx":address+=x
   "aby":address+=y
   "zpx":address=(address+x)&255
   "zpy":address=(address+y)&255
   "iny":address=read(address)+256*read((address+1)&255)+y
   "inx":address=read((address+x)&255)+256*read((address+x+1)&255)
  var value:=address if mode=="imm" else 0
  if op in ["LDA","LDX","LDY","AND","ORA","EOR","CMP","CPX","CPY","ADC","SBC","INC","DEC","ROR","ASL","LSR"] and mode not in ["imm","acc"]:value=read(address)
  if mode=="acc":value=a
  match op:
   "LDA":a=nz(value)
   "LDX":x=nz(value)
   "LDY":y=nz(value)
   "STA":write(address,a)
   "STX":write(address,x)
   "STY":write(address,y)
   "TAX":x=nz(a)
   "TXA":a=nz(x)
   "TAY":y=nz(a)
   "TYA":a=nz(y)
   "INX":x=nz(x+1)
   "DEX":x=nz(x-1)
   "INY":y=nz(y+1)
   "DEY":y=nz(y-1)
   "INC":write(address,nz(value+1))
   "DEC":write(address,nz(value-1))
   "AND":a=nz(a&value)
   "ORA":a=nz(a|value)
   "EOR":a=nz(a^value)
   "CLC":carry=0
   "SEC":carry=1
   "CMP","CPX","CPY":
    var left:=a if op=="CMP" else (x if op=="CPX" else y)
    carry=int(left>=value);nz(left-value)
   "ADC":
    var sum:=a+value+carry;carry=int(sum>255);a=nz(sum)
   "SBC":
    var diff:=a-value-(1-carry);carry=int(diff>=0);a=nz(diff)
   "ROR","ASL","LSR":
    var result: int
    if op=="ROR":result=(value>>1)|(carry<<7);carry=value&1
    elif op=="ASL":result=value<<1;carry=(value>>7)&1
    else:result=value>>1;carry=value&1
    result=nz(result)
    if mode=="acc":a=result
    else:write(address,result)
   "JSR":stack.append(pc);pc=address
   "DISPATCH":
    if a>=n.targets.size():error="Unrecovered scheduler dispatch %d" % a;return
    pc=int(n.targets[a])
    m[0x4c9]=y;carry=(a>>7)&1;a=pc&255
    m[0xee]=a;m[0xef]=pc>>8;nz(y)
   "RTS":
    if stack.is_empty():return
    pc=stack.pop_back()
   "JMP":pc=address
   "BEQ":
    if zero:pc=address
   "BNE":
    if not zero:pc=address
   "BMI":
    if negative:pc=address
   "BPL":
    if not negative:pc=address
   "BCS":
    if carry:pc=address
   "BCC":
    if not carry:pc=address
   _:error="Unsupported contact operation "+op;return
 error="Contact routine exceeded instruction budget"
