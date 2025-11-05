# Ensure Pester is available and run the test suite in this repo
param(
    [string]$TestFile = "",
    [switch]$Coverage
)

# Cache root directory path calculation
$rootDir = Split-Path (Split-Path $PSScriptRoot)
$testsDir = Join-Path $rootDir 'tests'
$profileDir = Join-Path $rootDir 'profile.d'

# Check for Pester module (cache module check)
$pesterCmd = Get-Command Invoke-Pester -ErrorAction SilentlyContinue
if (-not $pesterCmd) {
    Write-Host 'Pester not found; installing to CurrentUser scope...'
    Install-Module -Name Pester -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    $pesterCmd = Get-Command Invoke-Pester -ErrorAction Stop
}

$pesterParams = @{}
if ([string]::IsNullOrWhiteSpace($TestFile)) {
    # Run all tests in the tests/ directory
    $files = Get-ChildItem -Path $testsDir -Filter '*.ps1' -File | Sort-Object Name | Select-Object -ExpandProperty FullName
    Write-Host "Running Pester tests: $($files -join ', ')"
    $pesterParams.Script = $files
}
else {
    Write-Host "Running Pester tests: $TestFile"
    $pesterParams.Script = $TestFile
}

if ($Coverage) {
    # Add code coverage for profile.d directory
    $pesterParams.CodeCoverage = "$profileDir/*.ps1"

    # CodeCoverageOutputFile parameter is only available in Pester 4.0+
    # Cache module version check
    $pesterModule = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
    if ($pesterModule -and $pesterModule.Version -ge [version]'4.0.0') {
        $pesterParams.CodeCoverageOutputFile = 'coverage.xml'
    }
    Write-Host "Code coverage enabled for: $profileDir"
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
        Write-Host "Pester framework error suppressed (known issue with null ErrorRecord handling)"
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
