<#
scripts/utils/code-quality/modules/TestFailureAnalysis.psm1

.SYNOPSIS
    Test failure analysis utilities.

.DESCRIPTION
    Provides functions for analyzing test failures to identify patterns and root causes.
#>

# Import TestCategorization module for Get-TestCategory
$categorizationModulePath = Join-Path $PSScriptRoot 'TestCategorization.psm1'
if (Test-Path $categorizationModulePath) {
    Import-Module $categorizationModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Analyzes test failures to identify patterns and root causes.

.DESCRIPTION
    Groups failures by error message, test file, and other criteria
    to identify common failure patterns.

.PARAMETER TestResult
    The Pester test result object.

.OUTPUTS
    Failure analysis object
#>
function Get-FailureAnalysis {
    param(
        [Parameter(Mandatory)]
        $TestResult
    )

    $failures = $TestResult.FailedTests

    if (-not $failures) {
        return @()
    }

    $analysis = @{
        ByErrorMessage   = @{}
        ByFile           = @{}
        ByCategory       = @{}
        MostCommonErrors = @()
    }

    foreach ($failure in $failures) {
        # Group by error message
        $errorKey = $failure.ErrorRecord.Exception.Message
        if (-not $analysis.ByErrorMessage.ContainsKey($errorKey)) {
            $analysis.ByErrorMessage[$errorKey] = @()
        }
        $analysis.ByErrorMessage[$errorKey] += $failure

        # Group by file
        $fileKey = $failure.File
        if (-not $analysis.ByFile.ContainsKey($fileKey)) {
            $analysis.ByFile[$fileKey] = @()
        }
        $analysis.ByFile[$fileKey] += $failure

        # Group by category (extract from test name or tags)
        $category = Get-TestCategory -Test $failure
        if (-not $analysis.ByCategory.ContainsKey($category)) {
            $analysis.ByCategory[$category] = @()
        }
        $analysis.ByCategory[$category] += $failure
    }

    # Find most common errors
    $analysis.MostCommonErrors = $analysis.ByErrorMessage.GetEnumerator() |
    Sort-Object { $_.Value.Count } -Descending |
    Select-Object -First 5 |
    ForEach-Object {
        @{
            ErrorMessage = $_.Key
            Count        = $_.Value.Count
            Tests        = $_.Value | ForEach-Object { if ($_ -is [hashtable]) { $_.Name } else { $_.Name } }
        }
    }

    return $analysis
}

Export-ModuleMember -Function Get-FailureAnalysis

