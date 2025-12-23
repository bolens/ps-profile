# ===============================================
# TestMocks.ps1
# Mock functions for test environment
# ===============================================

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
    Set-Item -Path Function:Open-Item -Value {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
            [string[]]$Path
        )
        Write-Verbose "Mock: Would open item: $($Path -join ' ')"
    } -Force -ErrorAction SilentlyContinue
    
    function Open-Item {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
            [string[]]$Path
        )
        Write-Verbose "Mock: Would open item: $($Path -join ' ')"
    }

    # CRITICAL: Mock common editor commands to prevent them from executing
    # The fragment uses & $editor.Command $p which directly invokes editors like 'code', 'notepad', etc.
    # We need to create function mocks for these commands to intercept direct calls
    $editorCommands = @('code', 'code-insiders', 'codium', 'nvim', 'vim', 'emacs', 'micro', 'nano', 'notepad++', 'sublime_text', 'atom', 'gedit', 'kate', 'leafpad', 'mousepad', 'xedit', 'notepad')
    
    # Initialize storage for original commands if not already done
    if (-not $script:OriginalEditorCommands) {
        $script:OriginalEditorCommands = @{}
    }
    
    foreach ($cmd in $editorCommands) {
        $originalCmd = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($originalCmd) {
            # Store original command
            if (-not $script:OriginalEditorCommands.ContainsKey($cmd)) {
                $script:OriginalEditorCommands[$cmd] = $originalCmd
            }
            
            # Create function mock that shadows the command
            # Use a scriptblock that captures the command name properly
            $cmdName = $cmd  # Capture in local variable for closure
            $mockScript = [scriptblock]::Create(@"
                param([Parameter(ValueFromRemainingArguments = `$true)] `$args)
                Write-Verbose "Mock: Would execute editor command '$cmdName' with args: `$(`$args -join ' ')"
"@)
            Set-Item -Path "Function:\$cmd" -Value $mockScript -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Mock Start-Process when used for opening files (but allow other uses)
    # We'll create a wrapper that checks if it's being used to open files
    $originalStartProcess = Get-Command 'Start-Process' -ErrorAction SilentlyContinue
    if ($originalStartProcess) {
        # Store original in a script-scoped variable
        $script:OriginalStartProcess = $originalStartProcess
        
        function Start-Process {
            [CmdletBinding()]
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
            
            # Check if this looks like opening a file/URL (common patterns)
            $isFileOpen = $false
            if ($FilePath) {
                $filePathLower = $FilePath.ToLower()
                # Check for common editor/opener executables
                $editorPatterns = @('code.exe', 'code', 'notepad', 'notepad++.exe', 'vscode', 'cursor')
                foreach ($pattern in $editorPatterns) {
                    if ($filePathLower -like "*$pattern*") {
                        $isFileOpen = $true
                        break
                    }
                }
                
                # Check if FilePath is a file path (not an executable)
                if (-not $isFileOpen -and (Test-Path $FilePath -PathType Leaf -ErrorAction SilentlyContinue)) {
                    $isFileOpen = $true
                }
            }
            
            if ($isFileOpen) {
                Write-Verbose "Mock: Would start process to open file: $FilePath $($ArgumentList -join ' ')"
                if ($PassThru) {
                    # Return a mock process object
                    return [PSCustomObject]@{
                        Id          = 0
                        ProcessName = 'MockProcess'
                        HasExited   = $true
                        ExitCode    = 0
                    }
                }
                return
            }
            
            # For non-file-opening uses, call the original Start-Process
            $params = @{}
            if ($PSBoundParameters.ContainsKey('FilePath')) { $params['FilePath'] = $FilePath }
            if ($PSBoundParameters.ContainsKey('ArgumentList')) { $params['ArgumentList'] = $ArgumentList }
            if ($PSBoundParameters.ContainsKey('WindowStyle')) { $params['WindowStyle'] = $WindowStyle }
            if ($PSBoundParameters.ContainsKey('NoNewWindow')) { $params['NoNewWindow'] = $NoNewWindow }
            if ($PSBoundParameters.ContainsKey('PassThru')) { $params['PassThru'] = $PassThru }
            if ($PSBoundParameters.ContainsKey('Wait')) { $params['Wait'] = $Wait }
            if ($RemainingArguments) { $params['RemainingArguments'] = $RemainingArguments }
            
            & $script:OriginalStartProcess @params
        }
    }
}

<#
.SYNOPSIS
    Removes test artifacts from project root.
.DESCRIPTION
    Cleans up temporary files and directories created during tests that may have been
    left in the project root directory.
#>
function Remove-TestArtifacts {
    try {
        # Note: Get-TestRepoRoot should be available from TestSupport.ps1 loading TestPaths.ps1 first
        $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $artifactsToRemove = @('0', '2', '5', 'nonexistent.csv', 'nonexistent.yaml', 'nonexistent.txt')
        foreach ($artifact in $artifactsToRemove) {
            $artifactPath = Join-Path $repoRoot $artifact
            if (Test-Path $artifactPath) {
                Remove-Item $artifactPath -Force -ErrorAction SilentlyContinue
            }
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

