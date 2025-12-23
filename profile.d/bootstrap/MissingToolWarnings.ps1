# ===============================================
# MissingToolWarnings.ps1
# Missing tool warning utilities
# ===============================================

<#
.SYNOPSIS
    Gets platform-specific tool availability mapping.
.DESCRIPTION
    Returns a hashtable mapping tool names to their supported platforms.
    Tools not in this mapping are assumed to be cross-platform.
.OUTPUTS
    System.Collections.Hashtable
#>
function global:Get-PlatformSpecificTools {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    # Map of tool names to their supported platforms
    # Tools listed here will only show warnings on supported platforms
    return @{
        # macOS/Linux only tools
        'brew'       = @('macOS', 'Linux')
        'homebrew'   = @('macOS', 'Linux')
        
        # Linux-specific tools
        'apt'        = @('Linux')
        'yum'        = @('Linux')
        'dnf'        = @('Linux')
        'pacman'     = @('Linux')
        'apk'        = @('Linux')
        
        # Windows-specific tools
        'winget'     = @('Windows')
        'choco'      = @('Windows')
        'chocolatey' = @('Windows')
        
        # Platform-specific version managers
        'asdf'       = @('Linux', 'macOS')  # Can work on Windows with WSL but typically Unix-only
        
        # Other platform-specific tools can be added here
    }
}

<#
.SYNOPSIS
    Checks if a tool is available on the current platform.
.DESCRIPTION
    Returns true if the tool should show warnings on the current platform,
    false if it's platform-specific and not available on this platform.
    Uses the Platform module's Get-Platform function if available.
.PARAMETER Tool
    Name of the tool to check.
.OUTPUTS
    System.Boolean
#>
function global:Test-ToolAvailableOnPlatform {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Tool
    )

    $platformTools = Get-PlatformSpecificTools
    $toolLower = $Tool.ToLower().Trim()

    # If tool is not in the platform-specific mapping, assume it's cross-platform
    if (-not $platformTools.ContainsKey($toolLower)) {
        return $true
    }

    # Get current platform using Platform module if available
    $currentPlatform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
        try {
            (Get-Platform).Name
        }
        catch {
            # If Get-Platform fails, fall back to basic detection
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Unknown' }
        }
    }
    else {
        # Platform module not available, use basic detection
        if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
        elseif ($IsLinux) { 'Linux' }
        elseif ($IsMacOS) { 'macOS' }
        else { 'Unknown' }
    }

    # Check if current platform is in the supported platforms list
    $supportedPlatforms = $platformTools[$toolLower]
    return $supportedPlatforms -contains $currentPlatform
}

<#
.SYNOPSIS
    Writes a tool detection warning only once per session.
.DESCRIPTION
    Emits a warning about a missing optional tool unless warnings are globally
    suppressed or the message has already been shown in the current session.
    Platform-specific tools will only show warnings on their supported platforms.
.PARAMETER Tool
    Unique identifier for the tool (used for de-duplication).
.PARAMETER InstallHint
    Optional installation hint appended to the default warning text.
.PARAMETER Message
    Full warning message to emit instead of the default format.
.PARAMETER Force
    When specified, emits the warning even when it has already been shown.
#>
function global:Write-MissingToolWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tool,

        [string]$InstallHint,

        [string]$Message,

        [switch]$Force
    )

    if (Test-EnvBool $env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS) {
        return
    }

    if (-not $global:MissingToolWarnings) {
        return
    }

    # Check if tool is available on current platform
    if (-not (Test-ToolAvailableOnPlatform -Tool $Tool)) {
        # Tool is platform-specific and not available on this platform, suppress warning
        return
    }

    $displayName = if ([string]::IsNullOrWhiteSpace($Tool)) { 'Tool' } else { $Tool.Trim() }
    $normalized = if ([string]::IsNullOrWhiteSpace($Tool)) { 'unknown-tool' } else { $Tool.Trim() }

    if (-not $Force -and $global:MissingToolWarnings.ContainsKey($normalized)) {
        return
    }

    $global:MissingToolWarnings[$normalized] = $true

    $warningText = if ($Message) {
        $Message
    }
    elseif ($InstallHint) {
        "$displayName not found. $InstallHint"
    }
    else {
        "$displayName not found."
    }

    # Collect warning for batch display instead of showing immediately
    if (-not $global:CollectedMissingToolWarnings) {
        $global:CollectedMissingToolWarnings = [System.Collections.Generic.List[hashtable]]::new()
    }
    
    # Check if we already have this tool in the collection
    $existingIndex = -1
    for ($i = 0; $i -lt $global:CollectedMissingToolWarnings.Count; $i++) {
        if ($global:CollectedMissingToolWarnings[$i].Tool -eq $normalized) {
            $existingIndex = $i
            break
        }
    }
    
    $warningEntry = @{
        Tool        = $displayName
        Normalized  = $normalized
        Message     = $warningText
        InstallHint = $InstallHint
    }
    
    if ($existingIndex -ge 0) {
        # Update existing entry (in case Force was used or message changed)
        $global:CollectedMissingToolWarnings[$existingIndex] = $warningEntry
    }
    else {
        # Add new entry
        $global:CollectedMissingToolWarnings.Add($warningEntry)
    }
}

