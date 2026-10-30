#!/usr/bin/env bash
# Opt-in experiment: two REAL T3 provider threads and native cross-thread messages.
# This does not install T3, configure accounts, or alter another service.
set -euo pipefail

if [ "$#" -ne 6 ] || [ "$1" != "--run" ]; then
  printf '%s\n' 'Usage: bash scripts/frontier-team-proof.sh --run PROJECT CLAUDE_INSTANCE CLAUDE_MODEL CODEX_INSTANCE CODEX_MODEL'
  printf '%s\n' 'First inspect provider IDs using T3 orchestrator_capabilities. Start with a disposable review-only project.'
  exit 2
fi

PROJECT="$2"
CLAUDE_INSTANCE="$3"
CLAUDE_MODEL="$4"
CODEX_INSTANCE="$5"
CODEX_MODEL="$6"

if [ ! -d "$PROJECT" ] || [ "$CLAUDE_INSTANCE" = "$CODEX_INSTANCE" ]; then
  printf '%s\n' 'Refused: project directory missing or provider instance IDs are identical.' >&2
  exit 2
fi

command -v python3 >/dev/null 2>&1 || { echo 'Python 3 required to parse T3 JSON'; exit 2; }

# Use the fork's source CLI (Node 26 in vp dev) when T3_CLI_JS is provided;
# otherwise use an installed t3 command. Never eval a user-supplied command.
CLI=(t3)
if [ -n "${T3_CLI_JS:-}" ]; then
  command -v node >/dev/null 2>&1 || { echo 'Node required for T3_CLI_JS'; exit 2; }
  [ -f "$T3_CLI_JS" ] || { echo 'T3_CLI_JS does not name a file'; exit 2; }
  CLI=(node "$T3_CLI_JS")
else
  command -v t3 >/dev/null 2>&1 || { echo 'T3 CLI not installed. Use T3_CLI_JS for source development.'; exit 2; }
fi
BASE_ARGS=()
if [ -n "${T3_BASE_DIR:-}" ]; then
  BASE_ARGS=(--base-dir "$T3_BASE_DIR")
fi

# Old official releases do not support a per-thread permission flag.
# Fail closed before creating even the first provider thread.
HELP="$("${CLI[@]}" thread start "${BASE_ARGS[@]}" --help 2>&1 || true)"
if ! grep -q -- '--permission' <<< "$HELP"; then
  echo 'This T3 CLI lacks --permission. Use the updated personal-fork CLI.' >&2
  exit 2
fi

RUN_DIR="$(mktemp -d "/tmp/t3-frontier-team-XXXXXXXX")"
chmod 700 "$RUN_DIR"
printf 'Pilot receipt directory: %s\n' "$RUN_DIR"

CLAUDE_PROMPT='You are the actual Claude Code provider in a bounded two-frontier-model experiment. Answer READY_CLAUDE, then stop. On a later instruction you will send ONE specific critique question to a Codex peer using the native T3 t3_thread_send MCP tool, read the response, and answer its counterquestion in your own thread. No source edits, no unbounded conversation loops, no impersonation.'
CLAUDE_JSON="$("${CLI[@]}" thread start "${BASE_ARGS[@]}" --json --permission approval-required --title "Frontier pilot: Claude" --provider "$CLAUDE_INSTANCE" --model "$CLAUDE_MODEL" "$PROJECT" "$CLAUDE_PROMPT")"
printf '%s\n' "$CLAUDE_JSON" > "$RUN_DIR/claude_launch.json"
CLAUDE_THREAD="$(printf '%s' "$CLAUDE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["threadId"])')"
printf 'Claude thread: %s\n' "$CLAUDE_THREAD"

CODEX_PROMPT="You are an independently authenticated Codex provider in a frontier-team experiment. Your peer is Claude thread $CLAUDE_THREAD. Answer READY_CODEX, then stop. When a later T3 peer message arrives, respond in your own thread and send exactly ONE concrete counterquestion to Claude through the native t3_thread_send MCP tool, using mode queue. Stop after the counterquestion. Do not edit files or impersonate Claude."
CODEX_JSON="$("${CLI[@]}" thread start "${BASE_ARGS[@]}" --json --permission approval-required --title "Frontier pilot: Codex" --provider "$CODEX_INSTANCE" --model "$CODEX_MODEL" "$PROJECT" "$CODEX_PROMPT")"
printf '%s\n' "$CODEX_JSON" > "$RUN_DIR/codex_launch.json"
CODEX_THREAD="$(printf '%s' "$CODEX_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["threadId"])')"
printf 'Codex thread: %s\n' "$CODEX_THREAD"

KICKOFF="This is the authorized frontier-team exchange test. The REAL Codex thread is $CODEX_THREAD. Use your T3-provided MCP t3_thread_send to send exactly ONE review question to that thread with mode queue. Ask Codex: 'In a multi-model collaboration system, how can we prove a reply came from an independent provider rather than a simulated agent?' Include your own thread ID $CLAUDE_THREAD and request one counterquestion in return. Do not use shell, copy/paste, or another transport for the message. When Codex's counterquestion arrives in this thread, answer it once. Do not send another cross-thread message. In your final reply provide the T3 tool receipts and any unresolved question."

printf '%s\n' "$KICKOFF" > "$RUN_DIR/kickoff.txt"
"${CLI[@]}" thread send "${BASE_ARGS[@]}" "$CLAUDE_THREAD" "$KICKOFF"

printf '\nLAUNCHED, NOT YET VERIFIED. Check T3 thread Activity for actual MCP send receipts.\n'
printf 'Claude: %s\nCodex: %s\n' "$CLAUDE_THREAD" "$CODEX_THREAD"
printf 'Inspect with the same CLI and base-dir: thread show --json %s\n' "$CLAUDE_THREAD"
printf 'Inspect with the same CLI and base-dir: thread show --json %s\n' "$CODEX_THREAD"
printf 'Receipt: %s\n' "$RUN_DIR"
printf 'Success requires independently attributed peer-tool calls and two completed turns.\n'
