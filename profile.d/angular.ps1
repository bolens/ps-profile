# ===============================================
# angular.ps1
# Angular CLI helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Angular CLI helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Angular CLI operations.
    Functions check for npx/ng availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Angular
    Author: PowerShell Profile
#>

# Angular execute - run angular with arguments
<#
.SYNOPSIS
    Executes Angular CLI commands.

.DESCRIPTION
    Wrapper function for Angular CLI that checks for command availability before execution.
    Prefers npx @angular/cli, falls back to globally installed ng.

.PARAMETER Arguments
    Arguments to pass to Angular CLI.

.EXAMPLE
    Invoke-Angular --version

.EXAMPLE
    Invoke-Angular generate component my-component
#>
function Invoke-Angular {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx @angular/cli @Arguments
    }
    elseif (Test-CachedCommand ng) {
        ng @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            $pmHint = Get-PreferenceAwareInstallHint -ToolName '@angular/cli' -ToolType 'node-package'
            $pmHint -replace '@angular/cli', 'npm or @angular/cli'
        }
        else {
            'Install with: npm install -g npm or npm install -g @angular/cli'
        }
        Write-MissingToolWarning -Tool 'npx or ng' -InstallHint $installHint
    }
}

# Angular new project - create new Angular application
<#
.SYNOPSIS
    Creates a new Angular application.

.DESCRIPTION
    Wrapper for Angular CLI new command. Prefers npx @angular/cli, falls back to globally installed ng.

.PARAMETER Arguments
    Arguments to pass to ng new.

.EXAMPLE
    New-AngularApp my-app

.EXAMPLE
    New-AngularApp my-app --routing --style scss
#>
function New-AngularApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx @angular/cli new @Arguments
    }
    elseif (Test-CachedCommand ng) {
        ng new @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            $pmHint = Get-PreferenceAwareInstallHint -ToolName '@angular/cli' -ToolType 'node-package'
            $pmHint -replace '@angular/cli', 'npm or @angular/cli'
        }
        else {
            'Install with: npm install -g npm or npm install -g @angular/cli'
        }
        Write-MissingToolWarning -Tool 'npx or ng' -InstallHint $installHint
    }
}

# Angular serve - start development server
<#
.SYNOPSIS
    Starts Angular development server.

.DESCRIPTION
    Wrapper for Angular CLI serve command. Prefers npx @angular/cli, falls back to globally installed ng.

.PARAMETER Arguments
    Arguments to pass to ng serve.

.EXAMPLE
    Start-AngularDev

.EXAMPLE
    Start-AngularDev --port 4200
#>
function Start-AngularDev {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx @angular/cli serve @Arguments
    }
    elseif (Test-CachedCommand ng) {
        ng serve @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            $pmHint = Get-PreferenceAwareInstallHint -ToolName '@angular/cli' -ToolType 'node-package'
            $pmHint -replace '@angular/cli', 'npm or @angular/cli'
        }
        else {
            'Install with: npm install -g npm or npm install -g @angular/cli'
        }
        Write-MissingToolWarning -Tool 'npx or ng' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ng' -Target 'Invoke-Angular'
    Set-AgentModeAlias -Name 'ng-new' -Target 'New-AngularApp'
    Set-AgentModeAlias -Name 'ng-serve' -Target 'Start-AngularDev'
}
else {
    Set-Alias -Name 'ng' -Value 'Invoke-Angular' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ng-new' -Value 'New-AngularApp' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ng-serve' -Value 'Start-AngularDev' -ErrorAction SilentlyContinue
}
