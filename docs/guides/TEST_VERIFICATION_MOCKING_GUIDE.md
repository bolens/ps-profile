# Test Stub Integration Guide

This guide documents how to use the TestSupport stub helpers when fixing and improving tests. The suite no longer uses Pester `Mock` for command availability, network, or filesystem operations.

> **See also:** [Testing Guide](TESTING.md) (structure and running tests), [Testing Patterns](../examples/TESTING_PATTERNS.md) (code examples), [Tool Requirements](TOOL_REQUIREMENTS.md) (optional tools). Full index: [Related Testing Documentation](TESTING.md#related-testing-documentation).

Load TestSupport once per file:

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')  # adjust relative path as needed
}
```

`TestSupport.ps1` dot-sources the stub modules below. `Reset-TestIsolationState` runs automatically on load and clears state between test files.

## Quick Reference

### Command availability

```powershell
BeforeEach {
    # Make a command appear available (creates a no-op stub function)
    Set-TestCommandAvailabilityState -CommandName 'git'

    # Make a command appear unavailable
    Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false

    # Mark several commands unavailable (preferred when real binaries exist on PATH)
    Mark-TestCommandsUnavailable -CommandNames @('docker', 'podman', 'kubectl')
}
```

When real tools on PATH interfere with stubs, clear the bootstrap cache in `BeforeEach`:

```powershell
if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
    Clear-TestCachedCommandCache | Out-Null
}
```

### Capturing command invocations

```powershell
It 'Calls command with correct arguments' {
    Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

    $result = Invoke-ClamAVScan -Path 'C:\test' -Recursive

    Assert-TestCommandInvokedExactlyOnce
    $args = Get-TestCommandInvocationArgsFlat
    $args | Should -Contain '-r'
    $args | Should -Contain 'C:\test'
    $result | Should -Be 'Scan results'
}
```

Use `-OnInvoke { ... }` for custom return values (e.g. web responses):

```powershell
Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -MarkAvailable:$false -OnInvoke {
    [PSCustomObject]@{
        StatusCode = 200
        Content    = 'Mocked weather data'
        Headers    = @{}
    }
}
```

Use `Set-TestCommandThrowingMock` to simulate command failures:

```powershell
Set-TestCommandThrowingMock -CommandName 'clamscan' -Message 'Execution failed'
```

### Environment variables

```powershell
BeforeAll {
    Mock-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE' -Value '1' -RestoreOriginal
}

AfterAll {
    Restore-AllMocks
}
```

### Reflection wrappers (Collections module error paths)

`TestReflectionHelpers.ps1` is loaded automatically. Wrapper functions:

- `Invoke-MakeGenericTypeWrapper`
- `Invoke-CreateInstanceWrapper`
- `Invoke-TypeConstructorWrapper`

Override them in individual tests to simulate failure paths; they are restored by `Reset-TestIsolationState`.

## Common Patterns for Test Fixes

### Pattern 1: Tool-dependent tests

**Problem:** Test fails when tool is missing, or passes incorrectly when a real binary exists on PATH.

**Solution:**

```powershell
Describe 'Docker Functions' {
    Context 'When docker is unavailable' {
        BeforeEach {
            Mark-TestCommandsUnavailable -CommandNames 'docker'
        }

        It 'should handle missing docker gracefully' {
            { Get-ContainerEngineInfo } | Should -Not -Throw
        }
    }

    Context 'When docker is available' {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'docker'
        }

        It 'should use docker' {
            # Test implementation
        }
    }
}
```

### Pattern 2: Network-dependent tests

**Problem:** Test fails due to network calls.

**Solution:** Stub `Invoke-WebRequest` (or the cmdlet your code calls) with `Setup-CapturingCommandMock`:

```powershell
BeforeEach {
    Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -MarkAvailable:$false -OnInvoke {
        [PSCustomObject]@{
            StatusCode = 200
            Content    = '{"status": "ok"}'
            Headers    = @{}
        }
    }
}
```

### Pattern 3: File system tests

**Problem:** Test modifies files or requires specific file structure.

**Solution:** Prefer real temp directories via `Get-TestPath` / `New-TestTempDirectory` rather than mocking `Test-Path` or `Get-Content`. Create fixtures under a disposable temp root and clean up in `AfterEach`.

### Pattern 4: Environment variable tests

**Problem:** Test depends on environment variables.

**Solution:**

```powershell
BeforeAll {
    Mock-EnvironmentVariable -Name 'EDITOR' -Value $null
}

