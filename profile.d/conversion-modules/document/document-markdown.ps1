# ===============================================
# Markdown document format conversion utilities
# Markdown ↔ HTML, PDF, DOCX, LaTeX, RST
# ===============================================

<#
.SYNOPSIS
    Initializes Markdown document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Markdown format conversions.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-DocumentMarkdown {
    # Markdown to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.md$', '.html'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.md$', '.pdf'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to PDF. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.md$', '.docx'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to DOCX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to DOCX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.md$', '.tex'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to LaTeX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to LaTeX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Markdown to RST
    Set-Item -Path Function:Global:_ConvertTo-RstFromMarkdown -Value {
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
                $OutputPath = $InputPath -replace '\.md$', '.rst'
            }
            
            # Execute with error capture
            $errorOutput = & pandoc -f markdown -t rst $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Markdown to RST. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Markdown to RST: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Convert Markdown to HTML
<#
.SYNOPSIS
    Converts Markdown file to HTML.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to HTML format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-HtmlFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-HtmlFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HtmlFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to HTML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name markdown-to-html -Value ConvertTo-HtmlFromMarkdown -ErrorAction SilentlyContinue

# Convert Markdown to PDF
<#
.SYNOPSIS
    Converts Markdown file to PDF.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to PDF format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-PdfFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-PdfFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-PdfFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to PDF: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name markdown-to-pdf -Value ConvertTo-PdfFromMarkdown -ErrorAction SilentlyContinue

# Convert Markdown to DOCX
<#
.SYNOPSIS
    Converts Markdown file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
#>
function ConvertTo-DocxFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-DocxFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-DocxFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-DocxFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to DOCX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name markdown-to-docx -Value ConvertTo-DocxFromMarkdown -ErrorAction SilentlyContinue

# Convert Markdown to LaTeX
<#
.SYNOPSIS
    Converts Markdown file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to LaTeX format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-LaTeXFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-LaTeXFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-LaTeXFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to LaTeX: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name markdown-to-latex -Value ConvertTo-LaTeXFromMarkdown -ErrorAction SilentlyContinue

# Convert Markdown to RST
<#
.SYNOPSIS
    Converts Markdown file to RST.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to reStructuredText (RST) format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output RST file. If not specified, uses input path with .rst extension.
#>
function ConvertTo-RstFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-RstFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-RstFromMarkdown @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-RstFromMarkdown not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to RST: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name markdown-to-rst -Value ConvertTo-RstFromMarkdown -ErrorAction SilentlyContinue

