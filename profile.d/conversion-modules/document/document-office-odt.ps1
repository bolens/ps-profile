# ===============================================
# ODT (OpenDocument Text) format conversion utilities
# ODT ↔ Markdown, HTML, PDF, DOCX, LaTeX
# ===============================================

<#
.SYNOPSIS
    Initializes ODT document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ODT (OpenDocument Text) format conversions.
    ODT is the OpenDocument format for text documents used by LibreOffice and OpenOffice.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc for conversions. ODT files use .odt extension.
#>
function Initialize-FileConversion-DocumentOfficeOdt {
    # ODT to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-OdtToMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odt$', '.md'
            }
            
            $errorOutput = & pandoc -f odt -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODT to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODT to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODT to HTML
    Set-Item -Path Function:Global:_ConvertFrom-OdtToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odt$', '.html'
            }
            
            $errorOutput = & pandoc -f odt -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODT to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODT to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODT to PDF
    Set-Item -Path Function:Global:_ConvertFrom-OdtToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odt$', '.pdf'
            }
            
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODT to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODT to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODT to DOCX
    Set-Item -Path Function:Global:_ConvertFrom-OdtToDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odt$', '.docx'
            }
            
            $errorOutput = & pandoc -f odt -t docx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODT to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODT to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODT to LaTeX
    Set-Item -Path Function:Global:_ConvertFrom-OdtToLatex -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odt$', '.tex'
            }
            
            $errorOutput = & pandoc -f odt -t latex $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODT to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODT to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to ODT
    Set-Item -Path Function:Global:_ConvertTo-OdtFromMarkdown -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', '.odt'
            }
            
            $errorOutput = & pandoc -f markdown -t odt $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to ODT. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to ODT: $($_.Exception.Message)"
            throw
        }
    } -Force

    # DOCX to ODT
    Set-Item -Path Function:Global:_ConvertTo-OdtFromDocx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.docx$', '.odt'
            }
            
            $errorOutput = & pandoc -f docx -t odt $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting DOCX to ODT. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert DOCX to ODT: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts ODT file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an ODT (OpenDocument Text) file to Markdown format.
.PARAMETER InputPath
    Path to the input ODT file.
.PARAMETER OutputPath
    Path for the output Markdown file. If not specified, uses input path with .md extension.
.EXAMPLE
    ConvertFrom-OdtToMarkdown -InputPath "document.odt" -OutputPath "document.md"
#>
function ConvertFrom-OdtToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdtToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdtToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdtToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODT to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odt-to-markdown' -Target 'ConvertFrom-OdtToMarkdown'
}
else {
    Set-Alias -Name odt-to-markdown -Value ConvertFrom-OdtToMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODT file to HTML.
.DESCRIPTION
    Uses pandoc to convert an ODT file to HTML format.
.PARAMETER InputPath
    Path to the input ODT file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-OdtToHtml -InputPath "document.odt" -OutputPath "document.html"
#>
function ConvertFrom-OdtToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdtToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdtToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdtToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODT to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odt-to-html' -Target 'ConvertFrom-OdtToHtml'
}
else {
    Set-Alias -Name odt-to-html -Value ConvertFrom-OdtToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODT file to PDF.
.DESCRIPTION
    Uses pandoc to convert an ODT file to PDF format.
.PARAMETER InputPath
    Path to the input ODT file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-OdtToPdf -InputPath "document.odt" -OutputPath "document.pdf"
#>
function ConvertFrom-OdtToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdtToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdtToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdtToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODT to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odt-to-pdf' -Target 'ConvertFrom-OdtToPdf'
}
else {
    Set-Alias -Name odt-to-pdf -Value ConvertFrom-OdtToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODT file to DOCX.
.DESCRIPTION
    Uses pandoc to convert an ODT file to Microsoft Word DOCX format.
.PARAMETER InputPath
    Path to the input ODT file.
.PARAMETER OutputPath
    Path for the output DOCX file. If not specified, uses input path with .docx extension.
.EXAMPLE
    ConvertFrom-OdtToDocx -InputPath "document.odt" -OutputPath "document.docx"
#>
function ConvertFrom-OdtToDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdtToDocx -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdtToDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdtToDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODT to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odt-to-docx' -Target 'ConvertFrom-OdtToDocx'
}
else {
    Set-Alias -Name odt-to-docx -Value ConvertFrom-OdtToDocx -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODT file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an ODT file to LaTeX format.
.PARAMETER InputPath
    Path to the input ODT file.
.PARAMETER OutputPath
    Path for the output LaTeX file. If not specified, uses input path with .tex extension.
.EXAMPLE
    ConvertFrom-OdtToLatex -InputPath "document.odt" -OutputPath "document.tex"
#>
function ConvertFrom-OdtToLatex {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdtToLatex -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdtToLatex @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdtToLatex not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODT to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odt-to-latex' -Target 'ConvertFrom-OdtToLatex'
}
else {
    Set-Alias -Name odt-to-latex -Value ConvertFrom-OdtToLatex -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Markdown file to ODT.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to ODT (OpenDocument Text) format.
.PARAMETER InputPath
    Path to the input Markdown file.
.PARAMETER OutputPath
    Path for the output ODT file. If not specified, uses input path with .odt extension.
.EXAMPLE
    ConvertTo-OdtFromMarkdown -InputPath "document.md" -OutputPath "document.odt"
#>
function ConvertTo-OdtFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-OdtFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-OdtFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-OdtFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to ODT: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'markdown-to-odt' -Target 'ConvertTo-OdtFromMarkdown'
    Set-AgentModeAlias -Name 'md-to-odt' -Target 'ConvertTo-OdtFromMarkdown'
}
else {
    Set-Alias -Name markdown-to-odt -Value ConvertTo-OdtFromMarkdown -ErrorAction SilentlyContinue
    Set-Alias -Name md-to-odt -Value ConvertTo-OdtFromMarkdown -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts DOCX file to ODT.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to ODT (OpenDocument Text) format.
.PARAMETER InputPath
    Path to the input DOCX file.
.PARAMETER OutputPath
    Path for the output ODT file. If not specified, uses input path with .odt extension.
.EXAMPLE
    ConvertTo-OdtFromDocx -InputPath "document.docx" -OutputPath "document.odt"
#>
function ConvertTo-OdtFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-OdtFromDocx -ErrorAction SilentlyContinue) {
            _ConvertTo-OdtFromDocx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-OdtFromDocx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert DOCX to ODT: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'docx-to-odt' -Target 'ConvertTo-OdtFromDocx'
}
else {
    Set-Alias -Name docx-to-odt -Value ConvertTo-OdtFromDocx -ErrorAction SilentlyContinue
}

