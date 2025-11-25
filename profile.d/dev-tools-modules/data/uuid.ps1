# ===============================================
# UUID (Universally Unique Identifier) utilities
# ===============================================

<#
.SYNOPSIS
    Initializes UUID generator utility functions.
.DESCRIPTION
    Sets up internal functions for generating UUIDs of various versions.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
    UUID v5 requires Node.js and uuid package.
#>
function Initialize-DevTools-Uuid {
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
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'NodeJs.psm1'
        if (Test-Path $nodeJsModulePath) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # UUID Generator
    Set-Item -Path Function:Global:_New-Uuid -Value {
        param(
            [ValidateSet('v1', 'v4', 'v5')]
            [string]$Version = 'v4'
        )
        switch ($Version) {
            'v1' {
                # Time-based UUID (simplified version using GUID)
                [guid]::NewGuid().ToString()
            }
            'v4' {
                [guid]::NewGuid().ToString()
            }
            'v5' {
                # Name-based UUID (requires namespace and name)
                throw "UUID v5 requires namespace and name. Use New-UuidV5 -Namespace <guid> -Name <string>"
            }
        }
    } -Force

    Set-Item -Path Function:Global:_New-UuidV5 -Value {
        param([string]$Namespace, [string]$Name)
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use UUID v5 generation."
            }
            $nodeScript = @"
try {
    const { v5: uuidv5 } = require('uuid');
    const namespace = process.argv[1];
    const name = process.argv[2];
    const uuid = uuidv5(name, namespace);
    console.log(uuid);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: uuid package is not installed. Install it with: npm install -g uuid');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "uuid-v5-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Namespace, $Name
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
            Write-Error "Failed to generate UUID v5: $_"
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Generates a UUID (Universally Unique Identifier).
.DESCRIPTION
    Generates a UUID of the specified version. Supports v1 (time-based) and v4 (random).
    Note: v1 uses a simplified implementation. For true time-based UUIDs, use external libraries.
.PARAMETER Version
    The UUID version to generate. Default is v4 (random).
.EXAMPLE
    New-Uuid
    Generates a random UUID v4.
.EXAMPLE
    New-Uuid -Version v1
    Generates a time-based UUID v1 (simplified).
.OUTPUTS
    System.String
    The generated UUID string.
#>
function New-Uuid {
    param(
        [ValidateSet('v1', 'v4')]
        [string]$Version = 'v4'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-Uuid @PSBoundParameters
}
Set-Alias -Name uuid -Value New-Uuid -ErrorAction SilentlyContinue
Set-Alias -Name guid -Value New-Uuid -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Generates a UUID v5 (name-based).
.DESCRIPTION
    Generates a UUID v5 from a namespace and name using SHA-1 hashing.
    Requires Node.js and uuid package.
.PARAMETER Namespace
    The namespace UUID (e.g., DNS, URL namespace).
.PARAMETER Name
    The name to generate UUID from.
.EXAMPLE
    New-UuidV5 -Namespace "6ba7b810-9dad-11d1-80b4-00c04fd430c8" -Name "example.com"
    Generates a UUID v5 for the given namespace and name.
.OUTPUTS
    System.String
    The generated UUID v5 string.
#>
function New-UuidV5 {
    param([string]$Namespace, [string]$Name)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-UuidV5 @PSBoundParameters
}
Set-Alias -Name uuid-v5 -Value New-UuidV5 -ErrorAction SilentlyContinue

