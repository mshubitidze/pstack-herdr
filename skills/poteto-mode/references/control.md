# Control surfaces

Proving a change works means driving the real artifact the way a user does. This file names the harness for each surface. Skills say "drive the surface through its control harness" and point here.

Both harnesses are executables on `PATH`. That matters because verification runs inside delegates, and a delegate can be any agent kind. An MCP server or vendor plugin reaches only the kinds configured for it; a CLI reaches all of them.

| Surface | Harness |
|---|---|
| CLI, TUI, REPL, any terminal program | the **control-cli** skill (Herdr panes) |
| Browser, Electron, web app | the **control-ui** skill (`agent-browser`) |
| Native mobile | whatever simulator driver the repo has. A surface with no harness is a stated risk, not a silent gap |

The depth lives in the two control skills. This file only picks between them.

- **control-cli** drives terminal programs through Herdr panes. Harness loop, PTY fallback, profiling recipes.
- **control-ui** drives browser and Electron surfaces through `agent-browser`, falling back to CDP for CPU profiles, heap snapshots, and network throttling.

## Rules that hold on both

Reproduce a defect yourself on the surface before fixing it. Handing the repro to the user is the exception, taken only with a stated reason the harness cannot reach the target, and only after driving it as far as it goes.

Verify against the artifact, not a proxy (**principle-prove-it-works**). A passing test suite is not a driven feature. A screenshot of the wrong state is not evidence.

A project with no scripted path to its own behavior gets one built. That is what `/create-verification-skill` generates, tailored to the repo and its feature map.
