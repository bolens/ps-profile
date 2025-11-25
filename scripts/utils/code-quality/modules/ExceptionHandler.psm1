<#
scripts/utils/code-quality/modules/ExceptionHandler.psm1

.SYNOPSIS
    Exception handling utilities for function naming validation.

.DESCRIPTION
    Provides functions for loading and checking exceptions to naming conventions.
#>

<#
.SYNOPSIS
    Loads exceptions from the exceptions documentation file.

.DESCRIPTION
    Parses the exceptions markdown file to extract function names and exception verbs.

.PARAMETER ExceptionsFile
    Path to the exceptions documentation file.

.OUTPUTS
    Hashtable with Exceptions (function names) and ExceptionVerbs properties.
#>
function Get-NamingExceptions {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ExceptionsFile
    )

    $exceptions = @{}
    $exceptionVerbs = @('Ensure', 'Reload', 'Continue', 'Jump', 'Time', 'am', 'Simple', 'Visit')

    if (Test-Path $ExceptionsFile) {
        $exceptionContent = Get-Content -Path $ExceptionsFile -Raw
        # Parse function names from exceptions list
        $exceptionMatches = [regex]::Matches($exceptionContent, '(?:^|\n)\s*-\s+`?([A-Za-z]+-[A-Za-z0-9_]+)`?')
        foreach ($match in $exceptionMatches) {
            $exceptions[$match.Groups[1].Value] = $true
        }

        # Also extract exception verbs mentioned in documentation
        if ($exceptionContent -match 'Exception Categories') {
            # Extract verbs from "Common Utility Patterns" section
            if ($exceptionContent -match 'Reload|Continue|Jump|Time') {
                # Already in exceptionVerbs
            }
        }
    }

    return @{
        Exceptions     = $exceptions
        ExceptionVerbs = $exceptionVerbs
    }
}

<#
.SYNOPSIS
    Checks if a function is an exception to naming conventions.

.DESCRIPTION
    Determines if a function should be exempted from naming validation based on various criteria.

.PARAMETER FunctionName
    Name of the function to check.

.PARAMETER Verb
    Verb component of the function name.

.PARAMETER FilePath
    Path to the file containing the function.

.PARAMETER Exceptions
    Hashtable of exception function names.

.PARAMETER ExceptionVerbs
    Array of exception verbs.

.OUTPUTS
    System.Boolean. True if the function is an exception, false otherwise.
#>
function Test-IsException {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [string]$Verb,

        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [hashtable]$Exceptions,

        [Parameter(Mandatory)]
        [string[]]$ExceptionVerbs
    )

    # Import validation functions
    $validatorModule = Join-Path $PSScriptRoot 'FunctionNamingValidator.psm1'
    Import-Module $validatorModule -ErrorAction Stop

    # Check if function is in exceptions list
    if ($Exceptions.ContainsKey($FunctionName)) {
        return $true
    }

    # Check if verb is in exception verbs list
    if ($Verb -in $ExceptionVerbs) {
        return $true
    }

    # Check if it's a bootstrap function
    if (Test-IsBootstrapFunction -FilePath $FilePath -FunctionName $FunctionName) {
        return $true
    }

    # Check if it's a test file
    if ($FilePath -like '*\tests\*' -or $FilePath -like '*/tests/*') {
        return $true
    }

    return $false
}

Export-ModuleMember -Function Get-NamingExceptions, Test-IsException

