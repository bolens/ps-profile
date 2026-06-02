# ===============================================
# PesterMocks.psm1
# Pester 5 mocking utilities
# ===============================================

<#
.SYNOPSIS
    Pester 5 mocking utilities.

.DESCRIPTION
    Provides Pester 5-specific mocking functions with full Pester 5 syntax support.
    These functions wrap Pester 5's Mock command with convenient helpers.
#>

<#
.SYNOPSIS
    Creates a Pester 5 mock helper for common patterns.

.DESCRIPTION
    Provides a wrapper around Pester 5's Mock command with common parameter filters
    and Pester 5-specific features like -ExclusiveFilter, -Times, -Exactly, etc.

.PARAMETER CommandName
    Command to mock.

.PARAMETER MockWith
    Mock implementation scriptblock.

.PARAMETER ParameterFilter
    Parameter filter scriptblock (Pester 5 syntax).

.PARAMETER ExclusiveFilter
    Exclusive parameter filter (Pester 5 feature - only this filter matches).

.PARAMETER Scope
    Pester 5 scope: 'It', 'Context', 'Describe', or 'All'.

.PARAMETER Times
    Number of times the mock should be called (Pester 5 feature).

.PARAMETER Exactly
    If true, mock must be called exactly the specified number of times.

.PARAMETER Remove
    If true, removes the mock instead of creating one.

.EXAMPLE
    Use-PesterMock -CommandName 'Get-Command' -ParameterFilter { $Name -eq 'git' } -MockWith { $null }

.EXAMPLE
    Use-PesterMock -CommandName 'Test-HasCommand' -ParameterFilter { $Name -eq 'docker' } -MockWith { $false } -Scope Context

.EXAMPLE
    Use-PesterMock -CommandName 'Invoke-WebRequest' -MockWith { [PSCustomObject]@{ StatusCode = 200 } } -Times 1 -Exactly
#>
function Use-PesterMock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [scriptblock]$MockWith,

        [scriptblock]$ParameterFilter,

        [scriptblock]$ExclusiveFilter,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It',

        [int]$Times,

        [switch]$Exactly,

        [switch]$Remove
    )

    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        Write-Warning "Pester Mock command not available. Install Pester 5 module."
        return
    }

    $params = @{
        CommandName = $CommandName
    }

    if ($Remove) {
        $params['Remove'] = $true
        Mock @params
        return
    }

    if (-not $MockWith) {
        Write-Warning "MockWith is required when creating a mock."
        return
    }

    $params['MockWith'] = $MockWith
    $params['Scope'] = $Scope

    if ($ParameterFilter) {
        $params['ParameterFilter'] = $ParameterFilter
    }

    if ($ExclusiveFilter) {
        $params['ExclusiveFilter'] = $ExclusiveFilter
    }

    if ($Times -gt 0) {
        if ($Exactly) {
            $params['Times'] = $Times
            $params['Exactly'] = $true
        }
        else {
            $params['Times'] = $Times
        }
    }

    Mock @params
}

<#
.SYNOPSIS
    Verifies that a Pester 5 mock was called.

.DESCRIPTION
    Wrapper around Pester 5's Should -Invoke command for verifying mock calls.

.PARAMETER CommandName
    Command that was mocked.

.PARAMETER Times
    Expected number of calls.

.PARAMETER Exactly
    If true, must be called exactly the specified number of times.

.PARAMETER ParameterFilter
    Parameter filter to verify specific calls.

.PARAMETER Scope
    Pester 5 scope to check.

.EXAMPLE
    Use-PesterMock -CommandName 'Get-Command' -MockWith { $null }
    # ... test code ...
    Assert-MockCalled -CommandName 'Get-Command' -Times 1

.EXAMPLE
    Assert-MockCalled -CommandName 'Test-HasCommand' -ParameterFilter { $Name -eq 'docker' } -Times 1 -Exactly
#>
function Assert-MockCalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [int]$Times = 1,

        [switch]$Exactly,

        [scriptblock]$ParameterFilter,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    if (-not (Get-Command Should -ErrorAction SilentlyContinue)) {
        Write-Warning "Pester Should command not available. Install Pester 5 module."
        return
    }

    $params = @{
        CommandName = $CommandName
        Times       = $Times
        Scope       = $Scope
    }

    if ($Exactly) {
        $params['Exactly'] = $true
    }

    if ($ParameterFilter) {
        $params['ParameterFilter'] = $ParameterFilter
    }

    Should -Invoke @params
}

<#
.SYNOPSIS
    Creates a Pester 5 mock for command availability with common patterns.

