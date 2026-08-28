# shop-fixture

A small inventory / orders library. ESM, no dependencies, Node 21+.

## Commands
- Test: `npm test` (node:test over `tests/**/*.test.js`)

## Verifying your work
Run `npm test`; it must exit 0. There is no lint or build step.

## Conventions
- Errors are typed classes exported from the module that throws them.
- Money is rounded to two decimals with `round2` from `src/pricing.js`.
- Order ids come from a module counter; tests call `resetOrderIds()` in `beforeEach`.

## Data handling
Read `.claude/skills/data-policy/SKILL.md` and `docs/data-retention.md` before changing order records, customer fields, receipts or retention.
