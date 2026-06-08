<#
tests/unit/utility-verify-cache-cleared.tests.ps1

.SYNOPSIS
    Behavioral unit tests for verify-cache-cleared.ps1 with an isolated cache directory.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:VerifyCacheScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'verify-cache-cleared.ps1'
    $ConfirmPreference = 'None'
}

Describe 'verify-cache-cleared.ps1 execution' {
    It 'Reports success when the cache database does not exist in an isolated cache directory' {
        $cacheDir = New-TestTempDirectory -Prefix 'VerifyCacheCleared'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:VerifyCacheScript -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Database file does not exist|cache is cleared'
        }
        finally {
            if (Test-Path -LiteralPath $cacheDir) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
