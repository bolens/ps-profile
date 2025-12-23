# ===============================================
# GlobalState.ps1
# Global state variable initialization
# ===============================================

# Idempotency check: if bootstrap was already initialized, ensure global variables
# are still present (they may have been cleared). This allows safe re-sourcing.
if (Get-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -ErrorAction SilentlyContinue) {
    # Re-initialize global caches if missing (thread-safe collections for concurrent access)
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

    if (-not (Get-Variable -Name 'CollectedMissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:CollectedMissingToolWarnings = [System.Collections.Generic.List[hashtable]]::new()
    }

    # Re-initialize fragment warning suppression from environment variable
    $reinitCommand = Get-Command -Name 'Initialize-FragmentWarningSuppression' -ErrorAction SilentlyContinue
    if ($reinitCommand) {
        Initialize-FragmentWarningSuppression
    }
}

Set-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -Value $true -Force

# Calculate paths relative to this bootstrap file
$script:BootstrapRoot = Split-Path -Parent $PSCommandPath
$script:RepoRoot = Split-Path -Parent $script:BootstrapRoot

# Initialize global caches and state variables (thread-safe collections for profile-wide use)
if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

# Tracks function names that are allowed to be replaced (used by lazy-loading)
if (-not (Get-Variable -Name 'AgentModeReplaceAllowed' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:AgentModeReplaceAllowed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

# Commands that should be treated as available even if not found on PATH (for optional tools)
if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

# Tracks which tool warnings have been shown to avoid duplicate messages
if (-not (Get-Variable -Name 'MissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:MissingToolWarnings = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

# Stores collected missing tool warnings with details for batch display
if (-not (Get-Variable -Name 'CollectedMissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:CollectedMissingToolWarnings = [System.Collections.Generic.List[hashtable]]::new()
}

# Stores batch loading information for organized display
if (-not (Get-Variable -Name 'BatchLoadingInfo' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:BatchLoadingInfo = @{
        DependencyParsingTime = $null
        DependencyLevels      = 0
        Batches               = [System.Collections.Generic.List[hashtable]]::new()
        TotalFragments        = 0
        SucceededFragments    = [System.Collections.Generic.List[string]]::new()
        FailedFragments       = [System.Collections.Generic.List[hashtable]]::new()
        StartTime             = $null
        EndTime               = $null
    }
}

# Fragment warning suppression: patterns from PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS environment variable
if (-not (Get-Variable -Name 'FragmentWarningPatternSet' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:FragmentWarningPatternSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

if (-not (Get-Variable -Name 'SuppressAllFragmentWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:SuppressAllFragmentWarnings = $false
}

<#
.SYNOPSIS
    Converts an environment variable value to a boolean.
.DESCRIPTION
    Normalizes environment variable values to boolean, supporting:
    - '1', 'true', 'True', 'TRUE' -> $true
    - '0', 'false', 'False', 'FALSE' -> $false
    - Empty/null/whitespace -> $false
.PARAMETER Value
    The environment variable value to convert.
.OUTPUTS
    System.Boolean
#>
function global:Test-EnvBool {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )
    
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    
    $normalized = $Value.Trim().ToLowerInvariant()
    
    # Accept '1' or 'true' as true
    if ($normalized -eq '1' -or $normalized -eq 'true') {
        return $true
    }
    
    # Everything else (including '0', 'false') is false
    return $false
}

