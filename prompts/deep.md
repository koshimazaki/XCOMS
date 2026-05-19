Fresh-context review — DEEP mode. Multi-file / multi-commit audit.
Produce a prioritized risk register: HIGH > MEDIUM > LOW. For each
finding: one-line summary, file:line ref, mechanism (not just "looks
wrong"), minimal fix sketch.

You have danger-full-access — read freely, grep, run build/test commands,
project-specific audit scripts if useful. Verify suspicious patterns
against the actual code (don't trust commit messages).

Format:

```
## Verdict: <SHIP | MERGE-WITH-FOLLOWUPS | NEEDS-CHANGES>

## Risk register

### HIGH
1. <summary> — `file:line` — mechanism — fix sketch.

### MEDIUM
...

### LOW / NITS
...

## Build/audit signals
- <tool>: <pass|fail + relevant signal>

## Followup recommendations
- ...
```
