# ===============================================
# TestMocks.ps1
# Mock functions for test environment
# ===============================================

# Pre-initialize script-scoped state for Set-StrictMode compatibility
$script:OriginalEditorCommands = @{}
$script:OriginalStartProcess = $null
$script:TestDocumentLatexEngineOriginal = $null
$script:TestDocumentLatexEngineWasStubbed = $false
$global:TestStartProcessMockBlock = $null
$global:TestCommandInvocationCaptures = [System.Collections.Generic.List[object[]]]::new()
$global:TestCommandCaptureState = $null
$global:TestStartProcessCaptures = [System.Collections.Generic.List[hashtable]]::new()
if (-not (Get-Variable -Name 'TestRegisteredMockCommands' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:TestRegisteredMockCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

. (Join-Path $PSScriptRoot 'TestSupportCoreFunctions.ps1')

<#
.SYNOPSIS
    Resets cross-file test pollution from command mocks and profile global state.
.DESCRIPTION
    Clears command availability mocks, caches, and lazy-init flags so each test file
    starts from a clean slate when TestSupport is loaded in BeforeAll.
#>
function Reset-TestIsolationState {
    if ($env:PS_PROFILE_TEST_MODE -ne '1') {
        return
    }

    if (Get-Command Restore-TestSupportFunctions -ErrorAction SilentlyContinue) {
        Restore-TestSupportFunctions
    }

    if (Get-Command Restore-TestTerminalStubs -ErrorAction SilentlyContinue) {
        Restore-TestTerminalStubs
    }

    Initialize-TestProfileGlobals

    if (Get-Command Clear-TestCommandInvocationCapture -ErrorAction SilentlyContinue) {
        Clear-TestCommandInvocationCapture
    }

    Clear-AllFragmentLoadedState

    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }

    if (Get-Variable -Name 'TestCommandAvailabilityOverrides' -Scope Global -ErrorAction SilentlyContinue) {
        $global:TestCommandAvailabilityOverrides.Clear()
    }

    if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
        Clear-TestCommandAvailabilityStub
    }

    if (Get-Variable -Name 'TestRegisteredMockCommands' -Scope Global -ErrorAction SilentlyContinue) {
        foreach ($commandName in @($global:TestRegisteredMockCommands)) {
            Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Alias:\$commandName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Alias:\global:$commandName" -Force -ErrorAction SilentlyContinue
        }

        $global:TestRegisteredMockCommands.Clear()
    }

    if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    else {
        $global:AssumedAvailableCommands.Clear()
    }

    if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_ASSUME_COMMANDS) -and (Get-Command Add-AssumedCommand -ErrorAction SilentlyContinue)) {
        $assumedTokens = $env:PS_PROFILE_ASSUME_COMMANDS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if (@($assumedTokens).Count -gt 0) {
            Add-AssumedCommand -Name $assumedTokens | Out-Null
        }
    }

    if (Get-Variable -Name 'MissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue) {
        $global:MissingToolWarnings.Clear()
    }

    if (Get-Variable -Name 'CollectedMissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue) {
        $global:CollectedMissingToolWarnings.Clear()
    }

    if (Get-Variable -Name '__AvailableCommandMocks' -Scope Global -ErrorAction SilentlyContinue) {
        $global:__AvailableCommandMocks = @{}
    }

    $global:TestCommandCaptureState = $null

    foreach ($flagName in @(
            'GitInitialized'
            'UtilitiesInitialized'
            'SystemInitialized'
            'FileUtilitiesInitialized'
            'FileConversionDataInitialized'
            'FileConversionDocumentsInitialized'
            'FileConversionMediaInitialized'
            'FileConversionSpecializedInitialized'
            'DevToolsInitialized'
            'OhMyPoshStarshipInitialized'
            'SmartPromptCommandTrackingSetup'
            'SmartPromptInitialized'
            'ErrorHandlingLoaded'
        )) {
        Set-Variable -Name $flagName -Scope Global -Value $false -Force -ErrorAction SilentlyContinue
    }

    foreach ($globalName in @(
            'OriginalErrorActionPreference'
            'PSProfileOriginalVerbosePreference'
            'CommandStartTime'
        )) {
        if (-not (Get-Variable -Name $globalName -Scope Global -ErrorAction SilentlyContinue)) {
            Set-Variable -Name $globalName -Scope Global -Value $null -Force
        }
    }

    if (-not (Get-Variable -Name 'PSProfileSuppressVerboseForExternalTools' -Scope Global -ErrorAction SilentlyContinue)) {
        Set-Variable -Name 'PSProfileSuppressVerboseForExternalTools' -Scope Global -Value $false -Force
    }

    foreach ($cloudCommand in @('aws', 'az', 'gcloud')) {
        Remove-Item -Path "Function:\$cloudCommand" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$cloudCommand" -Force -ErrorAction SilentlyContinue
    }

    if (Get-Command Initialize-TestMocks -ErrorAction SilentlyContinue) {
        Initialize-TestMocks
    }
}

