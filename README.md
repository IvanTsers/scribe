# `scribe.sh`

This script creates a literate programming repository with stub files:
`org` to weave and tangle, `Makefile` for tangling, and `doc/*` for
weaving. Currently available languages: `go`, `sh`, `R`, and `python`.

Usage:

    bash scribe.sh progName "Author Name" lang

Do not use underscores in the program name to avoid LaTeX compilation
errors.