# ===============================================
# vite.ps1
# Vite build tool helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Vite build tool helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Vite operations.
    Functions check for vite/npx availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Vite
    Author: PowerShell Profile
#>

# Vite execute - run vite with arguments
<#
.SYNOPSIS
    Executes Vite commands.

.DESCRIPTION
    Wrapper function for Vite CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to vite.

.EXAMPLE
    Invoke-Vite --version

.EXAMPLE
    Invoke-Vite build
#>
function Invoke-Vite {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand vite) {
        npx vite @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'vite' -InstallHint 'Install with: npm install -g vite'
    }
}

# Create Vite project - scaffold new Vite project
<#
.SYNOPSIS
    Creates a new Vite project.

.DESCRIPTION
    Wrapper for npx create-vite command.

.PARAMETER Arguments
    Arguments to pass to create-vite.

.EXAMPLE
    New-ViteProject my-app

.EXAMPLE
    New-ViteProject my-app --template react-ts
#>
function New-ViteProject {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx create-vite @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'npx' -InstallHint 'Install with: npm install -g npm'
    }
}

# Vite dev server - start development server
<#
.SYNOPSIS
    Starts Vite development server.

.DESCRIPTION
    Wrapper for npx vite dev command.

.PARAMETER Arguments
    Arguments to pass to vite dev.

.EXAMPLE
    Start-ViteDev

.EXAMPLE
    Start-ViteDev --port 3000
#>
function Start-ViteDev {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx vite dev @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'npx' -InstallHint 'Install with: npm install -g npm'
    }
}

# Vite build - create production build
<#
.SYNOPSIS
    Builds Vite application for production.

.DESCRIPTION
    Wrapper for npx vite build command.

.PARAMETER Arguments
    Arguments to pass to vite build.

.EXAMPLE
    Build-ViteApp

.EXAMPLE
    Build-ViteApp --mode production
#>
function Build-ViteApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx vite build @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'npx' -InstallHint 'Install with: npm install -g npm'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'vite' -Target 'Invoke-Vite'
    Set-AgentModeAlias -Name 'create-vite' -Target 'New-ViteProject'
    Set-AgentModeAlias -Name 'vite-dev' -Target 'Start-ViteDev'
    Set-AgentModeAlias -Name 'vite-build' -Target 'Build-ViteApp'
}
else {
    Set-Alias -Name 'vite' -Value 'Invoke-Vite' -ErrorAction SilentlyContinue
    Set-Alias -Name 'create-vite' -Value 'New-ViteProject' -ErrorAction SilentlyContinue
    Set-Alias -Name 'vite-dev' -Value 'Start-ViteDev' -ErrorAction SilentlyContinue
    Set-Alias -Name 'vite-build' -Value 'Build-ViteApp' -ErrorAction SilentlyContinue
}
