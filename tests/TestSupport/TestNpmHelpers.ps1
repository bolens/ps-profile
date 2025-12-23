# ===============================================
# TestNpmHelpers.ps1
# NPM package availability testing utilities
# ===============================================

<#
.SYNOPSIS
    Checks if an npm package is available for use.
.DESCRIPTION
    Tests whether a specified npm package can be required by Node.js.
    Handles both npm and pnpm global package installations by checking
    pnpm's global directory and setting NODE_PATH appropriately.
.PARAMETER PackageName
    The name of the npm package to check (e.g., 'superjson', '@msgpack/msgpack').
.EXAMPLE
    Test-NpmPackageAvailable -PackageName 'superjson'
    Checks if the superjson package is available.
.OUTPUTS
    System.Boolean
    Returns $true if the package is available, $false otherwise.
.NOTES
    This function is used by test files to determine if npm packages are installed
    before running tests that depend on them. It automatically detects pnpm global
    installations and configures Node.js to find packages in pnpm's global directory.
#>
function Test-NpmPackageAvailable {
    param([string]$PackageName)
    
    # Get pnpm global path if available
    $pnpmGlobalPath = $null
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try {
            $pnpmRootOutput = pnpm root -g 2>&1
            $pnpmRoot = $pnpmRootOutput | Where-Object { $_ -and -not ($_ -match 'error|not found|WARN') } | Select-Object -First 1
            if ($pnpmRoot) {
                $pnpmGlobalPath = $pnpmRoot.ToString().Trim()
            }
        }
        catch {
            # Fall through to try common location
        }
    }
    
    # If pnpm global path not found, try common location
    if (-not $pnpmGlobalPath) {
        $commonPnpmPath = "$env:LOCALAPPDATA\pnpm\global\5\node_modules"
        if ($commonPnpmPath -and (Test-Path -LiteralPath $commonPnpmPath)) {
            $pnpmGlobalPath = $commonPnpmPath
        }
    }
    
    # Build check script
    $checkScript = @"
try {
    require('$PackageName');
    console.log('available');
} catch (e) {
    console.log('not available');
}
"@
    
    $tempCheck = Join-Path $env:TEMP "npm-check-$(Get-Random).js"
    Set-Content -Path $tempCheck -Value $checkScript -Encoding UTF8
    try {
        # Set NODE_PATH to include pnpm global if available
        $env:NODE_PATH = if ($pnpmGlobalPath) { $pnpmGlobalPath } else { $env:NODE_PATH }
        $result = & node $tempCheck 2>&1 | Where-Object { $_ -match 'available|not available' } | Select-Object -First 1
        return ($result -eq 'available')
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
        if ($pnpmGlobalPath) { Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue }
    }
}

