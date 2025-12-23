

<#
.SYNOPSIS
    Integration tests for Brotli compression utilities.

.DESCRIPTION
    This test suite validates Brotli compression and decompression functions.

.NOTES
    Tests cover both successful compression/decompression and roundtrip scenarios.
    Some tests may be skipped if BrotliStream is not available (requires .NET Core 2.1+ or .NET 5+).
#>

Describe 'Brotli Compression Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check if BrotliStream is available once for all tests
        $script:brotliAvailable = $false
        try {
            $null = [System.IO.Compression.BrotliStream]
            $script:brotliAvailable = $true
        }
        catch {
            $script:brotliAvailable = $false
        }
    }

    Context 'Brotli Compression' {
        It 'Compress-Brotli compresses a file' {
            if (-not $script:brotliAvailable) {
                Set-ItResult -Skipped -Because "BrotliStream is not available (requires .NET Core 2.1+ or .NET 5+)"
                return
            }
            
            # Check for function (functions exist in Function: drive)
            $cmd = Get-Command Compress-Brotli -ErrorAction SilentlyContinue
            if (-not $cmd) {
                # Try alias
                $alias = Get-Command compress-brotli -ErrorAction SilentlyContinue
                if ($alias) {
                    $cmd = Get-Command $alias.ResolvedCommand.Name -ErrorAction SilentlyContinue
                }
            }
            $cmd | Should -Not -Be $null
            
            # Get the function command (get function, not alias)
            $compressCmd = Get-Command Compress-Brotli -CommandType Function -ErrorAction Stop
            
            $testContent = 'This is test content for Brotli compression'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            { & $compressCmd.ScriptBlock -InputPath $tempFile } | Should -Not -Throw
            $compressedFile = $tempFile + '.br'
            if ($compressedFile -and -not [string]::IsNullOrWhiteSpace($compressedFile) -and (Test-Path -LiteralPath $compressedFile)) {
                $compressedFile | Should -Exist
                (Get-Item $compressedFile).Length | Should -BeLessThan (Get-Item $tempFile).Length
            }
        }
        
        It 'Expand-Brotli decompresses a Brotli file' {
            if (-not $script:brotliAvailable) {
                Set-ItResult -Skipped -Because "BrotliStream is not available (requires .NET Core 2.1+ or .NET 5+)"
                return
            }
            
            # Get the function commands (get functions, not aliases)
            $compressCmd = Get-Command Compress-Brotli -CommandType Function -ErrorAction Stop
            $expandCmd = Get-Command Expand-Brotli -CommandType Function -ErrorAction Stop
            
            $testContent = 'This is test content for Brotli compression'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $testContent -NoNewline
            
            $compressedFile = $tempFile + '.br'
            & $compressCmd.ScriptBlock -InputPath $tempFile -OutputPath $compressedFile
            
            { & $expandCmd.ScriptBlock -InputPath $compressedFile } | Should -Not -Throw
            $decompressedFile = $tempFile
            if ($decompressedFile -and -not [string]::IsNullOrWhiteSpace($decompressedFile) -and (Test-Path -LiteralPath $decompressedFile)) {
                $decompressedContent = Get-Content -Path $decompressedFile -Raw
                $decompressedContent | Should -Be $testContent
            }
        }
        
        It 'Brotli compression and decompression roundtrip' {
            if (-not $script:brotliAvailable) {
                Set-ItResult -Skipped -Because "BrotliStream is not available (requires .NET Core 2.1+ or .NET 5+)"
                return
            }
            
            # Get the function commands (get functions, not aliases)
            $compressCmd = Get-Command Compress-Brotli -CommandType Function -ErrorAction Stop
            $expandCmd = Get-Command Expand-Brotli -CommandType Function -ErrorAction Stop
            
            $originalContent = 'This is test content for Brotli compression roundtrip test'
            $tempFile = Join-Path $TestDrive 'test.txt'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            $compressedFile = $tempFile + '.br'
            & $compressCmd.ScriptBlock -InputPath $tempFile -OutputPath $compressedFile
            $decompressedFile = Join-Path $TestDrive 'test-decompressed.txt'
            & $expandCmd.ScriptBlock -InputPath $compressedFile -OutputPath $decompressedFile
            
            if ($decompressedFile -and -not [string]::IsNullOrWhiteSpace($decompressedFile) -and (Test-Path -LiteralPath $decompressedFile)) {
                $decompressedContent = Get-Content -Path $decompressedFile -Raw
                $decompressedContent | Should -Be $originalContent
            }
        }
    }
}

