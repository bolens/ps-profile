<#
tests/unit/library-fragment-parallel-loading.tests.ps1

.SYNOPSIS
    Unit tests for FragmentParallelLoading edge cases.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'fragment/FragmentParallelLoading.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentParallelLoadingTests'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentParallelLoading Module' {
    Context 'Invoke-FragmentsInParallel' {
        It 'Returns an empty result for an empty fragment array' {
            $result = Invoke-FragmentsInParallel -FragmentFiles @() -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 0
            $result.FailureCount | Should -Be 0
            $result.UsedParallel | Should -Be $false
        }

        It 'Loads multiple fragments and reports succeeded fragment names' {
            foreach ($name in @('30-one.ps1', '40-two.ps1')) {
                Set-Content -LiteralPath (Join-Path $script:FragmentDir $name) -Value "# $name" -Encoding UTF8
            }

            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '30-one.ps1')),
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '40-two.ps1'))
            )

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 2
            $result.FailureCount | Should -Be 0
            @($result.SucceededFragments) | Should -Contain '30-one'
            @($result.SucceededFragments) | Should -Contain '40-two'
        }

        It 'Loads a single fragment sequentially without parallel runspaces' {
            $fragmentPath = Join-Path $script:FragmentDir '10-sample.ps1'
            Set-Content -LiteralPath $fragmentPath -Value @'
$global:FragmentParallelLoadingSampleValue = 'loaded'
'@ -Encoding UTF8

            $fragmentFile = Get-Item -LiteralPath $fragmentPath
            $result = Invoke-FragmentsInParallel -FragmentFiles @($fragmentFile) -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 1
            $result.FailureCount | Should -Be 0
            $result.UsedParallel | Should -Be $false
            $global:FragmentParallelLoadingSampleValue | Should -Be 'loaded'
        }

        It 'Reports failure when a fragment throws during load' {
            $fragmentPath = Join-Path $script:FragmentDir '20-broken.ps1'
            Set-Content -LiteralPath $fragmentPath -Value 'throw "fragment load failed"' -Encoding UTF8

            $fragmentFile = Get-Item -LiteralPath $fragmentPath
            $result = Invoke-FragmentsInParallel -FragmentFiles @($fragmentFile) -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 0
            $result.FailureCount | Should -Be 1
            @($result.Errors).Count | Should -BeGreaterThan 0
        }
    }
}
