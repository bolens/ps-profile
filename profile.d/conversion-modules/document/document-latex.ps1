# ===============================================
# LaTeX document format conversion utilities
# LaTeX ↔ Markdown, HTML, PDF, DOCX, RST
# ===============================================

<#
.SYNOPSIS
    Initializes LaTeX document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for LaTeX format conversions.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-DocumentLaTeX {
    # LaTeX to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-LaTeXToMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.tex$', '.md'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f latex -t markdown $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting LaTeX to Markdown. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert LaTeX to Markdown: $($_.Exception.Message)"
            throw
        }
    } -Force

    # LaTeX to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromLaTeX -Value {
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
                $OutputPath = $InputPath -replace '\.tex$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f latex -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting LaTeX to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert LaTeX to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # LaTeX to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromLaTeX -Value {
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
                $OutputPath = $InputPath -replace '\.tex$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting LaTeX to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert LaTeX to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # LaTeX to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromLaTeX -Value {
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
                $OutputPath = $InputPath -replace '\.tex$', '.docx'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting LaTeX to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert LaTeX to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # LaTeX to RST
    Set-Item -Path Function:Global:_ConvertTo-RstFromLaTeX -Value {
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
                $OutputPath = $InputPath -replace '\.tex$', '.rst'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f latex -t rst $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting LaTeX to RST. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert LaTeX to RST: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert LaTeX to Markdown
<#
.SYNOPSIS
    Converts LaTeX file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to Markdown format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-LaTeXToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-LaTeXToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-LaTeXToMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-LaTeXToMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert LaTeX to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name latex-to-markdown -Value ConvertFrom-LaTeXToMarkdown -ErrorAction SilentlyContinue

# Convert LaTeX to HTML
<#
.SYNOPSIS
    Converts LaTeX file to HTML.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to HTML format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromLaTeX -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromLaTeX @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromLaTeX not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert LaTeX to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name latex-to-html -Value ConvertTo-HtmlFromLaTeX -ErrorAction SilentlyContinue

# Convert LaTeX to PDF
<#
.SYNOPSIS
    Converts LaTeX file to PDF.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to PDF format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromLaTeX -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromLaTeX @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromLaTeX not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert LaTeX to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name latex-to-pdf -Value ConvertTo-PdfFromLaTeX -ErrorAction SilentlyContinue

# Convert LaTeX to DOCX
<#
.SYNOPSIS
    Converts LaTeX file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
#>
function ConvertTo-DocxFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-DocxFromLaTeX -ErrorAction SilentlyContinue) {
            _ConvertTo-DocxFromLaTeX @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-DocxFromLaTeX not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert LaTeX to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name latex-to-docx -Value ConvertTo-DocxFromLaTeX -ErrorAction SilentlyContinue

# Convert LaTeX to RST
<#
.SYNOPSIS
    Converts LaTeX file to RST.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to reStructuredText (RST) format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output RST file. If not specified, uses input path with .rst extension.
#>
function ConvertTo-RstFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-RstFromLaTeX -ErrorAction SilentlyContinue) {
            _ConvertTo-RstFromLaTeX @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-RstFromLaTeX not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert LaTeX to RST: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name latex-to-rst -Value ConvertTo-RstFromLaTeX -ErrorAction SilentlyContinue

