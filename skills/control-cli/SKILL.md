---
name: control-cli
description: Drive, inspect, and profile an interactive CLI or TUI through a Herdr pane. Use for CLI UX checks, startup regressions, memory leaks, hangs, prompt flows, or terminal demos.
---

# Control CLI

Use a repeatable local harness to exercise an interactive CLI instead of poking at it manually. First reuse the repo's own test/demo harness if it exists; otherwise assemble a temporary harness from standard local tools.

## What It Is Used For

- Reproducing CLI/TUI bugs with deterministic input.
- Verifying keyboard flows, prompts, interrupts, resize behavior, and terminal layout.
- Capturing before/after transcripts for bug fixes.
- Profiling startup time, slow operations, hangs, or memory growth.
- Recording a short terminal demo when output is easier to show than explain.

## Harness Loop

1. Identify the command under test and the smallest reproducible workspace.
2. Discover existing local harnesses: package scripts, e2e tests, demo recorders, expect scripts, or PTY helpers.
3. If no harness exists, launch the CLI in its own Herdr pane with deterministic env vars.
4. Capture the current screen before interacting.
5. Send one action at a time: text, Enter, arrows, Escape, Ctrl-C, resize.
6. Wait for a concrete screen pattern or prompt before the next action.
7. Save the transcript and any profile artifacts.
8. Kill the session cleanly.

## Harness Options

- Repo-native harness: prefer checked-in scripts because they know the app's startup, env, and prompts.
- Herdr: managed panes, `pane read`, `pane send-keys`, `pane wait-output`.
- PTY probe: use a short Python, Node, or Expect script when you are outside Herdr.
- Runtime inspector: use Node or Bun inspector for CPU profiles, heap snapshots, and live evaluation.
- Terminal recorder: use repo-local demo tools or asciinema-compatible tools when the user asks for a demo.

## Minimal Herdr Harness

Herdr gives every session its own pane, so the CLI under test runs beside you rather than inside your own terminal.

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr pane run <pane-id> "<command-under-test>"
herdr pane wait-output <pane-id> --match "<ready text>" --timeout 60000
herdr pane read <pane-id> --source recent-unwrapped --lines 200
herdr pane send-keys <pane-id> ctrl+c
herdr pane close <pane-id>
```

Read the pane id out of the split's JSON response. `pane wait-output` searches what is already on screen before waiting, so output that arrived first still matches. Use `--regex` for a pattern and `--format ansi` when color is the evidence. Logical keys go through `send-keys`, which validates them before writing any bytes.

For Node CLIs needing an inspector:

```bash
herdr pane run <pane-id> "NODE_OPTIONS='--inspect=127.0.0.1:0' <node-cli-command>"
```

Read the pane to find the inspector URL, then attach Chrome DevTools-compatible tooling if profiling is needed.

## Minimal PTY Harness

Use a PTY script when you are outside Herdr and the repo has no demo harness. Keep it temporary unless the user asks to add a reusable test.

```python
import os
import pty
import select
import subprocess
import time

master_fd, slave_fd = pty.openpty()
proc = subprocess.Popen(
    ["<command>", "<arg>"],
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    close_fds=True,
)
os.close(slave_fd)

deadline = time.time() + 30
buffer = b""
while time.time() < deadline:
    ready, _, _ = select.select([master_fd], [], [], 0.25)
    if not ready:
        continue
    chunk = os.read(master_fd, 4096)
    buffer += chunk
    if b"<ready text>" in buffer:
        os.write(master_fd, b"help\n")
        break

print(buffer.decode(errors="replace"))
proc.terminate()
os.close(master_fd)
```

If the CLI needs richer terminal control, use `pty.fork()` or an existing PTY library.

## Profiling Recipes

- Startup regression: capture baseline and treatment startup timings under the same machine, env, and command.
- Slow operation: start a CPU profile, perform the operation, stop the profile, and compare top self-time functions.
- Memory leak: force GC if available, take a heap snapshot, perform the operation repeatedly, force GC again, and take another snapshot.
- Hang: capture the screen, active handles/resources, and a stack/CPU sample before interrupting.

## Guardrails

- Prefer deterministic waits over sleeps. If you must sleep, explain why.
- Do not send credentials or destructive commands into a controlled session.
- Keep the harness in `/tmp` unless the repo already has a testing/demo harness.
- Do not hard-code paths from another repository. Adapt commands to the current repo's scripts and runtime.
- Close every pane you opened, and clean up temp dirs, inspector processes, and demo artifacts unless the user asks to keep them.
