<#
.SYNOPSIS
Creates a minimal Cloudflare Wrangler config file at the XDG-style location shown in the debug log.

.DESCRIPTION
Some tools (including MCP/Cloudflare helpers) look for a global Wrangler config file at
a path derived from XDG config or APPDATA. On Windows the path in the log looked like:

  C:\Users\<you>\AppData\Roaming\xdg.config\.wrangler\config\default.toml

This script will create the directory and write a minimal `default.toml` containing an
`api_token` and optional `account_id`. It does NOT try to obtain credentials for you—
you should create an API token in the Cloudflare dashboard and pass it here, or use
`wrangler login` which will create the file for you.

.PARAMETER ApiToken
The Cloudflare API token. If omitted the script will prompt interactively.

.PARAMETER AccountId
Optional Cloudflare Account ID to include in the file.

.PARAMETER Force
Overwrite an existing file without prompting.

USAGE
  # interactively prompt for token
  .\scripts\init_wrangler_config.ps1

  # pass token and account id non-interactively
  .\scripts\init_wrangler_config.ps1 -ApiToken 'xxxxxxxx' -AccountId 'abcd-1234' -Force

#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiToken,

    [Parameter(Mandatory=$false)]
    [string]$AccountId,

    [switch]$Force
)

function Get-TargetPath {
    # Use the exact path style from your log. If you prefer XDG env var, set XDG_CONFIG_HOME
    $appdata = $env:APPDATA
    if (-not $appdata) { throw 'APPDATA is not set in the environment; unable to compute target path.' }

    # match the path reported by the debug message
    $dir = Join-Path -Path $appdata -ChildPath 'xdg.config\.wrangler\config'
    $file = Join-Path -Path $dir -ChildPath 'default.toml'
    return @{ Dir = $dir; File = $file }
}

$paths = Get-TargetPath
$dir = $paths.Dir
$file = $paths.File

Write-Host "Target config directory: $dir"
Write-Host "Target config file: $file"

if (-not $ApiToken) {
    $ApiToken = Read-Host -AsSecureString 'Enter Cloudflare API token (will be converted to plaintext in config file)'
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiToken)
    $ApiToken = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) | Out-Null
}

if (-not (Test-Path -Path $dir)) {
    Write-Host "Creating directory: $dir"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

if (Test-Path -Path $file -and -not $Force) {
    $ok = Read-Host "File already exists at $file. Overwrite? (y/N)"
    if ($ok -notin @('y','Y','yes','YES')) {
        Write-Host 'Aborting; existing file retained.'
        return
    }
}

$content = @()
$content += "# Wrangler global config created by init_wrangler_config.ps1"
$content += "# Replace the token or use `wrangler login` for a more secure setup"
$content += "api_token = \"$ApiToken\""
if ($AccountId) { $content += "account_id = \"$AccountId\"" }

Set-Content -Path $file -Value ($content -join "`n") -Encoding UTF8

Write-Host "Wrote config to: $file"
Write-Host "Notes:`n - Consider creating a more restrictive API token in the Cloudflare dashboard (least privilege).`n - Alternatively you can set the CF_API_TOKEN env var for CI or local runs: `setx CF_API_TOKEN '<token>'` (powershell)"

Write-Host "Now re-run your MCP server (for example: npx @cloudflare/mcp-server-cloudflare) in a new shell so the env is picked up if you used setx."
