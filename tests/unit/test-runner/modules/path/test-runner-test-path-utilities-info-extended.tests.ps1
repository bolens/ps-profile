<#
tests/unit/test-runner-test-path-utilities-info-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Test-TestPaths validation and discovery logging.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPathUtilities.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'TestPathUtilitiesInfoExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestPathUtilities info extended scenarios' {
    Context 'Test-TestPaths' {
        It 'Retains only existing paths when the input list is mixed' {
            $validFile = Join-Path $script:TempDir 'valid.tests.ps1'
            Set-Content -LiteralPath $validFile -Value "Describe 'Valid' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8
            $missing = Join-Path $script:TempDir 'missing.tests.ps1'

            $result = Test-TestPaths -TestPaths @($validFile, $missing) -Suite 'Unit' -RepoRoot $script:TestRepoRoot -WarningAction SilentlyContinue

            $result | Should -Contain $validFile
            $result | Should -Not -Contain $missing
        }

        It 'Falls back to the repository tests directory when every path is invalid' {
            $result = Test-TestPaths -TestPaths @('missing-a', 'missing-b') -Suite 'Unit' -RepoRoot $script:TestRepoRoot -WarningAction SilentlyContinue

            $result | Should -Contain (Join-Path $script:TestRepoRoot 'tests')
        }
    }

    Context 'Write-TestDiscoveryInfo' {
        It 'Logs suite discovery output for directory selections' {
            $unitDir = Join-Path $script:TestRepoRoot 'tests/unit'
            $output = @(Write-TestDiscoveryInfo -TestPaths @($unitDir) -Suite 'Unit' -TestFile '' | ForEach-Object { "$_" })

            ($output -join ' ') | Should -Match "suite 'Unit'"
        }

        It 'Logs relative paths when a single test file is selected' {
            $testFile = Join-Path $script:TempDir 'selected.tests.ps1'
            Set-Content -LiteralPath $testFile -Value "Describe 'Selected' { It 'runs' { `$true | Should -Be `$true } }" -Encoding UTF8

            $output = @(Write-TestDiscoveryInfo -TestPaths @($testFile) -Suite 'Unit' -TestFile $testFile | ForEach-Object { "$_" })

            ($output -join ' ') | Should -Match 'selected\.tests\.ps1'
        }
    }
}
