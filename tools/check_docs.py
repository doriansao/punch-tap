"""Check the small, explicitly indexed handoff docs without scanning research."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
BUDGETS = {
    "AGENTS.md": 450,
    "README.md": 400,
    "CONTRIBUTING.md": 250,
    "THIRD_PARTY_NOTICES.md": 300,
    ".github/pull_request_template.md": 150,
    "docs/CURRENT_STATE.md": 550,
    "docs/ARCHITECTURE.md": 650,
    "docs/ART_DIRECTION.md": 400,
    "docs/RECOVERY.md": 550,
    "docs/DEVELOPMENT.md": 450,
    "docs/ANIMATION_AUDIT.md": 500,
}


def main():
    errors = []
    total = 0
    for name, limit in BUDGETS.items():
        path = ROOT / name
        if not path.is_file():
            errors.append(f"Missing document: {name}")
            continue
        text = path.read_text(encoding="utf-8")
        count = len(text.split())
        total += count
        print(f"{name}: {count}/{limit} words")
        if count > limit:
            errors.append(f"{name}: exceeds word budget; trim or split by topic")
        for target in re.findall(r"\]\(([^)]+)\)", text):
            target = target.strip().strip("<>")
            if re.match(r"^[a-zA-Z][\w+.-]*:", target) or target.startswith("#"):
                continue
            local = target.split("#", 1)[0]
            if local and not (path.parent / local).exists():
                errors.append(f"{name}: missing local target {target}")
    for path in (ROOT / "docs").rglob("*.md"):
        name = path.relative_to(ROOT).as_posix()
        if name not in BUDGETS:
            errors.append(f"Unbudgeted doc: {name}; add it to README and BUDGETS")
        elif name not in {"docs/CURRENT_STATE.md"}:
            readme = (ROOT / "README.md").read_text(encoding="utf-8")
            if f"({name})" not in readme:
                errors.append(f"Document not indexed in README: {name}")
    print(f"Total: {total} words. Checks cover length and local paths, not factual accuracy.")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())
