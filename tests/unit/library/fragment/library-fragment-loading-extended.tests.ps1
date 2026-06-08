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
    }
}
