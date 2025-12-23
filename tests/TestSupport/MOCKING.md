# Mocking Framework Documentation

This document describes the comprehensive mocking framework available in the test suite.

## Overview

The mocking framework is organized into focused, modular components for easy maintenance:

- **MockRegistry.psm1** - Mock management and registry (~100 lines)
- **MockCommand.psm1** - Command mocking (~200 lines)
- **MockFileSystem.psm1** - File system mocking (~100 lines)
- **MockNetwork.psm1** - Network mocking (~100 lines)
- **MockEnvironment.psm1** - Environment variable mocking (~80 lines)
- **PesterMocks.psm1** - Pester 5 mocking helpers (~250 lines)

All modules are automatically imported by `TestSupport.ps1` when tests are loaded.

The framework provides two complementary approaches:

1. **Function-based mocks** (`Mock-Command`, `Mock-Commands`) - For test mode scenarios where you need to prevent external commands from executing
2. **Pester 5 mocks** (`Use-PesterMock`, `Mock-CommandAvailabilityPester`) - For unit tests using Pester 5's built-in mocking capabilities

## Quick Start

### Using Pester 5 Mocks (Recommended for Unit Tests)

```powershell
BeforeAll {
    # Mocking modules are automatically loaded by TestSupport.ps1
    # No need to import manually
}

Describe 'My Function' {
    Context 'When command is unavailable' {
        BeforeEach {
            # Mock command as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
        }

        It 'should handle missing command gracefully' {
            # Your test code
        }
    }

    Context 'When command is available' {
        BeforeEach {
            # Mock command as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
        }

        It 'should use the command' {
            # Your test code
        }
    }
}
```

### Using Function-based Mocks (For Test Mode)

```powershell
BeforeAll {
    # Initialize test mode
    $env:PS_PROFILE_TEST_MODE = '1'

    # Mocking modules are automatically loaded by TestSupport.ps1
    # Mock external commands
    Mock-Commands -CommandNames @('git', 'docker', 'kubectl')
}
```

## Available Functions

### Pester 5 Mocking Functions

#### `Use-PesterMock`

Creates a Pester 5 mock with full Pester 5 syntax support.

```powershell
# Basic usage
Use-PesterMock -CommandName 'Get-Command' `
    -ParameterFilter { $Name -eq 'git' } `
    -MockWith { $null } `
    -Scope It

# With exclusive filter (Pester 5 feature)
Use-PesterMock -CommandName 'Test-HasCommand' `
    -ExclusiveFilter { $Name -eq 'docker' } `
    -MockWith { $false } `
    -Scope Context

# With call count verification
Use-PesterMock -CommandName 'Invoke-WebRequest' `
    -MockWith { [PSCustomObject]@{ StatusCode = 200 } } `
    -Times 1 `
    -Exactly `
    -Scope It
```

#### `Mock-CommandAvailabilityPester`

Convenience function for mocking command availability with proper Pester 5 syntax.

```powershell
# Mock command as unavailable
Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It

# Mock command as available
Mock-CommandAvailabilityPester -CommandName 'git' -Available $true -Scope Context

# Mock with specific command type
Mock-CommandAvailabilityPester -CommandName 'notepad' -Available $true -CommandType 'Application' -Scope It
```

#### `Assert-MockCalled`

Verifies that a Pester 5 mock was called (wrapper around `Should -Invoke`).

```powershell
# Verify mock was called once
Assert-MockCalled -CommandName 'Get-Command' -Times 1

# Verify mock was called exactly once
Assert-MockCalled -CommandName 'Test-HasCommand' -Times 1 -Exactly

# Verify mock was called with specific parameters
Assert-MockCalled -CommandName 'Get-Command' `
    -ParameterFilter { $Name -eq 'docker' } `
    -Times 1 `
    -Exactly
```

#### `Setup-AvailableCommandMock`

Sets up Pester 5 mocks to make a command appear available. This is the recommended way to mock command availability for tests that need to verify command arguments.

```powershell
It 'Calls command with correct arguments' {
    # Set up command as available
    Setup-AvailableCommandMock -CommandName 'docker'

    # Capture arguments for verification
    $capturedArgs = $null
    Mock -CommandName 'docker' -MockWith {
        param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
        $script:capturedArgs = $Arguments
        return 'Mock output'
    }

    # Execute function under test
    Invoke-MyFunction

    # Verify arguments
    Should -Invoke -CommandName 'docker' -Times 1 -Exactly
    $script:capturedArgs | Should -Contain 'expected-arg'
}
```

**Key Features:**

- Handles `Test-CachedCommand` mocking automatically
- Clears command cache to ensure mocks work correctly
- Creates function mock so commands can be called with `&` operator
- Works with Pester 5's automatic scoping

**When to Use:**

- Use `Setup-AvailableCommandMock` when you need to verify command arguments (see Pattern 6)
- Use `Mock-CommandAvailabilityPester` when you only need to mock availability without argument verification

#### `Initialize-PesterMocks`

Sets up common Pester 5 mocks for a test context.

```powershell
BeforeEach {
    # Mock common commands as unavailable
    Initialize-PesterMocks -Commands @('git', 'docker') -Scope It

    # Also mock network operations
    Initialize-PesterMocks -Commands @('git', 'docker') -MockNetwork -Scope It
}
```

### Function-based Mocking Functions

#### `Mock-Command`

Creates a function-based mock for an external command (useful in test mode).

```powershell
# Basic mock (no-op)
Mock-Command -CommandName 'git'

