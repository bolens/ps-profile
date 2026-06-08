<#
tests/unit/library-fragment-parallel-loading-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-FragmentsInParallel mixed outcomes and metadata.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/fragment/FragmentParallelLoading.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentParallelExtended'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentParallelLoading extended scenarios' {
    Context 'Invoke-FragmentsInParallel' {
        It 'Reports partial success when one fragment fails and another succeeds' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '31-good.ps1') -Value '$global:ParallelExtendedGood = $true' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '32-bad.ps1') -Value 'throw "partial failure"' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '31-good.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '32-bad.ps1'))
            )

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 1
            $result.FailureCount | Should -Be 1
            @($result.Errors).Count | Should -BeGreaterThan 0
        }

        It 'Includes succeeded fragment names in the result object' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '33-a.ps1') -Value '# ok' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '34-b.ps1') -Value '# ok' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '33-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '34-b.ps1'))
            )

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            @($result.SucceededFragments) | Should -Contain '33-a'
            @($result.SucceededFragments) | Should -Contain '34-b'
        }

        It 'Returns UsedParallel false for a single fragment load' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '35-single.ps1') -Value '# single' -Encoding UTF8
            $fragment = Get-Item -LiteralPath (Join-Path $script:FragmentDir '35-single.ps1')

            $result = Invoke-FragmentsInParallel -FragmentFiles @($fragment) -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
        }

        It 'Reports failed fragment names when a load throws' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '36-count.ps1') -Value 'throw "count failure"' -Encoding UTF8
            $fragment = Get-Item -LiteralPath (Join-Path $script:FragmentDir '36-count.ps1')

            $result = Invoke-FragmentsInParallel -FragmentFiles @($fragment) -ProfileFragmentRoot $script:FragmentDir

            @($result.FailedFragments).Count | Should -Be 1
            $result.FailedFragments[0].Name | Should -Be '36-count'
        }
    }
}
