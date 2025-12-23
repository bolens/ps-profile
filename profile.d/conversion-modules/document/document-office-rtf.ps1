# ===============================================
# RTF (Rich Text Format) conversion utilities
# RTF ↔ Markdown, HTML, PDF, DOCX, Plain Text
# ===============================================

<#
.SYNOPSIS
    Initializes RTF document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for RTF (Rich Text Format) conversions.
    RTF is a document format developed by Microsoft for cross-platform document exchange.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc for conversions. RTF files use .rtf extension.
#>
function Initialize-FileConversion-DocumentOfficeRtf {
    # RTF to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-RtfToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rtf$', '.md'
            }
            
            $errorOutput = & pandoc -f rtf -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting RTF to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert RTF to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RTF to HTML
    Set-Item -Path Function:Global:_ConvertFrom-RtfToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rtf$', '.html'
            }
            
            $errorOutput = & pandoc -f rtf -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting RTF to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert RTF to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RTF to PDF
    Set-Item -Path Function:Global:_ConvertFrom-RtfToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rtf$', '.pdf'
            }
            
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting RTF to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert RTF to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RTF to DOCX
    Set-Item -Path Function:Global:_ConvertFrom-RtfToDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rtf$', '.docx'
            }
            
            $errorOutput = & pandoc -f rtf -t docx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting RTF to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert RTF to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # RTF to Plain Text
    Set-Item -Path Function:Global:_ConvertFrom-RtfToText -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.rtf$', '.txt'
            }
            
            $errorOutput = & pandoc -f rtf -t plain $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting RTF to Plain Text. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert RTF to Plain Text: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to RTF
    Set-Item -Path Function:Global:_ConvertTo-RtfFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', '.rtf'
            }
            
            $errorOutput = & pandoc -f markdown -t rtf $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to RTF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to RTF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DOCX to RTF
    Set-Item -Path Function:Global:_ConvertTo-RtfFromDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.docx$', '.rtf'
            }
            
            $errorOutput = & pandoc -f docx -t rtf $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting DOCX to RTF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to RTF: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts RTF file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an RTF (Rich Text Format) file to Markdown format.
.PARAMETER InputPath
    Path to the input RTF file.
.PARAMETER OutputPath
    Path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-RtfToMarkdown -InputPath "document.rtf" -OutputPath "document.md"
#>
function ConvertFrom-RtfToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-RtfToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-RtfToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-RtfToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RTF to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rtf-to-markdown' -Target 'ConvertFrom-RtfToMarkdown'
}
else {
    Set-Alias -Name rtf-to-markdown -Value ConvertFrom-RtfToMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts RTF file to HTML.
.DESCRIPTION
    Uses pandoc to convert an RTF file to HTML format.
.PARAMETER InputPath
    Path to the input RTF file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-RtfToHtml -InputPath "document.rtf" -OutputPath "document.html"
#>
function ConvertFrom-RtfToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-RtfToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-RtfToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-RtfToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RTF to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rtf-to-html' -Target 'ConvertFrom-RtfToHtml'
}
else {
    Set-Alias -Name rtf-to-html -Value ConvertFrom-RtfToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts RTF file to PDF.
.DESCRIPTION
    Uses pandoc to convert an RTF file to PDF format.
.PARAMETER InputPath
    Path to the input RTF file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-RtfToPdf -InputPath "document.rtf" -OutputPath "document.pdf"
#>
function ConvertFrom-RtfToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-RtfToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-RtfToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-RtfToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RTF to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rtf-to-pdf' -Target 'ConvertFrom-RtfToPdf'
}
else {
    Set-Alias -Name rtf-to-pdf -Value ConvertFrom-RtfToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts RTF file to DOCX.
.DESCRIPTION
    Uses pandoc to convert an RTF file to Microsoft Word DOCX format.
.PARAMETER InputPath
    Path to the input RTF file.
.PARAMETER OutputPath
    Path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertFrom-RtfToDocx -InputPath "document.rtf" -OutputPath "document.docx"
#>
function ConvertFrom-RtfToDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-RtfToDocx -ErrorAction SilentlyContinue) {
            _ConvertFrom-RtfToDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-RtfToDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RTF to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rtf-to-docx' -Target 'ConvertFrom-RtfToDocx'
}
else {
    Set-Alias -Name rtf-to-docx -Value ConvertFrom-RtfToDocx -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts RTF file to Plain Text.
.DESCRIPTION
    Uses pandoc to convert an RTF file to plain text format.
.PARAMETER InputPath
    Path to the input RTF file.
.PARAMETER OutputPath
    Path for the output text file. If not specified, uses input path with .txt extension.
.EXAMPLE
    ConvertFrom-RtfToText -InputPath "document.rtf" -OutputPath "document.txt"
#>
function ConvertFrom-RtfToText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-RtfToText -ErrorAction SilentlyContinue) {
            _ConvertFrom-RtfToText @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-RtfToText not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert RTF to Plain Text: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rtf-to-text' -Target 'ConvertFrom-RtfToText'
    Set-AgentModeAlias -Name 'rtf-to-txt' -Target 'ConvertFrom-RtfToText'
}
else {
    Set-Alias -Name rtf-to-text -Value ConvertFrom-RtfToText -ErrorAction SilentlyContinue
    Set-Alias -Name rtf-to-txt -Value ConvertFrom-RtfToText -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Markdown file to RTF.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to RTF (Rich Text Format).
.PARAMETER InputPath
    Path to the input Markdown file.
.PARAMETER OutputPath
    Path for the output RTF file. If not specified, uses input path with .rtf extension.
.EXAMPLE
    ConvertTo-RtfFromMarkdown -InputPath "document.md" -OutputPath "document.rtf"
#>
function ConvertTo-RtfFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-RtfFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-RtfFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-RtfFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to RTF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-rtf' -Target 'ConvertTo-RtfFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-rtf' -Target 'ConvertTo-RtfFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-rtf -Value ConvertTo-RtfFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-rtf -Value ConvertTo-RtfFromMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts DOCX file to RTF.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to RTF (Rich Text Format).
.PARAMETER InputPath
    Path to the input DOCX file.
.PARAMETER OutputPath
    Path for the output RTF file. If not specified, uses input path with .rtf extension.
.EXAMPLE
    ConvertTo-RtfFromDocx -InputPath "document.docx" -OutputPath "document.rtf"
#>
function ConvertTo-RtfFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-RtfFromDocx -ErrorAction SilentlyContinue) {
            _ConvertTo-RtfFromDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-RtfFromDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DOCX to RTF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'docx-to-rtf' -Target 'ConvertTo-RtfFromDocx'
}
else {
    Set-Alias -Name docx-to-rtf -Value ConvertTo-RtfFromDocx -ErrorAction SilentlyContinue
}

