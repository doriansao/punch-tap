# Reverse-engineering evidence

This page indexes evidence and its limits; it does not replace raw captures. Historical validation counts below are prior recorded results, not tests rerun on 2026-10-21.

## Source and tools

- Local ROM: `G:\Programming\punch-out-ai\rom\punch-out.nes`.
- Recorded SHA-256: `60ef51f55f6addb7a1893f816aad75ee3e146dd646958a865d3bece5b429b600`.
- iNES header + 128 KiB PRG + 128 KiB CHR, mapper 9/MMC2, NTSC.
- Local Mesen runner: `research/tools/mesen/Mesen.exe`; Python tools use py65, Pillow and NumPy.
- [Disassembler](../research/scripts/disasm_range.py): `python research/scripts/disasm_range.py 7 83EB 843E`.

## Evidence levels

1. **Observed:** emulator captures and actual routine entry/exit state comparisons.
2. **Source-derived:** disassembly and offline execution against selected captured states. Not proof that every synthetic state is reachable.
3. **Original-art estimate:** presentation registration for anatomy not recoverable from visible source pixels. Must be labeled.
4. **Integration:** matched input through the complete live fight. Routine-level parity does not imply whole-bout parity.

Prior validation reported: player VM, opponent step, player input and player get-up each compared against 13,953 captured calls; opponent compositor against 14,110 calls. Guard AI used 12,251 offline oracle cases; RNG used 2,048. These have different evidence levels. Re-run the corresponding [tests](../tests) after relevant changes.

Visible ROM reconstruction reported 11,244 exact player PPU frames and 12,219 exact opponent OAM frames. This establishes source reconstruction, not pixel identity of original replacement art. Local reports: `research/evidence/animation/ppu_pose_validation.json` and `oam_pose_validation.json`. Evidence artifacts are not distributed in the public repository.

## Pipeline map

Under `research/scripts/`, in dependency order:

1. `measure_animation.py`: capture measurements across visual audit, normal/right knockdowns, player get-up and long idle.
2. `recover_clipped_extents.py`: hidden-extent matching and explicitly labeled art estimates.
3. `validate_ppu_composition.py`, `validate_oam_composition.py`: validate source reconstruction.
4. `build_opponent_visual_catalog.py`, `refine_actor_bounds.py`: identify body shapes and separate particles.
5. `map_recovered_art.py`: assign original pose IDs/flips.
6. `export_animation_geometry.py`, `export_animation_tracks.py`, `export_compositor_transitions.py`: production numeric data and comparison fixtures.
7. `register_recovered_art.py`: original atlas region metadata; current script assumes older sheets and must be adapted for new art.

Do not run obsolete `map_displayed_poses.py` after PPU recovery; it can overwrite corrected pose selection.

## Known interpretation traps

- Poses 58 and 64..67 are text/clear operations, not visible boxer bodies.
- Get-up poses 68..71 have no complete observed hidden-body counterpart; their 61-pixel art extent is an estimate.
- Compositor selector alone does not identify a body; composition is stateful. Offline invalid combinations are not evidence of missing reachable poses.
- Local `research/evidence/comparison/index.html` uses captured-track overrides and is stale relative to current art/live code. Rebuild and label before presenting it as current evidence; it is not distributed.
- See [current state](CURRENT_STATE.md) for the failing full-bout test; do not cite old prototype passes as active-adapter validation.
