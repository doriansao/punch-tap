extends RefCounted
## A narrow recovered branch, not a general collision/damage resolver.
## Caller must already have selected the confirmed head-contact path.
## ROM PRG bank 7, $8335-$8343 checks $BA before ordinary damage.
static func resolve_confirmed_contact(hp: int, knockout_window: bool, ordinary_damage: int) -> int:
 if knockout_window:
  return 0
 return maxi(0, hp - ordinary_damage)
