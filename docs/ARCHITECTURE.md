# Architecture

Source inspected: 2026-10-21. Current runtime is GDScript; the installed Godot executable is the .NET distribution, but this is not a Rust or C# implementation.

## Runtime flow

`main.tscn -> main.gd -> fight_model_vm.gd -> animation_machine.gd -> recovered interpreters -> renderer`

| Component | Responsibility |
| --- | --- |
| [Project](../project.godot), [scene](../scenes/main.tscn) | 540 x 960 portrait canvas, Compatibility renderer, entry point |
| [main.gd](../scripts/main.gd) | Touch/keyboard controls, HUD, fight stepping, original sprite rendering |
| [fight_model_vm.gd](../scripts/fight_model_vm.gd) | Live adapter: input bits, shared state, contacts, knockdowns, model/UI state |
| [fight_model.gd](../scripts/fight_model.gd) | Legacy base still supplying combat, scoring, scheduling, round/get-up helpers |
| [animation_machine.gd](../scripts/recovered/animation_machine.gd) | Coupled actor state and presentation queue |
| [animation_timeline.gd](../scripts/recovered/animation_timeline.gd) | Live machine lookup; explicit captured-track override for comparisons |

## Recovered animation boundary

The machine owns a 2,048-entry integer array representing shared NES RAM values. Player and opponent interpreters exchange state through that array; they are not independent timed clips.

Tick order: guard AI; opponent interpreter and synchronous composition requests; final opponent composition; player input; player interpreter; get-up handler; presentation; actor coordinator. A two-frame presentation queue models observed display delay. Unknown recovered geometry/commands produce errors instead of invented fallback motion.

`player_animation_vm.gd` and `opponent_animation_vm.gd` interpret semantic programs. `opponent_compositor.gd` tracks persistent composition state. `player_input.gd`, `player_getup.gd`, `opponent_guard_ai.gd`, and `actor_coordinator.gd` implement associated routines. `nes_animation_rng.gd` supplies the recovered RNG helper; legacy model randomness still exists.

## Production data

All paths below are under `assets/data/`:

- `*_animation_program.json`: extracted semantic animation commands.
- `animation_geometry.json`, `player_presentation.json`: numeric pose geometry, initial state and presentation descriptors.
- `opponent_composition.json`: body-shape identities, transitions, placement and original-art mapping.
- `pose_art_map.json`: recovered pose to original art frame/flip mapping.
- `art_registration.json`: texture path, image region and measured glove marker per original art frame.
- `animation_tracks.json`: sampled clips for comparison fixtures.

These files have different owners and regeneration scripts. Do not hand-edit generated tables without understanding their exporter. Large JSON is not session documentation.

## Rendering and art swaps

The renderer selects a registered art frame from the current recovered pose. `SOURCE_SCALE = 2.6` maps source coordinates into the portrait stage. It scales art uniformly by recovered full height, centers using `draw_box`, and applies `crop_y` for partial off-screen visibility. Effects are separate from boxer bounds.

Changing art must not change interpreter timing or movement. Different cartoon anatomy requires registration and visual reach/alignment checks; matching numeric motion alone does not prove the new glove reaches the intended contact point.

## Research boundary

`research/` contains ROM-derived captures, disassembly, exporters, reports and comparisons. Its `.gdignore` excludes it from normal Godot importing. The local ROM is outside this project. Release packaging must explicitly exclude research and audit the editor MCP plugin/runtime probe when export presets are added.

Current integration gaps belong in [current state](CURRENT_STATE.md), not duplicated here.
