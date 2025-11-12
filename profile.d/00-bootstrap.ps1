# ===============================================
# 00-bootstrap.ps1
# Core bootstrap helpers for profile fragments
# ===============================================

if (Get-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -ErrorAction SilentlyContinue) {
    if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    if (-not (Get-Variable -Name 'AgentModeReplaceAllowed' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:AgentModeReplaceAllowed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    if (-not (Get-Variable -Name 'MissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:MissingToolWarnings = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    $reinitCommand = Get-Command -Name 'Initialize-FragmentWarningSuppression' -ErrorAction SilentlyContinue
    if ($reinitCommand) {
        Initialize-FragmentWarningSuppression
    }
    # Continue to define functions even if already initialized
}

Set-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -Value $true -Force

$script:BootstrapRoot = Split-Path -Parent $PSCommandPath
$script:RepoRoot = Split-Path -Parent $script:BootstrapRoot

$script:CommonModulePath = Join-Path $script:RepoRoot 'scripts\lib\Common.psm1'
if (Test-Path -LiteralPath $script:CommonModulePath) {
    if (-not (Get-Module -Name 'Common')) {
        try {
            Import-Module -Name $script:CommonModulePath -DisableNameChecking -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to import Common.psm1: $($_.Exception.Message)"
        }
    }
}
else {
    Write-Warning "Common module not found at $script:CommonModulePath"
}

if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'AgentModeReplaceAllowed' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:AgentModeReplaceAllowed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'MissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:MissingToolWarnings = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'FragmentWarningPatternSet' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:FragmentWarningPatternSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'SuppressAllFragmentWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:SuppressAllFragmentWarnings = $false
}

<#
.SYNOPSIS
    Tests if a command is available without triggering module autoload.
.DESCRIPTION
    Checks the function and alias providers before falling back to Get-Command.
    Returns $true when the specified command is available, otherwise $false.
.PARAMETER Name
    The name of the command to check for availability.
.OUTPUTS
    System.Boolean
#>
function global:Test-HasCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    $normalizedName = $Name.Trim()

    if ($global:AssumedAvailableCommands -and $global:AssumedAvailableCommands.ContainsKey($normalizedName)) {
        return $true
    }

    # Look through both local and global scopes without triggering module autoload.
    $functionPaths = @(
        "Function:\$normalizedName",
        "Function:\global:$normalizedName"
    )

    foreach ($path in $functionPaths) {
        try {
            if ($path -and (Test-Path -LiteralPath $path)) {
                return $true
            }
        }
        catch {
        }
    }

    $aliasPaths = @(
        "Alias:\$normalizedName",
        "Alias:\global:$normalizedName"
    )

    foreach ($path in $aliasPaths) {
        try {
            if ($path -and (Test-Path -LiteralPath $path)) {
                return $true
            }
        }
        catch {
        }
    }

    $command = Get-Command -Name $normalizedName -ErrorAction SilentlyContinue
    return $null -ne $command
}

<#
.SYNOPSIS
    Tests command availability with a short-lived in-memory cache.
.DESCRIPTION
    Wraps Test-HasCommand with a TTL-based cache to avoid repeated lookups.
    Cache entries expire after the specified number of minutes.
.PARAMETER Name
    The name of the command to check.
.PARAMETER CacheTTLMinutes
    Cache duration in minutes. Defaults to 5 minutes.
.OUTPUTS
    System.Boolean
#>
function global:Test-CachedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [ValidateRange(1, 1440)]
        [int]$CacheTTLMinutes = 5
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    $normalizedName = $Name.Trim()

    if ($global:AssumedAvailableCommands -and $global:AssumedAvailableCommands.ContainsKey($normalizedName)) {
        return $true
    }

    $cacheKey = $normalizedName.ToLowerInvariant()
    $now = Get-Date

    if ($global:TestCachedCommandCache.ContainsKey($cacheKey)) {
        $entry = [pscustomobject]$global:TestCachedCommandCache[$cacheKey]
        if ($entry -and $entry.Expires -gt $now) {
            return [bool]$entry.Result
        }
    }

    $result = Test-HasCommand -Name $normalizedName
    $expires = $now.AddMinutes([double]$CacheTTLMinutes)
    $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
        Result  = $result
        Expires = $expires
    }
    return $result
}

