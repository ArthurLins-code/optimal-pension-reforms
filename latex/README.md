# LaTeX Presentation Folder

This directory is self-contained, so you can move the whole `latex/` folder into another repo without changing internal paths.

## Structure

- `presentation/`: English deck based on the exact Overleaf `_main.tex` export.
- `apresentacao/`: Portuguese copy of the deck, reusing the same assets.
- `figures/`: Shared figures and PDFs used by both decks.

## Compile

From `latex/presentation/`:

```bash
/Library/TeX/texbin/latexmk -f -pdf -interaction=nonstopmode _main.tex
```

From `latex/apresentacao/`:

```bash
/Library/TeX/texbin/latexmk -f -pdf -interaction=nonstopmode _main.tex
```

`-f` is included because the exported source already contains a few TeX issues, but it still produces the PDF successfully.
