# ===============================================
# nextjs.ps1
# Next.js development helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Next.js development helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Next.js operations.
    Functions check for npx availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.NextJs
    Author: PowerShell Profile
#>

# Next.js dev server - start development server
<#
.SYNOPSIS
    Starts Next.js development server.

.DESCRIPTION
    Wrapper for npx next dev command.

.PARAMETER Arguments
    Arguments to pass to next dev.

.EXAMPLE
    Start-NextJsDev

.EXAMPLE
    Start-NextJsDev --port 3001
#>
function Start-NextJsDev {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx next dev @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Next.js build - create production build
<#
.SYNOPSIS
    Builds Next.js application for production.

.DESCRIPTION
    Wrapper for npx next build command.

.PARAMETER Arguments
    Arguments to pass to next build.

.EXAMPLE
    Build-NextJsApp

.EXAMPLE
    Build-NextJsApp --no-lint
#>
function Build-NextJsApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx next build @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Next.js start - start production server
<#
.SYNOPSIS
    Starts Next.js production server.

.DESCRIPTION
    Wrapper for npx next start command.

.PARAMETER Arguments
    Arguments to pass to next start.

.EXAMPLE
    Start-NextJsProduction

.EXAMPLE
    Start-NextJsProduction --port 3000
#>
function Start-NextJsProduction {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx next start @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Create Next.js app - bootstrap a new Next.js application
<#
.SYNOPSIS
    Creates a new Next.js application.

.DESCRIPTION
    Wrapper for npx create-next-app command.

.PARAMETER Arguments
    Arguments to pass to create-next-app.

.EXAMPLE
    New-NextJsApp my-app

.EXAMPLE
    New-NextJsApp my-app --typescript --tailwind
#>
function New-NextJsApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx create-next-app @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'npm' -ToolType 'node-package' -Tool 'npx'
    }
}

# Create aliases for short forms
Set-AgentModeAlias -Name 'next-dev' -Target 'Start-NextJsDev'
Set-AgentModeAlias -Name 'next-build' -Target 'Build-NextJsApp'
Set-AgentModeAlias -Name 'next-start' -Target 'Start-NextJsProduction'
Set-AgentModeAlias -Name 'create-next-app' -Target 'New-NextJsApp'