<#
.SYNOPSIS
    Clears the cached results used by Test-CachedCommand.
.DESCRIPTION
    Empties the in-memory cache so that subsequent Test-CachedCommand invocations
    recalculate command availability.
.OUTPUTS
    System.Boolean
#>
function global:Clear-TestCachedCommandCache {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not $global:TestCachedCommandCache) {
        return $false
    }

    $global:TestCachedCommandCache.Clear()
    return $true
}

<#
.SYNOPSIS
    Removes a single entry from the Test-CachedCommand cache.
.DESCRIPTION
    Deletes the cached availability result for the specified command name,
    forcing the next lookup to probe providers again.
.PARAMETER Name
    The command name whose cached result should be removed.
.OUTPUTS
    System.Boolean
#>
function global:Remove-TestCachedCommandCacheEntry {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not $global:TestCachedCommandCache -or [string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    $cacheKey = $Name.ToLowerInvariant()
    $removedEntry = $null
    return $global:TestCachedCommandCache.TryRemove($cacheKey, [ref]$removedEntry)
}

<#
.SYNOPSIS
    Adds command names that should always be treated as available.
.DESCRIPTION
    Registers command names, typically optional tools, that the profile should
    treat as present even when they are not discoverable on the current PATH.
.PARAMETER Name
    One or more command names to mark as assumed available.
.OUTPUTS
    System.Boolean
#>
function global:Add-AssumedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    if (-not $global:AssumedAvailableCommands) {
        return $false
    }

    $added = $false

    foreach ($entry in $Name) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $normalized = $entry.Trim()
        if ($global:AssumedAvailableCommands.TryAdd($normalized, $true) -or $global:AssumedAvailableCommands.ContainsKey($normalized)) {
            $added = $true
        }
    }

    return $added
}

<#
.SYNOPSIS
    Removes command names from the assumed available command list.
.DESCRIPTION
    Clears previously added assumed commands so future detection reverts to
    standard provider checks.
.PARAMETER Name
    One or more command names to remove from the assumed command list.
.OUTPUTS
    System.Boolean
#>
function global:Remove-AssumedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    if (-not $global:AssumedAvailableCommands) {
        return $false
    }

    $removed = $false

    foreach ($entry in $Name) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $normalized = $entry.Trim()
        $removedEntry = $null
        if ($global:AssumedAvailableCommands.TryRemove($normalized, [ref]$removedEntry)) {
            $removed = $true
        }
    }

    return $removed
}

<#
.SYNOPSIS
    Retrieves the list of assumed available commands.
.OUTPUTS
    System.String[]
#>
function global:Get-AssumedCommands {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    if (-not $global:AssumedAvailableCommands) {
        return @()
    }

    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in $global:AssumedAvailableCommands.Keys) {
        $result.Add($key)
    }
    $array = $result.ToArray()
    return , $array
}

<#
.SYNOPSIS
    Writes a tool detection warning only once per session.
