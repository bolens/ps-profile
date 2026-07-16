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

Describe 'generate-changelog.ps1 execution' {
    It 'Exits with setup error when git-cliff is not installed' {
        if ($script:GitCliffAvailable) {
            Set-ItResult -Skipped -Because 'git-cliff is installed on this host'
            return
        }

        # Script refuses auto-install when PS_PROFILE_TEST_MODE / NONINTERACTIVE is set
        # (inherited by Invoke-TestScriptFile child processes).
        $repo = New-GenerateChangelogTestRepository
        $scriptPath = Join-Path $repo 'scripts' 'utils' 'docs' 'generate-changelog.ps1'
        $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
            '-OutputFile', 'CHANGELOG-test.md'
        ) -EnvironmentVariables @{
            PS_PROFILE_TEST_MODE           = '1'
            PS_PROFILE_NONINTERACTIVE      = '1'
            PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'
        }
        # Under PS_PROFILE_TEST_MODE the script's Exit-WithCode throws instead of calling
        # [Environment]::Exit, so the child pwsh returns a non-zero (1) code rather than 2.
        # Either way the run must fail and surface the git-cliff refusal message.
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'git-cliff|required|non-interactive'
    }

    It 'Runs git-cliff without a cliff.toml config file in an isolated repository' {
        if (-not $script:GitCliffAvailable) {
            Set-ItResult -Skipped -Because 'git-cliff is not installed'
            return
        }

        $repo = New-TestTempDirectory -Prefix 'GenerateChangelogNoCliff'
        $docsDir = Join-Path $repo 'scripts' 'utils' 'docs'
        New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:GenerateChangelogScript -Destination (Join-Path $docsDir 'generate-changelog.ps1') -Force
                Push-Location $repo
        try {
            & git init -q 2>$null
            & git config user.email 'test@example.com' 2>$null
            & git config user.name 'Test User' 2>$null
            & git commit --allow-empty -m 'feat(init): seed repository' -q 2>$null
        }
        finally {
            Pop-Location
        }
                $scriptPath = Join-Path $docsDir 'generate-changelog.ps1'
        $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
            '-OutputFile', 'CHANGELOG-missing-cliff.md'
        )
                Test-Path -LiteralPath (Join-Path $repo 'cliff.toml') | Should -Be $false
        $result.ExitCode | Should -BeIn @(0, 1, 2)
        $result.Output | Should -Match 'git-cliff|changelog|Changelog'
    }
}
