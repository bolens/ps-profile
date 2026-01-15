<#
scripts/lib/NodeJs.psm1

.SYNOPSIS
    Node.js execution utilities with pnpm support.

.DESCRIPTION
    Provides functions for executing Node.js scripts with proper NODE_PATH
    configuration to support packages installed via both npm and pnpm.
    Handles automatic detection of pnpm global installations and configures
    Node.js module resolution accordingly.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Gets the pnpm global node_modules path if available.
.DESCRIPTION
    Attempts to locate pnpm's global node_modules directory to support
    packages installed via pnpm. Returns the path if found, otherwise $null.
.OUTPUTS
    System.String
    The path to pnpm's global node_modules directory, or $null if not found.
#>
function Get-PnpmGlobalPath {
    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue

    # First, check common pnpm/Node.js-related environment variables (highest priority)
    $pnpmEnvVars = @('PNPM_HOME', 'PNPM_ROOT', 'NPM_CONFIG_PREFIX', 'NODE_PATH', 'NVM_DIR')
    foreach ($envVar in $pnpmEnvVars) {
        $envVarName = "env:$envVar"
        $envValue = if (Test-Path -Path "Variable:$envVarName" -ErrorAction SilentlyContinue) {
            (Get-Item -Path "Variable:$envVarName" -ErrorAction SilentlyContinue).Value
        }
        else {
            $null
        }
        
        if ($envValue -and -not [string]::IsNullOrWhiteSpace($envValue)) {
            # For PNPM_HOME, PNPM_ROOT - check for node_modules directory
            if ($envVar -eq 'PNPM_HOME' -or $envVar -eq 'PNPM_ROOT') {
                # PNPM_HOME typically points to the pnpm installation directory
                # Check for global node_modules
                $testPath = Join-Path $envValue 'node_modules'
                $pathExists = if ($useValidation) {
                    Test-ValidPath -Path $testPath -PathType Directory
                }
                else {
                    $testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)
                }
                if ($pathExists) {
                    return $testPath
                }
                # Also check if the value itself is a node_modules path
                $pathExists = if ($useValidation) {
                    Test-ValidPath -Path $envValue -PathType Directory
                }
                else {
                    $envValue -and -not [string]::IsNullOrWhiteSpace($envValue) -and (Test-Path -LiteralPath $envValue)
                }
                if ($pathExists -and $envValue -like '*node_modules*') {
                    return $envValue
                }
            }
            # For NPM_CONFIG_PREFIX - this points to npm global installation
            elseif ($envVar -eq 'NPM_CONFIG_PREFIX') {
                $testPath = Join-Path $envValue 'node_modules'
                $pathExists = if ($useValidation) {
                    Test-ValidPath -Path $testPath -PathType Directory
                }
                else {
                    $testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)
                }
                if ($pathExists) {
                    return $testPath
                }
            }
            # For NODE_PATH - this is a semicolon/colon-separated list of paths
            elseif ($envVar -eq 'NODE_PATH') {
                $paths = $envValue -split ([System.IO.Path]::PathSeparator)
                foreach ($path in $paths) {
                    if ($path -and -not [string]::IsNullOrWhiteSpace($path)) {
                        $pathExists = if ($useValidation) {
                            Test-ValidPath -Path $path -PathType Directory
                        }
                        else {
                            $path -and -not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)
                        }
                        if ($pathExists) {
                            return $path
                        }
                    }
                }
            }
            # For NVM_DIR - this points to nvm installation, check for node versions
            elseif ($envVar -eq 'NVM_DIR') {
                # nvm typically has versions in versions/node directory
                $testPath = Join-Path $envValue 'versions' 'node'
                $pathExists = if ($useValidation) {
                    Test-ValidPath -Path $testPath -PathType Directory
                }
                else {
                    $testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)
                }
                if ($pathExists) {
                    # Return the first version's node_modules if available
                    $versions = Get-ChildItem -Path $testPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                    if ($versions) {
                        $latestVersionPath = Join-Path $versions[0].FullName 'lib' 'node_modules'
                        $latestExists = if ($useValidation) {
                            Test-ValidPath -Path $latestVersionPath -PathType Directory
                        }
                        else {
                            $latestVersionPath -and -not [string]::IsNullOrWhiteSpace($latestVersionPath) -and (Test-Path -LiteralPath $latestVersionPath)
                        }
                        if ($latestExists) {
                            return $latestVersionPath
                        }
                    }
                }
            }
        }
    }

    # Fall back to pnpm command if available
    $pnpmGlobalPath = $null
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try {
            $pnpmRootOutput = & pnpm root -g 2>&1
            $exitCode = $LASTEXITCODE
            
            # Only process output if command succeeded
            if ($exitCode -eq 0 -and $pnpmRootOutput) {
                $pnpmRoot = $pnpmRootOutput | Where-Object { 
                    $_ -and 
                    -not [string]::IsNullOrWhiteSpace($_) -and
                    -not ($_ -match 'error|not found|WARN|ERR') 
                } | Select-Object -First 1
                
                if ($pnpmRoot) {
                    $pnpmGlobalPath = $pnpmRoot.ToString().Trim()
                    # Validate that the path exists
                    if ($useValidation) {
                        if (Test-ValidPath -Path $pnpmGlobalPath -PathType Directory) {
                            return $pnpmGlobalPath
                        }
                    }
                    else {
                        # Fallback to manual validation
                        if ($pnpmGlobalPath -and -not [string]::IsNullOrWhiteSpace($pnpmGlobalPath) -and (Test-Path -LiteralPath $pnpmGlobalPath)) {
                            return $pnpmGlobalPath
                        }
                    }
                }
            }
        }
        catch {
            # Fall through to try common location
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 2) {
                    Write-Verbose "[nodejs.get-pnpm-global-path] pnpm root -g command failed: $($_.Exception.Message)"
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [nodejs.get-pnpm-global-path] Error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
    }
    
    # If pnpm global path not found, try common location
    if (-not $pnpmGlobalPath) {
        $commonPnpmPath = "$env:LOCALAPPDATA\pnpm\global\5\node_modules"
        if ($commonPnpmPath -and -not [string]::IsNullOrWhiteSpace($commonPnpmPath) -and (Test-Path -LiteralPath $commonPnpmPath)) {
            $pnpmGlobalPath = $commonPnpmPath
            # Level 3: Log common location found
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Verbose "[nodejs.get-pnpm-global-path] Found pnpm global path at common location: $commonPnpmPath"
            }
        }
    }
    
    # Level 3: Log final result
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        if ($pnpmGlobalPath) {
            Write-Host "  [nodejs.get-pnpm-global-path] Final pnpm global path: $pnpmGlobalPath" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [nodejs.get-pnpm-global-path] No pnpm global path found" -ForegroundColor DarkGray
        }
    }
    
    return $pnpmGlobalPath
}

