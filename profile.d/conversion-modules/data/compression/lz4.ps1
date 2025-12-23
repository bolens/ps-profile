# ===============================================
# LZ4 compression format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes LZ4 compression format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for LZ4 compression/decompression.
    LZ4 is a fast compression algorithm with high compression and decompression speeds.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires lz4 command-line tool to be installed and available in PATH.
    Install lz4: Windows (scoop install lz4), Linux (apt install lz4), macOS (brew install lz4)
#>
function Initialize-FileConversion-CoreCompressionLz4 {
    # LZ4 compress
    Set-Item -Path Function:Global:_Compress-Lz4 -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath,
            [int]$CompressionLevel = 1
        )
        try {
            # Check if lz4 command is available
            $lz4Cmd = Get-Command lz4 -ErrorAction SilentlyContinue
            if (-not $lz4Cmd) {
                throw "lz4 command is not available. Install lz4: Windows (scoop install lz4), Linux (apt install lz4), macOS (brew install lz4)"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.lz4'
            }
            
            # Validate compression level (lz4 supports 1-9, default is 1 for fastest)
            if ($CompressionLevel -lt 1 -or $CompressionLevel -gt 9) {
                throw "Compression level must be between 1 and 9"
            }
            
            # Use lz4 command-line tool
            # -f: force overwrite, -z: compress, -#: compression level
            $lz4Args = @('-f', '-z', "-$CompressionLevel", $InputPath, $OutputPath)
            
            $null = & $lz4Cmd @lz4Args 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "lz4 compression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to compress file with LZ4: $_"
            throw
        }
    } -Force

    # LZ4 decompress
    Set-Item -Path Function:Global:_Decompress-Lz4 -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Check if lz4 command is available
            $lz4Cmd = Get-Command lz4 -ErrorAction SilentlyContinue
            if (-not $lz4Cmd) {
                throw "lz4 command is not available. Install lz4: Windows (scoop install lz4), Linux (apt install lz4), macOS (brew install lz4)"
            }
            
            if (-not $OutputPath) {
                # Remove .lz4 extension if present
                if ($InputPath.EndsWith('.lz4')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 4)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            # Use lz4 command-line tool with -d flag for decompression
            $lz4Args = @('-f', '-d', $InputPath, $OutputPath)
            
            $null = & $lz4Cmd @lz4Args 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "lz4 decompression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to decompress LZ4 file: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Compress LZ4
<#
.SYNOPSIS
    Compresses a file using LZ4 compression.
.DESCRIPTION
    Compresses a file using the LZ4 compression algorithm.
    LZ4 is a fast compression algorithm with high compression and decompression speeds.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .lz4 extension.
.PARAMETER CompressionLevel
    The compression level (1-9). Default is 1 (fastest). Higher levels provide better compression but are slower.
.EXAMPLE
    Compress-Lz4 -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.lz4.
.EXAMPLE
    Compress-Lz4 -InputPath 'data.txt' -CompressionLevel 9
    
    Compresses data.txt with maximum compression level.
.OUTPUTS
    System.String
    Returns the path to the compressed file.
#>
Set-Item -Path Function:Global:Compress-Lz4 -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath,
        [int]$CompressionLevel = 1
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Lz4 @PSBoundParameters
} -Force
Set-Alias -Name compress-lz4 -Value Compress-Lz4 -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name lz4 -Value Compress-Lz4 -Scope Global -ErrorAction SilentlyContinue

# Decompress LZ4
<#
.SYNOPSIS
    Decompresses an LZ4 compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using LZ4 compression.
.PARAMETER InputPath
    The path to the LZ4 compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .lz4 extension from input path.
.EXAMPLE
    Expand-Lz4 -InputPath 'data.txt.lz4'
    
    Decompresses data.txt.lz4 to data.txt.
.OUTPUTS
    System.String
    Returns the path to the decompressed file.
#>
Set-Item -Path Function:Global:Expand-Lz4 -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Lz4 @PSBoundParameters
} -Force
Set-Alias -Name expand-lz4 -Value Expand-Lz4 -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name decompress-lz4 -Value Expand-Lz4 -Scope Global -ErrorAction SilentlyContinue

