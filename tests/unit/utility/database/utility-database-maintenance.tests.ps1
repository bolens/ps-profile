<#
tests/unit/utility-database-maintenance.tests.ps1

.SYNOPSIS
    Behavioral unit tests for database-maintenance.ps1 execution.
#>

function global:Invoke-DatabaseMaintenanceScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:DatabaseMaintenanceScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:DatabaseMaintenanceScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'database-maintenance.ps1'
    $ConfirmPreference = 'None'
}

Describe 'database-maintenance.ps1 execution' {
    It 'Accepts health action without enum load errors' {
        $result = Invoke-DatabaseMaintenanceScript -ArgumentList @('-Action', 'health')

        $result.Output | Should -Not -Match 'Unable to find type \[DatabaseAction\]'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Fails validation for an unknown database name when SQLite utilities are available' {
        $result = Invoke-DatabaseMaintenanceScript -ArgumentList @('-Action', 'statistics', '-Database', 'missing-db')

        if ($result.Output -match 'SqliteDatabase\.psm1 was not found') {
            $result.ExitCode | Should -BeIn @(1, 2, 3)
            return
        }

        $result.Output | Should -Match 'Unknown database'
        $result.ExitCode | Should -BeIn @(1, 2)
    }

    It 'Rejects unknown maintenance actions' {
        $result = Invoke-DatabaseMaintenanceScript -ArgumentList @('-Action', 'definitely-not-a-db-action')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Action|ValidateSet|cannot be validated'
    }
}
