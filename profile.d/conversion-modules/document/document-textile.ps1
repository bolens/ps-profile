# ===============================================
# Textile document format conversion utilities
# Textile ↔ Markdown, HTML, PDF, DOCX, LaTeX
# ===============================================

<#
.SYNOPSIS
    Initializes Textile document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Textile format conversions.
    Textile is a lightweight markup language for writing structured text.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc for conversions.
#>
function Initialize-FileConversion-DocumentTextile {
    # Textile to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-TextileToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.textile$|\.tx$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f textile -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Textile to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Textile to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Textile to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromTextile -Value {
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
                $OutputPath = $InputPath -replace '\.textile$|\.tx$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f textile -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Textile to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Textile to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Textile to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromTextile -Value {
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
                $OutputPath = $InputPath -replace '\.textile$|\.tx$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f textile $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Textile to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Textile to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Textile to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromTextile -Value {
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
                $OutputPath = $InputPath -replace '\.textile$|\.tx$', '.docx'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f textile $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Textile to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Textile to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Textile to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromTextile -Value {
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
                $OutputPath = $InputPath -replace '\.textile$|\.tx$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f textile $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Textile to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Textile to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert Textile to Markdown
<#
.SYNOPSIS
    Converts Textile file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a Textile file to Markdown format.
.PARAMETER InputPath
    The path to the Textile file (.textile or .tx extension).
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-TextileToMarkdown -InputPath "document.textile"
    
    Converts document.textile to document.md.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-TextileToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-TextileToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-TextileToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-TextileToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Textile to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name textile-to-markdown -Value ConvertFrom-TextileToMarkdown -ErrorAction SilentlyContinue

# Convert Textile to HTML
<#
.SYNOPSIS
    Converts Textile file to HTML.
.DESCRIPTION
    Uses pandoc to convert a Textile file to HTML format.
.PARAMETER InputPath
    The path to the Textile file (.textile or .tx extension).
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertTo-HtmlFromTextile -InputPath "document.textile"
    
    Converts document.textile to document.html.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-HtmlFromTextile {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromTextile -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromTextile @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromTextile not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Textile to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name textile-to-html -Value ConvertTo-HtmlFromTextile -ErrorAction SilentlyContinue

# Convert Textile to PDF
<#
.SYNOPSIS
    Converts Textile file to PDF.
.DESCRIPTION
    Uses pandoc to convert a Textile file to PDF format.
.PARAMETER InputPath
    The path to the Textile file (.textile or .tx extension).
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertTo-PdfFromTextile -InputPath "document.textile"
    
    Converts document.textile to document.pdf.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-PdfFromTextile {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromTextile -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromTextile @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromTextile not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Textile to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name textile-to-pdf -Value ConvertTo-PdfFromTextile -ErrorAction SilentlyContinue

# Convert Textile to DOCX
<#
.SYNOPSIS
    Converts Textile file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a Textile file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the Textile file (.textile or .tx extension).
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertTo-DocxFromTextile -InputPath "document.textile"
    
    Converts document.textile to document.docx.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-DocxFromTextile {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-DocxFromTextile -ErrorAction SilentlyContinue) {
            _ConvertTo-DocxFromTextile @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-DocxFromTextile not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Textile to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name textile-to-docx -Value ConvertTo-DocxFromTextile -ErrorAction SilentlyContinue

# Convert Textile to LaTeX
<#
.SYNOPSIS
    Converts Textile file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a Textile file to LaTeX format.
.PARAMETER InputPath
    The path to the Textile file (.textile or .tx extension).
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
.EXAMPLE
    ConvertTo-LaTeXFromTextile -InputPath "document.textile"
    
    Converts document.textile to document.tex.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-LaTeXFromTextile {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromTextile -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromTextile @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromTextile not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Textile to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name textile-to-latex -Value ConvertTo-LaTeXFromTextile -ErrorAction SilentlyContinue

