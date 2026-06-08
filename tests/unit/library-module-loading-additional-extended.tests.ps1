<#
tests/unit/library-module-loading-additional-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-FragmentModules batch loading helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    $modulePathCachePath = Join-Path $script:BootstrapDir 'ModulePathCache.ps1'
    if (Test-Path -LiteralPath $modulePathCachePath) {
        . $modulePathCachePath
    }

    . (Join-Path $script:BootstrapDir 'ModuleLoading.ps1')

    $script:TestFragmentRoot = New-TestTempDirectory -Prefix 'ModuleLoadingAdditionalExtended'
    $script:TestModulesDir = Join-Path $script:TestFragmentRoot 'batch-modules'
    New-Item -ItemType Directory -Path $script:TestModulesDir -Force | Out-Null

    $script:ModuleOne = Join-Path $script:TestModulesDir 'module-one.ps1'
    $script:ModuleTwo = Join-Path $script:TestModulesDir 'module-two.ps1'
    Set-Content -LiteralPath $script:ModuleOne -Value @'
function global:Get-ModuleOneValue { 'one' }
'@ -Encoding UTF8
    Set-Content -LiteralPath $script:ModuleTwo -Value @'
function global:Get-ModuleTwoValue { 'two' }
'@ -Encoding UTF8
}

AfterAll {
    if ($script:TestFragmentRoot -and (Test-Path -LiteralPath $script:TestFragmentRoot)) {
        Remove-Item -LiteralPath $script:TestFragmentRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Get-Command Clear-ModulePathCache -ErrorAction SilentlyContinue) {
        Clear-ModulePathCache | Out-Null
    }
}

Describe 'ModuleLoading additional extended scenarios' {
    Context 'Import-FragmentModules' {
        It 'Loads multiple module paths from a single invocation' {
            $modules = @(
                @{
                    ModulePath = @('batch-modules', 'module-one.ps1')
                    Context    = 'Extended batch one'
                }
                @{
                    ModulePath = @('batch-modules', 'module-two.ps1')
                    Context    = 'Extended batch two'
                }
            )

            $result = Import-FragmentModules `
                -FragmentRoot $script:TestFragmentRoot `
                -Modules $modules

            $result.SuccessCount | Should -Be 2
            $result.FailureCount | Should -Be 0
            Get-ModuleOneValue | Should -Be 'one'
            Get-ModuleTwoValue | Should -Be 'two'
        }

        It 'Rejects an empty Modules array at parameter binding time' {
            { Import-FragmentModules `
                    -FragmentRoot $script:TestFragmentRoot `
                    -Modules @() } | Should -Throw
        }
    }

    Context 'Import-FragmentModule optional loading' {
        It 'Returns false without throwing when a non-required module is missing' {
            Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('batch-modules', 'missing-module.ps1') `
                -Context 'Extended optional missing' | Should -Be $false
        }

        It 'Loads nested module paths under subdirectories' {
            $nestedDir = Join-Path $script:TestModulesDir 'nested'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            $nestedModule = Join-Path $nestedDir 'nested-module.ps1'
            Set-Content -LiteralPath $nestedModule -Value 'function global:Get-NestedModuleValue { "nested" }' -Encoding UTF8

            Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('batch-modules', 'nested', 'nested-module.ps1') `
                -Context 'Extended nested module' | Should -Be $true

            Get-NestedModuleValue | Should -Be 'nested'
        }
    }

    Context 'Test-FragmentModulePath segment validation' {
        It 'Returns false when a direct path argument points to a missing file' {
            $missingPath = Join-Path $script:TestFragmentRoot 'batch-modules\missing-module.ps1'
            Test-FragmentModulePath -Path $missingPath | Should -Be $false
        }
    }
}
