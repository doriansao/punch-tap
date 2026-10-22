# Approved art direction

User decisions recorded: 2026-10-21.

## Authoritative references

- [Approved two-character concept](../assets/cartoon/approved_concept.png): size contrast, Nico identity, bold cartoon style and comic hit reactions.
- [Approved Teo proportions v2](../assets/cartoon/teo_proportion_reference_v2.png): authoritative Teo front/rear anatomy and glove size. User approved this revision after requesting slightly smaller gloves.
- [Teo edit prompt/provenance](../assets/cartoon/teo_proportion_reference_v2.txt).

## Locked decisions

- Teo Cruz: very small compact adult cartoon boxer; large tousled dark head, short torso and stubby legs, oversized white boots, orange chevron top, charcoal shorts, mint gloves. Gloves remain oversized, at the revised reference size.
- Nico “Rivet” Reyes: much larger male opponent; huge barrel-shaped torso, short legs, square jaw, dark swept-up hair, orange gloves, teal trunks. Normal fighting view is directly front-facing.
- Gameplay shows Teo from behind and Nico facing him/the camera. Preserve recovered turns and falls where the actual sequence requires them.
- Bold outlines, simple cel shading, exaggerated silhouettes and funny squashed/stretched hit reactions. Avoid realistic muscle anatomy and elongated limbs.
- Original male characters. No Nintendo character graphics or copied faces/outfits in production.

## Production rules

Use approved references for appearance. Old realistic atlases are not anatomy/style references. They caused rejected longer bodies and smaller gloves.

Recover pose intent, hand laterality and orientation from evidence; map original poses to those IDs. Keep recovered sequence order, frame durations, motion offsets and contact frames. Concept exaggeration does not authorize new animation timing.

Check idle, punches, dodge, reaction and knockdown together in Godot. Dodge art 10/11 requires horizontal correction to lean outward. Ensure Teo stays small relative to Nico, gloves align with contacts, frame pivots do not jump, and off-screen bodies crop instead of shrinking.

## Asset status

`assets/cartoon/teo_rear.png` and the `teo_recovered_*` sheets in that directory are **rejected intermediate proportions**, not approved final sprites. Do not use them as identity references.

Generated ring, icon controls and empty bar frames are in `assets/cartoon/interface/`; Godot supplies live fills. These are integrated proposals, not approved designs.

Logo, punches, recoil/fall, special, victory and referee arm-loop v1 are integrated proposals. [Animation audit](ANIMATION_AUDIT.md) records corrections. Shared body height stabilizes arm poses. Native right-facing referee art remains a proposal; imagegen blocked its facing correction.  Prompts and `generation_manifest.json` record provenance.

`register_cartoon_art.py` measures alpha/glove landmarks and direction; connected-component spans prevent neighbouring-pose bleed. `referee_v1.png` derives from the original [referee concept](../assets/cartoon/referee_concept_v1.png), with adjacent prompt/provenance. Body/count commands drive movement; cartoon pose mapping and scale are authored. `nico_body_block_v1.png` supplies composition `bd7da4410430e979` only, including its idle reuse.
