# X Communications — contracts and `xreview` v2

X Communications, shortened to **XComs**, is a small vocabulary for agent
coordination. It does not require a particular database, message broker,
runtime, or user interface.

The split is intentional:

1. **Verbs** describe an action: review, hand over, or return.
2. **XCOM** carries packets and receipts and owns delivery state.
3. **Adapters** translate those contracts into a runtime's native CLI or task
   interface.

Keeping these layers separate makes the same workflow adoptable without
publishing machine-specific paths, account details, or private infrastructure.

## Component contracts

### `xreview` — judge

`xreview` launches one fresh reviewer against an explicit Git scope. The
reviewer reads the repository's own instructions, inspects surrounding code,
and reports only high-confidence, actionable findings. It never inherits the
builder's conversation.

Contract:

- resolve the requested scope before judging it;
- use one fresh reviewer unless the caller explicitly asks for more;
- remain read-only;
- report findings before summaries, with file and line evidence;
- keep a deterministic log that the caller can read after the session exits;
- support repository-local review rules without making them global defaults.

### `xcom` — carry

XCOM is the communication plane. It carries bounded task packets, receipts,
and references to larger artifacts between runtimes. The storage and delivery
implementation is deliberately not part of this public reference: adopters can
use the local or hosted mechanism they already trust.

The important boundary is simple: packets describe the work, while local
paths, credentials, provider IDs, and native task IDs remain with the host.

### `xtask` — hand over

`xtask` moves one converged topic into a fresh visible session. It is a
spin-off, not a clone of the originating conversation.

Its packet must stand alone and contain:

- the objective and why it matters;
- decisions already made and their rationale;
- relevant artifact or revision references;
- explicit exclusions;
- the first concrete action;
- completion conditions and a stop rule.

The sender owns curation because it knows which context is load-bearing. The
receiver should not need access to the source conversation.

### `xreturn` — run and return

`xreturn` uses the same bounded packet as `xtask`, but launches the destination
headlessly and brings its receipt back to the caller.

Contract:

- consume a packet at most once;
- run in the destination's own repository context;
- capture full output as an artifact and return a compact receipt;
- propagate the real process result;
- distinguish provider or quota failure from a defect in the work;
- time out or report a stall instead of waiting forever.

Use `xtask` when a person should continue in the new session. Use `xreturn`
when the originating agent should wait for and consume the result.

### X Adapter — connect

An X Adapter maps the portable contracts onto one runtime. Examples include a
CLI launcher, a native task-creation API, or a desktop integration.

An adapter may own:

- project and runtime lookup;
- worktree or branch placement;
- native task creation and task IDs;
- rendering a validated packet as the destination's opening prompt.

It must not own XCOM delivery state or silently expand the packet's scope. A
native UI adapter should create one visible task for one approved packet and
confirm that the task actually started.

## `xreview` v2 reference

### Scope

```sh
xreview                         # dirty working tree, otherwise HEAD
xreview HEAD                    # one commit
xreview 709558d                 # one commit by SHA
xreview HEAD~3..HEAD            # range
xreview --staged                # staged changes
xreview --working               # unstaged changes
xreview --pr 123                # pull request via GitHub CLI
xreview src/parser              # path-limited review
```

Use `--scope <name>` to add a repository-defined focus label. Global modes are
`lite`, `mid`, `deep`, `security`, and `docs`. A repository can add a local
`xreview` skill for framework- or domain-specific rules.

### Reviewer selection

```sh
XREVIEW_ENGINE=claude xreview HEAD --mode deep
XREVIEW_ENGINE=codex xreview HEAD --mode lite
```

When invoked from a Codex shell, the launcher chooses Claude for a cross-agent
check. Outside Codex it chooses Codex. If Claude was selected automatically but
is unavailable, an ordinary review can fall back to Codex; an explicitly
Claude-only run fails instead of pretending the proof happened.

Pull requests, path filters, staged-only diffs, working-only diffs, ranges,
mechanical passes, and combined revision/path scopes automatically select
Claude because the `codex review` CLI does not expose those exact scopes.

Claude runs default to `opus` at `max` effort:

```sh
XREVIEW_CLAUDE_MODEL=opus XREVIEW_CLAUDE_EFFORT=max xreview HEAD
```

### Headless and mechanical modes

The default opens a visible terminal-backed reviewer on macOS, common Linux
terminals, Windows Terminal, or tmux. If none is available it reports the
fallback and runs inline. Use `--headless` when a caller needs to wait for the
report in-process.

Claude reviews run in plan permission mode with direct edit tools and common
Git mutation commands disabled. This keeps the harness aligned with the
read-only review contract rather than relying only on prompt wording.

`--mechanical` changes the output from bug findings to a test contract: exact
harness, command, setup, action, assertion, and red/green expectation. It is a
read-only test-design pass, not proof that tests were run.

### Skill lookup

The launcher resolves its review instructions in this order:

1. `XREVIEW_SKILL_PATH`;
2. repository-local `.agents`, `.claude`, or `.codex` xreview skill;
3. the skill bundled with this repository;
4. the user's global xreview skill.

This repository therefore works after cloning without depending on a private
profile. A consuming project can still override the generic rules locally.

### Logs and environment

Every review is tee'd to a path-keyed log so same-named checkouts cannot
overwrite one another:

```text
${XREVIEW_LOG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/xreview}/<repo>-<path-hash>-<run-id>.log
```

The launcher removes `<log-path>.done` when a run starts and writes the
reviewer's numeric exit status there when it finishes. Programmatic consumers
of a windowed review should wait for that marker; `--headless` waits directly.
A best-effort `<repo>-<path-hash>-latest.log` symlink points to the newest run.

Supported overrides:

| Variable | Purpose |
|---|---|
| `XREVIEW_ENGINE` | Force `claude` or `codex` |
| `XREVIEW_CLAUDE_MODEL` | Claude model alias; default `opus` |
| `XREVIEW_CLAUDE_EFFORT` | Claude effort; default `max` |
| `XREVIEW_SKILL_PATH` | Explicit review instruction file |
| `XREVIEW_LOG_DIR` | Review log directory |
| `XREVIEW_SHARE_DIR` | Installer copy fallback directory |
| `XREVIEW_REQUIRE_CLAUDE=1` | Disable automatic Codex fallback |
| `CLAUDE_BIN` | Alternate Claude executable |

## Installation and upgrade

```sh
./install.sh                  # install to ~/.local/bin
./install.sh /usr/local/bin   # custom prefix
./install.sh --uninstall
```

Version 2 replaces the old positional `commit lite` style with explicit Git
targets and flags:

```text
xreview commit lite       -> xreview HEAD --mode lite
xreview branch deep       -> xreview main..HEAD --mode deep
xreview staged security   -> xreview --staged --mode security
```

Run `./scripts/check.sh` after changing the launcher or bundled skill.
Version 1 users may remove a stale `.agent-handoff/` directory; v2 does not
write review artifacts into consuming repositories.
The copy-fallback variable is now `XREVIEW_SHARE_DIR`; `--uninstall` cleans the
known v1 share-copy files as well as the v2 layout.

## Adopting the rest of XComs

1. Carry a small standalone task packet through a transport you already trust.
2. Keep project, runtime, and launch details in host-side configuration.
3. Use the packet for a visible fresh session (`xtask`) or a headless round trip
   (`xreturn`).
4. Add one thin adapter per runtime instead of teaching every project how to
   launch every agent.

## X Console

X Console is the future observer for XComs: sessions, status, receipts, and
provider health in one native interface. It should consume a safe projection,
not raw messages or private artifacts.
