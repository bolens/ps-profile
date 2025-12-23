# ===============================================
# database.ps1
# Database client tools and helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: server, development

<#
.SYNOPSIS
    Database client tools and helper functions.

.DESCRIPTION
    Provides PowerShell functions and aliases for common database client operations.
    Supports MongoDB Compass, SQL Workbench, DBeaver, TablePlus, Hasura CLI, and Supabase CLI.
    Functions check for tool availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Database
    Author: PowerShell Profile
#>

# MongoDB Compass - launch MongoDB GUI
<#
.SYNOPSIS
    Launches MongoDB Compass GUI.

.DESCRIPTION
    Opens MongoDB Compass, a GUI tool for MongoDB database management.

.EXAMPLE
    Invoke-MongoDbCompass
#>
function Invoke-MongoDbCompass {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand mongodb-compass) {
        mongodb-compass
    }
    else {
        Write-MissingToolWarning -Tool 'mongodb-compass' -InstallHint 'Install with: scoop install mongodb-compass'
    }
}

# SQL Workbench - launch SQL Workbench/J
<#
.SYNOPSIS
    Launches SQL Workbench/J.

.DESCRIPTION
    Opens SQL Workbench/J, a universal database tool for SQL databases.

.EXAMPLE
    Invoke-SqlWorkbench
#>
function Invoke-SqlWorkbench {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand sql-workbench) {
        sql-workbench
    }
    else {
        Write-MissingToolWarning -Tool 'sql-workbench' -InstallHint 'Install with: scoop install sql-workbench'
    }
}

# DBeaver - launch DBeaver
<#
.SYNOPSIS
    Launches DBeaver Universal Database Tool.

.DESCRIPTION
    Opens DBeaver, a universal database tool that supports many database types.

.EXAMPLE
    Invoke-DBeaver
#>
function Invoke-DBeaver {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand dbeaver) {
        dbeaver
    }
    else {
        Write-MissingToolWarning -Tool 'dbeaver' -InstallHint 'Install with: scoop install dbeaver'
    }
}

# TablePlus - launch TablePlus
<#
.SYNOPSIS
    Launches TablePlus.

.DESCRIPTION
    Opens TablePlus, a modern database client with a clean interface.

.EXAMPLE
    Invoke-TablePlus
#>
function Invoke-TablePlus {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand tableplus) {
        tableplus
    }
    else {
        Write-MissingToolWarning -Tool 'tableplus' -InstallHint 'Install with: scoop install tableplus'
    }
}

# Hasura CLI - Hasura GraphQL engine CLI
<#
.SYNOPSIS
    Executes Hasura CLI commands.

.DESCRIPTION
    Wrapper function for Hasura CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to hasura.

.EXAMPLE
    Invoke-Hasura version

.EXAMPLE
    Invoke-Hasura migrate apply
#>
function Invoke-Hasura {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand hasura-cli) {
        hasura-cli @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'hasura-cli' -InstallHint 'Install with: scoop install hasura-cli'
    }
}

# Supabase CLI - Supabase CLI wrapper
<#
.SYNOPSIS
    Executes Supabase CLI commands.

.DESCRIPTION
    Wrapper function for Supabase CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to supabase.

.EXAMPLE
    Invoke-Supabase status

.EXAMPLE
    Invoke-Supabase start
#>
function Invoke-Supabase {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand supabase-beta) {
        supabase-beta @Arguments
    }
    elseif (Test-CachedCommand supabase) {
        supabase @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'supabase' -InstallHint 'Install with: scoop install supabase-beta'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mongodb-compass' -Target 'Invoke-MongoDbCompass'
    Set-AgentModeAlias -Name 'sql-workbench' -Target 'Invoke-SqlWorkbench'
    Set-AgentModeAlias -Name 'dbeaver' -Target 'Invoke-DBeaver'
    Set-AgentModeAlias -Name 'tableplus' -Target 'Invoke-TablePlus'
    Set-AgentModeAlias -Name 'hasura' -Target 'Invoke-Hasura'
    Set-AgentModeAlias -Name 'supabase' -Target 'Invoke-Supabase'
}
else {
    Set-Alias -Name 'mongodb-compass' -Value 'Invoke-MongoDbCompass' -ErrorAction SilentlyContinue
    Set-Alias -Name 'sql-workbench' -Value 'Invoke-SqlWorkbench' -ErrorAction SilentlyContinue
    Set-Alias -Name 'dbeaver' -Value 'Invoke-DBeaver' -ErrorAction SilentlyContinue
    Set-Alias -Name 'tableplus' -Value 'Invoke-TablePlus' -ErrorAction SilentlyContinue
    Set-Alias -Name 'hasura' -Value 'Invoke-Hasura' -ErrorAction SilentlyContinue
    Set-Alias -Name 'supabase' -Value 'Invoke-Supabase' -ErrorAction SilentlyContinue
}
