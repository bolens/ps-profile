# ===============================================
# PDF media format conversion utilities
# PDF to text extraction and PDF merging
# ===============================================

<#
.SYNOPSIS
    Initializes PDF media format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for PDF format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaPdf {
    # PDF to text
    Set-Item -Path Function:Global:_ConvertFrom-PdfToText -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.pdf$', '.txt' }
            pdftotext $InputPath $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to convert PDF to text: $_"
        }
    } -Force

    # PDF merge
    Set-Item -Path Function:Global:_Merge-Pdf -Value {
        param([string[]]$InputPaths, [string]$OutputPath)
        try {
            pdftk $InputPaths cat output $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to merge PDF files: $_"
        }
    } -Force
}

# Convert PDF to text
<#
.SYNOPSIS
    Extracts text from PDF file.
.DESCRIPTION
    Uses pdftotext to extract plain text from a PDF file.
.PARAMETER InputPath
    The path to the PDF file.
.PARAMETER OutputPath
    The path for the output text file. If not specified, uses input path with .txt extension.
#>
function ConvertFrom-PdfToText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _ConvertFrom-PdfToText @PSBoundParameters
}
Set-Alias -Name pdf-to-text -Value ConvertFrom-PdfToText -ErrorAction SilentlyContinue

# Merge PDF files
<#
.SYNOPSIS
    Merges multiple PDF files.
.DESCRIPTION
    Uses pdftk to combine multiple PDF files into one.
.PARAMETER InputPaths
    Array of paths to PDF files to merge.
.PARAMETER OutputPath
    The path for the output merged PDF file.
#>
function Merge-Pdf {
    param([string[]]$InputPaths, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _Merge-Pdf @PSBoundParameters
}
Set-Alias -Name pdf-merge -Value Merge-Pdf -ErrorAction SilentlyContinue

