<#
.SYNOPSIS
    Locates the repository root directory for the tests.
.DESCRIPTION
    Walks up from the supplied start path until it finds a .git folder and returns that directory.
.PARAMETER StartPath
    The path to begin searching from; defaults to the calling script root.
.OUTPUTS
    System.String
#>
function Get-TestRepoRoot {
    param(
        [Parameter()]
        [string]$StartPath = $PSScriptRoot
    )

    $current = Get-Item -LiteralPath $StartPath
    while ($null -ne $current) {
        if (Test-Path -LiteralPath (Join-Path $current.FullName '.git')) {
            return $current.FullName
        }
        $current = $current.Parent
    }

    throw "Unable to locate repository root starting from $StartPath"
}

<#
.SYNOPSIS
    Resolves a path relative to the repository root.
.DESCRIPTION
    Combines the repository root with the provided relative path and optionally validates existence.
.PARAMETER RelativePath
    The path relative to the repository root to resolve.
.PARAMETER StartPath
    Optional path used to locate the repository root when different from the current script.
.PARAMETER EnsureExists
    When set, throws if the resolved path does not exist.
.OUTPUTS
    System.String
#>
function Get-TestPath {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [string]$StartPath = $PSScriptRoot,

        [switch]$EnsureExists
    )

    $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    $fullPath = Join-Path $repoRoot $RelativePath

    if ($EnsureExists -and -not (Test-Path -LiteralPath $fullPath)) {
        throw "Resolved test path does not exist: $fullPath"
    }

    return $fullPath
}

<#
.SYNOPSIS
    Returns the path to a test suite directory.
.DESCRIPTION
    Resolves the absolute path for the unit, integration, or performance test suite folders.
.PARAMETER Suite
    The name of the suite to resolve; must be Unit, Integration, or Performance.
.PARAMETER StartPath
    Optional start path used to determine the repository root.
.PARAMETER EnsureExists
    When supplied, validates that the suite path exists on disk.
.OUTPUTS
    System.String
#>
function Get-TestSuitePath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Unit', 'Integration', 'Performance')]
        [string]$Suite,

        [string]$StartPath = $PSScriptRoot,

        [switch]$EnsureExists
    )

    $relative = Join-Path 'tests' ($Suite.ToLower())
    return Get-TestPath -RelativePath $relative -StartPath $StartPath -EnsureExists:$EnsureExists
}

<#
.SYNOPSIS
    Enumerates test files for a given suite.
.DESCRIPTION
    Retrieves all *.tests.ps1 files under the requested suite directory, sorted by full path.
.PARAMETER Suite
    The target suite to enumerate; must be Unit, Integration, or Performance.
.PARAMETER StartPath
    Optional start path used to determine the repository root.
.OUTPUTS
    System.IO.FileInfo
#>
function Get-TestSuiteFiles {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Unit', 'Integration', 'Performance')]
        [string]$Suite,

        [string]$StartPath = $PSScriptRoot
    )

    $suitePath = Get-TestSuitePath -Suite $Suite -StartPath $StartPath -EnsureExists
    $scripts = Get-ChildItem -LiteralPath $suitePath -Filter '*.tests.ps1' -File -Recurse | Sort-Object FullName
    return $scripts
}


<#
.SYNOPSIS
    Creates a temporary directory for tests.
.DESCRIPTION
    Generates a unique directory in the system temp path using the provided prefix and returns its path.
.PARAMETER Prefix
    Text used at the start of the generated directory name.
.OUTPUTS
    System.String
#>
function New-TestTempDirectory {
    param(
        [string]$Prefix = 'PesterTest'
    )

    # Use test-data directory instead of system temp to keep all test artifacts together
    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $testDataRoot = Join-Path $repoRoot 'tests' 'test-data'
    
    # Ensure test-data directory exists
    if (-not (Test-Path $testDataRoot)) {
        New-Item -ItemType Directory -Path $testDataRoot -Force | Out-Null
    }
    
    $uniqueName = '{0}-{1}' -f $Prefix, ([System.Guid]::NewGuid().ToString())
    $path = Join-Path $testDataRoot $uniqueName
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

<#
.SYNOPSIS
    Executes transient PowerShell script content in a separate process.
.DESCRIPTION
    Writes the supplied script content to a temp file, runs it with pwsh, captures output, and cleans up the file.
.PARAMETER ScriptContent
    The PowerShell code to execute.
.OUTPUTS
    System.Object
#>
function Invoke-TestPwshScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent
    )

    # Use test-data directory instead of system temp
    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $testDataRoot = Join-Path $repoRoot 'tests' 'test-data'
    
    # Ensure test-data directory exists
    if (-not (Test-Path $testDataRoot)) {
        try {
            New-Item -ItemType Directory -Path $testDataRoot -Force | Out-Null
        }
        catch {
            throw "Failed to create test-data directory '$testDataRoot': $($_.Exception.Message)"
        }
    }
    
    $tempFile = Join-Path $testDataRoot ([System.IO.Path]::GetRandomFileName() + '.ps1')
    
    try {
        Set-Content -Path $tempFile -Value $ScriptContent -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        throw "Failed to write temporary test script to '$tempFile': $($_.Exception.Message)"
    }

    try {
        if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            throw "pwsh command not found. PowerShell Core must be installed to use this function."
        }
        
        $output = & pwsh -NoProfile -File $tempFile 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -ne 0) {
            $errorMessage = if ($output) { $output -join "`n" } else { "Unknown error" }
            throw "Test script failed with exit code $exitCode : $errorMessage"
        }
        
        return $output
    }
    catch {
        Write-Error "Failed to execute test script '$tempFile': $($_.Exception.Message)"
        throw
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Resolves a performance threshold from an environment variable.
.DESCRIPTION
    Returns the integer stored in the specified environment variable when valid, otherwise the provided default.
.PARAMETER EnvironmentVariable
    Name of the environment variable that may override the default threshold.
.PARAMETER Default
    Fallback value used when no override is present or valid.
.OUTPUTS
    System.Int32
#>
function Get-PerformanceThreshold {
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentVariable,

        [Parameter(Mandatory)]
        [int]$Default
    )

    $rawValue = [Environment]::GetEnvironmentVariable($EnvironmentVariable)

    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return $Default
    }

    $parsed = 0
    if ([int]::TryParse($rawValue, [ref]$parsed) -and $parsed -gt 0) {
        return $parsed
    }

    return $Default
}

