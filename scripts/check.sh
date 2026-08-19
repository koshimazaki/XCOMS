#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

unset XREVIEW_ENGINE XREVIEW_CLAUDE_MODEL XREVIEW_CLAUDE_EFFORT \
  XREVIEW_SKILL_PATH XREVIEW_REQUIRE_CLAUDE CLAUDE_BIN

expect_output() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -q "$pattern" <<<"$output"; then
    echo "xcoms checks: missing $label" >&2
    exit 1
  fi
}

bash -n xreview
bash -n install.sh
./xreview --version | grep -qx 'xreview 2.0.0'
HELP_OUTPUT="$(./xreview --help)"
expect_output "$HELP_OUTPUT" 'Mechanical Test Contract' 'mechanical help text'

if ./xreview --mode >/dev/null 2>&1; then
  echo 'xcoms checks: missing --mode value was accepted' >&2
  exit 1
fi

CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xcoms-check.XXXXXX")"
cleanup() {
  rm -rf "$CHECK_DIR"
}
trap cleanup EXIT

mkdir -p "$CHECK_DIR/bin" "$CHECK_DIR/repo"
./install.sh "$CHECK_DIR/bin" >/dev/null
git -C "$CHECK_DIR/repo" init -q

DRY_RUN_OUTPUT="$(
  cd "$CHECK_DIR/repo"
  PATH="/usr/bin:/bin" XREVIEW_ENGINE=codex \
    "$CHECK_DIR/bin/xreview" --dry-run --mode docs 2>&1
)"
expect_output "$DRY_RUN_OUTPUT" 'dry-run: would spawn terminal-backed codex reviewer' 'Codex dry-run engine'
expect_output "$DRY_RUN_OUTPUT" 'would run -> codex review --commit HEAD' 'Codex HEAD scope'

DRY_RUN_OUTPUT="$(
  cd "$CHECK_DIR/repo"
  "$CHECK_DIR/bin/xreview" --dry-run --working --mode docs 2>&1
)"
expect_output "$DRY_RUN_OUTPUT" 'dry-run: would spawn terminal-backed claude reviewer' 'Claude dry-run engine'
expect_output "$DRY_RUN_OUTPUT" 'model: opus' 'default Opus model'

RANGE_OUTPUT="$(./xreview --dry-run HEAD~1..HEAD --mode deep 2>&1)"
expect_output "$RANGE_OUTPUT" 'dry-run: would spawn terminal-backed claude reviewer' 'Claude range routing'

DRY_RUN_OUTPUT="$(
  cd "$CHECK_DIR/repo"
  "$CHECK_DIR/bin/xreview" --dry-run 'src/my dir' --mode docs 2>&1
)"
expect_output "$DRY_RUN_OUTPUT" 'scope: src/my\\ dir' 'quoted path scope'

mkdir -p "$CHECK_DIR/repo/src"
printf 'untracked fixture\n' > "$CHECK_DIR/repo/src/new-file.txt"
UNTRACKED_OUTPUT="$(
  cd "$CHECK_DIR/repo"
  PATH="/usr/bin:/bin" XREVIEW_ENGINE=claude \
    "$CHECK_DIR/bin/xreview" src/new-file.txt 2>&1 || true
)"
if grep -q 'nothing to review' <<<"$UNTRACKED_OUTPUT"; then
  echo 'xcoms checks: explicit untracked path was skipped as empty' >&2
  exit 1
fi
rm -f "$CHECK_DIR/repo/src/new-file.txt"
rmdir "$CHECK_DIR/repo/src"

if XREVIEW_ENGINE=codex ./xreview --dry-run --working >/dev/null 2>&1; then
  echo 'xcoms checks: Codex accepted an inexact working-only scope' >&2
  exit 1
fi

if ./xreview --mode 'bad;mode' >/dev/null 2>&1; then
  echo 'xcoms checks: unsafe mode name was accepted' >&2
  exit 1
fi

if ./xreview --unknown-option >/dev/null 2>&1; then
  echo 'xcoms checks: unknown option was accepted' >&2
  exit 1
fi

if ./xreview --staged --working >/dev/null 2>&1; then
  echo 'xcoms checks: conflicting exact scopes were accepted' >&2
  exit 1
fi

EMPTY_OUTPUT="$(
  cd "$CHECK_DIR/repo"
  "$CHECK_DIR/bin/xreview" --staged --mode lite 2>&1
)"
expect_output "$EMPTY_OUTPUT" 'nothing to review' 'empty staged short-circuit'

cat > "$CHECK_DIR/bin/codex" <<'MOCK_CODEX'
#!/usr/bin/env bash
printf 'mock codex review: %s\n' "$*"
MOCK_CODEX
chmod +x "$CHECK_DIR/bin/codex"

MOCK_OUTPUT="$(
  cd "$CHECK_DIR/repo"
  PATH="$CHECK_DIR/bin:$PATH" XREVIEW_ENGINE=codex \
    XREVIEW_LOG_DIR="$CHECK_DIR/logs" \
    "$CHECK_DIR/bin/xreview" --headless --mode lite 2>&1
)"
expect_output "$MOCK_OUTPUT" 'mock codex review: review --commit HEAD' 'headless Codex invocation'
expect_output "$MOCK_OUTPUT" 'Use the xreview skill at' 'Codex skill prompt'
expect_output "$MOCK_OUTPUT" 'Mode: lite' 'Codex mode prompt'

(
  cd "$CHECK_DIR/repo"
  PATH="$CHECK_DIR/bin:$PATH" XREVIEW_ENGINE=codex \
    XREVIEW_LOG_DIR="$CHECK_DIR/logs" \
    "$CHECK_DIR/bin/xreview" --headless --mode lite >/dev/null 2>&1
)

DONE_FILES=("$CHECK_DIR/logs/"*.done)
if [[ ${#DONE_FILES[@]} -ne 2 ]]; then
  echo 'xcoms checks: per-run completion markers were not preserved' >&2
  exit 1
fi
for done_file in "${DONE_FILES[@]}"; do
  if ! grep -qx '0' "$done_file"; then
    echo 'xcoms checks: completion marker did not preserve exit status' >&2
    exit 1
  fi
  if ! grep -q 'mock codex review' "${done_file%.done}"; then
    echo 'xcoms checks: review log did not preserve output' >&2
    exit 1
  fi
done

git diff --check
git diff --cached --check
echo 'xcoms checks: ok'
