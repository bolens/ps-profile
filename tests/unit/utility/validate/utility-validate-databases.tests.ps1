<#
tests/unit/utility-validate-databases.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-databases.ps1 execution.
#>

function global:Invoke-ValidateDatabasesScript {
    param(
        [string[]]$ArgumentList = @()
    )

    $output = & pwsh -NoProfile -File $script:ValidateDatabasesScript @ArgumentList 2>&1 | Out-String
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
    $script:ValidateDatabasesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'validate-databases.ps1'
    $script:SqliteAvailable = [bool](Get-Command sqlite3 -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'validate-databases.ps1 execution' {
    It 'Runs validation and reports SQLite availability' {
        $result = Invoke-ValidateDatabasesScript

        $result.Output | Should -Match 'Validating SQLite Database Implementation'
        $result.Output | Should -Match 'SQLite'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Accepts Json output format without enum load errors' {
        $result = Invoke-ValidateDatabasesScript -ArgumentList @('-OutputFormat', 'Json')

        $result.Output | Should -Not -Match 'Unable to find type \[OutputFormat\]'
        $result.Output | Should -Match 'SqliteAvailable|SQLite Available'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Rejects unsupported OutputFormat values' {
        $result = Invoke-ValidateDatabasesScript -ArgumentList @('-OutputFormat', 'Xml')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'OutputFormat|ValidateSet|cannot be validated'
    }
}