.DESCRIPTION
    Helper function that creates Pester 5 mocks for Get-Command and Test-HasCommand
    with proper parameter filters for common command availability testing patterns.

.PARAMETER CommandName
    Name of the command to mock.

.PARAMETER Available
    Whether the command should appear available.

.PARAMETER CommandType
    Type of command (Application, Function, Cmdlet, etc.). Defaults to 'Application'.

.PARAMETER Scope
    Pester 5 scope.

.EXAMPLE
    Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope Context
#>
function Invoke-PesterMockInCallerScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        Write-Warning 'Pester Mock command not available. Install Pester 5 module.'
        return
    }

    $testFrame = Get-PSCallStack | Where-Object { $_.ScriptName -like '*.tests.ps1' } | Select-Object -First 1
    if (-not $testFrame) {
        & $ScriptBlock
        return
    }

    $sessionState = $testFrame.InvocationInfo.MyCommand.Module.SessionState
    if ($null -eq $sessionState) {
        & $ScriptBlock
        return
    }

    $null = $sessionState.InvokeCommand.InvokeScript(
        $true,
        $ScriptBlock,
        $sessionState,
        $sessionState.Global,
        $sessionState.Module,
        @(),
        @(),
        @()
    )
}

function Set-TestCommandAvailabilityState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [bool]$Available = $true
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
        return
    }

    $cacheEntry = [pscustomobject]@{
        Result  = $false
        Expires = $cacheExpiry
    }
    $global:TestCachedCommandCache[$cacheKey] = $cacheEntry
    $global:TestCachedCommandCache[$normalized] = $cacheEntry
}

function Register-TestCommandAvailabilityPesterMock {
    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        return
    }

    if (-not (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue)) {
        return
    }

    Mock -CommandName Test-CachedCommand -MockWith {
        param(
            [Parameter(Position = 0)]
            [string]$Name,

            [int]$CacheTTLMinutes = 5
        )

        $actualName = $Name
        if ([string]::IsNullOrWhiteSpace($actualName) -and $args.Count -gt 0) {
            $firstArg = $args[0]
            if ($firstArg -is [string]) {
                $actualName = $firstArg
            }
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

        if ([string]::IsNullOrWhiteSpace($actualName)) {
            return $false
        }

        $trimmed = $actualName.Trim()
        $lower = $trimmed.ToLowerInvariant()

        if ($global:AssumedAvailableCommands -and $global:AssumedAvailableCommands.ContainsKey($trimmed)) {
            return $true
        }

        if ($global:TestCachedCommandCache -and $global:TestCachedCommandCache.ContainsKey($lower)) {
            $entry = [pscustomobject]$global:TestCachedCommandCache[$lower]
            if ($entry -and $entry.Expires -gt (Get-Date)) {
                return [bool]$entry.Result
            }
        }

        return $null -ne (Get-Command -Name $trimmed -ErrorAction SilentlyContinue)
    }
}

