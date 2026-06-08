<#
tests/unit/library-profile-fragment-loader.tests.ps1

.SYNOPSIS
    Unit tests for ProfileFragmentLoader module reload helper.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:LoaderPath = Join-Path $PSScriptRoot '../../scripts/lib/profile/ProfileFragmentLoader.psm1'
    Import-Module $script:LoaderPath -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentLoaderTests'
    $script:ModuleFile = Join-Path $script:TempDir 'SampleModule.psm1'
    $script:ModuleName = 'SampleModule'

    Set-Content -LiteralPath $script:ModuleFile -Value @'
function Get-SampleModuleValue {
    return 'v1'
}
Export-ModuleMember -Function Get-SampleModuleValue
'@ -Encoding UTF8

    if (-not (Get-Variable -Name PSProfileModuleFileTimes -Scope Global -ErrorAction SilentlyContinue)) {
        $global:PSProfileModuleFileTimes = @{}
    }
}

AfterAll {
    Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
    Remove-Module -Name ProfileFragmentLoader -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileFragmentLoader helpers' {
    Context 'Test-AndReloadModuleIfChanged' {
        BeforeEach {
            Clear-TestStartProcessCapture
        }

        AfterEach {
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }

        It 'Returns false for missing module paths' {
            $global:TestReloadModulePath = Join-Path $script:TempDir 'missing.psm1'

            try {
                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged -ModulePath $global:TestReloadModulePath -ModuleName 'MissingModule' |
                        Should -Be $false
                }
            }
            finally {
                Remove-Variable -Name TestReloadModulePath -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Caches write time on first inspection without forcing reload' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
                Import-Module -Name $script:ModuleFile -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false
                    $global:PSProfileModuleFileTimes.ContainsKey($global:TestReloadModulePath) | Should -Be $true
                }
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Detects file changes and removes loaded module' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
                Import-Module -Name $script:ModuleFile -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    $null = Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName
                }

                Set-Content -LiteralPath $script:ModuleFile -Value @'
function Get-SampleModuleValue {
    return 'v2'
}
Export-ModuleMember -Function Get-SampleModuleValue
'@ -Encoding UTF8
                Start-Sleep -Milliseconds 50

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $true
                    Get-Module -Name $global:TestReloadModuleName | Should -BeNullOrEmpty
                }
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }
}
