# ===============================================
# MockFileSystem.psm1
# File system mocking utilities
# ===============================================

<#
.SYNOPSIS
    File system mocking utilities.

.DESCRIPTION
    Provides functions for mocking file system operations like Test-Path, Get-Item, etc.
#>

# Import mock registry functions
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $modulePath 'MockRegistry.psm1') -DisableNameChecking -ErrorAction Stop

<#
.SYNOPSIS
    Mocks file system operations.

.DESCRIPTION
    Provides easy mocking of Test-Path, Get-Item, Get-ChildItem, etc. for file system operations.

.PARAMETER Operation
    File system operation to mock: 'Test-Path', 'Get-Item', 'Get-ChildItem', 'Read-File', 'Write-File'.

.PARAMETER Path
    Path pattern to match (supports wildcards).

.PARAMETER MockWith
    ScriptBlock to execute for the operation.

.PARAMETER ReturnValue
    Simple return value (for Test-Path, returns boolean).

.PARAMETER UsePesterMock
    If true, uses Pester's Mock command.

.EXAMPLE
    Mock-FileSystem -Operation 'Test-Path' -Path '*.ps1' -ReturnValue $true

.EXAMPLE
    Mock-FileSystem -Operation 'Get-Item' -Path 'test.txt' -MockWith {
        [PSCustomObject]@{ FullName = 'test.txt'; Length = 100 }
    }
#>
function Mock-FileSystem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Test-Path', 'Get-Item', 'Get-ChildItem', 'Read-File', 'Write-File', 'Remove-Item', 'New-Item')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$Path,

        [scriptblock]$MockWith,

        [object]$ReturnValue,

        [switch]$UsePesterMock
    )

    if ($UsePesterMock -and (Get-Command Mock -ErrorAction SilentlyContinue)) {
        # Pester 5 syntax with proper parameter filter
        # Pester 5 automatically scopes mocks based on where they're called (It, Context, Describe blocks)
        $filter = {
            ($PSBoundParameters.ContainsKey('Path') -and $PSBoundParameters['Path'] -like $Path) -or
            ($PSBoundParameters.ContainsKey('LiteralPath') -and $PSBoundParameters['LiteralPath'] -like $Path)
        }
        if ($MockWith) {
            Mock -CommandName $Operation -ParameterFilter $filter -MockWith $MockWith
        }
        elseif ($null -ne $ReturnValue) {
            Mock -CommandName $Operation -ParameterFilter $filter -MockWith { $ReturnValue }
        }
        return
    }

    # Function-based mocking (simplified - mainly for Test-Path)
    if ($Operation -eq 'Test-Path') {
        $originalTestPath = Get-Command Test-Path -ErrorAction SilentlyContinue
        $pathPattern = $Path
        $returnVal = if ($null -ne $ReturnValue) { $ReturnValue } else { $true }

        $mockTestPath = {
            param(
                [Parameter(Position = 0)]
                [string]$LiteralPath,

                [Parameter(Position = 0)]
                [string]$Path
            )

            $testPath = if ($LiteralPath) { $LiteralPath } else { $Path }
            if ($testPath -like $pathPattern) {
                return $returnVal
            }

            # Call original for other paths
            if ($originalTestPath) {
                return & $originalTestPath -LiteralPath $testPath -ErrorAction SilentlyContinue
            }
            return $false
        }

        Set-Item -Path Function:\Test-Path -Value $mockTestPath -Force -ErrorAction SilentlyContinue
        Register-Mock -Type 'Function' -Name 'Test-Path' -MockValue $mockTestPath -Original $originalTestPath
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Mock-FileSystem'
)

