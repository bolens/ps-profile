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
function Mock-CommandAvailabilityPester {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [bool]$Available = $true,

        [string]$CommandType = 'Application'
        # Note: Scope parameter removed - Pester 5 mocks are automatically scoped to current block
        # The Scope parameter is only used with Should -Invoke, not with Mock
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

        # Check for Mock command using function provider to avoid recursion
        # Don't use Get-Command here as it might already be mocked
        $mockExists = $false
        try {
            # Use function provider check first (fastest, no command resolution)
            if (Test-Path Function:\Mock -ErrorAction SilentlyContinue) {
                $mockExists = $true
            }
            # Fallback to module check (doesn't trigger Get-Command)
            elseif (Get-Module Pester -ErrorAction SilentlyContinue) {
                $mockExists = $true
            }
        }
        catch {
            Write-Warning "Error checking for Mock command: $($_.Exception.Message)"
        }
    
        if (-not $mockExists) {
            Write-Warning "Pester Mock command not available. Install Pester 5 module."
            return
        }

        # Targeted approach: Mock Get-Command for the specific command to prevent it from being found
        # Now that we've fixed the k function recursion issue, we can safely mock Get-Command
        # Use a very simple parameter filter to avoid any recursion risk
        
        $capturedCommandName = $CommandName
        $capturedAvailable = $Available
        
        # Initialize AssumedAvailableCommands if needed
        if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:AssumedAvailableCommands = @{}
        }
        
        # CRITICAL: Remove from AssumedAvailableCommands BEFORE setting up the mock
        # The real Test-CachedCommand checks AssumedAvailableCommands FIRST (line 50 of CommandCache.ps1)
        # If the command is in AssumedAvailableCommands, it returns true immediately without calling Get-Command
        # So we MUST remove it from AssumedAvailableCommands so the mock can intercept the call
        # Remove from assumed commands regardless of availability - the mock will handle the return value
        $null = $global:AssumedAvailableCommands.TryRemove($capturedCommandName, [ref]$null)
        # Also try lowercase version
        $null = $global:AssumedAvailableCommands.TryRemove($capturedCommandName.ToLowerInvariant(), [ref]$null)
        
        # CRITICAL: Remove function mocks BEFORE clearing cache
        # Test-CachedCommand checks the function provider FIRST (before Get-Command)
        # If a function exists, Test-CachedCommand will return true even if Get-Command returns null
        # We must remove function mocks for unavailable commands BEFORE Test-CachedCommand is called
        if (-not $capturedAvailable) {
            # Remove function mocks if command should be unavailable
            # Test-CachedCommand checks Function:\ and Function:\global: paths
            Remove-Item -Path "Function:\$capturedCommandName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$capturedCommandName" -Force -ErrorAction SilentlyContinue
            # Also try lowercase version
            $lowerName = $capturedCommandName.ToLowerInvariant()
            Remove-Item -Path "Function:\$lowerName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$lowerName" -Force -ErrorAction SilentlyContinue
        }
        
        # CRITICAL: Clear TestCachedCommandCache BEFORE setting up mocks
        # The cache is checked BEFORE the mock can intercept, so we must clear it first
        # Clear the specific entry for our command
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $cacheKey = $capturedCommandName.ToLowerInvariant()
            if ($global:TestCachedCommandCache.ContainsKey($cacheKey)) {
                $null = $global:TestCachedCommandCache.TryRemove($cacheKey, [ref]$null)
            }
            # Also try the exact name (case-sensitive)
            if ($global:TestCachedCommandCache.ContainsKey($capturedCommandName)) {
                $null = $global:TestCachedCommandCache.TryRemove($capturedCommandName, [ref]$null)
            }
        }
        
        # Also clear the entire cache to be safe
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        # CRITICAL: The cache might be repopulated immediately if Test-CachedCommand is called
        # So we need to ensure the mock intercepts BEFORE the cache check
        # The mock we set up below will intercept the call, but we also need to ensure
        # Get-Command returns null so Test-CachedCommand doesn't find the command and cache it
        
        # Strategy: Mock Get-Command so Test-CachedCommand naturally returns the correct value
        # This is more reliable than trying to mock Test-CachedCommand directly
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
        
        # Mock Get-Command with a parameter filter that matches our command name
        # CRITICAL: Get-Command can be called with -Name parameter or positionally
        # We use a parameter filter to match only our specific command
        # This avoids intercepting all Get-Command calls which would break other tests
        Mock -CommandName Get-Command -ParameterFilter {
            param([string]$Name)
            # Check both $Name and $args[0] for positional calls
            $nameToCheck = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { $null }
            if ([string]::IsNullOrWhiteSpace($nameToCheck)) {
                return $false
            }
            $normalized = $nameToCheck.Trim().ToLowerInvariant()
            ($normalized -eq $cmdNameLower) -or ($nameToCheck.Trim() -eq $cmdName)
        } -MockWith {
            return $mockGetCommandResult
        }
        
        # ALSO mock Test-CachedCommand directly to ensure it returns the mocked value
        # This is a backup in case Get-Command mock doesn't work
        # Note: In Pester 5, mocks are automatically scoped to the current block - no -Scope parameter needed
        # CRITICAL: Parameter filters don't work reliably with positional parameters in Pester
        # So we match ALL calls and check the parameter inside the mock body
        # We also clear the cache entry inside the mock to ensure fresh evaluation
        if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
            $mockValue = $capturedAvailable
            $cmdNameForMock = $capturedCommandName  # Capture for closure
            $cmdNameLowerForMock = $capturedCommandName.ToLowerInvariant()
            
            # Match ALL calls - no parameter filter
            # This ensures the mock intercepts BEFORE the real function executes (and before cache checks)
            # CRITICAL: Pester mocks intercept at the function call level, so they should intercept
            # before any code in the real function executes, including cache checks
            Mock -CommandName Test-CachedCommand -MockWith {
                param(
                    [Parameter(Position = 0)]
                    [string]$Name
                )
                
                # Get the actual name from parameter or args
                # When called positionally like Test-CachedCommand 'gitleaks', PowerShell binds to -Name parameter
                # But we also check $args as a fallback
                $actualName = $Name
                if ([string]::IsNullOrWhiteSpace($actualName) -and $args.Count -gt 0) {
                    $firstArg = $args[0]
                    if ($firstArg -is [string]) {
                        $actualName = $firstArg
                    }
                }
                
                # Also check PSBoundParameters as another fallback
                if ([string]::IsNullOrWhiteSpace($actualName) -and $PSBoundParameters.ContainsKey('Name')) {
                    $actualName = $PSBoundParameters['Name']
                }
                
                # Check if this is our command
                if (-not [string]::IsNullOrWhiteSpace($actualName)) {
                    $inputNormalized = $actualName.Trim().ToLowerInvariant()
                    $inputExact = $actualName.Trim()
                    
                    # Match both normalized and exact case
                    if ($inputNormalized -eq $cmdNameLowerForMock -or $inputExact -eq $cmdNameForMock) {
                        # This is our command - clear cache entry and return mocked value
                        # Clear cache to prevent stale entries from being returned
                        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
                            $cacheKey = $inputNormalized
                            $null = $global:TestCachedCommandCache.TryRemove($cacheKey, [ref]$null)
                            # Also try exact case
                            if ($global:TestCachedCommandCache.ContainsKey($inputExact)) {
                                $null = $global:TestCachedCommandCache.TryRemove($inputExact, [ref]$null)
                            }
                        }
                        # Return the mocked value directly, bypassing ALL checks
                        return $mockValue
                    }
                }
                
                # Not our command - we need to call the real function
                # CRITICAL: We can't use Get-Command here because it will return the mock (recursion)
                # We also can't easily get the original function from the function provider because
                # Pester replaces the function with the mock
                # 
                # Solution: Use Pester's built-in mechanism to call the original function
                # In Pester 5, we can use the -Verifiable parameter and Should -Invoke to verify calls
                # But for actually calling the original, we need to use a different approach
                #
                # For now, we'll use a workaround: temporarily remove the mock, call the original, then restore
                # But that's complex and might not work reliably
                #
                # Actually, a better approach: don't mock Test-CachedCommand for other commands at all
                # Only mock it when it's called for our specific command. But Pester mocks intercept all calls.
                #
                # The simplest solution: return false for other commands as a safe default
                # Tests that need Test-CachedCommand for other commands should set up their own mocks
                # This is acceptable because:
                # 1. Most tests only test one command at a time
                # 2. Tests can set up multiple mocks if needed
                # 3. It avoids recursion and complexity
                return $false
            }
        }
        
        # Also create a function mock for the command itself so it can be called
        # This ensures the command exists as a function when available
        # Pester mocks will take precedence over these function mocks when tests use Mock
        if ($capturedAvailable) {
            # Create a function mock that can be called
            # Tests can override this with Pester Mock calls which take precedence
            $mockCommandScript = {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # Default mock implementation - tests can override with their own Mock calls
                Write-Output "Mocked $capturedCommandName called with: $($Arguments -join ' ')"
            }
            Set-Item -Path "Function:\$capturedCommandName" -Value $mockCommandScript -Force -ErrorAction SilentlyContinue
            Set-Item -Path "Function:\global:$capturedCommandName" -Value $mockCommandScript -Force -ErrorAction SilentlyContinue
        }
        else {
            # CRITICAL: Remove function mocks if command should be unavailable
            # Test-CachedCommand checks Function:\ and Function:\global: paths FIRST (before Get-Command)
            # If a function exists, Test-CachedCommand will return true even if Get-Command returns null
            # We must remove from both locations and also try lowercase version
            Remove-Item -Path "Function:\$capturedCommandName" -ErrorAction SilentlyContinue -Force
            Remove-Item -Path "Function:\global:$capturedCommandName" -ErrorAction SilentlyContinue -Force
            # Also try lowercase version
            $lowerName = $capturedCommandName.ToLowerInvariant()
            Remove-Item -Path "Function:\$lowerName" -ErrorAction SilentlyContinue -Force
            Remove-Item -Path "Function:\global:$lowerName" -ErrorAction SilentlyContinue -Force
        }
        
        # For unavailable commands: Manipulate AssumedAvailableCommands to prevent command from being found
        # We avoid mocking Test-HasCommand directly to prevent recursion issues
        # Tests can directly mock Test-HasCommand if needed (see infrastructure-tools.tests.ps1:125 for working pattern)
        
        # The AssumedAvailableCommands manipulation ensures Test-HasCommand returns false
        # by removing the command from the assumed list, forcing it to check providers/Get-Command
        # For commands that actually exist, tests should directly mock Test-HasCommand in the test itself
    }
    catch {
        Write-Error "Unexpected error in Mock-CommandAvailabilityPester for $CommandName : $($_.Exception.Message)" -ErrorAction Continue
        Write-Error "Exception type: $($_.Exception.GetType().FullName)" -ErrorAction Continue
        if ($_.ScriptStackTrace) {
            Write-Error "Stack trace: $($_.ScriptStackTrace)" -ErrorAction Continue
        }
        if ($_.InnerException) {
            Write-Error "Inner exception: $($_.InnerException.Message)" -ErrorAction Continue
        }
    }
    finally {
        # Decrement depth counter
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
    
    # Initialize global hashtable for available command mocks
    if (-not (Get-Variable -Name '__AvailableCommandMocks' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:__AvailableCommandMocks = @{}
    }
    
    # Register this command as available in the global hashtable
    $normalized = $CommandName.ToLowerInvariant()
    $global:__AvailableCommandMocks[$normalized] = $true
    $global:__AvailableCommandMocks[$CommandName] = $true
    
    # Clear cache
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
        $null = $global:TestCachedCommandCache.TryRemove($CommandName, [ref]$null)
        $null = $global:TestCachedCommandCache.TryRemove($normalized, [ref]$null)
    }
    
    # Mock Test-CachedCommand to return true for commands in our hashtable
    # Use global hashtable to avoid script scope issues
    Mock -CommandName Test-CachedCommand -MockWith {
        param([string]$Name)
        $actualName = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { '' }
        if ([string]::IsNullOrWhiteSpace($actualName)) {
            return $false
        }
        
        $normalized = $actualName.Trim().ToLowerInvariant()
        $actualExact = $actualName.Trim()
        
        # Check if this command is in our available mocks hashtable
        if ($global:__AvailableCommandMocks -and 
            ($global:__AvailableCommandMocks.ContainsKey($normalized) -or 
            $global:__AvailableCommandMocks.ContainsKey($actualExact))) {
            return $true
        }
        
        return $false
    }
    
    # Mock Get-Command to return a mock object for commands in our hashtable
    # Use parameter filter to match only our commands
    Mock -CommandName Get-Command -ParameterFilter {
        $nameToCheck = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { $null }
        if ([string]::IsNullOrWhiteSpace($nameToCheck)) { return $false }
        $normalized = $nameToCheck.Trim().ToLowerInvariant()
        $actualExact = $nameToCheck.Trim()
        # Check if this command is in our available mocks hashtable
        $global:__AvailableCommandMocks -and 
        ($global:__AvailableCommandMocks.ContainsKey($normalized) -or 
        $global:__AvailableCommandMocks.ContainsKey($actualExact))
    } -MockWith {
        param([string]$Name)
        $nameToCheck = if ($Name) { $Name } elseif ($args.Count -gt 0) { $args[0] } else { $null }
        $actualExact = $nameToCheck.Trim()
        return [PSCustomObject]@{
            Name        = $actualExact
            CommandType = 'Application'
            Source      = "Mock\$actualExact.exe"
        }
    }
    
    # CRITICAL: Also create a function mock so the command can be called with & operator
    # This ensures Test-CachedCommand can find it via the function provider
    # Use the normalized name to check the hashtable
    if ($global:__AvailableCommandMocks -and 
        ($global:__AvailableCommandMocks.ContainsKey($normalized) -or 
        $global:__AvailableCommandMocks.ContainsKey($CommandName))) {
        $capturedCmdName = $CommandName
        $mockCommandScript = {
            param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
            # Default mock implementation - tests can override with their own Mock calls
            Write-Output "Mocked $capturedCmdName called with: $($Arguments -join ' ')"
        }
        Set-Item -Path "Function:\$CommandName" -Value $mockCommandScript -Force -ErrorAction SilentlyContinue
        Set-Item -Path "Function:\global:$CommandName" -Value $mockCommandScript -Force -ErrorAction SilentlyContinue
    }
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

# Export functions
Export-ModuleMember -Function @(
    'Use-PesterMock',
    'Assert-MockCalled',
    'Mock-CommandAvailabilityPester',
    'Initialize-PesterMocks',
    'Setup-AvailableCommandMock',
    'New-CommandArgumentCaptureMock'
)


