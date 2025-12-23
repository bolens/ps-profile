# ===============================================
# Org-mode format conversion utilities
# Org-mode ↔ Markdown, HTML, PDF, DOCX, LaTeX
# ===============================================

<#
.SYNOPSIS
    Initializes Org-mode document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Org-mode format conversions.
    Org-mode is a document editing and organizing mode for Emacs.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc for conversions. Org-mode files use .org extension.
#>
function Initialize-FileConversion-DocumentOfficeOrgmode {
    # Org-mode to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-OrgmodeToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.org$', '.md'
            }
            
            $errorOutput = & pandoc -f org -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Org-mode to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Org-mode to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Org-mode to HTML
    Set-Item -Path Function:Global:_ConvertFrom-OrgmodeToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.org$', '.html'
            }
            
            $errorOutput = & pandoc -f org -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Org-mode to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Org-mode to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Org-mode to PDF
    Set-Item -Path Function:Global:_ConvertFrom-OrgmodeToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.org$', '.pdf'
            }
            
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Org-mode to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Org-mode to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Org-mode to DOCX
    Set-Item -Path Function:Global:_ConvertFrom-OrgmodeToDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.org$', '.docx'
            }
            
            $errorOutput = & pandoc -f org -t docx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Org-mode to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Org-mode to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Org-mode to LaTeX
    Set-Item -Path Function:Global:_ConvertFrom-OrgmodeToLatex -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.org$', '.tex'
            }
            
            $errorOutput = & pandoc -f org -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Org-mode to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Org-mode to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to Org-mode
    Set-Item -Path Function:Global:_ConvertTo-OrgmodeFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', '.org'
            }
            
            $errorOutput = & pandoc -f markdown -t org $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to Org-mode. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to Org-mode: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts Org-mode file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an Org-mode file to Markdown format.
.PARAMETER InputPath
    Path to the input Org-mode file.
.PARAMETER OutputPath
    Path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-OrgmodeToMarkdown -InputPath "document.org" -OutputPath "document.md"
#>
function ConvertFrom-OrgmodeToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OrgmodeToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-OrgmodeToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OrgmodeToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Org-mode to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'org-to-markdown' -Target 'ConvertFrom-OrgmodeToMarkdown'
    Set-AgentModeAlias -Name 'orgmode-to-markdown' -Target 'ConvertFrom-OrgmodeToMarkdown'
}
else {
    Set-Alias -Name org-to-markdown -Value ConvertFrom-OrgmodeToMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name orgmode-to-markdown -Value ConvertFrom-OrgmodeToMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Org-mode file to HTML.
.DESCRIPTION
    Uses pandoc to convert an Org-mode file to HTML format.
.PARAMETER InputPath
    Path to the input Org-mode file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-OrgmodeToHtml -InputPath "document.org" -OutputPath "document.html"
#>
function ConvertFrom-OrgmodeToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OrgmodeToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-OrgmodeToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OrgmodeToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Org-mode to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'org-to-html' -Target 'ConvertFrom-OrgmodeToHtml'
    Set-AgentModeAlias -Name 'orgmode-to-html' -Target 'ConvertFrom-OrgmodeToHtml'
}
else {
    Set-Alias -Name org-to-html -Value ConvertFrom-OrgmodeToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name orgmode-to-html -Value ConvertFrom-OrgmodeToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Org-mode file to PDF.
.DESCRIPTION
    Uses pandoc to convert an Org-mode file to PDF format.
.PARAMETER InputPath
    Path to the input Org-mode file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-OrgmodeToPdf -InputPath "document.org" -OutputPath "document.pdf"
#>
function ConvertFrom-OrgmodeToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OrgmodeToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-OrgmodeToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OrgmodeToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Org-mode to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'org-to-pdf' -Target 'ConvertFrom-OrgmodeToPdf'
    Set-AgentModeAlias -Name 'orgmode-to-pdf' -Target 'ConvertFrom-OrgmodeToPdf'
}
else {
    Set-Alias -Name org-to-pdf -Value ConvertFrom-OrgmodeToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name orgmode-to-pdf -Value ConvertFrom-OrgmodeToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Org-mode file to DOCX.
.DESCRIPTION
    Uses pandoc to convert an Org-mode file to Microsoft Word DOCX format.
.PARAMETER InputPath
    Path to the input Org-mode file.
.PARAMETER OutputPath
    Path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertFrom-OrgmodeToDocx -InputPath "document.org" -OutputPath "document.docx"
#>
function ConvertFrom-OrgmodeToDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OrgmodeToDocx -ErrorAction SilentlyContinue) {
            _ConvertFrom-OrgmodeToDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OrgmodeToDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Org-mode to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'org-to-docx' -Target 'ConvertFrom-OrgmodeToDocx'
    Set-AgentModeAlias -Name 'orgmode-to-docx' -Target 'ConvertFrom-OrgmodeToDocx'
}
else {
    Set-Alias -Name org-to-docx -Value ConvertFrom-OrgmodeToDocx -ErrorAction SilentlyContinue
    Set-Alias -Name orgmode-to-docx -Value ConvertFrom-OrgmodeToDocx -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Org-mode file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an Org-mode file to LaTeX format.
.PARAMETER InputPath
    Path to the input Org-mode file.
.PARAMETER OutputPath
    Path for the output LaTeX file. If not specified, uses input path with .tex extension.
.EXAMPLE
    ConvertFrom-OrgmodeToLatex -InputPath "document.org" -OutputPath "document.tex"
#>
function ConvertFrom-OrgmodeToLatex {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OrgmodeToLatex -ErrorAction SilentlyContinue) {
            _ConvertFrom-OrgmodeToLatex @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OrgmodeToLatex not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Org-mode to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'org-to-latex' -Target 'ConvertFrom-OrgmodeToLatex'
    Set-AgentModeAlias -Name 'orgmode-to-latex' -Target 'ConvertFrom-OrgmodeToLatex'
}
else {
    Set-Alias -Name org-to-latex -Value ConvertFrom-OrgmodeToLatex -ErrorAction SilentlyContinue
    Set-Alias -Name orgmode-to-latex -Value ConvertFrom-OrgmodeToLatex -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Markdown file to Org-mode.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to Org-mode format.
.PARAMETER InputPath
    Path to the input Markdown file.
.PARAMETER OutputPath
    Path for the output Org-mode file. If not specified, uses input path with .org extension.
.EXAMPLE
    ConvertTo-OrgmodeFromMarkdown -InputPath "document.md" -OutputPath "document.org"
#>
function ConvertTo-OrgmodeFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-OrgmodeFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-OrgmodeFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-OrgmodeFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to Org-mode: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-org' -Target 'ConvertTo-OrgmodeFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-org' -Target 'ConvertTo-OrgmodeFromMarkdown'
    Set-AgentModeAlias -Name 'markdown-to-orgmode' -Target 'ConvertTo-OrgmodeFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-orgmode' -Target 'ConvertTo-OrgmodeFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-org -Value ConvertTo-OrgmodeFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-org -Value ConvertTo-OrgmodeFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name markdown-to-orgmode -Value ConvertTo-OrgmodeFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-orgmode -Value ConvertTo-OrgmodeFromMarkdown -ErrorAction SilentlyContinue
}

