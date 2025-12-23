# ===============================================
# Plain Text format conversion utilities
# Plain Text ↔ Markdown, HTML, PDF, DOCX, RTF (with encoding support)
# ===============================================

<#
.SYNOPSIS
    Initializes Plain Text document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Plain Text format conversions.
    Plain Text files support various encodings (UTF-8, UTF-16, ASCII, etc.).
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Plain Text files use .txt or .text extensions.
    Supports encoding detection and conversion between different text encodings.
#>
function Initialize-FileConversion-DocumentOfficePlaintext {
    # Plain Text to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-PlainTextToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(txt|text)$', '.md'
            }
            
            # Read with specified encoding
            $encodingObj = [System.Text.Encoding]::GetEncoding($Encoding)
            $content = Get-Content -Path $InputPath -Encoding $Encoding -Raw
            
            # Convert plain text to markdown (simple: wrap in code block or preserve as-is)
            # For now, just copy content with .md extension
            # More sophisticated conversion could detect structure and add markdown formatting
            Set-Content -Path $OutputPath -Value $content -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert Plain Text to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Plain Text to HTML
    Set-Item -Path Function:Global:_ConvertFrom-PlainTextToHtml -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(txt|text)$', '.html'
            }
            
            $errorOutput = & pandoc -f plain -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Plain Text to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Plain Text to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Plain Text to PDF
    Set-Item -Path Function:Global:_ConvertFrom-PlainTextToPdf -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(txt|text)$', '.pdf'
            }
            
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Plain Text to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Plain Text to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Plain Text to DOCX
    Set-Item -Path Function:Global:_ConvertFrom-PlainTextToDocx -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(txt|text)$', '.docx'
            }
            
            $errorOutput = & pandoc -f plain -t docx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Plain Text to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Plain Text to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Plain Text to RTF
    Set-Item -Path Function:Global:_ConvertFrom-PlainTextToRtf -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(txt|text)$', '.rtf'
            }
            
            $errorOutput = & pandoc -f plain -t rtf $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Plain Text to RTF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Plain Text to RTF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to Plain Text
    Set-Item -Path Function:Global:_ConvertTo-PlainTextFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', '.txt'
            }
            
            $errorOutput = & pandoc -f markdown -t plain $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to Plain Text. Error: $errorText"
            }
            
            # Apply encoding if specified
            if ($Encoding -ne 'UTF8') {
                $content = Get-Content -Path $OutputPath -Raw
                $encodingObj = [System.Text.Encoding]::GetEncoding($Encoding)
                [System.IO.File]::WriteAllText($OutputPath, $content, $encodingObj)
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to Plain Text: $($_.Exception.Message)"
            throw
        }
    } -Force

    # HTML to Plain Text
    Set-Item -Path Function:Global:_ConvertTo-PlainTextFromHtml -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.html$', '.txt'
            }
            
            $errorOutput = & pandoc -f html -t plain $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting HTML to Plain Text. Error: $errorText"
            }
            
            # Apply encoding if specified
            if ($Encoding -ne 'UTF8') {
                $content = Get-Content -Path $OutputPath -Raw
                $encodingObj = [System.Text.Encoding]::GetEncoding($Encoding)
                [System.IO.File]::WriteAllText($OutputPath, $content, $encodingObj)
            }
        }
        catch {
            Write-Error "Failed to convert HTML to Plain Text: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts Plain Text file to Markdown.
.DESCRIPTION
    Converts a Plain Text file to Markdown format, preserving content.
.PARAMETER InputPath
    Path to the input Plain Text file.
.PARAMETER OutputPath
    Path for the output Markdown file. If not specified, uses input path with .md extension.
.PARAMETER Encoding
    Text encoding of the input file (default: UTF8). Supports UTF8, UTF16, ASCII, etc.
.EXAMPLE
    ConvertFrom-PlainTextToMarkdown -InputPath "document.txt" -OutputPath "document.md" -Encoding UTF8
#>
function ConvertFrom-PlainTextToMarkdown {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-PlainTextToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-PlainTextToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-PlainTextToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Plain Text to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'text-to-markdown' -Target 'ConvertFrom-PlainTextToMarkdown'
    Set-AgentModeAlias -Name 'txt-to-markdown' -Target 'ConvertFrom-PlainTextToMarkdown'
}
else {
    Set-Alias -Name text-to-markdown -Value ConvertFrom-PlainTextToMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name txt-to-markdown -Value ConvertFrom-PlainTextToMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Plain Text file to HTML.
.DESCRIPTION
    Uses pandoc to convert a Plain Text file to HTML format.
.PARAMETER InputPath
    Path to the input Plain Text file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.PARAMETER Encoding
    Text encoding of the input file (default: UTF8).
.EXAMPLE
    ConvertFrom-PlainTextToHtml -InputPath "document.txt" -OutputPath "document.html"
#>
function ConvertFrom-PlainTextToHtml {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-PlainTextToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-PlainTextToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-PlainTextToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Plain Text to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'text-to-html' -Target 'ConvertFrom-PlainTextToHtml'
    Set-AgentModeAlias -Name 'txt-to-html' -Target 'ConvertFrom-PlainTextToHtml'
}
else {
    Set-Alias -Name text-to-html -Value ConvertFrom-PlainTextToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name txt-to-html -Value ConvertFrom-PlainTextToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Plain Text file to PDF.
.DESCRIPTION
    Uses pandoc to convert a Plain Text file to PDF format.
.PARAMETER InputPath
    Path to the input Plain Text file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.PARAMETER Encoding
    Text encoding of the input file (default: UTF8).
.EXAMPLE
    ConvertFrom-PlainTextToPdf -InputPath "document.txt" -OutputPath "document.pdf"
#>
function ConvertFrom-PlainTextToPdf {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-PlainTextToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-PlainTextToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-PlainTextToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Plain Text to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'text-to-pdf' -Target 'ConvertFrom-PlainTextToPdf'
    Set-AgentModeAlias -Name 'txt-to-pdf' -Target 'ConvertFrom-PlainTextToPdf'
}
else {
    Set-Alias -Name text-to-pdf -Value ConvertFrom-PlainTextToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name txt-to-pdf -Value ConvertFrom-PlainTextToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Plain Text file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a Plain Text file to Microsoft Word DOCX format.
.PARAMETER InputPath
    Path to the input Plain Text file.
.PARAMETER OutputPath
    Path for the output DOCX file. If not specified, uses input path with .docx extension.
.PARAMETER Encoding
    Text encoding of the input file (default: UTF8).
.EXAMPLE
    ConvertFrom-PlainTextToDocx -InputPath "document.txt" -OutputPath "document.docx"
#>
function ConvertFrom-PlainTextToDocx {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-PlainTextToDocx -ErrorAction SilentlyContinue) {
            _ConvertFrom-PlainTextToDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-PlainTextToDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Plain Text to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'text-to-docx' -Target 'ConvertFrom-PlainTextToDocx'
    Set-AgentModeAlias -Name 'txt-to-docx' -Target 'ConvertFrom-PlainTextToDocx'
}
else {
    Set-Alias -Name text-to-docx -Value ConvertFrom-PlainTextToDocx -ErrorAction SilentlyContinue
    Set-Alias -Name txt-to-docx -Value ConvertFrom-PlainTextToDocx -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Plain Text file to RTF.
.DESCRIPTION
    Uses pandoc to convert a Plain Text file to RTF (Rich Text Format).
.PARAMETER InputPath
    Path to the input Plain Text file.
.PARAMETER OutputPath
    Path for the output RTF file. If not specified, uses input path with .rtf extension.
.PARAMETER Encoding
    Text encoding of the input file (default: UTF8).
.EXAMPLE
    ConvertFrom-PlainTextToRtf -InputPath "document.txt" -OutputPath "document.rtf"
#>
function ConvertFrom-PlainTextToRtf {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-PlainTextToRtf -ErrorAction SilentlyContinue) {
            _ConvertFrom-PlainTextToRtf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-PlainTextToRtf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Plain Text to RTF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'text-to-rtf' -Target 'ConvertFrom-PlainTextToRtf'
    Set-AgentModeAlias -Name 'txt-to-rtf' -Target 'ConvertFrom-PlainTextToRtf'
}
else {
    Set-Alias -Name text-to-rtf -Value ConvertFrom-PlainTextToRtf -ErrorAction SilentlyContinue
    Set-Alias -Name txt-to-rtf -Value ConvertFrom-PlainTextToRtf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Markdown file to Plain Text.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to Plain Text format.
.PARAMETER InputPath
    Path to the input Markdown file.
.PARAMETER OutputPath
    Path for the output Plain Text file. If not specified, uses input path with .txt extension.
.PARAMETER Encoding
    Text encoding for the output file (default: UTF8).
.EXAMPLE
    ConvertTo-PlainTextFromMarkdown -InputPath "document.md" -OutputPath "document.txt" -Encoding UTF8
#>
function ConvertTo-PlainTextFromMarkdown {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PlainTextFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-PlainTextFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PlainTextFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to Plain Text: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-text' -Target 'ConvertTo-PlainTextFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-text' -Target 'ConvertTo-PlainTextFromMarkdown'
    Set-AgentModeAlias -Name 'markdown-to-txt' -Target 'ConvertTo-PlainTextFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-txt' -Target 'ConvertTo-PlainTextFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-text -Value ConvertTo-PlainTextFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-text -Value ConvertTo-PlainTextFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name markdown-to-txt -Value ConvertTo-PlainTextFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-txt -Value ConvertTo-PlainTextFromMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts HTML file to Plain Text.
.DESCRIPTION
    Uses pandoc to convert an HTML file to Plain Text format.
.PARAMETER InputPath
    Path to the input HTML file.
.PARAMETER OutputPath
    Path for the output Plain Text file. If not specified, uses input path with .txt extension.
.PARAMETER Encoding
    Text encoding for the output file (default: UTF8).
.EXAMPLE
    ConvertTo-PlainTextFromHtml -InputPath "document.html" -OutputPath "document.txt" -Encoding UTF8
#>
function ConvertTo-PlainTextFromHtml {
    param([string]$InputPath, [string]$OutputPath, [string]$Encoding = 'UTF8')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PlainTextFromHtml -ErrorAction SilentlyContinue) {
            _ConvertTo-PlainTextFromHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PlainTextFromHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HTML to Plain Text: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'html-to-text' -Target 'ConvertTo-PlainTextFromHtml'
    Set-AgentModeAlias -Name 'html-to-txt' -Target 'ConvertTo-PlainTextFromHtml'
}
else {
    Set-Alias -Name html-to-text -Value ConvertTo-PlainTextFromHtml -ErrorAction SilentlyContinue
    Set-Alias -Name html-to-txt -Value ConvertTo-PlainTextFromHtml -ErrorAction SilentlyContinue
}

