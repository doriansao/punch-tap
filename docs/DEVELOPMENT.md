# Local development

## Run and controls

Workspace: `G:\Programming\punch-tap`. Installed engine path:
`G:\Programming\Tools\Godot\Godot_v4.7.2-stable_mono_win64_console.exe`.

Open [project.godot](../project.godot) and press F5, or use [play.ps1](../tools/play.ps1).

Mobile: joystick up + punch targets head; neutral targets body; down guards; sides dodge. Separate left/right punch and special buttons. Keyboard: J/K punch, W high, S guard, A/D dodge, Space special, Enter start/resume, Escape pause. Get-up: tap punches.

Controller: left stick/D-pad moves/aims. West (X/Square) or LB/L1 punches left; south (A/Cross) or RB/R1 punches right; north (Y/Triangle) special; east (B/Circle) guards. Up aims high. Start/Options starts/pauses; south confirms menus. Disconnect pauses; deadzone 0.30.

## Checks

PowerShell, from workspace:

```powershell
$godotExe = 'G:\Programming\Tools\Godot\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godotExe --headless --path . --check-only --script res://tests/ui_test.gd
& $godotExe --headless --path . --script res://tests/ui_test.gd *> research/evidence/ui_vm_test.log
Get-Content research/evidence/ui_vm_test.log -Tail 30
python tools/check_docs.py
```

Use bounded test timeouts. Import new textures before rendering.

On a fresh clone, create `research/evidence/` for logs. Emulator captures and research binaries are intentionally absent; fixture-based routine tests need those local inputs. Research scripts retain workstation-specific paths and require configuration. Run documentation checks and applicable game tests locally before pushing; do not add hosted CI without an explicit user request.

Run `python tools/validate_local.py` for the local suite; add `--evidence` for captured-call checks. `--godot PATH` overrides the installed executable. Logs remain under ignored research evidence.

Choose tests by changed boundary:

| Change | Test scripts under `tests/` |
| --- | --- |
| Live integration/controls/entrance focus | `ui_test.gd`, `controller_input_test.gd`, `entrance_flow_test.gd` |
| Contacts, scheduling and resources | `contact_vm_test.gd`, `fight_control_test.gd` |
| Coupled actor progression | `animation_machine_test.gd` |
| KO/TKO integration (no ROM needed) | `knockdown_flow_test.gd` |
| Defense and visible warning cues | `defense_fight_parity_test.gd`, `attack_cue_test.gd` |
| Successful player get-up evidence | `getup_fight_parity_test.gd` |
| Body blocks, fatigue and player count-ten KO | `body_fight_parity_test.gd` |
| Incoming damage/presentation timing | `impact_presentation_test.gd` |
| Referee body/speech | `referee_presentation_test.gd`, `referee_speech_test.gd` |
| KO/coordinator and finish handshake evidence | `knockdown_entry_test.gd`, `presentation_gate_test.gd` |
| Animation interpreters | `player_vm_test.gd`, `opponent_step_test.gd`, `opponent_vm_test.gd` |
| Composition/striking-hand registration | `opponent_compositor_test.gd`, `punch_registration_test.gd` |
| Input/get-up | `presentation_controls_test.gd` |
| Guard AI/RNG | `opponent_guard_ai_test.gd`, `animation_rng_test.gd` |
| Title, opening, cadence, full-rate motion | [animation audit](ANIMATION_AUDIT.md); `motion_audit_capture.gd -- full --reuse` (rendering required) |

Inspect test preloads; some target the legacy model. `live_bout_capture.gd` renders a natural-input bout; `animation_comparison.gd` renders replay evidence. Their scopes are different.

## Godot MCP

Project plugin: `addons/godot_mcp`; tools: [start](../tools/start-godot-mcp.ps1), [stop](../tools/stop-godot-mcp.ps1), and `tools/gdmcp/gdmcp.exe --json doctor`.

Configured endpoint: `http://127.0.0.1:9080/mcp`, Codex server `punch-tap-godot`. Preserve the local loopback-only server patch. Check current connection rather than assuming a historical test still applies. Avoid two editors competing for the port. Preserve pinned plugin provenance in [lock file](../tools/godot-mcp-lock.json).

Android/iOS packaging, signing and physical-device tests are not complete. Audit editor tooling/runtime probes before release export.
