# ===============================================
# ToolInstallRegistry.ps1
# Tool installation method registry and fallback chains
# ===============================================
# Depends on: MissingToolWarnings.ps1 (platform utilities)
# ===============================================

<#
.SYNOPSIS
    Tool installation method registry and preference-aware fallback chains.

.DESCRIPTION
    Provides the core registry and resolution functions used by InstallHintResolver.ps1
    and Write-MissingToolWarning to generate accurate install hints:
    - Get-ToolInstallMethodRegistry: hashtable of tool -> install method mappings
    - Get-ToolSpecificInstallMethod: look up a single tool's preferred method
    - Test-CommandAvailable: thin wrapper around Get-Command with error suppression
    - Get-InstallMethodFallbackChain: ordered fallback list for a tool type
    - Get-SystemPackageManagerFallbackChain: platform-aware package manager order
    - Test-PreferenceAwareInstallPreferences: validate current env-var preferences
    - Set-PreferenceAwareInstallPreferences: set env-var preferences interactively
    - Show-MissingToolWarningsTable: display a summary table of all known tools

.NOTES
    Load before InstallHintResolver.ps1.
#>

<#
.SYNOPSIS
    Tool-specific installation method registry.
.DESCRIPTION
    Returns a hashtable mapping tool names to their preferred installation methods
    across different platforms and package managers.
.OUTPUTS
    System.Collections.Hashtable
#>
function global:Get-ToolInstallMethodRegistry {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    # Registry structure: ToolName -> Platform -> PackageManager -> InstallCommand
    return @{
        'pnpm'           = @{
            'Windows' = @{
                'scoop'      = 'scoop install pnpm'
                'winget'     = 'winget install pnpm'
                'npm'        = 'npm install -g pnpm'
                'chocolatey' = 'choco install pnpm -y'
            }
            'Linux'   = @{
                'npm' = 'npm install -g pnpm'
                'apt' = 'sudo apt install pnpm'
                'yum' = 'sudo yum install pnpm'
                'dnf' = 'sudo dnf install pnpm'
            }
            'macOS'   = @{
                'homebrew' = 'brew install pnpm'
                'npm'      = 'npm install -g pnpm'
            }
        }
        'uv'             = @{
            'Windows' = @{
                'scoop'  = 'scoop install uv'
                'pip'    = 'pip install uv'
                'winget' = 'winget install astral-sh.uv'
            }
            'Linux'   = @{
                'curl' = 'curl -LsSf https://astral.sh/uv/install.sh | sh'
                'pip'  = 'pip install uv'
            }
            'macOS'   = @{
                'homebrew' = 'brew install uv'
                'pip'      = 'pip install uv'
            }
        }
        'poetry'         = @{
            'Windows' = @{
                'scoop' = 'scoop install poetry'
                'pip'   = 'pip install poetry'
                'uv'    = 'uv tool install poetry'
            }
            'Linux'   = @{
                'curl' = 'curl -sSL https://install.python-poetry.org | python3 -'
                'pip'  = 'pip install poetry'
            }
            'macOS'   = @{
                'homebrew' = 'brew install poetry'
                'pip'      = 'pip install poetry'
            }
        }
        'cargo-binstall' = @{
            'Windows' = @{
                'cargo' = 'cargo install cargo-binstall'
                'scoop' = 'scoop install cargo-binstall'
            }
            'Linux'   = @{
                'cargo' = 'cargo install cargo-binstall'
                'curl'  = 'curl -L --proto "=https" --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash'
            }
            'macOS'   = @{
                'cargo'    = 'cargo install cargo-binstall'
                'homebrew' = 'brew install cargo-binstall'
            }
        }
        'bd'             = @{
            'Windows' = @{
                'powershell' = 'irm https://raw.githubusercontent.com/steveyegge/beads/main/install.ps1 | iex'
                'npm'        = 'npm install -g @beads/bd'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'  = 'npm install -g @beads/bd'
            }
            'macOS'   = @{
                'homebrew' = 'brew tap steveyegge/beads && brew install bd'
                'curl'     = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'      = 'npm install -g @beads/bd'
            }
        }
        'beads'          = @{
            'Windows' = @{
                'powershell' = 'irm https://raw.githubusercontent.com/steveyegge/beads/main/install.ps1 | iex'
                'npm'        = 'npm install -g @beads/bd'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'  = 'npm install -g @beads/bd'
            }
            'macOS'   = @{
                'homebrew' = 'brew tap steveyegge/beads && brew install bd'
                'curl'     = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'      = 'npm install -g @beads/bd'
            }
        }
        'sqlite3'        = @{
            'Windows' = @{
                'scoop'      = 'scoop install sqlite'
                'winget'     = 'winget install sqlite'
                'chocolatey' = 'choco install sqlite -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install sqlite3'
                'dnf'    = 'sudo dnf install sqlite'
                'yum'    = 'sudo yum install sqlite'
                'pacman' = 'sudo pacman -S sqlite'
            }
            'macOS'   = @{
                'homebrew' = 'brew install sqlite'
            }
        }
    }
}

