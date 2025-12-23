# ===============================================
# AsciiDoc format conversion utilities
# AsciiDoc ↔ Markdown, HTML, PDF, DOCX, LaTeX
# ===============================================

<#
.SYNOPSIS
    Initializes AsciiDoc document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for AsciiDoc format conversions.
    AsciiDoc is a text document format for writing notes, documentation, articles, books, etc.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc or asciidoc tools for conversions. AsciiDoc files use .adoc, .asciidoc, or .txt extensions.
#>
function Initialize-FileConversion-DocumentOfficeAsciidoc {
    # AsciiDoc to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-AsciidocToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(adoc|asciidoc)$', '.md'
            }
            
            # Try pandoc first
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc -f asciidoc -t markdown $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            # Fallback to asciidoc command (if available)
            if (Get-Command asciidoc -ErrorAction SilentlyContinue) {
                # asciidoc doesn't directly convert to markdown, so we'd need an intermediate step
                # For now, just indicate that pandoc is preferred
                throw "pandoc is required for AsciiDoc to Markdown conversion. Please install pandoc."
            }
            
            throw "Neither pandoc nor asciidoc found. Please install pandoc to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert AsciiDoc to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # AsciiDoc to HTML
    Set-Item -Path Function:Global:_ConvertFrom-AsciidocToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(adoc|asciidoc)$', '.html'
            }
            
            # Try pandoc first
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc -f asciidoc -t html $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            # Fallback to asciidoc command
            if (Get-Command asciidoc -ErrorAction SilentlyContinue) {
                $errorOutput = & asciidoc -b html5 -o $OutputPath $InputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            throw "Neither pandoc nor asciidoc found. Please install one of them to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert AsciiDoc to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # AsciiDoc to PDF
    Set-Item -Path Function:Global:_ConvertFrom-AsciidocToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(adoc|asciidoc)$', '.pdf'
            }
            
            # Try pandoc first
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            # Fallback to asciidoctor-pdf (if available)
            if (Get-Command asciidoctor-pdf -ErrorAction SilentlyContinue) {
                $errorOutput = & asciidoctor-pdf -o $OutputPath $InputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            throw "Neither pandoc nor asciidoctor-pdf found. Please install one of them to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert AsciiDoc to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # AsciiDoc to DOCX
    Set-Item -Path Function:Global:_ConvertFrom-AsciidocToDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(adoc|asciidoc)$', '.docx'
            }
            
            $errorOutput = & pandoc -f asciidoc -t docx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting AsciiDoc to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert AsciiDoc to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # AsciiDoc to LaTeX
    Set-Item -Path Function:Global:_ConvertFrom-AsciidocToLatex -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(adoc|asciidoc)$', '.tex'
            }
            
            $errorOutput = & pandoc -f asciidoc -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting AsciiDoc to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert AsciiDoc to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to AsciiDoc
    Set-Item -Path Function:Global:_ConvertTo-AsciidocFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', '.adoc'
            }
            
            $errorOutput = & pandoc -f markdown -t asciidoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to AsciiDoc. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to AsciiDoc: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts AsciiDoc file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an AsciiDoc file to Markdown format.
.PARAMETER InputPath
    Path to the input AsciiDoc file.
.PARAMETER OutputPath
    Path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-AsciidocToMarkdown -InputPath "document.adoc" -OutputPath "document.md"
