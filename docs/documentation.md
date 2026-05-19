# xreview — full documentation

Reference docs for `xreview`. The [README](../README.md) covers the
quick-start path; this page goes deep on installation, environment,
extending the tool, platform support, and how the spawn pipeline
works.

**Contents**

- [Install](#install) — all install paths (standalone, SIDKIT-bundled, custom prefix, uninstall)
- [Reviewer CLIs](#reviewer-clis) — installing Codex / Claude
- [Terminal window labelling](#terminal-window-labelling)
- [Platform support](#platform-support)
- [Environment variables](#environment-variables)
- [Extending to your domain](#extending-to-your-domain)
- [Exit codes](#exit-codes)
- [Examples](#examples) — pre-commit hook, CI
- [How it works](#how-it-works)

## Install

### Standalone

```sh
git clone https://github.com/koshimazaki/Codex-x-Claude-Review-System.git
cd Codex-x-Claude-Review-System
./install.sh                       # → ~/.local/bin/xreview
```

### Bundled inside SIDKIT

The tool was born inside SIDKIT and ships there as a bundled copy:

```sh
git clone https://github.com/koshimazaki/SIDKIT
cd SIDKIT/codex-claude-review
./install.sh
```

### Custom prefix

```sh
./install.sh /usr/local/bin
```

### Uninstall

```sh
./install.sh --uninstall
```

Removes `xreview` from `~/.local/bin`, `/usr/local/bin`, and `~/bin`
(whichever paths it finds it in).

## Reviewer CLIs

**Codex** (default — `gpt-5.5`, `model_reasoning_effort=xhigh`):

```sh
brew install --cask codex          # macOS
# Linux/Windows: https://github.com/openai/codex
```

If Codex.app is installed but not on PATH:

```sh
ln -s /Applications/Codex.app/Contents/Resources/codex ~/bin/codex
```

**Claude** (`--effort max`):

```sh
# https://github.com/anthropics/claude-code
REVIEW_REVIEWER=claude xreview commit lite
```

## Terminal window labelling

Every spawned window gets a title via OSC-0 escape (works on
Terminal.app, iTerm2, gnome-terminal, konsole, wezterm, kitty,
alacritty, xterm, Windows Terminal, tmux):

```
LITE · last commit (HEAD~1..HEAD)
DEEP · range f90a832^..b022db9
SECURITY · branch (main...HEAD)
FIRMWARE-C · commit 8a3e4cd
PCB · path: PCB-Design/projects/sidkit-main
```

On macOS the script also flips the Terminal.app profile so the dock
icon is glanceable. Linux/Windows terminals vary too much for portable
profile control — the title alone covers the use case.

## Platform support

| OS | Spawn | Title | Profile/colour |
|----|-------|-------|----------------|
| macOS | `osascript` → Terminal.app | ✓ | ✓ (named profile) |
| Linux | gnome-terminal / konsole / wezterm / kitty / alacritty / xterm / tmux | ✓ | configure your terminal's defaults |
| Windows (Git Bash/WSL/MSYS) | `wt.exe` → Windows Terminal, fallback `cmd start` | ✓ | configure your WT profile |
| Headless / no GUI | inline foreground | n/a | n/a |

Bash-only — no Python/Node/PowerShell dependency. The whole tool is
one script + a few markdown prompts.

## Environment variables

| Variable | Default | Meaning |
|----------|---------|---------|
| `REVIEW_BASE` | `main` | base branch for `branch` scope |
| `REVIEW_DIFF_CAP` | `3000` | max diff lines fed to reviewer |
| `REVIEW_REVIEWER` | `codex` | `codex` or `claude` |
| `REVIEW_PROMPTS_DIR` | `<script>/prompts` | override prompt directory |
| `REVIEW_HANDOFF_DIR` | `<repo>/.agent-handoff` | input/output dir |

## Extending to your domain

The tool ships with five prompt modes — three generic (`lite`, `deep`,
`security`) and two SIDKIT-flavoured (`firmware-c`, `pcb`). To add your
own:

```sh
cat > ~/.config/xreview/prompts/rust-async.md <<'EOF'
Fresh-context review — Rust async / tokio mode.

Focus on: send/sync bounds on spawn(), missing .await, channel
back-pressure, cancellation safety, Arc<Mutex> contention hot-spots,
Pin/Unpin invariants on hand-rolled futures, dropping JoinHandle.

End with: ## Verdict: <SHIP | MERGE-WITH-FOLLOWUPS | NEEDS-CHANGES>
EOF

REVIEW_PROMPTS_DIR=~/.config/xreview/prompts xreview commit rust-async
```

PRs welcome — submit your prompt template (Go-concurrency, K8s-yaml,
SwiftUI-state, etc.) and we'll add it to the bundle.

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | OK |
| 2 | Bad arguments / not in a git repo |
| 3 | Reviewer CLI not found |
| 4 | Filesystem error (chmod, write) |
| 5 | Terminal spawn failed (manually `bash <runner.sh>`) |
| 6 | Reviewer timed out |
| 7 | Reviewer exited non-zero or produced no verdict |

## Examples

- **`examples/pre-commit-review.sh`** — block a commit on `NEEDS-CHANGES`.
- **CI integration** — drop into a GitHub Actions step. The current
  spawn logic needs a TTY; for fully headless CI, set
  `REVIEW_HEADLESS=1` (TODO: not yet implemented; PRs welcome).

## How it works

```
xreview <scope> <mode>
   │
   ├── resolve scope (branch / commit / staged / range / sha / path)
   ├── load prompts/<mode>.md (fallback: inline default)
   ├── write input file with prompt + capped diff
   ├── write runner.sh (sets terminal title + runs reviewer + touches sentinel)
   ├── spawn terminal (osascript / gnome-terminal / wt.exe / tmux / inline)
   ├── poll sentinel until reviewer exits (mode-specific timeout)
   └── extract `## Verdict` section, print, exit
```

The runner heredoc is reviewer-agnostic — swap `codex exec …` for any
CLI that takes a prompt argument. See `xreview` itself for the
`REVIEWER_CMD` array.
