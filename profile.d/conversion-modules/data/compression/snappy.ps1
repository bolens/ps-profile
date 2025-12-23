# ===============================================
# Snappy compression format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Snappy compression format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Snappy compression/decompression.
    Snappy is a fast compression algorithm developed by Google, optimized for speed.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires snappy command-line tool or Python with python-snappy package to be installed.
    Install snappy: Windows (scoop install snappy), Linux (apt install snappy-tools), macOS (brew install snappy)
    Alternative: Python package (uv pip install python-snappy)
#>
function Initialize-FileConversion-CoreCompressionSnappy {
    # Snappy compress
    Set-Item -Path Function:Global:_Compress-Snappy -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Try snappy command first
            $snappyCmd = Get-Command snappy -ErrorAction SilentlyContinue
            if ($snappyCmd) {
                if (-not $OutputPath) {
                    $OutputPath = $InputPath + '.snappy'
                }
                
                # Use snappy command-line tool
                $snappyArgs = @('-c', $InputPath)
                $output = & $snappyCmd @snappyArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding Byte
                if ($LASTEXITCODE -ne 0) {
                    throw "snappy compression failed with exit code $LASTEXITCODE"
                }
                return
            }
            
            # Fallback to Python with python-snappy
            if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
                $pythonCmd = Get-PythonPath
                if ($pythonCmd) {
                    if (-not $OutputPath) {
                        $OutputPath = $InputPath + '.snappy'
                    }
                    
                    $pythonScript = @"
import sys
import snappy

try:
    with open(sys.argv[1], 'rb') as f:
        data = f.read()
    
    compressed = snappy.compress(data)
    
    with open(sys.argv[2], 'wb') as f:
        f.write(compressed)
except ImportError:
    print('Error: python-snappy package is not installed. Install with: uv pip install python-snappy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
                    $tempScript = Join-Path $env:TEMP "snappy-compress-$(Get-Random).py"
                    Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
                    try {
                        $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Python script failed: $result"
                        }
                        return
                    }
                    finally {
                        Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                    }
                }
            }
            
            throw "snappy is not available. Install snappy: Windows (scoop install snappy), Linux (apt install snappy-tools), macOS (brew install snappy), or Python package (uv pip install python-snappy)"
        }
        catch {
            Write-Error "Failed to compress file with Snappy: $_"
            throw
        }
    } -Force

    # Snappy decompress
    Set-Item -Path Function:Global:_Decompress-Snappy -Value {
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            [string]$OutputPath
        )
        try {
            # Try snappy command first
            $snappyCmd = Get-Command snappy -ErrorAction SilentlyContinue
            if ($snappyCmd) {
                if (-not $OutputPath) {
                    # Remove .snappy extension if present
                    if ($InputPath.EndsWith('.snappy')) {
                        $OutputPath = $InputPath.Substring(0, $InputPath.Length - 7)
                    }
                    else {
                        $OutputPath = $InputPath + '.decompressed'
                    }
                }
                
                # Use snappy command-line tool with -d flag for decompression
                $snappyArgs = @('-d', $InputPath)
                $output = & $snappyCmd @snappyArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding Byte
                if ($LASTEXITCODE -ne 0) {
                    throw "snappy decompression failed with exit code $LASTEXITCODE"
                }
                return
            }
            
            # Fallback to Python with python-snappy
            if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
                $pythonCmd = Get-PythonPath
                if ($pythonCmd) {
                    if (-not $OutputPath) {
                        if ($InputPath.EndsWith('.snappy')) {
                            $OutputPath = $InputPath.Substring(0, $InputPath.Length - 7)
                        }
                        else {
                            $OutputPath = $InputPath + '.decompressed'
                        }
                    }
                    
                    $pythonScript = @"
import sys
import snappy

try:
    with open(sys.argv[1], 'rb') as f:
        compressed = f.read()
    
    data = snappy.uncompress(compressed)
    
    with open(sys.argv[2], 'wb') as f:
        f.write(data)
except ImportError:
    print('Error: python-snappy package is not installed. Install with: uv pip install python-snappy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
                    $tempScript = Join-Path $env:TEMP "snappy-decompress-$(Get-Random).py"
                    Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
                    try {
                        $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Python script failed: $result"
                        }
                        return
                    }
                    finally {
                        Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                    }
                }
            }
            
            throw "snappy is not available. Install snappy: Windows (scoop install snappy), Linux (apt install snappy-tools), macOS (brew install snappy), or Python package (uv pip install python-snappy)"
        }
        catch {
            Write-Error "Failed to decompress Snappy file: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Compress Snappy
<#
.SYNOPSIS
    Compresses a file using Snappy compression.
.DESCRIPTION
    Compresses a file using the Snappy compression algorithm.
    Snappy is a fast compression algorithm developed by Google, optimized for speed.
.PARAMETER InputPath
    The path to the file to compress.
.PARAMETER OutputPath
    The path for the output compressed file. If not specified, uses input path with .snappy extension.
.EXAMPLE
    Compress-Snappy -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.snappy.
.OUTPUTS
    System.String
    Returns the path to the compressed file.
#>
Set-Item -Path Function:Global:Compress-Snappy -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Compress-Snappy @PSBoundParameters
} -Force
Set-Alias -Name compress-snappy -Value Compress-Snappy -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name snappy -Value Compress-Snappy -Scope Global -ErrorAction SilentlyContinue

# Decompress Snappy
<#
.SYNOPSIS
    Decompresses a Snappy compressed file.
.DESCRIPTION
    Decompresses a file that was compressed using Snappy compression.
.PARAMETER InputPath
    The path to the Snappy compressed file.
.PARAMETER OutputPath
    The path for the output decompressed file. If not specified, removes .snappy extension from input path.
.EXAMPLE
    Expand-Snappy -InputPath 'data.txt.snappy'
    
    Decompresses data.txt.snappy to data.txt.
.OUTPUTS
    System.String
    Returns the path to the decompressed file.
#>
Set-Item -Path Function:Global:Expand-Snappy -Value {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Decompress-Snappy @PSBoundParameters
} -Force
Set-Alias -Name expand-snappy -Value Expand-Snappy -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name decompress-snappy -Value Expand-Snappy -Scope Global -ErrorAction SilentlyContinue

