<#
tests/unit/utility-sync-profile-fragments.tests.ps1

.SYNOPSIS
    Behavioral unit tests for sync-profile-fragments.ps1 DryRun execution.
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
    $script:SyncFragmentsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'sync-profile-fragments.ps1'
    $ConfirmPreference = 'None'
}

Describe 'sync-profile-fragments.ps1 execution' {
    It 'DryRun previews fragment config sync without modifying .profile-fragments.json' {
        $configPath = Join-Path $script:TestRepoRoot '.profile-fragments.json'
        $before = if (Test-Path -LiteralPath $configPath) {
            Get-Content -LiteralPath $configPath -Raw
        }
        else {
            $null
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:SyncFragmentsScript -ArgumentList @(
            '-DryRun',
            '-ProfileDir', $script:TestRepoRoot
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN|DryRun|Would|fragment'

        if ($null -ne $before) {
            (Get-Content -LiteralPath $configPath -Raw) | Should -Be $before
        }
    }

    It 'Fails when the profile directory does not exist' {
        $missingProfileDir = Join-Path (New-TestTempDirectory -Prefix 'SyncFragmentsMissing') 'no-profile-dir'
            $result = Invoke-TestScriptFile -ScriptPath $script:SyncFragmentsScript -ArgumentList @(
                '-ProfileDir', $missingProfileDir
            )

            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'profile\.d directory not found'
    }

    It 'Writes .profile-fragments.json for an isolated profile directory' {
        $repo = New-TestTempDirectory -Prefix 'SyncFragmentsApply'
            $fragmentDir = Join-Path $repo 'scripts' 'utils' 'fragment'
            $profileDir = Join-Path $repo 'profile.d'
            $null = New-Item -ItemType Directory -Path $fragmentDir -Force
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:SyncFragmentsScript -Destination (Join-Path $fragmentDir 'sync-profile-fragments.ps1') -Force

            Set-Content -LiteralPath (Join-Path $profileDir 'sync-fixture.ps1') -Value @'
# Environment: minimal
function Get-SyncFragmentsFixture {
    'fixture'
}
'@ -Encoding UTF8

            $configPath = Join-Path $repo '.profile-fragments.json'
            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $fragmentDir 'sync-profile-fragments.ps1') -ArgumentList @(
                    '-ProfileDir', $repo
                )
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            Test-Path -LiteralPath $configPath | Should -BeTrue
            $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            $config.environments | Should -Not -BeNullOrEmpty
    }
}
