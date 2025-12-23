# ===============================================
# FB2 (FictionBook) e-book format conversion utilities
# FB2 ↔ Markdown, HTML, PDF, DOCX, LaTeX
# ===============================================

<#
.SYNOPSIS
    Initializes FB2 (FictionBook) e-book format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for FB2 format conversions.
    FB2 is an XML-based e-book format used primarily in Russia and Eastern Europe.
    Supports conversions between FB2 and Markdown, HTML, PDF, DOCX, LaTeX formats.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc for conversions (pandoc supports FB2 format).
    FB2 files are XML-based with .fb2 or .fbz (compressed) extensions.
#>
function Initialize-FileConversion-DocumentFb2 {
    # FB2 to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-Fb2ToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            
            Ensure-DocumentLatexEngine | Out-Null
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(fb2|fbz)$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f fb2 -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting FB2 to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert FB2 to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # FB2 to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromFb2 -Value {
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
                $OutputPath = $InputPath -replace '\.(fb2|fbz)$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f fb2 -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting FB2 to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert FB2 to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # FB2 to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromFb2 -Value {
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
                $OutputPath = $InputPath -replace '\.(fb2|fbz)$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f fb2 $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting FB2 to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert FB2 to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # FB2 to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromFb2 -Value {
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
                $OutputPath = $InputPath -replace '\.(fb2|fbz)$', '.docx'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f fb2 $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting FB2 to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert FB2 to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # FB2 to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromFb2 -Value {
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
                $OutputPath = $InputPath -replace '\.(fb2|fbz)$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f fb2 $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting FB2 to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert FB2 to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert FB2 to Markdown
<#
.SYNOPSIS
    Converts FB2 file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a FictionBook (FB2) e-book file to Markdown format.
.PARAMETER InputPath
    The path to the FB2 file (.fb2 or .fbz extension).
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-Fb2ToMarkdown -InputPath "book.fb2"
    
    Converts book.fb2 to book.md.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-Fb2ToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-Fb2ToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-Fb2ToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-Fb2ToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FB2 to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name fb2-to-markdown -Value ConvertFrom-Fb2ToMarkdown -ErrorAction SilentlyContinue

# Convert FB2 to HTML
<#
.SYNOPSIS
    Converts FB2 file to HTML.
.DESCRIPTION
    Uses pandoc to convert a FictionBook (FB2) e-book file to HTML format.
.PARAMETER InputPath
    The path to the FB2 file (.fb2 or .fbz extension).
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertTo-HtmlFromFb2 -InputPath "book.fb2"
    
    Converts book.fb2 to book.html.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-HtmlFromFb2 {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromFb2 -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromFb2 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromFb2 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FB2 to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name fb2-to-html -Value ConvertTo-HtmlFromFb2 -ErrorAction SilentlyContinue

# Convert FB2 to PDF
<#
.SYNOPSIS
    Converts FB2 file to PDF.
.DESCRIPTION
    Uses pandoc to convert a FictionBook (FB2) e-book file to PDF format.
.PARAMETER InputPath
    The path to the FB2 file (.fb2 or .fbz extension).
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertTo-PdfFromFb2 -InputPath "book.fb2"
    
    Converts book.fb2 to book.pdf.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-PdfFromFb2 {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromFb2 -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromFb2 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromFb2 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FB2 to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name fb2-to-pdf -Value ConvertTo-PdfFromFb2 -ErrorAction SilentlyContinue

# Convert FB2 to DOCX
<#
.SYNOPSIS
    Converts FB2 file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a FictionBook (FB2) e-book file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the FB2 file (.fb2 or .fbz extension).
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertTo-DocxFromFb2 -InputPath "book.fb2"
    
    Converts book.fb2 to book.docx.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-DocxFromFb2 {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-DocxFromFb2 -ErrorAction SilentlyContinue) {
            _ConvertTo-DocxFromFb2 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-DocxFromFb2 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FB2 to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name fb2-to-docx -Value ConvertTo-DocxFromFb2 -ErrorAction SilentlyContinue

# Convert FB2 to LaTeX
<#
.SYNOPSIS
    Converts FB2 file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a FictionBook (FB2) e-book file to LaTeX format.
.PARAMETER InputPath
    The path to the FB2 file (.fb2 or .fbz extension).
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
.EXAMPLE
    ConvertTo-LaTeXFromFb2 -InputPath "book.fb2"
    
    Converts book.fb2 to book.tex.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-LaTeXFromFb2 {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromFb2 -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromFb2 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromFb2 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FB2 to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name fb2-to-latex -Value ConvertTo-LaTeXFromFb2 -ErrorAction SilentlyContinue

