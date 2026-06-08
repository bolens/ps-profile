<#
tests/unit/library-fragment-loading-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentLoading dependency validation helpers.
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
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue

    $fileContentModulePath = Get-TestPath -RelativePath 'scripts\lib\file\FileContent.psm1' -StartPath $PSScriptRoot -ErrorAction SilentlyContinue
    if ($fileContentModulePath -and (Test-Path -LiteralPath $fileContentModulePath)) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    $fragmentLoadingPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentLoading.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentLoadingPath -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentLoadingExtended'
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

AfterAll {
    Remove-Module FragmentLoading -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentLoading extended scenarios' {
    Context 'Get-FragmentDependencies' {
        It 'Ignores duplicate dependency declarations' {
            $fragmentPath = Join-Path $script:TempDir 'dup-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value @'
#Requires -Fragment 'bootstrap'
#Requires -Fragment 'bootstrap'
# Dependencies: env, env
'@ -Encoding UTF8

            $deps = Get-FragmentDependencies -FragmentFile $fragmentPath
            @($deps | Where-Object { $_ -eq 'bootstrap' }).Count | Should -Be 1
            @($deps | Where-Object { $_ -eq 'env' }).Count | Should -Be 1
        }

        It 'Trims whitespace from Dependencies comment entries' {
            $fragmentPath = Join-Path $script:TempDir 'trimmed-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value @'
# Dependencies:  bootstrap , env , utilities
'@ -Encoding UTF8

            $deps = Get-FragmentDependencies -FragmentFile $fragmentPath
            $deps | Should -Contain 'bootstrap'
            $deps | Should -Contain 'env'
            $deps | Should -Contain 'utilities'
        }
    }

    Context 'Test-FragmentDependencies' {
        It 'Reports a valid dependency graph when all requirements are satisfied' {
            $basePath = Join-Path $script:TempDir '10-valid-base.ps1'
            $childPath = Join-Path $script:TempDir '20-valid-child.ps1'
            Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
            Set-Content -LiteralPath $childPath -Value '# Dependencies: 10-valid-base' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $basePath)
                (Get-Item -LiteralPath $childPath)
            )

            $result = Test-FragmentDependencies -FragmentFiles $fragments
            $result.Valid | Should -Be $true
            $result.HasIssues() | Should -Be $false
        }

        It 'Reports missing dependencies that are not present in the fragment set' {
            $missingPath = Join-Path $script:TempDir '10-needs-missing.ps1'
            Set-Content -LiteralPath $missingPath -Value @'
#Requires -Fragment 'missing-target'
'@ -Encoding UTF8

            $fragments = @(Get-Item -LiteralPath $missingPath)
            $result = Test-FragmentDependencies -FragmentFiles $fragments

            $result.Valid | Should -Be $false
            $result.MissingDependencies | Should -Not -BeNullOrEmpty
        }

        It 'Detects circular dependency chains' {
            $pathA = Join-Path $script:TempDir '10-cycle-a.ps1'
            $pathB = Join-Path $script:TempDir '20-cycle-b.ps1'
            Set-Content -LiteralPath $pathA -Value "#Requires -Fragment '20-cycle-b'" -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value "#Requires -Fragment '10-cycle-a'" -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
            )

            $result = Test-FragmentDependencies -FragmentFiles $fragments

            $result.Valid | Should -Be $false
            $result.CircularDependencies | Should -Not -BeNullOrEmpty
        }

        It 'Reports dependencies that are present but disabled' {
            $basePath = Join-Path $script:TempDir '10-disabled-dep-base.ps1'
            $disabledPath = Join-Path $script:TempDir '20-disabled-dep-target.ps1'
            $childPath = Join-Path $script:TempDir '30-disabled-dep-child.ps1'
            Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
            Set-Content -LiteralPath $disabledPath -Value '# disabled target' -Encoding UTF8
            Set-Content -LiteralPath $childPath -Value "# Dependencies: 20-disabled-dep-target" -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $basePath)
                (Get-Item -LiteralPath $disabledPath)
                (Get-Item -LiteralPath $childPath)
            )

            $result = Test-FragmentDependencies -FragmentFiles $fragments -DisabledFragments @('20-disabled-dep-target')

            $result.Valid | Should -Be $false
            @($result.MissingDependencies | Where-Object { $_ -match '\(disabled\)' }).Count |
                Should -BeGreaterThan 0
        }
    }

    Context 'Get-FragmentDependencyLevels' {
        It 'Groups independent fragments into the same dependency level' {
            $pathA = Join-Path $script:TempDir '10-independent-a.ps1'
            $pathB = Join-Path $script:TempDir '11-independent-b.ps1'
            Set-Content -LiteralPath $pathA -Value '# independent a' -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value '# independent b' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
            $levels.Keys | Should -Contain 'Level0'

            @($levels['Level0'] | ForEach-Object { $_.BaseName }) | Should -Contain '10-independent-a'
            @($levels['Level0'] | ForEach-Object { $_.BaseName }) | Should -Contain '11-independent-b'
        }

        It 'Places dependent fragments in later levels' {
            $pathBase = Join-Path $script:TempDir '20-level-base.ps1'
            $pathChild = Join-Path $script:TempDir '30-level-child.ps1'
            Set-Content -LiteralPath $pathBase -Value '# base fragment' -Encoding UTF8
            Set-Content -LiteralPath $pathChild -Value "#Requires -Fragment '20-level-base'" -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathChild)
                (Get-Item -LiteralPath $pathBase)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
            $levels.Keys | Should -Contain 'Level0'
            $levels.Keys | Should -Contain 'Level1'
            @($levels['Level0'] | ForEach-Object { $_.BaseName }) | Should -Contain '20-level-base'
            @($levels['Level1'] | ForEach-Object { $_.BaseName }) | Should -Contain '30-level-child'
        }

        It 'Excludes disabled fragments from dependency levels' {
            $pathA = Join-Path $script:TempDir '10-disabled-a.ps1'
            $pathB = Join-Path $script:TempDir '20-disabled-b.ps1'
            Set-Content -LiteralPath $pathA -Value '# disabled a' -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value '# disabled b' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments -DisabledFragments @('20-disabled-b')
            $allNames = @($levels.Values | ForEach-Object { $_ } | ForEach-Object { $_.BaseName })
            $allNames | Should -Contain '10-disabled-a'
            $allNames | Should -Not -Contain '20-disabled-b'
        }

        It 'Builds dependency levels through parallel parsing for larger fragment sets' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $basePath = Join-Path $script:TempDir '10-level-parallel-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "2$($_)-level-parallel.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-level-parallel-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments.ToArray()
                $levels.Keys | Should -Contain 'Level0'
                $levels.Keys | Should -Contain 'Level1'
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Uses parallel dependency parsing when enabled for larger fragment sets' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "1$($_)-parallel-parse.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments.ToArray()
                $levels.Keys.Count | Should -BeGreaterThan 0
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }
            }
        }
    }

    Context 'Get-FragmentDependencies cache and edge cases' {
        It 'Returns an empty array for a missing fragment path' {
            Get-FragmentDependencies -FragmentFile (Join-Path $script:TempDir 'missing-fragment.ps1') |
                Should -Be @()
        }

        It 'Reuses cached dependencies when the file has not changed' {
            $fragmentPath = Join-Path $script:TempDir 'cached-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value "#Requires -Fragment 'bootstrap'" -Encoding UTF8

            $first = Get-FragmentDependencies -FragmentFile $fragmentPath
            $second = Get-FragmentDependencies -FragmentFile $fragmentPath

            $first | Should -Contain 'bootstrap'
            $second | Should -Be $first
        }
    }

    Context 'Get-FragmentTier' {
        It 'Records tier parse failures through Write-StructuredWarning when debug is enabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $filePath = Join-Path $script:TempDir 'tier-parse-unreadable.ps1'
                Set-Content -LiteralPath $filePath -Value '# Tier: core' -Encoding UTF8

                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $filePath
                }

                Get-FragmentTier -FragmentFile $filePath | Should -Be 'optional'
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    $filePath = Join-Path $script:TempDir 'tier-parse-unreadable.ps1'
                    if (Test-Path -LiteralPath $filePath) {
                        chmod 644 $filePath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Reads explicit tier declarations from fragment content' {
            $path = Join-Path $script:TempDir '25-explicit-tier.ps1'
            Set-Content -LiteralPath $path -Value "# Tier: essential`n# fragment" -Encoding UTF8
            Get-FragmentTier -FragmentFile $path | Should -Be 'essential'
        }

        It 'Treats bootstrap fragments as core tier' {
            $path = Join-Path $script:TempDir 'bootstrap.ps1'
            Set-Content -LiteralPath $path -Value '# bootstrap' -Encoding UTF8
            Get-FragmentTier -FragmentFile $path | Should -Be 'core'
        }

        It 'Defaults missing files to optional tier' {
            Get-FragmentTier -FragmentFile (Join-Path $script:TempDir 'missing-tier.ps1') | Should -Be 'optional'
        }

        It 'Emits level 3 verbose tracing when tier parsing fails without structured logging' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            function global:Read-FileContent {
                param([string]$Path)
                throw 'tier parse verbose probe'
            }

            try {
                $filePath = Join-Path $script:TempDir 'tier-verbose-fail.ps1'
                Set-Content -LiteralPath $filePath -Value '# Tier: core' -Encoding UTF8
                Get-FragmentTier -FragmentFile $filePath | Should -Be 'optional'
            }
            finally {
                Remove-Item -Path Function:Read-FileContent -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Get-FragmentLoadOrder' {
        It 'Uses Write-StructuredWarning when parallel load-order parsing returns invalid results' {
            Enable-TestStructuredLogging
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "3$($_)-invalid-order.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                # Include a missing path in the parallel parser input via a deleted fragment entry
                $ghostPath = Join-Path $script:TempDir '39-ghost-order.ps1'
                Set-Content -LiteralPath $ghostPath -Value '# ghost' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $ghostPath))
                Remove-Item -LiteralPath $ghostPath -Force

                { Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray() } | Should -Not -Throw
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Uses parallel dependency parsing for larger fragment sets' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                $basePath = Join-Path $script:TempDir '10-parallel-order-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "2$($_)-parallel-order.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-parallel-order-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $order = Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray()
                @($order | ForEach-Object { $_.BaseName }) | Should -Contain '10-parallel-order-base'
                @($order | ForEach-Object { $_.BaseName }).Count | Should -Be 7
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Parses dependencies sequentially when parallel parsing is disabled' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '0'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $basePath = Join-Path $script:TempDir '10-seq-order-base.ps1'
                $childPath = Join-Path $script:TempDir '20-seq-order-child.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                Set-Content -LiteralPath $childPath -Value '# Dependencies: 10-seq-order-base' -Encoding UTF8

                $fragments = @(
                    (Get-Item -LiteralPath $childPath)
                    (Get-Item -LiteralPath $basePath)
                )

                $order = Get-FragmentLoadOrder -FragmentFiles $fragments
                [array]::IndexOf(@($order | ForEach-Object { $_.BaseName }), '10-seq-order-base') |
                    Should -BeLessThan ([array]::IndexOf(@($order | ForEach-Object { $_.BaseName }), '20-seq-order-child'))
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Omits disabled fragments from the computed load order' {
            $basePath = Join-Path $script:TempDir '10-order-base.ps1'
            $skipPath = Join-Path $script:TempDir '20-order-skip.ps1'
            Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
            Set-Content -LiteralPath $skipPath -Value '# skip' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $basePath)
                (Get-Item -LiteralPath $skipPath)
            )

            $order = Get-FragmentLoadOrder -FragmentFiles $fragments -DisabledFragments @('20-order-skip')
            @($order | ForEach-Object { $_.BaseName }) | Should -Contain '10-order-base'
            @($order | ForEach-Object { $_.BaseName }) | Should -Not -Contain '20-order-skip'
        }

        It 'Includes cyclic fragments in the remaining load-order bucket' {
            $pathA = Join-Path $script:TempDir '10-order-cycle-a.ps1'
            $pathB = Join-Path $script:TempDir '20-order-cycle-b.ps1'
            $pathC = Join-Path $script:TempDir '30-order-independent.ps1'
            Set-Content -LiteralPath $pathA -Value "#Requires -Fragment '20-order-cycle-b'" -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value "#Requires -Fragment '10-order-cycle-a'" -Encoding UTF8
            Set-Content -LiteralPath $pathC -Value '# independent' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
                (Get-Item -LiteralPath $pathC)
            )

            $order = Get-FragmentLoadOrder -FragmentFiles $fragments
            @($order | ForEach-Object { $_.BaseName }) | Should -Contain '30-order-independent'
            @($order | ForEach-Object { $_.BaseName }).Count | Should -Be 3
        }
    }

    Context 'Get-FragmentDependencies cache invalidation' {
        It 'Refreshes cached dependencies after the fragment file changes' {
            $fragmentPath = Join-Path $script:TempDir 'refresh-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8

            $first = Get-FragmentDependencies -FragmentFile $fragmentPath
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: env' -Encoding UTF8
            $second = Get-FragmentDependencies -FragmentFile $fragmentPath

            $first | Should -Contain 'bootstrap'
            $second | Should -Contain 'env'
            $second | Should -Not -Contain 'bootstrap'
        }
    }

    Context 'Get-FragmentTiers' {
        It 'Excludes bootstrap fragments when ExcludeBootstrap is specified' {
            $bootstrapPath = Join-Path $script:TempDir 'bootstrap.ps1'
            $corePath = Join-Path $script:TempDir '05-tier-core.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value '# bootstrap' -Encoding UTF8
            Set-Content -LiteralPath $corePath -Value '# core' -Encoding UTF8

            $tiers = Get-FragmentTiers -FragmentFiles @(
                (Get-Item -LiteralPath $bootstrapPath)
                (Get-Item -LiteralPath $corePath)
            ) -ExcludeBootstrap

            @($tiers.Tier0 | ForEach-Object { $_.BaseName }) | Should -Contain '05-tier-core'
            @($tiers.Tier0 | ForEach-Object { $_.BaseName }) | Should -Not -Contain 'bootstrap'
        }

        It 'Buckets fragments into tier lists by numeric prefix' {
            $corePath = Join-Path $script:TempDir '05-core-tier.ps1'
            $optionalPath = Join-Path $script:TempDir '75-optional-tier.ps1'
            Set-Content -LiteralPath $corePath -Value '# core' -Encoding UTF8
            Set-Content -LiteralPath $optionalPath -Value '# optional' -Encoding UTF8

            $coreFile = Get-Item -LiteralPath $corePath
            $optionalFile = Get-Item -LiteralPath $optionalPath
            $tiers = Get-FragmentTiers -FragmentFiles @($coreFile, $optionalFile)

            @($tiers.Tier0 | ForEach-Object { $_.BaseName }) | Should -Contain '05-core-tier'
            @($tiers.Tier3 | ForEach-Object { $_.BaseName }) | Should -Contain '75-optional-tier'
        }
    }
}