# Mock with custom behavior
Mock-Command -CommandName 'git' -MockWith {
    Write-Output 'git version 2.30.0'
}

# Mock with return value
Mock-Command -CommandName 'docker' -ReturnValue $null -ExitCode 0

# Mock with output
Mock-Command -CommandName 'kubectl' -Output @('pod1', 'pod2')
```

#### `Mock-Commands`

Mocks multiple commands at once.

```powershell
Mock-Commands -CommandNames @('git', 'docker', 'kubectl', 'terraform')
```

#### `Mock-CommandAvailability`

Mocks command availability checks (function-based, not Pester).

```powershell
# Mock command as unavailable
Mock-CommandAvailability -CommandName 'docker' -Available $false

# Mock command as available
Mock-CommandAvailability -CommandName 'git' -Available $true
```

### File System Mocking

#### `Mock-FileSystem`

Mocks file system operations.

```powershell
# Using Pester 5 mock
Mock-FileSystem -Operation 'Test-Path' -Path '*.ps1' -ReturnValue $true -UsePesterMock

# Using function-based mock
Mock-FileSystem -Operation 'Test-Path' -Path 'test.txt' -ReturnValue $true
```

### Network Mocking

#### `Mock-Network`

Mocks network operations.

```powershell
# Using Pester 5 mock
Mock-Network -Operation 'Test-Connection' `
    -ReturnValue @{
        ComputerName = 'localhost'
        ResponseTime = 1
        Status = 'Success'
    } `
    -UsePesterMock

# Using function-based mock
Mock-Network -Operation 'Invoke-WebRequest' `
    -MockWith {
        [PSCustomObject]@{ StatusCode = 200; Content = 'Success' }
    }
```

### Environment Variable Mocking

#### `Mock-EnvironmentVariable`

Mocks environment variables with automatic cleanup.

```powershell
# Mock environment variable
Mock-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE' -Value '1' -RestoreOriginal

# Restore later
Restore-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE'
```

### Mock Management

#### `Restore-AllMocks`

Restores all registered mocks to their original values.

```powershell
AfterAll {
    Restore-AllMocks
}
```

## Common Patterns

### Pattern 1: Mocking Command Availability in Unit Tests

```powershell
Describe 'MyFunction' {
    Context 'When docker is unavailable' {
        BeforeEach {
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
        }

        It 'should handle missing docker gracefully' {
            # Test implementation
        }
    }
}
```

### Pattern 2: Mocking Multiple Commands

```powershell
BeforeEach {
    @('git', 'docker', 'kubectl') | ForEach-Object {
        Mock-CommandAvailabilityPester -CommandName $_ -Available $false -Scope It
    }
}
```

### Pattern 3: Mocking Network Calls

```powershell
BeforeEach {
    Mock-Network -Operation 'Invoke-WebRequest' `
        -MockWith {
            [PSCustomObject]@{
                StatusCode = 200
                Content = '{"status": "ok"}'
            }
        } `
        -UsePesterMock
}
```

### Pattern 4: Verifying Mock Calls

