# ===============================================
# Brotli compression format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Brotli compression format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Brotli compression/decompression.
    Brotli is a modern compression algorithm developed by Google.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Uses .NET System.IO.Compression.BrotliStream (available in .NET Core 2.1+ and .NET 5+).
    For PowerShell 5.1, BrotliStream may not be available.
#>
function Initialize-FileConversion-CoreCompressionBrotli {
    # Brotli compress
    Set-Item -Path Function:Global:_Compress-Brotli -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath,
            [System.IO.Compression.CompressionLevel]$Quality = [System.IO.Compression.CompressionLevel]::Optimal
        )
        try {
            # Check if BrotliStream is available
            $brotliAvailable = $false
            try {
                $null = [System.IO.Compression.BrotliStream]
                $brotliAvailable = $true
            }
            catch {
                $brotliAvailable = $false
            }
            
            if (-not $brotliAvailable) {
                throw "BrotliStream is not available. Brotli requires .NET Core 2.1+ or .NET 5+. Upgrade to PowerShell 7+ or install .NET 5+ runtime."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.br'
            }
            
            $inputFile = Get-Item -LiteralPath $InputPath
            $inputStream = [System.IO.File]::OpenRead($inputFile.FullName)
            $outputStream = [System.IO.File]::Create($OutputPath)
            $brotliStream = New-Object System.IO.Compression.BrotliStream($outputStream, $Quality)
            
            try {
                $inputStream.CopyTo($brotliStream)
            }
            finally {
                $brotliStream.Close()
                $outputStream.Close()
                $inputStream.Close()
            }
        }
        catch {
            Write-Error "Failed to compress file with Brotli: $_"
            throw
        }
    } -Force

    # Brotli decompress
    Set-Item -Path Function:Global:_Decompress-Brotli -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Check if BrotliStream is available
            $brotliAvailable = $false
            try {
                $null = [System.IO.Compression.BrotliStream]
                $brotliAvailable = $true
            }
            catch {
                $brotliAvailable = $false
            }
            
            if (-not $brotliAvailable) {
                throw "BrotliStream is not available. Brotli requires .NET Core 2.1+ or .NET 5+. Upgrade to PowerShell 7+ or install .NET 5+ runtime."
            }
            
            if (-not $OutputPath) {
                # Remove .br extension if present
                if ($InputPath.EndsWith('.br')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 3)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            $inputStream = [System.IO.File]::OpenRead($InputPath)
            $brotliStream = New-Object System.IO.Compression.BrotliStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            $outputStream = [System.IO.File]::Create($OutputPath)
            
            try {
                $brotliStream.CopyTo($outputStream)
            }
            finally {
                $outputStream.Close()
                $brotliStream.Close()
                $inputStream.Close()
            }
        }
        catch {
            Write-Error "Failed to decompress Brotli file: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Compress with Brotli
<#
.SYNOPSIS
    Compresses a file using Brotli compression.
.DESCRIPTION
    Compresses a file using the Brotli compression algorithm.
    Brotli is a modern compression algorithm that provides better compression ratios than Gzip.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .br extension.
.PARAMETER Quality
    The compression quality level (Fastest, Optimal, NoCompression, SmallestSize).
    Default is Optimal.
.EXAMPLE
    Compress-Brotli -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.br.
.EXAMPLE
    Compress-Brotli -InputPath 'data.txt' -Quality Fastest
    
    Compresses data.txt with fastest compression.
.OUTPUTS
    System.String
    Returns the path to the compressed file.
#>
Set-Item -Path Function:Global:Compress-Brotli -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath,
        [System.IO.Compression.CompressionLevel]$Quality = [System.IO.Compression.CompressionLevel]::Optimal
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Brotli @PSBoundParameters
} -Force
Set-Alias -Name compress-brotli -Value Compress-Brotli -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name brotli -Value Compress-Brotli -Scope Global -ErrorAction SilentlyContinue

# Decompress Brotli
<#
.SYNOPSIS
    Decompresses a Brotli compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using Brotli compression.
.PARAMETER InputPath
    The path to the Brotli compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .br extension from input path.
.EXAMPLE
    Expand-Brotli -InputPath 'data.txt.br'
    
    Decompresses data.txt.br to data.txt.
.OUTPUTS
    System.String
    Returns the path to the decompressed file.
#>
Set-Item -Path Function:Global:Expand-Brotli -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Brotli @PSBoundParameters
} -Force
Set-Alias -Name expand-brotli -Value Expand-Brotli -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name uncompress-brotli -Value Expand-Brotli -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name decompress-brotli -Value Expand-Brotli -Scope Global -ErrorAction SilentlyContinue

