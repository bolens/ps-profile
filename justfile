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
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel {{arguments()}}

# Run Unit Test Suite
test-unit:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -Parallel {{arguments()}}

# Run Integration Test Suite
test-integration:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -Parallel {{arguments()}}

# Run Performance Test Suite
test-performance:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Performance -Parallel {{arguments()}}

# Run Pester Tests with Coverage
test-coverage:
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel {{arguments()}}

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
pwsh -NoProfile -File scripts/utils/performance/optimize-git-performance.ps1 {{arguments()}}

# Check Module Updates
check-module-updates:
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1 {{arguments()}}

# Install Module Updates
install-module-updates:
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1 -Update {{arguments()}}

# Generate Changelog
generate-changelog:
pwsh -NoProfile -File scripts/utils/docs/generate-changelog.ps1 {{arguments()}}

# Generate metrics dashboard
generate-dashboard:
pwsh -NoProfile -File scripts/utils/metrics/generate-dashboard.ps1 {{arguments()}}

# Create Release (Dry Run)
create-release:
pwsh -NoProfile -File scripts/utils/release/create-release.ps1 -DryRun

# Generate API Documentation
generate-docs:
pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1 {{arguments()}}

# Run Spellcheck
spellcheck:
pwsh -NoProfile -File scripts/utils/code-quality/spellcheck.ps1

# Check health of all SQLite databases
db-health:
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action health

# Get statistics for all SQLite databases
db-statistics:
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action statistics

# Optimize all SQLite databases
db-optimize:
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action optimize

# Backup all SQLite databases
db-backup:
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action backup

# Repair corrupted SQLite databases
db-repair:
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action repair

# Validate SQLite database implementation and configuration
db-validate:
pwsh -NoProfile -File scripts/utils/database/validate-databases.ps1

# Validate SQLite databases with operation testing
db-validate-full:
pwsh -NoProfile -File scripts/utils/database/validate-databases.ps1 -TestOperations

# Initialize all SQLite databases
db-init:
pwsh -NoProfile -File scripts/utils/database/initialize-databases.ps1

# Clear fragment cache (in-memory and SQLite database)
clear-fragment-cache:
pwsh -NoProfile -File scripts/utils/clear-fragment-cache.ps1 {{arguments()}}

# Validate fragment cache (verify cache state)
validate-fragment-cache:
pwsh -NoProfile -File scripts/utils/verify-cache-cleared.ps1 {{arguments()}}

# Check script standards and best practices
check-script-standards:
pwsh -NoProfile -File scripts/checks/check-script-standards.ps1

# Run Markdownlint
markdownlint:
pwsh -NoProfile -File scripts/utils/code-quality/run-markdownlint.ps1

# Install Git hooks
install-githooks:
pwsh -NoProfile -File scripts/git/install-githooks.ps1 {{arguments()}}

# Install pre-commit hook only
install-pre-commit-hook:
pwsh -NoProfile -File scripts/git/install-pre-commit-hook.ps1

# Format Code
format:
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1 {{arguments()}}

# Find Duplicate Functions
find-duplicates:
pwsh -NoProfile -File scripts/utils/metrics/find-duplicate-functions.ps1

# Generate Fragment READMEs
generate-fragment-readmes:
pwsh -NoProfile -File scripts/utils/docs/generate-fragment-readmes.ps1 {{arguments()}}

# Create a new profile fragment from template
new-fragment:
pwsh -NoProfile -File scripts/utils/fragment/new-fragment.ps1 {{arguments()}}

# Generate standalone script wrappers for fragment commands
generate-command-wrappers:
pwsh -NoProfile -File scripts/utils/fragment/generate-command-wrappers.ps1 {{arguments()}}

# Check Commit Messages
check-commit-messages:
pwsh -NoProfile -File scripts/checks/check-commit-messages.ps1

# Update Performance Baseline
update-baseline:
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -UpdateBaseline {{arguments()}}

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
pwsh -NoProfile -File scripts/utils/setup/init-wrangler-config.ps1 {{arguments()}}

# Run development environment setup
dev-setup:
pwsh -NoProfile -File scripts/dev/setup.ps1

# Check task parity across all task runner files
check-task-parity:
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 {{arguments()}}

# Generate missing tasks to achieve parity across all task runner files
generate-task-parity:
pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1 -Generate {{arguments()}}

# Default: run lint (common first task)
default: lint

