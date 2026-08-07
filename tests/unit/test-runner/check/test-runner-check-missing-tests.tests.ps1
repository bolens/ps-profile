<#
tests/unit/test-runner/check/test-runner-check-missing-tests.tests.ps1

.SYNOPSIS
    Behavioral tests for check-missing-tests.ps1 using isolated repositories.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'check-missing-tests.ps1'
}

Describe 'check-missing-tests.ps1 execution' {
    BeforeEach {
        $script:FixtureRoot = New-TestTempDirectory -Prefix 'MissingTests'
        $script:LibRoot = Join-Path $script:FixtureRoot 'scripts' 'lib'
        $script:UnitRoot = Join-Path $script:FixtureRoot 'tests' 'unit' 'library'
        $null = New-Item -ItemType Directory -Path $script:LibRoot -Force
        $null = New-Item -ItemType Directory -Path $script:UnitRoot -Force
    }

    It 'matches normalized module names and extended test suffixes' {
        Set-Content -LiteralPath (Join-Path $script:LibRoot 'Json-Utilities.psm1') -Value '# fixture' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:UnitRoot 'library-json_utilities-structure-extended.tests.ps1') `
            -Value "Describe 'fixture' {}" -Encoding UTF8

        $output = & $script:CheckScript -RepositoryRoot $script:FixtureRoot *>&1 | Out-String

        $output | Should -Match 'Total modules:\s+1'
        $output | Should -Match 'Modules with tests:\s+1'
        $output | Should -Match 'Missing tests for:\s+\(none\)'
    }

    It 'recognizes aggregate test coverage' {
        Set-Content -LiteralPath (Join-Path $script:LibRoot 'CodeMetrics.psm1') -Value '# fixture' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:UnitRoot 'library-codeanalysis-extended.tests.ps1') `
            -Value "Describe 'fixture' {}" -Encoding UTF8

        $output = & $script:CheckScript -RepositoryRoot $script:FixtureRoot *>&1 | Out-String

        $output | Should -Match 'Modules with tests:\s+1'
        $output | Should -Match 'Missing tests for:\s+\(none\)'
    }

    It 'reports every module without direct or aggregate coverage' {
        Set-Content -LiteralPath (Join-Path $script:LibRoot 'FirstMissing.psm1') -Value '# fixture' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:LibRoot 'SecondMissing.psm1') -Value '# fixture' -Encoding UTF8

        {
            & $script:CheckScript -RepositoryRoot $script:FixtureRoot
        } | Should -Throw
    }

    It 'handles a repository with no library modules' {
        $output = & $script:CheckScript -RepositoryRoot $script:FixtureRoot *>&1 | Out-String

        $output | Should -Match 'Total modules:\s+0'
        $output | Should -Match 'Missing tests for:\s+\(none\)'
    }
}
