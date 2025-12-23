<#
scripts/lib/Command.psm1

.SYNOPSIS
    Command availability checking utilities.

.DESCRIPTION
    Provides functions for checking if commands are available on the system,
    with caching support for performance.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Cache module for caching support
# Use SafeImport module if available, otherwise fall back to manual check
if ($PSScriptRoot -and -not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $parentDir = Split-Path -Parent $PSScriptRoot
    if ($parentDir -and -not [string]::IsNullOrWhiteSpace($parentDir)) {
        $safeImportModulePath = Join-Path $parentDir 'core' 'SafeImport.psm1'
        if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
            Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
        }
    }
    
    $cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'
    if ($cacheModulePath -and -not [string]::IsNullOrWhiteSpace($cacheModulePath)) {
        if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
            $null = Import-ModuleSafely -ModulePath $cacheModulePath -ErrorAction SilentlyContinue
        }
        else {
            # Fallback to manual validation
            if (Test-Path -LiteralPath $cacheModulePath) {
                try {
                    Import-Module $cacheModulePath -ErrorAction Stop
                }
                catch {
                    # Cache module is optional - function will work without it, just without caching
                    Write-Verbose "Failed to import Cache module: $($_.Exception.Message). Caching features will be unavailable."
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Tests if a command is available on the system.

.DESCRIPTION
    Checks if a command (executable, function, cmdlet, or alias) is available.
    Uses Test-CachedCommand if available from profile, otherwise falls back to Get-Command.
    This provides a consistent way to check command availability across scripts.

.PARAMETER CommandName
    The name of the command to check.

.OUTPUTS
    System.Boolean. Returns $true if command is available, $false otherwise.

.EXAMPLE
    if (Test-CommandAvailable -CommandName 'git') {
        & git --version
    }
#>
function Test-CommandAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$CommandName
    )

    # Handle null or empty command name
    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return $false
    }

    # Validate command name using Validation module if available
    if (Get-Command Test-ValidString -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidString -Value $CommandName)) {
            return $false
        }
    }

    # Check cache first (cache for 5 minutes)
    # Use CacheKey module if available for consistent key generation
    $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
        # New-CacheKey expects Components to be an array, wrap single string in array
        New-CacheKey -Prefix 'CommandAvailable' -Components @($CommandName)
    }
    else {
        "CommandAvailable_$CommandName"
    }
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    # Use Test-CachedCommand if available from profile (more efficient)
    if ((Test-Path Function:Test-CachedCommand) -or (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue)) {
        $result = Test-CachedCommand $CommandName
        if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
            Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds 300
        }
        return $result
    }

    # Fallback: use Get-Command
    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    $result = $null -ne $command
    if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
        Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds 300
    }
    return $result
}

<#
.SYNOPSIS
    Resolves an InstallCommand from external-tools configuration using preferred package managers.
.DESCRIPTION
    Takes an InstallCommand hashtable (with Windows/Linux/MacOS keys) or string and resolves it
    to use the preferred package manager (pnpm/npm/yarn/bun for Node packages, uv/pip/conda/poetry/pipenv for Python packages).
    For non-package-manager commands (like scoop, apt, brew), returns the platform-specific command as-is.
.PARAMETER InstallCommand
    The InstallCommand value from external-tools configuration. Can be a hashtable with Windows/Linux/MacOS keys or a string.
.PARAMETER PackageName
    Optional package name. If not provided, attempts to extract from the command.
.EXAMPLE
    $cmd = Resolve-InstallCommand -InstallCommand @{ Windows = 'npm install -g qrcode'; Linux = 'npm install -g qrcode' }
    Write-Host $cmd
.OUTPUTS
    System.String
    The resolved installation command for the current platform.
