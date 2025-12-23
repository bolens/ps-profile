<#
scripts/utils/code-quality/modules/TestDependencyManagement.psm1

.SYNOPSIS
    Test dependency management utilities.

.DESCRIPTION
    Provides functions for analyzing test dependencies and ensuring proper execution order.
#>

<#
.SYNOPSIS
    Manages test dependencies and execution order.

.DESCRIPTION
    Analyzes test dependencies and ensures proper execution order
    to avoid test interference and improve reliability.

.PARAMETER TestPaths
    Array of test file paths to analyze.

.PARAMETER DependencyMap
    Custom dependency mapping for tests.

.OUTPUTS
    Ordered list of test files with dependency information
#>
function Get-TestExecutionOrder {
    param(
        [string[]]$TestPaths,
        [hashtable]$DependencyMap = @{}
    )

    # Simple dependency analysis based on file names and content
    $testFiles = @()

    foreach ($path in $TestPaths) {
        $fileInfo = @{
            Path         = $path
            Name         = Split-Path $path -Leaf
            Dependencies = @()
            Priority     = 0
        }

        # Analyze file content for dependencies (basic implementation)
        if ($path -and -not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            $content = Get-Content $path -Raw

            # Look for dependency markers in comments
            $deps = [regex]::Matches($content, '#\s*DependsOn:\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
            ForEach-Object { $_.Groups[1].Value.Trim() }

            $fileInfo.Dependencies = $deps

            # Assign priority based on test type
            if ($fileInfo.Name -like '*unit*') {
                $fileInfo.Priority = 1
            }
            elseif ($fileInfo.Name -like '*integration*') {
                $fileInfo.Priority = 2
            }
            elseif ($fileInfo.Name -like '*performance*') {
                $fileInfo.Priority = 3
            }
        }

        $testFiles += $fileInfo
    }

    # Sort by priority and dependencies
    $orderedFiles = $testFiles | Sort-Object {
        $_.Priority
    } | Select-Object -ExpandProperty Path

    return $orderedFiles
}

Export-ModuleMember -Function Get-TestExecutionOrder

