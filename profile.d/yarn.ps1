# ===============================================
# yarn.ps1
# Yarn package manager helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Yarn package manager helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Yarn operations.
    Functions check for yarn availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Yarn
    Author: PowerShell Profile
#>

# Yarn execute - run yarn with arguments
<#
.SYNOPSIS
    Executes Yarn commands.

.DESCRIPTION
    Wrapper function for Yarn CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to yarn.

.EXAMPLE
    Invoke-Yarn --version

.EXAMPLE
    Invoke-Yarn install
#>
function Invoke-Yarn {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand yarn) {
        & rn @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn add - add packages to dependencies
<#
.SYNOPSIS
    Adds packages to project dependencies.

.DESCRIPTION
    Wrapper for yarn add command.

.PARAMETER Arguments
    Arguments to pass to yarn add.

.EXAMPLE
    Add-YarnPackage express

.EXAMPLE
    Add-YarnPackage -D typescript
#>
function Add-YarnPackage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand yarn) {
        & yarn add @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn install - install project dependencies
<#
.SYNOPSIS
    Installs project dependencies.

.DESCRIPTION
    Wrapper for yarn install command.

.EXAMPLE
    Install-YarnDependencies
#>
function Install-YarnDependencies {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn install
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn outdated - check for outdated packages
<#
.SYNOPSIS
    Checks for outdated packages in the current project.
.DESCRIPTION
    Lists all packages that have newer versions available.
    This is equivalent to running 'yarn outdated'.
.EXAMPLE
    Test-YarnOutdated
    Checks for outdated packages in the current project.
#>
function Test-YarnOutdated {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn outdated
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn upgrade - update all packages
<#
.SYNOPSIS
    Updates all packages in the current project to their latest versions.
.DESCRIPTION
    Updates all packages to their latest versions according to the version ranges
    specified in package.json. This is equivalent to running 'yarn upgrade'.
.EXAMPLE
    Update-YarnPackages
    Updates all packages in the current project.
#>
function Update-YarnPackages {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn global upgrade - update global packages
<#
.SYNOPSIS
    Updates all globally installed Yarn packages to their latest versions.
.DESCRIPTION
    Updates all globally installed packages. This is equivalent to running 'yarn global upgrade'.
.EXAMPLE
    Update-YarnGlobalPackages
    Updates all globally installed Yarn packages.
#>
function Update-YarnGlobalPackages {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn global upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn self-update - update yarn itself
<#
.SYNOPSIS
    Updates Yarn to the latest version.
.DESCRIPTION
    Updates Yarn itself to the latest version using 'yarn set version latest'.
.EXAMPLE
    Update-YarnSelf
    Updates Yarn to the latest version.
#>
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
#>
function Update-YarnPackages {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn global upgrade - update global packages
<#
.SYNOPSIS
    Updates all globally installed Yarn packages to their latest versions.
.DESCRIPTION
    Updates all globally installed packages. This is equivalent to running 'yarn global upgrade'.
.EXAMPLE
    Update-YarnGlobalPackages
    Updates all globally installed Yarn packages.
#>
function Update-YarnGlobalPackages {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn global upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Yarn self-update - update yarn itself
<#
.SYNOPSIS
    Updates Yarn to the latest version.
.DESCRIPTION
    Updates Yarn itself to the latest version using 'yarn set version latest'.
.EXAMPLE
    Update-YarnSelf
    Updates Yarn to the latest version.
#>
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
function Update-YarnSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand yarn) {
        & yarn set version latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'yarn' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install yarn'
        }
        Write-MissingToolWarning -Tool 'yarn' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
    Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
    Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
    Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
    Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
    Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
    Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
}
else {
    Set-Alias -Name 'yarn' -Value 'Invoke-Yarn' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-add' -Value 'Add-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-remove' -Value 'Remove-YarnPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-install' -Value 'Install-YarnDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-outdated' -Value 'Test-YarnOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-upgrade' -Value 'Update-YarnPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-global-upgrade' -Value 'Update-YarnGlobalPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yarn-update' -Value 'Update-YarnSelf' -ErrorAction SilentlyContinue
}
