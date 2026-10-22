# Current state

Handoff updated: 2026-10-22. First opponent uses recovered fight routines. This is not a completed game-wide port; original-art integration awaits user review.

## Runtime and presentation

- Godot portrait 540 x 960. Live shared-state interpreters preserve recovered sequences, movement, contacts, scheduling, knockdowns and resources. Start runs the referee entrance; focus loss pauses it. Controller bindings: [development](DEVELOPMENT.md). Joypad event, UI and entrance tests pass; physical-controller testing is pending.
- Portrait mat projection now keeps corner entrances onscreen and grounds prone/kneeling Nico. [Preview](../research/evidence/ring_projection/index.html): 97 sampled renders; 79 distant/fallen bounds checks pass. Projection/shadows are authored; source state/timing is unchanged.
- Referee walks, speech clouds and count updates consume decoded commands. Fight/count/KO/TKO coverage passes. Partial picture 172 now composes over 165 and passes an isolated ROM-executed test; first-entrance gates remain measured overrides.
- Recoil/fall facing, raised-arm victory poses, special follow-through/glove alignment and two stale startup display frames are corrected. Source-translated poses share art; source-mirrored poses share mirrored art.
- Recovered palette countdown now drives the opponent warning pulse through the display queue. The coral tint itself is authored. No combat interpolation or invented timing was added.

## Validation and previews

- All 30 local Godot suites pass, including controller input, ring projection, UI, entrance and ROM parity checks. Atlas validation checks 82 component meshes. Logs: `research/evidence/local_validation/`. No hosted CI.
- Full-fight adapter: 4,959 consecutive ROM frames/48 contacts/143 fields, zero mismatches through three knockdowns/TKO. One initial seed plus stable raw inputs; no per-frame reseeding.
- Body-counter experiment: 3,886 frames/17 contacts/148 fields, zero mismatches; four successful body hits and three state-22 attacks through post-bell routing/fade frame 5903. Includes palette timer/four colour-write fields.
- Defense: 2,183 frames; body-block/KO: 3,135; successful player get-ups and third-knockdown TKO: 4,527. Existing parity suites retain zero mismatches. Referee speech test covers 8,094 fixture frames. Punch registration checks 20 poses.
- [Animation audit](ANIMATION_AUDIT.md) owns the **16 clips/5,269 full-rate paired frames**, plus 70 isolated referee pairs, source-pixel checks and pose-family corrections. Viewer: `research/evidence/motion_audit/index.html`. New referee arm-loop art uses shared body scale and foot anchors. It is integrated for review. Its head faces right; the requested facing correction was blocked by imagegen. The motion viewer predates this projection fix.
- Palette check matches 4,123 queued samples/40 pulse frames. Bell checks match 134 clock screenshots and 46 fade/routing samples.

## Remaining boundaries

- Bell countdown/fade and second-round return now match captures: 3,862 consecutive return/combat frames, 26 contacts, 143 fields; setup matches 134 fields. Production continuation preserves visibility and the 23-frame FIGHT command. Corner UI, healing choices and corner RNG/time remain adapted or unverified.
- Referee 172 is validated in isolation, not naturally reached in these fixtures. First-entrance overrides remain; source writers are identified, but removal is untested. Get-up 68..77 writes end at screen row 239; no complete off-screen anatomy exists in those commands. Replacement extent is authored, not a remaining hidden-ROM sprite.
- ROM-held drawings remain held for their original duration. These checks establish recorded-path timing and placement, not approval of replacement anatomy or all possible fight paths.
- Android/iOS packaging and physical-device QA remain unfinished.

Eight authorized overnight runs finished; automation remains paused. Push only when requested; no GitHub Actions. Run `python tools/validate_local.py --evidence`; see [development](DEVELOPMENT.md) for commands. ROMs/captures stay ignored.
