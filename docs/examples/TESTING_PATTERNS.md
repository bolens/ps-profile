# Writing Tests

This guide demonstrates how to write tests following the project's standardized patterns, including test structure, TestSupport usage, and best practices.

## Overview

Tests in this project follow these patterns:

- **TestSupport.ps1** - Load test support utilities and helpers
- **Pester 5.0+** - Modern Pester syntax with `Should` assertions
- **Test Structure** - `BeforeAll`, `AfterAll`, `BeforeEach`, `AfterEach` blocks
- **Path Resolution** - Use `Get-TestRepoRoot` and `Get-TestPath` for paths
- **Mocking** - Use TestSupport mocking framework for external dependencies

## Basic Test Structure

### Minimal Test File

```powershell
# Load TestSupport.ps1 - ensure it's loaded before using its functions
$testSupportPath = Join-Path $PSScriptRoot '..\TestSupport.ps1'
if (Test-Path $testSupportPath) {
    . $testSupportPath
}
else {
    throw "TestSupport.ps1 not found at: $testSupportPath"
}

BeforeAll {
    # Ensure TestSupport functions are available
    if (-not (Get-Command Get-TestRepoRoot -ErrorAction SilentlyContinue)) {
        $testSupportPath = Join-Path $PSScriptRoot '..\TestSupport.ps1'
        if (Test-Path $testSupportPath) {
            . $testSupportPath
        }
        if (-not (Get-Command Get-TestRepoRoot -ErrorAction SilentlyContinue)) {
            throw "Get-TestRepoRoot function not available"
        }
    }

    # Get test paths
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists

    # Load module under test
    $modulePath = Join-Path $script:ProfileDir '00-bootstrap' 'ModuleLoading.ps1'
    if (Test-Path $modulePath) {
        . $modulePath
    }
    else {
        throw "Module not found at: $modulePath"
    }
}

Describe 'Module Loading Functions' {
    Context 'Import-FragmentModule' {
        It 'Loads valid module successfully' {
            $result = Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('test-modules', 'valid-module.ps1') `
                -Context 'Test: valid-module'

            $result | Should -Be $true
        }

        It 'Returns false for non-existent module' {
            $result = Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('test-modules', 'nonexistent.ps1') `
                -Context 'Test: nonexistent'

            $result | Should -Be $false
        }
    }
}
```

## TestSupport Functions

### Path Resolution

```powershell
BeforeAll {
    # Get repository root
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot

    # Get test paths (creates if doesn't exist)
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\00-bootstrap' -StartPath $PSScriptRoot -EnsureExists
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
}
```

### Loading Modules

```powershell
BeforeAll {
    # Load dependencies first
    $modulePathCachePath = Join-Path $script:BootstrapDir 'ModulePathCache.ps1'
    if (Test-Path $modulePathCachePath) {
        . $modulePathCachePath
    }

    # Load the module under test
    $moduleLoadingPath = Join-Path $script:BootstrapDir 'ModuleLoading.ps1'
    if (Test-Path $moduleLoadingPath) {
        . $moduleLoadingPath
    }
    else {
        throw "ModuleLoading.ps1 not found at: $moduleLoadingPath"
    }
}
```

## Test Organization

### Unit Tests

```powershell
# tests/unit/library-module-loading.tests.ps1

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\00-bootstrap' -StartPath $PSScriptRoot -EnsureExists

    # Load module under test
    $modulePath = Join-Path $script:BootstrapDir 'ModuleLoading.ps1'
    . $modulePath
}

Describe 'Import-FragmentModule' {
    Context 'Basic Loading' {
        It 'Loads valid module successfully' {
            # Test implementation
        }

        It 'Returns false for non-existent module' {
            # Test implementation
        }
    }

    Context 'Dependency Checking' {
        It 'Validates dependencies before loading' {
            # Test implementation
        }
    }
}
```

### Integration Tests

```powershell
# tests/integration/bootstrap/module-loading-standard.tests.ps1

BeforeAll {
    # Load TestSupport
    . $PSScriptRoot/../../TestSupport.ps1

    # Get test repository root
    $testRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot

    # Load bootstrap to get module loading functions
    $bootstrapPath = Join-Path $testRepoRoot 'profile.d' '00-bootstrap.ps1'
    if (-not (Test-Path -LiteralPath $bootstrapPath)) {
        throw "Bootstrap file not found at: $bootstrapPath"
    }

    # Clear any existing fragment loading state
    $global:__psprofile_fragment_loaded = @{}

    # Load bootstrap
    . $bootstrapPath

    # Verify module loading functions are available
    if (-not (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue)) {
        throw "Import-FragmentModule not available after loading bootstrap"
    }
}

Describe 'Module Loading Integration' {
    Context 'Fragment Loading' {
        It 'Loads fragments in correct order' {
            # Test implementation
        }
    }
}
```

## Mocking

### Mocking Commands

```powershell
BeforeAll {
    # Load TestSupport (includes mocking framework)
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
}

Describe 'Function with External Command' {
    Context 'When command is available' {
        It 'Executes command successfully' {
            # Mock the command
            Mock Test-CachedCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $true }
            Mock docker -MockWith { "Docker version 20.10.0" }

            # Test the function
            $result = Invoke-Docker ps

            # Verify
            Should -Invoke docker -Exactly -Times 1
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When command is not available' {
        It 'Shows warning message' {
            # Mock command as unavailable
            Mock Test-CachedCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock Write-MissingToolWarning -MockWith { }

            # Test the function
            Invoke-Docker ps

            # Verify warning was shown
            Should -Invoke Write-MissingToolWarning -Exactly -Times 1
        }
    }
}
```

### Mocking File System

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
}

