# ===============================================
# 00-bootstrap.ps1
# Bootstrap helpers for profile fragments
#
# Purpose: define small, collision-safe helpers used by other `profile.d` files
# so fragments can register functions/aliases without accidentally overwriting
# existing user or module commands.
#
# This file is intentionally loaded first (prefix `00-`) so other fragments
# can rely on these helpers. It's idempotent and will not overwrite existing
# helpers if already defined.
# ===============================================

# Initialize profile timing tracking
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileFragmentTimes) {
    $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
}

# Command usage tracking (only when debugging)
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileCommandUsage) {
    $global:PSProfileCommandUsage = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()
}

# Collision-safe function creator for profile fragments
if (-not (Test-Path "Function:\\global:Set-AgentModeFunction")) {
    <#
    .SYNOPSIS
        Creates collision-safe functions for profile fragments.
    .DESCRIPTION
        Defines a helper function that creates small convenience functions or wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register functions.
    .PARAMETER Name
        The name of the function to create.
    .PARAMETER Body
        The script block containing the function body.
    .PARAMETER ReturnScriptBlock
        If specified, returns the created script block instead of a boolean.
    #>
    function Set-AgentModeFunction {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory)] [string]$Name,
            [Parameter(Mandatory)] [scriptblock]$Body,
            [switch]$ReturnScriptBlock
        )
        # Don't overwrite existing commands
        if (Get-Command -Name $Name -ErrorAction SilentlyContinue) { return $false }

        $funcPath = 'Function:' + $Name
        # Determine debug verbosity: user can opt-in with PS_PROFILE_DEBUG=1
        $dbgEnabled = $false
        try { $dbgEnabled = ($env:PS_PROFILE_DEBUG -eq '1') -or (($env:GITHUB_ACTIONS -eq 'true') -and ($env:PS_PROFILE_DEBUG -ne '0')) } catch { $dbgEnabled = $false }
        if ($dbgEnabled) {
            if ($env:GITHUB_ACTIONS -eq 'true') { Write-Output "DEBUG: Set-AgentModeFunction: creating $Name" } else { Write-Verbose "Set-AgentModeFunction: creating $Name" }
        }
        # Build a ScriptBlock from the provided body. By default the helper
        # does not return the ScriptBlock to avoid emitting values during
        # profile dot-sourcing. Consumers may request the ScriptBlock by
        # specifying -ReturnScriptBlock.
        # Create the function in the global function provider directly, avoiding
        # text-based Invoke-Expression which can be slower and flagged by linters.
        $sb = [scriptblock]::Create($Body.ToString())
        try {
            # Use the Function: drive to create a persistent global function without
            # parsing text. This is more robust and avoids an extra Get-Command call.
            $funcPath = "Function:\global:$Name"
            if (Test-Path $funcPath) {
                if ($dbgEnabled) { Write-Verbose "Set-AgentModeFunction: function $Name already exists in $funcPath" }
                return $false
            }
            if ($PSCmdlet.ShouldProcess("Function '$Name'", "Create")) {
                New-Item -Path $funcPath -Value $sb -Force | Out-Null
                # Verify registration using provider path to avoid module autoload
                if (-not (Test-Path $funcPath)) { throw "Set-AgentModeFunction: unable to register function $Name" }
                if ($ReturnScriptBlock) { return $sb } else { return $true }
            }
        }
        catch {
            $err = $_.Exception.Message
            if ($dbgEnabled) { Write-Verbose "Set-AgentModeFunction: creation failed: $err" }
            throw
        }
    }
}

