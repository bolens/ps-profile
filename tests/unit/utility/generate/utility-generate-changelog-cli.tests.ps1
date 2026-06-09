<#
tests/unit/utility-generate-changelog-cli.tests.ps1

.SYNOPSIS
    Behavioral smoke test for generate-changelog.ps1 when git-cliff is installed.
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
    $script:GenerateChangelogScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-changelog.ps1'
    $script:GitCliffAvailable = [bool](Get-Command git-cliff -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'generate-changelog.ps1 with git-cliff installed' {
    It 'Generates CHANGELOG.md using cliff.toml when git-cliff is available' {
        if (-not $script:GitCliffAvailable) {
            Set-ItResult -Skipped -Because 'git-cliff is not installed'
            return
        }

        if (-not (Test-Path -LiteralPath (Join-Path $script:TestRepoRoot 'cliff.toml'))) {
            Set-ItResult -Skipped -Because 'cliff.toml is not present in the repository root'
            return
        }

        $outputFull = Get-TestArtifactPath -FileName 'CHANGELOG-cli-test.md'
        $outputRel = Get-TestRepoRelativePath -Path $outputFull -StartPath $PSScriptRoot

        $result = Invoke-TestScriptFile -ScriptPath $script:GenerateChangelogScript -ArgumentList @(
            '-OutputFile', $outputRel
        )

        $result.ExitCode | Should -Be 0
        Test-Path -LiteralPath $outputFull | Should -BeTrue
        $result.Output | Should -Not -Match 'cliff.toml.*is not found'
    }

    It 'Uses git-cliff default configuration when cliff.toml is missing in an isolated repository' {
        if (-not $script:GitCliffAvailable) {
            Set-ItResult -Skipped -Because 'git-cliff is not installed'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'GenerateChangelogNoCliff'
        $docsDir = Join-Path $repo 'scripts' 'utils' 'docs'
        $null = New-Item -ItemType Directory -Path $docsDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:GenerateChangelogScript -Destination (Join-Path $docsDir 'generate-changelog.ps1') -Force

        Push-Location $repo
                git init -q | Out-Null
        git config user.email 'fixture@example.com'
        git config user.name 'Fixture'
        Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
        git add README.md
        git commit -m 'init' -q
    }
    finally {
        Pop-Location

        $outputRel = 'CHANGELOG-fixture.md'
        $result = Invoke-TestScriptFile -ScriptPath (Join-Path $docsDir 'generate-changelog.ps1') -ArgumentList @(
            '-OutputFile', $outputRel
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'cliff\.toml.*not found|default configuration|Changelog generated successfully'
        Test-Path -LiteralPath (Join-Path $repo $outputRel) | Should -BeTrue
    }
}
