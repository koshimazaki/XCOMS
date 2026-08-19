```text
██╗  ██╗ ██████╗ ██████╗ ███╗   ███╗███████╗
╚██╗██╔╝██╔════╝██╔═══██╗████╗ ████║██╔════╝
 ╚███╔╝ ██║     ██║   ██║██╔████╔██║███████╗
 ██╔██╗ ██║     ██║   ██║██║╚██╔╝██║╚════██║
██╔╝ ██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
░░░█ X Communications (XComs) █░░░
░░ A small, portable protocol for communication between coding agents ░░ v0.2
```

# X Communications (XComs)

> A small, portable protocol for communication between coding agents.

XComs separates the actions an agent takes from the transport that carries
them. The same verbs can work across Codex, Claude Code, or another runtime
without baking one private setup into every repository.

This is a public reference for one working agent setup, not a prescribed
platform. Use the pieces that fit and adapt the rest to your own host.

| Component | Job | Public surface |
|---|---|---|
| `xreview` | **Judge** a change in fresh context | Working CLI, v2 |
| `xcom` | **Carry** packets, receipts, and artifacts | Transport contract |
| `xtask` | **Hand over** one bounded topic to a fresh session | Verb contract |
| `xreturn` | **Run and return** a result without a visible handoff | Verb contract |
| X Adapter | **Connect** a runtime's native task UI or CLI to XCOM | Adapter contract |
| X Console | **Observe** the system | Planned |

The repository ships the standalone `xreview` launcher and the minimal public
contracts for the rest. XCOM's storage, queue, and host integration are
deliberately replaceable.

## Install `xreview`

```sh
git clone https://github.com/koshimazaki/XCOMS.git
cd XCOMS
./install.sh
```

Requires Bash 3.2+, Git, and an authenticated
[Codex](https://github.com/openai/codex) or
[Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI.
Codex covers default dirty-tree and single-commit reviews. Exact staged,
working-tree, range, path, pull-request, and mechanical scopes require Claude.

## Quick start

```sh
xreview                             # dirty tree, otherwise HEAD
xreview --working --mode lite       # unstaged work
xreview HEAD~3..HEAD --mode deep    # commit range
xreview --pr 123 --mode security    # GitHub pull request
xreview HEAD --mechanical           # mechanical test contract
```

Inside a Codex session, `xreview` defaults to a fresh Claude Opus reviewer. In
other shells it defaults to Codex. Force either path with
`XREVIEW_ENGINE=claude` or `XREVIEW_ENGINE=codex`. Every result is also written
to a predictable per-repository log.

See [the documentation](docs/documentation.md) for the v2 CLI, the five XComs
contracts, and an implementation guide.

## Design rules

- Verbs stay thin and stateless.
- XCOM owns delivery state; adapters own runtime-specific wiring.
- A handoff carries one standalone topic, not a conversation dump.
- Paths, credentials, provider IDs, and native task IDs stay host-side.
- Reviewers are fresh, read-only, and independent by default.

MIT licensed.
