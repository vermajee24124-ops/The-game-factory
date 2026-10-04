# Turbo Rush Security Scanning

## Local/release checks

The release pipeline runs the Turbo Rush monetization audit and the project security audit before export.

## Strix

Strix is an open-source AI security/pentesting tool under Apache-2.0. Its official CI guidance supports GitHub Actions, changed-file quick scans, and SARIF output.

Turbo Rush includes a separate manual GitHub Actions workflow at `.github/workflows/turbo-rush-strix.yml`.

That workflow is intentionally manual and requires repository secrets supplied by the repository owner:

- `STRIX_LLM`
- `LLM_API_KEY`

No API key is stored in the repository.

The Strix workflow must never be treated as evidence of a completed scan until a real CI run produces a completed report.

Reference: https://github.com/usestrix/strix

## Release-security status

A CI build passing static checks does not prove zero device-specific vulnerabilities. Android real-device testing, store configuration, ad SDK configuration, and signed-key management still need final production review.
