# ===============================================
# XZ/LZMA compression format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes XZ/LZMA compression format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for XZ and LZMA compression/decompression.
    XZ is a compression format using the LZMA2 algorithm, providing high compression ratios.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires xz command-line tool to be installed and available in PATH.
    Install xz: Windows (scoop install xz), Linux (apt install xz-utils), macOS (brew install xz)
#>
function Initialize-FileConversion-CoreCompressionXz {
    # XZ compress
    Set-Item -Path Function:Global:_Compress-Xz -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath,
            [int]$CompressionLevel = 6
        )
        try {
            # Check if xz command is available
            $xzCmd = Get-Command xz -ErrorAction SilentlyContinue
            if (-not $xzCmd) {
                throw "xz command is not available. Install xz: Windows (scoop install xz), Linux (apt install xz-utils), macOS (brew install xz)"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.xz'
            }
            
            # Validate compression level (xz supports 0-9, default is 6)
            if ($CompressionLevel -lt 0 -or $CompressionLevel -gt 9) {
                throw "Compression level must be between 0 and 9"
            }
            
            # Use xz command-line tool
            # -k: keep original file, -#: compression level (0-9)
            $xzArgs = @('-k', "-$CompressionLevel", '-c', $InputPath)
            $output = & $xzCmd @xzArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding Byte
            if ($LASTEXITCODE -ne 0) {
                throw "xz compression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to compress file with XZ: $_"
            throw
        }
    } -Force

    # XZ decompress
    Set-Item -Path Function:Global:_Decompress-Xz -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Check if xz command is available
            $xzCmd = Get-Command xz -ErrorAction SilentlyContinue
            if (-not $xzCmd) {
                throw "xz command is not available. Install xz: Windows (scoop install xz), Linux (apt install xz-utils), macOS (brew install xz)"
            }
            
            if (-not $OutputPath) {
                # Remove .xz extension if present
                if ($InputPath.EndsWith('.xz')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 3)
                }
                elseif ($InputPath.EndsWith('.lzma')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 5)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            # Use xz command-line tool with -d flag for decompression
            $xzArgs = @('-d', '-k', '-c', $InputPath)
            $output = & $xzCmd @xzArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding Byte
            if ($LASTEXITCODE -ne 0) {
                throw "xz decompression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to decompress XZ file: $_"
            throw
        }
    } -Force

    # LZMA compress (using xz with --format=lzma)
    Set-Item -Path Function:Global:_Compress-Lzma -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath,
            [int]$CompressionLevel = 6
        )
        try {
            # Check if xz command is available
            $xzCmd = Get-Command xz -ErrorAction SilentlyContinue
            if (-not $xzCmd) {
                throw "xz command is not available. Install xz: Windows (scoop install xz), Linux (apt install xz-utils), macOS (brew install xz)"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.lzma'
            }
            
            # Validate compression level (xz supports 0-9, default is 6)
            if ($CompressionLevel -lt 0 -or $CompressionLevel -gt 9) {
                throw "Compression level must be between 0 and 9"
            }
            
            # Use xz command-line tool with --format=lzma for LZMA format
            $xzArgs = @('-k', '--format=lzma', "-$CompressionLevel", '-c', $InputPath)
            $output = & $xzCmd @xzArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding Byte
            if ($LASTEXITCODE -ne 0) {
                throw "LZMA compression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to compress file with LZMA: $_"
            throw
        }
    } -Force

    # LZMA decompress
    Set-Item -Path Function:Global:_Decompress-Lzma -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Check if xz command is available
            $xzCmd = Get-Command xz -ErrorAction SilentlyContinue
            if (-not $xzCmd) {
                throw "xz command is not available. Install xz: Windows (scoop install xz), Linux (apt install xz-utils), macOS (brew install xz)"
            }
            
            if (-not $OutputPath) {
                # Remove .lzma extension if present
                if ($InputPath.EndsWith('.lzma')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 5)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            # Use xz command-line tool with -d flag for decompression
            $xzArgs = @('-d', '-k', '-c', $InputPath)
            $output = & $xzCmd @xzArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding Byte
            if ($LASTEXITCODE -ne 0) {
                throw "LZMA decompression failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to decompress LZMA file: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Compress XZ
<#
.SYNOPSIS
    Compresses a file using XZ compression.
.DESCRIPTION
    Compresses a file using the XZ compression format (LZMA2 algorithm).
    XZ provides high compression ratios.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .xz extension.
.PARAMETER CompressionLevel
    The compression level (0-9). Default is 6. Higher levels provide better compression but are slower.
.EXAMPLE
    Compress-Xz -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.xz.
.EXAMPLE
    Compress-Xz -InputPath 'data.txt' -CompressionLevel 9
    
    Compresses data.txt with maximum compression level.
.OUTPUTS
    System.String
    Returns the path to the compressed file.
#>
Set-Item -Path Function:Global:Compress-Xz -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath,
        [int]$CompressionLevel = 6
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Xz @PSBoundParameters
} -Force
Set-Alias -Name compress-xz -Value Compress-Xz -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name xz -Value Compress-Xz -Scope Global -ErrorAction SilentlyContinue

# Decompress XZ
<#
.SYNOPSIS
    Decompresses an XZ compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using XZ compression.
.PARAMETER InputPath
    The path to the XZ compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .xz extension from input path.
.EXAMPLE
    Expand-Xz -InputPath 'data.txt.xz'
    
    Decompresses data.txt.xz to data.txt.
.OUTPUTS
    System.String
    Returns the path to the decompressed file.
#>
Set-Item -Path Function:Global:Expand-Xz -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Xz @PSBoundParameters
} -Force
Set-Alias -Name expand-xz -Value Expand-Xz -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name decompress-xz -Value Expand-Xz -Scope Global -ErrorAction SilentlyContinue

# Compress LZMA
<#
.SYNOPSIS
    Compresses a file using LZMA compression.
.DESCRIPTION
    Compresses a file using the LZMA compression format.
    LZMA provides high compression ratios.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .lzma extension.
.PARAMETER CompressionLevel
    The compression level (0-9). Default is 6. Higher levels provide better compression but are slower.
.EXAMPLE
    Compress-Lzma -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.lzma.
.OUTPUTS
    System.String
    Returns the path to the compressed file.
#>
Set-Item -Path Function:Global:Compress-Lzma -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath,
        [int]$CompressionLevel = 6
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Lzma @PSBoundParameters
} -Force
Set-Alias -Name compress-lzma -Value Compress-Lzma -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name lzma -Value Compress-Lzma -Scope Global -ErrorAction SilentlyContinue

# Decompress LZMA
<#
.SYNOPSIS
    Decompresses an LZMA compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using LZMA compression.
.PARAMETER InputPath
    The path to the LZMA compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .lzma extension from input path.
.EXAMPLE
    Expand-Lzma -InputPath 'data.txt.lzma'
    
    Decompresses data.txt.lzma to data.txt.
.OUTPUTS
    System.String
    Returns the path to the decompressed file.
#>
Set-Item -Path Function:Global:Expand-Lzma -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Lzma @PSBoundParameters
} -Force
Set-Alias -Name expand-lzma -Value Expand-Lzma -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name decompress-lzma -Value Expand-Lzma -Scope Global -ErrorAction SilentlyContinue

