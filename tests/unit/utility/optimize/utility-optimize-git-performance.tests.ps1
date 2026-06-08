<#
tests/unit/utility-optimize-git-performance.tests.ps1

.SYNOPSIS
    Behavioral smoke test for optimize-git-performance.ps1 with an isolated HOME.
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
    $script:OptimizeGitPerfScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'performance' 'optimize-git-performance.ps1'
    $script:GitWrapperPath = Join-Path $script:TestRepoRoot 'profile.d' 'git-fast-wrapper.ps1'
    $ConfirmPreference = 'None'
}

Describe 'optimize-git-performance.ps1 execution' {
    It 'Applies git optimizations without touching the real user git config' {
        $tempHome = New-TestTempDirectory -Prefix 'git-optimize-home'
        $wrapperExisted = Test-Path -LiteralPath $script:GitWrapperPath
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:OptimizeGitPerfScript -EnvironmentVariables @{
                HOME        = $tempHome
                USERPROFILE = $tempHome
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Optimizing Git Performance'
            $result.Output | Should -Match 'Git performance optimizations applied'
            Test-Path -LiteralPath (Join-Path $tempHome '.gitconfig') | Should -BeTrue
        }
        finally {
            if (Test-Path -LiteralPath $tempHome) {
                Remove-Item -LiteralPath $tempHome -Recurse -Force -ErrorAction SilentlyContinue
            }

            if (-not $wrapperExisted -and (Test-Path -LiteralPath $script:GitWrapperPath)) {
                Remove-Item -LiteralPath $script:GitWrapperPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