# Collision-safe alias creator for profile fragments
if (-not (Test-Path "Function:\\global:Set-AgentModeAlias")) {
    <#
    .SYNOPSIS
        Creates collision-safe aliases for profile fragments.
    .DESCRIPTION
        Defines a helper function that creates aliases or function wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register aliases.
    .PARAMETER Name
        The name of the alias to create.
    .PARAMETER Target
        The target command for the alias.
    .PARAMETER ReturnDefinition
        If specified, returns the alias definition instead of a boolean.
    #>
    function Set-AgentModeAlias {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory)] [string]$Name,
            [Parameter(Mandatory)] [string]$Target,
            [switch]$ReturnDefinition
        )
        if (Get-Command -Name $Name -ErrorAction SilentlyContinue) { return $false }
        try {
            # Determine debug verbosity
            $dbgEnabled = $false
            try { $dbgEnabled = ($env:PS_PROFILE_DEBUG -eq '1') -or (($env:GITHUB_ACTIONS -eq 'true') -and ($env:PS_PROFILE_DEBUG -ne '0')) } catch { $dbgEnabled = $false }
            if ($dbgEnabled) { Write-Verbose ("Set-AgentModeAlias: creating global wrapper {0} -> {1}" -f $Name, $Target) }
            # Prefer creating an alias or function using the provider API.
            try {
                if ($PSCmdlet.ShouldProcess("Alias '$Name'", "Create")) {
                    New-Alias -Name $Name -Value $Target -Scope Global -Force -ErrorAction Stop
                    if ($ReturnDefinition) { return "New-Alias -Name $Name -Value $Target -Scope Global" } else { return $true }
                }
            }
            catch {
                # Fall back to creating a small function via the Function: provider
                $funcPath = "Function:\global:$Name"
                $sb = [scriptblock]::Create("param([Parameter(ValueFromRemainingArguments=\$true)]\$args) & $Target @args")
                if ($PSCmdlet.ShouldProcess("Function '$Name'", "Create")) {
                    New-Item -Path $funcPath -Value $sb -Force | Out-Null
                    if ($ReturnDefinition) { return $funcPath } else { return $true }
                }
            }
        }
        catch {
            if ($dbgEnabled) { Write-Verbose ("Set-AgentModeAlias: failed creating {0}: {1}" -f $Name, $_.Exception.Message) }
            return $false
        }
    }
}

# Lightweight cached command-test used by multiple fragments to avoid repeated Get-Command calls
if (-not (Test-Path "Function:\\global:Test-CachedCommand")) {
    <#
    .SYNOPSIS
        Tests for command availability with caching and TTL.
    .DESCRIPTION
        Lightweight cached command testing used by profile fragments to avoid
        repeated Get-Command calls. Results are cached in script scope for performance.
        Cache entries expire after 5 minutes to handle cases where commands are
        installed after profile load.
    .PARAMETER Name
        The name of the command to test.
    .PARAMETER CacheTTLMinutes
        Optional. Cache time-to-live in minutes. Default is 5 minutes.
    .EXAMPLE
        if (Test-CachedCommand 'docker') { # configure docker helpers }
    #>
    function Test-CachedCommand {
        param(
            [Parameter(Mandatory)]
            [string]$Name,
            [int]$CacheTTLMinutes = 5
        )
        
        # Initialize cache dictionaries if needed
        if (-not $script:__cmdCache) { $script:__cmdCache = @{} }
        if (-not $script:__cmdCacheTTL) { $script:__cmdCacheTTL = @{} }
        
        # Check if cache entry exists and is still valid
        if ($script:__cmdCache.ContainsKey($Name)) {
            $cacheAge = if ($script:__cmdCacheTTL.ContainsKey($Name)) {
                (Get-Date) - $script:__cmdCacheTTL[$Name]
            }
            else {
                [TimeSpan]::MaxValue
            }
            
            # Return cached value if still valid
            if ($cacheAge.TotalMinutes -le $CacheTTLMinutes) {
                return $script:__cmdCache[$Name]
            }
        }
        
        # Cache miss or expired - check command and update cache
        $found = $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
        $script:__cmdCache[$Name] = $found
        $script:__cmdCacheTTL[$Name] = Get-Date
        
        return $found
    }
}

# Small utility exported for fragments: prefer provider checks first to avoid module autoload
if (-not (Test-Path "Function:\\global:Test-HasCommand")) {
    <#
    .SYNOPSIS
        Tests if a command is available.
    .DESCRIPTION
        Utility function to check if a command exists. Uses fast provider checks first
        to avoid module autoload, then falls back to cached or direct command testing.
    .PARAMETER Name
        The name of the command to test.
    #>
    $sb = {
        param([Parameter(Mandatory)] [string]$Name)
        # Fast provider checks avoid triggering module autoload/discovery
        if ((Test-Path "Function:\\global:$Name") -or (Test-Path "Function:\\$Name") -or (Test-Path "Alias:\\$Name")) { return $true }
        # If we have the cached helper, prefer it to avoid repeated Get-Command calls
        if (Test-Path "Function:\\global:Test-CachedCommand") {
            try { return [bool](Test-CachedCommand -Name $Name) } catch { Write-Verbose "Test-CachedCommand failed: $($_.Exception.Message)" }
        }
        # Last resort: Get-Command (may autoload modules)
        return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
    }
    # Create function in global scope explicitly
    Set-Item -Path "Function:\global:Test-HasCommand" -Value $sb -Force | Out-Null
}

# ===============================================
# CROSS-PLATFORM COMPATIBILITY HELPERS
# ===============================================
# Platform detection helpers for cross-platform compatibility
if (-not (Test-Path "Function:\\global:Test-IsWindows")) {
    <#
    .SYNOPSIS
        Tests if the current platform is Windows.
    .DESCRIPTION
        Returns $true if running on Windows, $false otherwise.
        Works with both PowerShell Core and Windows PowerShell.
    #>
    function Test-IsWindows {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            return $IsWindows
        }
        else {
            # Windows PowerShell always runs on Windows
            return $true
        }
    }
}

