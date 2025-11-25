<#
scripts/utils/code-quality/modules/TestResultValidation.psm1

.SYNOPSIS
    Test result validation utilities.

.DESCRIPTION
    Provides functions for validating test results for consistency and detecting anomalies.
#>

<#
.SYNOPSIS
    Implements test result validation and consistency checks.

.DESCRIPTION
    Validates test results for consistency, detects anomalies,
    and ensures result integrity.

.PARAMETER TestResult
    The Pester test result object to validate.

.PARAMETER ExpectedTests
    Expected number of tests.

.PARAMETER ValidationRules
    Custom validation rules to apply.

.OUTPUTS
    Validation results
#>
function Test-TestResultIntegrity {
    param(
        $TestResult,
        [int]$ExpectedTests,
        [hashtable]$ValidationRules = @{}
    )

    # Initialize validation result structure
    $validation = @{
        IsValid         = $true
        Issues          = @()
        Warnings        = @()
        Recommendations = @()
    }

    # Basic null check
    if ($null -eq $TestResult) {
        $validation.IsValid = $false
        $validation.Issues += 'TestResult is null'
        return $validation
    }

    # Validate test count matches expected (if provided)
    $totalTests = $TestResult.TotalCount
    if ($ExpectedTests -and $totalTests -ne $ExpectedTests) {
        $validation.Warnings += "Expected $ExpectedTests tests but found $totalTests"
    }

    # Consistency check: sum of all test states should equal total count
    $calculatedTotal = $TestResult.PassedCount + $TestResult.FailedCount + $TestResult.SkippedCount + $TestResult.InconclusiveCount + $TestResult.NotRunCount
    if ($calculatedTotal -ne $totalTests) {
        $validation.Issues += "Test counts inconsistent: Total=$totalTests, Calculated=$calculatedTotal"
        $validation.IsValid = $false
    }

    # Validate duration is non-negative (sanity check)
    if ($TestResult.Time.TotalSeconds -lt 0) {
        $validation.Issues += 'Negative test duration detected'
        $validation.IsValid = $false
    }

    # Apply custom validation rules (user-defined validation functions)
    foreach ($rule in $ValidationRules.GetEnumerator()) {
        try {
            $ruleResult = & $rule.Value $TestResult
            if ($ruleResult.Passed) {
                continue
            }
            
            # Categorize rule violations by severity
            if ($ruleResult.Severity -eq 'Error') {
                $validation.Issues += "$($rule.Key): $($ruleResult.Message)"
                $validation.IsValid = $false
            }
            else {
                $validation.Warnings += "$($rule.Key): $($ruleResult.Message)"
            }
        }
        catch {
            # Rule execution errors are warnings, not failures (rule may be malformed)
            $validation.Warnings += "Validation rule '$($rule.Key)' failed: $($_.Exception.Message)"
        }
    }

    # Generate recommendations based on test result patterns
    if ($TestResult.FailedCount -gt ($totalTests * 0.1)) {
        # Threshold: more than 10% failures suggests test stability issues
        $validation.Recommendations += 'High failure rate detected - review test stability'
    }

    if ($TestResult.SkippedCount -gt ($totalTests * 0.2)) {
        # Threshold: more than 20% skipped suggests test condition issues
        $validation.Recommendations += 'High skip rate detected - review test conditions'
    }

    return $validation
}

Export-ModuleMember -Function Test-TestResultIntegrity

