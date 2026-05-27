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
#>
function ConvertTo-UrlEncoded { param([string]$text) [uri]::EscapeDataString($text) }
Set-AgentModeAlias -Name 'url-encode' -Target 'ConvertTo-UrlEncoded'
# URL decode
<#
.SYNOPSIS
    URL-decodes a string.
.DESCRIPTION
    Decodes a URL-encoded string.
#>
function ConvertFrom-UrlEncoded { param([string]$text) [uri]::UnescapeDataString($text) }
Set-AgentModeAlias -Name 'url-decode' -Target 'ConvertFrom-UrlEncoded'