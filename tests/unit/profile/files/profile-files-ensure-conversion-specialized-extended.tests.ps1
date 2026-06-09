# ===============================================
# profile-files-ensure-conversion-specialized-extended.tests.ps1
# Execution tests for files.ps1 Ensure-FileConversion-Specialized behavior
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

function script:Reset-FileConversionSpecializedState {
    Set-Variable -Name FileConversionSpecializedInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files.ps1 Ensure-FileConversion-Specialized extended scenarios' {
    BeforeEach {
        Reset-FileConversionSpecializedState
    }

    It 'Registers specialized conversion helpers through Ensure-FileConversion-Specialized' {
        Ensure-FileConversion-Specialized

        Get-Command ConvertTo-QrCodeFromText -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-JwtFromJson -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-BarcodeFromText -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:FileConversionSpecializedInitialized | Should -Be $true
    }

    It 'Delegates initialization to Initialize-FileConversion-Specialized loader' {
        Ensure-FileConversion-Specialized

        Get-Command Initialize-FileConversion-SpecializedQrCode -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-SpecializedJwt -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-SpecializedBarcode -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips re-initialization when specialized conversion is already loaded' {
        Ensure-FileConversion-Specialized
        $firstQr = Get-Command ConvertTo-QrCodeFromText -ErrorAction Stop

        Ensure-FileConversion-Specialized

        (Get-Command ConvertTo-QrCodeFromText -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstQr.ScriptBlock.ToString()
    }
}
