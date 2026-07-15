# LaTeX Presentation Folder

This directory is self-contained, so you can move the whole `latex/` folder into another repo without changing internal paths.

## Structure

- `presentation/`: English deck based on the exact Overleaf `_main.tex` export.
- `apresentacao/`: Portuguese copy of the deck, reusing the same assets.
- `figures/`: Shared figures and PDFs used by both decks.

## Compile

From `latex/presentation/`:

```bash
latexmk _main.tex
```

From `latex/apresentacao/`:

```bash
latexmk _main.tex
```

The repository root `.latexmkrc` makes `latexmk` compile from the source file's own directory and write SyncTeX files.
