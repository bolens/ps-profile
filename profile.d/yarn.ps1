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
    Functions check for yarn availability using Test-CachedCommand for efficient
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
        & yarn @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
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
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
    }
}

# Yarn remove - remove packages from dependencies
<#
.SYNOPSIS
    Removes packages from project dependencies.

.DESCRIPTION
    Wrapper for yarn remove command.

.PARAMETER Arguments
    Arguments to pass to yarn remove.

.EXAMPLE
    Remove-YarnPackage express

.EXAMPLE
    Remove-YarnPackage typescript -D
#>
function Remove-YarnPackage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand yarn) {
        & yarn remove @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
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
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
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
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
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
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
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
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
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
        Invoke-MissingToolWarning -ToolName 'yarn' -ToolType 'node-package'
    }
}

# Create aliases for short forms
Set-AgentModeAlias -Name 'yarn' -Target 'Invoke-Yarn'
Set-AgentModeAlias -Name 'yarn-add' -Target 'Add-YarnPackage'
Set-AgentModeAlias -Name 'yarn-remove' -Target 'Remove-YarnPackage'
Set-AgentModeAlias -Name 'yarn-install' -Target 'Install-YarnDependencies'
Set-AgentModeAlias -Name 'yarn-outdated' -Target 'Test-YarnOutdated'
Set-AgentModeAlias -Name 'yarn-upgrade' -Target 'Update-YarnPackages'
Set-AgentModeAlias -Name 'yarn-global-upgrade' -Target 'Update-YarnGlobalPackages'
Set-AgentModeAlias -Name 'yarn-update' -Target 'Update-YarnSelf'
