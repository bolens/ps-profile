<#
tests/unit/test-runner-test-cache.tests.ps1

.SYNOPSIS
    Unit tests for TestCache module (JSON cache path).
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestCache.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestCacheTests'
    $script:CachePath = Join-Path $script:TempDir 'cache'
    $script:TestFile = New-TestTempFile -Prefix 'cache-target' -Extension '.tests.ps1' -Content "Describe 'Cache target' { It 'runs' { `$true | Should -Be `$true } }"
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestCache Module' {
    Context 'Get-TestCacheStatus' {
        It 'Reports missing cache directory' {
            $missingPath = Join-Path $script:TempDir 'missing-cache'
            $status = Get-TestCacheStatus -CachePath $missingPath -TestPaths @($script:TestFile)

            $status.IsValid | Should -Be $false
            $status.Reason | Should -Match 'does not exist'
        }

        It 'Invalidates cache when Force is specified' {
            $status = Get-TestCacheStatus -CachePath $script:CachePath -TestPaths @($script:TestFile) -Force

            $status.IsValid | Should -Be $false
            $status.Reason | Should -Match 'forced'
        }
    }

    Context 'Save-TestCache and validation' {
        It 'Saves and validates cache for unchanged test files' {
            $testResult = [pscustomobject]@{
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(0.5)
            }

            Save-TestCache -TestResult $testResult -TestPaths @($script:TestFile) -CachePath $script:CachePath

            $status = Get-TestCacheStatus -CachePath $script:CachePath -TestPaths @($script:TestFile)
            $status.IsValid | Should -Be $true
            $status.Reason | Should -Match 'valid'
        }

        It 'Invalidates cache after test file content changes' {
            $testResult = [pscustomobject]@{
                PassedCount  = 1
                FailedCount  = 0
                SkippedCount = 0
                Time         = [TimeSpan]::FromSeconds(0.5)
            }

            Save-TestCache -TestResult $testResult -TestPaths @($script:TestFile) -CachePath $script:CachePath
            Add-Content -LiteralPath $script:TestFile -Value "`n# changed" -Encoding UTF8

            $status = Get-TestCacheStatus -CachePath $script:CachePath -TestPaths @($script:TestFile)
            $status.IsValid | Should -Be $false
            $status.Reason | Should -Match 'changed'
        }
    }
}