if (-not (Test-Path "Function:\\global:Test-IsLinux")) {
    <#
    .SYNOPSIS
        Tests if the current platform is Linux.
    .DESCRIPTION
        Returns $true if running on Linux, $false otherwise.
    #>
    function Test-IsLinux {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            return $IsLinux
        }
        else {
            return $false
        }
    }
}

if (-not (Test-Path "Function:\\global:Test-IsMacOS")) {
    <#
    .SYNOPSIS
        Tests if the current platform is macOS.
    .DESCRIPTION
        Returns $true if running on macOS, $false otherwise.
    #>
    function Test-IsMacOS {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            return $IsMacOS
        }
        else {
            return $false
        }
    }
}

if (-not (Test-Path "Function:\\global:Get-UserHome")) {
    <#
    .SYNOPSIS
        Gets the user's home directory path.
    .DESCRIPTION
        Returns the user's home directory path in a cross-platform compatible way.
        Uses $env:HOME on Unix systems and $env:USERPROFILE on Windows.
    .OUTPUTS
        System.String. The path to the user's home directory.
    .EXAMPLE
        $homeDir = Get-UserHome
        $configPath = Join-Path $homeDir '.config' 'myapp'
    .EXAMPLE
        # Use in cross-platform path construction
        $downloads = Join-Path (Get-UserHome) 'Downloads'
        if (Test-Path $downloads) {
            Set-Location $downloads
        }
    .NOTES
        This function provides a consistent way to get the user's home directory
        across Windows, Linux, and macOS. Prefer this over direct use of
        $env:USERPROFILE or $env:HOME for better cross-platform compatibility.
    #>
    function Get-UserHome {
        if ($env:HOME) {
            return $env:HOME
        }
        elseif ($env:USERPROFILE) {
            return $env:USERPROFILE
        }
        else {
            # Fallback for systems where neither is set
            return $HOME
        }
    }
}

