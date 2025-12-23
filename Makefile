# Makefile - Task runner configuration - parity with Taskfile.yml
# https://www.gnu.org/software/make/
#
# Usage: make <target>
# Example: make lint, make test, make quality-check

.PHONY: lint validate check-comment-help test test-unit test-integration test-performance test-coverage
.PHONY: benchmark security-scan diagnose-profile-performance optimize-git-performance
.PHONY: check-module-updates install-module-updates generate-changelog generate-dashboard
.PHONY: create-release generate-docs spellcheck check-script-standards markdownlint
.PHONY: install-githooks install-pre-commit-hook format find-duplicates
.PHONY: generate-fragment-readmes new-fragment check-commit-messages update-baseline
.PHONY: collect-code-metrics export-metrics save-metrics-snapshot track-coverage-trends
.PHONY: quality-check pre-commit-checks check-idempotency validate-function-naming
.PHONY: check-missing-tests validate-dependencies check-missing-packages check-vulnerabilities
.PHONY: format-and-lint all-docs init-wrangler-config dev-setup default

lint: ## Lint profile.d
	pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1

validate: ## Validate profile (lint + idempotency)
	pwsh -NoProfile -File scripts/checks/validate-profile.ps1

check-comment-help: ## Check comment-based help
	pwsh -NoProfile -File scripts/checks/check-comment-help.ps1

test: ## Run Pester tests with coverage
	pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel

test-unit: ## Run unit test suite
	pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -Parallel

test-integration: ## Run integration test suite
	pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -Parallel

test-performance: ## Run performance test suite
	pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Performance -Parallel

test-coverage: ## Run Pester tests with coverage
	pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel

benchmark: ## Run startup performance benchmark
	pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1

security-scan: ## Run security scan
	pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1

diagnose-profile-performance: ## Diagnose profile performance issues
	pwsh -NoProfile -File scripts/utils/performance/diagnose-profile-performance.ps1

optimize-git-performance: ## Optimize Git performance
	pwsh -NoProfile -File scripts/utils/performance/optimize-git-performance.ps1

check-module-updates: ## Check PowerShell module updates
	pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1

install-module-updates: ## Install PowerShell module updates
	pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1 -Update

generate-changelog: ## Generate changelog from git history
	pwsh -NoProfile -File scripts/utils/docs/generate-changelog.ps1

generate-dashboard: ## Generate metrics dashboard
	pwsh -NoProfile -File scripts/utils/metrics/generate-dashboard.ps1

create-release: ## Create release (dry run)
	pwsh -NoProfile -File scripts/utils/release/create-release.ps1 -DryRun

generate-docs: ## Generate API documentation
	pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1

spellcheck: ## Run spellcheck
	pwsh -NoProfile -File scripts/utils/code-quality/spellcheck.ps1

check-script-standards: ## Check script standards and best practices
	pwsh -NoProfile -File scripts/checks/check-script-standards.ps1

markdownlint: ## Run markdownlint
	pwsh -NoProfile -File scripts/utils/code-quality/run-markdownlint.ps1

install-githooks: ## Install git hooks
	pwsh -NoProfile -File scripts/git/install-githooks.ps1

install-pre-commit-hook: ## Install pre-commit hook only
	pwsh -NoProfile -File scripts/git/install-pre-commit-hook.ps1

format: ## Format PowerShell code
	pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1

find-duplicates: ## Find duplicate functions
	pwsh -NoProfile -File scripts/utils/metrics/find-duplicate-functions.ps1

generate-fragment-readmes: ## Generate fragment READMEs
	pwsh -NoProfile -File scripts/utils/docs/generate-fragment-readmes.ps1

new-fragment: ## Create a new profile fragment from template
	pwsh -NoProfile -File scripts/utils/fragment/new-fragment.ps1

check-commit-messages: ## Check commit messages
	pwsh -NoProfile -File scripts/checks/check-commit-messages.ps1

update-baseline: ## Update performance baseline
	pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -UpdateBaseline

collect-code-metrics: ## Collect code metrics
	pwsh -NoProfile -File scripts/utils/metrics/collect-code-metrics.ps1

export-metrics: ## Export metrics data
	pwsh -NoProfile -File scripts/utils/metrics/export-metrics.ps1

save-metrics-snapshot: ## Save metrics snapshot
	pwsh -NoProfile -File scripts/utils/metrics/save-metrics-snapshot.ps1

track-coverage-trends: ## Track test coverage trends over time
	pwsh -NoProfile -File scripts/utils/metrics/track-coverage-trends.ps1

quality-check: format security-scan lint spellcheck markdownlint check-comment-help test validate-function-naming ## Full quality check (format + security + lint + spellcheck + markdownlint + help + tests + naming)
	@echo "All quality checks passed"

pre-commit-checks: ## Run pre-commit checks
	pwsh -NoProfile -File scripts/git/pre-commit.ps1

check-idempotency: ## Check fragment idempotency
	pwsh -NoProfile -File scripts/checks/check-idempotency.ps1

validate-function-naming: ## Validate function naming conventions
	pwsh -NoProfile -File scripts/utils/code-quality/validate-function-naming.ps1

check-missing-tests: ## Check for missing tests
	pwsh -NoProfile -File scripts/utils/code-quality/check-missing-tests.ps1

validate-dependencies: ## Validate dependencies
	pwsh -NoProfile -File scripts/utils/dependencies/validate-dependencies.ps1

check-missing-packages: ## Check for missing packages and modules
	pwsh -NoProfile -File scripts/utils/dependencies/check-missing-packages.ps1

check-vulnerabilities: ## Check dependency updates (vulnerability scanning can be added)
	pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1

format-and-lint: format lint ## Format and lint code
	@echo "Format and lint completed"

all-docs: generate-docs generate-fragment-readmes ## Generate all documentation (API docs + fragment READMEs)
	@echo "All documentation generated"

init-wrangler-config: ## Initialize wrangler configuration
	pwsh -NoProfile -File scripts/utils/setup/init-wrangler-config.ps1

dev-setup: ## Run development environment setup
	pwsh -NoProfile -File scripts/dev/setup.ps1

default: ## Show make target help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

