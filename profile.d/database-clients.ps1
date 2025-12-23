# ===============================================
# database-clients.ps1
# Database client tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: server, development

<#
.SYNOPSIS
    Database client tools fragment for database management and operations.

.DESCRIPTION
    Provides wrapper functions for database client tools:
    - mongodb-compass: MongoDB GUI client
    - sql-workbench: SQL Workbench/J universal database tool
    - dbeaver: Universal database tool
    - tableplus: Modern database client
    - hasura-cli: Hasura GraphQL engine CLI
    - supabase: Supabase CLI

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'database-clients') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # MongoDB Compass - MongoDB GUI client
    # ===============================================

    <#
    .SYNOPSIS
        Launches MongoDB Compass GUI.
    
    .DESCRIPTION
        Opens MongoDB Compass, a GUI tool for MongoDB database management and visualization.
        MongoDB Compass allows you to explore, query, and manage MongoDB databases.
    
    .PARAMETER ConnectionString
        Optional MongoDB connection string to open directly.
    
    .EXAMPLE
        Start-MongoDbCompass
        Launches MongoDB Compass GUI.
    
    .EXAMPLE
        Start-MongoDbCompass -ConnectionString "mongodb://localhost:27017"
        Launches MongoDB Compass with a connection string.
    
    .OUTPUTS
        System.Diagnostics.Process. Process object for MongoDB Compass.
    #>
    function Start-MongoDbCompass {
        [CmdletBinding()]
        [OutputType([System.Diagnostics.Process])]
        param(
            [Parameter()]
            [string]$ConnectionString
        )

        if (-not (Test-CachedCommand 'mongodb-compass')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'mongodb-compass' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install mongodb-compass"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'mongodb-compass' -InstallHint $installHint
            }
            else {
                Write-Warning "mongodb-compass not found. $installHint"
            }
            return $null
        }

        try {
            $args = @()
            if (-not [string]::IsNullOrWhiteSpace($ConnectionString)) {
                $args += $ConnectionString
            }
            $process = Start-Process -FilePath 'mongodb-compass' -ArgumentList $args -PassThru -NoNewWindow
            return $process
        }
        catch {
            Write-Error "Failed to start mongodb-compass: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Start-MongoDbCompass -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Start-MongoDbCompass' -Body ${function:Start-MongoDbCompass}
        Set-AgentModeAlias -Name 'mongodb-compass' -Target 'Start-MongoDbCompass'
    }

    # ===============================================
    # SQL Workbench - SQL Workbench/J
    # ===============================================

    <#
    .SYNOPSIS
        Launches SQL Workbench/J.
    
    .DESCRIPTION
        Opens SQL Workbench/J, a universal database tool for SQL databases.
        Supports multiple database systems including MySQL, PostgreSQL, Oracle, and more.
    
    .PARAMETER Workspace
        Optional workspace file to open.
    
    .EXAMPLE
        Start-SqlWorkbench
        Launches SQL Workbench/J.
    
    .EXAMPLE
        Start-SqlWorkbench -Workspace "C:\Workspaces\my-workspace.xml"
        Launches SQL Workbench/J with a specific workspace.
    
    .OUTPUTS
        System.Diagnostics.Process. Process object for SQL Workbench/J.
    #>
    function Start-SqlWorkbench {
        [CmdletBinding()]
        [OutputType([System.Diagnostics.Process])]
        param(
            [Parameter()]
            [string]$Workspace
        )

        if (-not (Test-CachedCommand 'sql-workbench')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'sql-workbench' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install sql-workbench"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'sql-workbench' -InstallHint $installHint
            }
            else {
                Write-Warning "sql-workbench not found. $installHint"
            }
            return $null
        }

        try {
            $args = @()
            if (-not [string]::IsNullOrWhiteSpace($Workspace)) {
                if (-not (Test-Path -LiteralPath $Workspace)) {
                    Write-Error "Workspace file not found: $Workspace"
                    return $null
                }
                $args += $Workspace
            }
            $process = Start-Process -FilePath 'sql-workbench' -ArgumentList $args -PassThru -NoNewWindow
            return $process
        }
        catch {
            Write-Error "Failed to start sql-workbench: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Start-SqlWorkbench -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Start-SqlWorkbench' -Body ${function:Start-SqlWorkbench}
        Set-AgentModeAlias -Name 'sql-workbench' -Target 'Start-SqlWorkbench'
    }

    # ===============================================
    # DBeaver - Universal database tool
    # ===============================================

    <#
    .SYNOPSIS
        Launches DBeaver Universal Database Tool.
    
    .DESCRIPTION
        Opens DBeaver, a universal database tool that supports many database types.
        DBeaver provides a rich SQL editor, data viewer, and database management features.
    
    .PARAMETER Workspace
        Optional workspace directory to open.
    
    .EXAMPLE
        Start-DBeaver
        Launches DBeaver.
    
    .EXAMPLE
        Start-DBeaver -Workspace "C:\Workspaces\dbeaver"
        Launches DBeaver with a specific workspace directory.
    
    .OUTPUTS
        System.Diagnostics.Process. Process object for DBeaver.
    #>
    function Start-DBeaver {
        [CmdletBinding()]
        [OutputType([System.Diagnostics.Process])]
        param(
            [Parameter()]
            [string]$Workspace
        )

        if (-not (Test-CachedCommand 'dbeaver')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'dbeaver' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install dbeaver"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'dbeaver' -InstallHint $installHint
            }
            else {
                Write-Warning "dbeaver not found. $installHint"
            }
            return $null
        }

        try {
            $args = @()
            if (-not [string]::IsNullOrWhiteSpace($Workspace)) {
                if (-not (Test-Path -LiteralPath $Workspace -PathType Container)) {
                    Write-Error "Workspace directory not found: $Workspace"
                    return $null
                }
                $args += @('-data', $Workspace)
            }
            $process = Start-Process -FilePath 'dbeaver' -ArgumentList $args -PassThru -NoNewWindow
            return $process
        }
        catch {
            Write-Error "Failed to start dbeaver: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Start-DBeaver -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Start-DBeaver' -Body ${function:Start-DBeaver}
        Set-AgentModeAlias -Name 'dbeaver' -Target 'Start-DBeaver'
    }

    # ===============================================
    # TablePlus - Modern database client
    # ===============================================

    <#
    .SYNOPSIS
        Launches TablePlus.
    
    .DESCRIPTION
        Opens TablePlus, a modern database client with a clean interface.
        TablePlus supports multiple database systems with a unified interface.
    
    .PARAMETER Connection
        Optional connection name or file to open.
    
    .EXAMPLE
        Start-TablePlus
        Launches TablePlus.
    
    .EXAMPLE
        Start-TablePlus -Connection "my-connection"
        Launches TablePlus with a specific connection.
    
    .OUTPUTS
        System.Diagnostics.Process. Process object for TablePlus.
    #>
    function Start-TablePlus {
        [CmdletBinding()]
        [OutputType([System.Diagnostics.Process])]
        param(
            [Parameter()]
            [string]$Connection
        )

        if (-not (Test-CachedCommand 'tableplus')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'tableplus' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install tableplus"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'tableplus' -InstallHint $installHint
            }
            else {
                Write-Warning "tableplus not found. $installHint"
            }
            return $null
        }

        try {
            $args = @()
            if (-not [string]::IsNullOrWhiteSpace($Connection)) {
                $args += $Connection
            }
            $process = Start-Process -FilePath 'tableplus' -ArgumentList $args -PassThru -NoNewWindow
            return $process
        }
        catch {
            Write-Error "Failed to start tableplus: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Start-TablePlus -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Start-TablePlus' -Body ${function:Start-TablePlus}
        Set-AgentModeAlias -Name 'tableplus' -Target 'Start-TablePlus'
    }

    # ===============================================
    # Hasura CLI - Hasura GraphQL engine CLI
    # ===============================================

    <#
    .SYNOPSIS
        Executes Hasura CLI commands.
    
    .DESCRIPTION
        Wrapper function for Hasura CLI that executes Hasura GraphQL engine commands.
        Hasura provides instant GraphQL APIs over databases.
    
    .PARAMETER Arguments
        Arguments to pass to hasura-cli command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-Hasura version
        Checks Hasura CLI version.
    
    .EXAMPLE
        Invoke-Hasura migrate apply
        Applies database migrations.
    
    .EXAMPLE
        Invoke-Hasura console
        Starts Hasura console.
    
    .OUTPUTS
        System.String. Output from Hasura CLI execution.
    #>
    function Invoke-Hasura {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'hasura-cli')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'hasura-cli' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install hasura-cli"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'hasura-cli' -InstallHint $installHint
            }
            else {
                Write-Warning "hasura-cli not found. $installHint"
            }
            return $null
        }

        try {
            $result = & hasura-cli $Arguments 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run hasura-cli: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-Hasura -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Hasura' -Body ${function:Invoke-Hasura}
        Set-AgentModeAlias -Name 'hasura' -Target 'Invoke-Hasura'
    }

    # ===============================================
    # Supabase CLI - Supabase CLI
    # ===============================================

    <#
    .SYNOPSIS
        Executes Supabase CLI commands.
    
    .DESCRIPTION
        Wrapper function for Supabase CLI that executes Supabase commands.
        Supabase is an open-source Firebase alternative with PostgreSQL database.
    
    .PARAMETER Arguments
        Arguments to pass to supabase command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-Supabase status
        Checks Supabase local development status.
    
    .EXAMPLE
        Invoke-Supabase start
        Starts local Supabase development environment.
    
    .EXAMPLE
        Invoke-Supabase stop
        Stops local Supabase development environment.
    
    .OUTPUTS
        System.String. Output from Supabase CLI execution.
    #>
    function Invoke-Supabase {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        $supabaseCmd = $null
        if (Test-CachedCommand 'supabase-beta') {
            $supabaseCmd = 'supabase-beta'
        }
        elseif (Test-CachedCommand 'supabase') {
            $supabaseCmd = 'supabase'
        }

        if (-not $supabaseCmd) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'supabase' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install supabase-beta"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'supabase' -InstallHint $installHint
            }
            else {
                Write-Warning "supabase not found. $installHint"
            }
            return $null
        }

        try {
            $result = & $supabaseCmd $Arguments 2>&1
            return $result
        }
        catch {
            $cmdName = $supabaseCmd
            Write-Error "Failed to run ${cmdName}: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-Supabase -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Supabase' -Body ${function:Invoke-Supabase}
        Set-AgentModeAlias -Name 'supabase' -Target 'Invoke-Supabase'
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'database-clients'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'database-clients' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load database-clients fragment: $($_.Exception.Message)"
    }
}
