# ===============================================
# vue.ps1
# Vue.js development helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Vue.js development helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Vue.js operations.
    Functions check for npx/vue availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Vue
    Author: PowerShell Profile
#>

# Vue execute - run vue with arguments
<#
.SYNOPSIS
    Executes Vue CLI commands.

.DESCRIPTION
    Wrapper function for Vue CLI that checks for command availability before execution.
    Prefers npx @vue/cli, falls back to globally installed vue.

.PARAMETER Arguments
    Arguments to pass to Vue CLI.

.EXAMPLE
    Invoke-Vue --version

.EXAMPLE
    Invoke-Vue create my-app
#>
function Invoke-Vue {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx @vue/cli @Arguments
    }
    elseif (Test-CachedCommand vue) {
        vue @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'npx or vue' -InstallHint 'Install with: npm install -g npm or npm install -g @vue/cli'
    }
}

# Vue create project - create new Vue.js project
<#
.SYNOPSIS
    Creates a new Vue.js project.

.DESCRIPTION
    Wrapper for Vue CLI create command. Prefers npx @vue/cli, falls back to globally installed vue.

.PARAMETER Arguments
    Arguments to pass to vue create.

.EXAMPLE
    New-VueApp my-app

.EXAMPLE
    New-VueApp my-app --default
#>
function New-VueApp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx @vue/cli create @Arguments
    }
    elseif (Test-CachedCommand vue) {
        vue create @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'npx or vue' -InstallHint 'Install with: npm install -g npm or npm install -g @vue/cli'
    }
}

# Vue serve - start development server
<#
.SYNOPSIS
    Starts Vue.js development server.

.DESCRIPTION
    Wrapper for Vue CLI serve command. Prefers npx @vue/cli, falls back to globally installed vue.

.PARAMETER Arguments
    Arguments to pass to vue serve.

.EXAMPLE
    Start-VueDev

.EXAMPLE
    Start-VueDev --port 8080
#>
function Start-VueDev {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand npx) {
        npx @vue/cli serve @Arguments
    }
    elseif (Test-CachedCommand vue) {
        vue serve @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'npx or vue' -InstallHint 'Install with: npm install -g npm or npm install -g @vue/cli'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'vue' -Target 'Invoke-Vue'
    Set-AgentModeAlias -Name 'vue-create' -Target 'New-VueApp'
    Set-AgentModeAlias -Name 'vue-serve' -Target 'Start-VueDev'
}
else {
    Set-Alias -Name 'vue' -Value 'Invoke-Vue' -ErrorAction SilentlyContinue
    Set-Alias -Name 'vue-create' -Value 'New-VueApp' -ErrorAction SilentlyContinue
    Set-Alias -Name 'vue-serve' -Value 'Start-VueDev' -ErrorAction SilentlyContinue
}
