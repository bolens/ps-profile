# ===============================================
# Checksum calculation utilities
# CRC32, Adler32 checksum formats
# ===============================================

<#
.SYNOPSIS
    Initializes checksum calculation utility functions.
.DESCRIPTION
    Sets up internal functions for calculating checksums (CRC32, Adler32, etc.).
    Supports checksum calculation for strings and files.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Checksums are used for error detection and data integrity verification.
#>
function Initialize-FileConversion-DigestChecksum {
    # CRC32 calculation
    Set-Item -Path Function:Global:_Get-Crc32 -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return 0
        }
        
        # CRC32 polynomial: 0xEDB88320 (reversed form of 0x04C11DB7)
        $crc32Table = @()
        for ($i = 0; $i -lt 256; $i++) {
            $crc = $i
            for ($j = 0; $j -lt 8; $j++) {
                if ($crc -band 1) {
                    $crc = (($crc -shr 1) -bxor 0xEDB88320)
                }
                else {
                    $crc = ($crc -shr 1)
                }
            }
            $crc32Table += $crc
        }
        
        $crc = 0xFFFFFFFF
        foreach ($byte in $Bytes) {
            $crc = (($crc -shr 8) -bxor $crc32Table[($crc -bxor $byte) -band 0xFF])
        }
        $crc = ($crc -bxor 0xFFFFFFFF)
        
        # Convert to unsigned 32-bit integer
        return [uint32]$crc
    } -Force

    # Adler32 calculation
    Set-Item -Path Function:Global:_Get-Adler32 -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return 1
        }
        
        $adler1 = 1
        $adler2 = 0
        $mod = 65521  # Largest prime less than 2^16
        
        foreach ($byte in $Bytes) {
            $adler1 = ($adler1 + $byte) % $mod
            $adler2 = ($adler2 + $adler1) % $mod
        }
        
        # Combine into 32-bit value: (adler2 << 16) | adler1
        return [uint32](($adler2 -shl 16) -bor $adler1)
    } -Force

    # Calculate checksum from string
    Set-Item -Path Function:Global:_Get-ChecksumFromString -Value {
        param(
            [string]$InputString,
            [ValidateSet('CRC32', 'Adler32')]
            [string]$Algorithm = 'CRC32'
        )
        if ([string]::IsNullOrWhiteSpace($InputString)) {
            return @{
                Algorithm = $Algorithm
                Checksum  = 0
                Hex       = '00000000'
            }
        }
        
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
        $checksum = 0
        
        switch ($Algorithm) {
            'CRC32' {
                $checksum = _Get-Crc32 -Bytes $bytes
            }
            'Adler32' {
                $checksum = _Get-Adler32 -Bytes $bytes
            }
        }
        
        return @{
            Algorithm = $Algorithm
            Checksum  = $checksum
            Hex       = $checksum.ToString('X8')
            Decimal   = $checksum
        }
    } -Force

    # Calculate checksum from file
    Set-Item -Path Function:Global:_Get-ChecksumFromFile -Value {
        param(
            [string]$FilePath,
            [ValidateSet('CRC32', 'Adler32')]
            [string]$Algorithm = 'CRC32'
        )
        if ($FilePath -and -not [string]::IsNullOrWhiteSpace($FilePath) -and -not (Test-Path -LiteralPath $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $checksum = 0
        
        switch ($Algorithm) {
            'CRC32' {
                $checksum = _Get-Crc32 -Bytes $bytes
            }
            'Adler32' {
                $checksum = _Get-Adler32 -Bytes $bytes
            }
        }
        
        return @{
            Algorithm = $Algorithm
            Checksum  = $checksum
            Hex       = $checksum.ToString('X8')
            Decimal   = $checksum
            File      = $FilePath
        }
    } -Force
}

# Calculate CRC32 checksum
<#
.SYNOPSIS
    Calculates CRC32 checksum for a string or file.
.DESCRIPTION
    Calculates the CRC32 (Cyclic Redundancy Check) checksum for the input string or file.
    CRC32 is commonly used for error detection in data transmission and storage.
.PARAMETER InputString
    The string to calculate checksum for.
.PARAMETER FilePath
    The path to the file to calculate checksum for.
.EXAMPLE
    Get-Crc32 -InputString "Hello World"
    
    Calculates CRC32 checksum for the string.
.EXAMPLE
    Get-Crc32 -FilePath "C:\temp\file.txt"
    
    Calculates CRC32 checksum for the file.
.OUTPUTS
    PSCustomObject
    Returns an object with Algorithm, Checksum, Hex, and Decimal properties.
#>
function Get-Crc32 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'String')]
        [string]$InputString,
        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [string]$FilePath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'File') {
                if (Get-Command _Get-ChecksumFromFile -ErrorAction SilentlyContinue) {
                    $result = _Get-ChecksumFromFile -FilePath $FilePath -Algorithm 'CRC32'
                    return [PSCustomObject]$result
                }
            }
            else {
                if (Get-Command _Get-ChecksumFromString -ErrorAction SilentlyContinue) {
                    $result = _Get-ChecksumFromString -InputString $InputString -Algorithm 'CRC32'
                    return [PSCustomObject]$result
                }
            }
        }
        catch {
            Write-Error "Failed to calculate CRC32 checksum: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name crc32 -Value Get-Crc32 -ErrorAction SilentlyContinue

# Calculate Adler32 checksum
<#
.SYNOPSIS
    Calculates Adler32 checksum for a string or file.
.DESCRIPTION
    Calculates the Adler32 checksum for the input string or file.
    Adler32 is a checksum algorithm used in zlib compression.
.PARAMETER InputString
    The string to calculate checksum for.
.PARAMETER FilePath
    The path to the file to calculate checksum for.
.EXAMPLE
    Get-Adler32 -InputString "Hello World"
    
    Calculates Adler32 checksum for the string.
.EXAMPLE
    Get-Adler32 -FilePath "C:\temp\file.txt"
    
    Calculates Adler32 checksum for the file.
.OUTPUTS
    PSCustomObject
    Returns an object with Algorithm, Checksum, Hex, and Decimal properties.
#>
function Get-Adler32 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'String')]
        [string]$InputString,
        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [string]$FilePath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'File') {
                if (Get-Command _Get-ChecksumFromFile -ErrorAction SilentlyContinue) {
                    $result = _Get-ChecksumFromFile -FilePath $FilePath -Algorithm 'Adler32'
                    return [PSCustomObject]$result
                }
            }
            else {
                if (Get-Command _Get-ChecksumFromString -ErrorAction SilentlyContinue) {
                    $result = _Get-ChecksumFromString -InputString $InputString -Algorithm 'Adler32'
                    return [PSCustomObject]$result
                }
            }
        }
        catch {
            Write-Error "Failed to calculate Adler32 checksum: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name adler32 -Value Get-Adler32 -ErrorAction SilentlyContinue

# Calculate checksum (generic)
<#
.SYNOPSIS
    Calculates checksum for a string or file using specified algorithm.
.DESCRIPTION
    Calculates checksum (CRC32 or Adler32) for the input string or file.
.PARAMETER InputString
    The string to calculate checksum for.
.PARAMETER FilePath
    The path to the file to calculate checksum for.
.PARAMETER Algorithm
    The checksum algorithm to use (CRC32 or Adler32). Default is CRC32.
.EXAMPLE
    Get-Checksum -InputString "Hello World" -Algorithm CRC32
    
    Calculates CRC32 checksum for the string.
.EXAMPLE
    Get-Checksum -FilePath "C:\temp\file.txt" -Algorithm Adler32
    
    Calculates Adler32 checksum for the file.
.OUTPUTS
    PSCustomObject
    Returns an object with Algorithm, Checksum, Hex, and Decimal properties.
#>
function Get-Checksum {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'String')]
        [string]$InputString,
        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [string]$FilePath,
        [ValidateSet('CRC32', 'Adler32')]
        [string]$Algorithm = 'CRC32'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'File') {
                if (Get-Command _Get-ChecksumFromFile -ErrorAction SilentlyContinue) {
                    $result = _Get-ChecksumFromFile -FilePath $FilePath -Algorithm $Algorithm
                    return [PSCustomObject]$result
                }
            }
            else {
                if (Get-Command _Get-ChecksumFromString -ErrorAction SilentlyContinue) {
                    $result = _Get-ChecksumFromString -InputString $InputString -Algorithm $Algorithm
                    return [PSCustomObject]$result
                }
            }
        }
        catch {
            Write-Error "Failed to calculate checksum: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name checksum -Value Get-Checksum -ErrorAction SilentlyContinue