<#
.SYNOPSIS
    Executes a Node.js script with proper NODE_PATH configuration.
.DESCRIPTION
    Executes a Node.js script, automatically setting NODE_PATH to include
    pnpm's global node_modules directory if available. This ensures packages
    installed via pnpm can be found by Node.js.
.PARAMETER ScriptPath
    The path to the Node.js script to execute.
.PARAMETER Arguments
    Arguments to pass to the Node.js script.
.EXAMPLE
    Invoke-NodeScript -ScriptPath "script.js" -Arguments "arg1", "arg2"
    Executes the Node.js script with the specified arguments.
.OUTPUTS
    System.String
    The output from the Node.js script.
#>
function Invoke-NodeScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )
    
    # Validate script path exists
    if (-not ($ScriptPath -and -not [string]::IsNullOrWhiteSpace($ScriptPath) -and (Test-Path -LiteralPath $ScriptPath))) {
        throw "Node.js script not found: $ScriptPath"
    }
    
    # Check if node command is available
    $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        $errorMessage = "Node.js is not available. Please install Node.js to use this function."
        $errorMessage += "`nSuggestion: Install Node.js from https://nodejs.org/ or use a package manager (scoop, choco, winget)"
        throw $errorMessage
    }
    
    # Validate node executable is actually usable
    try {
        $nodeVersion = & node --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Node.js command exists but failed to execute (exit code: $LASTEXITCODE)"
        }
    }
    catch {
        throw "Node.js command found at '$($nodeCommand.Source)' but is not executable: $($_.Exception.Message)"
    }
    
    $pnpmGlobalPath = Get-PnpmGlobalPath
    $originalNodePath = $env:NODE_PATH
    
    try {
        # Set NODE_PATH to include pnpm global if available
        if ($pnpmGlobalPath) {
            try {
                if ($env:NODE_PATH) {
                    $env:NODE_PATH = "$pnpmGlobalPath;$env:NODE_PATH"
                }
                else {
                    $env:NODE_PATH = $pnpmGlobalPath
                }
            }
            catch {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to set NODE_PATH: $($_.Exception.Message). Continuing without pnpm global path." -OperationName 'nodejs.invoke-script' -Context @{
                            ScriptPath = $ScriptPath
                            PnpmGlobalPath = $pnpmGlobalPath
                            Error = $_.Exception.Message
                        }
                    }
                    else {
                        Write-Warning "[nodejs.invoke-script] Failed to set NODE_PATH: $($_.Exception.Message). Continuing without pnpm global path."
                    }
                }
                # Level 3: Log detailed error information
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [nodejs.invoke-script] NODE_PATH error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
        
        # Execute node script
        # Capture both stdout and stderr, but check exit code to determine if output is valid
        try {
            $output = & node $ScriptPath @Arguments 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return $output
            }
            
            # Build error message
            if (-not $output) {
                throw "Node.js script failed with exit code ${exitCode}: Unknown error (no output from script)"
            }
            
            # Filter out common non-error messages
            $filteredOutput = $output | Where-Object { 
                $_ -notmatch '^npm (WARN|info)' -and 
                $_ -notmatch '^yarn (WARN|info)' 
            }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $output -join "`n"
            }
            
            $fullErrorMessage = "Node.js script failed with exit code $exitCode"
            if ($errorMessage) {
                $fullErrorMessage += ": $errorMessage"
            }
            throw $fullErrorMessage
        }
        catch {
            $errorContext = "Failed to execute Node.js script '$ScriptPath'"
            if ($Arguments -and $Arguments.Count -gt 0) {
                $errorContext += " with arguments: $($Arguments -join ' ')"
            }
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'nodejs.invoke-script' -Context @{
                            ScriptPath = $ScriptPath
                            Arguments = $Arguments
                            ErrorContext = $errorContext
                        }
                    }
                    else {
                        Write-Error "$errorContext`: $($_.Exception.Message)" -ErrorAction Continue
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[nodejs.invoke-script] Execution error details - ScriptPath: $ScriptPath, Arguments: $($Arguments -join ', '), Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)"
                }
            }
            else {
                # Always log critical errors even if debug is off
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'nodejs.invoke-script' -Context @{
                        ScriptPath = $ScriptPath
                        Arguments = $Arguments
                        ErrorContext = $errorContext
                    }
                }
                else {
                    Write-Error "$errorContext`: $($_.Exception.Message)" -ErrorAction Continue
                }
            }
            throw
        }
    }
    finally {
        # Restore original NODE_PATH
        try {
            if ($originalNodePath) {
                $env:NODE_PATH = $originalNodePath
            }
            elseif ($pnpmGlobalPath) {
                Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
            }
        }
        catch {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to restore NODE_PATH: $($_.Exception.Message)" -OperationName 'nodejs.invoke-script' -Context @{
                            ScriptPath = $ScriptPath
                            OriginalNodePath = $originalNodePath
                            PnpmGlobalPath = $pnpmGlobalPath
                            Error = $_.Exception.Message
                        }
                    }
                    else {
                        Write-Warning "[nodejs.invoke-script] Failed to restore NODE_PATH: $($_.Exception.Message)"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [nodejs.invoke-script] NODE_PATH restore error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Sets up NODE_PATH environment variable for Node.js execution.
.DESCRIPTION
    Configures NODE_PATH to include pnpm's global node_modules directory
    if available. Returns a script block that restores the original NODE_PATH
    when disposed. Use this for manual node execution when you need to manage
    the environment yourself.
.EXAMPLE
    $restore = Set-NodePathForPnpm
    try {
        & node script.js
    }
    finally {
        & $restore
    }
.OUTPUTS
    ScriptBlock
    A script block that restores the original NODE_PATH when invoked.
#>
function Set-NodePathForPnpm {
    $pnpmGlobalPath = Get-PnpmGlobalPath
    $originalNodePath = $env:NODE_PATH
    
    if ($pnpmGlobalPath) {
        if ($env:NODE_PATH) {
            $env:NODE_PATH = "$pnpmGlobalPath;$env:NODE_PATH"
        }
        else {
            $env:NODE_PATH = $pnpmGlobalPath
        }
    }
    
    # Return restore script block
    {
        if ($originalNodePath) {
            $env:NODE_PATH = $originalNodePath
        }
        elseif ($pnpmGlobalPath) {
            Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
        }
    }.GetNewClosure()
}

<#
.SYNOPSIS
    Gets the preferred Node.js package manager based on availability and user preference.
.DESCRIPTION
    Determines which Node.js package manager to use based on:
    1. User preference via $env:PS_NODE_PACKAGE_MANAGER ('pnpm', 'npm', 'yarn', 'bun', or 'auto')
    2. Manager availability (checks if commands are installed)
    3. Defaults to 'pnpm' if available, then 'npm', then others
    
    Returns a hashtable with manager information including:
    - Manager: 'pnpm', 'npm', 'yarn', 'bun', or $null
    - Available: $true if the manager is available
    - InstallCommand: Command template for installing packages (e.g., 'pnpm add -g {package}')
    - GlobalFlag: Flag for global installation (e.g., '-g', '--global')
    - LocalFlag: Flag for local installation (usually empty)
.EXAMPLE
    $pmInfo = Get-NodePackageManagerPreference
    if ($pmInfo.Available) {
        $installCmd = $pmInfo.InstallCommand -f 'superjson'
        Write-Host "Install with: $installCmd"
    }
.OUTPUTS
    System.Collections.Hashtable
    Hashtable with Manager, Available, InstallCommand, GlobalFlag, and LocalFlag keys.
#>
function Get-NodePackageManagerPreference {
    # Check user preference
    $preference = if ($env:PS_NODE_PACKAGE_MANAGER) {
        $env:PS_NODE_PACKAGE_MANAGER.ToLower()
    }
    else {
        'auto'
    }
    
    # Check availability of package managers
    $managers = @{
        'pnpm' = @{
            Command        = 'pnpm'
            CheckCommand   = { Get-Command pnpm -ErrorAction SilentlyContinue }
            InstallCommand = 'pnpm add -g {package}'
            GlobalFlag     = '-g'
            LocalFlag      = ''
            Available      = $false
        }
        'npm'  = @{
            Command        = 'npm'
            CheckCommand   = { Get-Command npm -ErrorAction SilentlyContinue }
            InstallCommand = 'npm install -g {package}'
            GlobalFlag     = '-g'
            LocalFlag      = ''
            Available      = $false
        }
        'yarn' = @{
            Command        = 'yarn'
            CheckCommand   = { Get-Command yarn -ErrorAction SilentlyContinue }
            InstallCommand = 'yarn global add {package}'
            GlobalFlag     = 'global'
            LocalFlag      = ''
            Available      = $false
        }
        'bun'  = @{
            Command        = 'bun'
            CheckCommand   = { Get-Command bun -ErrorAction SilentlyContinue }
            InstallCommand = 'bun add -g {package}'
            GlobalFlag     = '-g'
            LocalFlag      = ''
            Available      = $false
        }
    }
    
    # Check availability
    foreach ($key in $managers.Keys) {
        try {
            $managers[$key].Available = (& $managers[$key].CheckCommand) -ne $null
        }
        catch {
            $managers[$key].Available = $false
        }
    }
    
    # Determine manager based on preference
    $selectedManager = switch ($preference) {
        'pnpm' {
            if ($managers['pnpm'].Available) { 'pnpm' } elseif ($managers['npm'].Available) { 'npm' } else { $null }
        }
        'npm' {
            if ($managers['npm'].Available) { 'npm' } elseif ($managers['pnpm'].Available) { 'pnpm' } else { $null }
        }
        'yarn' {
            if ($managers['yarn'].Available) { 'yarn' } elseif ($managers['pnpm'].Available) { 'pnpm' } elseif ($managers['npm'].Available) { 'npm' } else { $null }
        }
        'bun' {
            if ($managers['bun'].Available) { 'bun' } elseif ($managers['pnpm'].Available) { 'pnpm' } elseif ($managers['npm'].Available) { 'npm' } else { $null }
        }
        default {
            # 'auto' or invalid preference - prefer pnpm, then npm, then others
            if ($managers['pnpm'].Available) { 'pnpm' }
            elseif ($managers['npm'].Available) { 'npm' }
            elseif ($managers['yarn'].Available) { 'yarn' }
            elseif ($managers['bun'].Available) { 'bun' }
            else { $null }
        }
    }
    
    if (-not $selectedManager) {
        return @{
            Manager        = $null
            Available      = $false
            InstallCommand = 'npm install -g {package}'
            GlobalFlag     = '-g'
            LocalFlag      = ''
            AllManagers    = $managers
        }
    }
    
    $managerInfo = $managers[$selectedManager]
    
    return @{
        Manager        = $selectedManager
        Available      = $true
        InstallCommand = $managerInfo.InstallCommand
        GlobalFlag     = $managerInfo.GlobalFlag
        LocalFlag      = $managerInfo.LocalFlag
        AllManagers    = $managers
    }
}

<#
.SYNOPSIS
    Gets installation command for a Node.js package using the preferred package manager.
.DESCRIPTION
    Returns the installation command for a Node.js package using the preferred package manager.
    Supports global and local installation modes.
.PARAMETER PackageName
    The name of the package to install.
.PARAMETER Global
    If true, install globally. If false, install locally.
.EXAMPLE
    $cmd = Get-NodePackageInstallCommand -PackageName 'superjson' -Global
    Write-Host "Run: $cmd"
.OUTPUTS
    System.String
    The installation command string.
#>
function Get-NodePackageInstallCommand {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [switch]$Global
    )
    
    $pmInfo = Get-NodePackageManagerPreference
    
    if (-not $pmInfo.Available) {
        # Fallback to npm if no manager available
        $flag = if ($Global) { '-g' } else { '' }
        return "npm install $flag $PackageName".Trim()
    }
    
    if ($Global) {
        $installCmd = $pmInfo.InstallCommand -f $PackageName
        return $installCmd
    }
    else {
        # For local installation, remove global flag
        $baseCmd = $pmInfo.InstallCommand -replace ' -g| --global| global', ''
        return $baseCmd -f $PackageName
    }
}

