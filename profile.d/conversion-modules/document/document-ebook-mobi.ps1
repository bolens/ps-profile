# ===============================================
# MOBI/AZW e-book format conversion utilities
# MOBI/AZW ↔ EPUB, PDF, HTML, Markdown
# ===============================================

<#
.SYNOPSIS
    Initializes MOBI/AZW e-book format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for MOBI/AZW format conversions.
    MOBI and AZW are Amazon Kindle e-book formats.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Calibre (ebook-convert) or pandoc for conversions.
    MOBI files use .mobi extension, AZW files use .azw or .azw3 extension.
#>
function Initialize-FileConversion-DocumentEbookMobi {
    # MOBI/AZW to EPUB
    Set-Item -Path Function:Global:_ConvertFrom-MobiToEpub -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(mobi|azw|azw3)$', '.epub'
            }

            $attempts = @()
            
            # Try Calibre ebook-convert first (best support for MOBI/AZW)
            $ebookConvertCmd = Get-Command ebook-convert -ErrorAction SilentlyContinue
            if ($ebookConvertCmd) {
                $errorOutput = & $ebookConvertCmd $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "Calibre ebook-convert failed with exit code $exitCode. Error: $errorText"
            }
            else {
                $attempts += "Calibre ebook-convert command not found."
            }
            
            # Fallback to pandoc (if available)
            $pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
            if ($pandocCmd) {
                $errorOutput = & $pandocCmd -f mobi -t epub $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "pandoc failed with exit code $exitCode when converting MOBI/AZW to EPUB. Error: $errorText"
            }
            else {
                $attempts += "pandoc command not found."
            }
            
            $attemptSummary = $attempts -join "`n - "
            throw "MOBI/AZW to EPUB conversion failed. Attempts:`n - $attemptSummary"
        }
        catch {
            Write-Error "Failed to convert MOBI/AZW to EPUB: $($_.Exception.Message)"
            throw
        }
    } -Force

    # MOBI/AZW to PDF
    Set-Item -Path Function:Global:_ConvertFrom-MobiToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(mobi|azw|azw3)$', '.pdf'
            }

            $attempts = @()
            
            # Try Calibre ebook-convert first
            $ebookConvertCmd = Get-Command ebook-convert -ErrorAction SilentlyContinue
            if ($ebookConvertCmd) {
                $errorOutput = & $ebookConvertCmd $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "Calibre ebook-convert failed with exit code $exitCode. Error: $errorText"
            }
            else {
                $attempts += "Calibre ebook-convert command not found."
            }
            
            # Fallback to pandoc
            $pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
            if ($pandocCmd) {
                $errorOutput = & $pandocCmd $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "pandoc failed with exit code $exitCode when converting MOBI/AZW to PDF. Error: $errorText"
            }
            else {
                $attempts += "pandoc command not found."
            }
            
            $attemptSummary = $attempts -join "`n - "
            throw "MOBI/AZW to PDF conversion failed. Attempts:`n - $attemptSummary"
        }
        catch {
            Write-Error "Failed to convert MOBI/AZW to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # MOBI/AZW to HTML
    Set-Item -Path Function:Global:_ConvertFrom-MobiToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(mobi|azw|azw3)$', '.html'
            }

            $attempts = @()
            
            # Try Calibre ebook-convert first
            $ebookConvertCmd = Get-Command ebook-convert -ErrorAction SilentlyContinue
            if ($ebookConvertCmd) {
                $errorOutput = & $ebookConvertCmd $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "Calibre ebook-convert failed with exit code $exitCode. Error: $errorText"
            }
            else {
                $attempts += "Calibre ebook-convert command not found."
            }
            
            # Fallback to pandoc
            $pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
            if ($pandocCmd) {
                $errorOutput = & $pandocCmd -f mobi -t html $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "pandoc failed with exit code $exitCode when converting MOBI/AZW to HTML. Error: $errorText"
            }
            else {
                $attempts += "pandoc command not found."
            }
            
            $attemptSummary = $attempts -join "`n - "
            throw "MOBI/AZW to HTML conversion failed. Attempts:`n - $attemptSummary"
        }
        catch {
            Write-Error "Failed to convert MOBI/AZW to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # MOBI/AZW to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-MobiToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(mobi|azw|azw3)$', '.md'
            }
            
            $errorOutput = & pandoc -f mobi -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting MOBI/AZW to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert MOBI/AZW to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # EPUB to MOBI/AZW
    Set-Item -Path Function:Global:_ConvertTo-MobiFromEpub -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Format = 'mobi')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $ext = if ($Format -eq 'azw3') { '.azw3' } elseif ($Format -eq 'azw') { '.azw' } else { '.mobi' }
                $OutputPath = $InputPath -replace '\.epub$', $ext
            }

            $attempts = @()
            
            # Try Calibre ebook-convert first (best support)
            $ebookConvertCmd = Get-Command ebook-convert -ErrorAction SilentlyContinue
            if ($ebookConvertCmd) {
                $errorOutput = & $ebookConvertCmd $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "Calibre ebook-convert failed with exit code $exitCode. Error: $errorText"
            }
            else {
                $attempts += "Calibre ebook-convert command not found."
            }
            
            # Fallback to pandoc (if available)
            $pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
            if ($pandocCmd) {
                $errorOutput = & $pandocCmd -f epub -t mobi $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "pandoc failed with exit code $exitCode when converting EPUB to MOBI/AZW. Error: $errorText"
            }
            else {
                $attempts += "pandoc command not found."
            }
            
            $attemptSummary = $attempts -join "`n - "
            throw "EPUB to MOBI/AZW conversion failed. Attempts:`n - $attemptSummary"
        }
        catch {
            Write-Error "Failed to convert EPUB to MOBI/AZW: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to MOBI/AZW
    Set-Item -Path Function:Global:_ConvertTo-MobiFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Format = 'mobi')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $ext = if ($Format -eq 'azw3') { '.azw3' } elseif ($Format -eq 'azw') { '.azw' } else { '.mobi' }
                $OutputPath = $InputPath -replace '\.(md|markdown)$', $ext
            }

            $attempts = @()
            
            # Try Calibre ebook-convert first
            $ebookConvertCmd = Get-Command ebook-convert -ErrorAction SilentlyContinue
            if ($ebookConvertCmd) {
                $errorOutput = & $ebookConvertCmd $InputPath $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "Calibre ebook-convert failed with exit code $exitCode. Error: $errorText"
            }
            else {
                $attempts += "Calibre ebook-convert command not found."
            }
            
            # Fallback to pandoc
            $pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
            if ($pandocCmd) {
                $errorOutput = & $pandocCmd -f markdown -t mobi $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }

                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'No additional error output.' }
                $attempts += "pandoc failed with exit code $exitCode when converting Markdown to MOBI/AZW. Error: $errorText"
            }
            else {
                $attempts += "pandoc command not found."
            }
            
            $attemptSummary = $attempts -join "`n - "
            throw "Markdown to MOBI/AZW conversion failed. Attempts:`n - $attemptSummary"
        }
        catch {
            Write-Error "Failed to convert Markdown to MOBI/AZW: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts MOBI/AZW file to EPUB.
.DESCRIPTION
    Uses Calibre or pandoc to convert a MOBI/AZW file to EPUB format.
.PARAMETER InputPath
    Path to the input MOBI/AZW file.
.PARAMETER OutputPath
    Path for the output EPUB file. If not specified, uses input path with .epub extension.
.EXAMPLE
    ConvertFrom-MobiToEpub -InputPath "book.mobi" -OutputPath "book.epub"
#>
function ConvertFrom-MobiToEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-MobiToEpub -ErrorAction SilentlyContinue) {
            _ConvertFrom-MobiToEpub @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-MobiToEpub not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MOBI/AZW to EPUB: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mobi-to-epub' -Target 'ConvertFrom-MobiToEpub'
    Set-AgentModeAlias -Name 'azw-to-epub' -Target 'ConvertFrom-MobiToEpub'
    Set-AgentModeAlias -Name 'azw3-to-epub' -Target 'ConvertFrom-MobiToEpub'
}
else {
    Set-Alias -Name mobi-to-epub -Value ConvertFrom-MobiToEpub -ErrorAction SilentlyContinue
    Set-Alias -Name azw-to-epub -Value ConvertFrom-MobiToEpub -ErrorAction SilentlyContinue
    Set-Alias -Name azw3-to-epub -Value ConvertFrom-MobiToEpub -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts MOBI/AZW file to PDF.
.DESCRIPTION
    Uses Calibre or pandoc to convert a MOBI/AZW file to PDF format.
.PARAMETER InputPath
    Path to the input MOBI/AZW file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-MobiToPdf -InputPath "book.mobi" -OutputPath "book.pdf"
#>
function ConvertFrom-MobiToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-MobiToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-MobiToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-MobiToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MOBI/AZW to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mobi-to-pdf' -Target 'ConvertFrom-MobiToPdf'
    Set-AgentModeAlias -Name 'azw-to-pdf' -Target 'ConvertFrom-MobiToPdf'
    Set-AgentModeAlias -Name 'azw3-to-pdf' -Target 'ConvertFrom-MobiToPdf'
}
else {
    Set-Alias -Name mobi-to-pdf -Value ConvertFrom-MobiToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name azw-to-pdf -Value ConvertFrom-MobiToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name azw3-to-pdf -Value ConvertFrom-MobiToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts MOBI/AZW file to HTML.
.DESCRIPTION
    Uses Calibre or pandoc to convert a MOBI/AZW file to HTML format.
.PARAMETER InputPath
    Path to the input MOBI/AZW file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-MobiToHtml -InputPath "book.mobi" -OutputPath "book.html"
#>
function ConvertFrom-MobiToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-MobiToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-MobiToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-MobiToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MOBI/AZW to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mobi-to-html' -Target 'ConvertFrom-MobiToHtml'
    Set-AgentModeAlias -Name 'azw-to-html' -Target 'ConvertFrom-MobiToHtml'
    Set-AgentModeAlias -Name 'azw3-to-html' -Target 'ConvertFrom-MobiToHtml'
}
else {
    Set-Alias -Name mobi-to-html -Value ConvertFrom-MobiToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name azw-to-html -Value ConvertFrom-MobiToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name azw3-to-html -Value ConvertFrom-MobiToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts MOBI/AZW file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a MOBI/AZW file to Markdown format.
.PARAMETER InputPath
    Path to the input MOBI/AZW file.
.PARAMETER OutputPath
    Path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-MobiToMarkdown -InputPath "book.mobi" -OutputPath "book.md"
#>
function ConvertFrom-MobiToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-MobiToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-MobiToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-MobiToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MOBI/AZW to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mobi-to-markdown' -Target 'ConvertFrom-MobiToMarkdown'
    Set-AgentModeAlias -Name 'azw-to-markdown' -Target 'ConvertFrom-MobiToMarkdown'
    Set-AgentModeAlias -Name 'azw3-to-markdown' -Target 'ConvertFrom-MobiToMarkdown'
}
else {
    Set-Alias -Name mobi-to-markdown -Value ConvertFrom-MobiToMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name azw-to-markdown -Value ConvertFrom-MobiToMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name azw3-to-markdown -Value ConvertFrom-MobiToMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts EPUB file to MOBI/AZW.
.DESCRIPTION
    Uses Calibre or pandoc to convert an EPUB file to MOBI/AZW format.
.PARAMETER InputPath
    Path to the input EPUB file.
.PARAMETER OutputPath
    Path for the output MOBI/AZW file. If not specified, uses input path with appropriate extension.
.PARAMETER Format
    Output format: 'mobi', 'azw', or 'azw3' (default: 'mobi').
.EXAMPLE
    ConvertTo-MobiFromEpub -InputPath "book.epub" -OutputPath "book.mobi" -Format mobi
#>
function ConvertTo-MobiFromEpub {
    param([string]$InputPath, [string]$OutputPath, [string]$Format = 'mobi')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-MobiFromEpub -ErrorAction SilentlyContinue) {
            _ConvertTo-MobiFromEpub @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-MobiFromEpub not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EPUB to MOBI/AZW: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'epub-to-mobi' -Target 'ConvertTo-MobiFromEpub'
    Set-AgentModeAlias -Name 'epub-to-azw' -Target 'ConvertTo-MobiFromEpub'
    Set-AgentModeAlias -Name 'epub-to-azw3' -Target 'ConvertTo-MobiFromEpub'
}
else {
    Set-Alias -Name epub-to-mobi -Value ConvertTo-MobiFromEpub -ErrorAction SilentlyContinue
    Set-Alias -Name epub-to-azw -Value ConvertTo-MobiFromEpub -ErrorAction SilentlyContinue
    Set-Alias -Name epub-to-azw3 -Value ConvertTo-MobiFromEpub -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Markdown file to MOBI/AZW.
.DESCRIPTION
    Uses Calibre or pandoc to convert a Markdown file to MOBI/AZW format.
.PARAMETER InputPath
    Path to the input Markdown file.
.PARAMETER OutputPath
    Path for the output MOBI/AZW file. If not specified, uses input path with appropriate extension.
.PARAMETER Format
    Output format: 'mobi', 'azw', or 'azw3' (default: 'mobi').
.EXAMPLE
    ConvertTo-MobiFromMarkdown -InputPath "book.md" -OutputPath "book.mobi" -Format mobi
#>
function ConvertTo-MobiFromMarkdown {
    param([string]$InputPath, [string]$OutputPath, [string]$Format = 'mobi')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-MobiFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-MobiFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to MOBI/AZW: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-mobi' -Target 'ConvertTo-MobiFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-mobi' -Target 'ConvertTo-MobiFromMarkdown'
    Set-AgentModeAlias -Name 'markdown-to-azw' -Target 'ConvertTo-MobiFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-azw' -Target 'ConvertTo-MobiFromMarkdown'
    Set-AgentModeAlias -Name 'markdown-to-azw3' -Target 'ConvertTo-MobiFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-azw3' -Target 'ConvertTo-MobiFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-mobi -Value ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-mobi -Value ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name markdown-to-azw -Value ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-azw -Value ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name markdown-to-azw3 -Value ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-azw3 -Value ConvertTo-MobiFromMarkdown -ErrorAction SilentlyContinue
}