<#
.SYNOPSIS
    Gets tool-specific installation method.
.DESCRIPTION
    Retrieves the best installation method for a specific tool based on preferences,
    platform, and availability.
.PARAMETER ToolName
    Name of the tool to get installation method for.
.PARAMETER Platform
    Target platform (Windows, Linux, macOS). If not specified, auto-detects.
.PARAMETER PreferredMethod
    Preferred installation method (scoop, npm, pip, etc.). If not specified, uses preferences.
.OUTPUTS
    System.String
#>
function global:Get-ToolSpecificInstallMethod {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        
        [string]$Platform,
        
        [string]$PreferredMethod
    )
    
    $registry = Get-ToolInstallMethodRegistry
    $toolLower = $ToolName.ToLower()
    
    if (-not $registry.ContainsKey($toolLower)) {
        return $null
    }
    
    $toolMethods = $registry[$toolLower]
    
    # Detect platform if not provided
    if (-not $Platform) {
        $Platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
    }
    
    if (-not $toolMethods.ContainsKey($Platform)) {
        return $null
    }
    
    $platformMethods = $toolMethods[$Platform]
    
    # If preferred method specified, use it if available
    if ($PreferredMethod) {
        $prefLower = $PreferredMethod.ToLower()
        if ($platformMethods.ContainsKey($prefLower)) {
            $method = $platformMethods[$prefLower]
            # Check if the method is available
            if ($prefLower -eq 'scoop' -and (Test-CachedCommand 'scoop')) {
                return $method
            }
            elseif ($prefLower -eq 'npm' -and (Test-CachedCommand 'npm')) {
                return $method
            }
            elseif ($prefLower -eq 'pip' -and (Test-CachedCommand 'pip')) {
                return $method
            }
            elseif ($prefLower -eq 'winget' -and (Test-CachedCommand 'winget')) {
                return $method
            }
            elseif ($prefLower -eq 'homebrew' -and (Test-CachedCommand 'brew')) {
                return $method
            }
            elseif ($prefLower -eq 'cargo' -and (Test-CachedCommand 'cargo')) {
                return $method
            }
            elseif ($prefLower -eq 'curl') {
                return $method
            }
            elseif ($prefLower -eq 'powershell' -and ($Platform -eq 'Windows' -or $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
                return $method
            }
        }
    }
    
    # Try to use preferences
    $systemPm = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower() } else { 'auto' }
    
    # Try preferred system package manager first
    if ($systemPm -ne 'auto' -and $platformMethods.ContainsKey($systemPm)) {
        $method = $platformMethods[$systemPm]
        if (Test-CommandAvailable -CommandName $systemPm) {
            return $method
        }
    }
    
    # Try language-specific preferences
    if ($toolLower -in @('pnpm', 'npm', 'yarn', 'bun')) {
        $nodePm = if ($env:PS_NODE_PACKAGE_MANAGER) { $env:PS_NODE_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        if ($nodePm -ne 'auto' -and $platformMethods.ContainsKey($nodePm)) {
            $method = $platformMethods[$nodePm]
            if (Test-CommandAvailable -CommandName $nodePm) {
                return $method
            }
        }
    }
    elseif ($toolLower -in @('uv', 'poetry', 'pipenv', 'hatch', 'pdm', 'rye')) {
        $pythonPm = if ($env:PS_PYTHON_PACKAGE_MANAGER) { $env:PS_PYTHON_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        if ($pythonPm -ne 'auto' -and $platformMethods.ContainsKey($pythonPm)) {
            $method = $platformMethods[$pythonPm]
            if (Test-CommandAvailable -CommandName $pythonPm) {
                return $method
            }
        }
    }
    
    # Auto-detect: try methods in order of preference
    $preferredOrder = @('powershell', 'scoop', 'homebrew', 'npm', 'pip', 'cargo', 'winget', 'curl', 'apt', 'yum', 'dnf')
    foreach ($methodName in $preferredOrder) {
        if ($platformMethods.ContainsKey($methodName)) {
            if ($methodName -eq 'curl' -or $methodName -eq 'powershell' -or (Test-CommandAvailable -CommandName $methodName)) {
                # For powershell, verify we're on Windows
                if ($methodName -eq 'powershell' -and $Platform -ne 'Windows' -and -not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
                    continue
                }
                return $platformMethods[$methodName]
            }
        }
    }
    
    # Return first available method
    foreach ($methodName in $platformMethods.Keys) {
        return $platformMethods[$methodName]
    }
    
    return $null
}

<#
.SYNOPSIS
    Helper function to test if a command is available.
.DESCRIPTION
    Checks if a command is available in the current environment.
.PARAMETER CommandName
    Name of the command to check.
.OUTPUTS
    System.Boolean
#>
function global:Test-CommandAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )
    
    # Map common package manager names to their commands
    $commandMap = @{
        'scoop'      = 'scoop'
        'homebrew'   = 'brew'
        'chocolatey' = 'choco'
        'npm'        = 'npm'
        'pip'        = 'pip'
        'cargo'      = 'cargo'
        'winget'     = 'winget'
        'apt'        = 'apt'
        'yum'        = 'yum'
        'dnf'        = 'dnf'
        'pacman'     = 'pacman'
    }
    
    $actualCommand = if ($commandMap.ContainsKey($CommandName.ToLower())) {
        $commandMap[$CommandName.ToLower()]
    }
    else {
        $CommandName
    }
    
    return [bool](Get-Command $actualCommand -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Generates a prioritized fallback chain for installation methods.
.DESCRIPTION
    Creates a formatted string with multiple installation options in priority order,
    showing the preferred method first, followed by available fallbacks.
.PARAMETER PreferredMethod
    The preferred installation command (if available).
.PARAMETER FallbackMethods
    Array of fallback installation commands in priority order.
.PARAMETER MaxFallbacks
    Maximum number of fallback options to show (default: 3).
.OUTPUTS
    System.String
#>
function global:Get-InstallMethodFallbackChain {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$PreferredMethod,
        
        [string[]]$FallbackMethods = @(),
        
        [int]$MaxFallbacks = 3
    )
    
    $methods = @()
    
    # Add preferred method if provided
    if ($PreferredMethod) {
        $methods += $PreferredMethod
    }
    
    # Add available fallbacks (up to MaxFallbacks)
    $fallbackCount = 0
    foreach ($fallback in $FallbackMethods) {
        if ($fallbackCount -ge $MaxFallbacks) {
            break
        }
        # Don't add duplicates
        if ($fallback -and $fallback -ne $PreferredMethod -and $fallback -notin $methods) {
            $methods += $fallback
            $fallbackCount++
        }
    }
    
    # Format the chain
    if ($methods.Count -eq 0) {
        return $null
    }
    elseif ($methods.Count -eq 1) {
        return $methods[0]
    }
    else {
        # Format: "primary (or: fallback1, or: fallback2, or: fallback3)"
        $primary = $methods[0]
        $fallbacks = $methods[1..($methods.Count - 1)]
        $fallbackStr = ($fallbacks | ForEach-Object { "or: $_" }) -join ', '
        return "$primary ($fallbackStr)"
    }
}

