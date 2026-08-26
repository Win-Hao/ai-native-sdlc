---
id: <NNNN-slug>
stage: build
status: draft              # draft | approved | implemented
from_spec: ./spec.md
approved_by: <name>
created: <YYYY-MM-DD>
---

# Plan: <title> (from spec.md <YYYY-MM-DD>)

## Files that change
<Every path, marked new / modify / delete. Never "and related files".>

- `path/to/file.ts` (new) — <responsibility>
- `path/to/other.py` (modify) — <what changes>

## Order of work
1. <First step. Each step is a vertical slice: demoable on its own, sized to one session.>
2. <Second step.>
3. <Third step.>

## Risks
<What this change could break. Which step is riskiest.>

## Alternatives not taken
<Options considered and rejected, with the reason. Interrogating the plan
finds the most here.>

## Proof
<How to show it is right, written from spec.md "Testing decisions": named test
files at the agreed seams, commands, expected output, the mock a screenshot
must match.>

- `tests/test_x.py` covers <which cases>
- `make test` green
- Screenshot matches `design/mock-x.png`

## Deviations
<Filled in — in the same commit — whenever the implementation departs from the
plan. Empty means none.>
