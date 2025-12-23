# ===============================================
# Zstandard (zstd) compression format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Zstandard (zstd) compression format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Zstandard (zstd) compression/decompression.
    Zstandard is a fast compression algorithm developed by Facebook.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires zstd command-line tool to be installed and available in PATH.
    Install zstd: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)
#>
function Initialize-FileConversion-CoreCompressionZstd {
    # Zstd compress
    Set-Item -Path Function:Global:_Compress-Zstd -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath,
            [int]$CompressionLevel = 3
        )
        try {
            # Check if zstd command is available (Get-Command finds it regardless of extension)
            $zstdCmd = Get-Command zstd -ErrorAction SilentlyContinue
            if (-not $zstdCmd) {
                throw "zstd command is not available. Install zstd: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.zst'
            }
            
            # Validate compression level (zstd supports -1 to 22, default is 3)
            if ($CompressionLevel -lt -1 -or $CompressionLevel -gt 22) {
                throw "Compression level must be between -1 and 22"
            }
            
            # Use zstd command-line tool
            # Compression level format: -3 (single argument, not "-3")
            $levelArg = "-$CompressionLevel"
            $zstdArgs = @('-f', $levelArg, '-o', $OutputPath, $InputPath)
            
            # Invoke zstd using the command object - works for both executables and PowerShell script shims
            $null = & $zstdCmd @zstdArgs 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "zstd compression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to compress file with zstd: $_"
            throw
        }
    } -Force

    # Zstd decompress
    Set-Item -Path Function:Global:_Decompress-Zstd -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Check if zstd command is available (Get-Command finds it regardless of extension)
            $zstdCmd = Get-Command zstd -ErrorAction SilentlyContinue
            if (-not $zstdCmd) {
                throw "zstd command is not available. Install zstd: Windows (scoop install zstd), Linux (apt install zstd), macOS (brew install zstd)"
            }
            
            if (-not $OutputPath) {
                # Remove .zst or .zstd extension if present
                if ($InputPath.EndsWith('.zst')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 4)
                }
                elseif ($InputPath.EndsWith('.zstd')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 5)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            # Use zstd command-line tool with -d flag for decompression
            $zstdArgs = @('-d', '-f', '-o', $OutputPath, $InputPath)
            
            # Invoke zstd using the command object - works for both executables and PowerShell script shims
            $null = & $zstdCmd @zstdArgs 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "zstd decompression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to decompress zstd file: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Compress with Zstandard
<#
.SYNOPSIS
    Compresses a file using Zstandard (zstd) compression.
.DESCRIPTION
    Compresses a file using the Zstandard (zstd) compression algorithm.
    Zstandard provides a good balance between compression ratio and speed.
    Requires the zstd command-line tool to be installed.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .zst extension.
.PARAMETER CompressionLevel
    The compression level (1-22, or -1 for default). Higher values provide better compression but are slower.
    Default is 3.
.EXAMPLE
    Compress-Zstd -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.zst.
.EXAMPLE
    Compress-Zstd -InputPath 'data.txt' -CompressionLevel 10
    
    Compresses data.txt with compression level 10.
.NOTES
    Requires zstd command-line tool:
    - Windows: scoop install zstd
    - Linux: apt install zstd (or equivalent)
    - macOS: brew install zstd
.OUTPUTS
    System.String
    Returns the path to the compressed file.
#>
Set-Item -Path Function:Global:Compress-Zstd -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath,
        [int]$CompressionLevel = 3
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Zstd @PSBoundParameters
} -Force
Set-Alias -Name compress-zstd -Value Compress-Zstd -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name zstd -Value Compress-Zstd -Scope Global -ErrorAction SilentlyContinue

# Decompress Zstandard
<#
.SYNOPSIS
    Decompresses a Zstandard (zstd) compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using Zstandard (zstd) compression.
    Requires the zstd command-line tool to be installed.
.PARAMETER InputPath
    The path to the zstd compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .zst extension from input path.
.EXAMPLE
    Expand-Zstd -InputPath 'data.txt.zst'
    
    Decompresses data.txt.zst to data.txt.
.NOTES
    Requires zstd command-line tool:
    - Windows: scoop install zstd
    - Linux: apt install zstd (or equivalent)
    - macOS: brew install zstd
.OUTPUTS
    System.String
    Returns the path to the decompressed file.
#>
Set-Item -Path Function:Global:Expand-Zstd -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Zstd @PSBoundParameters
} -Force
Set-Alias -Name expand-zstd -Value Expand-Zstd -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name uncompress-zstd -Value Expand-Zstd -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name decompress-zstd -Value Expand-Zstd -Scope Global -ErrorAction SilentlyContinue

