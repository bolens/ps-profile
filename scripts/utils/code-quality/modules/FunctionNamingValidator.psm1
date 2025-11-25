<#
scripts/utils/code-quality/modules/FunctionNamingValidator.psm1

.SYNOPSIS
    Function naming validation utilities.

.DESCRIPTION
    Provides functions for validating PowerShell function naming conventions.
#>

# Get approved PowerShell verbs (cached at module load)
$script:approvedVerbs = (Get-Verb).Verb | Sort-Object

<#
.SYNOPSIS
    Checks if a verb is from the approved PowerShell verbs list.

.DESCRIPTION
    Validates that a verb is in the list of approved PowerShell verbs returned by Get-Verb.

.PARAMETER Verb
    The verb to check.

.OUTPUTS
    System.Boolean. True if the verb is approved, false otherwise.
#>
function Test-ApprovedVerb {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Verb
    )
    return $Verb -in $script:approvedVerbs
}

<#
.SYNOPSIS
    Extracts verb and noun from a function name.

.DESCRIPTION
    Parses a function name to extract the verb and noun components, validating the Verb-Noun format.

.PARAMETER FunctionName
    The function name to parse.

.OUTPUTS
    Hashtable with Verb, Noun, and IsValidFormat properties.
#>
function Get-FunctionParts {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    if ($FunctionName -match '^([A-Za-z]+)-([A-Za-z0-9_]+)$') {
        return @{
            Verb          = $matches[1]
            Noun          = $matches[2]
            IsValidFormat = $true
        }
    }
    else {
        return @{
            Verb          = $null
            Noun          = $null
            IsValidFormat = $false
        }
    }
}

<#
.SYNOPSIS
    Checks if a function uses Set-AgentModeFunction or similar safe registration patterns.

.DESCRIPTION
    Validates that a function is defined using collision-safe patterns like Set-AgentModeFunction,
    Register-LazyFunction, or guarded function definitions.

.PARAMETER FilePath
    Path to the file containing the function.

.PARAMETER FunctionName
    Name of the function to check.

.OUTPUTS
    System.Boolean or $null. True if uses safe pattern, false if uses direct function keyword, null if unknown.
#>
function Test-UsesAgentModeFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    if (-not (Test-Path $FilePath)) {
        return $false
    }

    $content = Get-Content -Path $FilePath -Raw
    $functionPattern = [regex]::Escape($FunctionName)

    # Check if function is defined using Set-AgentModeFunction
    if ($content -match "Set-AgentModeFunction\s+-Name\s+['`"]$functionPattern['`"]") {
        return $true
    }

    # Check if function is defined using lazy loading pattern
    if ($content -match "Register-LazyFunction\s+-Name\s+['`"]$functionPattern['`"]") {
        return $true
    }

    # Check if function is a lazy-loading stub (checks for function existence and calls Ensure-*)
    if ($content -match "function\s+$functionPattern\s*\{[^}]*Ensure-[A-Za-z]+") {
        return $true  # Lazy-loading stub is a valid pattern
    }

    # Check if function is defined with proper guard (if (-not (Test-Path Function:Name)))
    # This is a common pattern in the codebase for collision-safe function definition
    $guardPattern = "if\s*\(\s*-not\s*\(\s*Test-Path\s+Function:$functionPattern\s*\)\s*\)\s*\{\s*function\s+$functionPattern"
    if ($content -match $guardPattern) {
        return $true  # Guarded function definition is a valid pattern
    }

    # Check if function is defined using direct function keyword (not recommended but may exist)
    if ($content -match "(?m)^\s*function\s+$functionPattern\s*\{") {
        return $false
    }

    return $null  # Unknown pattern
}

<#
.SYNOPSIS
    Checks if a function is a bootstrap function (exception).

.DESCRIPTION
    Determines if a function is one of the bootstrap functions defined in 00-bootstrap.ps1,
    which are exceptions to naming conventions.

.PARAMETER FilePath
    Path to the file containing the function.

.PARAMETER FunctionName
    Name of the function to check.

.OUTPUTS
    System.Boolean. True if the function is a bootstrap function, false otherwise.
#>
function Test-IsBootstrapFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    # Bootstrap functions are in 00-bootstrap.ps1
    if ($FilePath -like '*\00-bootstrap.ps1' -or $FilePath -like '*/00-bootstrap.ps1') {
        $bootstrapFunctions = @(
            'Set-AgentModeFunction',
            'Set-AgentModeAlias',
            'Test-CachedCommand',
            'Test-HasCommand',
            'Test-IsWindows',
            'Test-IsLinux',
            'Test-IsMacOS',
            'Get-UserHome',
            'Register-LazyFunction',
            'Get-FragmentConfigPath',
            'Get-FragmentConfig',
            'ConvertTo-Hashtable',
            'Save-FragmentConfig',
            'Test-ProfileFragmentEnabled',
            'Enable-ProfileFragment',
            'Disable-ProfileFragment',
            'Get-ProfileFragment',
            'Get-FragmentDependencies',
            'Test-FragmentDependencies',
            'Get-FragmentLoadOrder',
            'Visit-Fragment'
        )
        return $FunctionName -in $bootstrapFunctions
    }

    return $false
}

Export-ModuleMember -Function Test-ApprovedVerb, Get-FunctionParts, Test-UsesAgentModeFunction, Test-IsBootstrapFunction

