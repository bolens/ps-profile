<#
tests/unit/library-profile-fragment-loader-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentLoader batch progress and reload helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LoaderPath = Join-Path $PSScriptRoot '../../scripts/lib/profile/ProfileFragmentLoader.psm1'
    Import-Module $script:LoaderPath -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentLoaderExtended'
    $script:ModuleFile = Join-Path $script:TempDir 'ReloadProbe.psm1'
    $script:ModuleName = 'ReloadProbe'

    Set-Content -LiteralPath $script:ModuleFile -Value @'
function Get-ReloadProbeValue {
    return 'initial'
}
Export-ModuleMember -Function Get-ReloadProbeValue
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

Describe 'ProfileFragmentLoader extended scenarios' {
    Context 'Test-AndReloadModuleIfChanged' {
        BeforeEach {
            $global:PSProfileModuleFileTimes = @{}
        }

        It 'Returns false when the module file exists but is not loaded yet' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false
                }

                Get-Module -Name $script:ModuleName | Should -BeNullOrEmpty
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Updates cached write time without forcing reload when content is unchanged' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
                Import-Module -Name $script:ModuleFile -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false

                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false
                }

                (Get-Module -Name $script:ModuleName).Name | Should -Be $script:ModuleName
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Write-BatchProgressRow' {
        BeforeEach {
            $global:BatchProgressOutput = [System.Collections.Generic.List[string]]::new()
        }

        It 'Calculates progress percentage from batch number and total batches' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                Mock Write-Host {
                    param([object]$Object)
                    $null = $global:BatchProgressOutput.Add([string]$Object)
                }

                Write-BatchProgressRow -BatchNumber 2 -TotalBatches 4 -FragmentCount 3 -FragmentNames @('a', 'b', 'c')
            }

            ($global:BatchProgressOutput | Select-Object -Last 1) | Should -Match '50%'
        }

        It 'Truncates fragment name lists longer than ten entries' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                Mock Write-Host {
                    param([object]$Object)
                    $null = $global:BatchProgressOutput.Add([string]$Object)
                }

                $names = 1..12 | ForEach-Object { "frag-$_" }
                Write-BatchProgressRow -BatchNumber 1 -TotalBatches 1 -FragmentCount 12 -FragmentNames $names
            }

            ($global:BatchProgressOutput | Select-Object -Last 1) | Should -Match '\(\+2 more\)'
        }
    }

    Context 'Write-BatchProgressTableHeader' {
        It 'Prints the table header only once per loader session' {
            $global:BatchProgressOutput = [System.Collections.Generic.List[string]]::new()

            InModuleScope -ModuleName ProfileFragmentLoader {
                Mock Write-Host {
                    param([object]$Object)
                    $null = $global:BatchProgressOutput.Add([string]$Object)
                }

                Write-BatchProgressTableHeader
                Write-BatchProgressTableHeader
            }

            @($global:BatchProgressOutput | Where-Object { $_ -match '^Batch\s+Fragments' }).Count | Should -Be 1
        }
    }
}
