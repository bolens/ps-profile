# ===============================================
# Encoding utility functions
# URL encoding/decoding
# ===============================================

# URL encode
<#
.SYNOPSIS
    URL-encodes a string.
.DESCRIPTION
    Encodes a string for use in URLs.
.EXAMPLE
    ConvertTo-UrlEncoded -text 'hello world'
.PARAMETER text
    Plain text to encode for use in a URL query or path segment.

#>
function ConvertTo-UrlEncoded { param([string]$text) [uri]::EscapeDataString($text) }
Set-AgentModeAlias -Name 'url-encode' -Target 'ConvertTo-UrlEncoded'
# URL decode
<#
.SYNOPSIS
    URL-decodes a string.
.DESCRIPTION
    Decodes a URL-encoded string.
.EXAMPLE
    ConvertFrom-UrlEncoded -text 'hello%20world'
.PARAMETER text
    URL-encoded text to decode back to plain text.

#>
function ConvertFrom-UrlEncoded { param([string]$text) [uri]::UnescapeDataString($text) }
Set-AgentModeAlias -Name 'url-decode' -Target 'ConvertFrom-UrlEncoded'