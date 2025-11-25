# Developer Guides

This directory contains comprehensive guides for developers working on or contributing to the PowerShell profile.

## Available Guides

### [Development Guide](DEVELOPMENT.md)

Comprehensive developer guide covering:

- Advanced testing with Pester
- Performance monitoring and baselining
- Test retry logic and flaky test handling
- Environment health checks
- Detailed analysis and reporting

**When to use**: When writing tests, debugging test failures, or working on the test infrastructure.

### [Codebase Improvements](CODEBASE_IMPROVEMENTS.md)

Documentation of proposed and implemented improvements to simplify development:

- Implementation status tracking
- Identified issues and proposed solutions
- Migration strategies
- Usage examples

**When to use**: When understanding recent codebase changes or proposing new improvements.

### [Improvements Implemented](IMPROVEMENTS_IMPLEMENTED.md)

Detailed information about improvements that have been implemented:

- What was changed
- How to use new features
- Migration guides
- Examples

**When to use**: When learning about new features or migrating existing code to use new patterns.

### [Function Naming Exceptions](FUNCTION_NAMING_EXCEPTIONS.md)

List of functions that don't follow standard PowerShell naming conventions and the reasons why.

**When to use**: When reviewing function names or understanding naming decisions.

### [Security Allowlist](SECURITY_ALLOWLIST.md)

Security scanning allowlist for PSScriptAnalyzer rules that are intentionally suppressed.

**When to use**: When adding new security suppressions or reviewing security configurations.

## Related Documentation

- **Main Documentation**: [../README.md](../README.md)
- **API Reference**: [../api/README.md](../api/README.md)
- **Fragment Documentation**: [../fragments/README.md](../fragments/README.md)
- **Architecture**: [../../ARCHITECTURE.md](../../ARCHITECTURE.md)
- **Contributing**: [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
