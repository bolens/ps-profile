

<#
.SYNOPSIS
    Integration tests for Data Size unit conversion utilities.

.DESCRIPTION
    This test suite validates the Data Size unit conversion utilities:
    - Data Size conversions (Bytes, KB, MB, GB, TB, PB, EB)
    - Binary (1024-based) and decimal (1000-based) unit support
    - Conversions to/from bytes

.NOTES
    Tests cover both successful conversions, roundtrip scenarios, and edge cases.
#>

Describe 'Data Size Unit Conversion Utilities Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Data Size Conversions (Binary Units - Default)' {
        It 'Convert-DataSize converts KB to MB' {
            $result = Convert-DataSize -Value 1024 -FromUnit 'KB' -ToUnit 'MB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'MB'
            $result.OriginalValue | Should -Be 1024
            $result.OriginalUnit | Should -Be 'KB'
            $result.Bytes | Should -Be 1048576
            $result.IsDecimal | Should -Be $false
        }
        
        It 'Convert-DataSize converts GB to MB' {
            $result = Convert-DataSize -Value 1 -FromUnit 'GB' -ToUnit 'MB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'MB'
        }
        
        It 'Convert-DataSize converts MB to KB' {
            $result = Convert-DataSize -Value 1 -FromUnit 'MB' -ToUnit 'KB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'KB'
        }
        
        It 'Convert-DataSize converts TB to GB' {
            $result = Convert-DataSize -Value 1 -FromUnit 'TB' -ToUnit 'GB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'GB'
        }
        
        It 'Convert-DataSize handles fractional values' {
            $result = Convert-DataSize -Value 512 -FromUnit 'KB' -ToUnit 'MB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 0.5
            $result.Unit | Should -Be 'MB'
        }
        
        It 'Convert-DataSize supports pipeline input' {
            $result = 1024 | Convert-DataSize -FromUnit 'KB' -ToUnit 'MB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'MB'
        }
        
        It 'Convert-DataSize supports plural unit names' {
            $result = Convert-DataSize -Value 1 -FromUnit 'gigabytes' -ToUnit 'megabytes'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'megabytes'
        }
        
        It 'Convert-DataSize supports singular unit names' {
            $result = Convert-DataSize -Value 1 -FromUnit 'gigabyte' -ToUnit 'megabyte'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'megabyte'
        }
        
        It 'Convert-DataSize supports IEC binary units (KiB, MiB, etc.)' {
            $result = Convert-DataSize -Value 1 -FromUnit 'GiB' -ToUnit 'MiB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'MiB'
        }
    }
    
    Context 'Data Size Conversions (Decimal Units)' {
        It 'Convert-DataSize with -UseDecimal converts KB to MB (decimal)' {
            $result = Convert-DataSize -Value 1000 -FromUnit 'KB' -ToUnit 'MB' -UseDecimal
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'MB'
            $result.IsDecimal | Should -Be $true
        }
        
        It 'Convert-DataSize with -UseDecimal converts GB to MB (decimal)' {
            $result = Convert-DataSize -Value 1 -FromUnit 'GB' -ToUnit 'MB' -UseDecimal
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1000
            $result.Unit | Should -Be 'MB'
            $result.IsDecimal | Should -Be $true
        }
        
        It 'Convert-DataSize binary vs decimal produces different results' {
            $binary = Convert-DataSize -Value 1 -FromUnit 'GB' -ToUnit 'MB'
            $decimal = Convert-DataSize -Value 1 -FromUnit 'GB' -ToUnit 'MB' -UseDecimal
            $binary.Value | Should -Be 1024
            $decimal.Value | Should -Be 1000
            $binary.Value | Should -Not -Be $decimal.Value
        }
    }
    
    Context 'Bytes Conversions' {
        It 'ConvertFrom-BytesToDataSize converts bytes to KB' {
            $result = ConvertFrom-BytesToDataSize -Bytes 1024 -ToUnit 'KB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'KB'
            $result.Bytes | Should -Be 1024
        }
        
        It 'ConvertFrom-BytesToDataSize converts bytes to MB' {
            $result = ConvertFrom-BytesToDataSize -Bytes 1048576 -ToUnit 'MB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'MB'
        }
        
        It 'ConvertFrom-BytesToDataSize supports pipeline input' {
            $result = 1048576 | ConvertFrom-BytesToDataSize -ToUnit 'MB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'MB'
        }
        
        It 'ConvertFrom-BytesToDataSize with -UseDecimal converts bytes to KB (decimal)' {
            $result = ConvertFrom-BytesToDataSize -Bytes 1000 -ToUnit 'KB' -UseDecimal
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1
            $result.Unit | Should -Be 'KB'
            $result.IsDecimal | Should -Be $true
        }
        
        It 'ConvertTo-BytesFromDataSize converts KB to bytes' {
            $result = ConvertTo-BytesFromDataSize -Value 1 -FromUnit 'KB'
            $result | Should -Be 1024
        }
        
        It 'ConvertTo-BytesFromDataSize converts MB to bytes' {
            $result = ConvertTo-BytesFromDataSize -Value 1 -FromUnit 'MB'
            $result | Should -Be 1048576
        }
        
        It 'ConvertTo-BytesFromDataSize converts GB to bytes' {
            $result = ConvertTo-BytesFromDataSize -Value 1 -FromUnit 'GB'
            $result | Should -Be 1073741824
        }
        
        It 'ConvertTo-BytesFromDataSize supports pipeline input' {
            $result = 1 | ConvertTo-BytesFromDataSize -FromUnit 'GB'
            $result | Should -Be 1073741824
        }
        
        It 'ConvertTo-BytesFromDataSize with -UseDecimal converts KB to bytes (decimal)' {
            $result = ConvertTo-BytesFromDataSize -Value 1 -FromUnit 'KB' -UseDecimal
            $result | Should -Be 1000
        }
        
        It 'Bytes roundtrip conversion' {
            $originalBytes = 1048576
            $mb = ConvertFrom-BytesToDataSize -Bytes $originalBytes -ToUnit 'MB'
            $backToBytes = ConvertTo-BytesFromDataSize -Value $mb.Value -FromUnit 'MB'
            $backToBytes | Should -Be $originalBytes
        }
    }
    
    Context 'Edge Cases and Error Handling' {
        It 'Convert-DataSize handles zero value' {
            $result = Convert-DataSize -Value 0 -FromUnit 'MB' -ToUnit 'KB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 0
        }
        
        It 'Convert-DataSize handles very large values' {
            $result = Convert-DataSize -Value 1 -FromUnit 'PB' -ToUnit 'TB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 1024
            $result.Unit | Should -Be 'TB'
        }
        
        It 'Convert-DataSize throws error for invalid source unit' {
            { Convert-DataSize -Value 1 -FromUnit 'InvalidUnit' -ToUnit 'MB' } | Should -Throw
        }
        
        It 'Convert-DataSize throws error for invalid target unit' {
            { Convert-DataSize -Value 1 -FromUnit 'MB' -ToUnit 'InvalidUnit' } | Should -Throw
        }
        
        It 'ConvertFrom-BytesToDataSize handles zero bytes' {
            $result = ConvertFrom-BytesToDataSize -Bytes 0 -ToUnit 'KB'
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be 0
        }
        
        It 'ConvertTo-BytesFromDataSize handles zero value' {
            $result = ConvertTo-BytesFromDataSize -Value 0 -FromUnit 'MB'
            $result | Should -Be 0
        }
    }
    
    Context 'Roundtrip Conversions' {
        It 'MB to KB and back roundtrip' {
            $original = 1
            $kb = Convert-DataSize -Value $original -FromUnit 'MB' -ToUnit 'KB'
            $backToMb = Convert-DataSize -Value $kb.Value -FromUnit 'KB' -ToUnit 'MB'
            $backToMb.Value | Should -Be $original
        }
        
        It 'GB to TB and back roundtrip' {
            $original = 1
            $tb = Convert-DataSize -Value $original -FromUnit 'GB' -ToUnit 'TB'
            $backToGb = Convert-DataSize -Value $tb.Value -FromUnit 'TB' -ToUnit 'GB'
            $backToGb.Value | Should -Be $original
        }
        
        It 'Decimal units roundtrip' {
            $original = 1
            $mb = Convert-DataSize -Value $original -FromUnit 'GB' -ToUnit 'MB' -UseDecimal
            $backToGb = Convert-DataSize -Value $mb.Value -FromUnit 'MB' -ToUnit 'GB' -UseDecimal
            $backToGb.Value | Should -Be $original
        }
    }
}

