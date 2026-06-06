

<#
.SYNOPSIS
    Integration tests for Data rate unit conversion utilities.

.DESCRIPTION
    This test suite validates Data rate / bandwidth conversion functions.

.NOTES
    Tests cover decimal and binary multipliers.
#>

Describe 'Data Rate Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Data Rate Conversions' {
        It 'Convert-DataRate function exists' {
            Get-Command Convert-DataRate -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-DataRate converts Mbps to Kbps' {
            $result = Convert-DataRate -Value 10 -FromUnit 'mbps' -ToUnit 'kbps'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 10000
        }

        It 'Convert-DataRate converts MB/s to Mbps' {
            $result = Convert-DataRate -Value 1 -FromUnit 'mb/s' -ToUnit 'mbps'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 8
        }

        It 'Convert-DataRate supports binary mode' {
            $result = Convert-DataRate -Value 1024 -FromUnit 'kbps' -ToUnit 'mbps' -UseBinary
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.IsBinary | Should -Be $true
        }

        It 'Convert-DataRate supports pipeline input' {
            $result = 8000 | Convert-DataRate -FromUnit 'kbps' -ToUnit 'mbps'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 8
        }

        It 'Convert-DataRate roundtrip conversion' {
            $original = 100
            $converted = Convert-DataRate -Value $original -FromUnit 'mbps' -ToUnit 'kbps'
            $back = Convert-DataRate -Value $converted.Value -FromUnit 'kbps' -ToUnit 'mbps'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-DataRate throws error for invalid unit' {
            { Convert-DataRate -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'mbps' } | Should -Throw
        }
    }
}
