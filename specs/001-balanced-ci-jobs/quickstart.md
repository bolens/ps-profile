# Validation quickstart

Use an existing PowerShell 7 and Pester 5.7.x installation; do not install modules or load the live profile.

1. Run the focused CI jobs test file through `scripts/utils/code-quality/analyze-coverage.ps1`, explicitly including the new module and test paths.
2. Verify expanded packed jobs equal the authoritative matrix for full, filtered, duplicated-input, and empty selections.
3. Run committed synthetic shard fixtures in temporary Git repositories with spaces in their paths. Verify failing-then-passing outcomes, distinct repository/temp paths, exact revision, and ordinary/batch/coverage artifact retention.
4. Run one real small bundle from a clean committed fixture and inspect per-shard summaries.
5. Run `make validate`, workflow lint/security checks, publication audit, and separate review.
6. Push the exact reviewed head and measure workflow creation through aggregate completion. Require all applicable checks and the under-20-minute target before merge.

## Local evidence

The real conversion-document-markdown-core and conversion-data-scientific shards
passed together in two isolated workers: 65 passing tests, 11 existing skips,
zero failures. Each shard took about 28 seconds including checkout and collection.
The committed fixture revision was c5f10016603fe642941ef23d3de146852a66655b.

The isolated error-handling file passes all 11 cases through the native CI runner.
The coverage analyzer reports three strict-mode fixture errors in existing synthetic
error/retry constructs; native CI behavior remains unchanged.

Linux worker cancellation terminates the native child and removes its clone in the
focused fixture. Windows descendant termination is not locally available; hosted
Windows execution remains required before merge.

The job module passes 14 focused cases with 90.04% measured coverage. The unchanged
shard-filter suite passes 17 cases with 99.12% measured coverage. Workflow lint and security checks report no new findings, and the two new PowerShell files have no configured
PSScriptAnalyzer findings. Independent reviews of scheduling and execution are
complete; all three initial findings and the worker-cleanup finding are fixed.

## Hosted delivery receipt

Keep the tested source head and synthetic merge revision in the PR receipt. Measure
workflow creation through the successful aggregate job's completion, including queue
time. Compare with run 33989732846 (66m47s), and report test-step cost separately.
The complete intermediate run 33999907789 passed in 30m45s with 21,955 test-step
seconds. Push the reviewed implementation, require every applicable check and a
successful complete run under 20 minutes, then follow the repository merge/release
playbook. Continue improving the PR if that criterion is unmet.

Full native validation passed: security, lint, spelling, Markdown, comment help,
idempotency, and duplicate-function checks. Hosted acceptance remains pending.