<#
.SYNOPSIS
    Clears cached missing tool warnings.
.DESCRIPTION
    Removes warning suppression entries so subsequent calls may emit warnings
    again. When no Tool parameter is provided, all cached warnings are cleared.
.PARAMETER Tool
    Optional set of tool names whose warning entries should be cleared.
.OUTPUTS
    System.Boolean
#>
function global:Clear-MissingToolWarnings {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string[]]$Tool
    )

    if (-not $global:MissingToolWarnings) {
        return $false
    }

    if (-not $Tool -or $Tool.Count -eq 0) {
        $global:MissingToolWarnings.Clear()
        return $true
    }

    $cleared = $false

    foreach ($entry in $Tool) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $normalized = $entry.Trim()
        $removed = $null
        if ($global:MissingToolWarnings.TryRemove($normalized, [ref]$removed)) {
            $cleared = $true
        }
    }

    return $cleared
}

<#
.SYNOPSIS
    Gets a preference-aware install hint for a tool.
.DESCRIPTION
    Generates an install hint string that respects user preferences for:
    - Python package managers (PS_PYTHON_PACKAGE_MANAGER)
    - Node.js package managers (PS_NODE_PACKAGE_MANAGER)
    - Python runtime (PS_PYTHON_RUNTIME)
    - Rust package managers (PS_RUST_PACKAGE_MANAGER)
    - Go package managers (PS_GO_PACKAGE_MANAGER)
    - Java build tools (PS_JAVA_BUILD_TOOL)
    - Ruby package managers (PS_RUBY_PACKAGE_MANAGER)
    - PHP package managers (PS_PHP_PACKAGE_MANAGER)
    - .NET package managers (PS_DOTNET_PACKAGE_MANAGER)
    - Dart package managers (PS_DART_PACKAGE_MANAGER)
    - Elixir package managers (PS_ELIXIR_PACKAGE_MANAGER)
    
    Falls back to sensible defaults if preferences are not set or tools are not available.
.PARAMETER ToolName
    Name of the tool to get install hint for.
.PARAMETER ToolType
    Type of tool: 'python-package', 'node-package', 'python-runtime', 'rust-package', 
    'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 
    'dart-package', 'elixir-package', or 'generic'.
    If not specified, attempts to auto-detect based on tool name.
.PARAMETER DefaultInstallCommand
    Default install command to use if preference detection fails.
    For Python packages, should include {package} placeholder.
    For Node packages, should include {package} placeholder.
.EXAMPLE
    $hint = Get-PreferenceAwareInstallHint -ToolName 'pipenv' -ToolType 'python-package'
    Write-MissingToolWarning -Tool 'pipenv' -InstallHint $hint
    
    Gets install hint for pipenv using preferred Python package manager.
.EXAMPLE
    $hint = Get-PreferenceAwareInstallHint -ToolName 'typescript' -ToolType 'node-package'
    Write-MissingToolWarning -Tool 'typescript' -InstallHint $hint
    
    Gets install hint for typescript using preferred Node package manager.
.OUTPUTS
    System.String
    Formatted install hint (e.g., "Install with: uv tool install pipenv").