Describe 'File Operations' {
    Context 'File Existence Checks' {
        It 'Handles existing files' {
            # Create test file in TestDrive
            $testFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $testFile -Value "test content"

            # Test
            $result = Test-Path $testFile
            $result | Should -Be $true
        }

        It 'Handles non-existent files' {
            $testFile = Join-Path $TestDrive 'nonexistent.txt'

            $result = Test-Path $testFile
            $result | Should -Be $false
        }
    }
}
```

## Test Data Setup

### Using TestDrive

```powershell
BeforeAll {
    # Create test directory structure
    $script:TestFragmentRoot = Join-Path $TestDrive 'TestFragmentRoot'
    $script:TestModulesDir = Join-Path $script:TestFragmentRoot 'test-modules'
    $script:TestSubDir = Join-Path $script:TestModulesDir 'subdir'

    New-Item -ItemType Directory -Path $script:TestFragmentRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $script:TestModulesDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:TestSubDir -Force | Out-Null

    # Create test module files
    $testModuleContent = @'
function global:Test-ValidFunction {
    Write-Output "Test function"
}
'@
    Set-Content -Path (Join-Path $script:TestModulesDir 'valid-module.ps1') -Value $testModuleContent
}

AfterAll {
    # Cleanup is automatic with TestDrive, but you can add custom cleanup
    Remove-Item -Path $script:TestFragmentRoot -Recurse -Force -ErrorAction SilentlyContinue
}
```

## Best Practices

### 1. Always Load TestSupport First

```powershell
# ✅ CORRECT: Load TestSupport at the top
$testSupportPath = Join-Path $PSScriptRoot '..\TestSupport.ps1'
. $testSupportPath

# ❌ WRONG: Use functions without loading TestSupport
$repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot  # May not be available
```

### 2. Use TestSupport Path Functions

```powershell
# ✅ CORRECT: Use Get-TestRepoRoot and Get-TestPath
$script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
$script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists

# ❌ WRONG: Hardcode paths
$script:ProfileDir = "C:\Users\...\profile.d"  # Not portable
```

### 3. Clean Up in AfterAll

```powershell
# ✅ CORRECT: Clean up test data
AfterAll {
    Remove-Item -Path $script:TestFragmentRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path 'Function:\Test-TempFunction' -Force -ErrorAction SilentlyContinue
}

# ❌ WRONG: Leave test artifacts
# No cleanup - may affect other tests
```

### 4. Use Descriptive Test Names

```powershell
# ✅ CORRECT: Descriptive test names
It 'Loads valid module successfully' { }
It 'Returns false for non-existent module' { }
It 'Validates dependencies before loading' { }

# ❌ AVOID: Vague test names
It 'Test 1' { }
It 'Works' { }
```

### 5. Test Both Success and Failure Paths

```powershell
# ✅ CORRECT: Test both paths
Context 'Module Loading' {
    It 'Loads valid module successfully' {
        # Success path
    }

    It 'Returns false for non-existent module' {
        # Failure path
    }
}

# ❌ AVOID: Only testing success
Context 'Module Loading' {
    It 'Loads valid module successfully' {
        # Only success path tested
    }
}
```

## Test Checklist

When writing tests:

- [ ] Load `TestSupport.ps1` at the top of the file
- [ ] Use `Get-TestRepoRoot` for repository root
- [ ] Use `Get-TestPath` for relative paths
- [ ] Load dependencies in `BeforeAll`
- [ ] Load module under test in `BeforeAll`
- [ ] Create test data in `BeforeAll` or `BeforeEach`
- [ ] Clean up test data in `AfterAll` or `AfterEach`
- [ ] Use descriptive test names
- [ ] Test both success and failure paths
- [ ] Use mocking for external dependencies
- [ ] Use `TestDrive` for temporary files
- [ ] Verify function availability before testing
- [ ] Use appropriate Pester assertions (`Should -Be`, `Should -Not -BeNullOrEmpty`, etc.)

## Notes

- Tests should be independent (no shared state between tests)
- Use `TestDrive` for temporary files (automatically cleaned up)
- Mock external commands and file system operations when possible
- Load TestSupport before using any test helper functions
- Use `BeforeAll` for expensive setup (module loading, path resolution)
- Use `BeforeEach` for test-specific setup
- Always verify function/module availability before testing
- Tests should run in any order (no dependencies between tests)
