# ===============================================
# trace-testpath.ps1
# Debug utility to trace Test-Path calls that receive null/empty paths
# ===============================================

# Import CommonEnums for PathType enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Traces Test-Path calls to identify which ones receive null/empty paths.

.DESCRIPTION
    This script creates a wrapper around Test-Path that logs when null/empty paths
    are detected. Use this to identify the source of Path[x] prompts during test execution.

.PARAMETER TestFile
    The test file to run with tracing enabled.

.PARAMETER TestPath
    A specific test path pattern to match.

.EXAMPLE
    .\trace-testpath.ps1 -TestFile 'tests/unit/test-support.tests.ps1'

    Runs the test file with Test-Path tracing enabled.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TestFile,
    
    [string]$TestPath
)

# Enable debug mode
$env:PS_PROFILE_DEBUG_TESTPATH = 'verbose'

Write-Host "🔍 Test-Path Tracing Enabled" -ForegroundColor Cyan
Write-Host "   Test File: $TestFile" -ForegroundColor Gray
Write-Host "   Any Test-Path calls with null/empty paths will be logged below" -ForegroundColor Gray
Write-Host ""

# Create a wrapper function that intercepts Test-Path
function global:Test-Path {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Path')]
        [AllowNull()]
        [string]$Path,
        
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'LiteralPath')]
        [AllowNull()]
        [string]$LiteralPath,
        
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [PathType]$PathType
        
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [System.Management.Automation.ActionPreference]$ErrorAction = 'Continue'
    )
    
    # Determine which path to use
    $pathToTest = if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') { $LiteralPath } else { $Path }
    
    # Check for null or empty - log it
    if ([string]::IsNullOrWhiteSpace($pathToTest)) {
        $callStack = Get-PSCallStack
        $caller = if ($callStack.Count -gt 1) { $callStack[1] } else { $callStack[0] }
        $location = if ($caller.ScriptName) { "$($caller.ScriptName):$($caller.ScriptLineNumber)" } else { "Line $($caller.ScriptLineNumber)" }
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
        
        # Return false instead of prompting
        return $false
    }
    
    # Build Test-Path parameters for the real Test-Path
    $testPathParams = @{}
    if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
        $testPathParams['LiteralPath'] = $pathToTest
    }
    else {
        $testPathParams['Path'] = $pathToTest
    }
    
    if ($PathType) {
        # Convert enum to string
        $testPathParams['PathType'] = $PathType.ToString()
    }
    
    $testPathParams['ErrorAction'] = $ErrorAction
    
    # Call the real Test-Path (using Get-Command to bypass our wrapper)
    $realTestPath = Get-Command Test-Path -All | Where-Object { $_.Source -eq 'Microsoft.PowerShell.Management' } | Select-Object -First 1
    if ($realTestPath) {
        return & $realTestPath.Module.Name\Test-Path @testPathParams
    }
    else {
        # Fallback - this shouldn't happen
        return Microsoft.PowerShell.Management\Test-Path @testPathParams
    }
}

# Run the test
try {
    if ($TestPath) {
        pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestPath $TestPath
    }
    else {
        pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile $TestFile
    }
}
finally {
    # Clean up
    Remove-Item Env:\PS_PROFILE_DEBUG_TESTPATH -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Test-Path -ErrorAction SilentlyContinue
}

