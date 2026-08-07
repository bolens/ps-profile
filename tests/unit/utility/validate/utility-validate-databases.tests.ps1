<#
tests/unit/utility-validate-databases.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-databases.ps1 execution.
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
    $script:ValidateDatabasesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'validate-databases.ps1'
    $script:SqliteAvailable = [bool](Get-Command sqlite3 -ErrorAction SilentlyContinue)
    $cases = @(
        @{ Name = 'default'; Arguments = @() }
        @{ Name = 'json'; Arguments = @('-OutputFormat', 'Json') }
        @{ Name = 'invalid'; Arguments = @('-OutputFormat', 'Xml') }
    )
    $jobs = foreach ($case in $cases) {
        $cacheDir = New-TestTempDirectory -Prefix "ValidateDatabases-$($case.Name)"
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
        } -ArgumentList $script:ValidateDatabasesScript, $caseJson, $cacheDir
    }
    $script:ValidationResults = @{}
    $jobs | Receive-Job -Wait | ForEach-Object {
        $script:ValidationResults[$_.Name] = $_
    }
    $jobs | Remove-Job -Force
    $ConfirmPreference = 'None'
}

Describe 'validate-databases.ps1 execution' {
    It 'Runs validation and reports SQLite availability' {
        $result = $script:ValidationResults.default

        $result.Output | Should -Match 'Validating SQLite Database Implementation'
        $result.Output | Should -Match 'SQLite'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Accepts Json output format without enum load errors' {
        $result = $script:ValidationResults.json

        $result.Output | Should -Not -Match 'Unable to find type \[OutputFormat\]'
        $result.Output | Should -Match 'SqliteAvailable|SQLite Available'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Rejects unsupported OutputFormat values' {
        $result = $script:ValidationResults.invalid

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'OutputFormat|ValidateSet|cannot be validated'
    }

    It 'Reports validation summary in table output format' {
        $result = $script:ValidationResults.default

        $result.Output | Should -Match 'Validating SQLite Database Implementation|SQLite'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }
}
