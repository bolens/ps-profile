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
    $files = Get-ChildItem -Path (Join-Path (Split-Path $PSScriptRoot) 'tests') -Filter '*.ps1' -File | Sort-Object Name | Select-Object -ExpandProperty FullName
    Write-Host "Running Pester tests: $($files -join ', ')"
    $pesterParams.Script = $files
} else {
    Write-Host "Running Pester tests: $TestFile"
    $pesterParams.Script = $TestFile
}

if ($Coverage) {
    # Add code coverage for profile.d directory
    $profilePath = Join-Path (Split-Path $PSScriptRoot) 'profile.d'
    $pesterParams.CodeCoverage = "$profilePath/*.ps1"
    $pesterParams.CodeCoverageOutputFile = 'coverage.xml'
    $pesterParams.CodeCoverageOutputFileFormat = 'JaCoCo'
    Write-Host "Code coverage enabled for: $profilePath"
}

$result = Invoke-Pester @pesterParams -PassThru
$result
