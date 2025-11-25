# ===============================================
# Common document format conversion utilities
# HTML, PDF, DOCX, EPUB conversions
# ===============================================

<#
.SYNOPSIS
    Initializes common document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HTML, PDF, DOCX, and EPUB format conversions.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-DocumentCommon {
    # HTML to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-HtmlToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.html$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f html -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert HTML to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # HTML to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromHtml -Value {
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
                $OutputPath = $InputPath -replace '\.html?$', '.pdf'
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
            Write-Error "Failed to convert HTML to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # HTML to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromHtml -Value {
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
                $OutputPath = $InputPath -replace '\.html?$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f html -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert HTML to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DOCX to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-DocxToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.docx$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f docx -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
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
            if (-not (Test-Path $InputPath)) {
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
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
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
            if (-not (Test-Path $InputPath)) {
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
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
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
            if (-not (Test-Path $InputPath)) {
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
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-EpubToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f epub -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromEpub -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f epub -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromEpub -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.pdf'
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
            Write-Error "Failed to convert EPUB to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromEpub -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f epub -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorMessage = if ($errorOutput) { $errorOutput -join "`n" } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode : $errorMessage"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert HTML to Markdown
<#
.SYNOPSIS
    Converts HTML file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an HTML file to Markdown format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-HtmlToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-HtmlToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-HtmlToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HTML to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name html-to-markdown -Value ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue

# Convert HTML to PDF
<#
.SYNOPSIS
    Converts HTML file to PDF.
.DESCRIPTION
    Uses pandoc to convert an HTML file to PDF format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromHtml -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HTML to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name html-to-pdf -Value ConvertTo-PdfFromHtml -ErrorAction SilentlyContinue

# Convert HTML to LaTeX
<#
.SYNOPSIS
    Converts HTML file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an HTML file to LaTeX format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromHtml -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HTML to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name html-to-latex -Value ConvertTo-LaTeXFromHtml -ErrorAction SilentlyContinue

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

# Convert EPUB to Markdown
<#
.SYNOPSIS
    Converts EPUB file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to Markdown format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-EpubToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-EpubToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-EpubToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EpubToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name epub-to-markdown -Value ConvertFrom-EpubToMarkdown -ErrorAction SilentlyContinue

# Convert EPUB to HTML
<#
.SYNOPSIS
    Converts EPUB file to HTML.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to HTML format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromEpub -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromEpub @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromEpub not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name epub-to-html -Value ConvertTo-HtmlFromEpub -ErrorAction SilentlyContinue

# Convert EPUB to PDF
<#
.SYNOPSIS
    Converts EPUB file to PDF.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to PDF format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromEpub -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromEpub @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromEpub not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name epub-to-pdf -Value ConvertTo-PdfFromEpub -ErrorAction SilentlyContinue

# Convert EPUB to LaTeX
<#
.SYNOPSIS
    Converts EPUB file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to LaTeX format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromEpub -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromEpub @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromEpub not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name epub-to-latex -Value ConvertTo-LaTeXFromEpub -ErrorAction SilentlyContinue

