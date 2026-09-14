# Environment

Recorded 29 Aug 2026, on the machine this mirror was last built on.

- **R version:** 4.6.1 (2026-06-24)
- **OS:** macOS (Apple Silicon)

## Packages used across these scripts

| Package | Version |
|---|---|
| dplyr | 1.2.1 |
| tidyr | 1.3.2 |
| ggplot2 | 4.0.3 |
| patchwork | 1.3.2 |
| ggrepel | 0.9.8 |
| readr | 2.2.0 |
| strucchange | 1.6.0 |
| MARSS | 3.11.10 |
| glmnet | 5.0 |
| broom | 1.0.13 |
| tidyverse | 2.0.0 |
| sandwich | 3.1.3 |
| lmtest | 0.9.40 |
| zoo | 1.9.0 |
| pacman | 0.5.1 |

Most scripts load their dependencies via `pacman::p_load(...)`, which installs anything
missing automatically — a fresh clone should only need `install.packages("pacman")` first.

## Known limitation

⛔ **The scripts in `scripts/` are not yet path-portable.** Each one still carries an absolute
path from the machine it was written on, so none will run as-is on a clone. This is being
worked on; see the "NOT YET DONE" section of `README.md` for the current state.
