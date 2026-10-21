extends RefCounted
## $85E9-$86A8, bank 7: frame/controller bit permutations plus accumulator.
static func permute(value: int, positions: Array) -> int:
 var result := 0
 for bit in 8: result |= ((value >> bit)&1) << int(positions[bit])
 return result
static func advance(frame_counter: int, buttons: int, accumulator: int) -> Vector2i:
 var next_acc := (accumulator + permute(buttons,[0,7,1,5,2,6,3,4]))&255
 var value := (permute(frame_counter,[7,0,6,1,5,2,4,3]) + permute(next_acc,[0,2,4,6,1,3,5,7]))&255
 return Vector2i(value,next_acc)
