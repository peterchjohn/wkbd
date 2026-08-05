# Who Killed British Democracy?

A book project by Peter John (Professor of Public Policy, King's College London),
examining the growing turbulence and instability of British politics in the twenty-first
century — sudden election reversals, referendum shocks, rapid leadership turnover, and
weak policy delivery — and asking what is driving it.

The book takes the form of an investigation: rather than settling on a single cause, it
works through a series of candidate explanations — the political class, civic culture,
media, economic shocks, constitutional design, the hollowing-out of the state — testing
each against the evidence in turn.

## About this repository

This repository holds the project's replication material: the data-construction scripts
and derived series behind the book's figures and analysis. The guiding principle is that
every reported number should be reconstructable from a sourced script and a logged
provenance trail — no black-box figures.

**This repository is a work in progress and is not yet complete.** Chapter drafts,
publisher correspondence, and material still under construction are deliberately excluded
(see `.gitignore`). What's here so far is being added incrementally as sections of the
analysis are finalised.

## Repository structure

- `scripts/` — R scripts that build each figure/series from source data
- `data/raw/` — source data as obtained (e.g. Institute for Government ministerial data)
- `data/processed/` — derived series produced by the scripts in `scripts/`
- `figures/` — output figures

## Status

Early stage. More material will be added as chapters are finalised.
