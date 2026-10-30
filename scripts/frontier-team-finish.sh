#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/Developer/t3code"
. "$HOME/.config/vite-plus/env"
STATE="$HOME/Developer/t3-frontier-state"
PILOT="$HOME/Developer/t3-frontier-pilot"
mkdir -p "$STATE/frontier-receipts"
REPORT="$STATE/frontier-receipts"
chmod 700 "$REPORT"
cli() { node apps/server/src/bin.ts "$@"; }
caps() { cli thread capabilities --base-dir "$STATE" --json > "$REPORT/capabilities.json" 2>"$REPORT/error.txt"; }

if ! caps; then
  echo "Starting isolated T3 developer server."
  nohup env T3CODE_DEV_SEED=0 vp run dev --home-dir "$STATE" > "$REPORT/dev.log" 2>&1 < /dev/null &
  ready=0
  for i in $(seq 1 40); do
    if caps; then ready=1; break; fi
    sleep 3
  done
  if [ "$ready" != 1 ]; then
    echo "T3 did not start. See $REPORT/dev.log"
    exit 2
  fi
fi

if command -v claude >/dev/null 2>&1 && ! claude auth status >/dev/null 2>&1; then
  claude auth login
fi
if command -v codex >/dev/null 2>&1 && ! codex login status >/dev/null 2>&1; then
  codex login
fi

ok=0
for i in $(seq 1 10); do
  caps
  if python3 scripts/frontier-team-select.py "$REPORT/capabilities.json" "$REPORT/providers.txt"; then
    ok=1
    break
  fi
  sleep 5
done
if [ "$ok" != 1 ]; then
  echo "T3 does not report both authenticated provider instances. Correct T3 provider setup and rerun."
  exit 2
fi
CLAUDE_ID="$(sed -n '1p' "$REPORT/providers.txt")"
CLAUDE_MODEL="$(sed -n '2p' "$REPORT/providers.txt")"
CODEX_ID="$(sed -n '3p' "$REPORT/providers.txt")"
CODEX_MODEL="$(sed -n '4p' "$REPORT/providers.txt")"
printf 'Claude: %s / %s\nCodex: %s / %s\n' "$CLAUDE_ID" "$CLAUDE_MODEL" "$CODEX_ID" "$CODEX_MODEL"

if [ ! -e "$PILOT" ]; then
  mkdir -p "$PILOT"
  git -C "$PILOT" init -q
  printf 'Disposable read-only AI collaboration pilot.\n' > "$PILOT/README.md"
  git -C "$PILOT" add README.md
  git -C "$PILOT" -c user.name="T3 Pilot" -c user.email="pilot@local.invalid" commit -qm init
fi
if [ ! -d "$PILOT/.git" ]; then
  echo "Pilot project exists and is not a Git checkout: $PILOT"
  exit 2
fi
if ! cli thread list --base-dir "$STATE" --project "$PILOT" >/dev/null 2>&1; then
  cli project add --base-dir "$STATE" --title "Frontier Team Pilot" "$PILOT"
fi
if cli thread list --base-dir "$STATE" --project "$PILOT" | grep -q "Frontier pilot:"; then
  echo "Pilot threads already exist. Refusing duplicate paid provider runs."
  exit 2
fi

export T3_CLI_JS="$PWD/apps/server/src/bin.ts"
export T3_BASE_DIR="$STATE"
bash scripts/frontier-team-proof.sh --run "$PILOT" "$CLAUDE_ID" "$CLAUDE_MODEL" "$CODEX_ID" "$CODEX_MODEL" | tee "$REPORT/launch.txt"
C="$(sed -n 's/^Claude thread: //p' "$REPORT/launch.txt" | tail -n 1)"
X="$(sed -n 's/^Codex thread: //p' "$REPORT/launch.txt" | tail -n 1)"
if [ -z "$C" ] || [ -z "$X" ]; then exit 2; fi

for i in $(seq 1 30); do
  cli thread activity --base-dir "$STATE" --json "$C" > "$REPORT/claude.json"
  cli thread activity --base-dir "$STATE" --json "$X" > "$REPORT/codex.json"
  if python3 scripts/frontier-team-verify.py "$REPORT/claude.json" "$REPORT/codex.json" "$C" "$X" > "$REPORT/result.json"; then
    cat "$REPORT/result.json"
    echo "VERIFIED: two different providers exchanged durable MCP peer messages."
    exit 0
  fi
  sleep 10
done
cat "$REPORT/result.json" 2>/dev/null || true
echo "Peer exchange not yet verified. Examine T3 activity; receipts: $REPORT"
exit 2
