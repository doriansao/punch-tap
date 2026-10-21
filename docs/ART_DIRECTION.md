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

Use approved references for appearance. Old realistic atlases are not anatomy/style references. They previously pulled generation toward longer bodies and smaller gloves, which the user rejected.

Recover pose intent, hand laterality and orientation from evidence; map original poses to those IDs. Keep recovered sequence order, frame durations, motion offsets and contact frames. Concept exaggeration does not authorize new animation timing.

Check idle, punches, dodge, reaction and knockdown together in Godot. Ensure Teo stays small relative to Nico, gloves align with contacts, frame pivots do not jump, and off-screen bodies crop instead of shrinking.

## Asset status

`assets/cartoon/teo_rear.png` and the `teo_recovered_*` sheets in that directory are **rejected intermediate proportions**, not approved final sprites. They have not replaced the active runtime registration. Do not use them as the next generation's identity reference.

The approved v2 PNG is a model sheet, not a usable atlas. Full sprite replacement and integration remain unfinished. Record future generation prompts and source references beside their deliverables; keep previews separate from runtime assets until validated.
