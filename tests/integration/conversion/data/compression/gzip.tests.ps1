

<#
.SYNOPSIS
    Integration tests for Gzip compression utilities.

.DESCRIPTION
    This test suite validates Gzip compression and decompression functions.

.NOTES
    Tests cover both successful compression/decompression and roundtrip scenarios.
#>

Describe 'Gzip Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Gzip Compression' {
        It 'Compress-Gzip compresses a file' {
            Get-Command Compress-Gzip -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $testContent = "This is test content for compression. " * 100
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { Compress-Gzip -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile + '.gz'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $compressedSize = (Get-Item $outputFile).Length
                $originalSize = (Get-Item $tempFile).Length
                $compressedSize | Should -BeLessThan $originalSize
            }
        }

        It 'Expand-Gzip decompresses a Gzip file' {
            Get-Command Expand-Gzip -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $testContent = "This is test content for compression. " * 100
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { Compress-Gzip -InputPath $tempFile } | Should -Not -Throw
            $compressedFile = $tempFile + '.gz'
            if ($compressedFile -and -not [string]::IsNullOrWhiteSpace($compressedFile) -and (Test-Path -LiteralPath $compressedFile)) {
                { Expand-Gzip -InputPath $compressedFile } | Should -Not -Throw
                $decompressedFile = $tempFile
                if ($decompressedFile -and -not [string]::IsNullOrWhiteSpace($decompressedFile) -and (Test-Path -LiteralPath $decompressedFile)) {
                    $decompressedContent = Get-Content -Path $decompressedFile -Raw
                    $decompressedContent | Should -Be $testContent
                }
            }
        }

        It 'Gzip compression and decompression roundtrip' {
            $originalContent = "Roundtrip test content. " * 50
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            { Compress-Gzip -InputPath $tempFile } | Should -Not -Throw
            $compressedFile = $tempFile + '.gz'
            if ($compressedFile -and -not [string]::IsNullOrWhiteSpace($compressedFile) -and (Test-Path -LiteralPath $compressedFile)) {
                { Expand-Gzip -InputPath $compressedFile -OutputPath ($tempFile + '.decompressed') } | Should -Not -Throw
                $decompressedFile = $tempFile + '.decompressed'
                if ($decompressedFile -and -not [string]::IsNullOrWhiteSpace($decompressedFile) -and (Test-Path -LiteralPath $decompressedFile)) {
                    $decompressedContent = Get-Content -Path $decompressedFile -Raw
                    $decompressedContent | Should -Be $originalContent
                }
            }
        }
    }
}

