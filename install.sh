#!/usr/bin/env bash
# install.sh — drop xreview into your shell PATH
#
# Default install location is ~/.local/bin (which most shells already have
# in PATH; if not, the installer prints the export line you need).
#
# Usage:
#   ./install.sh                   # default: ~/.local/bin/xreview
#   ./install.sh /usr/local/bin    # custom prefix
#   ./install.sh --uninstall

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/xreview"

PREFIX_DEFAULT="$HOME/.local/bin"
PREFIX="${1:-$PREFIX_DEFAULT}"

if [ "${1:-}" = "--uninstall" ]; then
  for p in "$HOME/.local/bin/xreview" "/usr/local/bin/xreview" "$HOME/bin/xreview"; do
    if [ -L "$p" ] || [ -f "$p" ]; then
      echo "Removing $p"
      rm -f "$p"
    fi
  done
  exit 0
fi

if [ ! -x "$SOURCE" ]; then
  chmod +x "$SOURCE" || { echo "ERR: cannot make $SOURCE executable" >&2; exit 1; }
fi

mkdir -p "$PREFIX"
DEST="$PREFIX/xreview"

# Prefer symlink so users get updates by `git pull` in this repo. The
# script auto-resolves the symlink target and finds prompts/ alongside
# the real file — no copy needed in the common case.
if ln -sf "$SOURCE" "$DEST" 2>/dev/null; then
  echo "Installed: $DEST -> $SOURCE"
else
  # Symlink failed (read-only fs / no privilege / Windows without
  # developer mode). Fall back to a hard copy of the WHOLE TREE into a
  # share-style location so prompts/ stays beside xreview. Build a
  # wrapper at the bin path that points at the share copy.
  SHARE_DIR="${REVIEW_SHARE_DIR:-$HOME/.local/share/xreview}"
  mkdir -p "$SHARE_DIR"
  cp "$SOURCE" "$SHARE_DIR/xreview"
  chmod +x "$SHARE_DIR/xreview"
  if [ -d "$SCRIPT_DIR/prompts" ]; then
    cp -R "$SCRIPT_DIR/prompts" "$SHARE_DIR/"
  fi
  cat > "$DEST" <<WRAPPER_EOF
#!/usr/bin/env bash
exec "$SHARE_DIR/xreview" "\$@"
WRAPPER_EOF
  chmod +x "$DEST"
  echo "Installed (copied): tree → $SHARE_DIR, wrapper → $DEST"
fi

# Check PATH
case ":$PATH:" in
  *":$PREFIX:"*)
    echo "PATH already contains $PREFIX — try: xreview --help"
    ;;
  *)
    echo
    echo "NOTE: $PREFIX is not in PATH. Add this to your shell rc:"
    echo "      export PATH=\"$PREFIX:\$PATH\""
    ;;
esac

# Sanity check reviewer CLIs
echo
echo "Reviewer CLI check:"
if command -v codex >/dev/null 2>&1 || [ -x "/Applications/Codex.app/Contents/Resources/codex" ]; then
  echo "  codex   ✓"
else
  echo "  codex   ✗ (install Codex.app or symlink: ln -s /Applications/Codex.app/Contents/Resources/codex ~/bin/codex)"
fi
if command -v claude >/dev/null 2>&1; then
  echo "  claude  ✓"
else
  echo "  claude  ✗ (optional — only needed for REVIEW_REVIEWER=claude)"
fi

echo
echo "Try: xreview commit lite"
