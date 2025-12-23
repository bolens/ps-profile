# Mocking Framework Integration Guide

This guide documents how to use the mocking framework when fixing and improving tests during the test verification process.

## Quick Reference

### Mocking Command Availability

```powershell
BeforeEach {
    # Mock command as unavailable (for graceful skipping)
    Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It

    # Mock command as available (for positive tests)
    Mock-CommandAvailabilityPester -CommandName 'git' -Available $true -Scope It
}
```

### Mocking Multiple Commands

```powershell
BeforeEach {
    @('docker', 'podman', 'kubectl') | ForEach-Object {
        Mock-CommandAvailabilityPester -CommandName $_ -Available $false -Scope It
    }
}
```

### Mocking Network Operations

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

### Mocking File System Operations

```powershell
BeforeEach {
    Mock-FileSystem -Operation 'Test-Path' `
        -Path 'profile.d\00-bootstrap.ps1' `
        -ReturnValue $true `
        -UsePesterMock
}
```

### Mocking Environment Variables

```powershell
BeforeEach {
    Mock-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE' -Value '1' -RestoreOriginal
}

AfterAll {
    Restore-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE'
}
```

## Common Patterns for Test Fixes

### Pattern 1: Tool-Dependent Tests

**Problem:** Test fails when tool is missing

**Solution:**

```powershell
Describe 'Docker Functions' {
    Context 'When docker is unavailable' {
        BeforeEach {
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
        }

        It 'should handle missing docker gracefully' {
            # Test should skip or handle gracefully
            { Get-ContainerEngineInfo } | Should -Not -Throw
        }
    }

    Context 'When docker is available' {
        BeforeEach {
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
        }

        It 'should use docker' {
            # Test implementation
        }
    }
}
```

### Pattern 2: Network-Dependent Tests

**Problem:** Test fails due to network calls

**Solution:**

```powershell
BeforeEach {
    Mock-Network -Operation 'Invoke-WebRequest' `
        -MockWith {
            [PSCustomObject]@{
                StatusCode = 200
                Content = 'Success'
            }
        } `
        -UsePesterMock
}
```

### Pattern 3: File System Tests

**Problem:** Test modifies files or requires specific file structure

**Solution:**

```powershell
BeforeEach {
    # Mock file existence
    Mock-FileSystem -Operation 'Test-Path' `
        -Path 'profile.d\*.ps1' `
        -ReturnValue $true `
        -UsePesterMock

    # Mock file reading
    Mock-FileSystem -Operation 'Get-Content' `
        -Path 'profile.d\00-bootstrap.ps1' `
        -ReturnValue '# Bootstrap content' `
        -UsePesterMock
}
```

### Pattern 4: Environment Variable Tests

**Problem:** Test depends on environment variables

**Solution:**

```powershell
BeforeAll {
    Mock-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE' -Value '1' -RestoreOriginal
}

