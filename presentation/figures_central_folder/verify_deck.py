#!/usr/bin/env python3
"""
verify_deck.py — confirm every live \\includegraphics in the presentation resolves
under latex/figures/{from_code,static}. Read-only; no copying.

Usage: python figures_central_folder/verify_deck.py
Exit 0 if all active figure references resolve, else 1 (lists the unresolved ones).
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent          # presentation/figures_central_folder/
PRESENTATION = HERE.parent                       # presentation/
ROOT = PRESENTATION.parent                       # repo root
DECK = ROOT / "latex" / "presentation" / "_main.tex"
FROM_CODE = ROOT / "latex" / "figures" / "from_code"
STATIC = ROOT / "latex" / "figures" / "static"

COMMENT = re.compile(r"(?<!\\)%.*")
INCLUDE = re.compile(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}")


def main() -> int:
    text = DECK.read_text(encoding="utf-8", errors="replace")
    names = []
    for line in text.splitlines():
        stripped = COMMENT.sub("", line)        # drop commented-out \includegraphics
        names.extend(m.group(1).strip() for m in INCLUDE.finditer(stripped))

    uniq = sorted(set(names))
    unresolved = [n for n in uniq if not ((FROM_CODE / n).exists() or (STATIC / n).exists())]

    print(f"active \\includegraphics : {len(names)} refs, {len(uniq)} unique")
    print(f"resolved                : {len(uniq) - len(unresolved)}")
    print(f"unresolved              : {len(unresolved)}")
    for n in unresolved:
        loc = "from_code" if (FROM_CODE / n).exists() else ("static" if (STATIC / n).exists() else "NOWHERE")
        print(f"   UNRESOLVED: {n}  ({loc})")

    return 1 if unresolved else 0


if __name__ == "__main__":
    sys.exit(main())
