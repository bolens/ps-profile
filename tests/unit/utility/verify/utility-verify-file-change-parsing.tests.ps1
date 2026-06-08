<#
tests/unit/utility-verify-file-change-parsing.tests.ps1

.SYNOPSIS
    Behavioral unit tests for verify-file-change-parsing.ps1 prerequisite checks.
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
    $script:VerifyFileChangeParsingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'verify-file-change-parsing.ps1'
    $script:CacheInitModule = Join-Path $script:TestRepoRoot 'scripts' 'lib' 'fragment' 'FragmentCacheInitialization.psm1'
    $ConfirmPreference = 'None'
}

Describe 'verify-file-change-parsing.ps1 execution' {
    It 'Fails fast when FragmentCacheInitialization is not available' {
        if (Test-Path -LiteralPath $script:CacheInitModule) {
            Set-ItResult -Skipped -Because 'FragmentCacheInitialization module is present; prerequisite failure path is not testable'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:VerifyFileChangeParsingScript

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'FragmentCacheInitialization module not found'
    }
}
