<#
tests/unit/utility-diagnose-profile-performance.tests.ps1

.SYNOPSIS
    Behavioral unit tests for diagnose-profile-performance.ps1 smoke execution.
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
    $script:DiagnoseProfilePerfScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'performance' 'diagnose-profile-performance.ps1'
    $ConfirmPreference = 'None'
}

Describe 'diagnose-profile-performance.ps1 execution' {
    It 'Runs profile performance diagnostics and prints recommendations' {
        if ($env:CI -or $env:GITHUB_ACTIONS -or $env:PS_PROFILE_RUN_SLOW_TESTS -ne '1') {
            Set-ItResult -Skipped -Because 'set PS_PROFILE_RUN_SLOW_TESTS=1 to run full profile load diagnostics locally'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:DiagnoseProfilePerfScript

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Profile Performance Diagnostics|Optimization Recommendations'
    }

    It 'Prints optimization recommendations even when the repository profile file is absent' {
        $repo = New-TestTempDirectory -Prefix 'DiagnoseProfilePerfRepo'
        $perfDir = Join-Path $repo 'scripts' 'utils' 'performance'
        $null = New-Item -ItemType Directory -Path $perfDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:DiagnoseProfilePerfScript -Destination (Join-Path $perfDir 'diagnose-profile-performance.ps1') -Force
                Push-Location $repo
        try {
            git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
            git add README.md
            git commit -m 'init' -q
        }
        finally {
            Pop-Location
        }
                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $perfDir 'diagnose-profile-performance.ps1')
                $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Profile Performance Diagnostics'
        $result.Output | Should -Match 'Method 1: Testing with performance profiling'
        $result.Output | Should -Match 'Optimization Recommendations'
    }

    It 'Completes diagnostics when PS_PROFILE_DEBUG is set in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'DiagnoseProfilePerfDebug'
        $perfDir = Join-Path $repo 'scripts' 'utils' 'performance'
        $null = New-Item -ItemType Directory -Path $perfDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:DiagnoseProfilePerfScript -Destination (Join-Path $perfDir 'diagnose-profile-performance.ps1') -Force
                Push-Location $repo
        try {
            git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
            git add README.md
            git commit -m 'init' -q
        }
        finally {
            Pop-Location
        }
                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $perfDir 'diagnose-profile-performance.ps1') -EnvironmentVariables @{
            PS_PROFILE_DEBUG = '2'
        }
                $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Profile Performance Diagnostics'
        $result.Output | Should -Match 'Optimization Recommendations'
    }
}