#>
function Resolve-InstallCommand {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        $InstallCommand,
        
        [string]$PackageName
    )
    
    # Import required modules if available
    if ($PSScriptRoot -and -not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $libRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        if ($libRoot -and -not [string]::IsNullOrWhiteSpace($libRoot)) {
            $platformModule = Join-Path $libRoot 'core' 'Platform.psm1'
            if ($platformModule -and -not [string]::IsNullOrWhiteSpace($platformModule) -and (Test-Path -LiteralPath $platformModule)) {
                Import-Module $platformModule -DisableNameChecking -ErrorAction SilentlyContinue
            }
            
            $pythonModule = Join-Path $libRoot 'runtime' 'Python.psm1'
            if ($pythonModule -and -not [string]::IsNullOrWhiteSpace($pythonModule) -and (Test-Path -LiteralPath $pythonModule)) {
                Import-Module $pythonModule -DisableNameChecking -ErrorAction SilentlyContinue
            }
            
            $nodeJsModule = Join-Path $libRoot 'runtime' 'NodeJs.psm1'
            if ($nodeJsModule -and -not [string]::IsNullOrWhiteSpace($nodeJsModule) -and (Test-Path -LiteralPath $nodeJsModule)) {
                Import-Module $nodeJsModule -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Get platform
    $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
        (Get-Platform).Name
    }
    elseif ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        'Windows'
    }
    elseif ($IsLinux) {
        'Linux'
    }
    elseif ($IsMacOS) {
        'macOS'
    }
    else {
        'Windows' # Default fallback
    }
    
    # Get platform-specific command
    $platformCommand = if ($InstallCommand -is [hashtable]) {
        $InstallCommand[$platform]
    }
    elseif ($InstallCommand -is [string]) {
        $InstallCommand
    }
    else {
        return $null
    }
    
    # Handle empty string - return empty string (not null) to preserve original input
    if ($null -eq $platformCommand) {
        return $null
    }
    if ([string]::IsNullOrWhiteSpace($platformCommand) -and $InstallCommand -is [hashtable]) {
        # Empty string in hashtable means missing platform command
        return $null
    }
    # If input was a string and it's empty, return empty string
    if ([string]::IsNullOrWhiteSpace($platformCommand) -and $InstallCommand -is [string]) {
        return ''
    }
    
    # Check if this is a Node.js package manager command
    if ($platformCommand -match '^\s*(npm|pnpm|yarn|bun)\s+') {
        # Extract package name if not provided
        if (-not $PackageName) {
            # Handle: pnpm add -g package, npm install -g package, yarn global add package
            if ($platformCommand -match '(?:add|install|global add)\s+(?:-g\s+|--global\s+)?([^\s]+)') {
                $PackageName = $matches[1]
            }
            # Handle: pnpm add -g package1 package2 (take first)
            elseif ($platformCommand -match '(?:add|install)\s+(?:-g\s+|--global\s+)?([^\s]+)') {
                $PackageName = $matches[1]
            }
        }
        
        if ($PackageName -and (Get-Command Get-NodePackageInstallRecommendation -ErrorAction SilentlyContinue)) {
            $isGlobal = $platformCommand -match '-g|--global|global'
            try {
                # Try with PackageNames (plural) first
                $cmd = Get-Command Get-NodePackageInstallRecommendation -ErrorAction Stop
                if ($cmd.Parameters.ContainsKey('PackageNames')) {
                    return Get-NodePackageInstallRecommendation -PackageNames @($PackageName) -Global:$isGlobal
                }
                elseif ($cmd.Parameters.ContainsKey('PackageName')) {
                    # Fallback for test support version with singular parameter
                    return Get-NodePackageInstallRecommendation -PackageName $PackageName -Global:$isGlobal
                }
            }
            catch {
                # If call fails, return platform command as-is
                Write-Verbose "Failed to get Node.js package recommendation: $($_.Exception.Message)"
            }
        }
    }
    
    # Check if this is a Python package manager command
    if ($platformCommand -match '^\s*(uv\s+)?pip\s+install|^\s*(pip|conda|poetry|pipenv)\s+') {
        # Extract package name if not provided
        if (-not $PackageName) {
            # Handle: uv pip install --system package, pip install --user package
            if ($platformCommand -match '(?:install|add)\s+(?:--system|--user|-g|--global)?\s*([^\s]+)') {
                $PackageName = $matches[1]
            }
            # Fallback: just get first word after install/add
            elseif ($platformCommand -match '(?:install|add)\s+([^\s]+)') {
                $PackageName = $matches[1]
            }
        }
        
        if ($PackageName -and (Get-Command Get-PythonPackageInstallRecommendation -ErrorAction SilentlyContinue)) {
            $isGlobal = $platformCommand -match '--system|--global|-g' -and $platformCommand -notmatch '--user'
            try {
                # Try with PackageNames (plural) first
                $cmd = Get-Command Get-PythonPackageInstallRecommendation -ErrorAction Stop
                if ($cmd.Parameters.ContainsKey('PackageNames')) {
                    return Get-PythonPackageInstallRecommendation -PackageNames @($PackageName) -Global:$isGlobal
                }
                elseif ($cmd.Parameters.ContainsKey('PackageName')) {
                    # Fallback for test support version with singular parameter
                    return Get-PythonPackageInstallRecommendation -PackageName $PackageName -Global:$isGlobal
                }
            }
            catch {
                # If call fails, return platform command as-is
                Write-Verbose "Failed to get Python package recommendation: $($_.Exception.Message)"
            }
        }
    }
    
    # Return platform-specific command as-is for other package managers (scoop, apt, brew, etc.)
    return $platformCommand
}

