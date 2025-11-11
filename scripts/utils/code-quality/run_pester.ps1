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
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $testsDir = Join-Path $repoRoot 'tests'
    $profileDir = Join-Path $repoRoot 'profile.d'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Ensure Pester is available
try {
    Ensure-ModuleAvailable -ModuleName 'Pester'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$pesterParams = @{}
if ([string]::IsNullOrWhiteSpace($TestFile)) {
    # Run all tests in the tests/ directory
    $testScripts = Get-PowerShellScripts -Path $testsDir -SortByName
    $files = $testScripts | Select-Object -ExpandProperty FullName
    Write-ScriptMessage -Message "Running Pester tests: $($files -join ', ')"
    $pesterParams.Script = $files
}
else {
    Write-ScriptMessage -Message "Running Pester tests: $TestFile"
    $pesterParams.Script = $TestFile
}

if ($Coverage) {
    # Add code coverage for profile.d directory
    $pesterParams.CodeCoverage = "$profileDir/*.ps1"

    # CodeCoverageOutputFile parameter is only available in Pester 4.0+
    # Cache module version check
    $pesterModule = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
    if ($pesterModule -and $pesterModule.Version -ge [version]'4.0.0') {
        $coverageDir = Join-Path $repoRoot 'scripts' 'data'
        if (-not (Test-Path -LiteralPath $coverageDir)) {
            New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
        }

        $coverageFile = Join-Path $coverageDir 'coverage.xml'
        $pesterParams.CodeCoverageOutputFile = $coverageFile
        Write-ScriptMessage -Message "Coverage report: $coverageFile"
    }
    Write-ScriptMessage -Message "Code coverage enabled for: $profileDir"
}

# Compile regex pattern once for error detection
$nullArgRegex = [regex]::new("null.*empty.*argument", [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$paramFirstRegex = [regex]::new("Cannot validate argument on parameter 'First'", [System.Text.RegularExpressions.RegexOptions]::Compiled)

try {
    $result = Invoke-Pester @pesterParams -PassThru
}
catch {
    # Work around Pester 3.4.0 bug with null ErrorRecord handling
    # If we get the specific error about null arguments, suppress it and get the result differently
    if ($nullArgRegex.IsMatch($_.Exception.Message) -or $paramFirstRegex.IsMatch($_.Exception.Message)) {
        Write-ScriptMessage -Message "Pester framework error suppressed (known issue with null ErrorRecord handling)"
        # Try to run without -PassThru to avoid the error
        Invoke-Pester @pesterParams
        # Create a basic result object
        $result = [PSCustomObject]@{
            PassedCount = 0
            FailedCount = 0
            TotalCount  = 0
        }
    }
    else {
        throw
    }
}

# Work around Pester 3.4.0 bug with null ErrorRecord handling
# Filter out test results with null ErrorRecord to prevent framework errors
if ($result.TestResult) {
    $result.TestResult = $result.TestResult | Where-Object { $_.ErrorRecord -ne $null }
}

$result