<#
.SYNOPSIS
    Initializes mock functions for test environment.
.DESCRIPTION
    Sets up mock functions for file-opening operations to prevent applications
    from launching during tests. These mocks override functions defined in profile
    fragments and prevent editors, browsers, and other applications from opening.
    Only initializes mocks when PS_PROFILE_TEST_MODE environment variable is set to '1'.
.NOTES
    This function mocks:
    - Open-VSCode
    - Open-Editor
    - Edit-Profile
    - notepad
    - Open-Item
    - Start-Process (when used for opening files)
#>
function Initialize-TestMocks {
    if ($env:PS_PROFILE_TEST_MODE -ne '1') {
        return
    }
    # Mock Open-VSCode to prevent VS Code from opening
    # Use Set-Item to force override even if function already exists
    Set-Item -Path Function:Open-VSCode -Value {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )
        Write-Verbose "Mock: Would open in VS Code: $($Arguments -join ' ')"
    } -Force -ErrorAction SilentlyContinue
    
    # Also create the function normally in case Set-Item didn't work
    function Open-VSCode {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )
        Write-Verbose "Mock: Would open in VS Code: $($Arguments -join ' ')"
    }

    # Mock Get-AvailableEditor FIRST to prevent any editor from being found/invoked
    # This must be done before fragments load, and must override any existing definition
    # The fragment defines this function without a guard, so we need to force override it
    # CRITICAL: This must return null so Open-Editor never finds an editor to execute
    if (Test-Path Function:\Get-AvailableEditor) {
        Remove-Item Function:\Get-AvailableEditor -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path Function:\global:Get-AvailableEditor) {
        Remove-Item Function:\global:Get-AvailableEditor -Force -ErrorAction SilentlyContinue
    }
    
    # Create mock scriptblock that ALWAYS returns null
    $getEditorMock = {
        # ALWAYS return null in test mode - never find any editor
        return $null
    }
    
    # Use Set-Item to force override - this will work even if fragment defines it later
    Set-Item -Path Function:\Get-AvailableEditor -Value $getEditorMock -Force -ErrorAction SilentlyContinue
    
    # Also create as global function to ensure it's available everywhere and can't be overridden
    function global:Get-AvailableEditor {
        # ALWAYS return null in test mode - never find any editor
        return $null
    }
    # Force override in global scope too
    Set-Item -Path Function:\global:Get-AvailableEditor -Value $getEditorMock -Force -ErrorAction SilentlyContinue
    
    # Mock Open-Editor to prevent editors from opening
    # CRITICAL: This must completely prevent any editor execution
    # Remove existing function if it exists
    if (Test-Path Function:\Open-Editor) {
        Remove-Item Function:\Open-Editor -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path Function:\global:Open-Editor) {
        Remove-Item Function:\global:Open-Editor -Force -ErrorAction SilentlyContinue
    }
    
    # Create a mock that NEVER executes any editor commands
    # This mock completely replaces the fragment's Open-Editor and prevents any editor from launching
    $openEditorMock = {
        param($p)
        if (-not $p) { 
            Write-Warning 'Usage: Open-Editor <path>'
            return 
        }
        # Mock: NEVER actually open editor, just log
        # Do NOT call Get-AvailableEditor, do NOT execute any editor commands
        Write-Verbose "Mock: Would open in editor: $p (editor execution prevented in test mode)"
    }
    
    # Use Set-Item to force override - this will work even if fragment defines it later
    Set-Item -Path Function:\Open-Editor -Value $openEditorMock -Force -ErrorAction SilentlyContinue
    
    # Create as global function to ensure it's available everywhere and prevents fragment from creating real one
    function global:Open-Editor {
        param($p)
        if (-not $p) { 
            Write-Warning 'Usage: Open-Editor <path>'
            return 
        }
        # Mock: NEVER actually open editor, just log
        # Do NOT call Get-AvailableEditor, do NOT execute any editor commands
        Write-Verbose "Mock: Would open in editor: $p (editor execution prevented in test mode)"
    }
    # Force override in global scope too
    Set-Item -Path Function:\global:Open-Editor -Value $openEditorMock -Force -ErrorAction SilentlyContinue
    
    # Also mock Open-VSCode to prevent it from opening
    if (Test-Path Function:\Open-VSCode) {
        Remove-Item Function:\Open-VSCode -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path Function:\global:Open-VSCode) {
        Remove-Item Function:\global:Open-VSCode -Force -ErrorAction SilentlyContinue
    }
    function global:Open-VSCode {
        [CmdletBinding()]
        param()
        Write-Verbose "Mock: Would open VS Code in current directory"
    }

    # Mock Edit-Profile to prevent VS Code from opening
    Set-Item -Path Function:Edit-Profile -Value {
        [CmdletBinding()]
        param()
        Write-Verbose "Mock: Would open profile in editor"
    } -Force -ErrorAction SilentlyContinue
    
    function Edit-Profile {
        [CmdletBinding()]
        param()
        Write-Verbose "Mock: Would open profile in editor"
    }

    # Mock notepad to prevent Notepad from opening
    # Store original if it exists (it's usually a cmdlet, not a function)
    $script:OriginalNotepadCmd = Get-Command 'notepad' -ErrorAction SilentlyContinue
    
    # Create a function that shadows the cmdlet
    Set-Item -Path Function:notepad -Value {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )
        Write-Verbose "Mock: Would open in Notepad: $($Arguments -join ' ')"
    } -Force -ErrorAction SilentlyContinue
    
    function notepad {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )
        Write-Verbose "Mock: Would open in Notepad: $($Arguments -join ' ')"
    }

    # Mock Open-Item to prevent file associations from launching
    $openItemMock = {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
            [string[]]$Path
        )
        Write-Verbose "Mock: Would open item: $($Path -join ' ')"
    }
    Set-Item -Path Function:\Open-Item -Value $openItemMock -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:\global:Open-Item -Value $openItemMock -Force -ErrorAction SilentlyContinue

    # Block cross-platform file/URL openers used by profile fragments on Linux/macOS
    $systemOpenerMock = {
        param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
        Write-Verbose "Mock: Blocked system opener with args: $($Arguments -join ' ')"
        return 0
    }
    foreach ($openerCommand in @('xdg-open', 'open', 'gio', 'wslview')) {
        Set-Item -Path "Function:\global:$openerCommand" -Value $systemOpenerMock -Force -ErrorAction SilentlyContinue
    }

    # CRITICAL: Mock common editor commands to prevent them from executing
    # The fragment uses & $editor.Command $p which directly invokes editors like 'code', 'notepad', etc.
    # We need to create function mocks for these commands to intercept direct calls
    $editorCommands = @(
        'code', 'code-insiders', 'codium', 'cursor', 'nvim', 'vim', 'emacs', 'micro', 'nano',
        'notepad++', 'sublime_text', 'atom', 'gedit', 'kate', 'leafpad', 'mousepad', 'xedit', 'notepad'
    )
    
    # Initialize storage for original commands if not already done
    if ($null -eq $script:OriginalEditorCommands) {
        $script:OriginalEditorCommands = @{}
    }
    
    foreach ($cmd in $editorCommands) {
        $cmdName = $cmd
        $mockScript = [scriptblock]::Create(@"
            param([Parameter(ValueFromRemainingArguments = `$true)] `$args)
            Write-Verbose "Mock: Would execute command '$cmdName' with args: `$(`$args -join ' ')"
"@)
        Set-Item -Path "Function:\global:$cmdName" -Value $mockScript -Force -ErrorAction SilentlyContinue
        Set-Item -Path "Function:\$cmdName" -Value $mockScript -Force -ErrorAction SilentlyContinue
    }

    # Block ALL Start-Process calls in test mode. Captures are stored in
    # $global:TestStartProcessCaptures for assertions (see Clear/Get-TestStartProcessCapture).
    $startProcessMock = {
        [CmdletBinding(DefaultParameterSetName = 'FilePath')]
        param(
            [Parameter(Mandatory = $false, Position = 0)]
            [string]$FilePath,

            [Parameter(Mandatory = $false)]
            [string[]]$ArgumentList,

            [Parameter(Mandatory = $false)]
            [System.Diagnostics.ProcessWindowStyle]$WindowStyle,

            [Parameter(Mandatory = $false)]
            [switch]$NoNewWindow,

            [Parameter(Mandatory = $false)]
            [switch]$PassThru,

            [Parameter(Mandatory = $false)]
            [switch]$Wait,

            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$RemainingArguments
        )

        if (-not $global:TestStartProcessCaptures) {
            $global:TestStartProcessCaptures = [System.Collections.Generic.List[hashtable]]::new()
        }

        $null = $global:TestStartProcessCaptures.Add(@{
                FilePath       = $FilePath
                ArgumentList   = @($ArgumentList)
                WindowStyle    = $WindowStyle
                NoNewWindow    = $NoNewWindow.IsPresent
                PassThru       = $PassThru.IsPresent
                Wait           = $Wait.IsPresent
            })

        Write-Verbose "Mock: Blocked Start-Process FilePath='$FilePath' Args='$($ArgumentList -join ' ')'"

        if ($PassThru) {
            return [PSCustomObject]@{
                Id          = 0
                ProcessName = if ($FilePath) { [System.IO.Path]::GetFileNameWithoutExtension($FilePath) } else { 'MockProcess' }
                HasExited   = $true
                ExitCode    = 0
            }
        }
    }

    $global:TestStartProcessMockBlock = $startProcessMock

    Set-Item -Path Function:\global:Start-Process -Value $startProcessMock -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:\Start-Process -Value $startProcessMock -Force -ErrorAction SilentlyContinue

    Clear-TestStartProcessCapture
}

function Clear-TestStartProcessCapture {
    $global:TestStartProcessCaptures = [System.Collections.Generic.List[hashtable]]::new()
}

function Get-TestStartProcessCapture {
    if (-not $global:TestStartProcessCaptures -or $global:TestStartProcessCaptures.Count -eq 0) {
        return $null
    }

    return $global:TestStartProcessCaptures[$global:TestStartProcessCaptures.Count - 1]
}

function Get-TestStartProcessCaptures {
    if (-not $global:TestStartProcessCaptures) {
        return @()
    }

    return ,@($global:TestStartProcessCaptures.ToArray())
}

function Reset-TestStartProcessMock {
    if ($null -eq $global:TestStartProcessMockBlock) {
        Initialize-TestMocks
        return
    }

    Set-Item -Path Function:\global:Start-Process -Value $global:TestStartProcessMockBlock -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:\Start-Process -Value $global:TestStartProcessMockBlock -Force -ErrorAction SilentlyContinue
    Clear-TestStartProcessCapture
}

function Set-TestStartProcessFailure {
    param(
        [string]$Message = 'Process start failed'
    )

    $failureMessage = $Message
    $throwingMock = {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$Unused
        )
        throw $failureMessage
    }.GetNewClosure()

    Set-Item -Path Function:\global:Start-Process -Value $throwingMock -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:\Start-Process -Value $throwingMock -Force -ErrorAction SilentlyContinue
}

function Clear-TestCommandInvocationCapture {
    $global:TestCommandInvocationCaptures = [System.Collections.Generic.List[object[]]]::new()
}

function Get-TestCommandInvocationArgs {
    if (-not $global:TestCommandInvocationCaptures -or $global:TestCommandInvocationCaptures.Count -eq 0) {
        return @()
    }

    return ,@($global:TestCommandInvocationCaptures[$global:TestCommandInvocationCaptures.Count - 1])
}

function Get-TestCommandInvocationArgsFlat {
    $queue = [System.Collections.Generic.Queue[object]]::new()
    foreach ($arg in (Get-TestCommandInvocationArgs)) {
        if ($null -ne $arg) {
            $null = $queue.Enqueue($arg)
        }
    }

    $flatArgs = [System.Collections.Generic.List[object]]::new()
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($null -eq $current) {
            continue
        }

        if ($current -is [System.Array]) {
            foreach ($item in $current) {
                if ($null -ne $item) {
                    $null = $queue.Enqueue($item)
                }
            }
            continue
        }

        $flatArgs.Add($current)
    }

    return $flatArgs.ToArray()
}

