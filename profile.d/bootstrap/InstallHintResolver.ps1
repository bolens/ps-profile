# ===============================================
# InstallHintResolver.ps1
# Preference-aware install hint resolution
# ===============================================
# Depends on: MissingToolWarnings.ps1 (platform utilities),
#             ToolInstallRegistry.ps1 (Get-ToolInstallMethodRegistry,
#             Get-ToolSpecificInstallMethod, Get-InstallMethodFallbackChain,
#             Test-CommandAvailable)
# ===============================================

<#
.SYNOPSIS
    Preference-aware install hint resolution for missing tool warnings.

.DESCRIPTION
    Provides Get-PreferenceAwareInstallHint, which generates install hint strings
    that respect user-configured package manager preferences via environment variables
    (PS_PYTHON_PACKAGE_MANAGER, PS_NODE_PACKAGE_MANAGER, PS_PYTHON_RUNTIME, etc.).
    Falls back to sensible platform defaults when preferences are not set.
    Depends on ToolInstallRegistry.ps1 for registry data and fallback chains.

.NOTES
    Load after ToolInstallRegistry.ps1.
#>

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
    # If found, generate a fallback chain from all available methods
    $toolSpecificMethod = Get-ToolSpecificInstallMethod -ToolName $ToolName
    if ($toolSpecificMethod) {
        # Get all available methods for this tool to build a fallback chain
        $registry = Get-ToolInstallMethodRegistry
        $toolLower = $ToolName.ToLower()
        
        if ($registry.ContainsKey($toolLower)) {
            $toolMethods = $registry[$toolLower]
            
            # Detect platform
            $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
                try { (Get-Platform).Name } catch { 'Windows' }
            }
            else {
                if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
                elseif ($IsLinux) { 'Linux' }
                elseif ($IsMacOS) { 'macOS' }
                else { 'Windows' }
            }
            
            if ($toolMethods.ContainsKey($Platform)) {
                $platformMethods = $toolMethods[$Platform]
                $availableMethods = @()
                
                # Collect all available methods for this platform
                foreach ($methodName in $platformMethods.Keys) {
                    $method = $platformMethods[$methodName]
                    if ($methodName -eq 'curl' -or $methodName -eq 'powershell' -or (Test-CommandAvailable -CommandName $methodName)) {
                        # For powershell, verify we're on Windows
                        if ($methodName -eq 'powershell' -and $Platform -ne 'Windows' -and -not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
                            continue
                        }
                        $availableMethods += $method
                    }
                }
                
                # Use preference to determine preferred method
                $systemPm = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower() } else { 'auto' }
                $preferredMethod = $toolSpecificMethod
                
                # If a preferred system package manager is set and available, prioritize it
                if ($systemPm -ne 'auto' -and $platformMethods.ContainsKey($systemPm)) {
                    $preferredMethodFromRegistry = $platformMethods[$systemPm]
                    if (Test-CommandAvailable -CommandName $systemPm) {
                        $preferredMethod = $preferredMethodFromRegistry
                    }
                }
                
                # Generate fallback chain with preferred method first
                $fallbackChain = Get-InstallMethodFallbackChain -PreferredMethod $preferredMethod -FallbackMethods $availableMethods -MaxFallbacks 3
                
                if ($fallbackChain) {
                    return "Install with: $fallbackChain"
                }
            }
        }
        
        # Fallback: just return the single method
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
        
        $hasScoop = Test-CachedCommand 'scoop'
        $hasBrew = Test-CachedCommand 'brew'
        
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
        
        $hasScoop = Test-CachedCommand 'scoop'
        $hasWinget = Test-CachedCommand 'winget'
        $hasBrew = Test-CachedCommand 'brew'
        
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
        
        $hasScoop = Test-CachedCommand 'scoop'
        $hasBrew = Test-CachedCommand 'brew'
        
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
        $hasBinstall = Test-CachedCommand 'cargo-binstall'
        $hasCargo = Test-CachedCommand 'cargo'
        
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
        
        $hasGo = Test-CachedCommand 'go'
        
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
        $hasMaven = Test-CachedCommand 'mvn'
        $hasGradle = Test-CachedCommand 'gradle'
        $hasSbt = Test-CachedCommand 'sbt'
        
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
        
        $hasComposer = Test-CachedCommand 'composer'
        $hasPecl = Test-CachedCommand 'pecl'
        $hasPear = Test-CachedCommand 'pear'
        
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
        
        $hasDotnet = Test-CachedCommand 'dotnet'
        $hasNuget = Test-CachedCommand 'nuget'
        
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
        
        $hasFlutter = Test-CachedCommand 'flutter'
        $hasDart = Test-CachedCommand 'dart'
        
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
        
        $hasMix = Test-CachedCommand 'mix'
        $hasHex = Test-CachedCommand 'hex'
        
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
    $hasScoop = Test-CachedCommand 'scoop'
    $hasWinget = Test-CachedCommand 'winget'
    $hasChoco = Test-CachedCommand 'choco'
    
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
            $hasApt = Test-CachedCommand 'apt'
            $hasDnf = Test-CachedCommand 'dnf'
            $hasYum = Test-CachedCommand 'yum'
            $hasPacman = Test-CachedCommand 'pacman'
            
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
            $hasBrew = Test-CachedCommand 'brew'
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
