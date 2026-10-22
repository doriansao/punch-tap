# Architecture

Inspected: 2026-10-22. GDScript runtime. `title_presentation.gd` draws menus. Start/Enter runs the unskippable entrance; focus loss pauses entrance/combat, preserving mode.

## Runtime flow

`main.tscn -> main.gd -> fight_model_vm.gd -> animation_machine.gd -> recovered interpreters -> renderer`

| Component | Responsibility |
| --- | --- |
| [Project](../project.godot), [scene](../scenes/main.tscn) | 540 x 960 portrait canvas, Compatibility renderer, entry point |
| [main.gd](../scripts/main.gd) | Touch/keyboard/controller controls, HUD, fight stepping, sprites |
| [fight_model_vm.gd](../scripts/fight_model_vm.gd) | Live adapter: input bits, shared state, contacts, knockdowns, model/UI state |
| [fight_model.gd](../scripts/fight_model.gd) | Compatibility UI/input state; damage/scheduling methods are superseded |
| [animation_machine.gd](../scripts/recovered/animation_machine.gd) | Coupled actor state and presentation queue |
| [animation_timeline.gd](../scripts/recovered/animation_timeline.gd) | Live machine lookup; explicit captured-track override for comparisons |

## Recovered animation boundary

[controller_input.gd](../scripts/controller_input.gd) normalizes joypads; `main.gd` routes edges through existing actions. Interpreters share 2,048 RAM integers.

Live tick order: advance frame counter; recovered clock/resource updates; clock events and schedule selection; guard AI; schedule execution; opponent interpreter and synchronous composition requests; final opponent composition; player input; player interpreter; presentation handshake; contact/combo/count resolution; get-up handler; presentation; actor coordinator. Actors use a primed two-frame queue; clock uploads latch next frame. Palette countdown `$C440` precedes queueing. Clock acknowledgement releases `$B63E`; `$BF7E/$A774` drive fade. `$AB58/$B5A9` initialize round return; `$AF73` gates visibility. Unknown commands stop.

`knockdown_entry.gd` applies the ROM's KO state changes. `presentation_gate.gd` supplies isolated fixtures. Live `presentation_control.gd` preserves HUD command timers/RNG; a two-slot NMI transfer budget can defer its updates.  Finish scripts write `$00` terminal values (KO/TKO, win/loss); `$BB` is actor coordination, not the bout-result signal.

`player_animation_vm.gd` and `opponent_animation_vm.gd` interpret semantic programs. `opponent_compositor.gd` tracks persistent composition state. `player_input.gd`, `player_getup.gd`, `opponent_guard_ai.gd`, and `actor_coordinator.gd` implement associated routines. `nes_animation_rng.gd` supplies the recovered RNG helper; active schedule/count choices use shared source RNG state.

`contact_vm.gd` executes decoded contact/count, clock, scheduler and resource operations with byte flags. Unknown operations stop. `fight_control_enabled` distinguishes live integration from isolated fixtures. RNG uses previous inputs; source owns delay `$581`. `controller_poll.gd` implements `$AFBD..$B020` stable-sample edge handling. Mobile tap pulses last two samples; serial hardware is excluded. `$BC` remains source-owned, including zero-heart knockdown recovery.

## Production data

Under `assets/data/`:

- `contact_program.json`: 1,591 decoded operations and 474 gameplay table values, exported by `recover_contact_program.py`.
- `*_animation_program.json`: extracted semantic animation commands.
- `animation_geometry.json`, `player_presentation.json`: numeric pose geometry, fixture/live initial states and presentation descriptors. Combat starts at captured frame 2017 (clock 0:01). `fight_entrance.gd` first runs live actor VMs using `entrance.json`; two entrance gates remain measured overrides; removal is untested.
- `opponent_composition.json`: body-shape identities, transitions, placement and original-art mapping.
- `pose_art_map.json`: recovered pose to original art frame/flip mapping.
- `art_registration.json`: texture path, image region, reviewed direction correction and measured glove marker per original art frame.
- `animation_tracks.json`: sampled clips for comparison fixtures.

`presentation_control.json` contains 121 semantic HUD control commands; `export_presentation_control.py` owns regeneration. No message text or tile data is exported.

## Rendering and art swaps

Recovered poses select original art. `SOURCE_SCALE = 2.6` preserves source motion. Nico’s upright poses use head/top anchors; fallen poses use authored floor pivots, shared across prone/kneeling/rising poses. Apron occlusion aligns to source y=240 (portrait y=649). Teo’s attack gloves align to recovered reach markers, without changing contact outcomes. Nico’s jab hand has a foreground polygon layer above Teo. VFX resolve after displayed poses commit; incoming flash, sound and sparks wait one frame for the strike pose.

`isolated_sprite.gd` caches textured component meshes from `art_registration.draw_spans`, excluding neighbouring poses without editing PNGs. `illustrated_interface.gd` draws ring/UI, bordered containers and live fills. `ringside_presentation.gd` owns cosmetic effects. Interface art/prompts live under `assets/cartoon/interface/`. `referee_presentation.gd` retains high-picture body/count updates in the display queue; numeric descriptors drive movement, with authored art mapping/scale. Jab audio follows displayed windup. Speech preserves Fight/count/KO/TKO cues. Partial 172 retains 165’s body; shared body-height/foot registration prevents arm-induced shrinking. Cloud geometry is authored.

## Research boundary

`research/` contains ROM-derived captures, disassembly, exporters, reports and comparisons. Its `.gdignore` excludes Godot importing. The ROM is external. Release packaging must explicitly exclude research and audit the editor MCP plugin/runtime probe when export presets are added.

Integration gaps: [current state](CURRENT_STATE.md).