#>
function ConvertFrom-AsciidocToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-AsciidocToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-AsciidocToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AsciidocToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AsciiDoc to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'asciidoc-to-markdown' -Target 'ConvertFrom-AsciidocToMarkdown'
    Set-AgentModeAlias -Name 'adoc-to-markdown' -Target 'ConvertFrom-AsciidocToMarkdown'
}
else {
    Set-Alias -Name asciidoc-to-markdown -Value ConvertFrom-AsciidocToMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name adoc-to-markdown -Value ConvertFrom-AsciidocToMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AsciiDoc file to HTML.
.DESCRIPTION
    Uses pandoc or asciidoc to convert an AsciiDoc file to HTML format.
.PARAMETER InputPath
    Path to the input AsciiDoc file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-AsciidocToHtml -InputPath "document.adoc" -OutputPath "document.html"
#>
function ConvertFrom-AsciidocToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-AsciidocToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-AsciidocToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AsciidocToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AsciiDoc to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'asciidoc-to-html' -Target 'ConvertFrom-AsciidocToHtml'
    Set-AgentModeAlias -Name 'adoc-to-html' -Target 'ConvertFrom-AsciidocToHtml'
}
else {
    Set-Alias -Name asciidoc-to-html -Value ConvertFrom-AsciidocToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name adoc-to-html -Value ConvertFrom-AsciidocToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AsciiDoc file to PDF.
.DESCRIPTION
    Uses pandoc or asciidoctor-pdf to convert an AsciiDoc file to PDF format.
.PARAMETER InputPath
    Path to the input AsciiDoc file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-AsciidocToPdf -InputPath "document.adoc" -OutputPath "document.pdf"
#>
function ConvertFrom-AsciidocToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-AsciidocToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-AsciidocToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AsciidocToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AsciiDoc to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'asciidoc-to-pdf' -Target 'ConvertFrom-AsciidocToPdf'
    Set-AgentModeAlias -Name 'adoc-to-pdf' -Target 'ConvertFrom-AsciidocToPdf'
}
else {
    Set-Alias -Name asciidoc-to-pdf -Value ConvertFrom-AsciidocToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name adoc-to-pdf -Value ConvertFrom-AsciidocToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AsciiDoc file to DOCX.
.DESCRIPTION
    Uses pandoc to convert an AsciiDoc file to Microsoft Word DOCX format.
.PARAMETER InputPath
    Path to the input AsciiDoc file.
.PARAMETER OutputPath
    Path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertFrom-AsciidocToDocx -InputPath "document.adoc" -OutputPath "document.docx"
#>
function ConvertFrom-AsciidocToDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-AsciidocToDocx -ErrorAction SilentlyContinue) {
            _ConvertFrom-AsciidocToDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AsciidocToDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AsciiDoc to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'asciidoc-to-docx' -Target 'ConvertFrom-AsciidocToDocx'
    Set-AgentModeAlias -Name 'adoc-to-docx' -Target 'ConvertFrom-AsciidocToDocx'
}
else {
    Set-Alias -Name asciidoc-to-docx -Value ConvertFrom-AsciidocToDocx -ErrorAction SilentlyContinue
    Set-Alias -Name adoc-to-docx -Value ConvertFrom-AsciidocToDocx -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AsciiDoc file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an AsciiDoc file to LaTeX format.
.PARAMETER InputPath
    Path to the input AsciiDoc file.
.PARAMETER OutputPath
    Path for the output LaTeX file. If not specified, uses input path with .tex extension.
.EXAMPLE
    ConvertFrom-AsciidocToLatex -InputPath "document.adoc" -OutputPath "document.tex"
#>
function ConvertFrom-AsciidocToLatex {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-AsciidocToLatex -ErrorAction SilentlyContinue) {
            _ConvertFrom-AsciidocToLatex @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AsciidocToLatex not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AsciiDoc to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'asciidoc-to-latex' -Target 'ConvertFrom-AsciidocToLatex'
    Set-AgentModeAlias -Name 'adoc-to-latex' -Target 'ConvertFrom-AsciidocToLatex'
}
else {
    Set-Alias -Name asciidoc-to-latex -Value ConvertFrom-AsciidocToLatex -ErrorAction SilentlyContinue
    Set-Alias -Name adoc-to-latex -Value ConvertFrom-AsciidocToLatex -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Markdown file to AsciiDoc.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to AsciiDoc format.
.PARAMETER InputPath
    Path to the input Markdown file.
.PARAMETER OutputPath
    Path for the output AsciiDoc file. If not specified, uses input path with .adoc extension.
.EXAMPLE
    ConvertTo-AsciidocFromMarkdown -InputPath "document.md" -OutputPath "document.adoc"
#>
function ConvertTo-AsciidocFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-AsciidocFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-AsciidocFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-AsciidocFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to AsciiDoc: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-asciidoc' -Target 'ConvertTo-AsciidocFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-asciidoc' -Target 'ConvertTo-AsciidocFromMarkdown'
    Set-AgentModeAlias -Name 'markdown-to-adoc' -Target 'ConvertTo-AsciidocFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-adoc' -Target 'ConvertTo-AsciidocFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-asciidoc -Value ConvertTo-AsciidocFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-asciidoc -Value ConvertTo-AsciidocFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name markdown-to-adoc -Value ConvertTo-AsciidocFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-adoc -Value ConvertTo-AsciidocFromMarkdown -ErrorAction SilentlyContinue
}

