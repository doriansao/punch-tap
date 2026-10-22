# Animation comparison

Verified 2026-10-22. Scope: recorded first-opponent sequences and one isolated referee routine; not game-wide parity.

## Corrections

[Ring placement preview](../research/evidence/ring_projection/index.html): 97 sampled before/after pairs; 79 distant/fallen frame bounds pass [test](../tests/ring_projection_test.gd). Authored depth projection keeps the corner entrance onscreen, grounds the prone torso and adds floor shadows. Combat-depth registration stays unchanged. The full-rate viewer below predates this projection correction.

- Rising/extended punches retain laterality. Turned special follow-through uses recovered glove alignment.
- Mirrored recoil/fall families share consistent art. Victory 85/86 use raised arms, with corrected head proportions.
- Fight startup primes the display queue from its seed. Source timings/contact rules remain unchanged.
- Post-bell clock uploads now acknowledge `$030A` through `$A61A/$C0E0`. `$B530/$B63E` dispatch and `$BF7E/$A774` fade replace the immediate freeze. Fade opacity is authored; source thresholds and two eight-frame waits drive it.
- Referee 172 patches predecessor 165, retaining head/body/feet. The composed box is `[93,136,21,48]`; its standalone 10-pixel-wide fragment is not a complete body. Original art uses a stable registration anchor, shared body height and foot markers. [New referee strip](../assets/cartoon/production/referee_arm_loop_v1.png) ([exact prompt](../assets/cartoon/production/referee_arm_loop_v1.prompt.txt), built-in imagegen) avoids body turns/two-arm substitutions; native right-facing head remains a proposal because imagegen blocked its correction.

## Local comparisons

[Motion viewer](../research/evidence/motion_audit/index.html): **16 clips / 5,269 consecutive image pairs**, with frame/pose stepping and preloading. Covers head/body punches, state-22 attack, special, slips, opponent fall/count/return, both player get-ups, third knockdown/TKO, victory, bell/fade and second-round return. Godot uses one seed and raw inputs.

[Referee viewer](../research/evidence/referee_partial/index.html): **70 isolated ROM-executed/Godot pairs**. Original bank-11 `$8319` executes the `$9E13` loop; four arm-lowering transitions match interpreter state. This loop was not naturally reached in these fights. [Exporter](../research/scripts/recover_referee_partial.py), [test](../tests/referee_partial_test.gd).

- Body-counter parity: **3,886 frames / 148 fields**, zero mismatches through post-bell routing. [Fade check](../research/scripts/check_post_bell_presentation.py) independently matches 134 clock screenshots and 46 end-frame RAM samples, including exit from fight routing.
- Round return: [adapter test](../tests/round2_parity_test.gd) matches 3,862 frames/143 fields/26 contacts; [setup test](../tests/round_return_setup_test.gd) matches 134 fields and runs 600 production ticks. FIGHT displays at source frames 7019..7041. Source visibility acknowledgement is preserved; blanking uses authored black.
- Extended get-up parity: **4,527 frames / 143 fields**, zero mismatches through two returns and third-knockdown TKO; [test](../tests/getup_finish_parity_test.gd).
- [Pixel check](../research/scripts/check_displayed_motion.py): 4,301 exact colour masks; twelve one/two-pixel foreground-occluded differences. All 4,295 unobscured silhouettes and 4,293 unobscured landmarks match. Global fade excludes 41 samples and has its separate check.
- [Palette check](../research/scripts/check_palette_presentation.py) covers the attack pulse; original coral tint is authored.

## Get-up geometry and art

Decoded commands 68..77 all end at tile row 29 (screen y=239). Their visible heights are 14, 18, 26, 34, 38, 42, 46, 50, 54 and 58 pixels. Commands 68..71 contain unique visible prefixes, not recoverable complete off-screen bodies. The 61-pixel replacement-art extent is explicitly authored; cropping preserves the recovered visible region. No invisible anatomy is claimed as ROM evidence.

[Mapper](../research/scripts/map_recovered_art.py), [registrar](../research/scripts/register_cartoon_art.py) and [family test](../tests/pose_family_registration_test.gd) own assignments/alignment. New recoil/fall, turned-special and victory-v2 PNGs have adjacent exact prompts and generation provenance; integration awaits user review.

ROM pose holds remain intact. Corner UI/healing/RNG choices and first-entrance override removal remain outside these checks. Older galleries retain earlier art. See [current state](CURRENT_STATE.md).
