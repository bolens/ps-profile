# ===============================================
# HTML document format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes HTML document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HTML format conversions.
    Supports conversions from HTML to Markdown, PDF, and LaTeX.
    This function is called automatically by Initialize-FileConversion-DocumentCommon.
.NOTES
    This is an internal initialization function and should not be called directly.
    All conversions use pandoc as the underlying tool.
#>
function Initialize-FileConversion-DocumentCommonHtml {
    # HTML to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-HtmlToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.html$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f html -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting HTML to Markdown. Error: $errorText"
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
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
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
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting HTML to PDF. Error: $errorText"
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
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
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
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting HTML to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert HTML to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
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
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'html-to-markdown' -Target 'ConvertFrom-HtmlToMarkdown'
}
else {
    Set-Alias -Name html-to-markdown -Value ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue -Scope Global
}

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
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'html-to-pdf' -Target 'ConvertTo-PdfFromHtml'
}
else {
    Set-Alias -Name html-to-pdf -Value ConvertTo-PdfFromHtml -ErrorAction SilentlyContinue -Scope Global
}

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
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'html-to-latex' -Target 'ConvertTo-LaTeXFromHtml'
}
else {
    Set-Alias -Name html-to-latex -Value ConvertTo-LaTeXFromHtml -ErrorAction SilentlyContinue -Scope Global
}

