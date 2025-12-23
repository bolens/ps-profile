# Developer Guides

This directory contains comprehensive guides for developers working on or contributing to the PowerShell profile.

## Available Guides

### Implementation & Planning

#### [Module Expansion Plan](MODULE_EXPANSION_PLAN.md)

Comprehensive plan for adding new modules and enhancing existing ones:

- 39+ new modules planned
- 6 modules to enhance
- Implementation standards and requirements
- Testing requirements (100% coverage mandatory)
- Documentation standards

**When to use**: When planning new modules, understanding implementation requirements, or reviewing module standards.

#### [Module Expansion Summary](MODULE_EXPANSION_SUMMARY.md)

Quick reference summary of the module expansion plan:

- New modules by category
- Enhanced modules list
- Implementation phases
- Key requirements

**When to use**: Quick overview of planned modules and implementation order.

#### [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md)

Detailed implementation roadmap with phases, dependencies, and timeline:

- Phase 0: Foundation (CRITICAL - start here)
- Phase 1: Fragment migration
- Phases 2-4: New modules (high/medium/low priority)
- Phase 5: Enhanced modules
- Phase 6: Pattern extraction
- Week-by-week schedule

**When to use**: Understanding implementation order, dependencies, and timeline.

#### [Implementation Progress](IMPLEMENTATION_PROGRESS.md)

Progress tracking for the implementation roadmap:

- Task checklists for each phase
- Module implementation checklist
- Metrics tracking
- Blockers and issues

**When to use**: Tracking implementation progress and status.

#### [Fragment Numbering Migration](FRAGMENT_NUMBERING_MIGRATION.md)

Plan for migrating from numbered to named fragments:

- Migration strategy
- Dependency resolution
- Backward compatibility
- Testing approach

**When to use**: When migrating fragments or understanding the new naming convention.

#### [Refactoring Opportunities](REFACTORING_OPPORTUNITIES.md)

Identified refactoring opportunities and priorities:

- High priority: Module loading, tool wrappers, command detection
- Medium priority: Pattern extraction
- Low priority: Consolidation and optimization
- Migration checklists

**When to use**: When refactoring code or understanding code quality improvements.

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

#### [Test Verification Plan](TEST_VERIFICATION_PLAN.md)

Comprehensive plan for test verification and improvement:

- Test execution strategy
- Error handling enhancement
- Coverage analysis
- Tool detection
- Documentation

**When to use**: Understanding test verification strategy and phases.

#### [Test Verification Progress](TEST_VERIFICATION_PROGRESS.md)

Progress tracking for test verification:

- Phase status (1-9)
- Test results summary
- Module migration status
- Next steps

**When to use**: Tracking test verification progress and status.

#### [Test Verification Mocking Guide](TEST_VERIFICATION_MOCKING_GUIDE.md)

Guide for using mocking frameworks in tests.

**When to use**: When writing tests that require mocking.

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

#### [Profile Performance Summary](PROFILE_PERFORMANCE_SUMMARY.md)

Summary of profile performance optimizations.

**When to use**: Understanding profile performance characteristics.

#### [Profile Performance Optimization](PROFILE_PERFORMANCE_OPTIMIZATION.md)

Detailed performance optimization guide.

**When to use**: When optimizing profile performance.

#### [Profile Performance Quick Wins](PROFILE_PERFORMANCE_QUICK_WINS.md)

Quick performance improvements.

**When to use**: When looking for easy performance wins.

#### [Profile Loading Performance Analysis](PROFILE_LOADING_PERFORMANCE_ANALYSIS.md)

Analysis of profile loading performance.

**When to use**: Understanding profile loading performance.

#### [Prompt Performance Troubleshooting](PROMPT_PERFORMANCE_TROUBLESHOOTING.md)

Troubleshooting guide for prompt performance issues.

**When to use**: When debugging prompt performance problems.

#### [Test Optimization Summary](TEST_OPTIMIZATION_SUMMARY.md)

Summary of test optimization efforts.

**When to use**: Understanding test performance characteristics.

## Related Documentation

- **Main Documentation**: [../README.md](../README.md)
- **API Reference**: [../api/README.md](../api/README.md)
- **Fragment Documentation**: [../fragments/README.md](../fragments/README.md)
- **Architecture**: [../../ARCHITECTURE.md](../../ARCHITECTURE.md)
- **Contributing**: [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