```powershell
It 'should call Get-Command once' {
    # Setup
    Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It

    # Execute
    MyFunction

    # Verify
    Assert-MockCalled -CommandName 'Get-Command' `
        -ParameterFilter { $Name -eq 'docker' } `
        -Times 1 `
        -Exactly
}
```

### Pattern 5: Mocking with Different Scopes

```powershell
Describe 'My Suite' {
    # Mock for entire suite
    BeforeAll {
        Mock-CommandAvailabilityPester -CommandName 'git' -Available $false -Scope Describe
    }

    Context 'Specific context' {
        # Override for this context
        BeforeEach {
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $true -Scope Context
        }

        It 'should use git' {
            # Test implementation
        }
    }
}
```

### Pattern 6: Verifying Command Arguments (Recommended Pattern)

**Problem:** You need to verify that a command was called with specific arguments.

**Solution:** Use argument capture pattern with script-scope variables.

```powershell
It 'Calls command with correct arguments' {
    # Step 1: Set up command as available
    Setup-AvailableCommandMock -CommandName 'mycommand'

    # Step 2: Capture arguments in a script-scope variable
    $capturedArgs = $null
    Mock -CommandName 'mycommand' -MockWith {
        param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
        # Capture all arguments (PowerShell expands arrays when using & command $args)
        $script:capturedArgs = $Arguments
        return 'Mock output'
    }

    # Step 3: Execute the function under test
    $result = Invoke-MyFunction -Path 'C:\test' -Recursive

    # Step 4: Verify the command was called
    Should -Invoke -CommandName 'mycommand' -Times 1 -Exactly

    # Step 5: Verify arguments (with null check for better error messages)
    if ($null -eq $script:capturedArgs) {
        throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
    }
    $script:capturedArgs | Should -Contain '-r'
    $script:capturedArgs | Should -Contain 'C:\test'
}
```

**Key Points:**

- Use `Setup-AvailableCommandMock` to make the command appear available
- Use `param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)` to capture all arguments
- Store captured arguments in `$script:capturedArgs` (script scope) to ensure they're accessible after the mock executes
- When commands are called with `& command $args`, PowerShell expands the array, so `$Arguments` contains individual elements
- Always verify the mock was called first with `Should -Invoke`, then check arguments
- Include null checks for better error messages when debugging

**Why This Pattern?**

- More reliable than `ParameterFilter` in `Should -Invoke` (handles positional parameters better)
- Works correctly with commands called via `& command $args` (PowerShell array expansion)
- Provides better error messages when arguments don't match
- Easier to debug (can inspect `$script:capturedArgs` directly)

### Pattern 6a: Using New-CommandArgumentCaptureMock Helper (Optional)

For convenience, you can use the `New-CommandArgumentCaptureMock` helper function which reduces boilerplate:

```powershell
It 'Install-ChocoPackage calls choco install' {
    # Set up argument capture mock using helper
    $mock = New-CommandArgumentCaptureMock -CommandName 'choco' -MockOutput 'Package installed successfully'

    # Execute
    { Install-ChocoPackage -Packages git 4>&1 | Out-Null } | Should -Not -Throw

    # Verify
    $mock.VerifyCalled()
    $capturedArgs = $mock.CapturedArgs()
    if ($null -eq $capturedArgs) {
        throw "Mock was called but capturedArgs is null."
    }
    $capturedArgs | Should -Contain 'install'
    $capturedArgs | Should -Contain 'git'
}
```

**When to Use the Helper:**

- ✅ When you want to reduce boilerplate code
- ✅ When function mocks don't exist (or are removed first)
- ✅ For consistency across multiple tests

**When to Use the Direct Pattern:**

- ✅ When function mocks exist from `Mock-CommandAvailabilityPester` (they may take precedence)
- ✅ When you need maximum control over the mock behavior
- ✅ When the helper doesn't work due to function mock precedence

**Note:** The helper function (`New-CommandArgumentCaptureMock`) is a convenience wrapper around Pattern 6. If you encounter issues with function mocks taking precedence, use the direct pattern instead.

## Pester 5 Scope Reference

- `It` - Mock applies only to the current `It` block (default)
- `Context` - Mock applies to all `It` blocks in the current `Context`
- `Describe` - Mock applies to all `It` blocks in the current `Describe`
- `All` - Mock applies to all tests in the file

## Best Practices

1. **Use Pester 5 mocks for unit tests** - They integrate better with Pester's test lifecycle
2. **Use function-based mocks for test mode** - When you need to prevent commands from executing during profile loading
3. **Always specify scope** - Be explicit about where your mocks apply
4. **Clean up after tests** - Use `Restore-AllMocks` in `AfterAll` blocks when using function-based mocks
5. **Use parameter filters** - Be specific about when your mocks should apply
6. **Verify mock calls** - Use `Assert-MockCalled` to ensure your code calls dependencies correctly

## Integration with Existing Tests

The mocking framework integrates seamlessly with existing test patterns:

```powershell
# Old pattern (still works)
Mock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'bat' } -MockWith { $null } -Scope It

# New pattern (more convenient)
Mock-CommandAvailabilityPester -CommandName 'bat' -Available $false -Scope It
```

Both patterns work, but the new pattern is more concise and provides better defaults.

## See Also

- [Pester 5 Documentation](https://pester.dev/docs/quick-start)
- [Pester 5 Mocking Guide](https://pester.dev/docs/commands/Mock)
- `tests/TestSupport/TestMocks.ps1` - Legacy test mocks for test mode
