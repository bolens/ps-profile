<#
tests/unit/utility-database-maintenance.tests.ps1

.SYNOPSIS
    Behavioral unit tests for database-maintenance.ps1 execution.
#>

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
    $cases = @(
        @{ Name = 'health'; Arguments = @('-Action', 'health') }
        @{ Name = 'missing'; Arguments = @('-Action', 'statistics', '-Database', 'missing-db') }
        @{ Name = 'statistics'; Arguments = @('-Action', 'statistics', '-OutputFormat', 'json') }
        @{ Name = 'optimize'; Arguments = @('-Action', 'optimize') }
        @{ Name = 'backup'; Arguments = @('-Action', 'backup') }
        @{ Name = 'repair'; Arguments = @('-Action', 'repair') }
        @{ Name = 'invalid'; Arguments = @('-Action', 'definitely-not-a-db-action') }
    )
    $jobs = foreach ($case in $cases) {
        $cacheDir = New-TestTempDirectory -Prefix "DatabaseMaintenance-$($case.Name)"
        $caseJson = $case | ConvertTo-Json -Compress
        Start-Job -ScriptBlock {
            param($ScriptPath, $CaseJson, $CacheDirectory)

            $testCase = $CaseJson | ConvertFrom-Json
            $env:PS_PROFILE_CACHE_DIR = $CacheDirectory
            $output = & pwsh -NoProfile -File $ScriptPath @($testCase.Arguments) 2>&1 | Out-String
            [pscustomobject]@{
                Name     = $testCase.Name
                ExitCode = $LASTEXITCODE
                Output   = $output
            }
        } -ArgumentList $script:DatabaseMaintenanceScript, $caseJson, $cacheDir
    }
    $script:MaintenanceResults = @{}
    $jobs | Receive-Job -Wait | ForEach-Object {
        $script:MaintenanceResults[$_.Name] = $_
    }
    $jobs | Remove-Job -Force
    $ConfirmPreference = 'None'
}

Describe 'database-maintenance.ps1 execution' {
    It 'Accepts health action without enum load errors' {
        $result = $script:MaintenanceResults.health

        $result.Output | Should -Not -Match 'Unable to find type \[DatabaseAction\]'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Fails validation for an unknown database name when SQLite utilities are available' {
        $result = $script:MaintenanceResults.missing

        if ($result.Output -match 'SqliteDatabase\.psm1 was not found') {
            $result.ExitCode | Should -BeIn @(1, 2, 3)
            return
        }

        $result.Output | Should -Match 'Unknown database'
        $result.ExitCode | Should -BeIn @(1, 2)
    }

    It 'Accepts statistics action with JSON output format' {
        $result = $script:MaintenanceResults.statistics

        $result.Output | Should -Not -Match 'Unable to find type \[DatabaseAction\]'
        if ($result.Output -match 'SqliteDatabase\.psm1 was not found') {
            $result.ExitCode | Should -BeIn @(1, 2, 3)
            return
        }

        $result.Output | Should -Match 'statistics|database|Database'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Accepts optimize action without enum load errors' {
        $result = $script:MaintenanceResults.optimize

        $result.Output | Should -Not -Match 'Unable to find type \[DatabaseAction\]'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Accepts backup action without enum load errors' {
        $result = $script:MaintenanceResults.backup

        $result.Output | Should -Not -Match 'Unable to find type \[DatabaseAction\]'
        if ($result.Output -match 'SqliteDatabase\.psm1 was not found') {
            $result.ExitCode | Should -BeIn @(1, 2, 3)
            return
        }

        $result.Output | Should -Match 'backup|Backup|database'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Accepts repair action without enum load errors' {
        $result = $script:MaintenanceResults.repair

        $result.Output | Should -Not -Match 'Unable to find type \[DatabaseAction\]'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Rejects unknown maintenance actions' {
        $result = $script:MaintenanceResults.invalid

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Action|ValidateSet|cannot be validated'
    }
}
