# ===============================================
# URL and HTML encoding utilities
# ===============================================

<#
.SYNOPSIS
    Initializes URL and HTML encoding utility functions.
.DESCRIPTION
    Sets up internal functions for URL and HTML encoding/decoding.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires System.Web assembly for HttpUtility.
#>
function Initialize-DevTools-Encoding {
    # Ensure System.Web is loaded for HttpUtility
    if (-not ([System.Management.Automation.PSTypeName]'System.Web.HttpUtility').Type) {
        try {
            Add-Type -AssemblyName System.Web
        }
        catch {
            Write-Warning "Could not load System.Web assembly. URL/HTML encoding may not work. Error: $_"
        }
    }

    # URL Encoder/Decoder
    Set-Item -Path Function:Global:_ConvertTo-UrlEncoded -Value {
        param([Parameter(ValueFromPipeline = $true)][string]$Text)
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            try {
                [System.Web.HttpUtility]::UrlEncode($Text)
            }
            catch {
                # Fallback to PowerShell's built-in encoding
                [System.Uri]::EscapeDataString($Text)
            }
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-UrlEncoded -Value {
        param([Parameter(ValueFromPipeline = $true)][string]$Text)
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            try {
                [System.Web.HttpUtility]::UrlDecode($Text)
            }
            catch {
                # Fallback to PowerShell's built-in decoding
                [System.Uri]::UnescapeDataString($Text)
            }
        }
    } -Force

    # HTML Encoder/Decoder
    Set-Item -Path Function:Global:_ConvertTo-HtmlEncoded -Value {
        param([Parameter(ValueFromPipeline = $true)][string]$Text)
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            [System.Web.HttpUtility]::HtmlEncode($Text)
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-HtmlEncoded -Value {
        param([Parameter(ValueFromPipeline = $true)][string]$Text)
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            [System.Web.HttpUtility]::HtmlDecode($Text)
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    URL-encodes a string.
.DESCRIPTION
    Encodes special characters in a string for use in URLs.
.PARAMETER Text
    The text to encode. Can be piped.
.EXAMPLE
    "Hello World" | ConvertTo-UrlEncoded
    Returns "Hello+World".
.OUTPUTS
    System.String
    The URL-encoded string.
#>
function ConvertTo-UrlEncoded {
    param([Parameter(ValueFromPipeline = $true)][string]$Text)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertTo-UrlEncoded @PSBoundParameters
}
Set-Alias -Name url-encode -Value ConvertTo-UrlEncoded -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    URL-decodes a string.
.DESCRIPTION
    Decodes URL-encoded strings back to their original form.
.PARAMETER Text
    The URL-encoded text to decode. Can be piped.
.EXAMPLE
    "Hello+World" | ConvertFrom-UrlEncoded
    Returns "Hello World".
.OUTPUTS
    System.String
    The URL-decoded string.
#>
function ConvertFrom-UrlEncoded {
    param([Parameter(ValueFromPipeline = $true)][string]$Text)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertFrom-UrlEncoded @PSBoundParameters
}
Set-Alias -Name url-decode -Value ConvertFrom-UrlEncoded -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    HTML-encodes a string.
.DESCRIPTION
    Encodes special characters in a string for safe use in HTML.
.PARAMETER Text
    The text to encode. Can be piped.
.EXAMPLE
    "<script>" | ConvertTo-HtmlEncoded
    Returns "&lt;script&gt;".
.OUTPUTS
    System.String
    The HTML-encoded string.
#>
function ConvertTo-HtmlEncoded {
    param([Parameter(ValueFromPipeline = $true)][string]$Text)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertTo-HtmlEncoded @PSBoundParameters
}
Set-Alias -Name html-encode -Value ConvertTo-HtmlEncoded -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    HTML-decodes a string.
.DESCRIPTION
    Decodes HTML-encoded strings back to their original form.
.PARAMETER Text
    The HTML-encoded text to decode. Can be piped.
.EXAMPLE
    "&lt;script&gt;" | ConvertFrom-HtmlEncoded
    Returns "<script>".
.OUTPUTS
    System.String
    The HTML-decoded string.
#>
function ConvertFrom-HtmlEncoded {
    param([Parameter(ValueFromPipeline = $true)][string]$Text)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertFrom-HtmlEncoded @PSBoundParameters
}
Set-Alias -Name html-decode -Value ConvertFrom-HtmlEncoded -ErrorAction SilentlyContinue

