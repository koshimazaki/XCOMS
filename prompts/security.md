Fresh-context SECURITY review.

Focus areas:
- OWASP top-10: injection (SQL/command/LDAP), XSS, broken auth, sensitive
  data exposure, XXE, broken access control, security misconfiguration,
  insecure deserialization, known-vuln components, insufficient logging.
- Supply chain: new deps, lockfile drift, transitive vulns, postinstall
  scripts, typosquatting, vendor binary blobs.
- Secrets: hardcoded credentials, tokens in logs, secrets in commit
  history, .env file leaks, weak crypto (md5/sha1/des/rc4).
- Auth boundaries: missing authz checks, IDOR, JWT secret handling,
  session fixation, CSRF protection.
- Input handling: deserialization, SSRF (URL fetches, redirects),
  path traversal, unbounded reads, integer overflow.
- Concurrency: race conditions, TOCTOU, missing locks around shared
  state, double-free, use-after-free.
- LLM-specific (if touched): prompt injection, output-as-input loops,
  tool-call validation, sandbox escape.

For each finding: severity (HIGH/MEDIUM/LOW), file:line, exploit sketch
(how an attacker would trigger it), fix sketch.

You have danger-full-access — grep deps, inspect lockfiles, run linters
(`semgrep`, `bandit`, `npm audit`, `cargo audit` if available).

End with `## Verdict: <SAFE | NEEDS-HARDENING | BLOCKING>`.
