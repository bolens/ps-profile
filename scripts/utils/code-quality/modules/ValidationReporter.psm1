<#
scripts/utils/code-quality/modules/ValidationReporter.psm1

.SYNOPSIS
    Validation report generation utilities.

.DESCRIPTION
    Provides functions for generating and displaying validation reports.
#>

<#
.SYNOPSIS
    Analyzes function validation results and generates a report object.

.DESCRIPTION
    Processes discovered functions and generates validation results including issues and statistics.

.PARAMETER Functions
    Array of function objects to analyze.

.PARAMETER Exceptions
    Hashtable of exception function names.

.PARAMETER ExceptionVerbs
    Array of exception verbs.

.OUTPUTS
    PSCustomObject with validation results including statistics and issues.
#>
function Get-ValidationResults {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Functions,

        [Parameter(Mandatory)]
        [hashtable]$Exceptions,

        [Parameter(Mandatory)]
        [string[]]$ExceptionVerbs
    )

    # Import exception handler
    $exceptionModule = Join-Path $PSScriptRoot 'ExceptionHandler.psm1'
    Import-Module $exceptionModule -ErrorAction Stop

    $results = [PSCustomObject]@{
        TotalFunctions                     = $Functions.Count
        FunctionsWithApprovedVerbs         = ($Functions | Where-Object { $_.HasApprovedVerb }).Count
        FunctionsWithUnapprovedVerbs       = ($Functions | Where-Object {
                $_.IsValidFormat -and -not $_.HasApprovedVerb -and -not (Test-IsException -FunctionName $_.Name -Verb $_.Verb -FilePath $_.FilePath -Exceptions $Exceptions -ExceptionVerbs $ExceptionVerbs)
            }).Count
        FunctionsWithInvalidFormat         = ($Functions | Where-Object { -not $_.IsValidFormat }).Count
        ProfileDFunctionsNotUsingAgentMode = 0  # Removed requirement - Set-AgentModeFunction is optional
        ExceptionsCount                    = $Exceptions.Count
        Functions                          = $Functions
        Issues                             = @()
    }

    # Identify issues
    foreach ($func in $Functions) {
        # Skip exceptions
        if (Test-IsException -FunctionName $func.Name -Verb $func.Verb -FilePath $func.FilePath -Exceptions $Exceptions -ExceptionVerbs $ExceptionVerbs) {
            continue
        }

        $issues = @()

        if (-not $func.IsValidFormat) {
            $issues += "Invalid format (not Verb-Noun)"
        }

        if ($func.IsValidFormat -and -not $func.HasApprovedVerb) {
            $issues += "Unapproved verb: $($func.Verb)"
        }

        # Removed: Set-AgentModeFunction requirement - it's optional for profile functions

        if ($issues.Count -gt 0) {
            $results.Issues += [PSCustomObject]@{
                FunctionName             = $func.Name
                FilePath                 = $func.RelativePath
                Issues                   = $issues -join '; '
                Verb                     = $func.Verb
                HasApprovedVerb          = $func.HasApprovedVerb
                UsesSetAgentModeFunction = $func.UsesSetAgentModeFunction
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Displays validation results to the console.

.DESCRIPTION
    Outputs formatted validation results with color-coded status messages.

.PARAMETER Results
    Validation results object from Get-ValidationResults.

.OUTPUTS
    None. Outputs to console.
#>
function Write-ValidationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Results
    )

    Write-Host "`nFunction Naming Validation Results" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "Total Functions Found: $($Results.TotalFunctions)" -ForegroundColor White
    Write-Host "Functions with Approved Verbs: $($Results.FunctionsWithApprovedVerbs)" -ForegroundColor Green
    Write-Host "Functions with Unapproved Verbs: $($Results.FunctionsWithUnapprovedVerbs)" -ForegroundColor $(if ($Results.FunctionsWithUnapprovedVerbs -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host "Functions with Invalid Format: $($Results.FunctionsWithInvalidFormat)" -ForegroundColor $(if ($Results.FunctionsWithInvalidFormat -eq 0) { 'Green' } else { 'Red' })
    Write-Host "Documented Exceptions: $($Results.ExceptionsCount)" -ForegroundColor White

    if ($Results.Issues.Count -gt 0) {
        Write-Host "`nIssues Found:" -ForegroundColor Yellow
        foreach ($issue in $Results.Issues) {
            Write-Host "  - $($issue.FunctionName) ($($issue.FilePath)): $($issue.Issues)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`n✓ No issues found!" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Saves validation results to a JSON file.

.DESCRIPTION
    Exports validation results in JSON format for further processing or reporting.

.PARAMETER Results
    Validation results object from Get-ValidationResults.

.PARAMETER OutputPath
    Path where the JSON report should be saved.

.OUTPUTS
    None. Writes file to disk.
#>
function Save-ValidationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Results,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $report = @{
        Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Summary      = @{
            TotalFunctions                     = $Results.TotalFunctions
            FunctionsWithApprovedVerbs         = $Results.FunctionsWithApprovedVerbs
            FunctionsWithUnapprovedVerbs       = $Results.FunctionsWithUnapprovedVerbs
            FunctionsWithInvalidFormat         = $Results.FunctionsWithInvalidFormat
            ProfileDFunctionsNotUsingAgentMode = $Results.ProfileDFunctionsNotUsingAgentMode
            ExceptionsCount                    = $Results.ExceptionsCount
        }
        Issues       = $Results.Issues | ForEach-Object {
            @{
                FunctionName             = $_.FunctionName
                FilePath                 = $_.FilePath
                Issues                   = $_.Issues
                Verb                     = $_.Verb
                HasApprovedVerb          = $_.HasApprovedVerb
                UsesSetAgentModeFunction = $_.UsesSetAgentModeFunction
            }
        }
        AllFunctions = $Results.Functions | ForEach-Object {
            @{
                Name                     = $_.Name
                Verb                     = $_.Verb
                Noun                     = $_.Noun
                HasApprovedVerb          = $_.HasApprovedVerb
                FilePath                 = $_.RelativePath
                IsProfileDFile           = $_.IsProfileDFile
                UsesSetAgentModeFunction = $_.UsesSetAgentModeFunction
            }
        }
    }

    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    Write-Host "`nReport saved to: $OutputPath" -ForegroundColor Green
}

Export-ModuleMember -Function Get-ValidationResults, Write-ValidationReport, Save-ValidationReport

