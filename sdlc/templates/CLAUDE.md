# <Service name>

<One line: what this repo is and where its boundary lies.>

## Commands
- Build: `<cmd>`  (healthy output contains `<text>`)
- Test: `<cmd>`   (all green; integration: `<cmd>`, needs `<precondition>`)
- Lint: `<cmd>`   (zero warnings; runs in CI, fix before pushing)
- Run: `<cmd>`

## Verifying your work
Run all three before reporting any task complete, and paste the output.
If a test fails, fix the code, not the test.

## Conventions
- <language / framework versions and hard constraints>
- <naming, layout and error-handling conventions>
- <rules for error-prone types: money, time, ids>

## Architecture
- `<dir>/` — <responsibility>
- <dependency direction between modules>
- <what is generated code — never hand-edit>

## Things Claude gets wrong
<When the same mistake happens twice, it goes here. This section is alive; the
others are static.>
- <specific mistake → the correct way>

## SDLC
Change artifacts live in `sdlc/<id>/` (intent.md → spec.md → plan.md); the active
change id is in `.sdlc/current`. Commands: /sdlc:intent /sdlc:spec /sdlc:plan
/sdlc:build /sdlc:fix /sdlc:verify /sdlc:review /sdlc:done; /sdlc:status shows where a
change stands. Gates and drive mode: `.sdlc/config.json`.
