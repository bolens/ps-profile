<#
tests/unit/profile-module-loading-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ModuleLoading path validation helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'

    $modulePathCachePath = Join-Path $script:BootstrapDir 'ModulePathCache.ps1'
    if (Test-Path -LiteralPath $modulePathCachePath) {
        . $modulePathCachePath
    }

    $moduleLoadingPath = Join-Path $script:BootstrapDir 'ModuleLoading.ps1'
    . $moduleLoadingPath

    $script:TestFragmentRoot = New-TestTempDirectory -Prefix 'ModuleLoadingExtended'
    $script:TestModulesDir = Join-Path $script:TestFragmentRoot 'modules'
    $script:NestedDir = Join-Path $script:TestModulesDir 'nested'
    New-Item -ItemType Directory -Path $script:NestedDir -Force | Out-Null

    $script:ValidModulePath = Join-Path $script:NestedDir 'helper.ps1'
    Set-Content -LiteralPath $script:ValidModulePath -Value @'
function global:Get-ExtendedModuleValue {
    return 'extended'
}
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

Describe 'ModuleLoading extended scenarios' {
    Context 'Test-FragmentModulePath' {
        It 'Returns true for existing module paths supplied as a single path' {
            Test-FragmentModulePath -Path $script:ValidModulePath | Should -Be $true
        }

        It 'Returns false for missing module paths supplied as a single path' {
            $missingPath = Join-Path $script:TestFragmentRoot 'missing-module.ps1'
            Test-FragmentModulePath -Path $missingPath | Should -Be $false
        }

        It 'Validates nested module segments under a fragment root' {
            Test-FragmentModulePath `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('modules', 'nested', 'helper.ps1') | Should -Be $true
        }

        It 'Returns false when an intermediate directory segment is missing' {
            Test-FragmentModulePath `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('modules', 'missing-dir', 'helper.ps1') | Should -Be $false
        }
    }

    Context 'Invoke-GlobalProfileScript' {
        It 'Dot-sources an existing script and promotes new functions to global scope' {
            $scriptFile = Join-Path $script:TestFragmentRoot 'define-function.ps1'
            Set-Content -LiteralPath $scriptFile -Value @'
function Get-ExtendedScriptFunction {
    return 'script-output'
}
'@ -Encoding UTF8

            { Invoke-GlobalProfileScript -Path $scriptFile } | Should -Not -Throw
            Get-ExtendedScriptFunction | Should -Be 'script-output'
        }
    }
}
