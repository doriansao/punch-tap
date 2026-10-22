extends RefCounted
## Godot standardized joypad positions; one active pad until reset/disconnect.
var device := -1
var buttons:Dictionary={}
var axes:=Vector2.ZERO
func reset() -> void:
 device=-1;buttons.clear();axes=Vector2.ZERO
func feed(event:InputEvent) -> bool:
 if event is InputEventJoypadMotion:
  if event.axis not in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:return false
  if device<0 and absf(event.axis_value)<0.30:return false
 elif event is InputEventJoypadButton:
  if device<0 and not event.pressed:return false
 else:return false
 if device>=0 and event.device!=device:return false
 device=event.device
 if event is InputEventJoypadButton:buttons[event.button_index]=event.pressed
 elif event.axis==JOY_AXIS_LEFT_X:axes.x=event.axis_value
 else:axes.y=event.axis_value
 return true
func down(button:int)->bool:return buttons.get(button,false)
func snapshot()->Dictionary:
 var direction:=Vector2(float(down(JOY_BUTTON_DPAD_RIGHT))-float(down(JOY_BUTTON_DPAD_LEFT)),float(down(JOY_BUTTON_DPAD_DOWN))-float(down(JOY_BUTTON_DPAD_UP)))
 if direction==Vector2.ZERO and axes.length()>0.30:direction=axes
 var horizontal:=absf(direction.x)>absf(direction.y)
 return {"left":down(JOY_BUTTON_X) or down(JOY_BUTTON_LEFT_SHOULDER),"right":down(JOY_BUTTON_A) or down(JOY_BUTTON_RIGHT_SHOULDER),"special":down(JOY_BUTTON_Y),"guard":down(JOY_BUTTON_B) or (not horizontal and direction.y>0),"high":not horizontal and direction.y<0,"dodge_left":horizontal and direction.x<0,"dodge_right":horizontal and direction.x>0}
