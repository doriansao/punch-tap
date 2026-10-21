# Current state

Handoff updated: 2026-10-21. Source and historical evidence reconciled; publication checks below are newly run. Full-bout integration was not rerun.

## Repository and publication checks

Public repository: https://github.com/doriansao/punch-tap (`main`). Initial publication excludes ROMs, research evidence, local tools, secrets and caches. A clean staged-file copy passed documentation checks, Godot startup and `animation_machine_test.gd`. Editor import exited successfully with an existing-editor MCP port collision and resource-cleanup warning; startup and machine test exited cleanly. The known full-bout failure below remains unresolved.

## Objective and constraints

Finish a first fight with actual recovered animation logic, timings, movement, and contact behavior, using original cartoon characters. Keep mobile joystick, left/right punches, and special. Preserve small rear-view Teo against oversized front-facing Nico. Do not label incomplete work a completed port.

## Implemented

- [Main](../scripts/main.gd) loads `fight_model_vm.gd`; live animation uses the coupled recovered interpreters. Captured clips are explicit comparison overrides, not the normal live selector.
- Player/opponent animation, opponent composition, player input/get-up, guard AI, and NES animation RNG implementations exist under `scripts/recovered/`. See [architecture](ARCHITECTURE.md) and [evidence limits](RECOVERY.md).
- Existing runtime art registration has 40 frames per actor. These older assets do not satisfy the newly approved cartoon direction.
- Teo's revised character reference is approved, including the slightly smaller gloves. See [art direction](ART_DIRECTION.md). New sprite production/integration is unfinished.

## Blocking issues

1. **Live bout stalls during a later opponent knockdown.** Existing local `research/evidence/ui_vm_test.log` (not distributed) reports 20 passes, 1 failure after 18,000 frames: `opponent_down`, player VM state 1, opponent state 13, count 0. Do not reuse earlier successful prototype-bout claims for this adapter.
2. Collision/KD integration in [fight_model_vm.gd](../scripts/fight_model_vm.gd) still mixes recovered VM state with legacy combat helpers. Source bank 7 `$8404` clears combo variables `$4A..$4C`, pauses clock, and sets KO state. Missing helper semantics are a **hypothesis** for the stall, not a demonstrated fix. Investigate the caller and combo branch before changing state transitions.
3. Whole-bout matched-input parity is unproven. Legacy scheduling/get-up selection remains; a tested animation RNG helper does not establish full RNG parity.
4. Comparison HTML/screenshots predate the latest live adapter and approved art. They are replay evidence, not proof of a current successful bout.
5. Unique player get-up poses 68..71 use an explicit original-art height estimate for hidden extents. Some research reports still overstate off-screen recovery; correct those classifications.

## Next actions

1. Use approved Teo reference only for character proportions; regenerate rejected atlas art without importing realistic anatomy. Preserve recovered pose identity, laterality, timings, movement, and crop/alignment metadata.
2. Recover/validate KO helper and collision state handling; get the active UI full-bout test passing without forcing arbitrary animation states.
3. Check render alignment, off-screen clipping, and the Teo/Nico size contrast in actual Godot captures. Rebuild the comparison with clear replay/live labels.
4. Update evidence and this handoff after verification. Android/iOS export and physical-device QA remain future work.

## Resume efficiently

For art: read ART_DIRECTION and renderer registration code. For the KO bug: read `fight_model_vm.gd`, `animation_machine.gd`, `actor_coordinator.gd`, and the UI log; disassemble bank 7 `$83EB..$843D`. Do not reread all capture binaries or regenerate art merely to regain context.
