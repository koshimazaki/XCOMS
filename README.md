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

`xreview` hands the current git diff to a second agent — Codex
(default, `gpt-5.5` xhigh) or Claude (`--effort max`) — running in a
fresh context. Because the reviewer has not been exposed to the
builder's reasoning, the builder's confirmation bias does not carry
into the review, and genuine issues surface that a self-review would
otherwise miss.

The reviewer spawns in a separate terminal window with a labelled
profile, streams output to `.agent-handoff/`, and signals completion
via a sentinel file. The caller blocks until the verdict is ready.

Made for [SIDKIT](https://github.com/sidkit-org) — an AI-native
audio-game console — and extendable to any project, any language.
See [`docs/documentation.md`](docs/documentation.md) for the full
reference.

## Install

```sh
git clone https://github.com/koshimazaki/Codex-x-Claude-Review-System.git
cd Codex-x-Claude-Review-System
./install.sh                       # → ~/.local/bin/xreview
```

The tool is also bundled inside SIDKIT — see
[`docs/documentation.md`](docs/documentation.md) for that path and
other install options.

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

## Documentation

[`docs/documentation.md`](docs/documentation.md) — full reference for
install paths, environment variables, terminal labelling, platform
support, custom prompt modes, reviewer CLI setup, exit codes, and the
spawn architecture.

## Origin

Born inside SIDKIT — a text-to-hardware generative sound platform for Teensy
4.1 — where the cost of a missed audio-ISR-safety violation is "no
sound" and the cost of a missed PCB DRC violation is "fab errata".
Fresh-context review caught a real 3-bit-mask bug *twice* (firmware
side, then WebUI side after the firmware fix) that the implementer had
already convinced themselves was correct. That's the value.

Part of the [SIDKIT](https://github.com/sidkit-org) ecosystem
([sidkit.org](https://sidkit.org)). If it helps your
project too, fork the prompts. If you build a prompt template for
your stack, PR it back.

## License

MIT.
