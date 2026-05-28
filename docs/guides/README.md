# Developer Guides

This directory contains comprehensive guides for developers working on or contributing to the PowerShell profile.

## Available Guides

### Implementation & Planning

#### [Module Loading Standard](MODULE_LOADING_STANDARD.md)

Standardized module loading pattern specification:

- `Import-FragmentModule` function design
- Path caching infrastructure
- Dependency validation
- Retry logic
- Error handling

**When to use**: When implementing or using module loading patterns.

#### [Fragment Command Access](FRAGMENT_COMMAND_ACCESS.md)

How to access commands and functions defined inside profile fragments.

**When to use**: When a function defined in a fragment is not visible in your session.

#### [Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md)

How the SQLite-backed fragment cache works and how to interact with it.

**When to use**: When working with fragment parsing, caching, or cache invalidation.

#### [Fragment Cache Refactoring](FRAGMENT_CACHE_REFACTORING.md)

Analysis and plan for refactoring the `FragmentCache.psm1` module.

**When to use**: When modifying or extending the fragment cache system.

#### [Fragment Loading Optimization](FRAGMENT_LOADING_OPTIMIZATION.md)

Strategies for optimizing fragment load times.

**When to use**: When investigating slow profile startup or fragment loading.

#### [Profile Fragment Loader Modularization](PROFILE_FRAGMENT_LOADER_MODULARIZATION.md)

Analysis of `ProfileFragmentLoader.psm1` modularization opportunities.

**When to use**: When refactoring or extending the profile fragment loader.

#### [Modularization Analysis](MODULARIZATION_ANALYSIS.md)

Identifies monolithic files that could benefit from modularization.

**When to use**: When planning large refactors or splitting oversized files.

#### [Module Documentation Template](MODULE_DOCUMENTATION_TEMPLATE.md)

Standardized template for documenting PowerShell profile modules.

**When to use**: When writing new module documentation.

#### [Preference-Aware Install Hints](PREFERENCE_AWARE_INSTALL_HINTS.md)

How the preference-aware install hint system works.

**When to use**: When adding new tool install hints or customizing hint output.

#### [Preference Awareness Implementation](PREFERENCE_AWARENESS_IMPLEMENTATION.md)

Summary of all places where preference-awareness is implemented.

**When to use**: When auditing or extending preference-aware behavior.

#### [SQLite Databases](SQLITE_DATABASES.md)

Overview of SQLite databases used for persistent storage in the profile.

**When to use**: When working with fragment cache, metrics history, or other persistent data.

### Testing

#### [Testing Guide](TESTING.md)

Comprehensive testing guide:

- Test structure and organization
- Best practices
- Mocking frameworks
- Tool detection
- Performance testing

**When to use**: When writing tests, debugging test failures, or working on the test infrastructure.

#### [Development Guide](DEVELOPMENT.md)

Advanced developer guide covering:

- Advanced testing with Pester
- Performance monitoring and baselining
- Test retry logic and flaky test handling
- Environment health checks
- Detailed analysis and reporting

**When to use**: When writing tests, debugging test failures, or working on the test infrastructure.

#### [Development Quick Start](DEVELOPMENT_QUICK_START.md)

Quick reference for developers — fast profile loading, common commands, and setup shortcuts.

**When to use**: When onboarding to the project or quickly orienting to the development workflow.

#### [Test Verification Mocking Guide](TEST_VERIFICATION_MOCKING_GUIDE.md)

Guide for using mocking frameworks in tests.

**When to use**: When writing tests that require mocking.

#### [Verify Coverage Guide](VERIFY_COVERAGE.md)

Guide for verifying test coverage for utility modules.

**When to use**: When verifying test coverage or understanding coverage requirements.

#### [Tool Requirements](TOOL_REQUIREMENTS.md)

Documentation of tool requirements for tests.

**When to use**: Understanding which tools are required for tests.

### Code Quality

#### [Error Handling Standard](ERROR_HANDLING_STANDARD.md)

Standardized error handling approach, including `Write-StructuredError`, color coding conventions, and catch-block patterns.

**When to use**: When adding error handling to fragments, modules, or scripts.

#### [Function Naming Exceptions](FUNCTION_NAMING_EXCEPTIONS.md)

List of functions that don't follow standard PowerShell naming conventions and the reasons why.

**When to use**: When reviewing function names or understanding naming decisions.

#### [Security Allowlist](SECURITY_ALLOWLIST.md)

Security scanning allowlist for PSScriptAnalyzer rules that are intentionally suppressed.

**When to use**: When adding new security suppressions or reviewing security configurations.

#### [Type Safety Guide](TYPE_SAFETY.md)

Strategies for improving type safety in PowerShell codebases.

**When to use**: When adding enums, classes, or type-validated parameters.

#### [Type Safety Implementation Summary](TYPE_SAFETY_IMPLEMENTATION_SUMMARY.md)

Summary of implemented type safety improvements.

**When to use**: Understanding what type safety improvements are already in place.

#### [Type Safety Migration Status](TYPE_SAFETY_MIGRATION_STATUS.md)

Tracks the migration from backward-compatible enum usage to direct enum usage.

**When to use**: When continuing or auditing the type safety migration.

#### [Type Safety Remaining Improvements](TYPE_SAFETY_REMAINING_IMPROVEMENTS.md)

Outlines additional type safety improvements that could be implemented.

**When to use**: When planning future type safety work.

### Performance

#### [Profile Performance Optimization](PROFILE_PERFORMANCE_OPTIMIZATION.md)

Detailed performance optimization guide.

**When to use**: When optimizing profile performance.

#### [Development Performance Optimization](DEVELOPMENT_PERFORMANCE.md)

Performance optimization specifically for developers working on the profile itself.

**When to use**: When profiling or improving the development iteration cycle.

#### [Profile Loading Performance Analysis](PROFILE_LOADING_PERFORMANCE_ANALYSIS.md)

Analysis of profile loading performance.

**When to use**: Understanding profile loading performance.

#### [Profile Load Time Optimization](PROFILE_LOAD_TIME_OPTIMIZATION.md)

Actionable recommendations for improving PowerShell profile load times.

**When to use**: When profile startup is slow and you want concrete fixes.

#### [Parallel Loading State Merge Analysis](PARALLEL_LOADING_STATE_MERGE_ANALYSIS.md)

Technical analysis of parallel loading state merging challenges and alternatives.

**When to use**: Understanding why state merging is difficult and what alternatives exist.

#### [Prompt Performance Troubleshooting](PROMPT_PERFORMANCE_TROUBLESHOOTING.md)

Troubleshooting guide for prompt performance issues.

**When to use**: When debugging prompt performance problems.

## Related Documentation

- **Main Documentation**: [../README.md](../README.md)
- **API Reference**: [../api/README.md](../api/README.md)
- **Fragment Documentation**: [../fragments/README.md](../fragments/README.md)
- **Architecture**: [../../ARCHITECTURE.md](../../ARCHITECTURE.md)
- **Contributing**: [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
