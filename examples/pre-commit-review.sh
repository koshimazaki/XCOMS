#!/usr/bin/env bash
# pre-commit-review.sh — block a commit on a NEEDS-CHANGES verdict
#
# Drop into .git/hooks/pre-commit (chmod +x) to gate every commit on a
# lite review of the staged changes. Set XREVIEW_PREHOOK_SKIP=1 to bypass
# (e.g. for emergency hotfixes).
#
# Caveat: lite mode still takes 10-20 min — this is more useful as a
# pre-push hook than pre-commit. For pre-commit, prefer a fast linter and
# leave xreview for pre-push.

set -euo pipefail

if [ "${XREVIEW_PREHOOK_SKIP:-0}" = "1" ]; then
  echo "[xreview] skipped via XREVIEW_PREHOOK_SKIP=1"
  exit 0
fi

if ! command -v xreview >/dev/null 2>&1; then
  echo "[xreview] not installed — skipping pre-commit review"
  exit 0
fi

# Run xreview and capture both its output AND its real exit code.
# Without `set -o pipefail` + PIPESTATUS, the `| tee` swallows xreview's
# exit code and a crashed reviewer would look like a clean review.
set -o pipefail
OUT=$(xreview staged lite 2>&1 | tee /dev/tty)
XRC=${PIPESTATUS[0]}

if [ "$XRC" -eq 7 ]; then
  echo
  echo "[xreview] reviewer crashed or produced no verdict — aborting commit."
  echo "Bypass with: XREVIEW_PREHOOK_SKIP=1 git commit ..."
  exit 1
elif [ "$XRC" -ne 0 ]; then
  echo
  echo "[xreview] failed (exit $XRC) — aborting commit."
  exit "$XRC"
fi

if echo "$OUT" | grep -q '## Verdict: NEEDS-CHANGES'; then
  echo
  echo "[xreview] NEEDS-CHANGES verdict — aborting commit."
  echo "Bypass with: XREVIEW_PREHOOK_SKIP=1 git commit ..."
  exit 1
fi

exit 0
