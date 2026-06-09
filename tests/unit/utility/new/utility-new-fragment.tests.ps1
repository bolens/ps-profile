<#
tests/unit/utility-new-fragment.tests.ps1

.SYNOPSIS
    Behavioral unit tests for new-fragment.ps1 in an isolated repository fixture.
#>

function global:New-NewFragmentFixtureRepository {
    $repo = New-TestTempDirectory -Prefix 'NewFragmentRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $fragmentDir = Join-Path $scriptsDir 'utils' 'fragment'
    New-Item -ItemType Directory -Path $fragmentDir -Force | Out-Null
    Copy-Item -LiteralPath $script:NewFragmentScript -Destination (Join-Path $fragmentDir 'new-fragment.ps1') -Force

    New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d') -Force | Out-Null

    Push-Location $repo
    try {
    git init -q | Out-Null
    git config user.email 'fixture@example.com'
    git config user.name 'Fixture'
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
    $script:NewFragmentScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'new-fragment.ps1'
    $ConfirmPreference = 'None'
}

Describe 'new-fragment.ps1 execution' {
    It 'Creates a numbered fragment and README in an isolated profile.d directory' {
        $repo = New-NewFragmentFixtureRepository
        $fragmentName = 'fixture-feature'
        $fragmentNumber = 88
        Push-Location $repo
        try {
            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'utils' 'fragment' 'new-fragment.ps1') -ArgumentList @(
                '-Name', $fragmentName,
                '-Number', "$fragmentNumber",
                '-Description', 'Fixture fragment for new-fragment tests'
            )
        }
        finally {
            Pop-Location
        }
                $result.ExitCode | Should -Be 0
        $fragmentPath = Join-Path $repo 'profile.d' ('{0:D2}-{1}.ps1' -f $fragmentNumber, $fragmentName)
        $readmePath = Join-Path $repo 'profile.d' ('{0:D2}-{1}.ps1.README.md' -f $fragmentNumber, $fragmentName)
        Test-Path -LiteralPath $fragmentPath | Should -BeTrue
        Test-Path -LiteralPath $readmePath | Should -BeTrue
        Get-Content -LiteralPath $fragmentPath -Raw | Should -Match 'fixture-featureLoaded'
    }

    It 'Fails when creating a fragment that already exists' {
        $repo = New-NewFragmentFixtureRepository
        $fragmentName = 'duplicate-feature'
        $fragmentNumber = 77
        $scriptPath = Join-Path $repo 'scripts' 'utils' 'fragment' 'new-fragment.ps1'
        $first = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
            '-Name', $fragmentName,
            '-Number', "$fragmentNumber",
            '-Description', 'First fragment creation'
        )
        $first.ExitCode | Should -Be 0
                $second = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
            '-Name', $fragmentName,
            '-Number', "$fragmentNumber",
            '-Description', 'Duplicate fragment creation'
        )
        $second.ExitCode | Should -BeIn @(1, 2)
        $second.Output | Should -Match 'already exists'
    }

    It 'Fails when the fragment number is outside the supported range' {
        $repo = New-NewFragmentFixtureRepository
        $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'utils' 'fragment' 'new-fragment.ps1') -ArgumentList @(
            '-Name', 'out-of-range',
            '-Number', '150',
            '-Description', 'Fragment number out of range'
        )
                $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'Fragment number must be between 00 and 99'
    }
}
