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

#### [Function Naming Exceptions](FUNCTION_NAMING_EXCEPTIONS.md)

List of functions that don't follow standard PowerShell naming conventions and the reasons why.

**When to use**: When reviewing function names or understanding naming decisions.

#### [Security Allowlist](SECURITY_ALLOWLIST.md)

Security scanning allowlist for PSScriptAnalyzer rules that are intentionally suppressed.

**When to use**: When adding new security suppressions or reviewing security configurations.

### Performance

#### [Profile Performance Optimization](PROFILE_PERFORMANCE_OPTIMIZATION.md)

Detailed performance optimization guide.

**When to use**: When optimizing profile performance.

#### [Profile Loading Performance Analysis](PROFILE_LOADING_PERFORMANCE_ANALYSIS.md)

Analysis of profile loading performance.

**When to use**: Understanding profile loading performance.

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
