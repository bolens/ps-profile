

<#
.SYNOPSIS
    Integration tests for Zstandard (zstd) compression utilities.

.DESCRIPTION
    This test suite validates Zstandard compression and decompression functions.

.NOTES
    Tests cover both successful compression/decompression and roundtrip scenarios.
    Some tests may be skipped if zstd command is not available.
#>

Describe 'Zstandard (zstd) Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check if zstd command is available once for all tests (Get-Command finds it regardless of extension)
        $script:zstdAvailable = $false
        $cmd = Get-Command zstd -ErrorAction SilentlyContinue
        if ($cmd) {
            $script:zstdAvailable = $true
        }
    }

    Context 'Zstandard (zstd) Compression' {
        It 'Compress-Zstd compresses a file' {
            if (-not $script:zstdAvailable) {
                Set-ItResult -Skipped -Because "zstd command is not available. Install: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)"
                return
            }
            
            # Get the function command (get function, not alias)
            $compressCmd = Get-Command Compress-Zstd -CommandType Function -ErrorAction Stop
            
            $testContent = 'This is test content for zstd compression'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { & $compressCmd.ScriptBlock -InputPath $tempFile } | Should -Not -Throw
            $compressedFile = $tempFile + '.zst'
            if ($compressedFile -and -not [string]::IsNullOrWhiteSpace($compressedFile) -and (Test-Path -LiteralPath $compressedFile)) {
                $compressedFile | Should -Exist
                (Get-Item $compressedFile).Length | Should -BeLessThan (Get-Item $tempFile).Length
            }
        }
        
        It 'Expand-Zstd decompresses a zstd file' {
            if (-not $script:zstdAvailable) {
                Set-ItResult -Skipped -Because "zstd command is not available. Install: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)"
                return
            }
            
            # Get the function commands (get functions, not aliases)
            $compressCmd = Get-Command Compress-Zstd -CommandType Function -ErrorAction Stop
            $expandCmd = Get-Command Expand-Zstd -CommandType Function -ErrorAction Stop
            
            $testContent = 'This is test content for zstd compression'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            $compressedFile = $tempFile + '.zst'
            & $compressCmd.ScriptBlock -InputPath $tempFile -OutputPath $compressedFile
            
            { & $expandCmd.ScriptBlock -InputPath $compressedFile } | Should -Not -Throw
            $decompressedFile = $tempFile
            if ($decompressedFile -and -not [string]::IsNullOrWhiteSpace($decompressedFile) -and (Test-Path -LiteralPath $decompressedFile)) {
                $decompressedContent = Get-Content -Path $decompressedFile -Raw
                $decompressedContent | Should -Be $testContent
            }
        }
        
        It 'zstd compression and decompression roundtrip' {
            if (-not $script:zstdAvailable) {
                Set-ItResult -Skipped -Because "zstd command is not available. Install: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)"
                return
            }
            
            # Get the function commands (get functions, not aliases)
            $compressCmd = Get-Command Compress-Zstd -CommandType Function -ErrorAction Stop
            $expandCmd = Get-Command Expand-Zstd -CommandType Function -ErrorAction Stop
            
            $originalContent = 'This is test content for zstd compression roundtrip test'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            $compressedFile = $tempFile + '.zst'
            & $compressCmd.ScriptBlock -InputPath $tempFile -OutputPath $compressedFile
            $decompressedFile = Join-Path $TestDrive 'test-decompressed.txt'
            & $expandCmd.ScriptBlock -InputPath $compressedFile -OutputPath $decompressedFile
            
            if ($decompressedFile -and -not [string]::IsNullOrWhiteSpace($decompressedFile) -and (Test-Path -LiteralPath $decompressedFile)) {
                $decompressedContent = Get-Content -Path $decompressedFile -Raw
                $decompressedContent | Should -Be $originalContent
            }
        }
        
        It 'Compress-Zstd with custom compression level' {
            if (-not $script:zstdAvailable) {
                Set-ItResult -Skipped -Because "zstd command is not available. Install: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)"
                return
            }
            
            # Get the function command (get function, not alias)
            $compressCmd = Get-Command Compress-Zstd -CommandType Function -ErrorAction Stop
            
            $testContent = 'This is test content for zstd compression with custom level'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { & $compressCmd.ScriptBlock -InputPath $tempFile -CompressionLevel 10 } | Should -Not -Throw
        }
    }
}