#>
function global:Get-PreferenceAwareInstallHint {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        
        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'generic')]
        [string]$ToolType = 'generic',
        
        [string]$DefaultInstallCommand
    )
    
    # Check tool-specific installation method registry first
    $toolSpecificMethod = Get-ToolSpecificInstallMethod -ToolName $ToolName
    if ($toolSpecificMethod) {
        return "Install with: $toolSpecificMethod"
    }
    
    # Auto-detect tool type if not specified
    if ($ToolType -eq 'generic') {
        # Common Python package managers
        $pythonManagers = @('pipenv', 'poetry', 'hatch', 'pdm', 'rye', 'uv', 'pip', 'conda')
        # Common Node package managers
        $nodeManagers = @('npm', 'pnpm', 'yarn', 'bun')
        # Python runtime tools
        $pythonRuntimes = @('python', 'python3', 'py')
        # Rust tools
        $rustTools = @('cargo', 'rustup', 'rustc', 'cargo-binstall', 'cargo-watch', 'cargo-audit', 'cargo-outdated')
        # Go tools
        $goTools = @('go', 'goreleaser', 'mage', 'golangci-lint')
        # Java build tools
        $javaTools = @('mvn', 'maven', 'gradle', 'ant', 'sbt', 'kotlinc', 'scalac')
        # Ruby tools
        $rubyTools = @('gem', 'bundler', 'ruby', 'rake')
        # PHP tools
        $phpTools = @('composer', 'pecl', 'pear', 'php')
        # .NET tools
        $dotnetTools = @('nuget', 'dotnet', 'paket')
        # Dart tools
        $dartTools = @('dart', 'flutter', 'pub')
        # Elixir tools
        $elixirTools = @('mix', 'hex', 'elixir', 'iex')
        
        $toolLower = $ToolName.ToLower()
        
        if ($pythonManagers -contains $toolLower) {
            $ToolType = 'python-package'
        }
        elseif ($nodeManagers -contains $toolLower) {
            $ToolType = 'node-package'
        }
        elseif ($pythonRuntimes -contains $toolLower) {
            $ToolType = 'python-runtime'
        }
        elseif ($rustTools -contains $toolLower) {
            $ToolType = 'rust-package'
        }
        elseif ($goTools -contains $toolLower) {
            $ToolType = 'go-package'
        }
        elseif ($javaTools -contains $toolLower) {
            $ToolType = 'java-build-tool'
        }
        elseif ($rubyTools -contains $toolLower) {
            $ToolType = 'ruby-package'
        }
        elseif ($phpTools -contains $toolLower) {
            $ToolType = 'php-package'
        }
        elseif ($dotnetTools -contains $toolLower) {
            $ToolType = 'dotnet-package'
        }
        elseif ($dartTools -contains $toolLower) {
            $ToolType = 'dart-package'
        }
        elseif ($elixirTools -contains $toolLower) {
            $ToolType = 'elixir-package'
        }
        # Check if it's a Python package (common patterns)
        elseif ($ToolName -match '^(pip|poetry|pipenv|hatch|pdm|rye|uv|conda)') {
            $ToolType = 'python-package'
        }
        # Check if it's a Node package (common patterns)
        elseif ($ToolName -match '^(npm|pnpm|yarn|bun)') {
            $ToolType = 'node-package'
        }
        # Check if it's a Rust tool (cargo-*)
        elseif ($ToolName -match '^cargo-') {
            $ToolType = 'rust-package'
        }
        # Check if it's a Go tool
        elseif ($ToolName -match '^(go-|golang)') {
            $ToolType = 'go-package'
        }
    }
    
    # Handle Python package managers
    if ($ToolType -eq 'python-package') {
        # Try to use Python package manager preference
        if (Get-Command Get-PythonPackageManagerPreference -ErrorAction SilentlyContinue) {
            try {
                $pmInfo = Get-PythonPackageManagerPreference
                if ($pmInfo -and $pmInfo.Available -and $pmInfo.Manager) {
                    $manager = $pmInfo.Manager
                    
                    # Generate install command based on manager
                    $preferredCmd = switch ($manager) {
                        'uv' {
                            "uv tool install $ToolName"
                        }
                        'pip' {
                            # Check if we have a preferred Python runtime
                            $pythonCmd = if (Get-Command Get-PythonExecutable -ErrorAction SilentlyContinue) {
                                try {
                                    $pythonExe = Get-PythonExecutable
                                    if ($pythonExe) {
                                        $pythonExe
                                    }
                                    else {
                                        'python'
                                    }
                                }
                                catch {
                                    'python'
                                }
                            }
                            else {
                                'python'
                            }
                            "$pythonCmd -m pip install $ToolName"
                        }
                        'conda' {
                            "conda install -c conda-forge $ToolName"
                        }
                        'poetry' {
                            "poetry add $ToolName"
                        }
                        'pipenv' {
                            "pipenv install $ToolName"
                        }
                        default {
                            "pip install $ToolName"
                        }
                    }
                    
                    # Build fallback chain for Python package managers
                    $fallbackMethods = @()
                    $pythonCmd = if (Get-Command Get-PythonExecutable -ErrorAction SilentlyContinue) {
                        try {
                            $exe = Get-PythonExecutable
                            if ($exe) { $exe } else { 'python' }
                        }
                        catch { 'python' }
                    }
                    else { 'python' }
                    
                    # Add alternative Python package managers as fallbacks
                    if ($manager -ne 'uv' -and (Test-CommandAvailable -CommandName 'uv')) {
                        $fallbackMethods += "uv tool install $ToolName"
                    }
                    if ($manager -ne 'pip' -and (Test-CommandAvailable -CommandName 'pip')) {
                        $fallbackMethods += "$pythonCmd -m pip install $ToolName"
                    }
                    if ($manager -ne 'poetry' -and (Test-CommandAvailable -CommandName 'poetry')) {
                        $fallbackMethods += "poetry add $ToolName"
                    }
                    
                    # Generate fallback chain
                    $fallbackChain = Get-InstallMethodFallbackChain -PreferredMethod $preferredCmd -FallbackMethods $fallbackMethods -MaxFallbacks 2
                    
                    if ($fallbackChain) {
                        return "Install with: $fallbackChain"
                    }
                    else {
                        return "Install with: $preferredCmd"
                    }
                }
            }
            catch {
                # Fall through to default
            }
        }
        
        # Fallback: use default or generate based on common patterns
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        # Smart fallback based on tool name
        # Use platform-aware system package manager detection
        $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
        
        $hasScoop = Get-Command scoop -ErrorAction SilentlyContinue
        $hasBrew = Get-Command brew -ErrorAction SilentlyContinue
        
        if ($ToolName -eq 'uv') {
            $runtimeInstall = switch ($platform) {
                'Windows' { if ($hasScoop) { "scoop install uv" } else { "pip install uv" } }
                'Linux' { "curl -LsSf https://astral.sh/uv/install.sh | sh" }
                'macOS' { if ($hasBrew) { "brew install uv" } else { "pip install uv" } }
                default { "pip install uv" }
            }
            return "Install with: $runtimeInstall"
        }
        elseif ($ToolName -eq 'poetry') {
            $runtimeInstall = switch ($platform) {
                'Windows' { if ($hasScoop) { "scoop install poetry" } else { "pip install poetry" } }
                'Linux' { "curl -sSL https://install.python-poetry.org | python3 -" }
                'macOS' { if ($hasBrew) { "brew install poetry" } else { "pip install poetry" } }
                default { "pip install poetry" }
            }
            return "Install with: $runtimeInstall (or: uv tool install poetry, or: pip install poetry)"
        }
        elseif ($ToolName -eq 'pipenv') {
            $runtimeInstall = switch ($platform) {
                'Windows' { if ($hasScoop) { "scoop install pipenv" } else { "pip install pipenv" } }
                'Linux' { "pip install pipenv" }
                'macOS' { if ($hasBrew) { "brew install pipenv" } else { "pip install pipenv" } }
                default { "pip install pipenv" }
            }
            return "Install with: $runtimeInstall (or: uv tool install pipenv)"
        }
        elseif ($ToolName -eq 'hatch') {
            $runtimeInstall = switch ($platform) {
                'Windows' { if ($hasScoop) { "scoop install hatch" } else { "pip install hatch" } }
                'Linux' { "pip install hatch" }
                'macOS' { if ($hasBrew) { "brew install hatch" } else { "pip install hatch" } }
                default { "pip install hatch" }
            }
            return "Install with: $runtimeInstall (or: uv tool install hatch)"
        }
        else {
            return "Install with: pip install $ToolName (or: uv tool install $ToolName)"
        }
    }
    
    # Handle Node package managers
    if ($ToolType -eq 'node-package') {
        # Try to use Node package manager preference
        if (Get-Command Get-NodePackageManagerPreference -ErrorAction SilentlyContinue) {
            try {
                $pmInfo = Get-NodePackageManagerPreference
                if ($pmInfo -and $pmInfo.Available -and $pmInfo.Manager) {
                    $manager = $pmInfo.Manager
                    
                    # Generate install command based on manager
                    $preferredCmd = switch ($manager) {
                        'pnpm' {
                            "pnpm add -g $ToolName"
                        }
                        'npm' {
                            "npm install -g $ToolName"
                        }
                        'yarn' {
                            "yarn global add $ToolName"
                        }
                        'bun' {
                            "bun add -g $ToolName"
                        }
                        default {
                            "npm install -g $ToolName"
                        }
                    }
                    
                    # Build fallback chain for Node package managers
                    $fallbackMethods = @()
                    
                    # Add alternative Node package managers as fallbacks
                    if ($manager -ne 'pnpm' -and (Test-CommandAvailable -CommandName 'pnpm')) {
                        $fallbackMethods += "pnpm add -g $ToolName"
                    }
                    if ($manager -ne 'npm' -and (Test-CommandAvailable -CommandName 'npm')) {
                        $fallbackMethods += "npm install -g $ToolName"
                    }
                    if ($manager -ne 'yarn' -and (Test-CommandAvailable -CommandName 'yarn')) {
                        $fallbackMethods += "yarn global add $ToolName"
                    }
                    if ($manager -ne 'bun' -and (Test-CommandAvailable -CommandName 'bun')) {
                        $fallbackMethods += "bun add -g $ToolName"
                    }
                    
                    # Generate fallback chain
                    $fallbackChain = Get-InstallMethodFallbackChain -PreferredMethod $preferredCmd -FallbackMethods $fallbackMethods -MaxFallbacks 2
                    
                    if ($fallbackChain) {
                        return "Install with: $fallbackChain"
                    }
                    else {
                        return "Install with: $preferredCmd"
                    }
                }
            }
            catch {
                # Fall through to default
            }
        }
        
        # Fallback: use default or generate based on common patterns
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        # Smart fallback based on tool name
        # Use platform-aware system package manager for runtime installs
        $systemPmCmd = if ($env:PS_SYSTEM_PACKAGE_MANAGER) {
            $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
        
        $hasScoop = Get-Command scoop -ErrorAction SilentlyContinue
        $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
        $hasBrew = Get-Command brew -ErrorAction SilentlyContinue
        
        if ($ToolName -eq 'npm') {
            $runtimeInstall = switch ($platform) {
                'Windows' {
                    if (($systemPmCmd -eq 'scoop' -and $hasScoop) -or ($systemPmCmd -eq 'auto' -and $hasScoop)) {
                        "scoop install nodejs"
                    }
                    elseif ($hasWinget) {
                        "winget install OpenJS.NodeJS"
                    }
                    else {
                        "scoop install nodejs (or winget install OpenJS.NodeJS)"
                    }
                }
                'Linux' { "sudo apt install nodejs npm (or use your distribution's package manager)" }
                'macOS' {
                    if (($systemPmCmd -eq 'homebrew' -and $hasBrew) -or ($systemPmCmd -eq 'auto' -and $hasBrew)) {
                        "brew install node"
                    }
                    else {
                        "brew install node"
                    }
                }
                default { "scoop install nodejs" }
            }
            return "Install with: $runtimeInstall"
        }
        elseif ($ToolName -eq 'pnpm') {
            $runtimeInstall = switch ($platform) {
                'Windows' {
                    if (($systemPmCmd -eq 'scoop' -and $hasScoop) -or ($systemPmCmd -eq 'auto' -and $hasScoop)) {
                        "scoop install pnpm"
                    }
                    elseif ($hasWinget) {
                        "winget install pnpm"
                    }
                    else {
                        "scoop install pnpm"
                    }
                }
                'Linux' { "npm install -g pnpm (or sudo apt install pnpm)" }
                'macOS' {
                    if (($systemPmCmd -eq 'homebrew' -and $hasBrew) -or ($systemPmCmd -eq 'auto' -and $hasBrew)) {
                        "brew install pnpm"
                    }
                    else {
                        "npm install -g pnpm"
                    }
                }
                default { "scoop install pnpm" }
            }
            return "Install with: $runtimeInstall"
        }
        elseif ($ToolName -eq 'yarn') {
            $runtimeInstall = switch ($platform) {
                'Windows' {
                    if (($systemPmCmd -eq 'scoop' -and $hasScoop) -or ($systemPmCmd -eq 'auto' -and $hasScoop)) {
                        "scoop install yarn"
                    }
                    elseif ($hasWinget) {
                        "winget install Yarn.Yarn"
                    }
                    else {
                        "scoop install yarn"
                    }
                }
                'Linux' { "npm install -g yarn (or sudo apt install yarn)" }
                'macOS' {
                    if (($systemPmCmd -eq 'homebrew' -and $hasBrew) -or ($systemPmCmd -eq 'auto' -and $hasBrew)) {
                        "brew install yarn"
                    }
                    else {
                        "npm install -g yarn"
                    }
                }
                default { "scoop install yarn" }
            }
            return "Install with: $runtimeInstall"
        }
        elseif ($ToolName -eq 'bun') {
            $runtimeInstall = switch ($platform) {
                'Windows' {
                    if (($systemPmCmd -eq 'scoop' -and $hasScoop) -or ($systemPmCmd -eq 'auto' -and $hasScoop)) {
                        "scoop install bun"
                    }
                    elseif ($hasWinget) {
                        "winget install Oven-sh.Bun"
                    }
                    else {
                        "scoop install bun"
                    }
                }
                'Linux' { "curl -fsSL https://bun.sh/install | bash" }
                'macOS' {
                    if (($systemPmCmd -eq 'homebrew' -and $hasBrew) -or ($systemPmCmd -eq 'auto' -and $hasBrew)) {
                        "brew install bun"
                    }
                    else {
                        "curl -fsSL https://bun.sh/install | bash"
                    }
                }
                default { "scoop install bun" }
            }
            return "Install with: $runtimeInstall"
        }
        else {
            return "Install with: npm install -g $ToolName"
        }
    }
    
    # Handle Python runtime
    if ($ToolType -eq 'python-runtime') {
        # Check for Python runtime preference
        $pythonRuntime = if ($env:PS_PYTHON_RUNTIME) {
            $env:PS_PYTHON_RUNTIME.ToLower()
        }
        else {
            'auto'
        }
        
        # Try to detect Python executable
        if (Get-Command Get-PythonExecutable -ErrorAction SilentlyContinue) {
            try {
                $pythonExe = Get-PythonExecutable
                if ($pythonExe) {
                    # If it's a command name (not a path), use it directly
                    if ($pythonExe -notmatch '[\\/]') {
                        return "Install with: scoop install python (or ensure $pythonExe is in PATH)"
                    }
                }
            }
            catch {
                # Fall through
            }
        }
        
        # Fallback based on preference and platform
        $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
        
        $hasScoop = Get-Command scoop -ErrorAction SilentlyContinue
        $hasBrew = Get-Command brew -ErrorAction SilentlyContinue
        
        if ($pythonRuntime -ne 'auto' -and $pythonRuntime -in @('python', 'python3', 'py')) {
            $runtimeInstall = switch ($platform) {
                'Windows' {
                    if ($hasScoop) {
                        "scoop install python (or ensure $pythonRuntime is in PATH)"
                    }
                    else {
                        "Install Python from python.org (or ensure $pythonRuntime is in PATH)"
                    }
                }
                'Linux' { "sudo apt install python3 (or use your distribution's package manager)" }
                'macOS' {
                    if ($hasBrew) {
                        "brew install python3 (or ensure $pythonRuntime is in PATH)"
                    }
                    else {
                        "Install Python from python.org (or ensure $pythonRuntime is in PATH)"
                    }
                }
                default { "scoop install python (or ensure $pythonRuntime is in PATH)" }
            }
            return "Install with: $runtimeInstall"
        }
        
        $runtimeInstall = switch ($platform) {
            'Windows' {
                if ($hasScoop) {
                    "scoop install python"
                }
                else {
                    "Install Python from python.org"
                }
            }
            'Linux' { "sudo apt install python3 (or use your distribution's package manager)" }
            'macOS' {
                if ($hasBrew) {
                    "brew install python3"
                }
                else {
                    "Install Python from python.org"
                }
            }
            default { "scoop install python" }
        }
        return "Install with: $runtimeInstall"
    }
    
    # Handle Rust package managers
    if ($ToolType -eq 'rust-package') {
        $preference = if ($env:PS_RUST_PACKAGE_MANAGER) {
            $env:PS_RUST_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        # Check for cargo-binstall (faster binary installer)
        $hasBinstall = Get-Command cargo-binstall -ErrorAction SilentlyContinue
        $hasCargo = Get-Command cargo -ErrorAction SilentlyContinue
        
        if ($preference -eq 'cargo-binstall' -and $hasBinstall) {
            return "Install with: cargo-binstall $ToolName"
        }
        elseif ($preference -eq 'cargo' -and $hasCargo) {
            return "Install with: cargo install $ToolName"
        }
        elseif ($preference -eq 'auto') {
            if ($hasBinstall) {
                return "Install with: cargo-binstall $ToolName (or: cargo install $ToolName)"
            }
            elseif ($hasCargo) {
                return "Install with: cargo install $ToolName"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -eq 'cargo-binstall') {
            return "Install with: cargo install cargo-binstall"
        }
        elseif ($ToolName -eq 'cargo' -or $ToolName -eq 'rustup') {
            return "Install with: scoop install rustup"
        }
        else {
            return "Install with: cargo install $ToolName (or: scoop install rustup)"
        }
    }
    
    # Handle Go package managers
    if ($ToolType -eq 'go-package') {
        $preference = if ($env:PS_GO_PACKAGE_MANAGER) {
            $env:PS_GO_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        $hasGo = Get-Command go -ErrorAction SilentlyContinue
        
        if ($hasGo) {
            if ($preference -eq 'go-install') {
                return "Install with: go install $ToolName@latest"
            }
            elseif ($preference -eq 'go-get') {
                return "Install with: go get $ToolName"
            }
            else {
                # Auto: prefer go install (modern)
                return "Install with: go install $ToolName@latest"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -eq 'go') {
            return "Install with: scoop install go"
        }
        else {
            return "Install with: go install $ToolName@latest (or: scoop install go)"
        }
    }
    
    # Handle Java build tools
    if ($ToolType -eq 'java-build-tool') {
        $preference = if ($env:PS_JAVA_BUILD_TOOL) {
            $env:PS_JAVA_BUILD_TOOL.ToLower()
        }
        else {
            'auto'
        }
        
        # Check availability
        $hasMaven = Get-Command mvn -ErrorAction SilentlyContinue
        $hasGradle = Get-Command gradle -ErrorAction SilentlyContinue
        $hasSbt = Get-Command sbt -ErrorAction SilentlyContinue
        
        if ($preference -eq 'maven' -and $hasMaven) {
            return "Install with: mvn install (or: scoop install maven)"
        }
        elseif ($preference -eq 'gradle' -and $hasGradle) {
            return "Install with: gradle build (or: scoop install gradle)"
        }
        elseif ($preference -eq 'sbt' -and $hasSbt) {
            return "Install with: sbt compile (or: scoop install sbt)"
        }
        elseif ($preference -eq 'auto') {
            if ($hasMaven) {
                return "Install with: mvn install (or: scoop install maven)"
            }
            elseif ($hasGradle) {
                return "Install with: gradle build (or: scoop install gradle)"
            }
            elseif ($hasSbt) {
                return "Install with: sbt compile (or: scoop install sbt)"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -match '^mvn|maven') {
            return "Install with: scoop install maven"
        }
        elseif ($ToolName -eq 'gradle') {
            return "Install with: scoop install gradle"
        }
        elseif ($ToolName -eq 'sbt') {
            return "Install with: scoop install sbt"
        }
        else {
            return "Install with: scoop install $ToolName"
        }
    }
    
    # Handle Ruby package managers
    if ($ToolType -eq 'ruby-package') {
        $preference = if ($env:PS_RUBY_PACKAGE_MANAGER) {
            $env:PS_RUBY_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        # Use Test-CommandAvailable if available, otherwise fall back to Get-Command
        $testCmd = if (Get-Command Test-CommandAvailable -ErrorAction SilentlyContinue) {
            { param($name) Test-CommandAvailable -CommandName $name }
        }
        else {
            { param($name) [bool](Get-Command $name -ErrorAction SilentlyContinue) }
        }
        
        $hasGem = & $testCmd 'gem'
        $hasBundler = & $testCmd 'bundler'
        $hasScoop = & $testCmd 'scoop'
        
        if ($preference -eq 'bundler' -and $hasBundler) {
            return "Install with: bundle add $ToolName"
        }
        elseif ($preference -eq 'gem' -and $hasGem) {
            return "Install with: gem install $ToolName"
        }
        elseif ($preference -eq 'auto') {
            if ($hasBundler) {
                return "Install with: bundle add $ToolName (or: gem install $ToolName)"
            }
            elseif ($hasGem) {
                return "Install with: gem install $ToolName"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        # Check if gem/ruby needs to be installed first
        if ($ToolName -eq 'gem' -or $ToolName -eq 'ruby') {
            if ($hasScoop) {
                return "Install with: scoop install ruby"
            }
            else {
                return "Install with: scoop install ruby (or: https://www.ruby-lang.org/)"
            }
        }
        elseif ($ToolName -eq 'bundler') {
            if ($hasGem) {
                return "Install with: gem install bundler"
            }
            elseif ($hasScoop) {
                return "Install with: scoop install ruby (then: gem install bundler)"
            }
            else {
                return "Install with: gem install bundler (requires Ruby: scoop install ruby or https://www.ruby-lang.org/)"
            }
        }
        else {
            # For other ruby packages (like cocoapods)
            if ($hasGem) {
                return "Install with: gem install $ToolName"
            }
            elseif ($hasScoop) {
                return "Install with: scoop install ruby (then: gem install $ToolName)"
            }
            else {
                return "Install with: gem install $ToolName (requires Ruby: scoop install ruby or https://www.ruby-lang.org/)"
            }
        }
    }
    
    # Handle PHP package managers
    if ($ToolType -eq 'php-package') {
        $preference = if ($env:PS_PHP_PACKAGE_MANAGER) {
            $env:PS_PHP_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        $hasComposer = Get-Command composer -ErrorAction SilentlyContinue
        $hasPecl = Get-Command pecl -ErrorAction SilentlyContinue
        $hasPear = Get-Command pear -ErrorAction SilentlyContinue
        
        if ($preference -eq 'composer' -and $hasComposer) {
            return "Install with: composer require $ToolName"
        }
        elseif ($preference -eq 'pecl' -and $hasPecl) {
            return "Install with: pecl install $ToolName"
        }
        elseif ($preference -eq 'pear' -and $hasPear) {
            return "Install with: pear install $ToolName"
        }
        elseif ($preference -eq 'auto') {
            if ($hasComposer) {
                return "Install with: composer require $ToolName"
            }
            elseif ($hasPecl) {
                return "Install with: pecl install $ToolName"
            }
            elseif ($hasPear) {
                return "Install with: pear install $ToolName"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -eq 'composer') {
            return "Install with: scoop install composer"
        }
        elseif ($ToolName -eq 'php') {
            return "Install with: scoop install php"
        }
        else {
            return "Install with: composer require $ToolName (or: scoop install composer)"
        }
    }
    
    # Handle .NET package managers
    if ($ToolType -eq 'dotnet-package') {
        $preference = if ($env:PS_DOTNET_PACKAGE_MANAGER) {
            $env:PS_DOTNET_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        $hasDotnet = Get-Command dotnet -ErrorAction SilentlyContinue
        $hasNuget = Get-Command nuget -ErrorAction SilentlyContinue
        
        if ($preference -eq 'dotnet' -and $hasDotnet) {
            return "Install with: dotnet add package $ToolName"
        }
        elseif ($preference -eq 'nuget' -and $hasNuget) {
            return "Install with: nuget install $ToolName"
        }
        elseif ($preference -eq 'auto') {
            if ($hasDotnet) {
                return "Install with: dotnet add package $ToolName"
            }
            elseif ($hasNuget) {
                return "Install with: nuget install $ToolName"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -eq 'dotnet') {
            return "Install with: scoop install dotnet-sdk"
        }
        elseif ($ToolName -eq 'nuget') {
            return "Install with: dotnet tool install -g NuGet.CommandLine (or: scoop install nuget)"
        }
        else {
            return "Install with: dotnet add package $ToolName (or: scoop install dotnet-sdk)"
        }
    }
    
    # Handle Dart package managers
    if ($ToolType -eq 'dart-package') {
        $preference = if ($env:PS_DART_PACKAGE_MANAGER) {
            $env:PS_DART_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        $hasFlutter = Get-Command flutter -ErrorAction SilentlyContinue
        $hasDart = Get-Command dart -ErrorAction SilentlyContinue
        
        if ($preference -eq 'flutter' -and $hasFlutter) {
            return "Install with: flutter pub add $ToolName"
        }
        elseif ($preference -eq 'pub' -and $hasDart) {
            return "Install with: dart pub add $ToolName"
        }
        elseif ($preference -eq 'auto') {
            if ($hasFlutter) {
                return "Install with: flutter pub add $ToolName"
            }
            elseif ($hasDart) {
                return "Install with: dart pub add $ToolName"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -eq 'flutter') {
            return "Install with: scoop install flutter"
        }
        elseif ($ToolName -eq 'dart') {
            return "Install with: scoop install dart-sdk"
        }
        else {
            return "Install with: dart pub add $ToolName (or: scoop install dart-sdk)"
        }
    }
    
    # Handle Elixir package managers
    if ($ToolType -eq 'elixir-package') {
        $preference = if ($env:PS_ELIXIR_PACKAGE_MANAGER) {
            $env:PS_ELIXIR_PACKAGE_MANAGER.ToLower()
        }
        else {
            'auto'
        }
        
        $hasMix = Get-Command mix -ErrorAction SilentlyContinue
        $hasHex = Get-Command hex -ErrorAction SilentlyContinue
        
        if ($preference -eq 'mix' -and $hasMix) {
            return "Install with: mix deps.get (or: mix archive.install hex $ToolName)"
        }
        elseif ($preference -eq 'hex' -and $hasHex) {
            return "Install with: mix hex.install $ToolName"
        }
        elseif ($preference -eq 'auto') {
            if ($hasMix) {
                return "Install with: mix deps.get (or: mix archive.install hex $ToolName)"
            }
        }
        
        # Fallback
        if ($DefaultInstallCommand) {
            return "Install with: $DefaultInstallCommand"
        }
        
        if ($ToolName -eq 'mix' -or $ToolName -eq 'elixir') {
            return "Install with: scoop install elixir"
        }
        else {
            return "Install with: mix deps.get (or: scoop install elixir)"
        }
    }
    
    # Generic fallback - use platform-aware system package manager with fallback chain
    if ($DefaultInstallCommand) {
        return "Install with: $DefaultInstallCommand"
    }
    
    # Get system package manager preference
    $systemPmPreference = if ($env:PS_SYSTEM_PACKAGE_MANAGER) {
        $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower()
    }
    else {
        'auto'
    }
    
    # Use the fallback chain function
    $fallbackInfo = Get-SystemPackageManagerFallbackChain -ToolName $ToolName -PreferredManager $systemPmPreference
    
    if ($fallbackInfo.FallbackChain) {
        return "Install with: $($fallbackInfo.FallbackChain)"
    }
    
    # Fallback if function fails - use simple detection
    $platform = $fallbackInfo.Platform
    $hasScoop = Get-Command scoop -ErrorAction SilentlyContinue
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    $hasChoco = Get-Command choco -ErrorAction SilentlyContinue
    
    $installCmd = switch ($platform) {
        'Windows' {
            if ($hasScoop) {
                "scoop install $ToolName"
            }
            elseif ($hasWinget) {
                "winget install $ToolName"
            }
            elseif ($hasChoco) {
                "choco install $ToolName -y"
            }
            else {
                "scoop install $ToolName (or: winget install $ToolName, or: choco install $ToolName -y)"
            }
        }
        'Linux' {
            $hasApt = Get-Command apt -ErrorAction SilentlyContinue
            $hasDnf = Get-Command dnf -ErrorAction SilentlyContinue
            $hasYum = Get-Command yum -ErrorAction SilentlyContinue
            $hasPacman = Get-Command pacman -ErrorAction SilentlyContinue
            
            if ($hasApt) {
                "sudo apt install $ToolName"
            }
            elseif ($hasDnf) {
                "sudo dnf install $ToolName"
            }
            elseif ($hasYum) {
                "sudo yum install $ToolName"
            }
            elseif ($hasPacman) {
                "sudo pacman -S $ToolName"
            }
            elseif ($hasScoop) {
                "scoop install $ToolName"
            }
            else {
                "sudo apt install $ToolName (or: sudo dnf install $ToolName, or: sudo yum install $ToolName)"
            }
        }
        'macOS' {
            $hasBrew = Get-Command brew -ErrorAction SilentlyContinue
            if ($hasBrew) {
                "brew install $ToolName"
            }
            elseif ($hasScoop) {
                "scoop install $ToolName"
            }
            else {
                "brew install $ToolName (or: scoop install $ToolName)"
            }
        }
        default {
            "scoop install $ToolName"
        }
    }
    
    return "Install with: $installCmd"
}

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
            if ($prefLower -eq 'scoop' -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
                return $method
            }
            elseif ($prefLower -eq 'npm' -and (Get-Command npm -ErrorAction SilentlyContinue)) {
                return $method
            }
            elseif ($prefLower -eq 'pip' -and (Get-Command pip -ErrorAction SilentlyContinue)) {
                return $method
            }
            elseif ($prefLower -eq 'winget' -and (Get-Command winget -ErrorAction SilentlyContinue)) {
                return $method
            }
            elseif ($prefLower -eq 'homebrew' -and (Get-Command brew -ErrorAction SilentlyContinue)) {
                return $method
            }
            elseif ($prefLower -eq 'cargo' -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
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

    # Display table
    $tableData | Format-Table -AutoSize -Property Tool, InstallHint | Out-String | Write-Host

    # Clear collected warnings after display
    $global:CollectedMissingToolWarnings.Clear()
}

