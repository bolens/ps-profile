<#
tests/unit/test-runner-test-cache-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestCache JSON fallback edge cases.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestCache.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestCacheExtended'
    $script:TestFile = New-TestTempFile -Prefix 'cache-extended-target' -Extension '.tests.ps1' -Content "Describe 'Cache target' { It 'runs' { `$true | Should -Be `$true } }"
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestCache extended scenarios' {
    Context 'Get-TestCacheStatus edge cases' {
        It 'Reports missing cache file when cache directory exists' {
            $cachePath = Join-Path $script:TempDir 'empty-cache-dir'
            New-Item -ItemType Directory -Path $cachePath -Force | Out-Null

            $status = Get-TestCacheStatus -CachePath $cachePath -TestPaths @($script:TestFile)

            $status.IsValid | Should -Be $false
            $status.Reason | Should -Match 'Cache file does not exist'
        }

        It 'Reports read failure for corrupt cache JSON' {
            $cachePath = Join-Path $script:TempDir 'corrupt-cache'
            New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $cachePath 'results.cache') -Value '{ invalid json cache }' -Encoding UTF8

            $status = Get-TestCacheStatus -CachePath $cachePath -TestPaths @($script:TestFile)

            $status.IsValid | Should -Be $false
            $status.Reason | Should -Match 'Failed to read cache'
        }

        It 'Returns invalid status when no test paths are supplied' {
            $cachePath = Join-Path $script:TempDir 'no-paths-cache'
            New-Item -ItemType Directory -Path $cachePath -Force | Out-Null

            $status = Get-TestCacheStatus -CachePath $cachePath -TestPaths @()

            $status.IsValid | Should -Be $false
            $status.Reason | Should -Not -BeNullOrEmpty
        }
    }
}
