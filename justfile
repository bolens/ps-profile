# https://github.com/casey/just
# Task runner configuration - parity with Taskfile.yml

# Lint profile.d
lint:
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1

# Validate profile (lint + idempotency)
validate:
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Check comment-based help
check-comment-help:
pwsh -NoProfile -File scripts/checks/check-comment-help.ps1

# Run Pester Tests
test:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel

# Run Unit Test Suite
test-unit:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -Parallel

# Run Integration Test Suite
test-integration:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -Parallel

# Run Performance Test Suite
test-performance:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Performance -Parallel

# Run Pester Tests with Coverage
test-coverage:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel

# Run Performance Benchmark
benchmark:
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1

# Run Security Scan
security-scan:
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1

# Diagnose profile performance issues
diagnose-profile-performance:
pwsh -NoProfile -File scripts/utils/performance/diagnose-profile-performance.ps1

# Optimize Git performance
optimize-git-performance:
pwsh -NoProfile -File scripts/utils/performance/optimize-git-performance.ps1

# Check Module Updates
check-module-updates:
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1

# Install Module Updates
install-module-updates:
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1 -Update

# Generate Changelog
generate-changelog:
pwsh -NoProfile -File scripts/utils/docs/generate-changelog.ps1

# Generate metrics dashboard
generate-dashboard:
pwsh -NoProfile -File scripts/utils/metrics/generate-dashboard.ps1

# Create Release (Dry Run)
create-release:
pwsh -NoProfile -File scripts/utils/release/create-release.ps1 -DryRun

# Generate API Documentation
generate-docs:
pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1

# Run Spellcheck
spellcheck:
pwsh -NoProfile -File scripts/utils/code-quality/spellcheck.ps1

# Check script standards and best practices
check-script-standards:
pwsh -NoProfile -File scripts/checks/check-script-standards.ps1

# Run Markdownlint
markdownlint:
pwsh -NoProfile -File scripts/utils/code-quality/run-markdownlint.ps1

# Install Git hooks
install-githooks:
pwsh -NoProfile -File scripts/git/install-githooks.ps1

# Install pre-commit hook only
install-pre-commit-hook:
pwsh -NoProfile -File scripts/git/install-pre-commit-hook.ps1

# Format Code
format:
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1

# Find Duplicate Functions
find-duplicates:
pwsh -NoProfile -File scripts/utils/metrics/find-duplicate-functions.ps1

# Generate Fragment READMEs
generate-fragment-readmes:
pwsh -NoProfile -File scripts/utils/docs/generate-fragment-readmes.ps1

# Create a new profile fragment from template
new-fragment:
pwsh -NoProfile -File scripts/utils/fragment/new-fragment.ps1

# Check Commit Messages
check-commit-messages:
pwsh -NoProfile -File scripts/checks/check-commit-messages.ps1

# Update Performance Baseline
update-baseline:
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -UpdateBaseline

# Collect code metrics
collect-code-metrics:
pwsh -NoProfile -File scripts/utils/metrics/collect-code-metrics.ps1

# Export metrics data
export-metrics:
pwsh -NoProfile -File scripts/utils/metrics/export-metrics.ps1

# Save a metrics snapshot
save-metrics-snapshot:
pwsh -NoProfile -File scripts/utils/metrics/save-metrics-snapshot.ps1

# Track test coverage trends over time
track-coverage-trends:
pwsh -NoProfile -File scripts/utils/metrics/track-coverage-trends.ps1

# Full Quality Check (format + security + lint + spellcheck + markdownlint + help + tests + function naming)
quality-check format security-scan lint spellcheck markdownlint check-comment-help test validate-function-naming:
@echo "All quality checks passed"

# Run Pre-commit Checks
pre-commit-checks:
pwsh -NoProfile -File scripts/git/pre-commit.ps1

# Check Idempotency
check-idempotency:
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1

# Validate Function Naming Conventions
validate-function-naming:
pwsh -NoProfile -File scripts/utils/code-quality/validate-function-naming.ps1

# Check for Missing Tests
check-missing-tests:
pwsh -NoProfile -File scripts/utils/code-quality/check-missing-tests.ps1

# Validate Dependencies
validate-dependencies:
pwsh -NoProfile -File scripts/utils/dependencies/validate-dependencies.ps1

# Check for missing packages and modules
check-missing-packages:
pwsh -NoProfile -File scripts/utils/dependencies/check-missing-packages.ps1

# Check Dependency Updates (Vulnerability scanning can be added)
check-vulnerabilities:
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1

# Format and Lint Code
format-and-lint format lint:
@echo "Format and lint completed"

# Generate All Documentation (API docs + fragment READMEs)
all-docs generate-docs generate-fragment-readmes:
@echo "All documentation generated"

# Initialize wrangler configuration
init-wrangler-config:
pwsh -NoProfile -File scripts/utils/setup/init-wrangler-config.ps1

# Run development environment setup
dev-setup:
pwsh -NoProfile -File scripts/dev/setup.ps1

# Default: run lint (common first task)
default: lint

