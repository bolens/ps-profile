<#
tests/unit/profile-module-loading-bootstrap-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-GlobalProfileScript bootstrap behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    $modulePathCachePath = Join-Path $script:BootstrapDir 'ModulePathCache.ps1'
    if (Test-Path -LiteralPath $modulePathCachePath) {
        . $modulePathCachePath
    }

    . (Join-Path $script:BootstrapDir 'ModuleLoading.ps1')

    $script:TestFragmentRoot = New-TestTempDirectory -Prefix 'ModuleLoadingBootstrapExtended'
}

AfterAll {
    if (Get-Command Clear-ModulePathCache -ErrorAction SilentlyContinue) {
        Clear-ModulePathCache | Out-Null
    }
}

Describe 'ModuleLoading bootstrap extended scenarios' {
    Context 'Invoke-GlobalProfileScript' {
        It 'Throws when the script path does not exist' {
            $missingPath = Join-Path $script:TestFragmentRoot 'missing-script.ps1'
            { Invoke-GlobalProfileScript -Path $missingPath } | Should -Throw
        }

        It 'Promotes newly defined functions to the global scope' {
            $scriptFile = Join-Path $script:TestFragmentRoot 'promote-function.ps1'
            Set-Content -LiteralPath $scriptFile -Value @'
function Get-BootstrapExtendedFunction {
    return 'promoted'
}
'@ -Encoding UTF8

            Invoke-GlobalProfileScript -Path $scriptFile | Out-Null
            Get-BootstrapExtendedFunction | Should -Be 'promoted'
        }

        It 'Does not overwrite functions that already exist in global scope' {
            function global:BootstrapExtendedGuard { 'original' }

            $scriptFile = Join-Path $script:TestFragmentRoot 'overwrite-guard.ps1'
            Set-Content -LiteralPath $scriptFile -Value @'
function BootstrapExtendedGuard {
    return 'replacement'
}
'@ -Encoding UTF8

            Invoke-GlobalProfileScript -Path $scriptFile | Out-Null
            BootstrapExtendedGuard | Should -Be 'original'
        }

        It 'Promotes aliases defined by the sourced script' {
            $scriptFile = Join-Path $script:TestFragmentRoot 'promote-alias.ps1'
            Set-Content -LiteralPath $scriptFile -Value @'
function Get-BootstrapExtendedAliasTarget {
    return 'alias-target'
}
Set-Alias -Name bea -Value Get-BootstrapExtendedAliasTarget
'@ -Encoding UTF8

            Invoke-GlobalProfileScript -Path $scriptFile | Out-Null
            bea | Should -Be 'alias-target'
        }
    }

    Context 'Import-FragmentModule path validation' {
        It 'Returns false when a module path segment is whitespace' {
            Import-FragmentModule `
                -FragmentRoot $script:TestFragmentRoot `
                -ModulePath @('modules', '   ', 'helper.ps1') `
                -Context 'Bootstrap whitespace segment' | Should -Be $false
        }
    }
}
