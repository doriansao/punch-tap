extends SceneTree
const Action = preload("res://scripts/recovered/player_action.gd")
const Contact = preload("res://scripts/recovered/head_contact.gd")
func _initialize() -> void:
 var cases = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/player_actions.json"))
 var checks := 0
 for name in cases:
  var data: Dictionary = cases[name]
  var model = Action.new()
  var action: String = "left_body" if name == "hold_left" else name
  for frame in range(data.state.size()):
   if frame == int(data.accepted_sample):
    assert(model.press(action), name + " rejected initial action")
   else:
    model.advance_frame()
   if frame > int(data.accepted_sample) and frame < int(data.accepted_sample) + 120 and name == "hold_left":
    assert(not model.press(action), "Held punch repeated")
   elif frame == int(data.accepted_sample) + 3:
    model.release(action)
   assert(model.state == int(data.state[frame]), "%s state mismatch at sample %d: %d vs %d" % [name, frame, model.state, int(data.state[frame])])
   assert(model.contact_code == int(data.contact[frame]), "%s contact mismatch at %d" % [name, frame])
   checks += 2
 print("RECOVERED_ACTIONS_PASS: %d frame comparisons across %d ROM experiments" % [checks, cases.size()])
 var contacts = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/head_contacts.json"))
 for row in contacts:
  assert(Contact.resolve_confirmed_contact(int(row.hp), row.knockout_window, int(row.ordinary_damage)) == int(row.expected), "Head-contact mismatch at ROM frame %d" % int(row.frame))
 print("RECOVERED_CONTACTS_PASS: %d observed contacts, including the instant knockout branch" % contacts.size())
 quit(0)
