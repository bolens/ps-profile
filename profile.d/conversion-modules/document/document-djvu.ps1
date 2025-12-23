# ===============================================
# DjVu document format conversion utilities
# DjVu ↔ PDF, PNG, JPEG, Text
# ===============================================

<#
.SYNOPSIS
    Initializes DjVu document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for DjVu format conversions.
    DjVu is a file format designed primarily to store scanned documents.
    Supports conversions between DjVu and PDF, PNG, JPEG, and text extraction.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires djvulibre tools (djvutxt, djvused, c44, etc.) or ImageMagick for conversions.
    DjVu files use .djvu or .djv extensions.
#>
function Initialize-FileConversion-DocumentDjvu {
    # DjVu to PDF (using ImageMagick if available, otherwise djvulibre)
    Set-Item -Path Function:Global:_ConvertFrom-DjvuToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(djvu|djv)$', '.pdf'
            }
            
            # Try ImageMagick first (better quality)
            if (Get-Command magick -ErrorAction SilentlyContinue) {
                $errorOutput = & magick $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            # Fallback to convert (ImageMagick legacy command)
            elseif (Get-Command convert -ErrorAction SilentlyContinue) {
                $errorOutput = & convert $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            # Fallback to djvups + ps2pdf (if available)
            elseif (Get-Command djvups -ErrorAction SilentlyContinue) {
                $tempPs = $OutputPath -replace '\.pdf$', '.ps'
                $errorOutput = & djvups $InputPath $tempPs 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0 -and
                    $tempPs -and
                    -not [string]::IsNullOrWhiteSpace($tempPs) -and
                    (Test-Path -LiteralPath $tempPs)) {
                    if (Get-Command ps2pdf -ErrorAction SilentlyContinue) {
                        & ps2pdf $tempPs $OutputPath 2>&1 | Out-Null
                        Remove-Item $tempPs -ErrorAction SilentlyContinue
                        return
                    }
                }
            }
            
            throw "No suitable tool found for DjVu to PDF conversion. Please install ImageMagick or djvulibre."
        }
        catch {
            Write-Error "Failed to convert DjVu to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DjVu to PNG (using ImageMagick or djvulibre)
    Set-Item -Path Function:Global:_ConvertFrom-DjvuToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(djvu|djv)$', '.png'
            }
            
            # Try ImageMagick first
            if (Get-Command magick -ErrorAction SilentlyContinue) {
                $errorOutput = & magick $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            elseif (Get-Command convert -ErrorAction SilentlyContinue) {
                $errorOutput = & convert $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            # Fallback to ddjvu (djvulibre)
            elseif (Get-Command ddjvu -ErrorAction SilentlyContinue) {
                $errorOutput = & ddjvu -format=png $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            throw "No suitable tool found for DjVu to PNG conversion. Please install ImageMagick or djvulibre."
        }
        catch {
            Write-Error "Failed to convert DjVu to PNG: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DjVu to JPEG (using ImageMagick or djvulibre)
    Set-Item -Path Function:Global:_ConvertFrom-DjvuToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(djvu|djv)$', '.jpg'
            }
            
            # Try ImageMagick first
            if (Get-Command magick -ErrorAction SilentlyContinue) {
                $errorOutput = & magick $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            elseif (Get-Command convert -ErrorAction SilentlyContinue) {
                $errorOutput = & convert $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            # Fallback to ddjvu (djvulibre)
            elseif (Get-Command ddjvu -ErrorAction SilentlyContinue) {
                $errorOutput = & ddjvu -format=jpeg $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            throw "No suitable tool found for DjVu to JPEG conversion. Please install ImageMagick or djvulibre."
        }
        catch {
            Write-Error "Failed to convert DjVu to JPEG: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Extract text from DjVu
    Set-Item -Path Function:Global:_ConvertFrom-DjvuToText -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(djvu|djv)$', '.txt'
            }
            
            # Use djvutxt (djvulibre) for text extraction
            if (Get-Command djvutxt -ErrorAction SilentlyContinue) {
                $errorOutput = & djvutxt $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
                else {
                    $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                    throw "djvutxt failed with exit code $exitCode : $errorMessage"
                }
            }
            else {
                throw "djvutxt command not found. Please install djvulibre to extract text from DjVu files."
            }
        }
        catch {
            Write-Error "Failed to extract text from DjVu: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert DjVu to PDF
<#
.SYNOPSIS
    Converts DjVu file to PDF.
.DESCRIPTION
    Converts a DjVu document file to PDF format using ImageMagick or djvulibre tools.
.PARAMETER InputPath
    The path to the DjVu file (.djvu or .djv extension).
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-DjvuToPdf -InputPath "document.djvu"
    
    Converts document.djvu to document.pdf.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-DjvuToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-DjvuToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-DjvuToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-DjvuToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DjVu to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name djvu-to-pdf -Value ConvertFrom-DjvuToPdf -ErrorAction SilentlyContinue

# Convert DjVu to PNG
<#
.SYNOPSIS
    Converts DjVu file to PNG.
.DESCRIPTION
    Converts a DjVu document file to PNG image format using ImageMagick or djvulibre tools.
.PARAMETER InputPath
    The path to the DjVu file (.djvu or .djv extension).
.PARAMETER OutputPath
    The path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-DjvuToPng -InputPath "document.djvu"
    
    Converts document.djvu to document.png.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-DjvuToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-DjvuToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-DjvuToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-DjvuToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DjVu to PNG: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name djvu-to-png -Value ConvertFrom-DjvuToPng -ErrorAction SilentlyContinue

# Convert DjVu to JPEG
<#
.SYNOPSIS
    Converts DjVu file to JPEG.
.DESCRIPTION
    Converts a DjVu document file to JPEG image format using ImageMagick or djvulibre tools.
.PARAMETER InputPath
    The path to the DjVu file (.djvu or .djv extension).
.PARAMETER OutputPath
    The path for the output JPEG file. If not specified, uses input path with .jpg extension.
.EXAMPLE
    ConvertFrom-DjvuToJpeg -InputPath "document.djvu"
    
    Converts document.djvu to document.jpg.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-DjvuToJpeg {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-DjvuToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-DjvuToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-DjvuToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DjVu to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name djvu-to-jpeg -Value ConvertFrom-DjvuToJpeg -ErrorAction SilentlyContinue
Set-Alias -Name djvu-to-jpg -Value ConvertFrom-DjvuToJpeg -ErrorAction SilentlyContinue

# Extract text from DjVu
<#
.SYNOPSIS
    Extracts text from DjVu file.
.DESCRIPTION
    Extracts text content from a DjVu document file using djvutxt tool.
.PARAMETER InputPath
    The path to the DjVu file (.djvu or .djv extension).
.PARAMETER OutputPath
    The path for the output text file. If not specified, uses input path with .txt extension.
.EXAMPLE
    ConvertFrom-DjvuToText -InputPath "document.djvu"
    
    Extracts text from document.djvu to document.txt.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-DjvuToText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-DjvuToText -ErrorAction SilentlyContinue) {
            _ConvertFrom-DjvuToText @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-DjvuToText not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to extract text from DjVu: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name djvu-to-text -Value ConvertFrom-DjvuToText -ErrorAction SilentlyContinue

