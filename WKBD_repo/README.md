# WKBD_repo — Chapter 2 replication mirror

*Who Killed British Democracy?* — Peter John. Bristol University Press.
**Built 17 Aug 2026** by `scripts/_helpers/build_repo_mirror.R`.

This folder is the GitHub-shaped view of Chapter 2: manuscript, scripts, data, figures, tables.
Everything here is a **copy**; the working tree is unchanged. Re-run the builder after any figure
rebuild and it refreshes in place.

```
WKBD_repo/
  manuscript/   the current chapter (newest "Chapter Two vNN.docx" — picked automatically)
  figures/      the 16 figures, named by their PRINTED number
  tables/       Table 2.1, and the chapter shapes table
  scripts/      the build scripts, filenames exactly as in the working tree
  scripts/_helpers/   shared code (Chow, house theme, the two assembly scripts)
  data/         inputs, grouped: executive / electoral / public_opinion /
                parliament / policy / nao / composite
  MANIFEST.csv  figure number -> repo filename -> build script -> working-tree path
```

## Read MANIFEST.csv first

Script filenames are kept **exactly as they are in the working tree**, on purpose. Two naming
systems have just been reconciled (see below) and inventing a third one here would undo that.
`MANIFEST.csv` is the index that ties a figure number to its script and its original location.

## ⛔ NOT YET DONE — do not let the tidy shape imply more than it delivers

- **The scripts are not path-portable.** Each one still carries the absolute path
  `/Users/peterjohn/.../Who Killed British Democracy?/...` it was written with. They reproduce the
  figures **on PJ's machine only**. Making them portable — one `ROOT` variable, relative paths
  throughout — is a real job and has not been started. ⚠ A reader who clones this will get 17
  scripts that fail on the first `read.csv`. (29 Aug: `PROVENANCE.csv` and `ENVIRONMENT.md`, the
  other two replication-package gaps, are now done — see the project root here — so this is the
  one remaining item before this mirror is genuinely clone-and-run.)
- **Figure 2.1's data is not a file.** The PM list is a hardcoded `tribble` inside
  `scripts/01_pm_turnover.R`, so there is no `pm_tenure` input for it in `data/`. (The separate
  `data/executive/pm_tenure.csv` is what Figure 2.4 reads.) Same pattern in
  `05_comparative_turnover.R`.
- **`data/executive/great_officers.csv` is author-verified, not source-verified** — 97 rows typed
  from gov.uk/Wikipedia with no per-row URL. Legitimate for a book; it must not be described as
  source-verified in the replication appendix.
- **Table 2.1 is a PNG.** BUP require tables to stay in the Word typescript and figures to be
  separate files; we currently have that the wrong way round. Stage (c) work.
- **Figures are at draft resolution.** `scripts/_helpers/figure_house_theme.R` carries
  `HOUSE_MODE <- "draft"`; flipping it to `"production"` gives BUP's 120 mm / 300 dpi. ⚠ The real
  problem is type size after reduction, not resolution — a 9-inch figure reduced to 120 mm puts
  10 pt type at about 5 pt. Worst affected: 2.8, 2.9, 2.10.
- **The online appendices are not in here.** They live in `online_appendix/` and are **not for
  release yet** (PJ, 17 Aug).
- **Project structure outside this folder.** This mirror only shows what's currently live. Every
  superseded script, figure, or dataset that fed an earlier version of a live file is preserved,
  not deleted, at `_ARCHIVE/` (project root — same mirrored folder names as the live tree, e.g.
  `_ARCHIVE/scripts/`, `_ARCHIVE/figures/`), with a full `original_path,archived_to` record in
  `_ARCHIVE/RESTORE_MAP.csv`. The complete list of what this builder actually reads —
  regenerated from `build_repo_mirror.R` itself, so it can't drift out of date — is
  `data_workspace_2026-07/_LIVE_PATHS.csv`; see `data_workspace_2026-07/00_LIVE_VS_EXPLORATORY.md`
  for how that list is used and why a folder's name (e.g. a `ch3_`-prefixed folder feeding a
  Chapter 2 figure) is not a reliable guide to whether it's live.

## ⚠ Open questions that touch the data in this folder

- **`data/parliament/lords_defeats_annual.csv`** annualises an official **by-session** series by
  step-carry, so a two-year session's whole total lands on every year it spans. The 2024–2026
  session contributes **208** to 2024, 2025 and 2026; per year that is 104, *below* 2021 and 2022.
  The break year is 2016 either way. `sources_raw/lords_defeats_by_session_official.csv` is
  included so the alternative can be built. Undecided: raw or per-year on the figure.
- **`data/policy/uturns_series.csv`** — 72 events were dated from model recall, 29 of them in the
  1990s where the series peaks. A 20-event hand-check has been outstanding since 15 Aug.
- **`data/composite/canonical_pc1_1979_2024.csv`** — ⚠ **this component list is stale** (dated to
  the 16 Aug freeze) and needs re-verifying against `composite_canonical/build_canonical_composite.R`
  directly before quoting: `rebellion_pct` was later dropped (18 Aug, kept one parliamentary
  dimension via `dislocation` only) and `unexpected` (public opinion, Fig 2.9) was added (17 Aug) —
  PJ is actively reconsidering that last addition (29 Aug) on IV/DV-consistency grounds, so this
  entry should not be corrected until that's settled, to avoid re-editing it twice.
  `full_model_comparison.R` builds the everything-in alternative (r = 0.934) that answers the
  selection objection.

## What changed on 17 Aug

Three things were reconciled on the day this folder was first built:

1. **All Chow panels came out of the chapter**, on a single model-selection rule applied to every
   series (BIC over flat / linear / quadratic / break / segmented / spline).
2. **Two renumberings** — the old 2.3 was dropped, and the old 2.2 was merged into 2.1 as panel B.
   The chapter has **16** figures, not 18.
3. **One script per figure.** Every figure had been building from a `_NOCHOW` variant while the
   original still sat beside it — and for Figure 2.1 both wrote to the *same* filename, so running
   the original silently replaced the live figure. Variants promoted; originals preserved in
   `_ARCHIVE/scripts/superseded_17aug_prechow_scripts/` at the project root.

Source filenames were then brought into line with the printed numbers, in one pass, with the
references inside every script rewritten at the same time.
