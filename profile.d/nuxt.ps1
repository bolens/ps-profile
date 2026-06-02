# ===============================================
# nuxt.ps1
# Nuxt.js development helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Nuxt.js development helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Nuxt.js operations.
    Functions check for npx/nuxi availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Nuxt
    Author: PowerShell Profile
#>

# Nuxt execute - run nuxi with arguments
<#
.SYNOPSIS
    Executes Nuxt CLI (nuxi) commands.

.DESCRIPTION
    Wrapper function for Nuxt CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to nuxi.

.EXAMPLE
    Invoke-Nuxt --version

.EXAMPLE
    Invoke-Nuxt init my-app
#>
function Invoke-Nuxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand nuxi) {
        npx nuxi @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'nuxi' -ToolType 'node-package'
    }
}

# Nuxt dev server - start development server
<#
.SYNOPSIS
    Starts Nuxt.js development server.

.DESCRIPTION
    Wrapper for npx nuxi dev command.

.PARAMETER Arguments
    Arguments to pass to nuxi dev.

.EXAMPLE
    Start-NuxtDev

.EXAMPLE
    Start-NuxtDev --port 3000
#>
function Start-NuxtDev {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx nuxi dev @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Nuxt build - create production build
<#
.SYNOPSIS
    Builds Nuxt.js application for production.

.DESCRIPTION
    Wrapper for npx nuxi build command.

.PARAMETER Arguments
    Arguments to pass to nuxi build.

.EXAMPLE
    Build-NuxtApp

.EXAMPLE
    Build-NuxtApp --prerender
#>
function Build-NuxtApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx nuxi build @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Create Nuxt app - scaffold new Nuxt.js project
<#
.SYNOPSIS
    Creates a new Nuxt.js application.

.DESCRIPTION
    Wrapper for npx nuxi@latest init command.

.PARAMETER Arguments
    Arguments to pass to nuxi init.

.EXAMPLE
    New-NuxtApp my-app

.EXAMPLE
    New-NuxtApp my-app --package-manager pnpm
#>
function New-NuxtApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx nuxi@latest init @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Create aliases for short forms
Set-AgentModeAlias -Name 'nuxi' -Target 'Invoke-Nuxt'
Set-AgentModeAlias -Name 'nuxt-dev' -Target 'Start-NuxtDev'
Set-AgentModeAlias -Name 'nuxt-build' -Target 'Build-NuxtApp'
Set-AgentModeAlias -Name 'create-nuxt-app' -Target 'New-NuxtApp'
