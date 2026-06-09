# ===============================================
# TestSupport.ps1
# Test support utilities loader
# ===============================================
# This file loads all test support modules from the TestSupport subdirectory.
# All test utilities are organized into focused modules for better maintainability.

# Suppress all confirmation prompts for non-interactive test execution
# Tests should never require user input - always run non-interactively
# This must be set at the very top, before any operations that might prompt
$ErrorActionPreference = 'Stop'
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'

# Enable strict mode for enhanced error checking in tests
# This catches uninitialized variables, typos, and other common errors
# Scoped to script to avoid affecting parent scopes
Set-StrictMode -Version Latest

# Pre-initialize script-scoped flags for Set-StrictMode compatibility
$script:TestSupportDefaultAssumedCommandsSet = $null

# Set default parameter values to suppress prompts for Remove-Item and other operations
# This ensures tests can clean up Function:\ paths without prompting
if (-not $PSDefaultParameterValues) {
    $PSDefaultParameterValues = @{}
}
$PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$PSDefaultParameterValues['Remove-Item:Force'] = $true
$PSDefaultParameterValues['Remove-Item:Recurse'] = $true
$PSDefaultParameterValues['Clear-Item:Confirm'] = $false
$PSDefaultParameterValues['Clear-Item:Force'] = $true

# Set globally as well to ensure it applies in all scopes
if (-not $global:PSDefaultParameterValues) {
    $global:PSDefaultParameterValues = @{}
}
$global:PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$global:PSDefaultParameterValues['Remove-Item:Force'] = $true
$global:PSDefaultParameterValues['Remove-Item:Recurse'] = $true
$global:PSDefaultParameterValues['Clear-Item:Confirm'] = $false
$global:PSDefaultParameterValues['Clear-Item:Force'] = $true

# Set environment variables to suppress confirmations in profile fragments
$env:PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'
$env:PS_PROFILE_FORCE = '1'

# TestSupport is only loaded by the test runner and individual test files.
# Enable test mode immediately so profile fragments and mocks behave non-interactively.
$env:PS_PROFILE_TEST_MODE = '1'
$env:PS_PROFILE_NONINTERACTIVE = '1'

# Normalize TMPDIR for Linux environments where only TEMP/TMP may be set.
if ([string]::IsNullOrWhiteSpace($env:TMPDIR)) {
    $env:TMPDIR = [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar)
}

function global:Read-Host {
    <#
    .SYNOPSIS
        Non-interactive Read-Host stub for automated test execution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Remaining,

        [switch]$AsSecureString
    )

    $prompt = if ($Remaining.Count -gt 0) { [string]$Remaining[0] } else { 'input' }
    throw "Read-Host is disabled during automated test execution. Prompt: '$prompt'. Mock Read-Host in tests that require interactive behavior."
}

<#
.SYNOPSIS
    Resolves the path to TestSupport.ps1 from any test file location.

.DESCRIPTION
    Walks up from the specified path until it finds TestSupport.ps1.
    This allows test files in any subdirectory to reliably load TestSupport.ps1.

.PARAMETER StartPath
    Path to start searching from. Defaults to the calling script's directory.

.EXAMPLE
    $testSupportPath = & { $current = Get-Item $PSScriptRoot; while ($null -ne $current) { $path = Join-Path $current.FullName 'TestSupport.ps1'; if (Test-Path $path) { return $path }; $current = $current.Parent } }
    . $testSupportPath
#>
function Get-TestSupportPath {
    param(
        [string]$StartPath = $PSScriptRoot
    )

    $current = Get-Item -LiteralPath $StartPath
    
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if ($testSupportPath -and -not [string]::IsNullOrWhiteSpace($testSupportPath) -and (Test-Path -LiteralPath $testSupportPath)) {
            return $testSupportPath
        }
        
        # Stop if we've gone beyond the tests directory
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) {
            break
        }
        
        $current = $current.Parent
    }
    
    throw "Unable to locate TestSupport.ps1 starting from $StartPath"
}

$testSupportDir = Join-Path $PSScriptRoot 'TestSupport'

