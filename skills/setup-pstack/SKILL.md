---
name: setup-pstack
description: Configure which agent kind and model pstack uses per role. Detects the models you can actually reach and writes the roster every skill reads. Use for /setup-pstack, "configure pstack models", or changing pstack's model choices.
---

# Setup pstack

Write `~/.agents/pstack-models.md`, the roster that maps each pstack role to an agent kind and a model. Every skill names a role and reads its value here. A role with no line falls back to the default named in the skill that owns it, so this is an override layer, not a requirement.

The roster lives outside any one harness because delegates run as separate agents. See the delegation contract in the `poteto-mode` skill (`references/delegation.md`) for how a role becomes a running agent.

## Steps

### 1. Detect what you can reach

Enumerate real models, never guess them. Two sources cover the roster.

```bash
pi --list-models
herdr agent 2>&1 | grep '^  kinds:'
```

`pi --list-models` prints every provider and model id that Pi can reach, which is the widest set. Claude models do not appear there. Reach those through the `claude` kind, whose aliases are `fable`, `opus`, `sonnet`, and `haiku`, plus any full model name the CLI accepts.

Confirm a kind is installed before writing it into the roster. A roster line naming a kind that is not on `PATH` breaks every delegation that reads it.

### 2. Load current state

If `~/.agents/pstack-models.md` exists, read it and treat its values as the current choices. Otherwise start from the skills' own defaults.

### 3. Map and confirm

Show every role with its current value, marking anything you could not confirm in step 1. Ask whether to accept as-is or change specific roles. Prefer a structured multiple-choice question over free text.

Panel roles (`how critics`, `arena runners`, `architect runners`, `interrogate reviewers`, `arena cross-judge pool`) take a list. One delegate runs per entry, so the list length sets the fan-out. Panels exist to disagree, so spread their entries across model families and warn the user when a panel would collapse to one.

`swarm workers` is the default for every worker unless a race assigns a model per arm.

### 4. Validate

Every model written must have appeared in step 1's detection. If a chosen value is unavailable, stop and ask again.

### 5. Write the roster

Overwrite the whole file so re-runs stay idempotent. One line per role, in the form `role: <kind> <model args>`. The model args are passed verbatim after the `--` in `herdr agent start`.

```
# pstack roster. One line per role. Delete a line to fall back to the skill default.
# Form: role: <kind> <args passed after -- to herdr agent start>

feature:                pi --model <provider>/<id>:<thinking>
refactoring:            pi --model <provider>/<id>:<thinking>
bug-fix:                claude --model <alias>
perf-issue:             claude --model <alias>
hillclimb:              claude --model <alias>
judgment and prose:     claude --model <alias>
hardest tasks:          claude --model <alias>

how explorer:           pi --model <provider>/<id>:<thinking>
how explainer:          claude --model <alias>
how critics:            <one entry per critic, across families>

why investigators:      pi --model <provider>/<id>:<thinking>
why synthesizer:        claude --model <alias>

reflect tooling:        pi --model <provider>/<id>:<thinking>
reflect judgment:       claude --model <alias>
reflect divergent:      claude --model <alias>
reflect synthesizer:    claude --model <alias>

arena runners:          <one entry per runner, across families>
arena cross-judge pool: <one entry per candidate judge, across families>
swarm workers:          pi --model <provider>/<id>:<thinking>
architect runners:      <one entry per runner, across families>
interrogate reviewers:  <one entry per reviewer, across families>
```

### 6. Confirm

Tell the user the roster was written and that re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once. "Want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.
