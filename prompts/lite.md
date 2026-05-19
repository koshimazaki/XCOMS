Fresh-context review — LITE mode. Output max ~500 words. Lead with HIGH-
severity findings only. Skip nits and style. For each finding give one
line + file:line ref + mechanism + fix sketch. Skip findings that aren't
actionable. You have danger-full-access; only run audit tools if a finding
is genuinely ambiguous from the diff alone — default to fast.

End with a single Verdict line:
- `## Verdict: SHIP` — no findings worth blocking on
- `## Verdict: MERGE-WITH-FOLLOWUPS` — findings listed are non-blocking
- `## Verdict: NEEDS-CHANGES` — at least one finding must land before merge
