# Contributing

Read [AGENTS.md](AGENTS.md) and [current state](docs/CURRENT_STATE.md) before changing behavior. Keep each change focused and describe the trigger, resulting behavior, and validation in a pull request.

- Preserve recovered timing and movement. Identify the source routine or capture when changing emulated behavior; label assumptions explicitly.
- Follow [approved art direction](docs/ART_DIRECTION.md). Concept approvals and runtime integration are separate milestones.
- Do not upload ROMs, extracted copyrighted media, memory dumps, emulator screenshots, credentials or local tool binaries. Keep them in ignored local locations.
- Update the relevant short document in the same change. Run `python tools/check_docs.py` and the applicable tests from [development](docs/DEVELOPMENT.md).
- State whether checks used the live adapter, legacy model, captured replays, or offline routine fixtures. Do not describe the known failing full-bout test as passing.

The repository does not currently grant a project-wide open-source license. Do not introduce third-party assets or change licensing without an explicit maintainer decision.