# ===============================================
# LAZY FUNCTION REGISTRATION HELPER
# ===============================================
# Helper function to register lazy-loading functions that initialize on first use
if (-not (Test-Path "Function:\\global:Register-LazyFunction")) {
    <#
    .SYNOPSIS
        Registers a lazy-loading function that initializes on first use.
    .DESCRIPTION
        Creates a function stub that calls an initializer function on first invocation,
        then delegates to the actual function implementation. This pattern allows
        expensive initialization to be deferred until the function is actually used.
        The stub is replaced with the actual function after first initialization.
    .PARAMETER Name
        The name of the function to register.
    .PARAMETER Initializer
        A scriptblock that performs initialization (e.g., calls Ensure-* functions).
        This is executed once on first function call. The initializer should create
        the actual function with the same name.
    .PARAMETER Alias
        Optional alias name to create for the function.
    .EXAMPLE
        # Define the actual function in an Ensure-* helper
        function Ensure-GitHelper {
            if ($script:__GitHelpersInitialized) { return }
            Set-AgentModeFunction -Name 'Invoke-GitClone' -Body { git clone @args }
        }
        
        # Register lazy stub
        Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { Ensure-GitHelper } -Alias 'gcl'
        
        # First call initializes and invokes, subsequent calls use actual function
        Invoke-GitClone https://github.com/user/repo.git
    .EXAMPLE
        # Register multiple lazy functions with the same initializer
        Register-LazyFunction -Name 'Save-GitStash' -Initializer { Ensure-GitHelper } -Alias 'gsta'
        Register-LazyFunction -Name 'Restore-GitStash' -Initializer { Ensure-GitHelper } -Alias 'gstp'
    .NOTES
        This helper reduces code duplication when registering multiple lazy-loading
        functions. The initializer is only called once per function, even if multiple
        functions share the same initializer.
    #>
    function Register-LazyFunction {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Name,
            
            [Parameter(Mandatory)]
            [scriptblock]$Initializer,
            
            [string]$Alias
        )
        
        if (Test-Path "Function:$Name") {
            return
        }
        
        # Capture variables for closure
        $funcName = $Name
        $initScript = $Initializer
        
        # Create a lazy stub that initializes on first call
        $stub = [scriptblock]::Create(@"
param([Parameter(ValueFromRemainingArguments = `$true)] `$args)

# Call the initializer once
& { $($initScript.ToString()) }

# Get the actual function (should exist after initialization)
`$actualFunc = Get-Command '$funcName' -CommandType Function -ErrorAction SilentlyContinue
if (`$actualFunc) {
    # Replace this stub with a direct call to the actual function
    `$actualScriptBlock = `$actualFunc.ScriptBlock
    Set-Item -Path "Function:$funcName" -Value `$actualScriptBlock -Force | Out-Null
    
    # Invoke the actual function
    & `$actualScriptBlock.InvokeReturnAsIs(`$args)
}
else {
    Write-Warning "Function $funcName was not initialized by the initializer scriptblock."
}
"@)
        
        Set-Item -Path "Function:$Name" -Value $stub -Force | Out-Null
        
        if ($Alias) {
            Set-Alias -Name $Alias -Value $Name -ErrorAction SilentlyContinue
        }
    }
}

# ===============================================
# DEPRECATION MANAGEMENT HELPER
# ===============================================
# Helper function to register deprecated functions/aliases with warnings
if (-not (Test-Path "Function:\\global:Register-DeprecatedFunction")) {
    <#
    .SYNOPSIS
        Registers a deprecated function or alias with a deprecation warning.
    .DESCRIPTION
        Creates a wrapper function that displays a deprecation warning when called,
        then forwards the call to the new function. Useful for maintaining backward
        compatibility while encouraging migration to new APIs.
    .PARAMETER OldName
        The name of the deprecated function or alias.
    .PARAMETER NewName
        The name of the replacement function or alias.
    .PARAMETER RemovalVersion
        Optional. The version when the deprecated function will be removed.
    .PARAMETER Message
        Optional. Custom deprecation message. If not provided, a default message is used.
    .EXAMPLE
        Register-DeprecatedFunction -OldName 'Old-Function' -NewName 'New-Function' -RemovalVersion '2.0.0'
    .EXAMPLE
        Register-DeprecatedFunction -OldName 'old-alias' -NewName 'new-alias' -Message 'This alias is deprecated'
    #>
    function Register-DeprecatedFunction {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$OldName,
            
            [Parameter(Mandatory)]
            [string]$NewName,
            
            [string]$RemovalVersion,
            
            [string]$Message
        )
        
        # Don't overwrite if already exists (may have been manually defined)
        if (Test-Path "Function:$OldName") {
            Write-Verbose "Function $OldName already exists, skipping deprecation wrapper"
            return
        }
        
        # Generate deprecation message
        if (-not $Message) {
            $Message = "$OldName is deprecated. Use $NewName instead."
            if ($RemovalVersion) {
                $Message += " Will be removed in version $RemovalVersion."
            }
        }
        
        # Create wrapper function
        $wrapper = {
            param([Parameter(ValueFromRemainingArguments = $true)] $args)
            
            Write-Warning $using:Message
            & $using:NewName @args
        }
        
        Set-Item -Path "Function:$OldName" -Value $wrapper -Force | Out-Null
        
        # Also create alias if the new name is a function
        if (Test-Path "Function:$NewName") {
            Set-Alias -Name $OldName -Value $NewName -ErrorAction SilentlyContinue
        }
    }
}

# ===============================================
# FRAGMENT MANAGEMENT HELPERS
# ===============================================
# Helper function to get the fragment config file path
if (-not (Test-Path "Function:\\global:Get-FragmentConfigPath")) {
    function Get-FragmentConfigPath {
        $profileDir = Split-Path -Parent $PROFILE
        return Join-Path $profileDir '.profile-fragments.json'
    }
}

# Helper function to load fragment configuration
if (-not (Test-Path "Function:\\global:Get-FragmentConfig")) {
    <#
    .SYNOPSIS
        Gets the fragment configuration.
    .DESCRIPTION
        Loads and returns the fragment configuration from .profile-fragments.json.
        Supports enhanced configuration options including load order override,
        environment-specific sets, feature flags, and performance tuning.
    #>
    function Get-FragmentConfig {
        $configPath = Get-FragmentConfigPath
        if (-not (Test-Path $configPath)) {
            return @{
                disabled     = @()
                loadOrder    = @()
                environments = @{}
                featureFlags = @{}
                performance  = @{
                    batchLoad       = $false
                    maxFragmentTime = 500
                }
            }
        }
        try {
            $content = Get-Content -Path $configPath -Raw -ErrorAction Stop
            $configObj = $content | ConvertFrom-Json
            # Convert to hashtable for easier manipulation
            $config = @{
                disabled     = @()
                loadOrder    = @()
                environments = @{}
                featureFlags = @{}
                performance  = @{
                    batchLoad       = $false
                    maxFragmentTime = 500
                }
            }
            
            if ($configObj.disabled) {
                $config.disabled = @($configObj.disabled)
            }
            if ($configObj.loadOrder) {
                $config.loadOrder = @($configObj.loadOrder)
            }
            if ($configObj.environments) {
                $config.environments = ConvertTo-Hashtable -InputObject $configObj.environments
            }
            if ($configObj.featureFlags) {
                $config.featureFlags = ConvertTo-Hashtable -InputObject $configObj.featureFlags
            }
            if ($configObj.performance) {
                $config.performance = ConvertTo-Hashtable -InputObject $configObj.performance
                if (-not $config.performance.ContainsKey('batchLoad')) {
                    $config.performance.batchLoad = $false
                }
                if (-not $config.performance.ContainsKey('maxFragmentTime')) {
                    $config.performance.maxFragmentTime = 500
                }
            }
            
            return $config
        }
        catch {
            Write-Warning "Failed to load fragment config: $($_.Exception.Message). Using defaults."
            return @{
                disabled     = @()
                loadOrder    = @()
                environments = @{}
                featureFlags = @{}
                performance  = @{
                    batchLoad       = $false
                    maxFragmentTime = 500
                }
            }
        }
    }
}

# Helper to convert PSCustomObject to Hashtable recursively
if (-not (Test-Path "Function:\\global:ConvertTo-Hashtable")) {
    function ConvertTo-Hashtable {
        param([Parameter(ValueFromPipeline)]$InputObject)
        
        if ($null -eq $InputObject) {
            return @{}
        }
        
        if ($InputObject -is [hashtable]) {
            return $InputObject
        }
        
        if ($InputObject -is [PSCustomObject]) {
            $hash = @{}
            $InputObject.PSObject.Properties | ForEach-Object {
                if ($_.Value -is [PSCustomObject]) {
                    $hash[$_.Name] = ConvertTo-Hashtable -InputObject $_.Value
                }
                elseif ($_.Value -is [System.Array]) {
                    $hash[$_.Name] = $_.Value | ForEach-Object {
                        if ($_ -is [PSCustomObject]) {
                            ConvertTo-Hashtable -InputObject $_
                        }
                        else {
                            $_
                        }
                    }
                }
                else {
                    $hash[$_.Name] = $_.Value
                }
            }
            return $hash
        }
        
        return @{}
    }
}

# Helper function to save fragment configuration
if (-not (Test-Path "Function:\\global:Save-FragmentConfig")) {
    function Save-FragmentConfig {
        param([Parameter(Mandatory)] [hashtable]$Config)
        $configPath = Get-FragmentConfigPath
        try {
            $json = $Config | ConvertTo-Json -Depth 10 -Compress
            Set-Content -Path $configPath -Value $json -ErrorAction Stop
            return $true
        }
        catch {
            Write-Error "Failed to save fragment config: $($_.Exception.Message)"
            return $false
        }
    }
}

# Helper function to check if a fragment is enabled
if (-not (Test-Path "Function:\\global:Test-ProfileFragmentEnabled")) {
    <#
    .SYNOPSIS
        Tests if a profile fragment is enabled.
    .DESCRIPTION
        Checks the fragment configuration to determine if a fragment is enabled.
        Fragments are enabled by default unless explicitly disabled.
    .PARAMETER FragmentName
        The name of the fragment to check (e.g., '11-git.ps1' or '11-git').
    #>
    function Test-ProfileFragmentEnabled {
        param([Parameter(Mandatory)] [string]$FragmentName)
        
        # Normalize fragment name (remove .ps1 extension if present)
        if ($FragmentName -like '*.ps1') {
            $FragmentName = $FragmentName -replace '\.ps1$', ''
        }
        
        $config = Get-FragmentConfig
        return $FragmentName -notin $config.disabled
    }
}

# Enable a profile fragment
if (-not (Test-Path "Function:\\global:Enable-ProfileFragment")) {
    <#
    .SYNOPSIS
        Enables a profile fragment.
    .DESCRIPTION
        Removes a fragment from the disabled list, allowing it to be loaded on next profile reload.
    .PARAMETER FragmentName
        The name of the fragment to enable (e.g., '11-git.ps1' or '11-git').
    .EXAMPLE
        Enable-ProfileFragment -FragmentName '11-git'
    #>
    function Enable-ProfileFragment {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory, ValueFromPipeline)] [string]$FragmentName
        )
        
        # Normalize fragment name
        if ($FragmentName -like '*.ps1') {
            $FragmentName = $FragmentName -replace '\.ps1$', ''
        }
        
        $config = Get-FragmentConfig
        if ($FragmentName -in $config.disabled) {
            if ($PSCmdlet.ShouldProcess("Fragment '$FragmentName'", "Enable")) {
                $config.disabled = $config.disabled | Where-Object { $_ -ne $FragmentName }
                if (Save-FragmentConfig -Config $config) {
                    Write-Host "Fragment '$FragmentName' enabled. Reload your profile with '. `$PROFILE' to apply changes." -ForegroundColor Green
                    return $true
                }
            }
        }
        else {
            Write-Host "Fragment '$FragmentName' is already enabled." -ForegroundColor Yellow
            return $false
        }
    }
}

