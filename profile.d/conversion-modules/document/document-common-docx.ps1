# ===============================================
# DOCX document format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes DOCX document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for DOCX (Microsoft Word) format conversions.
    Supports conversions from DOCX to Markdown, HTML, PDF, and LaTeX.
    This function is called automatically by Initialize-FileConversion-DocumentCommon.
.NOTES
    This is an internal initialization function and should not be called directly.
    All conversions use pandoc as the underlying tool.
#>
function Initialize-FileConversion-DocumentCommonDocx {
    # DOCX to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-DocxToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.docx$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f docx -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting DOCX to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DOCX to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.docx$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f docx -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting DOCX to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DOCX to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.docx$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting DOCX to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DOCX to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.docx$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f docx -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting DOCX to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert DOCX to Markdown
<#
.SYNOPSIS
    Converts DOCX file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a DOCX file to Markdown format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-DocxToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-DocxToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-DocxToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-DocxToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DOCX to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name docx-to-markdown -Value ConvertFrom-DocxToMarkdown -ErrorAction SilentlyContinue

# Convert DOCX to HTML
<#
.SYNOPSIS
    Converts DOCX file to HTML.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to HTML format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromDocx -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DOCX to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name docx-to-html -Value ConvertTo-HtmlFromDocx -ErrorAction SilentlyContinue

# Convert DOCX to PDF
<#
.SYNOPSIS
    Converts DOCX file to PDF.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to PDF format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromDocx -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DOCX to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name docx-to-pdf -Value ConvertTo-PdfFromDocx -ErrorAction SilentlyContinue

# Convert DOCX to LaTeX
<#
.SYNOPSIS
    Converts DOCX file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to LaTeX format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromDocx -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DOCX to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name docx-to-latex -Value ConvertTo-LaTeXFromDocx -ErrorAction SilentlyContinue

