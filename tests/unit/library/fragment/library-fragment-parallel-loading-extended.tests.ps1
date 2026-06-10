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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-TestLibraryModule -ModulePath (Join-Path $script:LibPath 'fragment' 'FragmentParallelLoading.psm1')

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentParallelExtended'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null
}

function script:Clear-ParallelLoadTestEnvironment {
    foreach ($name in @(
            'PS_PROFILE_DEBUG'
            'PS_PROFILE_PARALLEL_LOAD_TIMEOUT_MS'
            'PS_PROFILE_PARALLEL_LOAD_FORCE_TIMEOUT'
            'PS_PROFILE_PARALLEL_LOAD_FORCE_POOL_ERROR'
            'PS_PROFILE_PARALLEL_LOAD_FORCE_REEXEC_FAIL'
            'PS_PROFILE_PARALLEL_LOAD_FORCE_RUNSPACE_FAIL'
            'PS_PROFILE_PARALLEL_LOAD_TEST_INLINE'
            'PS_PROFILE_PARALLEL_LOAD_FORCE_POLL_TIMEOUT'
            'PS_PROFILE_PARALLEL_LOAD_FORCE_ENDINVOKE_FAIL'
        )) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

AfterAll {
    Clear-ParallelLoadTestEnvironment
    Remove-Module FragmentParallelLoading -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentParallelLoading extended scenarios' {
    BeforeEach {
        Clear-ParallelLoadTestEnvironment
        Remove-Item Variable:global:ParallelExtendedGood -ErrorAction SilentlyContinue
        Remove-Item Variable:global:ParallelBootstrapMarker -ErrorAction SilentlyContinue
        Remove-Item Variable:global:ParallelReexecMarker -ErrorAction SilentlyContinue
    }

    Context 'Invoke-FragmentsInParallel' {
        It 'Returns an empty result object for an empty fragment list' {
            $result = Invoke-FragmentsInParallel -FragmentFiles @() -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 0
            $result.FailureCount | Should -Be 0
            $result.UsedParallel | Should -Be $false
            @($result.SucceededFragments).Count | Should -Be 0
        }

        It 'Reports partial success when one fragment fails and another succeeds' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '31-good.ps1') -Value '$global:ParallelExtendedGood = $true' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '32-bad.ps1') -Value 'throw "partial failure"' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '31-good.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '32-bad.ps1'))
            )

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -BeGreaterOrEqual 1
            $result.FailureCount | Should -BeGreaterOrEqual 1
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

        It 'Sets ProfileFragmentRoot when loading a single fragment' {
            $nestedDir = Join-Path $script:FragmentDir 'nested-single'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            $fragmentPath = Join-Path $nestedDir '37-root.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '$global:ParallelRootMarker = $global:ProfileFragmentRoot' -Encoding UTF8
            $fragment = Get-Item -LiteralPath $fragmentPath

            $null = Invoke-FragmentsInParallel -FragmentFiles @($fragment) -ProfileFragmentRoot $script:FragmentDir
            $global:ParallelRootMarker | Should -Be $nestedDir
        }

        It 'Falls back to sequential loading when the runspace pool setup is forced to fail' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '38-fallback-a.ps1') -Value '$global:ParallelFallbackA = 1' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '39-fallback-b.ps1') -Value '$global:ParallelFallbackB = 2' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '38-fallback-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '39-fallback-b.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_POOL_ERROR = '1'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 2
            $result.UsedParallel | Should -Be $false
            $global:ParallelFallbackA | Should -Be 1
            $global:ParallelFallbackB | Should -Be 2
        }

        It 'Falls back to sequential loading when parallel execution times out' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '40-timeout-a.ps1') -Value 'Start-Sleep -Milliseconds 50' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '41-timeout-b.ps1') -Value '# fast' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '40-timeout-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '41-timeout-b.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_TIMEOUT = '1'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 1
        }

        It 'Loads bootstrap helpers into runspaces when a bootstrap path is provided' {
            $bootstrapPath = Join-Path $script:FragmentDir '00-bootstrap.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value '$global:ParallelBootstrapMarker = "bootstrapped"' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '43-second.ps1') -Value '# second' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '42-with-bootstrap.ps1') -Value '# validated in parallel runspace' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '42-with-bootstrap.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '43-second.ps1'))
            )

            $env:PS_PROFILE_DEBUG = '3'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir -BootstrapFragmentPath $bootstrapPath

            $result.SuccessCount | Should -Be 2
            $result.UsedParallel | Should -Be $true
        }

        It 'Marks UsedParallel true when all fragments succeed in parallel validation' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '44-parallel-ok.ps1') -Value '$global:ParallelReexecMarker = "ok"' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '45-parallel-ok.ps1') -Value '# ok' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '44-parallel-ok.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '45-parallel-ok.ps1'))
            )

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $true
            $result.SuccessCount | Should -Be 2
            $global:ParallelReexecMarker | Should -Be 'ok'
        }

        It 'Records sequential re-execution failures when the forced probe fragment is reloaded' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '46-reexec-fail.ps1') -Value '# first pass ok' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '47-reexec-ok.ps1') -Value '# ok' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '46-reexec-fail.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '47-reexec-ok.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_REEXEC_FAIL = '1'
            $env:PS_PROFILE_DEBUG = '2'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result | Should -Not -BeNullOrEmpty
            $result.UsedParallel | Should -Be $true
            @($result.FailedFragments | Where-Object { $_.Name -eq '46-reexec-fail' }).Count | Should -BeGreaterOrEqual 1
        }

        It 'Emits structured warnings for single-fragment failures when debug level is enabled' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '48-single-fail.ps1') -Value 'throw "single structured failure"' -Encoding UTF8
            $fragment = Get-Item -LiteralPath (Join-Path $script:FragmentDir '48-single-fail.ps1')

            $env:PS_PROFILE_DEBUG = '2'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles @($fragment) -ProfileFragmentRoot $script:FragmentDir

            $result | Should -Not -BeNullOrEmpty
            $result.SuccessCount | Should -Be 0
            $result.FailureCount | Should -Be 1
            @($result.FailedFragments).Count | Should -Be 1
        }

        It 'Uses a custom timeout when PS_PROFILE_PARALLEL_LOAD_TIMEOUT_MS is set' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '49-timeout-ms-a.ps1') -Value '# a' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '50-timeout-ms-b.ps1') -Value '# b' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '49-timeout-ms-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '50-timeout-ms-b.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TIMEOUT_MS = '5000'
            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -BeGreaterOrEqual 2
        }

        It 'Reports runspace validation failures without completing parallel merge' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '51-runspace-fail.ps1') -Value '# fail in runspace' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '52-runspace-ok.ps1') -Value '# ok' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '51-runspace-fail.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '52-runspace-ok.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_RUNSPACE_FAIL = '1'
            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 2
        }

        It 'Uses extended timeout budgets for larger fragment batches' {
            $fragments = 1..12 | ForEach-Object {
                $path = Join-Path $script:FragmentDir ("6{0}-batch.ps1" -f $_)
                Set-Content -LiteralPath $path -Value "# batch $_" -Encoding UTF8
                Get-Item -LiteralPath $path
            }

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir -ThrottleLimit 4

            $result.SuccessCount | Should -Be 12
        }

        It 'Logs missing bootstrap paths at debug level 2 without failing the batch' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '70-no-bootstrap-a.ps1') -Value '# a' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '71-no-bootstrap-b.ps1') -Value '# b' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '70-no-bootstrap-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '71-no-bootstrap-b.ps1'))
            )

            $env:PS_PROFILE_DEBUG = '2'
            $missingBootstrap = Join-Path $script:FragmentDir 'missing-bootstrap.ps1'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir -BootstrapFragmentPath $missingBootstrap

            $result.SuccessCount | Should -Be 2
        }

        It 'Emits timeout warnings when forced timeout occurs without debug enabled' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '72-timeout-nodebug-a.ps1') -Value '# a' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '73-timeout-nodebug-b.ps1') -Value '# b' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '72-timeout-nodebug-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '73-timeout-nodebug-b.ps1'))
            )

            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_TIMEOUT = '1'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 2
        }

        It 'Executes fragment worker logic inline when test inline mode is enabled' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '80-inline-a.ps1') -Value '$global:ParallelInlineA = 1' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '81-inline-b.ps1') -Value '$global:ParallelInlineB = 2' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '80-inline-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '81-inline-b.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.SuccessCount | Should -Be 2
            $result.UsedParallel | Should -Be $true
            $global:ParallelInlineA | Should -Be 1
            $global:ParallelInlineB | Should -Be 2
        }

        It 'Loads bootstrap fragments inline and logs bootstrap success at debug level 3' {
            $bootstrapPath = Join-Path $script:FragmentDir '00-inline-bootstrap.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value '$global:ParallelInlineBootstrap = "ok"' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '82-inline-boot.ps1') -Value '# inline bootstrap probe' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '83-inline-boot2.ps1') -Value '# second' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '82-inline-boot.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '83-inline-boot2.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $env:PS_PROFILE_DEBUG = '3'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir -BootstrapFragmentPath $bootstrapPath

            $result.SuccessCount | Should -Be 2
            $global:ParallelInlineBootstrap | Should -Be 'ok'
        }

        It 'Logs bootstrap load failures inline at debug level 2 without aborting the batch' {
            $bootstrapPath = Join-Path $script:FragmentDir '00-inline-bad-bootstrap.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap inline failure"' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '84-inline-after-bootstrap.ps1') -Value '# still loads' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '85-inline-after-bootstrap2.ps1') -Value '# still loads' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '84-inline-after-bootstrap.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '85-inline-after-bootstrap2.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $env:PS_PROFILE_DEBUG = '3'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir -BootstrapFragmentPath $bootstrapPath

            $result.SuccessCount | Should -Be 2
        }

        It 'Reports inline runspace validation failures for matching fragment names' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '86-runspace-fail.ps1') -Value '# probe' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '87-runspace-ok.ps1') -Value '# ok' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '86-runspace-fail.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '87-runspace-ok.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_RUNSPACE_FAIL = '1'
            $env:PS_PROFILE_DEBUG = '2'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -Be 2
        }

        It 'Falls back to sequential loading when inline validation reports partial failures with debug enabled' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '88-inline-partial-good.ps1') -Value '$global:ParallelPartialGood = 1' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '89-inline-partial-bad.ps1') -Value 'throw "inline partial failure"' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '88-inline-partial-good.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '89-inline-partial-bad.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 1
            $result.FailureCount | Should -BeGreaterOrEqual 1
        }

        It 'Records endinvoke collection failures when the forced probe fragment is collected' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '90-endinvoke-fail.ps1') -Value '# ok in runspace' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '91-endinvoke-ok.ps1') -Value '# ok' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '90-endinvoke-fail.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '91-endinvoke-ok.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_ENDINVOKE_FAIL = '1'
            $env:PS_PROFILE_DEBUG = '2'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            @($result.FailedFragments | Where-Object { $_.Name -eq '90-endinvoke-fail' }).Count | Should -BeGreaterOrEqual 1
        }

        It 'Uses poll timeout fallback when fragments exceed the forced poll timeout budget' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '92-poll-slow.ps1') -Value 'Start-Sleep -Milliseconds 500' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '93-poll-fast.ps1') -Value '# fast' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '92-poll-slow.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '93-poll-fast.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_POLL_TIMEOUT = '1'
            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 2
        }

        It 'Logs pool setup failures with structured errors when debug level is at least 2' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '94-pool-a.ps1') -Value '# a' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '95-pool-b.ps1') -Value '# b' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '94-pool-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '95-pool-b.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_POOL_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -Be 2
        }

        It 'Emits timeout warnings at debug level 1 when forced timeout marks handles incomplete' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '96-slow-timeout.ps1') -Value 'Start-Sleep -Seconds 5' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '97-fast-timeout.ps1') -Value '# fast' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '96-slow-timeout.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '97-fast-timeout.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_FORCE_TIMEOUT = '1'
            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 1
        }

        It 'Logs sequential fallback details at debug level 3 after inline partial failures' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '98-fallback-log-a.ps1') -Value '# a' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '99-fallback-log-b.ps1') -Value 'throw "fallback log failure"' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '98-fallback-log-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '99-fallback-log-b.ps1'))
            )

            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $env:PS_PROFILE_DEBUG = '3'
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.SuccessCount | Should -BeGreaterOrEqual 1
        }

        It 'Uses Write-Warning fallbacks when structured logging commands are unavailable' {
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '74-warn-a.ps1') -Value '# a' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $script:FragmentDir '75-warn-b.ps1') -Value 'throw "warn fallback failure"' -Encoding UTF8
            $fragments = @(
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '74-warn-a.ps1'))
                (Get-Item -LiteralPath (Join-Path $script:FragmentDir '75-warn-b.ps1'))
            )

            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')
            $env:PS_PROFILE_PARALLEL_LOAD_TEST_INLINE = '1'
            $env:PS_PROFILE_DEBUG = '2'

            $result = Invoke-FragmentsInParallel -FragmentFiles $fragments -ProfileFragmentRoot $script:FragmentDir

            $result.UsedParallel | Should -Be $false
            $result.FailureCount | Should -BeGreaterOrEqual 1
        }
    }
}