# Disable a profile fragment
if (-not (Test-Path "Function:\\global:Disable-ProfileFragment")) {
    <#
    .SYNOPSIS
        Disables a profile fragment.
    .DESCRIPTION
        Adds a fragment to the disabled list, preventing it from being loaded on next profile reload.
    .PARAMETER FragmentName
        The name of the fragment to disable (e.g., '11-git.ps1' or '11-git').
    .EXAMPLE
        Disable-ProfileFragment -FragmentName '11-git'
    #>
    function Disable-ProfileFragment {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory, ValueFromPipeline)] [string]$FragmentName
        )
        
        # Normalize fragment name
        if ($FragmentName -like '*.ps1') {
            $FragmentName = $FragmentName -replace '\.ps1$', ''
        }
        
        $config = Get-FragmentConfig
        if ($FragmentName -notin $config.disabled) {
            if ($PSCmdlet.ShouldProcess("Fragment '$FragmentName'", "Disable")) {
                $existingDisabled = if ($config.disabled) { @($config.disabled) } else { @() }
                $config.disabled = $existingDisabled + $FragmentName
                if (Save-FragmentConfig -Config $config) {
                    Write-Host "Fragment '$FragmentName' disabled. Reload your profile with '. `$PROFILE' to apply changes." -ForegroundColor Yellow
                    return $true
                }
            }
        }
        else {
            Write-Host "Fragment '$FragmentName' is already disabled." -ForegroundColor Yellow
            return $false
        }
    }
}

