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
        $scriptPath = Join-Path $repo 'scripts' 'utils' 'release' 'create-release.ps1'
        Push-Location $repo
        try {
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @('-DryRun')
        }
        finally {
            Pop-Location
        }
                $result.ExitCode | Should -BeIn @(0, 1, 2)
        $result.Output | Should -Match 'Analyzing commits|Breaking changes|features|fixes|DryRun|release'
    }

    It 'DryRun recommends a minor version bump when feature commits are present' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CreateReleaseTestRepository
        Push-Location $repo
        try {
            & git commit --allow-empty -m 'feat(release): add release fixture feature' -q 2>$null
        }
        finally {
            Pop-Location
        }
                $scriptPath = Join-Path $repo 'scripts' 'utils' 'release' 'create-release.ps1'
        Push-Location $repo
        try {
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @('-DryRun')
        }
        finally {
            Pop-Location
        }
                $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Features: [1-9]'
        $result.Output | Should -Match 'Recommended version bump: minor'
        $result.Output | Should -Match 'DRY RUN'
    }

    It 'DryRun recommends a major version bump when breaking commits are present' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CreateReleaseTestRepository
        Push-Location $repo
        try {
            & git commit --allow-empty -m 'feat!: remove deprecated profile hook' -q 2>$null
        }
        finally {
            Pop-Location
        }
                $scriptPath = Join-Path $repo 'scripts' 'utils' 'release' 'create-release.ps1'
        Push-Location $repo
        try {
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @('-DryRun')
        }
        finally {
            Pop-Location
        }
                $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Breaking changes: [1-9]'
        $result.Output | Should -Match 'Recommended version bump: major'
    }
}
