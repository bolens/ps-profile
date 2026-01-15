# ===============================================
# Gzip/Zlib compression format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Gzip/Zlib compression format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Gzip and Zlib compression/decompression.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Uses .NET System.IO.Compression classes for compression/decompression.
#>
function Initialize-FileConversion-CoreCompressionGzip {
    # Gzip compress
    Set-Item -Path Function:Global:_Compress-Gzip -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.gzip.compress] Starting compression: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.gz'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.compress] Output path: $OutputPath"
            }
            
            $inputFile = Get-Item -LiteralPath $InputPath
            $inputSize = $inputFile.Length
            
            # Level 2: File context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.compress] Input file size: ${inputSize} bytes"
            }
            
            $compressStartTime = Get-Date
            $inputStream = [System.IO.File]::OpenRead($inputFile.FullName)
            $outputStream = [System.IO.File]::Create($OutputPath)
            $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
            
            try {
                $inputStream.CopyTo($gzipStream)
            }
            finally {
                $gzipStream.Close()
                $outputStream.Close()
                $inputStream.Close()
            }
            
            $compressDuration = ((Get-Date) - $compressStartTime).TotalMilliseconds
            $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
            $compressionRatio = if ($inputSize -gt 0) { [math]::Round(($outputSize / $inputSize) * 100, 2) } else { 0 }
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.compress] Compression completed in ${compressDuration}ms"
                Write-Verbose "[conversion.gzip.compress] Output size: ${outputSize} bytes, Compression ratio: ${compressionRatio}%"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.gzip.compress] Performance - Duration: ${compressDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Ratio: ${compressionRatio}%" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.gzip.compress' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to compress file with Gzip: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.compress] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.gzip.compress] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # Gzip decompress
    Set-Item -Path Function:Global:_Decompress-Gzip -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.gzip.decompress] Starting decompression: $InputPath"
            }
            
            if (-not $OutputPath) {
                # Remove .gz extension if present
                if ($InputPath.EndsWith('.gz')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 3)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.decompress] Output path: $OutputPath"
            }
            
            $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
            
            # Level 2: File context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.decompress] Input file size: ${inputSize} bytes"
            }
            
            $decompressStartTime = Get-Date
            $inputStream = [System.IO.File]::OpenRead($InputPath)
            $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            $outputStream = [System.IO.File]::Create($OutputPath)
            
            try {
                $gzipStream.CopyTo($outputStream)
            }
            finally {
                $outputStream.Close()
                $gzipStream.Close()
                $inputStream.Close()
            }
            
            $decompressDuration = ((Get-Date) - $decompressStartTime).TotalMilliseconds
            $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
            $expansionRatio = if ($inputSize -gt 0) { [math]::Round(($outputSize / $inputSize) * 100, 2) } else { 0 }
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.decompress] Decompression completed in ${decompressDuration}ms"
                Write-Verbose "[conversion.gzip.decompress] Output size: ${outputSize} bytes, Expansion ratio: ${expansionRatio}%"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.gzip.decompress] Performance - Duration: ${decompressDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Ratio: ${expansionRatio}%" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.gzip.decompress' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to decompress Gzip file: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.gzip.decompress] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.gzip.decompress] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # Zlib compress (using DeflateStream)
    Set-Item -Path Function:Global:_Compress-Zlib -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.zlib.compress] Starting compression: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath + '.zlib'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.compress] Output path: $OutputPath"
            }
            
            $inputFile = Get-Item -LiteralPath $InputPath
            $inputSize = $inputFile.Length
            
            # Level 2: File context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.compress] Input file size: ${inputSize} bytes"
            }
            
            $compressStartTime = Get-Date
            $inputStream = [System.IO.File]::OpenRead($inputFile.FullName)
            $outputStream = [System.IO.File]::Create($OutputPath)
            $deflateStream = New-Object System.IO.Compression.DeflateStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
            
            try {
                $inputStream.CopyTo($deflateStream)
            }
            finally {
                $deflateStream.Close()
                $outputStream.Close()
                $inputStream.Close()
            }
            
            $compressDuration = ((Get-Date) - $compressStartTime).TotalMilliseconds
            $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
            $compressionRatio = if ($inputSize -gt 0) { [math]::Round(($outputSize / $inputSize) * 100, 2) } else { 0 }
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.compress] Compression completed in ${compressDuration}ms"
                Write-Verbose "[conversion.zlib.compress] Output size: ${outputSize} bytes, Compression ratio: ${compressionRatio}%"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.zlib.compress] Performance - Duration: ${compressDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Ratio: ${compressionRatio}%" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.zlib.compress' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to compress file with Zlib: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.compress] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.zlib.compress] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # Zlib decompress (using DeflateStream)
    Set-Item -Path Function:Global:_Decompress-Zlib -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.zlib.decompress] Starting decompression: $InputPath"
            }
            
            if (-not $OutputPath) {
                # Remove .zlib extension if present
                if ($InputPath.EndsWith('.zlib')) {
                    $OutputPath = $InputPath.Substring(0, $InputPath.Length - 5)
                }
                else {
                    $OutputPath = $InputPath + '.decompressed'
                }
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.decompress] Output path: $OutputPath"
            }
            
            $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
            
            # Level 2: File context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.decompress] Input file size: ${inputSize} bytes"
            }
            
            $decompressStartTime = Get-Date
            $inputStream = [System.IO.File]::OpenRead($InputPath)
            $deflateStream = New-Object System.IO.Compression.DeflateStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            $outputStream = [System.IO.File]::Create($OutputPath)
            
            try {
                $deflateStream.CopyTo($outputStream)
            }
            finally {
                $outputStream.Close()
                $deflateStream.Close()
                $inputStream.Close()
            }
            
            $decompressDuration = ((Get-Date) - $decompressStartTime).TotalMilliseconds
            $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
            $expansionRatio = if ($inputSize -gt 0) { [math]::Round(($outputSize / $inputSize) * 100, 2) } else { 0 }
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.decompress] Decompression completed in ${decompressDuration}ms"
                Write-Verbose "[conversion.zlib.decompress] Output size: ${outputSize} bytes, Expansion ratio: ${expansionRatio}%"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.zlib.decompress] Performance - Duration: ${decompressDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Ratio: ${expansionRatio}%" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.zlib.decompress' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to decompress Zlib file: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.zlib.decompress] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.zlib.decompress] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Compress with Gzip
<#
.SYNOPSIS
    Compresses a file using Gzip compression.
.DESCRIPTION
    Compresses a file using Gzip compression algorithm.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .gz extension.
.EXAMPLE
    Compress-Gzip -InputPath "data.txt" -OutputPath "data.txt.gz"
    
    Compresses data.txt to data.txt.gz.
#>
Set-Item -Path Function:Global:Compress-Gzip -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Gzip @PSBoundParameters
} -Force
Set-Alias -Name gzip-compress -Value Compress-Gzip -Scope Global -ErrorAction SilentlyContinue

