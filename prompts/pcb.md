Fresh-context review — PCB / SCHEMATIC mode.

Born from SIDKIT (KiCad, dual-board hand-routed snap-apart unit + final
PCB v1). Patterns apply to any KiCad / Eagle / Allegro project — adapt
the audit script names for your toolchain.

**Focus areas:**

1. **Audit-report freshness** — PCB audit reports are *point-in-time
   snapshots*. The diff may include a regenerated report that no longer
   matches the current schematic. ALWAYS re-run the live audit and
   compare top-line counts (critical / warn / ok / manual) before
   trusting any committed `audit-report.md`.
2. **Net-label drift** — names that disappear silently (e.g. `SW_ON` →
   `J_SW` rename across schematic + footprint). Confirm both the symbol
   and the canonical front-panel/back-panel doc match.
3. **Phantom components** — symbols that exist in the schematic but
   aren't on the BOM, or BOM entries with no schematic instance. Common
   when refactoring sub-sheets.
4. **Power-rail topology** — VBUS / VSYS / +3V3 / GND classes correctly
   assigned, decoupling caps near every IC pin pair, single-point GND
   referencing for analog islands.
5. **Hierarchical-sheet pin contracts** — sub-sheet hier-labels match
   root hier-pin names exactly. Any new ERC errors at root level after
   a sub-sheet change is usually a label mismatch.
6. **Footprint pad numbering** — for hand-wired adapters, pin 1 marker
   matches PCB silkscreen orientation. Mismatched indices on FFC
   connectors are a classic mistake.
7. **DRC clearance** — board outline + edge clearance, drill-to-track
   spacing, copper pour stitching. Re-run DRC on any board file in the
   diff.
8. **Reference-design licensing** — Adafruit / SparkFun / TI reference
   circuits lifted into the schematic need correct attribution
   silkscreen (CC-BY-SA, MIT, etc.) per upstream LICENSE.

**Audit tools you can run:**
- `python3 PCB-Design/scripts/audit_all.py` (SIDKIT) — full audit
- `python3 PCB-Design/scripts/erc.py --root` — ERC at root level
- `python3 PCB-Design/scripts/audit_reference_match.py` — adopted
  reference circuits match upstream BOM
- KiCad CLI (8.0+): `kicad-cli sch erc <project>.kicad_sch`
- KiCad CLI: `kicad-cli pcb drc <project>.kicad_pcb`

**Output format:**

```
## Verdict: <SHIP | MERGE-WITH-FOLLOWUPS | NEEDS-CHANGES>

## Risk register

### HIGH (electrically wrong / DRC critical)
1. <summary> — `<sheet>.kicad_sch:<symbol>` — mechanism — fix.

### MEDIUM (lint / freshness / attribution)
...

### LOW
...

## Audit signals
- live audit re-run: <critical>/<warn>/<ok>/<manual> (committed: same?)
- ERC root: <count> errors
- DRC: <count> violations

## Followups
- ...
```
