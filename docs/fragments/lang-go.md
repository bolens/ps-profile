# lang-go.ps1

Enhanced Go development tools fragment.

## Overview

The `lang-go.ps1` fragment provides wrapper functions for Go development tools that enhance the basic `go.ps1` functionality. This module focuses on advanced Go development workflows including release automation, build tooling, and code quality checks.

## Dependencies

- **bootstrap** - Core helper functions (`Set-AgentModeFunction`, `Set-AgentModeAlias`, `Test-CachedCommand`)
- **env** - Environment configuration

## Functions

### Release-GoProject

Creates Go project releases using goreleaser.

**Syntax:**

```powershell
Release-GoProject [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to goreleaser. Can be used multiple times or as an array.

**Examples:**

```powershell
# Create a release
Release-GoProject

# Create a snapshot release (dry-run)
Release-GoProject --snapshot

# Build release artifacts without publishing
Release-GoProject --skip-publish
```

**Aliases:**

- `goreleaser`

**Tool:**

- **goreleaser** - Release automation for Go projects
  - Installation: `go install github.com/goreleaser/goreleaser/v2/cmd/goreleaser@latest` or `scoop install goreleaser`

### Invoke-Mage

Runs mage build targets for Go projects.

**Syntax:**

```powershell
Invoke-Mage [[-Target] <string>] [[-Arguments] <string[]>]
```

**Parameters:**

- `Target` (optional) - Mage target to run. If not specified, lists available targets.
- `Arguments` (optional) - Additional arguments to pass to mage. Can be used multiple times or as an array.

**Examples:**

```powershell
# List available mage targets
Invoke-Mage

# Run the 'build' target
Invoke-Mage build

# Run the 'test' target with verbose output
Invoke-Mage test -v
```

**Aliases:**

- `mage`

**Tool:**

- **mage** - Build tool for Go projects using magefiles
  - Installation: `go install github.com/magefile/mage@latest` or `scoop install mage`

### Lint-GoProject

Lints Go code using golangci-lint.

**Syntax:**

```powershell
Lint-GoProject [[-Arguments] <string[]>]
```

**Parameters:**

- `Arguments` (optional) - Additional arguments to pass to golangci-lint. Can be used multiple times or as an array.

**Examples:**

```powershell
# Lint the current Go project
Lint-GoProject

# Lint and automatically fix issues where possible
Lint-GoProject --fix

# Lint all packages recursively
Lint-GoProject ./...
```

**Aliases:**

- `golangci-lint`

**Tool:**

- **golangci-lint** - Fast linter for Go code
  - Installation: `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest` or `scoop install golangci-lint`

### Build-GoProject

Builds a Go project with common optimizations.

**Syntax:**

```powershell
Build-GoProject [[-Output] <string>] [[-Arguments] <string[]>]
```

**Parameters:**

- `Output` (optional) - Output binary name or path.
- `Arguments` (optional) - Additional arguments to pass to go build. Can be used multiple times or as an array.

**Examples:**

```powershell
# Build the current Go project
Build-GoProject

# Build and name the output binary 'myapp'
Build-GoProject -Output myapp

# Build with linker flags to strip symbols
Build-GoProject -Arguments @('-ldflags', '-s -w')
```

**Aliases:**

- `go-build-project`

**Tool:**

- **go** - Go compiler (built-in)
  - Installation: `scoop install go`

### Test-GoProject

Runs Go tests with common options.

**Syntax:**

```powershell
Test-GoProject [-Verbose] [-Coverage] [[-Arguments] <string[]>]
```

**Parameters:**

- `VerboseOutput` (switch) - Enable verbose test output (-v flag).
- `Coverage` (switch) - Generate coverage report (-cover flag).
- `Arguments` (optional) - Additional arguments to pass to go test. Can be used multiple times or as an array.

**Examples:**

```powershell
# Run tests in the current package
Test-GoProject

# Run tests with verbose output
Test-GoProject -VerboseOutput

# Run tests with coverage for all packages
Test-GoProject -Coverage ./...
```

**Aliases:**

- `go-test-project`

**Tool:**

- **go** - Go compiler (built-in)
  - Installation: `scoop install go`

## Error Handling

All functions gracefully handle missing tools by:

1. Checking tool availability using `Test-CachedCommand`
2. Displaying a helpful warning with installation instructions
3. Returning `$null` instead of throwing errors

This ensures the profile continues to load even when tools are not installed.

## Idempotency

The fragment is idempotent and can be safely loaded multiple times. Functions and aliases are only registered if they don't already exist.

## Performance

- Uses `Test-CachedCommand` for efficient command detection without triggering module autoload
- Functions are registered lazily (only when needed)
- Fragment loading is optimized for fast startup times

## Related Fragments

- **go.ps1** - Basic Go operations (`Invoke-GoRun`, `Build-GoProgram`, `Test-GoPackage`, etc.)

## Notes

- This fragment enhances `go.ps1` with additional development tools
- All functions follow PowerShell best practices with proper error handling
- Install hints are provided when tools are missing
- Functions use `Write-MissingToolWarning` for consistent error messaging
