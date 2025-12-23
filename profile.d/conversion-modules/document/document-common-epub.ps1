# ===============================================
# EPUB document format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes EPUB document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for EPUB format conversions.
    Supports conversions from EPUB to Markdown, HTML, PDF, and LaTeX.
    This function is called automatically by Initialize-FileConversion-DocumentCommon.
.NOTES
    This is an internal initialization function and should not be called directly.
    All conversions use pandoc as the underlying tool.
#>
function Initialize-FileConversion-DocumentCommonEpub {
    # EPUB to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-EpubToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f epub -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting EPUB to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to HTML
    Set-Item -Path Function:Global:_ConvertFrom-EpubToHtml -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f epub -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting EPUB to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to PDF
    Set-Item -Path Function:Global:_ConvertFrom-EpubToPdf -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting EPUB to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to LaTeX
    Set-Item -Path Function:Global:_ConvertFrom-EpubToLatex -Value {
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
                $OutputPath = $InputPath -replace '\.epub$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f epub -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting EPUB to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to DOCX
    Set-Item -Path Function:Global:_ConvertFrom-EpubToDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.epub$', '.docx'
            }
            
            $errorOutput = & pandoc -f epub -t docx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting EPUB to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert EPUB to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to EPUB
    Set-Item -Path Function:Global:_ConvertTo-EpubFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', '.epub'
            }
            
            $errorOutput = & pandoc -f markdown -t epub $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to EPUB. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to EPUB: $($_.Exception.Message)"
            throw
        }
    } -Force

    # HTML to EPUB
    Set-Item -Path Function:Global:_ConvertTo-EpubFromHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.html$', '.epub'
            }
            
            $errorOutput = & pandoc -f html -t epub $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting HTML to EPUB. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert HTML to EPUB: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
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
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'epub-to-markdown' -Target 'ConvertFrom-EpubToMarkdown'
}
else {
    Set-Alias -Name epub-to-markdown -Value ConvertFrom-EpubToMarkdown -ErrorAction SilentlyContinue
}

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
function ConvertFrom-EpubToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-EpubToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-EpubToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EpubToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'epub-to-html' -Target 'ConvertFrom-EpubToHtml'
}
else {
    Set-Alias -Name epub-to-html -Value ConvertFrom-EpubToHtml -ErrorAction SilentlyContinue
}

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
function ConvertFrom-EpubToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-EpubToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-EpubToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EpubToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'epub-to-pdf' -Target 'ConvertFrom-EpubToPdf'
}
else {
    Set-Alias -Name epub-to-pdf -Value ConvertFrom-EpubToPdf -ErrorAction SilentlyContinue
}

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
function ConvertFrom-EpubToLatex {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-EpubToLatex -ErrorAction SilentlyContinue) {
            _ConvertFrom-EpubToLatex @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EpubToLatex not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'epub-to-latex' -Target 'ConvertFrom-EpubToLatex'
}
else {
    Set-Alias -Name epub-to-latex -Value ConvertFrom-EpubToLatex -ErrorAction SilentlyContinue
}

# Convert EPUB to DOCX
<#
.SYNOPSIS
    Converts EPUB file to DOCX.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertFrom-EpubToDocx -InputPath "book.epub" -OutputPath "book.docx"
#>
function ConvertFrom-EpubToDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-EpubToDocx -ErrorAction SilentlyContinue) {
            _ConvertFrom-EpubToDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EpubToDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'epub-to-docx' -Target 'ConvertFrom-EpubToDocx'
}
else {
    Set-Alias -Name epub-to-docx -Value ConvertFrom-EpubToDocx -ErrorAction SilentlyContinue
}

# Convert Markdown to EPUB
<#
.SYNOPSIS
    Converts Markdown file to EPUB.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to EPUB (e-book) format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output EPUB file. If not specified, uses input path with .epub extension.
.EXAMPLE
    ConvertTo-EpubFromMarkdown -InputPath "book.md" -OutputPath "book.epub"
#>
function ConvertTo-EpubFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-EpubFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-EpubFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-EpubFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to EPUB: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-epub' -Target 'ConvertTo-EpubFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-epub' -Target 'ConvertTo-EpubFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-epub -Value ConvertTo-EpubFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-epub -Value ConvertTo-EpubFromMarkdown -ErrorAction SilentlyContinue
}

# Convert HTML to EPUB
<#
.SYNOPSIS
    Converts HTML file to EPUB.
.DESCRIPTION
    Uses pandoc to convert an HTML file to EPUB (e-book) format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output EPUB file. If not specified, uses input path with .epub extension.
.EXAMPLE
    ConvertTo-EpubFromHtml -InputPath "book.html" -OutputPath "book.epub"
#>
function ConvertTo-EpubFromHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-EpubFromHtml -ErrorAction SilentlyContinue) {
            _ConvertTo-EpubFromHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-EpubFromHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HTML to EPUB: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'html-to-epub' -Target 'ConvertTo-EpubFromHtml'
}
else {
    Set-Alias -Name html-to-epub -Value ConvertTo-EpubFromHtml -ErrorAction SilentlyContinue
}