# Load test support modules in dependency order
if ($testSupportDir -and -not [string]::IsNullOrWhiteSpace($testSupportDir) -and (Test-Path -LiteralPath $testSupportDir)) {
    # Load TestPaths first (used by other modules)
    $testPathsPath = Join-Path $testSupportDir 'TestPaths.ps1'
    if ($testPathsPath -and -not [string]::IsNullOrWhiteSpace($testPathsPath) -and (Test-Path -LiteralPath $testPathsPath)) {
        . $testPathsPath
    }
    
    # Load TestExecution (depends on TestPaths)
    $testExecutionPath = Join-Path $testSupportDir 'TestExecution.ps1'
    if ($testExecutionPath -and -not [string]::IsNullOrWhiteSpace($testExecutionPath) -and (Test-Path -LiteralPath $testExecutionPath)) {
        . $testExecutionPath
    }

    # Load TestBackup (depends on TestPaths and TestExecution)
    $testBackupPath = Join-Path $testSupportDir 'TestBackup.ps1'
    if ($testBackupPath -and -not [string]::IsNullOrWhiteSpace($testBackupPath) -and (Test-Path -LiteralPath $testBackupPath)) {
        . $testBackupPath
    }

    # Load TestDriftLock (depends on TestPaths)
    $testDriftLockPath = Join-Path $testSupportDir 'TestDriftLock.ps1'
    if ($testDriftLockPath -and -not [string]::IsNullOrWhiteSpace($testDriftLockPath) -and (Test-Path -LiteralPath $testDriftLockPath)) {
        . $testDriftLockPath
    }
    
    # Load TestNpmHelpers (standalone)
    $testNpmHelpersPath = Join-Path $testSupportDir 'TestNpmHelpers.ps1'
    if ($testNpmHelpersPath -and -not [string]::IsNullOrWhiteSpace($testNpmHelpersPath) -and (Test-Path -LiteralPath $testNpmHelpersPath)) {
        . $testNpmHelpersPath
    }
    
    # Load TestPythonHelpers (standalone)
    $testPythonHelpersPath = Join-Path $testSupportDir 'TestPythonHelpers.ps1'
    if ($testPythonHelpersPath -and -not [string]::IsNullOrWhiteSpace($testPythonHelpersPath) -and (Test-Path -LiteralPath $testPythonHelpersPath)) {
        . $testPythonHelpersPath
    }
    
    # Load TestScoopHelpers (standalone)
    $testScoopHelpersPath = Join-Path $testSupportDir 'TestScoopHelpers.ps1'
    if ($testScoopHelpersPath -and -not [string]::IsNullOrWhiteSpace($testScoopHelpersPath) -and (Test-Path -LiteralPath $testScoopHelpersPath)) {
        . $testScoopHelpersPath
    }

    # Load TestLinuxPackageHelpers (standalone)
    $testLinuxPackageHelpersPath = Join-Path $testSupportDir 'TestLinuxPackageHelpers.ps1'
    if ($testLinuxPackageHelpersPath -and -not [string]::IsNullOrWhiteSpace($testLinuxPackageHelpersPath) -and (Test-Path -LiteralPath $testLinuxPackageHelpersPath)) {
        . $testLinuxPackageHelpersPath
    }
    
    # Load TestMocks (standalone, but should load early)
    $testMocksPath = Join-Path $testSupportDir 'TestMocks.ps1'
    if ($testMocksPath -and -not [string]::IsNullOrWhiteSpace($testMocksPath) -and (Test-Path -LiteralPath $testMocksPath)) {
        . $testMocksPath
    }

    # Load TerminalTestStubs (Write-Host / Get-History / Read-Host stubs for terminal tests)
    $terminalStubsPath = Join-Path $testSupportDir 'TerminalTestStubs.ps1'
    if ($terminalStubsPath -and -not [string]::IsNullOrWhiteSpace($terminalStubsPath) -and (Test-Path -LiteralPath $terminalStubsPath)) {
        . $terminalStubsPath
    }

    # Load command availability stubs (depends on TestMocks for TestRegisteredMockCommands)
    $testCommandAvailabilityPath = Join-Path $testSupportDir 'TestCommandAvailability.ps1'
    if ($testCommandAvailabilityPath -and -not [string]::IsNullOrWhiteSpace($testCommandAvailabilityPath) -and (Test-Path -LiteralPath $testCommandAvailabilityPath)) {
        . $testCommandAvailabilityPath
    }

    # Load environment variable stubs for integration tests
    $testEnvironmentStubsPath = Join-Path $testSupportDir 'TestEnvironmentStubs.ps1'
    if ($testEnvironmentStubsPath -and -not [string]::IsNullOrWhiteSpace($testEnvironmentStubsPath) -and (Test-Path -LiteralPath $testEnvironmentStubsPath)) {
        . $testEnvironmentStubsPath
    }

    # Load reflection wrappers for Collections module error-path tests
    $testReflectionHelpersPath = Join-Path $testSupportDir 'TestReflectionHelpers.ps1'
    if ($testReflectionHelpersPath -and -not [string]::IsNullOrWhiteSpace($testReflectionHelpersPath) -and (Test-Path -LiteralPath $testReflectionHelpersPath)) {
        . $testReflectionHelpersPath
    }
    
    # Load TestModuleLoading (depends on nothing, but used by tests)
    $testModuleLoadingPath = Join-Path $testSupportDir 'TestModuleLoading.ps1'
    if ($testModuleLoadingPath -and -not [string]::IsNullOrWhiteSpace($testModuleLoadingPath) -and (Test-Path -LiteralPath $testModuleLoadingPath)) {
        . $testModuleLoadingPath
    }
    
    # Load ToolDetection (standalone, provides tool availability checking)
    $toolDetectionPath = Join-Path $testSupportDir 'ToolDetection.ps1'
    if ($toolDetectionPath -and -not [string]::IsNullOrWhiteSpace($toolDetectionPath) -and (Test-Path -LiteralPath $toolDetectionPath)) {
        . $toolDetectionPath
    }
}

