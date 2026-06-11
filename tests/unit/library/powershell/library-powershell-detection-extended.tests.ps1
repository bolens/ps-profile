<#
tests/unit/library-powershell-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-PowerShellExecutable consistency and exports.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'runtime' 'PowerShellDetection.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module PowerShellDetection -ErrorAction SilentlyContinue -Force
}

Describe 'PowerShellDetection extended scenarios' {
    Context 'Get-PowerShellExecutable' {
        It 'Returns the same executable on repeated calls' {
            $first = Get-PowerShellExecutable
            $second = Get-PowerShellExecutable

            $second | Should -Be $first
        }

        It 'Matches the current session PSEdition' {
            $result = Get-PowerShellExecutable

            if ($PSVersionTable.PSEdition -eq 'Core') {
                $result | Should -Be 'pwsh'
            }
            else {
                $result | Should -Be 'powershell'
            }
        }

        It 'Exports only Get-PowerShellExecutable from the module' {
            $module = Get-Module PowerShellDetection
            @($module.ExportedFunctions.Keys) | Should -Be @('Get-PowerShellExecutable')
        }

        It 'Returns a non-empty executable name without file path separators' {
            $result = Get-PowerShellExecutable

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Not -Match '[\\/]'
        }

        It 'Returns pwsh when PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION requests core' {
            $original = $env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION
            try {
                $env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION = 'core'
                Get-PowerShellExecutable | Should -Be 'pwsh'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION = $original
                }
            }
        }

        It 'Returns powershell when PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION requests desktop' {
            $original = $env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION
            try {
                $env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION = 'desktop'
                Get-PowerShellExecutable | Should -Be 'powershell'
            }
            finally {
                if ($null -eq $original) {
                    Remove-Item Env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION = $original
                }
            }
        }
    }
}
