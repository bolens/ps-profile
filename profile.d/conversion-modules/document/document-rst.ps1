# ===============================================
# RST (reStructuredText) document format conversion utilities
# RST ↔ Markdown, HTML, PDF, DOCX, LaTeX
# ===============================================

<#
.SYNOPSIS
    Initializes RST document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for RST format conversions.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-DocumentRst {
    # RST to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-RstToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            
            Ensure-DocumentLatexEngine | Out-Null
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rst$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f rst -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert RST to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RST to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromRst -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rst$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f rst -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert RST to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RST to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromRst -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rst$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert RST to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RST to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromRst -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rst$', '.docx'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert RST to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RST to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromRst -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            # Validate inputs
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rst$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert RST to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert RST to Markdown
<#
.SYNOPSIS
    Converts RST file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to Markdown format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-RstToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-RstToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-RstToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-RstToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RST to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name rst-to-markdown -Value ConvertFrom-RstToMarkdown -ErrorAction SilentlyContinue

# Convert RST to HTML
<#
.SYNOPSIS
    Converts RST file to HTML.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to HTML format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromRst -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromRst @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromRst not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RST to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name rst-to-html -Value ConvertTo-HtmlFromRst -ErrorAction SilentlyContinue

# Convert RST to PDF
<#
.SYNOPSIS
    Converts RST file to PDF.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to PDF format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromRst -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromRst @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromRst not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RST to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name rst-to-pdf -Value ConvertTo-PdfFromRst -ErrorAction SilentlyContinue

# Convert RST to DOCX
<#
.SYNOPSIS
    Converts RST file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
#>
function ConvertTo-DocxFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-DocxFromRst -ErrorAction SilentlyContinue) {
            _ConvertTo-DocxFromRst @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-DocxFromRst not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RST to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name rst-to-docx -Value ConvertTo-DocxFromRst -ErrorAction SilentlyContinue

# Convert RST to LaTeX
<#
.SYNOPSIS
    Converts RST file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to LaTeX format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromRst -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromRst @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromRst not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RST to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name rst-to-latex -Value ConvertTo-LaTeXFromRst -ErrorAction SilentlyContinue

