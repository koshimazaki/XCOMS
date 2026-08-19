---
name: xreview
description: Use when the user says xreview, /review, code review this commit/range/scope, review HEAD, review staged changes, review a PR, or asks for a fast high-signal reviewer pass. Global behavior is language-agnostic, subscription-backed lite mode with a fresh single reviewer terminal session; repository-local xreview skills or instructions may add specialized rubrics.
---

# xreview

Run a focused, language-agnostic code review on the requested local git or PR
scope.

## Repository Overrides

This is the global fallback skill. If the repository contains its own xreview
skill or review instructions, prefer those for specialized behavior. Examples:
firmware C, Unreal/UE plugin rules, MCP contracts, generated template checks,
schema drift, or product-specific architecture constraints.

Without a repo-local override, do not assume a language or framework. Review the
change for real bugs, broken contracts, data-loss risks, unsafe input handling,
security issues, migration/compatibility risks, and missing verification.

## Launcher

Prefer the global launcher when available:

```bash
xreview <target-or-flags>
```

The launcher starts a fresh dedicated terminal-backed review session for the
requested commit, range, working tree, staged diff, PR, file, or named scope.
When Codex is invoking this skill, default to a cross-agent check by running the
Claude reviewer path (`XREVIEW_ENGINE=claude xreview ...`). If the user
explicitly asks for Codex to check with Codex, force `XREVIEW_ENGINE=codex`.
Only perform the review inline if the launcher is missing or fails before the
review starts.

For a mechanical test contract pass, use:

```bash
xreview <target-or-flags> --mechanical
```

This launches a visible fresh Claude session whose job is to translate the
change into exact deterministic tests or behavioral checks. It remains read-only:
it does not edit test files or run builds/tests as proof.

## Output log

Every review — windowed or `--headless`, codex or claude — is tee'd to a
predictable per-repo log, so the result can be re-read after the Terminal window
closes and an agent that launched a windowed review can still read the findings:

```
${XREVIEW_LOG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/xreview}/<repo>-<path-hash>-<run-id>.log
```

Each run has its own log. The launcher also maintains a best-effort
`<repo>-<path-hash>-latest.log` symlink and prints the exact run path plus a
`<log-path>.done` marker in its startup summary. It writes the reviewer's
numeric exit status to the marker when complete. A
programmatic consumer of a windowed review must wait for that marker before
reading the log; `--headless` waits and streams directly.

## Defaults

- Use `lite` mode unless the user asks for `mid`, `deep`, `security`, `docs`, or a repo-specific explicit mode.
- Use a single reviewer pass by default. Do not run dual/multi-agent comparison unless the user explicitly asks for it.
- Use the user's installed subscription-backed tool setup. Do not add API-key, budget, or cost flags.
- Review is read-only unless the user explicitly asks to fix issues.
- Findings first, ordered by severity. Report only high-confidence, actionable issues.
- `--mechanical`, `--test-contract`, and `--tests` switch from bug findings to
  a Mechanical Test Contract: exact file/harness, command, setup, action,
  assertion, red/green expectation, and any manual/HIL fallback.

## Scope Parser

Resolve the review target before inspecting code:

- No target: review dirty working tree if present; otherwise review `HEAD`.
- `--staged`: `git diff --cached`.
- `--working`: `git diff`.
- Single commit SHA or `HEAD`: `git diff <commit>^..<commit>`.
- Range such as `A..B`, `HEAD~3..HEAD`, or `main..HEAD`: review that diff.
- PR number/URL via `--pr`, `--pr=<value>`, or `pr:<value>`: use `gh pr view`
  and `gh pr diff`.
- File or directory paths: review only those paths; combine with commit/range when both are provided.
- `--scope <name>`: apply the named rubric and, when sensible, filter to matching paths.

Always show the resolved scope in the review summary.

## Global Modes

- `lite`: high-signal bugs, regressions, contract breaks, data-loss risks, and explicit project-rule violations only.
- `mid`: the lite bug pass plus focused compatibility, test, and maintainability risks.
- `deep`: broader design and maintainability review after the bug pass.
- `docs`: contradictions between docs, scripts, README counts, and executable source.
- `security`: injection, unsafe shelling, secret handling, auth boundaries, unvalidated input, and unsafe file/network operations.
- `mechanical` flag: a test-reviewer pass, not a depth mode. Combine with
  `--mode lite|mid|deep` to set how broad the test search should be.

Any other mode is repo-specific. Look for local instructions before applying it;
if none exist, treat it as a focus label rather than importing assumptions.

## Workflow

1. Spawn the launcher (`xreview ...`) when possible. From Codex, prefer Claude
   as the reviewer by default; use Codex as the reviewer only when explicitly
   requested.
2. Read project instructions first: `AGENTS.md`, `CLAUDE.md`, and nearby scoped instruction files.
3. Resolve the requested git/file/PR scope with the parser above.
4. Inspect the diff, then read surrounding source for every flagged issue.
5. For DB/MCP/template reviews, verify claims against scripts/tests/catalogues rather than docs alone.
6. Run lightweight validation only when it directly supports the review and is safe for the repo.
7. Do not flag pre-existing issues unless the reviewed change makes them worse or depends on them.

For `--mechanical`, replace steps 4-7 with:

4. Inspect the diff, then read the closest existing test harnesses and
   behavioral entry points.
5. Propose tests that are cheap, deterministic, and close to the changed
   contract.
6. For each test, specify the exact file or harness, command, setup, action,
   assertion, and red/green expectation.
7. If automation is impractical, name the smallest manual or hardware-in-loop
   check that would catch the regression.

## Output

Use this structure:

```markdown
Reviewed: <resolved scope and mode>

Findings:
- [P1/P2/P3] <file:line> <issue>
  Evidence: <short proof>
  Fix: <concrete fix>

Residual risk:
- <tests not run, uncertain external dependency, or "None obvious">
```

If no high-confidence issues are found, say that clearly and mention any residual risk or test gap.

For `--mechanical`, use:

```markdown
Reviewed: <resolved scope and mechanical mode>

Mechanical Test Contract:
- [M1/M2/M3] <behavior or risk>
  File/harness: <exact path or HIL/manual>
  Command: <exact command>
  Setup: <test setup>
  Act: <stimulus>
  Assert: <observable expectation>
  Red/green: <what fails before, what passes after>

Behavioral / E2E checks:
- <only when useful; exact manual or automated flow>

Coverage gaps:
- <what still cannot be proven mechanically>
```