AfterAll {
    Restore-AllMocks
}
```

### Pattern 5: Verifying command arguments (recommended pattern)

**Problem:** You need to verify that an external command was called with specific arguments via `& command $args`.

**Solution:** Use `Setup-CapturingCommandMock` and inspect captured args.

```powershell
It 'Calls command with correct arguments' {
    Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

    $result = Invoke-ClamAVScan -Path 'C:\test' -Recursive

    Assert-TestCommandInvokedExactlyOnce
    $args = Get-TestCommandInvocationArgsFlat
    $args | Should -Contain '-r'
    $args | Should -Contain 'C:\test'
    $result | Should -Be 'Scan results'
}
```

**Key points:**

- **`Set-TestCommandAvailabilityState`** — marks a command available and installs a basic stub; use before tests that only check availability
- **`Setup-CapturingCommandMock`** — marks available (by default), replaces the stub with an argument-capturing function, and records invocations in `$global:TestCommandInvocationCaptures`
- **`Get-TestCommandInvocationArgsFlat`** — returns flattened args from the last capture (handles splatted/array expansion)
- **`Assert-TestCommandInvokedExactlyOnce`** — asserts exactly one invocation was recorded

**Common mistakes to avoid:**

- ❌ Relying on `Set-TestCommandAvailabilityState` alone when a real binary exists on PATH — use `Mark-TestCommandsUnavailable` first, or clear the cache
- ❌ Forgetting to call `Setup-CapturingCommandMock` when you need to assert arguments — the default availability stub does not capture args
- ❌ Using Pester `Mock` for command availability — stubs in TestSupport work across scopes without Pester mock isolation issues

## Implementation Checklist

When fixing a test file:

- [ ] Dot-source `TestSupport.ps1` in `BeforeAll`
- [ ] Identify external dependencies (tools, network, files, environment)
- [ ] Use `Set-TestCommandAvailabilityState` / `Mark-TestCommandsUnavailable` for tool availability
- [ ] Use `Setup-CapturingCommandMock` when verifying command arguments or custom output
- [ ] Use `Mock-EnvironmentVariable` for environment variables
- [ ] Use real temp paths for filesystem scenarios
- [ ] Call `Restore-AllMocks` in `AfterAll` when using environment stubs
- [ ] Verify test passes with stubs on a machine that has (and lacks) the real tools

## Cleanup

### Per-test / per-file isolation

- `Reset-TestIsolationState` runs when TestSupport loads and clears availability overrides, capture state, and registered stub functions
- `Clear-TestCommandInvocationCapture` resets argument capture between tests when needed

### Environment stubs

- `Restore-AllMocks` in `AfterAll` restores environment variables registered via `Mock-EnvironmentVariable`

## Examples by Test Category

### Tools tests

```powershell
BeforeEach {
    Mark-TestCommandsUnavailable -CommandNames @('aws', 'az', 'gcloud')
}
```

### System / environment tests

```powershell
AfterAll {
    Restore-AllMocks
}

It 'sets EDITOR default when not set' {
    Mock-EnvironmentVariable -Name 'EDITOR' -Value $null
    # ...
}
```

### Network tests

```powershell
BeforeEach {
    Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -MarkAvailable:$false -OnInvoke {
        [PSCustomObject]@{ StatusCode = 200; Content = 'Success'; Headers = @{} }
    }
}
```

## See Also

### TestSupport source files

- `tests/TestSupport/TestCommandAvailability.ps1` — `Set-TestCommandAvailabilityState`, availability stub install/clear
- `tests/TestSupport/TestMocks.ps1` — `Setup-CapturingCommandMock`, `Initialize-TestMocks`, capture helpers
- `tests/TestSupport/TestEnvironmentStubs.ps1` — `Mock-EnvironmentVariable`, `Restore-AllMocks`
- `tests/TestSupport/TestReflectionHelpers.ps1` — reflection wrappers for Collections error-path tests
- `tests/TestSupport/ToolDetection.ps1` — container engine helpers, `Mark-TestCommandsUnavailable`

### Related testing documentation

| Guide | Purpose |
| ----- | ------- |
| [Testing Guide](TESTING.md) | **Primary** — structure, running tests, runner flags |
| [Test Stub Guide](TEST_VERIFICATION_MOCKING_GUIDE.md) | This doc — TestSupport stubs and isolation |
| [Testing Patterns](../examples/TESTING_PATTERNS.md) | Code examples for writing tests |
| [Coverage Verification](VERIFY_COVERAGE.md) | `analyze-coverage.ps1` workflows |
| [Development Guide](DEVELOPMENT.md) | Setup, workflow, advanced runner features |
| [Tool Requirements](TOOL_REQUIREMENTS.md) | Required and optional test tools |