# Provide default assumed commands for optional tooling during tests to avoid noisy warnings
if ($null -eq $script:TestSupportDefaultAssumedCommandsSet) {
    $script:TestSupportDefaultAssumedCommandsSet = $true

    $defaultAssumedCommands = @('scoop', 'uv', 'pnpm', 'eza', 'navi', 'btm', 'bottom', 'procs', 'dust', 'pixi')
    $existingAssumedCommands = @()

    if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_ASSUME_COMMANDS)) {
        $existingAssumedCommands = $env:PS_PROFILE_ASSUME_COMMANDS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    $combinedAssumedCommands = ($existingAssumedCommands + $defaultAssumedCommands) | Sort-Object -Unique

    if ($combinedAssumedCommands) {
        $env:PS_PROFILE_ASSUME_COMMANDS = [string]::Join(',', $combinedAssumedCommands)
    }

    $defaultSuppressedFragments = @('99-test-*')
    $existingSuppressedFragments = @()

    if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS)) {
        $existingSuppressedFragments = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    $combinedSuppressed = ($existingSuppressedFragments + $defaultSuppressedFragments) | Sort-Object -Unique

    if ($combinedSuppressed) {
        $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = [string]::Join(',', $combinedSuppressed)
    }
}

# Reset cross-file pollution before initializing mocks for each test file
if (Get-Command Reset-TestIsolationState -ErrorAction SilentlyContinue) {
    Reset-TestIsolationState
}

# Auto-initialize mocks whenever TestSupport loads (test mode is always enabled above)
if (Get-Command Initialize-TestMocks -ErrorAction SilentlyContinue) {
    Initialize-TestMocks
}

<#
.SYNOPSIS
    Registers an AfterEach hook that cleans transient test artifacts.
.DESCRIPTION
    Must be called from within a Describe/Context/BeforeAll block. When TestSupport
    is dot-sourced from a file's top level, this is not registered automatically.
#>
function Add-TestPerTestCleanup {
    if (-not (Get-Command AfterEach -ErrorAction SilentlyContinue -CommandType Function)) {
        return
    }

    AfterEach {
        if (Get-Command Remove-TestArtifacts -ErrorAction SilentlyContinue) {
            Remove-TestArtifacts
        }
    }
}

function Test-IsDotSourcedFromPesterHook {
    $hookCommands = @('BeforeAll', 'BeforeEach', 'BeforeDiscovery', 'Describe', 'Context')
    foreach ($frame in (Get-PSCallStack | Select-Object -Skip 1 -First 10)) {
        if ($frame.Command -in $hookCommands) {
            return $true
        }
    }

    return $false
}

if (Test-IsDotSourcedFromPesterHook) {
    Add-TestPerTestCleanup
}