<#
.SYNOPSIS
    Gets prioritized fallback chain for system package managers.
.DESCRIPTION
    Returns installation commands for system package managers in priority order,
    checking availability and respecting preferences.
.PARAMETER ToolName
    Name of the tool to install.
.PARAMETER Platform
    Target platform (Windows, Linux, macOS). If not specified, auto-detects.
.PARAMETER PreferredManager
    Preferred package manager name (scoop, winget, etc.).
.OUTPUTS
    System.Collections.Hashtable
#>
function global:Get-SystemPackageManagerFallbackChain {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        
        [string]$Platform,
        
        [string]$PreferredManager
    )
    
    # Detect platform if not provided
    if (-not $Platform) {
        $Platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
    }
    
    # Define platform-specific package managers in priority order
    $packageManagers = switch ($Platform) {
        'Windows' {
            @(
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
                @{ Name = 'winget'; Command = 'winget'; InstallCmd = "winget install $ToolName" }
                @{ Name = 'chocolatey'; Command = 'choco'; InstallCmd = "choco install $ToolName -y" }
            )
        }
        'Linux' {
            @(
                @{ Name = 'apt'; Command = 'apt'; InstallCmd = "sudo apt install $ToolName" }
                @{ Name = 'dnf'; Command = 'dnf'; InstallCmd = "sudo dnf install $ToolName" }
                @{ Name = 'yum'; Command = 'yum'; InstallCmd = "sudo yum install $ToolName" }
                @{ Name = 'pacman'; Command = 'pacman'; InstallCmd = "sudo pacman -S $ToolName" }
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
            )
        }
        'macOS' {
            @(
                @{ Name = 'homebrew'; Command = 'brew'; InstallCmd = "brew install $ToolName" }
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
            )
        }
        default {
            @(
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
            )
        }
    }
    
    # Check availability and build priority list
    $availableMethods = @()
    $preferredMethod = $null
    $preferredIndex = -1
    
    for ($i = 0; $i -lt $packageManagers.Count; $i++) {
        $pm = $packageManagers[$i]
        $isAvailable = Test-CommandAvailable -CommandName $pm.Command
        
        if ($isAvailable) {
            $availableMethods += $pm.InstallCmd
            
            # Check if this is the preferred manager
            if ($PreferredManager -and $pm.Name.ToLower() -eq $PreferredManager.ToLower()) {
                $preferredMethod = $pm.InstallCmd
                $preferredIndex = $availableMethods.Count - 1
            }
        }
    }
    
    # Reorder if preferred method is found
    if ($preferredIndex -gt 0) {
        $preferred = $availableMethods[$preferredIndex]
        $availableMethods = @($preferred) + ($availableMethods | Where-Object { $_ -ne $preferred })
    }
    
    # Generate fallback chain
    $fallbackChain = Get-InstallMethodFallbackChain -PreferredMethod $preferredMethod -FallbackMethods $availableMethods -MaxFallbacks 3
    
    return @{
        Preferred     = $preferredMethod
        Available     = $availableMethods
        FallbackChain = $fallbackChain
        Platform      = $Platform
    }
}

