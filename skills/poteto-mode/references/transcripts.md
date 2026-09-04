# Finding transcripts

Several skills read past agent sessions. `recall` rebuilds working context, `reflect` reviews a run, `automate-me` mines working style, `session-pickup` resumes someone else's work, `eval` grades what a candidate actually read, and `show-me-your-work` audits its own log against what happened.

Every harness stores sessions differently. Find the file, never construct its path.

## Ask Herdr first

For any agent Herdr started, Herdr already knows where its session lives.

```bash
herdr agent list
```

Each entry carries `agent_session`, which is either a path (`kind: "path"`) or a session id (`kind: "id"`) plus the `cwd` and the agent kind. That beats searching, and it is the only method that works uniformly across kinds. Use it before falling back to the layouts below.

## Per-harness layouts

| Harness | Location | Shape |
|---|---|---|
| Claude Code | `~/.claude/projects/<slug>/<session-id>.jsonl` | One JSONL per session. `<slug>` is the working directory with each `/` replaced by `-` |
| Pi | `~/.pi/agent/sessions/<slug>/<timestamp>_<uuid>.jsonl` | One JSONL per session, under a slugified working directory |
| Codex | `~/.codex/sessions/<YYYY>/<MM>/<DD>/rollout-<timestamp>-<uuid>.jsonl` | One JSONL per session, partitioned by date with no project in the path |
| OpenCode | `~/.local/share/opencode/opencode.db` | SQLite, not files. Sessions and messages live in the `session`, `session_v2`, `session_message` and `message` tables |

Two of these need more than a glob. Codex partitions by date, so finding this project's sessions means reading each candidate's recorded working directory rather than matching a path. OpenCode needs SQL.

## Rules

**Order by modification time, never by name.** `ls -t`. UUID and timestamp names do not sort into recency in the way you want, and the newest chat is usually the one you need.

```bash
ls -t <session-dir>/*.jsonl | head -10
```

**Confirm the file before you read it.** Read the first line and check that the opening user message matches the conversation you are looking for. When nothing resolves, write a tight digest of the session and pass that instead of guessing.

**Scope to this project.** Never sweep every project directory. That reads private chats from unrelated work. Scope by the current working directory's slug, and when the harness does not encode one, filter candidates by their recorded working directory instead.

**Grep before reading.** Transcripts are large. Search for the topic first, then read only the matching sessions and only their relevant regions. Hand the reading to delegates and keep their findings, not the raw payloads, in the main thread (**principle-guard-the-context-window**).

**A transcript is history, not current truth.** Verify anything actionable against live state with `git` and `gh` before acting on it.