# Get profile fragment status
if (-not (Test-Path "Function:\\global:Get-ProfileFragment")) {
    <#
    .SYNOPSIS
        Gets the status of profile fragments.
    .DESCRIPTION
        Lists all profile fragments and their enabled/disabled status.
    .PARAMETER FragmentName
        Optional. Filter by specific fragment name.
    .PARAMETER DisabledOnly
        Show only disabled fragments.
    .PARAMETER EnabledOnly
        Show only enabled fragments.
    .EXAMPLE
        Get-ProfileFragment
    .EXAMPLE
        Get-ProfileFragment -DisabledOnly
    #>
    function Get-ProfileFragment {
        [CmdletBinding()]
        param(
            [string]$FragmentName,
            [switch]$DisabledOnly,
            [switch]$EnabledOnly
        )
        
        $profileDir = Split-Path -Parent $PROFILE
        $profileD = Join-Path $profileDir 'profile.d'
        
        if (-not (Test-Path $profileD)) {
            Write-Warning "Profile.d directory not found: $profileD"
            return
        }
        
        $config = Get-FragmentConfig
        $fragments = Get-ChildItem -Path $profileD -File -Filter '*.ps1' | Sort-Object Name
        
        $results = foreach ($fragment in $fragments) {
            $name = $fragment.BaseName
            $isEnabled = Test-ProfileFragmentEnabled -FragmentName $name
            
            if ($FragmentName -and $name -notlike "*$FragmentName*") {
                continue
            }
            if ($DisabledOnly -and $isEnabled) {
                continue
            }
            if ($EnabledOnly -and -not $isEnabled) {
                continue
            }
            
            [PSCustomObject]@{
                Name     = $name
                FileName = $fragment.Name
                Enabled  = $isEnabled
                Path     = $fragment.FullName
            }
        }
        
        return $results
    }
}