<#
.SYNOPSIS
    Gets installation recommendation message for missing Node.js packages.
.DESCRIPTION
    Returns a formatted installation recommendation message for one or more Node.js packages.
    Uses the preferred package manager and formats the message appropriately.
.PARAMETER PackageNames
    One or more package names to include in the recommendation.
.PARAMETER Global
    If true, recommend global installation. If false, recommend local installation.
.EXAMPLE
    $msg = Get-NodePackageInstallRecommendation -PackageNames 'superjson', 'json5'
    Write-Host $msg
.OUTPUTS
    System.String
    The installation recommendation message.
#>
function Get-NodePackageInstallRecommendation {
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,
        
        [switch]$Global
    )
    
    $pmInfo = Get-NodePackageManagerPreference
    
    if (-not $pmInfo.Available) {
        $flag = if ($Global) { '-g' } else { '' }
        $packages = $PackageNames -join ' '
        return "npm install $flag $packages".Trim()
    }
    
    if ($Global) {
        # For global installs, install packages individually or together based on manager
        if ($pmInfo.Manager -eq 'yarn') {
            $packages = $PackageNames -join ' '
            return "yarn global add $packages"
        }
        else {
            $packages = $PackageNames -join ' '
            $installCmd = $pmInfo.InstallCommand -replace '\{package\}', $packages
            return $installCmd
        }
    }
    else {
        $baseCmd = $pmInfo.InstallCommand -replace ' -g| --global| global', ''
        $packages = $PackageNames -join ' '
        return $baseCmd -f $packages
    }
}

