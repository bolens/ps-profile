<#
tests/unit/profile-import-fragment-module-required-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-FragmentModule required loading behavior.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    $modulePathCachePath = Join-Path $bootstrapDir 'ModulePathCache.ps1'
    if (Test-Path -LiteralPath $modulePathCachePath) {
        . $modulePathCachePath
    }

    . (Join-Path $bootstrapDir 'ModuleLoading.ps1')

    $script:TestFragmentRoot = New-TestTempDirectory -Prefix 'ImportFragmentRequiredExtended'
    $script:ModulesDir = Join-Path $script:TestFragmentRoot 'modules'
    New-Item -ItemType Directory -Path $script:ModulesDir -Force | Out-Null
    $script:ValidModule = Join-Path $script:ModulesDir 'required-module.ps1'
    Set-Content -LiteralPath $script:ValidModule -Value @'
function global:Get-RequiredModuleValue { 'required' }
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

Describe 'Import-FragmentModule required extended scenarios' {
    Context 'Import-FragmentModule' {
        It 'Throws when a required module file is missing' {
            {
                Import-FragmentModule `
                    -FragmentRoot $script:TestFragmentRoot `
                    -ModulePath @('modules', 'missing-required.ps1') `
                    -Context 'Required missing module' `
                    -Required
            } | Should -Throw '*Module file not found*'
        }

        It 'Throws when FragmentRoot is blank for a required import' {
            {
                Import-FragmentModule `
                    -FragmentRoot '   ' `
                    -ModulePath @('modules', 'required-module.ps1') `
                    -Context 'Required blank root' `
                    -Required
            } | Should -Throw '*FragmentRoot cannot be null or empty*'
        }

        It 'Loads a required module successfully when the file exists' {
            Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('modules', 'required-module.ps1') `
                -Context 'Required existing module' `
                -Required | Should -Be $true

            Get-RequiredModuleValue | Should -Be 'required'
        }

        It 'Returns false without throwing when FragmentRoot is blank for optional imports' {
            Import-FragmentModule `
                -FragmentRoot '   ' `
                -ModulePath @('modules', 'required-module.ps1') `
                -Context 'Optional blank root' | Should -Be $false
        }

        It 'Returns false when a module path segment is blank for optional imports' {
            Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('modules', '   ', 'required-module.ps1') `
                -Context 'Optional blank segment' | Should -Be $false
        }
    }
}
