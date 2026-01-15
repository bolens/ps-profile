# ===============================================
# Regular expression testing utilities
# ===============================================

<#
.SYNOPSIS
    Initializes regex testing utility functions.
.DESCRIPTION
    Sets up internal functions for testing regular expressions against input text.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Regex {
    # Regex Tester
    Set-Item -Path Function:Global:_Test-Regex -Value {
        param(
            [string]$Pattern,
            [string]$InputText,
            [switch]$AllMatches,
            [switch]$IgnoreCase
        )
        try {
            $options = if ($IgnoreCase) { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase } else { [System.Text.RegularExpressions.RegexOptions]::None }
            $regex = [System.Text.RegularExpressions.Regex]::new($Pattern, $options)
            if ($AllMatches) {
                $matches = $regex.Matches($InputText)
                $matches | ForEach-Object {
                    [PSCustomObject]@{
                        Value  = $_.Value
                        Index  = $_.Index
                        Length = $_.Length
                        Groups = $_.Groups | ForEach-Object { $_.Value }
                    }
                }
            }
            else {
                $match = $regex.Match($InputText)
                if ($match.Success) {
                    [PSCustomObject]@{
                        Success = $true
                        Value   = $match.Value
                        Index   = $match.Index
                        Length  = $match.Length
                        Groups  = $match.Groups | ForEach-Object { $_.Value }
                    }
                }
                else {
                    [PSCustomObject]@{
                        Success = $false
                        Value   = $null
                        Index   = -1
                        Length  = 0
                        Groups  = @()
                    }
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.regex.match' -Context @{
                    pattern = $Pattern
                }
            }
            else {
                Write-Error "Invalid regex pattern: $_" -ErrorAction Continue
            }
            return [PSCustomObject]@{
                Success = $false
                Value   = $null
                Index   = -1
                Length  = 0
                Groups  = @()
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Tests a regular expression against input text.
.DESCRIPTION
    Tests a regular expression pattern against input text and returns match results.
.PARAMETER Pattern
    The regular expression pattern to test.
.PARAMETER Input
    The input text to test against.
.PARAMETER AllMatches
    If specified, returns all matches instead of just the first.
.PARAMETER IgnoreCase
    If specified, performs case-insensitive matching.
.EXAMPLE
    Test-Regex -Pattern "\d+" -Input "Hello 123 World"
    Tests the pattern against the input and returns match details.
.EXAMPLE
    Test-Regex -Pattern "\w+" -Input "Hello World" -AllMatches
    Returns all word matches in the input.
.OUTPUTS
    PSCustomObject
    Object containing match information (Success, Value, Index, Length, Groups).
#>
function Test-Regex {
    param(
        [string]$Pattern,
        [Parameter(ValueFromPipeline = $true)]
        [string]$Input,
        [switch]$AllMatches,
        [switch]$IgnoreCase
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    # Rename Input to InputText to avoid conflict with $input
    $PSBoundParameters['InputText'] = $PSBoundParameters['Input']
    $PSBoundParameters.Remove('Input') | Out-Null
    _Test-Regex @PSBoundParameters
}
Set-Alias -Name regex-test -Value Test-Regex -ErrorAction SilentlyContinue

