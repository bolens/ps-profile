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

.PARAMETER text
    Plain text to encode for use in a URL query or path segment.

.EXAMPLE
    ConvertTo-UrlEncoded -text 'hello world'

#>
function ConvertTo-UrlEncoded { param([string]$text) [uri]::EscapeDataString($text) }
Set-AgentModeAlias -Name 'url-encode' -Target 'ConvertTo-UrlEncoded'
# URL decode
<#
.SYNOPSIS
    URL-decodes a string.

.DESCRIPTION
    Decodes a URL-encoded string.

.PARAMETER text
    URL-encoded text to decode back to plain text.

.EXAMPLE
    ConvertFrom-UrlEncoded -text 'hello%20world'

#>
function ConvertFrom-UrlEncoded { param([string]$text) [uri]::UnescapeDataString($text) }
Set-AgentModeAlias -Name 'url-decode' -Target 'ConvertFrom-UrlEncoded'