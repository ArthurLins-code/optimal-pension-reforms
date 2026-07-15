# Rename presentation tooling to deck_tools

Date: 2026-07-15

## Objective

Rename the top-level `presentation/` tooling folder to `deck_tools/` now that
the Beamer sources live under `latex/presentation/` and `latex/apresentacao/`.
The change should clarify the repository structure without changing deck
content, figure provenance, or analysis outputs.

## Scope

1. Move `presentation/` to `deck_tools/`.
2. Update active code paths in `config/paths.R`, `RUN.R`, and the deck build
   wrapper.
3. Update project-facing documentation that describes the current layout and
   run commands.
4. Leave historical quality reports and restructure archives unchanged unless
   they are part of the active workflow.

## Verification

1. Run `git status --short`.
2. Run `python3 deck_tools/figures_central_folder/verify_deck.py`.
3. Compile `latex/presentation/_main.tex` with `latexmk -g` and SyncTeX enabled,
   writing build artifacts outside the repo.
