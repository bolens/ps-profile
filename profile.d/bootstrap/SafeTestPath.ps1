# ===============================================
# SafeTestPath.ps1
# Safe Test-Path wrapper that handles null/empty paths
# ===============================================

<#
.SYNOPSIS
    Safely tests if a path exists, handling null and empty strings gracefully.

.DESCRIPTION
    Wrapper around Test-Path that checks for null/empty paths before calling Test-Path.
    This prevents PowerShell from prompting for input when Test-Path receives null/empty values.
    Use this instead of Test-Path when the path variable might be null or empty.

.PARAMETER Path
    The path to test. Can be null or empty.

.PARAMETER LiteralPath
    If specified, treats the path as a literal path (no wildcard expansion).

.PARAMETER PathType
    Specifies the type of path to test (Container, Leaf, or Any).

.OUTPUTS
    System.Boolean. True if the path exists, false otherwise (including when path is null/empty).

.EXAMPLE
    if (Test-SafePath -Path $modulePath) {
        Import-Module $modulePath
    }

    Safely checks if a module path exists before importing it.
#>
function global:Test-SafePath {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Path')]
        [AllowNull()]
        [string]$Path,
        
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'LiteralPath')]
        [AllowNull()]
        [string]$LiteralPath,
        
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [ValidateSet('Container', 'Leaf', 'Any')]
        [string]$PathType,
        
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [System.Management.Automation.ActionPreference]$ErrorAction = 'SilentlyContinue'
    )
    
    # Determine which path to use
    $pathToTest = if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') { $LiteralPath } else { $Path }
    
    # Check for null or empty - log if debug mode is enabled
    if ([string]::IsNullOrWhiteSpace($pathToTest)) {
        if ($env:PS_PROFILE_DEBUG_TESTPATH -or $env:PS_PROFILE_DEBUG) {
            $callStack = Get-PSCallStack
            $caller = if ($callStack.Count -gt 1) { $callStack[1] } else { $callStack[0] }
            $location = "$($caller.ScriptName):$($caller.ScriptLineNumber)"
            $function = $caller.FunctionName
            Write-Warning "Test-SafePath called with null/empty path at $location in function $function"
            if ($env:PS_PROFILE_DEBUG_TESTPATH -eq 'verbose') {
                Write-Host "Call stack:" -ForegroundColor Yellow
                $callStack | Select-Object -Skip 1 -First 5 | ForEach-Object {
                    Write-Host "  $($_.ScriptName):$($_.ScriptLineNumber) in $($_.FunctionName)" -ForegroundColor Gray
                }
            }
        }
        return $false
    }
    
    # Build Test-Path parameters
    $testPathParams = @{}
    if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
        $testPathParams['LiteralPath'] = $pathToTest
    }
    else {
        $testPathParams['Path'] = $pathToTest
    }
    
    if ($PathType) {
        $testPathParams['PathType'] = $PathType
    }
    
    $testPathParams['ErrorAction'] = $ErrorAction
    
    # Call Test-Path
    return Test-Path @testPathParams
}

<#
.SYNOPSIS
    Wraps Test-Path to log when null/empty paths are detected (debug mode only).

.DESCRIPTION
    This function intercepts Test-Path calls and logs when null/empty paths are detected.
    Only active when PS_PROFILE_DEBUG_TESTPATH environment variable is set.
    Use this to trace which Test-Path calls are receiving null/empty paths.

.NOTES
    This is a debug utility. Set $env:PS_PROFILE_DEBUG_TESTPATH = '1' to enable basic logging,
    or 'verbose' for detailed call stack information.
#>
function global:Trace-TestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [string]$Path,
        
        [switch]$LiteralPath,
        
        [ValidateSet('Container', 'Leaf', 'Any')]
        [string]$PathType
    )
    
    # Check for null or empty - always log in trace mode
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $callStack = Get-PSCallStack
        $caller = if ($callStack.Count -gt 1) { $callStack[1] } else { $callStack[0] }
        $location = "$($caller.ScriptName):$($caller.ScriptLineNumber)"
        $function = $caller.FunctionName
        
        Write-Host "⚠️  Test-Path called with NULL/EMPTY path" -ForegroundColor Red
        Write-Host "   Location: $location" -ForegroundColor Yellow
        Write-Host "   Function: $function" -ForegroundColor Yellow
        Write-Host "   Call stack:" -ForegroundColor Yellow
        $callStack | Select-Object -Skip 1 -First 10 | ForEach-Object {
            $scriptName = if ($_.ScriptName) { Split-Path -Leaf $_.ScriptName } else { '<no script>' }
            Write-Host "     $scriptName`:$($_.ScriptLineNumber) in $($_.FunctionName)" -ForegroundColor Gray
        }
        Write-Host ""
        return $false
    }
    
    # Build Test-Path parameters
    $testPathParams = @{}
    if ($LiteralPath) {
        $testPathParams['LiteralPath'] = $Path
    }
    else {
        $testPathParams['Path'] = $Path
    }
    
    if ($PathType) {
        $testPathParams['PathType'] = $PathType
    }
    
    # Call Test-Path
    return Test-Path @testPathParams
}

