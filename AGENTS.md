# Punch Tap! repository rules

## Session startup

Read [current state](docs/CURRENT_STATE.md) first. Read [architecture](docs/ARCHITECTURE.md) only when changing runtime code; follow its links for the relevant subsystem. Do not bulk-read research captures, generated JSON, old reports, or conversation transcripts. Search narrowly with `rg`.

## Project constraints

- Build Punch Tap! in Godot, portrait 540 x 960, for eventual Android/iOS release.
- Preserve ROM-recovered sequences, frame timings, movement, and contact behavior. Do not invent missing behavior or silently substitute replay clips for live logic.
- Use original male characters and original art/audio. Keep ROM graphics and research captures out of production assets.
- Follow [approved art direction](docs/ART_DIRECTION.md). Generated images are proposals until reviewed; do not equate generation with integration.
- Distinguish measured evidence, source-derived implementation, assumptions, and unverified behavior. Never call this a completed port while integration or parity checks fail.

## Documentation maintenance

- Markdown in `docs/` is the current handoff. Older `.txt` reports and logs are historical evidence, not current status.
- Give each fact one owner: architecture for structure, current state for blockers/next actions, art direction for visual decisions, recovery for evidence, development for commands.
- Update the owning document in the same work session when behavior, approved decisions, blockers, setup, or validation changes. Update current state before handing off unfinished work.
- Edit existing facts in place; remove resolved blockers. Do not append session diaries, chat transcripts, raw logs, repeated plans, or generated data.
- Each completion claim needs a relevant file/test/evidence link and its practical scope. Never turn a hypothesis into a fact by repeating it.
- Keep links relative inside repository docs. Link to large artifacts instead of copying them. Summarize results, not tool output.
- Keep startup reading small: this file <= 450 words and current state <= 550. Other page limits are enforced by `tools/check_docs.py`; no page may exceed 650 words.
- Split only when a page exceeds its budget or contains a separate topic. Add the new page to the README index and checker budgets. Do not create one file per session.
- Use ISO dates only for time-sensitive status/evidence; update dates when substantively verified, not merely opened. Record what was not retested.
- Run `python tools/check_docs.py` after documentation changes. Check code/test evidence before marking work complete; the docs checker validates structure, not truth.

User instructions take precedence. These rules do not introduce additional approval gates.
