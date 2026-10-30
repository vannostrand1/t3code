#!/usr/bin/env bash
# Offline mock smoke test. Never calls real T3 or any paid model.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$(mktemp -d)"
trap 'rm -rf "$DIR"' EXIT
mkdir -p "$DIR/bin" "$DIR/project"
cat > "$DIR/bin/t3" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_LOG"
case "$*" in
  *--help*) echo 'Usage: t3 thread start --permission <mode>'; exit 0 ;;
  *'Frontier pilot: Claude'*) echo '{"threadId":"mock-claude","projectId":"mock-project","runId":"mock-run-c"}'; exit 0 ;;
  *'Frontier pilot: Codex'*) echo '{"threadId":"mock-codex","projectId":"mock-project","runId":"mock-run-x"}'; exit 0 ;;
  *'thread send '*)
    case "$*" in *'mock-claude'*) echo 'Queued.'; exit 0 ;; esac ;;
esac
echo "Unexpected mock T3 invocation: $*" >&2
exit 3
MOCK
chmod +x "$DIR/bin/t3"
export MOCK_LOG="$DIR/commands.log"
export PATH="$DIR/bin:$PATH"
: > "$MOCK_LOG"
bash -n "$REPO/scripts/frontier-team-proof.sh"
bash -n "$REPO/scripts/frontier-team-preflight.sh"
bash "$REPO/scripts/frontier-team-proof.sh" --run "$DIR/project" "claude-actual" "model-c" "codex-actual" "model-x" > "$DIR/output.txt"
grep -q 'LAUNCHED, NOT YET VERIFIED' "$DIR/output.txt"
grep -q 'Claude thread: mock-claude' "$DIR/output.txt"
grep -q 'Codex thread: mock-codex' "$DIR/output.txt"
test "$(grep -c -- '--permission approval-required' "$MOCK_LOG")" -eq 2
test "$(grep -c 'thread send' "$MOCK_LOG")" -eq 1
grep -q -- '--provider claude-actual --model model-c' "$MOCK_LOG"
grep -q -- '--provider codex-actual --model model-x' "$MOCK_LOG"

: > "$MOCK_LOG"
if bash "$REPO/scripts/frontier-team-proof.sh" --run "$DIR/project" same model-c same model-x > "$DIR/bad.txt" 2>&1; then
  echo 'Identical provider IDs were not rejected' >&2
  exit 1
fi
test ! -s "$MOCK_LOG"
echo 'Offline mock checks passed (not a live model test).'
