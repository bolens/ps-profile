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
    
    # Load TestMocks (standalone, but should load early)
    $testMocksPath = Join-Path $testSupportDir 'TestMocks.ps1'
    if ($testMocksPath -and -not [string]::IsNullOrWhiteSpace($testMocksPath) -and (Test-Path -LiteralPath $testMocksPath)) {
        . $testMocksPath
    }

    # Load Mocking modules (comprehensive mocking framework)
    # Import all mocking sub-modules in dependency order
    $mockingDir = Join-Path $testSupportDir 'Mocking'
    if ($mockingDir -and -not [string]::IsNullOrWhiteSpace($mockingDir) -and (Test-Path -LiteralPath $mockingDir)) {
        # Import MockRegistry first (used by other modules)
        $mockRegistryPath = Join-Path $mockingDir 'MockRegistry.psm1'
        if ($mockRegistryPath -and -not [string]::IsNullOrWhiteSpace($mockRegistryPath) -and (Test-Path -LiteralPath $mockRegistryPath)) {
            Import-Module $mockRegistryPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
        }
        
        # Import other modules (they depend on MockRegistry)
        $mockingModules = @(
            'MockCommand.psm1',
            'MockFileSystem.psm1',
            'MockNetwork.psm1',
            'MockEnvironment.psm1',
            'MockPython.psm1',
            'MockReflection.psm1',
            'PesterMocks.psm1'
        )
        
        foreach ($module in $mockingModules) {
            $modulePath = Join-Path $mockingDir $module
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                Import-Module $modulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
        }
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
if (-not (Get-Variable -Name 'TestSupportDefaultAssumedCommandsSet' -Scope Script -ErrorAction SilentlyContinue)) {
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

# Auto-initialize mocks if test mode is already set when TestSupport.ps1 loads
if ($env:PS_PROFILE_TEST_MODE -eq '1') {
    if (Get-Command Initialize-TestMocks -ErrorAction SilentlyContinue) {
        Initialize-TestMocks
    }
}

# Register cleanup to run after tests
if ($env:PS_PROFILE_TEST_MODE -eq '1') {
    if (Get-Command Remove-TestArtifacts -ErrorAction SilentlyContinue) {
        # Clean up any existing artifacts
        Remove-TestArtifacts
    }
}
