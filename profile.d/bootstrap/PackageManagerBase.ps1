# ===============================================
# PackageManagerBase.ps1
# Base module for package manager wrappers
# ===============================================

<#
.SYNOPSIS
    Base module providing common patterns for package manager CLI wrappers.

.DESCRIPTION
    Extracts common patterns from package manager modules (npm, yarn, pip, cargo, etc.) to reduce duplication.
    Provides abstract functions that package manager-specific modules can use or extend.
    
    Common Patterns:
    1. Install/uninstall packages
    2. List packages
    3. Update packages
    4. Run scripts
    5. Manage lock files
    6. Version management

.NOTES
    This is a base module. Package manager-specific modules (npm.ps1, pip.ps1, cargo.ps1, etc.)
    should use these functions or extend them with manager-specific logic.
#>

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'package-manager-base') { return }
    }

    # ===============================================
    # Register-PackageManager - Main registration function
    # ===============================================

    <#
    .SYNOPSIS
        Registers a package manager with standardized commands.
    
    .DESCRIPTION
        Creates a standardized set of functions for a package manager.
        Handles install, uninstall, list, update, and run commands.
    
    .PARAMETER ManagerName
        Name of the package manager (e.g., 'Npm', 'Pip', 'Cargo').
    
    .PARAMETER CommandName
        Name of the CLI command (e.g., 'npm', 'pip', 'cargo').
    
    .PARAMETER InstallCommand
        Command for installing packages (default: 'install').
    
    .PARAMETER UninstallCommand
        Command for uninstalling packages (default: 'uninstall').
    
    .PARAMETER ListCommand
        Command for listing packages (default: 'list').
    
    .PARAMETER UpdateCommand
        Command for updating packages (default: 'update').
    
    .PARAMETER RunCommand
        Command for running scripts (default: 'run').
    
    .PARAMETER LockFile
        Optional lock file name (e.g., 'package-lock.json', 'Cargo.lock').
    
    .PARAMETER GlobalFlag
        Flag for global installs (e.g., '-g' for npm, '--user' for pip).
    
    .PARAMETER CustomCommands
        Hashtable of custom command names to script blocks.
    
    .EXAMPLE
        Register-PackageManager -ManagerName 'Npm' -CommandName 'npm' `
            -InstallCommand 'install' -GlobalFlag '-g' -LockFile 'package-lock.json'
        
        Registers npm package manager with standard commands.
    
    .OUTPUTS
        System.Boolean. True if registration successful, false otherwise.
    #>
    function Register-PackageManager {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ManagerName,

            [Parameter(Mandatory = $true)]
            [string]$CommandName,

            [string]$InstallCommand = 'install',

            [string]$UninstallCommand = 'uninstall',

            [string]$ListCommand = 'list',

            [string]$UpdateCommand = 'update',

            [string]$RunCommand = 'run',

            [string]$LockFile = $null,

            [string]$GlobalFlag = $null,

            [hashtable]$CustomCommands = @{}
        )

        if ([string]::IsNullOrWhiteSpace($ManagerName) -or [string]::IsNullOrWhiteSpace($CommandName)) {
            return $false
        }

        # Capture variables for closures
        $captured = @{
            CommandName      = $CommandName
            ManagerName      = $ManagerName
            InstallCommand   = $InstallCommand
            UninstallCommand = $UninstallCommand
            ListCommand      = $ListCommand
            UpdateCommand    = $UpdateCommand
            RunCommand       = $RunCommand
            GlobalFlag       = $GlobalFlag
        }

        # Register base wrapper
        if (Get-Command Register-ToolWrapper -ErrorAction SilentlyContinue) {
            Register-ToolWrapper -FunctionName "Invoke-$ManagerName" -CommandName $CommandName `
                -InstallHint "Install $ManagerName package manager"
        }

        # Register install command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $installBody = {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Packages,
                    [switch]$Global
                )
                if (Test-CachedCommand $captured.CommandName) {
                    $args = @($captured.InstallCommand)
                    if ($Global -and $captured.GlobalFlag) {
                        $args += $captured.GlobalFlag
                    }
                    & $captured.CommandName @args @Packages
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.ManagerName) package manager"
                }
            }
            Register-FragmentFunction -Name "Install-${ManagerName}Package" -Body $installBody
        }

        # Register uninstall command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $uninstallBody = {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Packages,
                    [switch]$Global
                )
                if (Test-CachedCommand $captured.CommandName) {
                    $args = @($captured.UninstallCommand)
                    if ($Global -and $captured.GlobalFlag) {
                        $args += $captured.GlobalFlag
                    }
                    & $captured.CommandName @args @Packages
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.ManagerName) package manager"
                }
            }
            Register-FragmentFunction -Name "Remove-${ManagerName}Package" -Body $uninstallBody
        }

        # Register list command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $listBody = {
                param(
                    [switch]$Global
                )
                if (Test-CachedCommand $captured.CommandName) {
                    $args = @($captured.ListCommand)
                    if ($Global -and $captured.GlobalFlag) {
                        $args += $captured.GlobalFlag
                    }
                    & $captured.CommandName @args
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.ManagerName) package manager"
                }
            }
            Register-FragmentFunction -Name "Get-${ManagerName}Packages" -Body $listBody
        }

        # Register update command
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $updateBody = {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Packages
                )
                if (Test-CachedCommand $captured.CommandName) {
                    $args = @($captured.UpdateCommand)
                    if ($Packages.Count -eq 0) {
                        # Update all packages
                        $args += '--all'
                    }
                    & $captured.CommandName @args @Packages
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.ManagerName) package manager"
                }
            }
            Register-FragmentFunction -Name "Update-${ManagerName}Packages" -Body $updateBody
        }

        # Register run command (for script execution)
        if (Get-Command Register-FragmentFunction -ErrorAction SilentlyContinue) {
            $runBody = {
                param(
                    [Parameter(Mandatory, Position = 0)]
                    [string]$ScriptName,
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Arguments
                )
                if (Test-CachedCommand $captured.CommandName) {
                    & $captured.CommandName $captured.RunCommand $ScriptName @Arguments
                }
                else {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint "Install $($captured.ManagerName) package manager"
                }
            }
            Register-FragmentFunction -Name "Invoke-${ManagerName}Script" -Body $runBody
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
        Set-AgentModeFunction -Name 'Register-PackageManager' -Body ${function:Register-PackageManager}
    }
    else {
        Set-Item -Path Function:Register-PackageManager -Value ${function:Register-PackageManager} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'package-manager-base'
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName "package-manager-base.load" -Context @{
            fragment      = 'package-manager-base'
            fragment_type = 'base-module'
        }
    }
    elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
        Handle-FragmentError -ErrorRecord $_ -Context "Fragment: package-manager-base"
    }
    elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: package-manager-base" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load package-manager-base fragment: $($_.Exception.Message)"
    }
}