.DESCRIPTION
    Emits a warning about a missing optional tool unless warnings are globally
    suppressed or the message has already been shown in the current session.
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

    if ($env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS -eq '1') {
        return
    }

    if (-not $global:MissingToolWarnings) {
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

    Write-Warning $warningText
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

function Initialize-FragmentWarningSuppression {
    if (-not (Get-Variable -Name 'FragmentWarningPatternSet' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:FragmentWarningPatternSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    else {
        $global:FragmentWarningPatternSet.Clear()
    }

    $global:SuppressAllFragmentWarnings = $false

    $rawValue = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS
    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return
    }

    $tokens = $rawValue -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($token in $tokens) {
        $normalized = $token.Trim()
        if ([string]::IsNullOrWhiteSpace($normalized)) {
            continue
        }

        switch -Regex ($normalized.ToLowerInvariant()) {
            '^(1|true|all|\*)$' {
                $global:SuppressAllFragmentWarnings = $true
                continue
            }
            default {
                [void]$global:FragmentWarningPatternSet.Add($normalized)
            }
        }
    }
}

function global:Test-FragmentWarningSuppressed {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$FragmentName
    )

    if ($global:SuppressAllFragmentWarnings) {
        return $true
    }

    if (-not $global:FragmentWarningPatternSet -or $global:FragmentWarningPatternSet.Count -eq 0) {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return $false
    }

    $candidateFull = $FragmentName.Trim()
    $candidateName = [System.IO.Path]::GetFileName($candidateFull)
    $candidateBase = [System.IO.Path]::GetFileNameWithoutExtension($candidateFull)

    foreach ($pattern in $global:FragmentWarningPatternSet) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        $normalizedPattern = $pattern.Trim()
        $patternName = [System.IO.Path]::GetFileName($normalizedPattern)
        $patternBase = [System.IO.Path]::GetFileNameWithoutExtension($normalizedPattern)

        $candidates = @($candidateFull, $candidateName, $candidateBase)
        $patterns = @($normalizedPattern, $patternName, $patternBase)

        foreach ($candidate in $candidates) {
            foreach ($patternVariant in $patterns) {
                if ([string]::IsNullOrWhiteSpace($candidate) -or [string]::IsNullOrWhiteSpace($patternVariant)) {
                    continue
                }

                if ($candidate -like $patternVariant) {
                    return $true
                }
            }
        }
    }

    return $false
}

if ($env:PS_PROFILE_ASSUME_COMMANDS) {
    $tokens = $env:PS_PROFILE_ASSUME_COMMANDS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($tokens) {
        Add-AssumedCommand -Name $tokens | Out-Null
    }
}

Initialize-FragmentWarningSuppression

<#
.SYNOPSIS
    Resolves the current user's home directory.
.DESCRIPTION
    Returns a cross-platform home directory path by checking $env:HOME,
    $env:USERPROFILE, and finally the .NET UserProfile folder.
.OUTPUTS
    System.String
#>
function global:Get-UserHome {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $resolvedHome = $null

    if ($env:HOME) {
        $resolvedHome = $env:HOME
    }

    if (-not $resolvedHome -and $env:USERPROFILE) {
        $resolvedHome = $env:USERPROFILE
    }

    if (-not $resolvedHome) {
        try {
            $resolvedHome = [System.Environment]::GetFolderPath('UserProfile')
        }
        catch {
            $resolvedHome = $null
        }
    }

    return $resolvedHome
}

<#
.SYNOPSIS
    Registers a collision-safe function in the global scope.
.DESCRIPTION
    Creates a function unless one already exists. When ReturnScriptBlock is
    specified, the created script block is returned for reuse.
.PARAMETER Name
    Name of the function to create.
.PARAMETER Body
    Script block executed when the function runs.
.PARAMETER ReturnScriptBlock
    Returns the created script block instead of $true/$false.
.OUTPUTS
    System.Boolean or System.Management.Automation.ScriptBlock
#>
function global:Set-AgentModeFunction {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Body,

        [switch]$ReturnScriptBlock
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or -not $Body) {
        return $false
    }

    $existing = Get-Command -Name $Name -ErrorAction SilentlyContinue
    $allowReplace = $global:AgentModeReplaceAllowed.Contains($Name)

    if ($existing -and -not $allowReplace) {
        return $false
    }

    $scriptBlock = $Body.GetNewClosure()
    Set-Item -Path ("Function:\global:" + $Name) -Value $scriptBlock -Force | Out-Null

    if ($allowReplace) {
        [void]$global:AgentModeReplaceAllowed.Remove($Name)
    }

    if ($ReturnScriptBlock) {
        return $scriptBlock
    }

    return $true
}