<#
.SYNOPSIS
    Invokes a command if it is available, otherwise uses a fallback.

.DESCRIPTION
    Checks if a command exists, and if so, invokes it with the provided arguments.
    If the command does not exist, executes a fallback scriptblock or returns a fallback value.
    This provides a consistent pattern for conditional command execution.

.PARAMETER CommandName
    The name of the command to check for and execute.

.PARAMETER Arguments
    Arguments to pass to the command if it exists. Can be a hashtable for named parameters
    or an array for positional parameters.

.PARAMETER FallbackValue
    Value to return if command does not exist.

.PARAMETER FallbackScriptBlock
    ScriptBlock to execute if command does not exist. Takes precedence over FallbackValue.

.PARAMETER ErrorAction
    Error action to use when checking for command. Defaults to SilentlyContinue.

.OUTPUTS
    The result of the command execution or fallback value/scriptblock result.

.EXAMPLE
    $result = Invoke-CommandIfAvailable -CommandName 'Format-LocaleDate' `
        -Arguments @{ Date = (Get-Date); Format = 'yyyy-MM-dd' } `
        -FallbackScriptBlock { param($d, $f) $d.ToString($f) }

.EXAMPLE
    $value = Invoke-CommandIfAvailable -CommandName 'Get-CustomValue' `
        -FallbackValue 'default'
#>
function Invoke-CommandIfAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [object]$Arguments,

        [object]$FallbackValue,

        [scriptblock]$FallbackScriptBlock
    )

    # Check if command is available
    if (Test-CommandAvailable -CommandName $CommandName) {
        try {
            # Execute command with arguments
            if ($null -ne $Arguments) {
                if ($Arguments -is [hashtable]) {
                    return & $CommandName @Arguments
                }
                elseif ($Arguments -is [array]) {
                    return & $CommandName $Arguments
                }
                else {
                    return & $CommandName $Arguments
                }
            }
            else {
                return & $CommandName
            }
        }
        catch {
            Write-Verbose "Failed to execute command '$CommandName': $($_.Exception.Message)"
            # Fall through to fallback
        }
    }

    # Use fallback
    if ($null -ne $FallbackScriptBlock) {
        if ($null -ne $Arguments) {
            if ($Arguments -is [hashtable]) {
                return & $FallbackScriptBlock @Arguments
            }
            elseif ($Arguments -is [array]) {
                return & $FallbackScriptBlock $Arguments
            }
            else {
                return & $FallbackScriptBlock $Arguments
            }
        }
        else {
            return & $FallbackScriptBlock
        }
    }

    return $FallbackValue
}

<#
.SYNOPSIS
    Gets an install hint string for a tool from requirements configuration.
.DESCRIPTION
    Loads requirements configuration and resolves the install command for a tool,
    returning a formatted install hint string suitable for use with Write-MissingToolWarning.
    Falls back to a default install command if the tool is not found in requirements.
.PARAMETER ToolName
    Name of the tool to get install hint for.
.PARAMETER RepoRoot
    Optional repository root path. If not provided, attempts to detect from current location.
    If provided, uses this path for loading requirements.
.PARAMETER DefaultInstallCommand
    Default install command to use if tool is not found in requirements.
    Defaults to "scoop install {ToolName}".
.OUTPUTS
    System.String. Formatted install hint (e.g., "Install with: scoop install toolname").
.EXAMPLE
    $hint = Get-ToolInstallHint -ToolName 'gitleaks'
    Write-MissingToolWarning -Tool 'gitleaks' -InstallHint $hint
    
    Gets install hint for gitleaks and uses it in a warning.
#>
function Get-ToolInstallHint {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        
        [string]$RepoRoot,
        
        [string]$DefaultInstallCommand
    )
    
    # Try to use preference-aware install hint if available
    if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        try {
            $hint = Get-PreferenceAwareInstallHint -ToolName $ToolName -DefaultInstallCommand $DefaultInstallCommand
            # Extract command from hint (remove "Install with: " prefix if present)
            if ($hint -match '^Install with:\s*(.+)$') {
                return $matches[1]
            }
            elseif ($hint -and -not ($hint -match '^Install with:')) {
                return $hint
            }
        }
        catch {
            # Fall through to default behavior
        }
    }
    
    # Set default install command if not provided
    if ([string]::IsNullOrWhiteSpace($DefaultInstallCommand)) {
        $DefaultInstallCommand = "scoop install $ToolName"
    }
    
    # Load requirements if available
    $requirements = $null
    if (Get-Command Import-Requirements -ErrorAction SilentlyContinue) {
        $repoRootPath = if ($RepoRoot) {
            $RepoRoot
        }
        elseif (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            # Try to get repo root from current location
            $currentPath = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            Get-RepoRoot -ScriptPath $currentPath -ErrorAction SilentlyContinue
        }
        else {
            # Fallback: try to find requirements directory
            $currentPath = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
            $testPath = $currentPath
            for ($i = 0; $i -lt 5; $i++) {
                $requirementsPath = Join-Path $testPath 'requirements' 'load-requirements.ps1'
                if (Test-Path -LiteralPath $requirementsPath) {
                    $testPath
                    break
                }
                $testPath = Split-Path -Parent $testPath
                if ([string]::IsNullOrWhiteSpace($testPath) -or $testPath -eq $currentPath) {
                    break
                }
            }
            $null
        }
        
        if ($repoRootPath) {
            $requirements = Import-Requirements -RepoRoot $repoRootPath -UseCache -ErrorAction SilentlyContinue
        }
    }
    
    # Check if tool is in requirements
    if (-not $requirements -or 
        -not $requirements.ExternalTools -or 
        -not $requirements.ExternalTools[$ToolName]) {
        return "Install with: $DefaultInstallCommand"
    }
    
    $toolReq = $requirements.ExternalTools[$ToolName]
    if (-not $toolReq.InstallCommand) {
        return "Install with: $DefaultInstallCommand"
    }
    
    # Resolve install command for current platform
    $installCmd = if (Get-Command Resolve-InstallCommand -ErrorAction SilentlyContinue) {
        Resolve-InstallCommand -InstallCommand $toolReq.InstallCommand -PackageName $ToolName
    }
    else {
        # Fallback: resolve platform-specific command manually
        $platform = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
        elseif ($IsLinux) { 'Linux' }
        elseif ($IsMacOS) { 'macOS' }
        else { 'Windows' }
        if ($toolReq.InstallCommand -is [hashtable]) {
            $toolReq.InstallCommand[$platform]
        }
        else {
            $toolReq.InstallCommand
        }
    }
    
    if ($installCmd) {
        return "Install with: $installCmd"
    }
    else {
        return "Install with: $DefaultInstallCommand"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-CommandAvailable',
    'Resolve-InstallCommand',
    'Invoke-CommandIfAvailable',
    'Get-ToolInstallHint'
)

