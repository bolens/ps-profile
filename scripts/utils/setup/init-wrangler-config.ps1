<#
scripts/utils/init-wrangler-config.ps1

.SYNOPSIS
    Creates a minimal Cloudflare Wrangler config file at the XDG-style location.

.DESCRIPTION
    Some tools (including MCP/Cloudflare helpers) look for a global Wrangler config file at
    a path derived from XDG config or APPDATA. On Windows the path is typically:
    
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

.PARAMETER DryRun
    If specified, shows what config file would be created without actually creating it.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\init-wrangler-config.ps1

    Interactively prompts for the API token and creates the config file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\init-wrangler-config.ps1 -ApiToken 'xxxxxxxx' -AccountId 'abcd-1234' -Force

    Creates the config file non-interactively with the provided token and account ID.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\init-wrangler-config.ps1 -DryRun

    Shows what config file would be created without actually creating it.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ApiToken,

    [Parameter(Mandatory = $false)]
    [string]$AccountId,

    [switch]$Force,

    [switch]$DryRun
)

# Import shared utilities using ModuleImport pattern
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import required modules using Import-LibModule
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking

<#
.SYNOPSIS
    Gets the target path for the Wrangler config file.

.DESCRIPTION
    Resolves the cross-platform path for the Wrangler config file based on:
    - XDG_CONFIG_HOME environment variable (Unix standard)
    - APPDATA environment variable (Windows)
    - Fallback to home directory with appropriate structure
    
    On Windows, uses the xdg.config subdirectory style within APPDATA.
    On Unix, uses standard XDG config structure.

.OUTPUTS
    System.Hashtable. A hashtable with 'Dir' and 'File' keys containing the directory
    and file paths respectively.

.EXAMPLE
    $paths = Get-TargetPath
    Write-Output "Config directory: $($paths.Dir)"
    Write-Output "Config file: $($paths.File)"
#>
function Get-TargetPath {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    # Cross-platform config directory resolution:
    # 1. Use XDG_CONFIG_HOME if set (Unix standard)
    # 2. Use APPDATA on Windows
    # 3. Fallback to home directory + .config (Unix) or APPDATA equivalent (Windows)
    
    $configBase = $null
    
    if ($env:XDG_CONFIG_HOME) {
        # XDG_CONFIG_HOME is set (Unix standard)
        $configBase = $env:XDG_CONFIG_HOME
    }
    elseif ($env:APPDATA) {
        # Windows: Use APPDATA
        $configBase = $env:APPDATA
    }
    else {
        # Fallback: Use home directory
        if ($env:HOME) {
            $configBase = Join-Path $env:HOME '.config'
        }
        elseif ($env:USERPROFILE) {
            # Windows fallback
            $configBase = Join-Path $env:USERPROFILE 'AppData' 'Roaming'
        }
        else {
            throw 'Unable to determine config directory. Neither XDG_CONFIG_HOME, APPDATA, HOME, nor USERPROFILE are set.'
        }
    }

    # On Windows with APPDATA, use the xdg.config subdirectory style
    # On Unix, use standard XDG structure
    if ($env:APPDATA -and $configBase -eq $env:APPDATA) {
        # Windows: match the path style from the original implementation
        $dir = Join-Path -Path $configBase -ChildPath 'xdg.config\.wrangler\config'
    }
    else {
        # Unix: standard XDG config structure
        $dir = Join-Path -Path $configBase -ChildPath '.wrangler' 'config'
    }
    
    $file = Join-Path -Path $dir -ChildPath 'default.toml'
    return @{ Dir = $dir; File = $file }
}

$paths = Get-TargetPath
$dir = $paths.Dir
$file = $paths.File

Write-Host "Target config directory: $dir"
Write-Host "Target config file: $file"

if (-not $ApiToken) {
    Write-Warning @"
SECURITY NOTICE: This script will store your API token in plaintext in a config file.
Consider using one of these more secure alternatives:
  1. Set CF_API_TOKEN environment variable: `setx CF_API_TOKEN '<token>'` (Windows) or `export CF_API_TOKEN='<token>'` (Unix)
  2. Use `wrangler login` which handles authentication securely
  3. Use Windows Credential Manager or keychain for token storage

Press Ctrl+C to cancel, or Enter to continue with file-based storage.
"@
    $ApiToken = Read-Host -AsSecureString 'Enter Cloudflare API token (will be converted to plaintext in config file)'
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiToken)
    $ApiToken = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) | Out-Null
}

# Ensure directory exists using FileSystem module helper
try {
    Ensure-DirectoryExists -Path $dir
    Write-Host "Directory ready: $dir"
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to create directory: $($_.Exception.Message)" -ErrorRecord $_
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would create config file at: $file" -ForegroundColor Yellow
    Write-Host "[DRY RUN] Would include:" -ForegroundColor Yellow
    if ($ApiToken) {
        Write-Host "  - API token: [REDACTED]" -ForegroundColor Yellow
    }
    if ($AccountId) {
        Write-Host "  - Account ID: $AccountId" -ForegroundColor Yellow
    }
    Write-Host "Run without -DryRun to create the config file." -ForegroundColor Yellow
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "DRY RUN: Would create config file at $file"
}

if (Test-Path -Path $file -and -not $Force) {
    $ok = Read-Host "File already exists at $file. Overwrite? (y/N)"
    if ($ok -notin @('y', 'Y', 'yes', 'YES')) {
        Write-Host 'Aborting; existing file retained.'
        Exit-WithCode -ExitCode [ExitCode]::Success -Message "Operation canceled by user"
    }
}

# Use List for better performance than array concatenation
$content = [System.Collections.Generic.List[string]]::new()
$content.Add('# Wrangler global config created by init-wrangler-config.ps1')
$content.Add('# Replace the token or use `wrangler login` for a more secure setup')
$content.Add("api_token = `"$ApiToken`"")
if ($AccountId) { $content.Add("account_id = `"$AccountId`"") }

Set-Content -Path $file -Value ($content -join "`n") -Encoding UTF8

Write-Host "Wrote config to: $file" -ForegroundColor Green
Write-Host ""
Write-Host "Security Recommendations:" -ForegroundColor Yellow
Write-Host "  - Consider creating a more restrictive API token in the Cloudflare dashboard (least privilege)"
Write-Host "  - For better security, use environment variables instead of config files:"
Write-Host "    Windows: `setx CF_API_TOKEN '<token>'`"
Write-Host "    Unix:    `export CF_API_TOKEN='<token>'`"
Write-Host "  - Use `wrangler login` for interactive sessions (handles authentication securely)"
Write-Host "  - Consider using credential stores (Windows Credential Manager, macOS Keychain) for production"
Write-Host ""
Write-Host "Note: If you used setx, re-run your MCP server in a new shell so the env is picked up."

