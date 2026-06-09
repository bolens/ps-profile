# ===============================================
# profile-utilities-ensure-extended.tests.ps1
# Execution tests for utilities.ps1 Ensure-Utilities deferred loading behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
}

function script:Reset-UtilitiesEnsureState {
    Set-Variable -Name 'UtilitiesInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/utilities.ps1 Ensure-Utilities extended scenarios' {
    BeforeEach {
        Reset-UtilitiesEnsureState
    }

    It 'Registers Ensure-Utilities before utility modules are loaded' {
        . (Join-Path $script:ProfileDir 'utilities.ps1')

        Get-Command Ensure-Utilities -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:UtilitiesInitialized | Should -Be $false
    }

    It 'Ensure-Utilities loads registry-backed utility modules and marks initialization complete' {
        . (Join-Path $script:ProfileDir 'utilities.ps1')

        Ensure-Utilities

        $global:UtilitiesInitialized | Should -Be $true
        Get-Command ConvertTo-UrlEncoded -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-EnvVar -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Ensure-Utilities is idempotent on repeated calls' {
        . (Join-Path $script:ProfileDir 'utilities.ps1')

        Ensure-Utilities
        $firstConvert = Get-Command ConvertTo-UrlEncoded -ErrorAction Stop

        Ensure-Utilities

        $global:UtilitiesInitialized | Should -Be $true
        (Get-Command ConvertTo-UrlEncoded -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstConvert.ScriptBlock.ToString()
    }
}