<#
.SYNOPSIS
    Registers a collision-safe alias in the global scope.
.DESCRIPTION
    Creates an alias only when it does not already exist. Optionally returns
    the alias definition string for diagnostic scenarios.
.PARAMETER Name
    Alias name to register.
.PARAMETER Target
    Target command or function the alias should invoke.
.PARAMETER ReturnDefinition
    Returns the alias definition instead of $true/$false.
.OUTPUTS
    System.Boolean or System.String
#>
function global:Set-AgentModeAlias {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Target,

        [switch]$ReturnDefinition
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Target)) {
        return $false
    }

    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return $false
    }

    Set-Alias -Name $Name -Value $Target -Scope Global -Force

    if ($ReturnDefinition) {
        $alias = Get-Alias -Name $Name -ErrorAction SilentlyContinue
        if ($alias) {
            return "$($alias.Name) -> $($alias.Definition)"
        }
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Registers a lazy-loading function stub.
.DESCRIPTION
    Creates a stub that runs the provided initializer on first use, allowing
    expensive setup work to be deferred. Optionally creates an alias that
    points to the stubbed function.
.PARAMETER Name
    Function name to register.
.PARAMETER Initializer
    Script block that performs initialization and defines the real function.
.PARAMETER Alias
    Optional alias name for the lazy-loaded function.
.OUTPUTS
    System.Boolean
#>
function global:Register-LazyFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Initializer,

        [string]$Alias
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or -not $Initializer) {
        return $false
    }

    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return $false
    }

    [void]$global:AgentModeReplaceAllowed.Add($Name)
    $initBlock = $Initializer

    $stub = {
        $null = & $initBlock
        $targetName = $MyInvocation.MyCommand.Name
        if (-not (Get-Command -Name $targetName -CommandType Function -ErrorAction SilentlyContinue)) {
            throw "Initializer failed to define function '$targetName'."
        }
        & $targetName @args
    }.GetNewClosure()

    Set-Item -Path ("Function:\global:" + $Name) -Value $stub -Force | Out-Null

    if ($Alias) {
        Set-AgentModeAlias -Name $Alias -Target $Name | Out-Null
    }

    return $true
}

<#
.SYNOPSIS
    Registers a deprecated function wrapper that forwards to a replacement.
.DESCRIPTION
    Creates a function with the deprecated name that writes a warning and then
    invokes the specified replacement command with the original arguments.
.PARAMETER OldName
    The deprecated function or alias name.
.PARAMETER NewName
    The replacement command to invoke.
.PARAMETER RemovalVersion
    Optional version identifier describing when the deprecated command will be removed.
.PARAMETER Message
    Optional custom warning message to display instead of the default text.
.OUTPUTS
    System.Boolean
#>
function global:Register-DeprecatedFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$OldName,

        [Parameter(Mandatory)]
        [string]$NewName,

        [string]$RemovalVersion,

        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($OldName) -or [string]::IsNullOrWhiteSpace($NewName)) {
        return $false
    }

    $replacement = Get-Command -Name $NewName -ErrorAction SilentlyContinue
    if (-not $replacement) {
        throw "Replacement command '$NewName' not found."
    }

    $warningMessage = if ($Message) {
        $Message
    }
    else {
        $parts = @("'$OldName' is deprecated. Use '$NewName' instead.")
        if ($RemovalVersion) {
            $parts += "This command will be removed in version $RemovalVersion."
        }
        $parts -join ' '
    }

    $targetCommandName = $NewName
    $warningText = $warningMessage

    $wrapper = {
        Write-Warning $warningText
        & $targetCommandName @args
    }.GetNewClosure()

    Set-Item -Path ("Function:\global:" + $OldName) -Value $wrapper -Force | Out-Null

    return $true
}
