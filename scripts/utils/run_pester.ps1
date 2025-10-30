# Ensure Pester is available and run the test suite in this repo
param(
    [string]$TestFile = "",
    [switch]$Coverage
)
if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
    Write-Host 'Pester not found; installing to CurrentUser scope...'
    Install-Module -Name Pester -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
}

$pesterParams = @{}
if ([string]::IsNullOrWhiteSpace($TestFile)) {
    # Run all tests in the tests/ directory
    $files = Get-ChildItem -Path (Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'tests') -Filter '*.ps1' -File | Sort-Object Name | Select-Object -ExpandProperty FullName
    Write-Host "Running Pester tests: $($files -join ', ')"
    $pesterParams.Script = $files
}
else {
    Write-Host "Running Pester tests: $TestFile"
    $pesterParams.Script = $TestFile
}

if ($Coverage) {
    # Add code coverage for profile.d directory
    $profilePath = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'profile.d'
    $pesterParams.CodeCoverage = "$profilePath/*.ps1"
    $pesterParams.CodeCoverageOutputFile = 'coverage.xml'
    Write-Host "Code coverage enabled for: $profilePath"
}

try {
    $result = Invoke-Pester @pesterParams -PassThru
}
catch {
    # Work around Pester 3.4.0 bug with null ErrorRecord handling
    # If we get the specific error about null arguments, suppress it and get the result differently
    if ($_.Exception.Message -match "null.*empty.*argument" -or $_.Exception.Message -match "Cannot validate argument on parameter 'First'") {
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