# ===============================================
# Fragment Dependency Management
# ===============================================

# Parse fragment dependencies from comment header
if (-not (Test-Path "Function:\\global:Get-FragmentDependencies")) {
    <#
    .SYNOPSIS
        Gets dependencies declared in a fragment file.
    .DESCRIPTION
        Parses fragment file header comments to extract declared dependencies.
        Supports both #Requires -Fragment and # Dependencies: comment formats.
    .PARAMETER FragmentPath
        Path to the fragment file to analyze.
    .EXAMPLE
        Get-FragmentDependencies -FragmentPath 'profile.d/11-git.ps1'
    #>
    function Get-FragmentDependencies {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$FragmentPath
        )
        
        if (-not (Test-Path $FragmentPath)) {
            return @()
        }
        
        $dependencies = @()
        $content = Get-Content -Path $FragmentPath -Raw
        
        # Look for #Requires -Fragment 'name' pattern
        $requiresMatches = [regex]::Matches($content, '#Requires\s+-Fragment\s+[''""]([^''""]+)[''""]')
        foreach ($match in $requiresMatches) {
            $dependencies += $match.Groups[1].Value
        }
        
        # Look for # Dependencies: pattern (comma-separated)
        if ($content -match '#\s*Dependencies:\s*(.+)') {
            $depLine = $matches[1].Trim()
            $depLine -split ',' | ForEach-Object {
                $dep = $_.Trim() -replace '[''""]', ''
                if ($dep) {
                    $dependencies += $dep
                }
            }
        }
        
        return $dependencies | Select-Object -Unique
    }
}

