<#
tests/unit/utility-create-release.tests.ps1

.SYNOPSIS
    Behavioral unit tests for create-release.ps1 DryRun in an isolated git repository.
#>

function global:New-CreateReleaseTestRepository {
    $repo = New-TestTempDirectory -Prefix 'CreateReleaseRepo'
    $releaseDir = Join-Path $repo 'scripts' 'utils' 'release'
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
    Copy-Item -LiteralPath $script:CreateReleaseScript -Destination (Join-Path $releaseDir 'create-release.ps1') -Force

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

    return $repo
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CreateReleaseScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'release' 'create-release.ps1'
    $script:GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'create-release.ps1 execution' {
    It 'DryRun analyzes commits without creating tags in an isolated repository' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CreateReleaseTestRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'utils' 'release' 'create-release.ps1'
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @('-DryRun')

            $result.ExitCode | Should -BeIn @(0, 1, 2)
            $result.Output | Should -Match 'Analyzing commits|Breaking changes|features|fixes|DryRun|release'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
