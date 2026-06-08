# ===============================================
# MissingToolWarnings.ps1
# Core missing tool warning utilities
# (install hint resolution split to InstallHintResolver.ps1)
# (tool registry split to ToolInstallRegistry.ps1)
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
.EXAMPLE
    Test-ToolAvailableOnPlatform -Tool 'value'
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
.EXAMPLE
    Write-MissingToolWarning -Tool 'value'
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
.EXAMPLE
    Clear-MissingToolWarnings -Tool @()
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
