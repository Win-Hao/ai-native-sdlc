---
name: gate
description: Stage 5 Deploy (b) — express the change process's human approval gates as hooks, so the agent acts up to the production gate and cannot pass it. Also audits which gates are currently live.
argument-hint: "[audit | add | test]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep Bash
---

# Stage 5b — Hooks as approval gates

A skill is an advisory control: it makes Claude likely to apply a policy. A hook
is the deterministic layer behind it. **Any policy that must hold without
exception needs a hook, not just a skill.** The skill makes violations rare; the
hook makes them close to impossible.

---

## `audit` — what is actually enforced right now

1. Read `.stagekit/config.json` and report the gate level (`_gate_level`), the drive
   mode (`drive`) and each gate: enabled or not, and the concrete paths/commands it matches **in this
   repo**.
2. Read `.claude/settings.json` and any managed settings for additional hooks
   and permission rules.
3. Report the honest gap: for each policy in `CLAUDE.md` and `.claude/skills/`,
   is there a deterministic control behind it, or only the skill? Name the ones
   with no hook — those are the policies that hold only by luck.

---

## Levels — raise enforcement as the artifacts come into use

`_gate_level` in `.stagekit/config.json` records how far this repo has gone. A gate on
an artifact nobody reads yet is a prompt everyone learns to click through, so
the order follows the adoption order:

| Level | Gates on | Raise it when |
|---|---|---|
| `minimal` | irreversible, production_gate | day one |
| `standard` | + test_lock, protected_paths | plan.md and the test-first fix path are in use |
| `full` | + plan_sync | plan.md is read before every implementation |

```
jq '._gate_level="standard" | .gates.test_lock.enabled=true | .gates.protected_paths.enabled=true' .stagekit/config.json > t && mv t .stagekit/config.json
jq '._gate_level="full" | .gates.plan_sync.enabled=true' .stagekit/config.json > t && mv t .stagekit/config.json
```

Then run `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh`: a gate that was off has
never had its globs checked against this repo.

---

## `add` — add a gate

1. **List the approvals that must survive.** Change-management sign-off, release
   authorization, edits to protected paths, schema migrations, dependency bumps.
   Get this list from the human; do not infer it.
2. **Express each as allow / ask / block:**

   | Verdict | Use for | Mechanism |
   |---|---|---|
   | block (`deny`) | Never legitimate in an agent session | `permissionDecision: deny` |
   | ask | Legitimate but irreversible | `permissionDecision: ask` |
   | allow | The safe inner loop | pre-approve, so the deny list doesn't cause prompt fatigue |

   Claude Code accepts exactly `allow`, `deny`, `ask` and `defer`. Anything else
   is discarded as invalid hook output — a gate that silently allows.

3. **Most gates are config, not code.** Prefer adding a pattern to
   `.stagekit/config.json` over writing a new hook script.
4. **A block must explain itself.** The reason *and the route to approval* go in
   the message. A gate that just says "denied" gets worked around.
5. Repo-wide hooks go in `.claude/settings.json` (in git, reviewed like code).
   Non-negotiable ones belong in managed settings an engineer cannot switch off.

---

## `test` — prove the gate fires

For each gate, actually trigger it and show the block. An untested gate is an
assumption. Check both directions: the blocked case blocks, and the normal case
still passes without a prompt.

The plugin's own gates have a self-test that does exactly this against a
throwaway repo: `${CLAUDE_PLUGIN_ROOT}/scripts/selftest.sh`. Run it after
changing anything in `scripts/`.

---

## The principle

The agent may act up to the production gate and cannot pass it. Branch protection
turns anything it writes into a PR with no path to main, and the production hook
holds the release until a named person authorizes it. The agent that wrote the
code has no route to approve it.
