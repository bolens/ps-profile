# ===============================================
# profile-files-ensure-conversion-media-extended.tests.ps1
# Execution tests for files.ps1 Ensure-FileConversion-Media behavior
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
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileConversionMediaState {
    Set-Variable -Name FileConversionMediaInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files.ps1 Ensure-FileConversion-Media extended scenarios' {
    BeforeEach {
        Reset-FileConversionMediaState
    }

    It 'Registers media conversion helpers through Ensure-FileConversion-Media' {
        Ensure-FileConversion-Media

        Get-Command Convert-Color -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Parse-Color -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Merge-Pdf -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:FileConversionMediaInitialized | Should -Be $true
    }

    It 'Convert-Color transforms named colors after Ensure-FileConversion-Media' {
        Ensure-FileConversion-Media

        $result = Convert-Color -Color 'red' -ToFormat 'hex'
        $result | Should -Match '#'
    }

    It 'Skips re-initialization when media conversion is already loaded' {
        Ensure-FileConversion-Media
        $firstColor = Get-Command Convert-Color -ErrorAction Stop

        Ensure-FileConversion-Media

        (Get-Command Convert-Color -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstColor.ScriptBlock.ToString()
    }
}
