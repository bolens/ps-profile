<#
tests/unit/utility-generate-changelog.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-changelog.ps1 when git-cliff is unavailable.
#>

function global:New-GenerateChangelogTestRepository {
    $repo = New-TestTempDirectory -Prefix 'GenerateChangelogRepo'
    $docsDir = Join-Path $repo 'scripts' 'utils' 'docs'
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
    Copy-Item -LiteralPath $script:GenerateChangelogScript -Destination (Join-Path $docsDir 'generate-changelog.ps1') -Force
    Set-Content -LiteralPath (Join-Path $repo 'cliff.toml') -Value '[changelog]' -Encoding UTF8
    return $repo
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:GenerateChangelogScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-changelog.ps1'
    $script:GitCliffAvailable = [bool](Get-Command git-cliff -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'generate-changelog.ps1 execution' {
    It 'Exits with setup error when git-cliff is not installed' {
        if ($script:GitCliffAvailable) {
            Set-ItResult -Skipped -Because 'git-cliff is installed on this host'
            return
        }

        $repo = New-GenerateChangelogTestRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'utils' 'docs' 'generate-changelog.ps1'
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
                '-OutputFile', 'CHANGELOG-test.md'
            )

            $result.ExitCode | Should -Be 2
            $result.Output | Should -Match 'git-cliff|required'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
