# ===============================================
# intercept-testpath.ps1
# Intercepts Test-Path calls to log null/empty paths
# ===============================================

<#
.SYNOPSIS
    Creates a wrapper function that intercepts Test-Path calls and logs null/empty paths.

.DESCRIPTION
    This script creates a function that shadows Test-Path and logs when null/empty paths
    are detected. It should be dot-sourced before running tests.
#>

# Save the original Test-Path cmdlet
$originalTestPath = Get-Command Test-Path -ErrorAction SilentlyContinue

# Create a wrapper function
function global:Test-Path {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Path,
        
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'LiteralPath')]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$LiteralPath,
        
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [ValidateSet('Container', 'Leaf', 'Any')]
        [string]$PathType
    )
    
    # Handle ErrorAction via $PSBoundParameters or common parameter
    $ErrorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) { 
        $PSBoundParameters['ErrorAction'] 
    }
    else { 
        'Continue' 
    }
    
    # Determine which path to use
    $pathToTest = if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') { $LiteralPath } else { $Path }
    
    # Check for null or empty - log it
    # Note: PowerShell may validate empty strings before this, so we also check in the parameter
    if ($null -eq $pathToTest -or [string]::IsNullOrWhiteSpace($pathToTest)) {
        $callStack = Get-PSCallStack
        $caller = if ($callStack.Count -gt 1) { $callStack[1] } else { $callStack[0] }
        $location = if ($caller.ScriptName) { 
            $scriptName = $caller.ScriptName
            if ($scriptName -notlike '*\*' -and $scriptName -notlike '*/*') {
                $scriptName = (Get-Location).Path + '\' + $scriptName
            }
            "$scriptName`:$($caller.ScriptLineNumber)" 
        }
        else { 
            "Line $($caller.ScriptLineNumber)" 
        }
        $function = if ($caller.FunctionName) { $caller.FunctionName } else { '<no function>' }
        
        Write-Host "⚠️  Test-Path called with NULL/EMPTY path" -ForegroundColor Red
        Write-Host "   Location: $location" -ForegroundColor Yellow
        Write-Host "   Function: $function" -ForegroundColor Yellow
        Write-Host "   Call stack:" -ForegroundColor Yellow
        $callStack | Select-Object -Skip 1 -First 10 | ForEach-Object {
            $scriptName = if ($_.ScriptName) { 
                $sn = $_.ScriptName
                if ($sn -notlike '*\*' -and $sn -notlike '*/*') {
                    $sn = (Get-Location).Path + '\' + $sn
                }
                Split-Path -Leaf $sn
            }
            else { 
                '<no script>' 
            }
            Write-Host "     $scriptName`:$($_.ScriptLineNumber) in $($_.FunctionName)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Return false instead of prompting
        return $false
    }
    
    # Build parameters for the real Test-Path
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
    
    # Call the original Test-Path cmdlet
    # Use Get-Command to get the actual cmdlet and invoke it
    $cmdlet = Get-Command Test-Path -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandType -eq 'Cmdlet' -and $_.Source -eq 'Microsoft.PowerShell.Management' 
    } | Select-Object -First 1
    
    if ($cmdlet) {
        return & $cmdlet @testPathParams
    }
    else {
        # Fallback: use the module-qualified name
        $module = Get-Module Microsoft.PowerShell.Management -ErrorAction SilentlyContinue
        if ($module) {
            return & Microsoft.PowerShell.Management\Test-Path @testPathParams
        }
        else {
            # Last resort: import the module and call it
            Import-Module Microsoft.PowerShell.Management -ErrorAction SilentlyContinue
            return & Microsoft.PowerShell.Management\Test-Path @testPathParams
        }
    }
}

Write-Host "✅ Test-Path interception enabled" -ForegroundColor Green
Write-Host "   Any Test-Path calls with null/empty paths will be logged" -ForegroundColor Gray