<#
.SYNOPSIS
    Checks if an npm package is available for use.
.DESCRIPTION
    Tests whether a specified npm package can be required by Node.js.
    Handles both npm and pnpm global package installations by checking
    pnpm's global directory and setting NODE_PATH appropriately.
.PARAMETER PackageName
    The name of the npm package to check (e.g., 'superjson', '@msgpack/msgpack').
.EXAMPLE
    Test-NpmPackageAvailable -PackageName 'superjson'
    Checks if the superjson package is available.
.OUTPUTS
    System.Boolean
    Returns $true if the package is available, $false otherwise.
.NOTES
    This function is used by test files to determine if npm packages are installed
    before running tests that depend on them. It automatically detects pnpm global
    installations and configures Node.js to find packages in pnpm's global directory.
#>
function Test-NpmPackageAvailable {
    param([string]$PackageName)
    
    # Get pnpm global path if available
    $pnpmGlobalPath = $null
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try {
            $pnpmRootOutput = pnpm root -g 2>&1
            $pnpmRoot = $pnpmRootOutput | Where-Object { $_ -and -not ($_ -match 'error|not found|WARN') } | Select-Object -First 1
            if ($pnpmRoot) {
                $pnpmGlobalPath = $pnpmRoot.ToString().Trim()
            }
        }
        catch {
            # Fall through to try common location
        }
    }
    
    # If pnpm global path not found, try common location
    if (-not $pnpmGlobalPath) {
        $commonPnpmPath = "$env:LOCALAPPDATA\pnpm\global\5\node_modules"
        if (Test-Path $commonPnpmPath) {
            $pnpmGlobalPath = $commonPnpmPath
        }
    }
    
    # Build check script
    $checkScript = @"
try {
    require('$PackageName');
    console.log('available');
} catch (e) {
    console.log('not available');
}
"@
    
    $tempCheck = Join-Path $env:TEMP "npm-check-$(Get-Random).js"
    Set-Content -Path $tempCheck -Value $checkScript -Encoding UTF8
    try {
        # Set NODE_PATH to include pnpm global if available
        $env:NODE_PATH = if ($pnpmGlobalPath) { $pnpmGlobalPath } else { $env:NODE_PATH }
        $result = & node $tempCheck 2>&1 | Where-Object { $_ -match 'available|not available' } | Select-Object -First 1
        return ($result -eq 'available')
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
        if ($pnpmGlobalPath) { Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue }
    }
}

# Provide default assumed commands for optional tooling during tests to avoid noisy warnings
if (-not (Get-Variable -Name 'TestSupportDefaultAssumedCommandsSet' -Scope Script -ErrorAction SilentlyContinue)) {
    $script:TestSupportDefaultAssumedCommandsSet = $true

    $defaultAssumedCommands = @('scoop', 'uv', 'pnpm', 'eza', 'navi', 'btm', 'bottom', 'procs', 'dust', 'pixi')
    $existingAssumedCommands = @()

    if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_ASSUME_COMMANDS)) {
        $existingAssumedCommands = $env:PS_PROFILE_ASSUME_COMMANDS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    $combinedAssumedCommands = ($existingAssumedCommands + $defaultAssumedCommands) | Sort-Object -Unique

    if ($combinedAssumedCommands) {
        $env:PS_PROFILE_ASSUME_COMMANDS = [string]::Join(',', $combinedAssumedCommands)
    }

    $defaultSuppressedFragments = @('99-test-*')
    $existingSuppressedFragments = @()

    if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS)) {
        $existingSuppressedFragments = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    $combinedSuppressed = ($existingSuppressedFragments + $defaultSuppressedFragments) | Sort-Object -Unique

    if ($combinedSuppressed) {
        $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = [string]::Join(',', $combinedSuppressed)
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

# Suppress starship errors in test environment by setting TERM if not already set or if set to 'dumb'
# Note: This must be set before any starship commands run
if (-not $env:TERM -or $env:TERM -eq 'dumb') {
    $env:TERM = 'xterm-256color'
}

# Auto-initialize mocks if test mode is already set when TestSupport.ps1 loads
if ($env:PS_PROFILE_TEST_MODE -eq '1') {
    Initialize-TestMocks
}

# Cleanup function to remove test artifacts from project root
function Remove-TestArtifacts {
    try {
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

# Register cleanup to run after tests
if ($env:PS_PROFILE_TEST_MODE -eq '1') {
    # Clean up any existing artifacts
    Remove-TestArtifacts
}