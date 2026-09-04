#!/bin/bash
# Sticky-mode reminder for poteto-mode.
#
# Cursor keeps a mode skill active across turns with `mode: true` plus a
# `reminder:` frontmatter field. Claude Code has no such field, so this hook
# reproduces it. UserPromptSubmit fires on every prompt with no matcher, and
# text returned as hookSpecificOutput.additionalContext is added to the turn
# before the model sees the prompt.
#
# The reminder fires only while a marker file exists, so entering the mode is
# deliberate and opting out is one deletion. Without the marker this hook is a
# no-op, which is what keeps it from shouting into every unrelated session.
#
# Install by adding to settings.json:
#
#   "hooks": {
#     "UserPromptSubmit": [
#       { "matcher": "", "hooks": [
#         { "type": "command", "command": "<abs-path-to>/poteto-mode-reminder.sh" }
#       ]}
#     ]
#   }

set -euo pipefail

marker="${POTETO_MODE_MARKER:-${TMPDIR:-/tmp}/poteto-mode-active}"

[ -f "$marker" ] || exit 0

read -r -d '' reminder <<'TEXT' || true
poteto-mode is active. New task? Playbook match or rigor needed, apply /poteto-mode. Casual turn or the user opts out, don't.
TEXT

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}\n' \
  "$(printf '%s' "$reminder" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')"
