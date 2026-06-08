# ===============================================
# TestCommandAvailability.ps1
# Command availability stubs for tests (no Pester Mock)
# ===============================================

$script:OriginalTestCachedCommand = $null
$script:TestCachedCommandStubInstalled = $false

<#
.SYNOPSIS
    Installs a function wrapper for Test-CachedCommand that honors availability overrides.
#>
function Register-TestCommandAvailabilityStub {
    if ($script:TestCachedCommandStubInstalled) {
        return
    }

    $existing = Get-Command Test-CachedCommand -ErrorAction SilentlyContinue
    if (-not $existing -or $existing.CommandType -ne 'Function') {
        return
    }

    if (-not $script:OriginalTestCachedCommand) {
        $script:OriginalTestCachedCommand = $existing.ScriptBlock
    }

    $original = $script:OriginalTestCachedCommand
    $wrapper = {
        param(
            [Parameter(Position = 0)]
            [string]$Name,

            [int]$CacheTTLMinutes = 5
        )

        $actualName = $Name
        if ([string]::IsNullOrWhiteSpace($actualName) -and $args.Count -gt 0 -and $args[0] -is [string]) {
            $actualName = $args[0]
        }

        if (-not [string]::IsNullOrWhiteSpace($actualName) -and $global:TestCommandAvailabilityOverrides) {
            $trimmed = $actualName.Trim()
            $lower = $trimmed.ToLowerInvariant()
            if ($global:TestCommandAvailabilityOverrides.ContainsKey($trimmed)) {
                return [bool]$global:TestCommandAvailabilityOverrides[$trimmed]
            }
            if ($global:TestCommandAvailabilityOverrides.ContainsKey($lower)) {
                return [bool]$global:TestCommandAvailabilityOverrides[$lower]
            }
        }

        if ($PSBoundParameters.Count -gt 0) {
            return & $original @PSBoundParameters
        }

        return & $original $actualName $CacheTTLMinutes
    }.GetNewClosure()

    Set-Item -Path 'Function:\global:Test-CachedCommand' -Value $wrapper -Force -ErrorAction SilentlyContinue
    $script:TestCachedCommandStubInstalled = $true
}

<#
.SYNOPSIS
    Restores the original Test-CachedCommand after stub installation.
#>
function Clear-TestCommandAvailabilityStub {
    if (-not $script:TestCachedCommandStubInstalled) {
        return
    }

    Remove-Item -Path 'Function:\Test-CachedCommand' -Force -ErrorAction SilentlyContinue
    Remove-Item -Path 'Function:\global:Test-CachedCommand' -Force -ErrorAction SilentlyContinue

    if ($script:OriginalTestCachedCommand) {
        Set-Item -Path 'Function:\global:Test-CachedCommand' -Value $script:OriginalTestCachedCommand -Force -ErrorAction SilentlyContinue
    }

    $script:TestCachedCommandStubInstalled = $false
}

<#
.SYNOPSIS
    Sets whether a command appears available to profile helpers during tests.
#>
function Set-TestCommandAvailabilityState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [bool]$Available = $true,

        # Accepted for test call-site compatibility; state is cleared per test via TestSupport hooks.
        [string]$Scope
    )

    if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    elseif ($global:AssumedAvailableCommands -is [System.Collections.Hashtable]) {
        $converted = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $global:AssumedAvailableCommands.GetEnumerator()) {
            $converted[[string]$entry.Key] = [bool]$entry.Value
        }
        $global:AssumedAvailableCommands = $converted
    }

    if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
    }
    elseif ($global:TestCachedCommandCache -is [System.Collections.Hashtable]) {
        $convertedCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $global:TestCachedCommandCache.GetEnumerator()) {
            $convertedCache[[string]$entry.Key] = $entry.Value
        }
        $global:TestCachedCommandCache = $convertedCache
    }

    $normalized = $CommandName.Trim()
    $cacheKey = $normalized.ToLowerInvariant()
    $cacheExpiry = (Get-Date).AddHours(24)
    $removed = $null

    $null = $global:AssumedAvailableCommands.TryRemove($normalized, [ref]$removed)
    $null = $global:AssumedAvailableCommands.TryRemove($cacheKey, [ref]$removed)

    if (-not (Get-Variable -Name 'TestCommandAvailabilityOverrides' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestCommandAvailabilityOverrides = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    $null = $global:TestCommandAvailabilityOverrides.TryRemove($normalized, [ref]$removed)
    $null = $global:TestCommandAvailabilityOverrides.TryRemove($cacheKey, [ref]$removed)
    $global:TestCommandAvailabilityOverrides[$normalized] = $Available
    $global:TestCommandAvailabilityOverrides[$cacheKey] = $Available

    Remove-Item -Path "Function:\$normalized" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "Function:\global:$normalized" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "Function:\$cacheKey" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "Function:\global:$cacheKey" -Force -ErrorAction SilentlyContinue

    # Only remove mock-registered command stubs; preserve profile aliases (e.g. helm -> Invoke-Helm).
    if ($global:TestRegisteredMockCommands -and $global:TestRegisteredMockCommands.Contains($normalized)) {
        Remove-Item -Path "Alias:\$normalized" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\global:$normalized" -Force -ErrorAction SilentlyContinue
        [void]$global:TestRegisteredMockCommands.Remove($normalized)
    }

    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }

    $null = $global:TestCachedCommandCache.TryRemove($cacheKey, [ref]$removed)
    $null = $global:TestCachedCommandCache.TryRemove($normalized, [ref]$removed)

    if ($Available) {
        $global:AssumedAvailableCommands[$normalized] = $true
        $global:AssumedAvailableCommands[$cacheKey] = $true

        if (-not (Get-Variable -Name 'TestRegisteredMockCommands' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:TestRegisteredMockCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }

        [void]$global:TestRegisteredMockCommands.Add($normalized)

        $commandLabel = $normalized
        $stubCommand = {
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            Write-Output "Mocked $commandLabel called with: $($Arguments -join ' ')"
        }.GetNewClosure()

        Set-Item -Path "Function:\global:$normalized" -Value $stubCommand -Force
        Register-TestCommandAvailabilityStub
        return
    }

    $cacheEntry = [pscustomobject]@{
        Result  = $false
        Expires = $cacheExpiry
    }
    $global:TestCachedCommandCache[$cacheKey] = $cacheEntry
    $global:TestCachedCommandCache[$normalized] = $cacheEntry

    Register-TestCommandAvailabilityStub
}