function Mock-CommandAvailabilityPester {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [bool]$Available = $true,

        [string]$CommandType = 'Application',

        # Backward compatibility: ignored in Pester 5 (mocks are scoped to the current block)
        [string]$Scope
    )

    # CRITICAL: Check call depth FIRST before doing anything that might trigger recursion
    # Use a simple counter instead of a stack to avoid any potential issues
    if (-not (Get-Variable -Name '__MockCallDepth' -Scope Script -ErrorAction SilentlyContinue)) {
        $script:__MockCallDepth = 0
    }
    
    # Prevent infinite recursion by limiting call depth
    if ($script:__MockCallDepth -ge 5) {
        Write-Warning "Mock call depth limit reached. Aborting mock for $CommandName to prevent recursion."
        return
    }
    
    # Check if we're already inside a Test-HasCommand call (would cause recursion)
    # Use Get-PSCallStack to detect if Test-HasCommand is in the call stack
    $callStack = Get-PSCallStack
    $isInTestHasCommand = $callStack | Where-Object { $_.FunctionName -eq 'Test-HasCommand' }
    if ($isInTestHasCommand -and -not $Available) {
        Write-Warning "Detected recursive call to Mock-CommandAvailabilityPester from within Test-HasCommand. Skipping mock for $CommandName to prevent recursion."
        return
    }
    
    # Increment depth counter
    $script:__MockCallDepth++
    
    try {
        Set-TestCommandAvailabilityState -CommandName $CommandName -Available $Available
        Register-TestCommandAvailabilityPesterMock

        if (Get-Command Mock -ErrorAction SilentlyContinue) {
            $capturedCommandName = $CommandName
            $capturedAvailable = $Available
            $mockGetCommandResult = if ($capturedAvailable) {
                [PSCustomObject]@{
                    Name        = $capturedCommandName
                    CommandType = $CommandType
                    Source      = "Mock\$capturedCommandName.exe"
                }
            }
            else {
                $null
            }

            $cmdName = $capturedCommandName
            $cmdNameLower = $capturedCommandName.ToLowerInvariant()

            Mock -CommandName Get-Command -ParameterFilter {
                param([string]$Name)
                $nameToCheck = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { $null }
                if ([string]::IsNullOrWhiteSpace($nameToCheck)) {
                    return $false
                }
                $normalized = $nameToCheck.Trim().ToLowerInvariant()
                ($normalized -eq $cmdNameLower) -or ($nameToCheck.Trim() -eq $cmdName)
            } -MockWith {
                return $mockGetCommandResult
            }

            if ($capturedAvailable) {
                $mockCommandScript = {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    Write-Output "Mocked $capturedCommandName called with: $($Arguments -join ' ')"
                }.GetNewClosure()
                Set-Item -Path "Function:\$capturedCommandName" -Value $mockCommandScript -Force -ErrorAction SilentlyContinue
                Set-Item -Path "Function:\global:$capturedCommandName" -Value $mockCommandScript -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Error "Unexpected error in Mock-CommandAvailabilityPester for $CommandName : $($_.Exception.Message)" -ErrorAction Continue
    }
    finally {
        if ($script:__MockCallDepth -gt 0) {
            $script:__MockCallDepth--
        }
    }
}

<#
.SYNOPSIS
    Sets up common Pester 5 mocks for a test context.

.DESCRIPTION
    Creates Pester 5 mocks for common external commands used in profile fragments.
    This is a convenience function that uses Pester 5 syntax throughout.

.PARAMETER Commands
    Array of command names to mock. Defaults to common development tools.

.PARAMETER MockNetwork
    If true, mocks network operations using Pester 5.

.PARAMETER Scope
    Pester 5 scope for the mocks.

.EXAMPLE
    BeforeEach {
        Initialize-PesterMocks -Commands @('git', 'docker') -Scope It
    }
#>
function Initialize-PesterMocks {
    [CmdletBinding()]
    param(
        [string[]]$Commands = @('git', 'docker', 'kubectl', 'terraform', 'aws', 'az', 'gcloud'),

        [switch]$MockNetwork,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        Write-Warning "Pester Mock command not available. Install Pester 5 module."
        return
    }

    # Mock common commands as unavailable by default
    # Note: In Pester 5, mocks are automatically scoped to the current block
    foreach ($cmd in $Commands) {
        Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
    }

    # Mock network if requested
    if ($MockNetwork) {
        Invoke-PesterMockInCallerScope -ScriptBlock {
            Mock -CommandName Test-Connection -MockWith {
                [PSCustomObject]@{
                    ComputerName = 'localhost'
                    ResponseTime = 1
                    Status       = 'Success'
                }
            }

            Mock -CommandName Resolve-DnsName -MockWith {
                [PSCustomObject]@{
                    Name      = 'localhost'
                    Type      = 'A'
                    IPAddress = '127.0.0.1'
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Sets up Pester 5 mocks for a command to make it appear available.

.DESCRIPTION
    This function configures Pester 5 mocks to make a command appear available for testing.
    It handles:
    - Mocking Test-CachedCommand to return true for the specified command
    - Mocking Get-Command to return a mock command object
    - Creating a function mock so the command can be called with the & operator
    - Clearing the command cache to ensure mocks work correctly
    
    This function uses a global hashtable to track available commands, avoiding script scope
    issues when the function is imported from a module.

.PARAMETER CommandName
    The name of the command to mock as available.

.EXAMPLE
    Setup-AvailableCommandMock -CommandName 'docker'
    
    # Now Test-CachedCommand 'docker' will return $true
    # And Get-Command 'docker' will return a mock object
    # And & docker can be called (will use the function mock)

.NOTES
    This function is designed to work with Pester 5's automatic scoping. Mocks created
    by this function are automatically scoped to the current test block (It, Context, etc.).
    
    After calling this function, you can set up additional Mock calls for the command
    to customize its behavior in your tests.
    
    See also: Mock-CommandAvailabilityPester for mocking command availability with more options.
#>
function Setup-AvailableCommandMock {
    param([string]$CommandName)

    Set-TestCommandAvailabilityState -CommandName $CommandName -Available $true
}

<#
.SYNOPSIS
    Creates a reusable mock helper for capturing command arguments with ValueFromRemainingArguments.

.DESCRIPTION
    Creates a Pester mock that captures all arguments passed to a command, especially useful
    for testing functions that use ValueFromRemainingArguments and splat arguments to external commands.
    
    This helper reduces boilerplate when testing commands that are called with splatted arguments
    from ValueFromRemainingArguments parameters.

.PARAMETER CommandName
    The name of the command to mock.

.PARAMETER MockOutput
    Optional output to return from the mock. Defaults to empty string.

.PARAMETER ValidationScript
    Optional scriptblock to execute with the captured arguments for validation.

.EXAMPLE
    $mock = New-CommandArgumentCaptureMock -CommandName 'choco'
    Install-ChocoPackage -Packages git
    $mock.VerifyCalled()
    $mock.CapturedArgs() | Should -Contain 'install'
    $mock.CapturedArgs() | Should -Contain 'git'

.EXAMPLE
    $mock = New-CommandArgumentCaptureMock -CommandName 'choco' -MockOutput 'Success'
    Update-ChocoPackages
    $mock.CapturedArgs() | Should -Contain 'upgrade'

.NOTES
    This function uses script-scope variables to capture arguments, so the captured arguments
    are accessible after the mock executes. The mock uses ValueFromRemainingArguments to
    capture all arguments, including those from splatted arrays.
    
    In Pester 5, mocks are automatically scoped to the current block (It, Context, Describe).
    No -Scope parameter is needed on Mock calls.
    
    LIMITATIONS:
    - If function mocks exist from Mock-CommandAvailabilityPester, they may take precedence
      when using & operator, and Pester mocks may not intercept. In such cases, use the
      direct mock pattern (see MOCKING.md Pattern 6) instead of this helper.
    - This helper works best when function mocks don't exist, or when they're removed first.
#>
function New-CommandArgumentCaptureMock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [string]$MockOutput = '',

        [scriptblock]$ValidationScript
    )

    # Use a simple script-scope variable name (standard pattern used in tests)
    # This matches the pattern used in the Chocolatey tests
    # Use standard variable name - tests should use this helper one at a time per It block
    $script:capturedArgs = $null

    # Check if function mock exists - if so, update it to capture arguments
    # Function mocks take precedence when using & operator, so we update them directly
    $existingFunction = Get-Command $CommandName -ErrorAction SilentlyContinue
    $hasFunctionMock = $existingFunction -and $existingFunction.CommandType -eq 'Function'
    
    if ($hasFunctionMock) {
        # Update function mock to capture arguments
        $escapedOutput = $MockOutput -replace "'", "''"
        $functionBodyStr = @"
param([Parameter(ValueFromRemainingArguments = `$true)][object[]]`$Arguments)
`$script:capturedArgs = `$Arguments
if ('$escapedOutput') {
    Write-Output '$escapedOutput'
}
"@
        $functionBody = [scriptblock]::Create($functionBodyStr)
        Set-Item -Path "Function:\$CommandName" -Value $functionBody -Force -ErrorAction SilentlyContinue
        Set-Item -Path "Function:\global:$CommandName" -Value $functionBody -Force -ErrorAction SilentlyContinue
    }

    # Capture parameters for closure
    $capturedCommandName = $CommandName
    $capturedMockOutput = $MockOutput
    $capturedValidationScript = $ValidationScript

    # Always create Pester mock for tracking (even if function mock exists)
    # Note: In Pester 5, mocks are automatically scoped to the current block (It, Context, Describe)
    # No -Scope parameter needed on Mock calls
    Mock -CommandName $CommandName -MockWith {
        param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
        
        # Capture arguments in script scope
        $script:capturedArgs = $Arguments
        
        # Execute validation script if provided
        if ($capturedValidationScript) {
            & $capturedValidationScript -Arguments $Arguments
        }
        
        # Return mock output
        if ($capturedMockOutput) {
            Write-Output $capturedMockOutput
        }
    }

    # Create object with methods using Add-Member
    $result = [PSCustomObject]@{
        CommandName = $capturedCommandName
    }
    
    # Add CapturedArgs as a method
    $result | Add-Member -MemberType ScriptMethod -Name 'CapturedArgs' -Value {
        return $script:capturedArgs
    }
    
    # Add VerifyCalled as a method
    # Uses Pester's Should -Invoke to verify the mock was called
    # Note: If function mocks exist from Mock-CommandAvailabilityPester, they may take precedence
    # and Pester mocks may not intercept. In such cases, use the direct mock pattern instead.
    $result | Add-Member -MemberType ScriptMethod -Name 'VerifyCalled' -Value {
        param([int]$Times = 1, [switch]$Exactly)
        $params = @{
            CommandName = $this.CommandName
            Times       = $Times
        }
        if ($Exactly) {
            $params['Exactly'] = $true
        }
        Should -Invoke @params
    }
    
    return $result
}

