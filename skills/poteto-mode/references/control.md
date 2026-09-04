# Control surfaces

Proving a change works means driving the real artifact the way a user does. This file names the harness for each surface. Skills say "drive the surface through its control harness" and point here.

Both harnesses are executables on `PATH`. That matters because verification runs inside delegates, and a delegate can be any agent kind. An MCP server or vendor plugin reaches only the kinds configured for it; a CLI reaches all of them.

| Surface | Harness |
|---|---|
| CLI, TUI, REPL, any terminal program | `herdr` pane commands |
| Browser, Electron, web app | `agent-browser` |
| Native mobile | whatever simulator driver the repo has. A surface with no harness is a stated risk, not a silent gap |

## Terminal surfaces

Herdr drives terminal programs. Give the program its own pane, run it, wait on output, read the result.

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr pane run <pane-id> "<command>"
herdr pane wait-output <pane-id> --match "<literal>" --timeout 120000
herdr pane read <pane-id> --source recent-unwrapped --lines 200
```

`pane run` sends the command and Enter atomically. `pane wait-output` searches the existing snapshot first, so output that already arrived still matches. Use `--regex` instead of `--match` for a pattern. Drive interactive prompts with `herdr pane send-keys`, which validates keys before writing any bytes.

Read with `--format ansi` when color is the evidence, such as a diff or a pass/fail marker that only differs by color.

## Browser surfaces

`agent-browser` drives browsers and Electron apps. The loop is open, snapshot, act on refs, re-snapshot.

```bash
agent-browser --session <name> open <url>
agent-browser --session <name> snapshot -i
agent-browser --session <name> click @e3
agent-browser --session <name> fill @e1 "text"
agent-browser --session <name> screenshot <path>.png
agent-browser --session <name> close
```

`snapshot -i` returns the interactive accessibility tree with a ref per element, which is a few lines for a whole page rather than an image. Prefer it to screenshots for deciding what to do next, and save screenshots for evidence a human will look at.

**Refs belong to one session's most recent snapshot.** Snapshot before the first action, and again after anything that changes the page. Acting on a stale ref fails with `Unknown ref`, which is the harness telling you the page moved under you.

**Always pass `--session`.** Each session is an isolated browser with its own cookies, storage, history, and auth. Parallel verifiers need one session each, named for the verifier, or they fight over one browser. Sessions open concurrently without contention.

Close every session you opened.

## Rules that hold on both

Reproduce a defect yourself on the surface before fixing it. Handing the repro to the user is the exception, taken only with a stated reason the harness cannot reach the target, and only after driving it as far as it goes.

Verify against the artifact, not a proxy (**principle-prove-it-works**). A passing test suite is not a driven feature. A screenshot of the wrong state is not evidence.

A project with no scripted path to its own behavior gets one built. That is what `/create-verification-skill` generates, tailored to the repo and its feature map.