# Decompress Gzip
<#
.SYNOPSIS
    Decompresses a Gzip-compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using Gzip compression algorithm.
.PARAMETER InputPath
    The path to the Gzip-compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .gz extension from input path.
.EXAMPLE
    Expand-Gzip -InputPath "data.txt.gz" -OutputPath "data.txt"
    
    Decompresses data.txt.gz to data.txt.
#>
Set-Item -Path Function:Global:Expand-Gzip -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Gzip @PSBoundParameters
} -Force
Set-Alias -Name gzip-decompress -Value Expand-Gzip -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name gunzip -Value Expand-Gzip -Scope Global -ErrorAction SilentlyContinue

# Compress with Zlib
<#
.SYNOPSIS
    Compresses a file using Zlib compression.
.DESCRIPTION
    Compresses a file using Zlib (Deflate) compression algorithm.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .zlib extension.
.EXAMPLE
    Compress-Zlib -InputPath "data.txt" -OutputPath "data.txt.zlib"
    
    Compresses data.txt to data.txt.zlib.
#>
Set-Item -Path Function:Global:Compress-Zlib -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Zlib @PSBoundParameters
} -Force
Set-Alias -Name zlib-compress -Value Compress-Zlib -Scope Global -ErrorAction SilentlyContinue

# Decompress Zlib
<#
.SYNOPSIS
    Decompresses a Zlib-compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using Zlib (Deflate) compression algorithm.
.PARAMETER InputPath
    The path to the Zlib-compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .zlib extension from input path.
.EXAMPLE
    Expand-Zlib -InputPath "data.txt.zlib" -OutputPath "data.txt"
    
    Decompresses data.txt.zlib to data.txt.
#>
Set-Item -Path Function:Global:Expand-Zlib -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Zlib @PSBoundParameters
} -Force
Set-Alias -Name zlib-decompress -Value Expand-Zlib -Scope Global -ErrorAction SilentlyContinue

