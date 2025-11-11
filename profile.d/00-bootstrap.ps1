# ===============================================
# 00-bootstrap.ps1
# Core bootstrap helpers for profile fragments
# ===============================================

if (Get-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -ErrorAction SilentlyContinue) {
    if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Script -ErrorAction SilentlyContinue)) {
        $script:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    if (-not (Get-Variable -Name 'AgentModeReplaceAllowed' -Scope Script -ErrorAction SilentlyContinue)) {
        $script:AgentModeReplaceAllowed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    return
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

if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Script -ErrorAction SilentlyContinue)) {
    $script:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'AgentModeReplaceAllowed' -Scope Script -ErrorAction SilentlyContinue)) {
    $script:AgentModeReplaceAllowed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
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

    $functionPath = "Function:\$Name"
    if (Test-Path -LiteralPath $functionPath) { return $true }

    $aliasPath = "Alias:\$Name"
    if (Test-Path -LiteralPath $aliasPath) { return $true }

    $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
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

    $cacheKey = $Name.ToLowerInvariant()
    $now = Get-Date

    if ($script:TestCachedCommandCache.ContainsKey($cacheKey)) {
        $entry = [pscustomobject]$script:TestCachedCommandCache[$cacheKey]
        if ($entry -and $entry.Expires -gt $now) {
            return [bool]$entry.Result
        }
    }

    $result = Test-HasCommand -Name $Name
    $expires = $now.AddMinutes([double]$CacheTTLMinutes)
    $script:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
        Result  = $result
        Expires = $expires
    }
    return $result
}

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
    $allowReplace = $script:AgentModeReplaceAllowed.Contains($Name)

    if ($existing -and -not $allowReplace) {
        return $false
    }

    $scriptBlock = $Body.GetNewClosure()
    Set-Item -Path ("Function:\global:" + $Name) -Value $scriptBlock -Force | Out-Null

    if ($allowReplace) {
        [void]$script:AgentModeReplaceAllowed.Remove($Name)
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

    [void]$script:AgentModeReplaceAllowed.Add($Name)
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