AfterAll {
    Restore-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE'
}
```

### Pattern 5: Verifying Command Arguments (Recommended Pattern)

**Problem:** You need to verify that a command was called with specific arguments, especially when the command is called via `& command $args`.

**Solution:** Use the argument capture pattern with script-scope variables.

```powershell
It 'Calls command with correct arguments' {
    # Step 1: Set up command as available
    Setup-AvailableCommandMock -CommandName 'clamscan'

    # Step 2: Capture arguments in a script-scope variable
    $capturedArgs = $null
    Mock -CommandName 'clamscan' -MockWith {
        param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
        # Capture all arguments (PowerShell expands arrays when using & command $args)
        $script:capturedArgs = $Arguments
        return 'Scan results'
    }

    # Step 3: Execute the function under test
    $result = Invoke-ClamAVScan -Path 'C:\test' -Recursive

    # Step 4: Verify the command was called
    Should -Invoke -CommandName 'clamscan' -Times 1 -Exactly

    # Step 5: Verify arguments (with null check for better error messages)
    if ($null -eq $script:capturedArgs) {
        throw "Mock was called but capturedArgs is null. Mock may not be intercepting correctly."
    }
    $script:capturedArgs | Should -Contain '-r'
    $script:capturedArgs | Should -Contain 'C:\test'
}
```

**Key Points:**

- **Use `Setup-AvailableCommandMock`** - Makes the command appear available and handles cache clearing
- **Use `param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)`** - Captures all arguments reliably, including when called positionally
- **Store in `$script:capturedArgs`** - Script scope ensures the variable is accessible after the mock executes
- **PowerShell expands arrays** - When commands are called with `& command $args`, PowerShell expands the array, so `$Arguments` contains individual elements, not a nested array
- **Verify mock was called first** - Use `Should -Invoke -CommandName 'command' -Times 1 -Exactly` before checking arguments
- **Include null checks** - Provides better error messages when debugging

**Why This Pattern Instead of ParameterFilter?**

- More reliable with positional parameters
- Works correctly with `& command $args` calls (handles array expansion)
- Better error messages when arguments don't match
- Easier to debug (can inspect `$script:capturedArgs` directly)
- Avoids issues with Pester's `ParameterFilter` not matching positional calls correctly

**Common Mistakes to Avoid:**

- ❌ Using `ParameterFilter` in `Should -Invoke` - Doesn't work reliably with positional parameters
- ❌ Using local variables instead of script-scope - Variables won't be accessible after mock execution
- ❌ Not checking for null - Harder to debug when mock isn't intercepting correctly
- ❌ Not using `Setup-AvailableCommandMock` - Cache issues can cause mocks to fail

## Implementation Checklist

When fixing a test file:

- [ ] Identify external dependencies (tools, network, files, environment)
- [ ] Add appropriate mocks for missing dependencies
- [ ] Use `Mock-CommandAvailabilityPester` for tool availability
- [ ] Use `Mock-Network` for network operations
- [ ] Use `Mock-FileSystem` for file operations
- [ ] Use `Mock-EnvironmentVariable` for environment variables
- [ ] Ensure proper scope (It, Context, Describe)
- [ ] Add cleanup in AfterAll if using function-based mocks
- [ ] Verify test passes with mocks
- [ ] Document mocking pattern in test file comments

## Scope Guidelines

- **It scope** - Mock applies only to current test (most common)
- **Context scope** - Mock applies to all tests in context
- **Describe scope** - Mock applies to all tests in describe block
- **All scope** - Mock applies to all tests in file

**Best Practice:** Start with `It` scope and expand only if needed.

## Cleanup

### Pester 5 Mocks

- Automatically cleaned up by Pester
- No manual cleanup needed

### Function-based Mocks

- Use `Restore-AllMocks` in `AfterAll` blocks
- Or restore individual mocks with `Restore-EnvironmentVariable`, etc.

## Examples by Test Category

### Tools Tests

```powershell
BeforeEach {
    # Mock tools as unavailable for graceful skipping
    Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false -Scope It
    Mock-CommandAvailabilityPester -CommandName 'az' -Available $false -Scope It
    Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false -Scope It
}
```

### System Tests

```powershell
BeforeEach {
    # Mock file system operations
    Mock-FileSystem -Operation 'Get-ChildItem' `
        -Path 'profile.d' `
        -ReturnValue @(
            [PSCustomObject]@{ Name = '00-bootstrap.ps1' }
        ) `
        -UsePesterMock
}
```

### Network Tests

```powershell
BeforeEach {
    # Mock network connectivity
    Mock-Network -Operation 'Test-Connection' `
        -ReturnValue @{
            ComputerName = 'localhost'
            ResponseTime = 1
            Status = 'Success'
        } `
        -UsePesterMock
}
```

## See Also

- `tests/TestSupport/MOCKING.md` - Comprehensive mocking documentation
- `tests/TestSupport/Mocking/README.md` - Module structure documentation
- `tests/TestSupport/Mocking/PesterMocks.psm1` - Pester 5 mocking functions
- `tests/TestSupport/Mocking/MockCommand.psm1` - Command mocking functions
