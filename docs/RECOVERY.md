# Reverse-engineering evidence

## Source and tools

- Local ROM: `G:\Programming\punch-out-ai\rom\punch-out.nes`.
- Recorded SHA-256: `60ef51f55f6addb7a1893f816aad75ee3e146dd646958a865d3bece5b429b600`.
- iNES header + 128 KiB PRG + 128 KiB CHR, mapper 9/MMC2, NTSC.
- Local Mesen runner: `research/tools/mesen/Mesen.exe`; Python tools use py65, Pillow and NumPy.
- [Disassembler](../research/scripts/disasm_range.py): `python research/scripts/disasm_range.py 7 83EB 843E`.

## Evidence levels

1. **Observed:** emulator captures and actual routine entry/exit state comparisons.
2. **Source-derived:** disassembly/offline execution; synthetic states may be unreachable.
3. **Original-art estimate:** presentation registration for anatomy not recoverable from visible source pixels. Must be labeled.
4. **Integration:** matched input through the complete live fight. Routine-level parity does not imply whole-bout parity.

Routine proofs: 13,953 player/opponent/input/get-up calls; 14,110 compositor calls; 12,251 guard and 2,048 RNG offline cases.

Visible ROM reconstruction reported 11,244 exact player PPU frames and 12,219 exact opponent OAM frames. Replacement art is not pixel-identical. Local reports: `research/evidence/animation/ppu_pose_validation.json` and `oam_pose_validation.json`.

## Pipeline map

Under `research/scripts/`:

1. `measure_animation.py`: capture measurements across visual audit, normal/right knockdowns, player get-up and long idle.
2. `recover_clipped_extents.py`: hidden-extent matching and explicitly labeled art estimates.
3. `validate_ppu_composition.py`, `validate_oam_composition.py`: validate source reconstruction.
4. `build_opponent_visual_catalog.py`, `refine_actor_bounds.py`: identify body shapes and separate particles.
5. `map_recovered_art.py`: assign original pose IDs/flips.
6. `export_animation_geometry.py`, `export_animation_tracks.py`, `export_compositor_transitions.py`: production numeric data and comparison fixtures.
7. `export_missing_player_geometry.py`, `export_fight_start.py`: decoded unobserved poses and first-controllable state.
8. `register_cartoon_art.py`: current cartoon atlas region/flip metadata. The older registration exporter is obsolete.

Do not run obsolete `map_displayed_poses.py` after PPU recovery; it can overwrite corrected pose selection.

## Fight-routine and integration evidence

`contact_vm_test.gd`: 6,983 calls/58 contacts, zero mismatches excluding stack. `fight_control_test.gd`: eight clock/scheduler/resource routines, 37,824 calls, zero mismatches. `recover_contact_program.py` owns export.

`capture_full_fight.lua` captures `$A669..$A6C9` through terminal `$00=252`. `full_fight_parity_test.gd` runs the production adapter continuously from one seed and stable raw button samples: 4,959 frames/48 contacts match 143 fields through three knockdowns/TKO. `controller_poll.gd` recovers `$AFBD..$B020`; serial hardware, first entrance and full PPU parity are excluded. Report: `research/evidence/animation/full_fight_validation.json`.

`export_referee_presentation.py` exports 29 numeric descriptors from bank-11 `$8280` high-picture commands. Player VM drives walking/counts; speech preserves bodies. `referee_presentation_test.gd` matches 4,959 frames/146 body transitions and count visibility against captured RAM/decoded geometry. Speech test matches 8,094 frames: 153 bubble, 154..163 digits, 166 Fight, 168 KO, 169 TKO; 150/151 erase bubbles. 172 passes 70 isolated ROM-executed ticks.

Presentation tests check delayed incoming effects and windup cues. `defense_fight_parity_test.gd`: 2,183 frames/143 fields, two guards/four slips, zero mismatches.

## Known interpretation traps

`body_fight_parity_test.gd` matches 3,135 consecutive frames/29 contacts/143 fields through heart exhaustion and player count-ten KO. `capture_body_fight.lua` supplies stable raw inputs; no combat reseeding. `$83EB` resets `$BC=1` at knockdown even with zero hearts; deriving it from HUD hearts caused post-knockdown divergence. Adapter preserves it. Body-counter parity covers 3,886 frames/148 fields, four body hits and three state-22 attacks; [animation audit](ANIMATION_AUDIT.md) owns visual/palette evidence. `getup_finish_parity_test.gd` matches 4,527 frames/44 contacts/143 fields through two returns and third-knockdown TKO.

Round-return tests match 3,862 frames and 134 setup fields; [audit](ANIMATION_AUDIT.md). KO helpers pass 1,536 cases/4,684 calls. `$B65A..$B665` resets `$51=128`; finish scripts signal outcomes through `$00`. Export: `recover_knockdown_entry.py`.

- Poses 58 and 64..67 are text/clear operations, not visible boxer bodies.
- Get-up poses 68..71 have no complete observed hidden-body counterpart; their 61-pixel art extent is authored.
- Composition is stateful; invalid offline combinations do not establish reachable poses.
- Older clip comparison uses captured-track overrides and stale registration. Full-fight comparison uses the live adapter.
- See [current state](CURRENT_STATE.md) for integration limits.
