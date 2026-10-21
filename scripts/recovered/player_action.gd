extends RefCounted
## Measured player-action slice, NOT a complete combat port.
## Trace provenance: tests/fixtures/player_actions.json and research/REPORT.txt.
## Durations apply to the tested opening, 3-frame input pulse, normal stamina.
## Keep collision, opponent reactions and rendering outside this component.
signal contact(kind: int)
const PROFILES = {
 "left_body": {"id": 9, "frames": 34, "contact_at": 11, "contact": 1},
 "right_body": {"id": 10, "frames": 32, "contact_at": 9, "contact": 1},
 "left_head": {"id": 11, "frames": 39, "contact_at": 10, "contact": 3},
 "right_head": {"id": 12, "frames": 39, "contact_at": 10, "contact": 3},
 "dodge_left": {"id": 5, "frames": 34, "contact_at": -1, "contact": 0},
 "dodge_right": {"id": 3, "frames": 35, "contact_at": -1, "contact": 0},
 "down": {"id": 7, "frames": 15, "contact_at": -1, "contact": 0},
}
var state := 1
var contact_code := 0
var age := 0
var profile: Dictionary = {}
var held: Dictionary = {}

func reset() -> void:
 state = 1
 contact_code = 0
 age = 0
 profile = {}
 held.clear()

func press(action: String) -> bool:
 # Edge-triggered input: holding a punch must not schedule repeat attacks.
 if held.get(action, false):
  return false
 held[action] = true
 if state != 1 or not PROFILES.has(action):
  return false
 profile = PROFILES[action]
 age = 0
 state = profile.id
 contact_code = 0
 return true

func release(action: String) -> void:
 held.erase(action)

func advance_frame() -> void:
 contact_code = 0
 if profile.is_empty():
  return
 age += 1
 if age == profile.contact_at:
  contact_code = profile.contact
  contact.emit(contact_code)
 if age == profile.frames:
  state = 129 # Observed one-frame request to reinitialize the ready animation.
 elif age > profile.frames:
  state = 1
  profile = {}
