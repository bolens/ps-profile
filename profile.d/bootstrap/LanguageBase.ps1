# ===============================================
# LanguageBase.ps1
# Base module for language runtime wrappers
# ===============================================

<#
.SYNOPSIS
    Base module providing common patterns for language runtime CLI wrappers.

.DESCRIPTION
    Extracts common patterns from language modules (Go, Rust, Python, Node.js, etc.) to reduce duplication.
    Provides abstract functions that language-specific modules can use or extend.
    
    Common Patterns:
    1. Command execution with tool detection
    2. Version management (version managers: nvm, pyenv, rustup, etc.)
    3. Build commands (build, test, run, install)
    4. Package management (npm, pip, cargo, go mod)
    5. Environment activation (virtualenvs, conda, etc.)

.NOTES
    This is a base module. Language-specific modules (lang-python.ps1, lang-go.ps1, lang-rust.ps1, etc.)
    should use these functions or extend them with language-specific logic.
#>

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'language-base') { return }
    }

    # ===============================================
    # Register-LanguageModule - Main registration function
    # ===============================================

    <#
    .SYNOPSIS
        Registers a language module with standardized commands.
    
    .DESCRIPTION
        Creates a standardized set of functions and aliases for a language runtime.
        Handles version management, build commands, package management, and more.
    
    .PARAMETER LanguageName
        Name of the language (e.g., 'Python', 'Go', 'Rust').
    
    .PARAMETER CommandName
        Name of the CLI command (e.g., 'python', 'go', 'cargo').
    
    .PARAMETER VersionManager
        Optional version manager command name (e.g., 'pyenv', 'nvm', 'rustup').
    
    .PARAMETER BuildCommand
        Command for building projects (default: 'build').
    
    .PARAMETER TestCommand
        Command for running tests (default: 'test').
    
    .PARAMETER RunCommand
        Command for running projects (default: 'run').
    
    .PARAMETER PackageManager
        Optional package manager command name (e.g., 'pip', 'npm', 'cargo').
    
    .PARAMETER CustomCommands
        Hashtable of custom command names to script blocks.
    
    .EXAMPLE
        Register-LanguageModule -LanguageName 'Python' -CommandName 'python' `
            -VersionManager 'pyenv' -PackageManager 'pip' `
            -BuildCommand 'setup.py build' -TestCommand 'pytest'
        
        Registers Python language module with pyenv and pip support.
    
    .OUTPUTS
        System.Boolean. True if registration successful, false otherwise.
    #>
    function Register-LanguageModule {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$LanguageName,

            [Parameter(Mandatory = $true)]
            [string]$CommandName,

            [string]$VersionManager = $null,

            [string]$BuildCommand = 'build',

            [string]$TestCommand = 'test',

            [string]$RunCommand = 'run',

            [string]$PackageManager = $null,

            [hashtable]$CustomCommands = @{}
        )

        if ([string]::IsNullOrWhiteSpace($LanguageName) -or [string]::IsNullOrWhiteSpace($CommandName)) {
            return $false
        }

        # Register base wrapper
        if (Get-Command Register-ToolWrapper -ErrorAction SilentlyContinue) {
            Register-ToolWrapper -FunctionName "Invoke-$LanguageName" -CommandName $CommandName `
                -InstallHint "Install $LanguageName runtime"
        }
        else {
            # Fallback: use Set-AgentModeFunction directly
            $capturedWrapper = @{
                CommandName  = $CommandName
                LanguageName = $LanguageName
            }
            if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
                $wrapperBody = {
                    param([Parameter(ValueFromRemainingArguments = $true)] $Arguments)
                    if (Test-CachedCommand $capturedWrapper.CommandName) {
                        & $capturedWrapper.CommandName @Arguments
                    }
                    else {
                        Write-MissingToolWarning -Tool $capturedWrapper.CommandName -InstallHint "Install $($capturedWrapper.LanguageName) runtime"
                    }
                }
                Set-AgentModeFunction -Name "Invoke-$LanguageName" -Body $wrapperBody
            }
        }

        # Register version manager if specified
        if ($VersionManager) {
            if (Get-Command Register-ToolWrapper -ErrorAction SilentlyContinue) {
                Register-ToolWrapper -FunctionName "Invoke-$VersionManager" -CommandName $VersionManager `
                    -InstallHint "Install $VersionManager version manager"
            }
        }

        # Capture variables for closures
        $captured = @{
            CommandName  = $CommandName
            LanguageName = $LanguageName
            BuildCommand = $BuildCommand
            TestCommand  = $TestCommand
            RunCommand   = $RunCommand
        }

        # Capture variables for closures (hashtable pattern like Register-ToolWrapper)
        $captured = @{
            CommandName  = $CommandName
            LanguageName = $LanguageName
            BuildCommand = $BuildCommand
            TestCommand  = $TestCommand
            RunCommand   = $RunCommand
        }

        # Register build command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $buildBody = {
                param([Parameter(ValueFromRemainingArguments = $true)] $Arguments)
                if (Test-CachedCommand $captured.CommandName) {
                    $cmdArgs = if ($captured.BuildCommand -ne 'build') { $captured.BuildCommand -split ' ' } else { @('build') }
                    & $captured.CommandName @cmdArgs @Arguments
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.LanguageName) runtime"
                }
            }
            Register-FragmentFunction -Name "Build-${LanguageName}Project" -Body $buildBody
        }

        # Register test command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $testBody = {
                param([Parameter(ValueFromRemainingArguments = $true)] $Arguments)
                if (Test-CachedCommand $captured.CommandName) {
                    $cmdArgs = if ($captured.TestCommand -ne 'test') { $captured.TestCommand -split ' ' } else { @('test') }
                    & $captured.CommandName @cmdArgs @Arguments
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.LanguageName) runtime"
                }
            }
            Register-FragmentFunction -Name "Test-${LanguageName}Project" -Body $testBody
        }

        # Register run command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $runBody = {
                param([Parameter(ValueFromRemainingArguments = $true)] $Arguments)
                if (Test-CachedCommand $captured.CommandName) {
                    $cmdArgs = if ($captured.RunCommand -ne 'run') { $captured.RunCommand -split ' ' } else { @('run') }
                    & $captured.CommandName @cmdArgs @Arguments
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.LanguageName) runtime"
                }
            }
            Register-FragmentFunction -Name "Run-${LanguageName}Project" -Body $runBody
        }

        # Register package manager if specified
        if ($PackageManager) {
            if (Get-Command Register-ToolWrapper -ErrorAction SilentlyContinue) {
                Register-ToolWrapper -FunctionName "Invoke-$PackageManager" -CommandName $PackageManager `
                    -InstallHint "Install $PackageManager package manager"
            }
        }

        # Register custom commands
        foreach ($cmdName in $CustomCommands.Keys) {
            $cmdBody = $CustomCommands[$cmdName]
            if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
                Register-FragmentFunction -Name $cmdName -Body $cmdBody
            }
            elseif (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
                Set-AgentModeFunction -Name $cmdName -Body $cmdBody
            }
        }

        return $true
    }

    # Register function
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Register-LanguageModule' -Body ${function:Register-LanguageModule}
    }
    else {
        Set-Item -Path Function:Register-LanguageModule -Value ${function:Register-LanguageModule} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'language-base'
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName "language-base.load" -Context @{
            fragment = 'language-base'
            fragment_type = 'base-module'
        }
    }
    elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
        Handle-FragmentError -ErrorRecord $_ -Context "Fragment: language-base"
    }
    elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: language-base" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load language-base fragment: $($_.Exception.Message)"
    }
}
