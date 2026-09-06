# Preserve changelog configuration during test cleanup

Status: Implemented; native validation passed

Running fragment tests invokes Clear-TestRepoRootSpillover, whose transient-file
list previously contained the tracked cliff.toml configuration. A successful test
run therefore deleted source configuration from the checkout.

## Requirements

- FR-001: Cleanup must preserve cliff.toml and its contents.
- FR-002: Known transient spillover must still be removed.
- FR-004: The missing-repository fixture must clear and restore the explicit
  PS_PROFILE_REPO_ROOT override and model absent repository markers so it tests
  directory discovery independently of Git markers in temporary ancestors.
- FR-003: The regression must use a disposable repository-root fixture and must
  not depend on the developer's changelog configuration or live profile.

Acceptance: the focused TestSupport suite preserves a sentinel cliff.toml and
removes a transient hook-test-spill.txt in the same cleanup call. Existing native
validation and relevant helper tests must pass. No runtime profile behavior changes.
