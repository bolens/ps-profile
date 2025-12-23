

<#
.SYNOPSIS
    Integration tests for Checksum calculation utilities.

.DESCRIPTION
    This test suite validates Checksum calculation functions (CRC32, Adler32).

.NOTES
    Tests cover both successful calculations and consistency checks.
#>

Describe 'Checksum Calculation Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Checksum Calculations' {
        It 'Get-Crc32 function exists' {
            Get-Command Get-Crc32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-Crc32 calculates CRC32 for string' {
            $result = Get-Crc32 -InputString 'Hello World'
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveProperty 'Algorithm'
            $result | Should -HaveProperty 'Checksum'
            $result | Should -HaveProperty 'Hex'
            $result | Should -HaveProperty 'Decimal'
            $result.Algorithm | Should -Be 'CRC32'
            $result.Hex | Should -Match '^[0-9A-F]{8}$'
        }

        It 'Get-Crc32 calculates CRC32 for file' {
            $testContent = 'Test file content for CRC32'
            $tempFile = Join-Path $TestDrive 'test-crc32.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            $result = Get-Crc32 -FilePath $tempFile
            
            $result | Should -Not -BeNullOrEmpty
            $result.Algorithm | Should -Be 'CRC32'
            $result | Should -HaveProperty 'File'
            $result.File | Should -Be $tempFile
        }

        It 'Get-Crc32 returns consistent results' {
            $input = 'Test string'
            $result1 = Get-Crc32 -InputString $input
            $result2 = Get-Crc32 -InputString $input
            
            $result1.Checksum | Should -Be $result2.Checksum
            $result1.Hex | Should -Be $result2.Hex
        }

        It 'Get-Adler32 function exists' {
            Get-Command Get-Adler32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-Adler32 calculates Adler32 for string' {
            $result = Get-Adler32 -InputString 'Hello World'
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveProperty 'Algorithm'
            $result | Should -HaveProperty 'Checksum'
            $result | Should -HaveProperty 'Hex'
            $result | Should -HaveProperty 'Decimal'
            $result.Algorithm | Should -Be 'Adler32'
            $result.Hex | Should -Match '^[0-9A-F]{8}$'
        }

        It 'Get-Adler32 calculates Adler32 for file' {
            $testContent = 'Test file content for Adler32'
            $tempFile = Join-Path $TestDrive 'test-adler32.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            $result = Get-Adler32 -FilePath $tempFile
            
            $result | Should -Not -BeNullOrEmpty
            $result.Algorithm | Should -Be 'Adler32'
            $result | Should -HaveProperty 'File'
            $result.File | Should -Be $tempFile
        }

        It 'Get-Adler32 returns consistent results' {
            $input = 'Test string'
            $result1 = Get-Adler32 -InputString $input
            $result2 = Get-Adler32 -InputString $input
            
            $result1.Checksum | Should -Be $result2.Checksum
            $result1.Hex | Should -Be $result2.Hex
        }

        It 'Get-Checksum function exists' {
            Get-Command Get-Checksum -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-Checksum with CRC32 algorithm' {
            $result = Get-Checksum -InputString 'Test' -Algorithm CRC32
            
            $result | Should -Not -BeNullOrEmpty
            $result.Algorithm | Should -Be 'CRC32'
        }

        It 'Get-Checksum with Adler32 algorithm' {
            $result = Get-Checksum -InputString 'Test' -Algorithm Adler32
            
            $result | Should -Not -BeNullOrEmpty
            $result.Algorithm | Should -Be 'Adler32'
        }

        It 'CRC32 and Adler32 produce different results' {
            $input = 'Test string'
            $crc32 = Get-Crc32 -InputString $input
            $adler32 = Get-Adler32 -InputString $input
            
            $crc32.Checksum | Should -Not -Be $adler32.Checksum
        }

        It 'Handles empty string input' {
            $result = Get-Crc32 -InputString ''
            
            $result | Should -Not -BeNullOrEmpty
            $result.Checksum | Should -Be 0
            $result.Hex | Should -Be '00000000'
        }

        It 'Handles missing file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.txt'
            
            { Get-Crc32 -FilePath $nonExistentFile } | Should -Throw
        }
    }
}