# Validate fragment dependencies
if (-not (Test-Path "Function:\\global:Test-FragmentDependencies")) {
    <#
    .SYNOPSIS
        Validates that fragment dependencies are satisfied.
    .DESCRIPTION
        Checks if all declared dependencies for a fragment exist and are enabled.
    .PARAMETER FragmentPath
        Path to the fragment file to validate.
    .PARAMETER AvailableFragments
        Hashtable of available fragments (name -> file info).
    .PARAMETER DisabledFragments
        Array of disabled fragment names.
    .EXAMPLE
        Test-FragmentDependencies -FragmentPath 'profile.d/11-git.ps1' -AvailableFragments $fragments
    #>
    function Test-FragmentDependencies {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$FragmentPath,
            
            [Parameter(Mandatory)]
            [hashtable]$AvailableFragments,
            
            [string[]]$DisabledFragments = @()
        )
        
        $dependencies = Get-FragmentDependencies -FragmentPath $FragmentPath
        $missing = @()
        $disabled = @()
        
        foreach ($dep in $dependencies) {
            # Normalize dependency name (remove .ps1 if present)
            $depName = $dep -replace '\.ps1$', ''
            
            if (-not $AvailableFragments.ContainsKey($depName)) {
                $missing += $dep
            }
            elseif ($depName -in $DisabledFragments) {
                $disabled += $dep
            }
        }
        
        return [PSCustomObject]@{
            Valid        = ($missing.Count -eq 0 -and $disabled.Count -eq 0)
            Missing      = $missing
            Disabled     = $disabled
            Dependencies = $dependencies
        }
    }
}

# Get fragment load order considering dependencies
if (-not (Test-Path "Function:\\global:Get-FragmentLoadOrder")) {
    <#
    .SYNOPSIS
        Calculates optimal fragment load order based on dependencies.
    .DESCRIPTION
        Analyzes fragments and their dependencies to determine the correct load order.
        Returns fragments sorted topologically to satisfy all dependencies.
    .PARAMETER FragmentFiles
        Array of fragment file info objects to analyze.
    .PARAMETER DisabledFragments
        Array of disabled fragment names.
    .EXAMPLE
        $fragments = Get-ChildItem profile.d/*.ps1
        $order = Get-FragmentLoadOrder -FragmentFiles $fragments
    #>
    function Get-FragmentLoadOrder {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [System.IO.FileInfo[]]$FragmentFiles,
            
            [string[]]$DisabledFragments = @()
        )
        
        # Build dependency graph
        $fragmentMap = @{}
        $dependencies = @{}
        
        foreach ($file in $FragmentFiles) {
            $name = $file.BaseName
            if ($name -in $DisabledFragments -and $name -ne '00-bootstrap') {
                continue
            }
            
            $fragmentMap[$name] = $file
            $deps = Get-FragmentDependencies -FragmentPath $file.FullName
            $dependencies[$name] = $deps | ForEach-Object { $_ -replace '\.ps1$', '' }
        }
        
        # Topological sort
        $sorted = @()
        $visited = @{}
        $visiting = @{}
        
        function Visit-Fragment {
            param([string]$FragmentName)
            
            if ($visiting[$FragmentName]) {
                Write-Warning "Circular dependency detected involving fragment: $FragmentName"
                return
            }
            
            if ($visited[$FragmentName]) {
                return
            }
            
            $visiting[$FragmentName] = $true
            
            # Visit dependencies first
            if ($dependencies.ContainsKey($FragmentName)) {
                foreach ($dep in $dependencies[$FragmentName]) {
                    if ($fragmentMap.ContainsKey($dep)) {
                        Visit-Fragment -FragmentName $dep
                    }
                }
            }
            
            $visiting[$FragmentName] = $false
            $visited[$FragmentName] = $true
            
            if ($fragmentMap.ContainsKey($FragmentName)) {
                $sorted += $fragmentMap[$FragmentName]
            }
        }
        
        # Visit all fragments
        foreach ($name in $fragmentMap.Keys | Sort-Object) {
            if (-not $visited[$name]) {
                Visit-Fragment -FragmentName $name
            }
        }
        
        return $sorted
    }
}
