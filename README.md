```bash
 ██████╗ ██████╗ ██████╗ ███████╗██╗  ██╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝╚██╗██╔╝
██║     ██║   ██║██║  ██║█████╗   ╚███╔╝ 
██║     ██║   ██║██║  ██║██╔══╝   ██╔██╗ 
╚██████╗╚██████╔╝██████╔╝███████╗██╔╝ ██╗
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                    ×
 ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
██║     ██║     ███████║██║   ██║██║  ██║█████╗  
██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  
╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝
░░░█ Fresh-context cross-agent code reviewer █░░░
░░ v0.1
```

# codex-claude-review (`xreview`)

> A cross-platform, cross-agent fresh-context code reviewer.
> Built for [SIDKIT](https://sidkit.pages.dev) firmware + PCB review;
> generalizable to any git repo and any language.

Hands the current git diff to **Codex** (default, `gpt-5.5` xhigh) or
**Claude** (`--effort max`) for a *fresh-context* review — the reviewer
hasn't seen the builder's conversation, so it catches what the
programmer's confirmation bias missed.

The reviewer spawns in a **separate terminal window** with a labelled,
colour-keyed profile so you can see at a glance which review is which.
Output streams to disk in `.agent-handoff/` and the caller blocks on a
sentinel file until the verdict is ready.

**Why this exists.** SIDKIT is real-time embedded C++ on Teensy 4.1 +
4-bit greyscale OLED + custom PCB. Audio-ISR safety, FASTRUN coverage,
KiCad audit-report freshness, and SysEx 7-bit-byte constraints are
mistakes you only catch if you read the code *without* the builder's
"trust me" voice in your head. Fresh-context review is the cheapest way
to get that voice out of the room.

The framework is reviewer-agnostic and language-agnostic — only the
*prompts* are domain-specific, and they live in `prompts/` so you can
fork them for your stack.

## Install

```sh
# Standalone
git clone https://github.com/koshimazaki/Codex-x-Claude-Review-System.git
cd Codex-x-Claude-Review-System
./install.sh                       # → ~/.local/bin/xreview
```

Or use the copy bundled inside SIDKIT (canonical home for now):

```sh
git clone https://github.com/koshimazaki/SIDKIT
cd SIDKIT/codex-claude-review
./install.sh
```

Custom prefix:

```sh
./install.sh /usr/local/bin
```

Uninstall:

```sh
./install.sh --uninstall
```

**Requires:** `bash 4+`, `git`, and one of:
- [`codex`](https://github.com/openai/codex) (Codex.app on macOS)
- [`claude`](https://github.com/anthropics/claude-code)

## Quick start

From inside any git repo:

```sh
xreview                            # branch (main...HEAD), auto-deep
xreview commit                     # last commit, lite
xreview staged                     # staged changes, lite
xreview b022db9                    # single SHA, lite
xreview range:f90a832^..b022db9    # arbitrary range
xreview src/audio                  # path
xreview commit deep                # force deep mode
xreview branch security            # OWASP / supply-chain audit
xreview commit firmware-c          # SIDKIT firmware patterns
xreview branch pcb                 # KiCad / schematic patterns
xreview commit lite "Focus on ISR safety only."
```

## Scope

| Form | Diff |
|------|------|
| `branch` *(default)* | `git diff $REVIEW_BASE...HEAD` (default base: `main`) |
| `commit` | `git diff HEAD~1..HEAD` |
| `staged` | `git diff --cached` |
| `range:A..B` | `git diff A..B` |
| `<sha>` (6–40 hex, must exist) | `git diff <sha>^..<sha>` |
| anything else | `git diff HEAD -- <path>` |

## Mode

Mode = which prompt template to load. Auto-pick: `lite` for
commit/sha/staged, `deep` for branch/path.

| Mode | Output | Timeout | macOS profile |
|------|--------|---------|---------------|
| `lite` | ~500-word HIGH-only | 20 min | Grass (green) |
| `deep` | Full risk register | 50 min | Homebrew (green-on-black) |
| `security` | OWASP / supply-chain | 40 min | Red Sands (red) |
| `firmware-c` | Embedded C++ / RTOS / ISR safety | 50 min | Homebrew |
| `pcb` | KiCad / schematic / BOM | 40 min | Pro (blue) |

Add your own: drop `prompts/<mode>.md` (or set `REVIEW_PROMPTS_DIR` to
an external dir).

## Terminal window labelling

Every spawned window gets a title via OSC-0 escape (works on Terminal.app,
iTerm2, gnome-terminal, konsole, wezterm, kitty, alacritty, xterm, Windows
Terminal, tmux):

```
LITE · last commit (HEAD~1..HEAD)
DEEP · range f90a832^..b022db9
SECURITY · branch (main...HEAD)
FIRMWARE-C · commit 8a3e4cd
PCB · path: PCB-Design/projects/sidkit-main
```

On macOS the script also flips the Terminal.app profile so the dock icon
is glanceable. Linux/Windows terminals vary too much for portable
profile control — the title alone covers the use case.

## Platform support

| OS | Spawn | Title | Profile/colour |
|----|-------|-------|----------------|
| macOS | `osascript` → Terminal.app | ✓ | ✓ (named profile) |
| Linux | gnome-terminal / konsole / wezterm / kitty / alacritty / xterm / tmux | ✓ | configure your terminal's defaults |
| Windows (Git Bash/WSL/MSYS) | `wt.exe` → Windows Terminal, fallback `cmd start` | ✓ | configure your WT profile |
| Headless / no GUI | inline foreground | n/a | n/a |

Bash-only — no Python/Node/PowerShell dependency. The whole tool is one
script + a few markdown prompts.

## Environment

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

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | OK |
| 2 | Bad arguments / not in a git repo |
| 3 | Reviewer CLI not found |
| 4 | Filesystem error (chmod, write) |
| 5 | Terminal spawn failed (manually `bash <runner.sh>`) |
| 6 | Reviewer timed out |

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

## Origin

Born inside SIDKIT — a text-to-hardware generative sound platform for Teensy
4.1 — where the cost of a missed audio-ISR-safety violation is "no
sound" and the cost of a missed PCB DRC violation is "fab errata".
Fresh-context review caught a real 3-bit-mask bug *twice* (firmware
side, then WebUI side after the firmware fix) that the implementer had
already convinced themselves was correct. That's the value.

If it helps your project too, fork the prompts. If you build a prompt
template for your stack, PR it back.

## License

MIT.
