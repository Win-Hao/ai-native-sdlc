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

## StageKit
Change artifacts live in `stagekit/<id>/` (intent.md → spec.md → plan.md); the active
change id is in `.stagekit/current`. Commands: /stagekit:intent /stagekit:spec /stagekit:plan
/stagekit:build /stagekit:fix /stagekit:verify /stagekit:review /stagekit:done; /stagekit:status shows where a
change stands. Gates and drive mode: `.stagekit/config.json`.
