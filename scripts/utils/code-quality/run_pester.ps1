<#
scripts/utils/run_pester.ps1

.SYNOPSIS
    Runs Pester tests for the PowerShell profile.

.DESCRIPTION
    Ensures Pester is available and runs the test suite in this repository. Can run all tests
    or a specific test file. Optionally includes code coverage reporting.

.PARAMETER TestFile
    Optional path to a specific test file to run. If not specified, runs all tests in the
    tests directory.

.PARAMETER Coverage
    If specified, enables code coverage reporting for profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run_pester.ps1

    Runs all Pester tests in the tests directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run_pester.ps1 -TestFile tests\profile.tests.ps1

    Runs only the profile.tests.ps1 test file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run_pester.ps1 -Coverage

    Runs all tests with code coverage reporting enabled.
#>

param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Test file does not exist: $_"
            }
            $true
        })]
    [string]$TestFile = "",
    [switch]$Coverage
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $testsDir = Join-Path $repoRoot 'tests'
    $profileDir = Join-Path $repoRoot 'profile.d'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Ensure Pester 5+ is available and imported
$requiredPesterVersion = [version]'5.0.0'

try {
    Ensure-ModuleAvailable -ModuleName 'Pester'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$installedPester = Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1
if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    try {
        Write-ScriptMessage -Message "Installing Pester $requiredPesterVersion or newer"
        Install-RequiredModule -ModuleName 'Pester' -Scope 'CurrentUser' -Force
        $installedPester = Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

if (-not $installedPester -or $installedPester.Version -lt $requiredPesterVersion) {
    $message = "Pester $requiredPesterVersion or newer is required but could not be installed."
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $message
}

try {
    Import-Module -Name 'Pester' -MinimumVersion $requiredPesterVersion -Force -ErrorAction Stop
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Using Pester v$($installedPester.Version)"

$config = New-PesterConfiguration
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.Output.Verbosity = 'Detailed'

if ([string]::IsNullOrWhiteSpace($TestFile)) {
    # Run all tests in the tests/ directory
    $testScripts = Get-PowerShellScripts -Path $testsDir -SortByName
    $files = $testScripts | Select-Object -ExpandProperty FullName
    Write-ScriptMessage -Message "Running Pester tests: $($files -join ', ')"
    $config.Run.Path = $files
}
else {
    Write-ScriptMessage -Message "Running Pester tests: $TestFile"
    $config.Run.Path = @($TestFile)
}

if ($Coverage) {
    $coverageDir = Join-Path $repoRoot 'scripts' 'data'
    if (-not (Test-Path -LiteralPath $coverageDir)) {
        New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
    }

    $coverageFile = Join-Path $coverageDir 'coverage.xml'

    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.OutputPath = $coverageFile
    $config.CodeCoverage.Path = @($profileDir)
    $config.CodeCoverage.Recurse = $true

    Write-ScriptMessage -Message "Code coverage enabled for: $profileDir"
    Write-ScriptMessage -Message "Coverage report: $coverageFile"
}
else {
    $config.CodeCoverage.Enabled = $false
}

$result = Invoke-Pester -Configuration $config

$result

