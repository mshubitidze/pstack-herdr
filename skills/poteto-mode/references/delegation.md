# Delegation

Every pstack skill that spawns work follows this contract. Skills name a **role** and a **posture**. They never name herdr commands, agent kinds, or model slugs. Those live here and in the roster, so one edit reaches every skill.

Delegates run as real agents in Herdr panes. There is no headless path and no cloud path.

## Preconditions

Verify you are inside Herdr before spawning anything.

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say you cannot delegate and do the work in this session instead. Never silently degrade to doing a fan-out serially without saying so.

## The primitive

Five steps. Split, start, prompt, collect, close.

```bash
# 1. Split a background pane. Wide panes split right, tall panes split down.
herdr pane split --current --direction right --cwd "$PWD" --no-focus
#    Read .result.pane.pane_id from the JSON. Never guess it.

# 2. Start the agent. Native args go after the `--`.
herdr agent start <name> --kind <kind> --pane <pane-id> -- <model args>

# 3. Prompt it and block until it settles.
herdr agent prompt <name> "<brief>" --wait --timeout 600000

# 4. Collect. See the return path below.

# 5. Close the pane you created.
herdr pane close <pane-id>
```

Names must match `[a-z][a-z0-9_-]{0,31}` and be unique among live agents. Use the role and index, such as `critic-2` or `verifier-pr481`.

Measured on this machine, an agent reaches interactive readiness in three to five seconds, so a panel of four costs a few seconds of startup, not minutes. Size fan-out by the work, not by fear of boot cost.

## Kinds and roles

Each role resolves to a kind and a model through the roster at `~/.agents/pstack-models.md`. A role with no roster line falls back to the default named in the skill that owns it.

| Kind | Reaches | Model argument |
|---|---|---|
| `pi` | Every OpenAI Codex and OpenCode Go model | `-- --model <provider>/<id>:<thinking>` |
| `claude` | Fable, Opus, Sonnet, Haiku | `-- --model <alias>` |

`pi` is the default kind, since it reaches the widest roster and sets model and reasoning level in one argument. Use `claude` when the roster names a Claude model, which is the usual case for judgment and prose.

Cross-family diversity is the point of every panel. When a panel's roster entries would all resolve to one family, say so in the reply rather than pretending the panel was diverse.

## The return path

**Anything you will machine-read comes back as a file, not as pane text.**

Give every delegate an output path and require the reply to be that path alone.

```
Write your findings to /tmp/pstack/<run-slug>/<role>-<n>.md.
Reply with only that path. No summary in the reply.
```

Then read the file directly. Do not parse the pane.

Not because reads lose data; they recover full multi-line responses. Because of chrome. Claude prefixes its first response line with `⏺`, pi wraps output in borders and a status bar, and every kind renders differently. Parsing that across vendors breaks silently when any one of them changes.

Pane reads stay useful for three things. Checking whether a delegate is alive, inspecting one that stalled, and reading a short answer a human will look at anyway.

```bash
herdr agent read <name> --source recent-unwrapped --lines 200
```

## Fan-out

Spawn a wave in one pass. Split every pane, start every agent, then prompt them all before waiting on any of them. Prompting one at a time serializes the panel and throws away the parallelism.

Put a wave in its own tab when it exceeds three agents, so the operator's layout stays readable.

```bash
herdr tab create --workspace "$HERDR_WORKSPACE_ID" --no-focus
```

Each brief stands alone. It carries the goal, the exact slice or arm, how to verify, the output path, and the report vocabulary the skill expects. Delegates cannot read this chat, so a brief that says "as discussed above" is a broken brief.

If a delegate drops out, proceed with N-1 and name the dropout in the reply. Never quietly report a four-way panel that ran three ways.

## Waiting

`--wait` returns on the first settled `idle`, `done`, or `blocked`. That is the default and it is usually enough. Do not restate it with `--until`.

A `blocked` return means the delegate hit an approval or question dialog. Read it before answering.

```bash
herdr agent get <name>
herdr agent read <name> --source recent-unwrapped --lines 80
```

Answer a blocked delegate only when the answer is already settled by the brief. Anything else goes to the operator. Never send blind keys at a dialog you have not read.

## Read-only delegates

Herdr has no read-only mode. A delegate is a full agent. Read-only is a posture you state in the brief and enforce with tool restrictions.

| Kind | Restriction |
|---|---|
| `pi` | `-- --no-tools` for pure reasoning, or `-- --exclude-tools <names>` for a denylist. Read the installed tool names from `pi --help` rather than guessing them |
| `claude` | `-- --disallowedTools Edit Write` |

State the posture in the brief as well. Tool flags stop writes, the brief stops the delegate wasting a turn trying.

Restricting write tools does not cost a delegate its MCP access, so an MCP-backed investigator can be read-only and still reach every server it needs.

## Writers get their own worktree

Two delegates must never write the same branch or working tree. Give every writing delegate its own worktree and start it there.

```bash
herdr worktree create --branch <branch> --base <ref> --no-focus
```

This creates the worktree and its own workspace. Read the ids out of the response and start the delegate in that workspace rather than splitting a pane in yours. Run `herdr worktree` for the current command shape before relying on any field name here.

Readers and reviewers need no worktree. They share the parent's tree.

## Discipline

Use `--no-focus` on every split, so background work never steals the operator's focus.

Target panes by the id the split returned or by the agent's unique name, parsed out of the JSON response. Never rely on the focused pane, which may belong to the operator, and never copy an id from the examples here.

Close every pane you opened once its output is collected. Never close one you did not create.

## Changing a delegate's scope

An interrupt-chained resume drops directives silently. When scope changes, close the delegate and start a fresh one with the consolidated brief instead of correcting a running agent.

## Migrating a Cursor call

| Cursor `Task` | Here |
|---|---|
| `subagent_type: "poteto-agent"` | Brief instructs the delegate to read the `poteto-mode` skill in full first |
| `subagent_type: generalPurpose` | Any kind. The brief carries the whole role |
| `model: <slug>` | Roster role, resolved to kind plus model args |
| `readonly: true` | Tool restriction plus posture in the brief |
| `run_in_background: true` | Always true. Panes are background by construction |
| `environment: "cloud"` | Gone. Every delegate is local |
| `cloud_base_branch` | `herdr worktree create --base <ref>` |
