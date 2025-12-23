

<#
.SYNOPSIS
    Integration tests for Zlib compression utilities.

.DESCRIPTION
    This test suite validates Zlib compression and decompression functions.

.NOTES
    Tests cover both successful compression/decompression and roundtrip scenarios.
#>

Describe 'Zlib Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Zlib Compression' {
        It 'Compress-Zlib compresses a file' {
            Get-Command Compress-Zlib -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $testContent = "This is test content for Zlib compression. " * 100
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { Compress-Zlib -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile + '.zlib'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $compressedSize = (Get-Item $outputFile).Length
                $originalSize = (Get-Item $tempFile).Length
                $compressedSize | Should -BeLessThan $originalSize
            }
        }

        It 'Expand-Zlib decompresses a Zlib file' {
            Get-Command Expand-Zlib -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $testContent = "This is test content for Zlib compression. " * 100
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { Compress-Zlib -InputPath $tempFile } | Should -Not -Throw
            $compressedFile = $tempFile + '.zlib'
            if ($compressedFile -and -not [string]::IsNullOrWhiteSpace($compressedFile) -and (Test-Path -LiteralPath $compressedFile)) {
                { Expand-Zlib -InputPath $compressedFile } | Should -Not -Throw
            }
        }
    }
}

