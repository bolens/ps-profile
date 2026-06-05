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
function Get-TestNodeModuleSearchPaths {
    $paths = [System.Collections.Generic.List[string]]::new()

    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try {
            $pnpmRootOutput = pnpm root -g 2>&1
            $pnpmRoot = $pnpmRootOutput | Where-Object { $_ -and -not ($_ -match 'error|not found|WARN|\[ERROR\]') } | Select-Object -Last 1
            if ($pnpmRoot -and (Test-Path -LiteralPath $pnpmRoot)) {
                $paths.Add($pnpmRoot.ToString().Trim())
            }
        }
        catch {
            # Fall through to common locations
        }
    }

    foreach ($candidate in @(
            "$env:LOCALAPPDATA\pnpm\global\5\node_modules"
            (Join-Path $env:HOME '.local/share/pnpm/global/5/node_modules')
        )) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            $paths.Add($candidate)
        }
    }

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            $npmRootOutput = npm root -g 2>&1
            $npmRoot = $npmRootOutput | Where-Object { $_ -and -not ($_ -match 'warn|error|npm ERR') } | Select-Object -Last 1
            if ($npmRoot -and (Test-Path -LiteralPath $npmRoot)) {
                $paths.Add($npmRoot.ToString().Trim())
            }
        }
        catch {
            # Ignore npm root lookup failures
        }
    }

    $repoRoots = @()
    if ($env:PS_PROFILE_REPO_ROOT) { $repoRoots += $env:PS_PROFILE_REPO_ROOT }
    if (Get-Command Get-TestRepoRoot -ErrorAction SilentlyContinue) {
        try {
            $repoRoots += Get-TestRepoRoot -StartPath $PSScriptRoot
        }
        catch {
            # Ignore when repo root cannot be resolved from this context
        }
    }

    foreach ($repoRoot in @($repoRoots | Select-Object -Unique)) {
        $localModules = Join-Path $repoRoot 'node_modules'
        if (Test-Path -LiteralPath $localModules) {
            $paths.Add($localModules)
        }
    }

    return @($paths | Select-Object -Unique)
}

function Test-NpmPackageAvailable {
    param([string]$PackageName)

    $moduleSearchPaths = @(Get-TestNodeModuleSearchPaths)
    
    # Build check script
    $checkScript = @"
try {
    require('$PackageName');
    console.log('available');
} catch (e) {
    console.log('not available');
}
"@
    
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempCheck = Join-Path $tempDir ('npm-check-{0}.js' -f [Guid]::NewGuid().ToString())
    Set-Content -Path $tempCheck -Value $checkScript -Encoding UTF8
    try {
        # Set NODE_PATH to include global and repo-local installs
        $originalNodePath = $env:NODE_PATH
        if ($moduleSearchPaths.Count -gt 0) {
            $joinedSearchPaths = $moduleSearchPaths -join [IO.Path]::PathSeparator
            $env:NODE_PATH = if ($env:NODE_PATH) { "$joinedSearchPaths$([IO.Path]::PathSeparator)$env:NODE_PATH" } else { $joinedSearchPaths }
        }

        # Run from a neutral cwd so repo-local node_modules are not picked up
        $previousLocation = Get-Location
        try {
            Set-Location -Path $tempDir
            $result = & node $tempCheck 2>&1 | Where-Object { $_ -match 'available|not available' } | Select-Object -First 1
        }
        finally {
            Set-Location -Path $previousLocation
            if ($null -ne $originalNodePath) {
                $env:NODE_PATH = $originalNodePath
            }
            else {
                Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
            }
        }

        return ($result -eq 'available')
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
}

