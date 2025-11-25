# ===============================================
# Hash generator utilities
# ===============================================

<#
.SYNOPSIS
    Initializes hash generator utility functions.
.DESCRIPTION
    Sets up internal hash generation functions for text input.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Hash {
    Set-Item -Path Function:Global:_Get-TextHash -Value {
        param(
            [Parameter(ValueFromPipeline = $true)]
            [string]$Text,
            [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
            [string]$Algorithm = 'SHA256'
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
            $hashAlgorithm = switch ($Algorithm) {
                'MD5' { [System.Security.Cryptography.MD5]::Create() }
                'SHA1' { [System.Security.Cryptography.SHA1]::Create() }
                'SHA256' { [System.Security.Cryptography.SHA256]::Create() }
                'SHA384' { [System.Security.Cryptography.SHA384]::Create() }
                'SHA512' { [System.Security.Cryptography.SHA512]::Create() }
                default { [System.Security.Cryptography.SHA256]::Create() }
            }
            try {
                $hashBytes = $hashAlgorithm.ComputeHash($bytes)
                $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
                [PSCustomObject]@{
                    Algorithm = $Algorithm
                    Hash = $hashString
                    Text = $Text.Substring(0, [Math]::Min(50, $Text.Length))
                }
            }
            finally {
                $hashAlgorithm.Dispose()
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Calculates cryptographic hash of text input.
.DESCRIPTION
    Computes the hash value of text using the specified cryptographic algorithm.
    Supports MD5, SHA1, SHA256, SHA384, and SHA512 algorithms.
.PARAMETER Text
    The text to hash. Can be piped.
.PARAMETER Algorithm
    The hash algorithm to use. Default is SHA256.
.EXAMPLE
    "Hello World" | Get-TextHash
    Calculates SHA256 hash of "Hello World".
.EXAMPLE
    "password" | Get-TextHash -Algorithm MD5
    Calculates MD5 hash of "password".
.OUTPUTS
    PSCustomObject
    Object containing Algorithm, Hash, and Text properties.
#>
function Get-TextHash {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$Text,
        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'SHA256'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Get-TextHash @PSBoundParameters
}
Set-Alias -Name text-hash -Value Get-TextHash -ErrorAction SilentlyContinue

