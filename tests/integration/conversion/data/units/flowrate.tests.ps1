

<#
.SYNOPSIS
    Integration tests for Flow rate unit conversion utilities.

.DESCRIPTION
    This test suite validates Flow rate unit conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Flow Rate Unit Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Flow Rate Conversions' {
        It 'Convert-FlowRate function exists' {
            Get-Command Convert-FlowRate -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-FlowRate converts L/min to L/s' {
            $result = Convert-FlowRate -Value 60 -FromUnit 'l/min' -ToUnit 'l/s'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.0001
        }

        It 'Convert-FlowRate converts gpm to L/min' {
            $result = Convert-FlowRate -Value 1 -FromUnit 'gpm' -ToUnit 'l/min'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 3.78541) | Should -BeLessThan 0.01
        }

        It 'Convert-FlowRate supports pipeline input' {
            $result = 60 | Convert-FlowRate -FromUnit 'l/min' -ToUnit 'l/s'
            $result | Should -Not -BeNullOrEmpty
            [math]::Abs($result.Value - 1) | Should -BeLessThan 0.0001
        }

        It 'Convert-FlowRate roundtrip conversion' {
            $original = 10
            $converted = Convert-FlowRate -Value $original -FromUnit 'gpm' -ToUnit 'l/min'
            $back = Convert-FlowRate -Value $converted.Value -FromUnit 'l/min' -ToUnit 'gpm'
            [math]::Abs($back.Value - $original) | Should -BeLessThan 0.001
        }

        It 'Convert-FlowRate throws error for invalid unit' {
            { Convert-FlowRate -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'l/s' } | Should -Throw
        }
    }
}