function Assert-TestCommandInvokedExactlyOnce {
    $global:TestCommandInvocationCaptures.Count | Should -Be 1
}

function Assert-TestCommandInvocationContains {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Expected
    )

    $argsFlat = @((Get-TestCommandInvocationArgsFlat))
    foreach ($item in $Expected) {
        $argsFlat | Should -Contain $item
    }
}

function Setup-CapturingCommandMock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [int]$ExitCode = 0,

        [object]$Output = '',

        [scriptblock]$OnInvoke,

        [bool]$MarkAvailable = $true
    )

    Clear-TestCommandInvocationCapture

    if ($MarkAvailable) {
        Set-TestCommandAvailabilityState -CommandName $CommandName -Available $true
    }

    if (-not (Get-Variable -Name 'TestRegisteredMockCommands' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestRegisteredMockCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    [void]$global:TestRegisteredMockCommands.Add($CommandName)

    $global:TestCommandCaptureState = @{
        ExitCode = $ExitCode
        Output   = $Output
        OnInvoke = $OnInvoke
    }

    $capturingStub = {
        $invocationArgs = @($args)
        $flatArgs = [System.Collections.Generic.List[object]]::new()
        foreach ($arg in $invocationArgs) {
            if ($arg -is [System.Array]) {
                foreach ($nestedArg in $arg) {
                    $flatArgs.Add($nestedArg)
                }
            }
            else {
                $flatArgs.Add($arg)
            }
        }

        if (-not $global:TestCommandInvocationCaptures) {
            $global:TestCommandInvocationCaptures = [System.Collections.Generic.List[object[]]]::new()
        }

        $null = $global:TestCommandInvocationCaptures.Add($flatArgs.ToArray())

        $captureState = $global:TestCommandCaptureState
        $invokeOutput = $null
        if ($null -ne $captureState -and $captureState.ContainsKey('OnInvoke') -and $null -ne $captureState['OnInvoke']) {
            $invokeOutput = & $captureState['OnInvoke'] @invocationArgs
        }

        $exitCode = if ($null -ne $captureState -and $captureState.ContainsKey('ExitCode')) { [int]$captureState['ExitCode'] } else { 0 }
        Set-Variable -Name LASTEXITCODE -Value $exitCode -Scope Global -Force

        if ($null -ne $captureState -and $captureState.ContainsKey('Output') -and $null -ne $captureState['Output'] -and "$($captureState['Output'])" -ne '') {
            $outputValue = $captureState['Output']
            if ($outputValue -is [System.Array]) {
                foreach ($line in $outputValue) {
                    Write-Output $line
                }
            }
            else {
                Write-Output $outputValue
            }
        }
        elseif ($null -ne $invokeOutput) {
            Write-Output $invokeOutput
        }
    }

    Set-Item -Path "Function:\global:$CommandName" -Value $capturingStub -Force -ErrorAction SilentlyContinue
    Set-Item -Path "Function:\$CommandName" -Value $capturingStub -Force -ErrorAction SilentlyContinue
}

function Set-TestCommandThrowingMock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "$CommandName`: command failed"
    }

    Set-TestCommandAvailabilityState -CommandName $CommandName -Available $true

    $escapedMessage = $Message.Replace("'", "''")
    $throwingStub = [scriptblock]::Create(@"
        param([Parameter(ValueFromRemainingArguments = `$true)][object[]]`$Arguments)
        throw [System.Management.Automation.CommandNotFoundException]::new('$escapedMessage')
"@)

    Set-Item -Path "Function:\global:$CommandName" -Value $throwingStub -Force -ErrorAction SilentlyContinue
    Set-Item -Path "Function:\$CommandName" -Value $throwingStub -Force -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Clears fragment idempotency globals so profile fragments reload between test files.
#>
function Clear-AllFragmentLoadedState {
    foreach ($variable in Get-Variable -Scope Global) {
        if ($variable.Name -like '*Loaded') {
            Remove-Variable -Name $variable.Name -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Pre-initializes profile globals that break under Set-StrictMode when unset.
#>
function Initialize-TestProfileGlobals {
    if (-not (Get-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -ErrorAction SilentlyContinue)) {
        Set-Variable -Name 'PSProfileBootstrapInitialized' -Scope Global -Value $false -Force
    }

    if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
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
}

<#
.SYNOPSIS
    Restores TestSupport helper functions overwritten during Pester discovery.
#>
function Restore-TestSupportFunctions {
    $coreFunctionsPath = Join-Path $PSScriptRoot 'TestSupportCoreFunctions.ps1'
    if (Test-Path -LiteralPath $coreFunctionsPath) {
        . $coreFunctionsPath
    }

    $testCommandAvailabilityPath = Join-Path $PSScriptRoot 'TestCommandAvailability.ps1'
    if (Test-Path -LiteralPath $testCommandAvailabilityPath) {
        . $testCommandAvailabilityPath
    }
}

<#
.SYNOPSIS
    Removes known transient files left in the repository root by tests.
#>
function Clear-TestRepoRootSpillover {
    param(
        [string]$StartPath = $PSScriptRoot
    )

    if ($env:PS_PROFILE_SKIP_TEST_CLEANUP -eq '1') {
        return
    }

    $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    $artifactsToRemove = @(
        '0'
        '2'
        '5'
        'backup.dump'
        'backup.tar.gz'
        'custom-backup.dump'
        'backup.sql'
        'backup.sql.gz'
        'output.mkv'
        'render.png'
        'scene.blend'
        'test-volume-backup.tar.gz'
        'test-results.xml'
        'results.xml'
        'test-requirements.txt'
        'test-scoopfile.json'
        'test-npm-global.json'
        'test-npm-global-empty.json'
        'test-winget-packages.json'
        'test.txt'
        'test.hurl'
        'test-Brewfile'
        'test-packages.config'
        'cliff.toml'
        'nonexistent.csv'
        'nonexistent.yaml'
        'nonexistent.txt'
        'nonexistent.sql'
        'nonexistent.dump'
        'nonexistent.json'
        'hook-test-spill.txt'
        '-LiteralPath'
    )

    foreach ($artifact in $artifactsToRemove) {
        $artifactPath = Join-Path $repoRoot $artifact
        if (Test-Path -LiteralPath $artifactPath) {
            Remove-Item -LiteralPath $artifactPath -Force -ErrorAction SilentlyContinue
        }
    }

    Get-ChildItem -LiteralPath $repoRoot -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^testdb-\d{14}\.(dump|sql|archive)$' -or
        $_.Name -match '^test-.*\.(json|txt|xml|sql|dump|tar\.gz|hurl|config)$' -or
        $_.Name -match '^hook-test-.*\.txt$'
    } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

    $testWorktreePath = Join-Path $repoRoot 'test-worktree'
    if (Test-Path -LiteralPath $testWorktreePath) {
        Remove-Item -LiteralPath $testWorktreePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Stubs Ensure-DocumentLatexEngine so document conversion tests avoid LaTeX engine probes.
#>
function Set-TestDocumentLatexEngineStub {
    [CmdletBinding()]
    param(
        [string]$Engine = 'pdflatex'
    )

    if (-not $script:TestDocumentLatexEngineWasStubbed) {
        $existing = Get-Command Ensure-DocumentLatexEngine -ErrorAction SilentlyContinue
        if ($existing -and $existing.CommandType -eq 'Function') {
            $script:TestDocumentLatexEngineOriginal = $existing.ScriptBlock
        }
        $script:TestDocumentLatexEngineWasStubbed = $true
    }

    $stub = [scriptblock]::Create("return '$Engine'")
    Set-Item -Path 'Function:\global:Ensure-DocumentLatexEngine' -Value $stub -Force -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Restores Ensure-DocumentLatexEngine after document conversion test stubs.
#>
function Clear-TestDocumentLatexEngineStub {
    if (-not $script:TestDocumentLatexEngineWasStubbed) {
        return
    }

    Remove-Item -Path 'Function:\Ensure-DocumentLatexEngine' -Force -ErrorAction SilentlyContinue
    Remove-Item -Path 'Function:\global:Ensure-DocumentLatexEngine' -Force -ErrorAction SilentlyContinue

    if ($script:TestDocumentLatexEngineOriginal) {
        Set-Item -Path 'Function:\global:Ensure-DocumentLatexEngine' -Value $script:TestDocumentLatexEngineOriginal -Force -ErrorAction SilentlyContinue
    }

    $script:TestDocumentLatexEngineOriginal = $null
    $script:TestDocumentLatexEngineWasStubbed = $false
}

<#
.SYNOPSIS
    Configures stub-based mocks for document conversion integration tests.
.DESCRIPTION
    Marks pandoc/LaTeX tools unavailable and stubs Ensure-DocumentLatexEngine without
    Pester Mock Get-Command, which breaks batch runs and fragment dot-sourcing.
#>
function Initialize-DocumentConversionTestStubs {
    [CmdletBinding()]
    param(
        [string[]]$UnavailableCommands = @('pandoc', 'pdflatex', 'xelatex', 'luatex'),

        [string]$LatexEngine = 'pdflatex'
    )

    if (Get-Command Clear-TestCommandInvocationCapture -ErrorAction SilentlyContinue) {
        Clear-TestCommandInvocationCapture
    }

    foreach ($cmd in $UnavailableCommands) {
        Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
    }

    Set-TestDocumentLatexEngineStub -Engine $LatexEngine
}

<#
.SYNOPSIS
    Clears document conversion test stubs.
#>
function Clear-DocumentConversionTestStubs {
    Clear-TestDocumentLatexEngineStub
}

<#
.SYNOPSIS
    Removes test artifacts from project root.
.DESCRIPTION
    Cleans up registered test-data paths and any files accidentally created in the
    repository root by tests that used relative output paths.
#>
function Remove-TestArtifacts {
    try {
        if (Get-Command Clear-RegisteredTestCleanupPaths -ErrorAction SilentlyContinue) {
            Clear-RegisteredTestCleanupPaths
        }

        if (Get-Command Clear-TestRepoRootSpillover -ErrorAction SilentlyContinue) {
            Clear-TestRepoRootSpillover -StartPath $PSScriptRoot
        }

        # Note: Get-TestRepoRoot should be available from TestSupport.ps1 loading TestPaths.ps1 first
        $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot

        # Remove legacy test fixture location if present
        $legacyFixtureRoot = Join-Path $repoRoot (Join-Path 'scripts' '.test-fixtures')
        if (Test-Path -LiteralPath $legacyFixtureRoot) {
            Remove-Item -LiteralPath $legacyFixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Remove legacy performance report written at repository root
        $legacyRegressionReport = Join-Path $repoRoot 'performance-regression-report.txt'
        if (Test-Path -LiteralPath $legacyRegressionReport) {
            Remove-Item -LiteralPath $legacyRegressionReport -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Ignore errors during cleanup
    }
}

# Suppress starship errors in test environment by setting TERM if not already set or if set to 'dumb'
# Note: This must be set before any starship commands run
if (-not $env:TERM -or $env:TERM -eq 'dumb') {
    $env:TERM = 'xterm-256color'
}

