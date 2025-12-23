# ===============================================
# MockCommand.psm1
# Command mocking utilities
# ===============================================

<#
.SYNOPSIS
    Command mocking utilities.

.DESCRIPTION
    Provides functions for mocking external commands and command availability checks.
#>

# Import mock registry functions
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $modulePath 'MockRegistry.psm1') -DisableNameChecking -ErrorAction Stop

<#
.SYNOPSIS
    Mocks an external command with a function.

.DESCRIPTION
    Creates a function that shadows an external command, preventing it from executing.
    Useful for mocking commands like git, docker, etc. in tests.

.PARAMETER CommandName
    Name of the command to mock.

.PARAMETER MockWith
    ScriptBlock to execute when the command is called. Defaults to a no-op that writes verbose output.

.PARAMETER ReturnValue
    Simple value to return (alternative to MockWith).

.PARAMETER ExitCode
    Exit code to simulate (for commands that set $LASTEXITCODE).

.PARAMETER Output
    Output to write (for commands that produce output).

.EXAMPLE
    Mock-Command -CommandName 'git' -MockWith { Write-Output 'git version 2.30.0' }

.EXAMPLE
    Mock-Command -CommandName 'docker' -ReturnValue $null -ExitCode 0
#>
function Mock-Command {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [scriptblock]$MockWith,

        [object]$ReturnValue,

        [int]$ExitCode = 0,

        [object[]]$Output
    )

    # Store original command if it exists
    $original = Get-Command $CommandName -ErrorAction SilentlyContinue

    # Create mock scriptblock
    if ($MockWith) {
        $mockScript = $MockWith
    }
    elseif ($null -ne $ReturnValue) {
        $mockScript = { return $ReturnValue }
    }
    elseif ($Output) {
        $mockScript = {
            foreach ($item in $Output) {
                Write-Output $item
            }
        }
    }
    else {
        # Default: no-op with verbose logging
        $cmdName = $CommandName
        $mockScript = [scriptblock]::Create(@"
            param([Parameter(ValueFromRemainingArguments = `$true)] `$args)
            Write-Verbose "Mock: Would execute '$cmdName' with args: `$(`$args -join ' ')"
            `$script:LASTEXITCODE = $ExitCode
"@)
    }

    # Set exit code if specified
    if ($ExitCode -ne 0) {
        $oldScript = $mockScript
        $mockScript = [scriptblock]::Create(@"
            `$result = & {
                $($oldScript.ToString())
            }
            `$script:LASTEXITCODE = $ExitCode
            return `$result
"@)
    }

    # Create function mock
    Set-Item -Path "Function:\$CommandName" -Value $mockScript -Force -ErrorAction SilentlyContinue

    # Also create in global scope
    $functionName = "global:$CommandName"
    $functionBody = [scriptblock]::Create(@"
        param([Parameter(ValueFromRemainingArguments = `$true)] `$args)
        & `$mockScript @args
"@)
    Set-Item -Path "Function:\$functionName" -Value $functionBody -Force -ErrorAction SilentlyContinue

    # Register for cleanup
    Register-Mock -Type 'Command' -Name $CommandName -MockValue $mockScript -Original $original

    Write-Verbose "Mocked command: $CommandName"
}

<#
.SYNOPSIS
    Mocks multiple commands at once.

.DESCRIPTION
    Convenience function to mock multiple commands with default no-op behavior.

.PARAMETER CommandNames
    Array of command names to mock.

.EXAMPLE
    Mock-Commands -CommandNames @('git', 'docker', 'kubectl')
#>
function Mock-Commands {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$CommandNames
    )

    foreach ($cmd in $CommandNames) {
        Mock-Command -CommandName $cmd
    }
}

<#
.SYNOPSIS
    Mocks command availability checks.

.DESCRIPTION
    Mocks Get-Command or Test-HasCommand to return specific availability results.
    This is a function-based mock (not Pester). For Pester mocks, use Mock-CommandAvailabilityPester.

.PARAMETER CommandName
    Name of the command to mock availability for.

.PARAMETER Available
    Whether the command should appear available.

.PARAMETER UsePesterMock
    If true, uses Pester's Mock command instead of function-based mock.

.EXAMPLE
    Mock-CommandAvailability -CommandName 'docker' -Available $false
#>
function Mock-CommandAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [bool]$Available = $true,

        [switch]$UsePesterMock
    )

    if ($UsePesterMock -and (Get-Command Mock -ErrorAction SilentlyContinue)) {
        # Use Pester 5 mock
        $mockResult = if ($Available) {
            [PSCustomObject]@{
                Name        = $CommandName
                CommandType = 'Application'
                Source      = "Mock\$CommandName.exe"
            }
        }
        else {
            $null
        }

        # Pester 5 syntax
        Mock -CommandName Get-Command -ParameterFilter { $Name -eq $CommandName } -MockWith { $mockResult } -Scope It
        Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq $CommandName } -MockWith { $Available } -Scope It
        return
    }

    # Function-based mock for Get-Command
    $originalGetCommand = Get-Command Get-Command -ErrorAction SilentlyContinue
    $cmdName = $CommandName
    $isAvailable = $Available

    $mockGetCommand = {
        param(
            [Parameter(Position = 0)]
            [string]$Name,

            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$RemainingArgs
        )

        if ($Name -eq $cmdName) {
            if ($isAvailable) {
                return [PSCustomObject]@{
                    Name        = $cmdName
                    CommandType = 'Application'
                    Source      = "Mock\$cmdName.exe"
                }
            }
            else {
                return $null
            }
        }

        # For other commands, call original
        if ($originalGetCommand) {
            return & $originalGetCommand -Name $Name @RemainingArgs
        }
        return $null
    }

    # Mock Test-HasCommand if it exists
    if (Get-Command Test-HasCommand -ErrorAction SilentlyContinue) {
        $originalTestHasCommand = Get-Command Test-HasCommand
        $mockTestHasCommand = {
            param([string]$Name)
            if ($Name -eq $cmdName) {
                return $isAvailable
            }
            # Call original for other commands
            return & $originalTestHasCommand -Name $Name
        }
        Set-Item -Path Function:\Test-HasCommand -Value $mockTestHasCommand -Force -ErrorAction SilentlyContinue
        Register-Mock -Type 'Function' -Name 'Test-HasCommand' -MockValue $mockTestHasCommand -Original $originalTestHasCommand
    }
}

<#
.SYNOPSIS
    Sets up common mocks for profile testing.

.DESCRIPTION
    Mocks common external commands and operations used in profile fragments.
    This function uses function-based mocks (not Pester). For Pester mocks, use Initialize-PesterMocks.

.PARAMETER Commands
    Array of command names to mock. Defaults to common development tools.

.PARAMETER MockNetwork
    If true, mocks network operations.

.PARAMETER MockFileSystem
    If true, mocks file system operations (limited).

.EXAMPLE
    Initialize-CommonMocks -Commands @('git', 'docker')
#>
function Initialize-CommonMocks {
    [CmdletBinding()]
    param(
        [string[]]$Commands = @('git', 'docker', 'kubectl', 'terraform', 'aws', 'az', 'gcloud'),

        [switch]$MockNetwork,

        [switch]$MockFileSystem
    )

    # Mock common commands
    foreach ($cmd in $Commands) {
        Mock-Command -CommandName $cmd
    }

    # Mock network if requested
    if ($MockNetwork) {
        $mockingDir = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'TestSupport' 'Mocking'
        $mockNetworkPath = Join-Path $mockingDir 'MockNetwork.psm1'
        if (Test-Path $mockNetworkPath) {
            Import-Module $mockNetworkPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
        }
        
        Mock-Network -Operation 'Test-Connection' -ReturnValue @{
            ComputerName = 'localhost'
            ResponseTime = 1
            Status       = 'Success'
        }

        Mock-Network -Operation 'Resolve-DnsName' -ReturnValue @{
            Name      = 'localhost'
            Type      = 'A'
            IPAddress = '127.0.0.1'
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Mock-Command',
    'Mock-Commands',
    'Mock-CommandAvailability',
    'Initialize-CommonMocks'
)