<#
.SYNOPSIS
    Validates preference-aware install preferences.
.DESCRIPTION
    Checks if the current preferences are valid and the specified tools are available.
.PARAMETER PreferenceType
    Type of preference to validate (python-package, node-package, system-package, etc.).
    If not specified, validates all preferences.
.OUTPUTS
    System.Collections.Hashtable
#>
function global:Test-PreferenceAwareInstallPreferences {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'system-package', 'all')]
        [string]$PreferenceType = 'all'
    )
    
    $results = @{
        Valid       = $true
        Errors      = @()
        Warnings    = @()
        Preferences = @{}
    }
    
    # Validate Python package manager preference
    if ($PreferenceType -in @('python-package', 'all')) {
        $pythonPm = if ($env:PS_PYTHON_PACKAGE_MANAGER) { $env:PS_PYTHON_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_PYTHON_PACKAGE_MANAGER'] = $pythonPm
        
        if ($pythonPm -ne 'auto') {
            $validPythonPms = @('pip', 'uv', 'poetry', 'pipenv', 'hatch', 'pdm', 'rye', 'conda')
            if ($pythonPm -notin $validPythonPms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_PYTHON_PACKAGE_MANAGER: $pythonPm. Valid values: $($validPythonPms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $pythonPm)) {
                $results.Warnings += "PS_PYTHON_PACKAGE_MANAGER is set to '$pythonPm' but the command is not available"
            }
        }
    }
    
    # Validate Node package manager preference
    if ($PreferenceType -in @('node-package', 'all')) {
        $nodePm = if ($env:PS_NODE_PACKAGE_MANAGER) { $env:PS_NODE_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_NODE_PACKAGE_MANAGER'] = $nodePm
        
        if ($nodePm -ne 'auto') {
            $validNodePms = @('npm', 'pnpm', 'yarn', 'bun')
            if ($nodePm -notin $validNodePms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_NODE_PACKAGE_MANAGER: $nodePm. Valid values: $($validNodePms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $nodePm)) {
                $results.Warnings += "PS_NODE_PACKAGE_MANAGER is set to '$nodePm' but the command is not available"
            }
        }
    }
    
    # Validate Python runtime preference
    if ($PreferenceType -in @('python-runtime', 'all')) {
        $pythonRuntime = if ($env:PS_PYTHON_RUNTIME) { $env:PS_PYTHON_RUNTIME.ToLower() } else { 'auto' }
        $results.Preferences['PS_PYTHON_RUNTIME'] = $pythonRuntime
        
        if ($pythonRuntime -ne 'auto') {
            $validRuntimes = @('python', 'python3', 'py')
            if ($pythonRuntime -notin $validRuntimes) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_PYTHON_RUNTIME: $pythonRuntime. Valid values: $($validRuntimes -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $pythonRuntime)) {
                $results.Warnings += "PS_PYTHON_RUNTIME is set to '$pythonRuntime' but the command is not available"
            }
        }
    }
    
    # Validate Rust package manager preference
    if ($PreferenceType -in @('rust-package', 'all')) {
        $rustPm = if ($env:PS_RUST_PACKAGE_MANAGER) { $env:PS_RUST_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_RUST_PACKAGE_MANAGER'] = $rustPm
        
        if ($rustPm -ne 'auto') {
            $validRustPms = @('cargo', 'cargo-binstall')
            if ($rustPm -notin $validRustPms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_RUST_PACKAGE_MANAGER: $rustPm. Valid values: $($validRustPms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $rustPm)) {
                $results.Warnings += "PS_RUST_PACKAGE_MANAGER is set to '$rustPm' but the command is not available"
            }
        }
    }
    
    # Validate system package manager preference
    if ($PreferenceType -in @('system-package', 'all')) {
        $systemPm = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_SYSTEM_PACKAGE_MANAGER'] = $systemPm
        
        if ($systemPm -ne 'auto') {
            $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
                try { (Get-Platform).Name } catch { 'Windows' }
            }
            else {
                if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
                elseif ($IsLinux) { 'Linux' }
                elseif ($IsMacOS) { 'macOS' }
                else { 'Windows' }
            }
            
            $validSystemPms = switch ($platform) {
                'Windows' { @('scoop', 'winget', 'chocolatey', 'auto') }
                'Linux' { @('apt', 'yum', 'dnf', 'pacman', 'scoop', 'auto') }
                'macOS' { @('homebrew', 'scoop', 'auto') }
                default { @('scoop', 'auto') }
            }
            
            if ($systemPm -notin $validSystemPms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_SYSTEM_PACKAGE_MANAGER for $platform : $systemPm. Valid values: $($validSystemPms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $systemPm)) {
                $results.Warnings += "PS_SYSTEM_PACKAGE_MANAGER is set to '$systemPm' but the command is not available"
            }
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Interactive preference setup for install hints.
.DESCRIPTION
    Guides the user through setting up their preferences for package managers and runtimes.
.PARAMETER PreferenceType
    Type of preference to set up (python-package, node-package, system-package, etc.).
    If not specified, sets up all preferences.
.PARAMETER NonInteractive
    If specified, skips interactive prompts and uses defaults.
.OUTPUTS
    System.Collections.Hashtable
#>
function global:Set-PreferenceAwareInstallPreferences {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'system-package', 'all')]
        [string]$PreferenceType = 'all',
        
        [switch]$NonInteractive
    )
    
    $results = @{
        Preferences = @{}
        Updated     = @()
    }
    
    # Python package manager
    if ($PreferenceType -in @('python-package', 'all')) {
        $current = if ($env:PS_PYTHON_PACKAGE_MANAGER) { $env:PS_PYTHON_PACKAGE_MANAGER } else { 'auto' }
        $options = @('auto', 'pip', 'uv', 'poetry', 'pipenv', 'hatch', 'pdm', 'rye', 'conda')
        $available = $options | Where-Object { $_ -eq 'auto' -or (Test-CommandAvailable -CommandName $_) }
        
        if (-not $NonInteractive) {
            Write-Host "`nPython Package Manager Preference" -ForegroundColor Cyan
            Write-Host "Current: $current" -ForegroundColor Gray
            Write-Host "Available options:" -ForegroundColor Gray
            for ($i = 0; $i -lt $options.Count; $i++) {
                $marker = if ($options[$i] -in $available) { '✓' } else { '✗' }
                $default = if ($options[$i] -eq $current) { ' (current)' } else { '' }
                Write-Host "  $($i + 1). $marker $($options[$i])$default" -ForegroundColor $(if ($options[$i] -in $available) { 'Green' } else { 'Yellow' })
            }
            
            $choice = Read-Host "`nSelect preference (1-$($options.Count), or press Enter for '$current')"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = $current
            }
            elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
                $choice = $options[[int]$choice - 1]
            }
        }
        else {
            $choice = $current
        }
        
        if ($choice -ne $current) {
            $env:PS_PYTHON_PACKAGE_MANAGER = $choice
            $results.Preferences['PS_PYTHON_PACKAGE_MANAGER'] = $choice
            $results.Updated += 'PS_PYTHON_PACKAGE_MANAGER'
        }
    }
    
    # Node package manager
    if ($PreferenceType -in @('node-package', 'all')) {
        $current = if ($env:PS_NODE_PACKAGE_MANAGER) { $env:PS_NODE_PACKAGE_MANAGER } else { 'auto' }
        $options = @('auto', 'npm', 'pnpm', 'yarn', 'bun')
        $available = $options | Where-Object { $_ -eq 'auto' -or (Test-CommandAvailable -CommandName $_) }
        
        if (-not $NonInteractive) {
            Write-Host "`nNode Package Manager Preference" -ForegroundColor Cyan
            Write-Host "Current: $current" -ForegroundColor Gray
            Write-Host "Available options:" -ForegroundColor Gray
            for ($i = 0; $i -lt $options.Count; $i++) {
                $marker = if ($options[$i] -in $available) { '✓' } else { '✗' }
                $default = if ($options[$i] -eq $current) { ' (current)' } else { '' }
                Write-Host "  $($i + 1). $marker $($options[$i])$default" -ForegroundColor $(if ($options[$i] -in $available) { 'Green' } else { 'Yellow' })
            }
            
            $choice = Read-Host "`nSelect preference (1-$($options.Count), or press Enter for '$current')"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = $current
            }
            elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
                $choice = $options[[int]$choice - 1]
            }
        }
        else {
            $choice = $current
        }
        
        if ($choice -ne $current) {
            $env:PS_NODE_PACKAGE_MANAGER = $choice
            $results.Preferences['PS_NODE_PACKAGE_MANAGER'] = $choice
            $results.Updated += 'PS_NODE_PACKAGE_MANAGER'
        }
    }
    
    # System package manager
    if ($PreferenceType -in @('system-package', 'all')) {
        $current = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER } else { 'auto' }
        $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
        
        $options = switch ($platform) {
            'Windows' { @('auto', 'scoop', 'winget', 'chocolatey') }
            'Linux' { @('auto', 'apt', 'yum', 'dnf', 'pacman', 'scoop') }
            'macOS' { @('auto', 'homebrew', 'scoop') }
            default { @('auto', 'scoop') }
        }
        $available = $options | Where-Object { $_ -eq 'auto' -or (Test-CommandAvailable -CommandName $_) }
        
        if (-not $NonInteractive) {
            Write-Host "`nSystem Package Manager Preference ($platform)" -ForegroundColor Cyan
            Write-Host "Current: $current" -ForegroundColor Gray
            Write-Host "Available options:" -ForegroundColor Gray
            for ($i = 0; $i -lt $options.Count; $i++) {
                $marker = if ($options[$i] -in $available) { '✓' } else { '✗' }
                $default = if ($options[$i] -eq $current) { ' (current)' } else { '' }
                Write-Host "  $($i + 1). $marker $($options[$i])$default" -ForegroundColor $(if ($options[$i] -in $available) { 'Green' } else { 'Yellow' })
            }
            
            $choice = Read-Host "`nSelect preference (1-$($options.Count), or press Enter for '$current')"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = $current
            }
            elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
                $choice = $options[[int]$choice - 1]
            }
        }
        else {
            $choice = $current
        }
        
        if ($choice -ne $current) {
            $env:PS_SYSTEM_PACKAGE_MANAGER = $choice
            $results.Preferences['PS_SYSTEM_PACKAGE_MANAGER'] = $choice
            $results.Updated += 'PS_SYSTEM_PACKAGE_MANAGER'
        }
    }
    
    # Validate preferences after setting
    $validation = Test-PreferenceAwareInstallPreferences -PreferenceType $PreferenceType
    if (-not $validation.Valid) {
        Write-Warning "Some preferences are invalid: $($validation.Errors -join '; ')"
    }
    if ($validation.Warnings.Count -gt 0) {
        foreach ($warning in $validation.Warnings) {
            Write-Warning $warning
        }
    }
    
    if (-not $NonInteractive -and $results.Updated.Count -gt 0) {
        Write-Host "`nPreferences updated. Add these to your .env file to persist:" -ForegroundColor Green
        foreach ($key in $results.Updated) {
            Write-Host "  $key=$($results.Preferences[$key])" -ForegroundColor Yellow
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Displays all collected missing tool warnings in a formatted table.
.DESCRIPTION
    Shows a table of all missing tools that were detected during profile loading,
    including their installation hints. This provides a consolidated view instead
    of sporadic warnings during fragment loading.
.OUTPUTS
    None
#>
function global:Show-MissingToolWarningsTable {
    [CmdletBinding()]
    param()

    if (Test-EnvBool $env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS) {
        return
    }

    if (-not $global:CollectedMissingToolWarnings -or $global:CollectedMissingToolWarnings.Count -eq 0) {
        return
    }

    # Sort warnings by tool name for consistent display
    $sortedWarnings = $global:CollectedMissingToolWarnings | Sort-Object -Property Tool

    Write-Host "`n[Missing Tools]" -ForegroundColor Yellow
    Write-Host ""

    # Create table data
    $tableData = $sortedWarnings | ForEach-Object {
        $tool = $_.Tool
        $installHint = if ($_.InstallHint) {
            # Clean up common prefixes like "Install with:", "Install from:", etc.
            $hint = $_.InstallHint.Trim()
            if ($hint -match '^(Install with:|Install from:)\s*(.+)$') {
                $matches[2].Trim()
            }
            else {
                $hint
            }
        }
        else {
            # Extract install hint from message if available
            $message = $_.Message
            if ($message -match 'not found\.\s*(.+)') {
                $matches[1].Trim()
            }
            else {
                'See tool documentation'
            }
        }

        [PSCustomObject]@{
            Tool        = $tool
            InstallHint = $installHint
        }
    }

    # Display table - use direct Write-Host to avoid Out-String hang
    # Format-Table | Out-String can hang in some scenarios, so we format manually
    if ($tableData.Count -gt 0) {
        # Calculate column widths
        $toolWidth = [Math]::Max(4, ($tableData | ForEach-Object { $_.Tool.Length } | Measure-Object -Maximum).Maximum)
        $hintWidth = [Math]::Max(11, ($tableData | ForEach-Object { $_.InstallHint.Length } | Measure-Object -Maximum).Maximum)
        
        # Write header
        Write-Host ("{0,-$toolWidth} {1}" -f 'Tool', 'InstallHint') -ForegroundColor Cyan
        Write-Host ("{0,-$toolWidth} {1}" -f ('-' * $toolWidth), ('-' * $hintWidth)) -ForegroundColor Cyan
        
        # Write rows
        foreach ($row in $tableData) {
            Write-Host ("{0,-$toolWidth} {1}" -f $row.Tool, $row.InstallHint)
        }
    }

    # Clear collected warnings after display
    $global:CollectedMissingToolWarnings.Clear()
}

