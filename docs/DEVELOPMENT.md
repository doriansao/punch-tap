# Local development

## Run and controls

Workspace: `G:\Programming\punch-tap`. Installed engine path:
`G:\Programming\Tools\Godot\Godot_v4.7.2-stable_mono_win64_console.exe`.

Open [project.godot](../project.godot) and press F5, or use [play.ps1](../tools/play.ps1).

Mobile: joystick up + punch targets head; neutral targets body; down guards; sides dodge. Separate left/right punch and special buttons. Keyboard: J/K punch, W high, S guard, A/D dodge, Space special, Enter start/resume, Escape pause. Get-up uses repeated punch taps after the cue.

## Checks

PowerShell, from workspace:

```powershell
$godotExe = 'G:\Programming\Tools\Godot\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godotExe --headless --path . --check-only --script res://tests/ui_test.gd
& $godotExe --headless --path . --script res://tests/ui_test.gd *> research/evidence/ui_vm_test.log
Get-Content research/evidence/ui_vm_test.log -Tail 30
python tools/check_docs.py
```

Use a bounded process timeout when running new tests; parse errors in SceneTree tests can leave a process running. Import new textures with a headless editor import before rendering them. Avoid unbounded terminal output.

On a fresh clone, create `research/evidence/` for logs. Emulator captures and research binaries are intentionally absent; fixture-based routine tests need those local inputs. Research scripts retain workstation-specific paths and require configuration. Run documentation checks and applicable game tests locally before pushing; do not add hosted CI without an explicit user request.

Choose tests by changed boundary:

| Change | Test scripts under `tests/` |
| --- | --- |
| Live integration/controls | `ui_test.gd` |
| Coupled actor progression | `animation_machine_test.gd` |
| Animation interpreters | `player_vm_test.gd`, `opponent_step_test.gd`, `opponent_vm_test.gd` |
| Composition | `opponent_compositor_test.gd` |
| Input/get-up | `presentation_controls_test.gd` |
| Guard AI/RNG | `opponent_guard_ai_test.gd`, `animation_rng_test.gd` |
| Art/alignment | `recovered_art_preview.gd`, `animation_comparison.gd` (rendering required) |

Inspect each test's preload before claiming active-model coverage. Some older combat tests load the legacy base. Art preview currently overwrites two opponent-down screenshots; fix filenames before relying on both samples.

## Godot MCP

Project plugin: `addons/godot_mcp`; tools: [start](../tools/start-godot-mcp.ps1), [stop](../tools/stop-godot-mcp.ps1), and `tools/gdmcp/gdmcp.exe --json doctor`.

Configured endpoint: `http://127.0.0.1:9080/mcp`, Codex server `punch-tap-godot`. Preserve the local loopback-only server patch. Check current connection rather than assuming a historical test still applies. Avoid two editors competing for the port. Preserve pinned plugin provenance in [lock file](../tools/godot-mcp-lock.json).

Android/iOS packaging, signing and physical-device tests are not complete. Audit editor tooling/runtime probes before release export.
