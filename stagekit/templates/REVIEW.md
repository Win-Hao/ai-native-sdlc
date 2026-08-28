# Review instructions

## Passes
Run three passes and tag each finding with its pass:

- **Bugs**: logic errors, broken edge cases, subtle regressions, race conditions,
  unhandled error paths.
- **Security**: injection risks, authentication and authorization gaps, PII in logs
  or error messages, secrets in the diff, unsafe deserialization.
- **Compliance**: the change against `spec.md` — requirements missing or partial,
  behaviour nobody asked for (scope creep), requirements that look implemented
  but wrong, quoting the spec line for each — and against `plan.md` (including
  its "Files that change" list), `CLAUDE.md` and the repo's skills.

## What Important means here
Reserve **Important** for findings that would break behavior, leak data, or breach
a policy. Style and naming are nits.

## Cap the nits
Report at most five nits per review; summarize the rest as a count.

## Do not report
- Generated files under `<generated paths>`
- Anything CI already enforces (formatting, lint, type errors)
- Test coverage percentages

## Plan compliance
Compare the diff against `plan.md`:
- Files changed that the plan did not name → report as Important unless
  `plan.md` "Deviations" explains it.
- Steps in the plan with no corresponding change → report as Important.
- The plan's "Proof" section not satisfied → report as Important.

## Classes
Stable names for kinds of finding, so repeats can be counted across reviews
(`stagekit/*/findings.md`). Reuse before inventing; add new ones here in the same commit.

- unplanned-file — a file changed that plan.md does not name
- test-weakened — a test edited, deleted or loosened to make it pass
- <class-slug> — <one line>

## Output
End with a machine-readable tally:

```
IMPORTANT=<n> NITS=<n> PASSES=bugs,security,compliance
```
