<#
scripts/utils/code-quality/modules/TestInteractive.psm1

.SYNOPSIS
    Interactive test selection utilities.

.DESCRIPTION
    Provides functions for interactive test selection and filtering.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Locale module for locale-aware messages
$localeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Locale.psm1'
if ($localeModulePath -and -not [string]::IsNullOrWhiteSpace($localeModulePath) -and (Test-Path -LiteralPath $localeModulePath)) {
    Import-Module $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Interactively selects tests to run.

.DESCRIPTION
    Presents a menu of available tests and allows the user to select which tests to run.
    Supports filtering, multi-select, and quick actions.

.PARAMETER TestList
    Hashtable returned from Get-TestList containing available tests.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    Hashtable with SelectedTests (array) and SelectedFiles (array)
#>
function Select-TestsInteractively {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TestList,
        [string]$RepoRoot
    )

    $result = @{
        SelectedTests = @()
        SelectedFiles = @()
        Canceled      = $false
    }

    if ($TestList.Tests.Count -eq 0) {
        Write-Host "No tests available to select." -ForegroundColor Yellow
        return $result
    }

    Write-Host "`n=== Interactive Test Selection ===" -ForegroundColor Cyan
    Write-Host "Total tests available: $($TestList.Tests.Count)" -ForegroundColor Green
    Write-Host ""

    # Group tests by file for easier selection
    $testsByFile = $TestList.Tests | Group-Object -Property File
    
    Write-Host "Available test files:" -ForegroundColor Yellow
    $fileIndex = 1
    $fileMap = @{}
    
    foreach ($fileGroup in $testsByFile) {
        $fileMap[$fileIndex] = $fileGroup.Name
        $testCount = $fileGroup.Count
        Write-Host "  [$fileIndex] $($fileGroup.Name) ($testCount test(s))" -ForegroundColor White
        $fileIndex++
    }
    
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  - Enter file numbers (comma-separated) to select files" -ForegroundColor Gray
    Write-Host "  - Enter 'all' to select all tests" -ForegroundColor Gray
    Write-Host "  - Enter 'filter <pattern>' to filter tests by name" -ForegroundColor Gray
    Write-Host "  - Press Enter without input to cancel" -ForegroundColor Gray
    Write-Host ""

    $userInput = Read-Host "Select tests"
    
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $result.Canceled = $true
        return $result
    }

    $userInput = $userInput.Trim().ToLower()

    # Handle 'all' option
    if ($userInput -eq 'all') {
        $result.SelectedTests = $TestList.Tests
        $result.SelectedFiles = $TestList.TestFiles
        return $result
    }

    # Handle filter option
    if ($userInput -like 'filter *') {
        $pattern = $userInput -replace '^filter\s+', ''
        $filteredTests = $TestList.Tests | Where-Object { $_.Name -like "*$pattern*" }
        
        if ($filteredTests.Count -eq 0) {
            Write-Host "No tests match pattern: $pattern" -ForegroundColor Yellow
            $result.Canceled = $true
            return $result
        }
        
        Write-Host "Found $($filteredTests.Count) test(s) matching pattern: $pattern" -ForegroundColor Green
        $result.SelectedTests = $filteredTests
        $result.SelectedFiles = $filteredTests | Select-Object -ExpandProperty File -Unique
        return $result
    }

    # Handle file number selection
    $selectedIndices = @()
    $numberStrings = $userInput -split ','
    
    foreach ($numStr in $numberStrings) {
        $numStr = $numStr.Trim()
        if ([int]::TryParse($numStr, [ref]$null)) {
            $index = [int]$numStr
            if ($fileMap.ContainsKey($index)) {
                $selectedIndices += $index
            }
            else {
                Write-Host "Invalid file number: $index" -ForegroundColor Red
            }
        }
    }

    if ($selectedIndices.Count -eq 0) {
        Write-Host "No valid selections made." -ForegroundColor Yellow
        $result.Canceled = $true
        return $result
    }

    # Get selected files
    $selectedFiles = $selectedIndices | ForEach-Object { $fileMap[$_] } | Select-Object -Unique
    
    # Get tests from selected files
    $result.SelectedTests = $TestList.Tests | Where-Object { $selectedFiles -contains $_.File }
    $result.SelectedFiles = $selectedFiles

    Write-Host "Selected $($result.SelectedTests.Count) test(s) from $($result.SelectedFiles.Count) file(s)" -ForegroundColor Green
    
    return $result
}

Export-ModuleMember -Function @(
    'Select-TestsInteractively'
)

