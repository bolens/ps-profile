# ===============================================
# Base encoding utilities (Base32, Base58, Base91)
# ===============================================

<#
.SYNOPSIS
    Initializes base encoding utility functions.
.DESCRIPTION
    Sets up internal functions for Base32, Base58, and Base91 encoding/decoding.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and respective npm packages for some encodings.
#>
function Initialize-DevTools-BaseEncoding {
    # Ensure NodeJs module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # Base32 Encoder
    Set-Item -Path Function:Global:_ConvertTo-Base32 -Value {
        param([Parameter(ValueFromPipeline = $true)][string]$Text)
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            try {
                if (-not (Test-CachedCommand 'node')) {
                    throw "Node.js is not available. Install Node.js to use Base32 encoding."
                }
                $nodeScript = @"
import('base32-encode').then(({ default: base32Encode }) => {
    const text = process.argv[2];
    const buffer = Buffer.from(text, 'utf8');
    const encoded = base32Encode(buffer, 'RFC4648', { padding: false });
    console.log(encoded);
}).catch(error => {
    if (error.code === 'ERR_MODULE_NOT_FOUND' || error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: base32-encode package is not installed. Install it with: npm install -g base32-encode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
});
"@
                $tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "base32-encode-$(Get-Random).js"
                Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
                try {
                    $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Text
                    if ($LASTEXITCODE -ne 0) {
                        throw "Node.js script failed: $result"
                    }
                    return $result.Trim()
                }
                finally {
                    Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                }
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.encoding.base32.encode' -Context @{}
                }
                else {
                    Write-Error "Failed to encode Base32: $_"
                }
            }
        }
    } -Force

    # Base32 Decoder
    Set-Item -Path Function:Global:_ConvertFrom-Base32 -Value {
        param([Parameter(ValueFromPipeline = $true)][string]$Text)
        process {
            if ([string]::IsNullOrWhiteSpace($Text)) { return }
            try {
                if (-not (Test-CachedCommand 'node')) {
                    throw "Node.js is not available. Install Node.js to use Base32 decoding."
                }
                $nodeScript = @"
try {
    const base32 = require('base32-decode');
    const encoded = process.argv[2];
    const buffer = base32(encoded);
    const text = buffer.toString('utf8');
    console.log(text);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: base32-decode package is not installed. Install it with: npm install -g base32-decode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
                $tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "base32-decode-$(Get-Random).js"
                Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
                try {
                    $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Text
                    if ($LASTEXITCODE -ne 0) {
                        throw "Node.js script failed: $result"
                    }
                    return $result.Trim()
                }
                finally {
                    Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                }
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.encoding.base32.decode' -Context @{}
                }
                else {
                    Write-Error "Failed to decode Base32: $_"
                }
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Encodes text to Base32 format.

.DESCRIPTION
    Encodes text to Base32 format. Requires Node.js and base32-encode package.

.PARAMETER Text
    The text to encode. Can be piped.

.OUTPUTS
    System.String
    The Base32-encoded string.

.EXAMPLE
    "Hello" | ConvertTo-Base32
    Encodes the text to Base32.
#>
function ConvertTo-Base32 {
    param([Parameter(ValueFromPipeline = $true)][string]$Text)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertTo-Base32 @PSBoundParameters
}
Set-AgentModeAlias -Name 'base32-encode' -Target 'ConvertTo-Base32'
<#
.SYNOPSIS
    Decodes Base32-encoded text.

.DESCRIPTION
    Decodes Base32-encoded text back to original form. Requires Node.js and base32-decode package.

.PARAMETER Text
    The Base32-encoded text to decode. Can be piped.

.OUTPUTS
    System.String
    The decoded string.

.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32
    Decodes the Base32 string.
#>
function ConvertFrom-Base32 {
    param([Parameter(ValueFromPipeline = $true)][string]$Text)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertFrom-Base32 @PSBoundParameters
}
Set-AgentModeAlias -Name 'base32-decode' -Target 'ConvertFrom-Base32'