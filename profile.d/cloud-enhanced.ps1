# ===============================================
# cloud-enhanced.ps1
# Enhanced cloud tools and infrastructure
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, aws, azure, gcloud
# Environment: cloud, development

<#
.SYNOPSIS
    Enhanced cloud tools and infrastructure fragment.

.DESCRIPTION
    Provides enhanced wrapper functions for cloud platforms and infrastructure tools:
    - Azure: Subscription management
    - GCP: Project switching
    - Doppler: Secrets management
    - Heroku: Deployment helpers
    - Vercel: Deployment helpers
    - Netlify: Deployment helpers

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances existing aws.ps1, azure.ps1, and gcloud.ps1 modules.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'cloud-enhanced') { return }
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
    # Set-AzureSubscription - Switch Azure subscription
    # ===============================================

    <#
    .SYNOPSIS
        Switches the active Azure subscription.
    
    .DESCRIPTION
        Changes the active Azure subscription for the current session.
        Uses Azure CLI to list and set subscriptions.
    
    .PARAMETER SubscriptionId
        Subscription ID or name to switch to.
    
    .PARAMETER List
        List all available subscriptions instead of switching.
    
    .EXAMPLE
        Set-AzureSubscription -SubscriptionId "my-subscription-id"
        
        Switches to the specified subscription.
    
    .EXAMPLE
        Set-AzureSubscription -List
        
        Lists all available subscriptions.
    
    .OUTPUTS
        System.String. Subscription information or list of subscriptions.
    #>
    function Set-AzureSubscription {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$SubscriptionId,
            
            [switch]$List
        )

        if (-not (Test-CachedCommand 'az')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'azure-cli' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'az' -InstallHint $installHint
            }
            else {
                Write-Warning "az is not installed. Install it with: scoop install azure-cli"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'cloud.azure.subscription.manage' -Context @{
                action          = if ($List) { 'list' } elseif ($SubscriptionId) { 'set' } else { 'show' }
                subscription_id = $SubscriptionId
            } -ScriptBlock {
                if ($List) {
                    $output = & az account list --output table 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to list subscriptions. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
                elseif ($SubscriptionId) {
                    $output = & az account set --subscription $SubscriptionId 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to switch subscription. Exit code: $LASTEXITCODE"
                    }
                    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
                    return $output
                }
                else {
                    # Show current subscription
                    $output = & az account show --output table 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to get current subscription. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
            }
        }
        else {
            try {
                if ($List) {
                    $output = & az account list --output table 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to list subscriptions. Exit code: $LASTEXITCODE"
                    }
                }
                elseif ($SubscriptionId) {
                    $output = & az account set --subscription $SubscriptionId 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
                        return $output
                    }
                    else {
                        Write-Error "Failed to switch subscription. Exit code: $LASTEXITCODE"
                    }
                }
                else {
                    # Show current subscription
                    $output = & az account show --output table 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to get current subscription. Exit code: $LASTEXITCODE"
                    }
                }
            }
            catch {
                Write-Error "Failed to run az account command: $_"
            }
        }
    }

    # ===============================================
    # Set-GcpProject - Switch GCP project
    # ===============================================

    <#
    .SYNOPSIS
        Switches the active GCP project.
    
    .DESCRIPTION
        Changes the active Google Cloud Platform project for the current session.
        Uses gcloud to list and set projects.
    
    .PARAMETER ProjectId
        Project ID to switch to.
    
    .PARAMETER List
        List all available projects instead of switching.
    
    .EXAMPLE
        Set-GcpProject -ProjectId "my-project-id"
        
        Switches to the specified project.
    
    .EXAMPLE
        Set-GcpProject -List
        
        Lists all available projects.
    
    .OUTPUTS
        System.String. Project information or list of projects.
    #>
    function Set-GcpProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$ProjectId,
            
            [switch]$List
        )

        if (-not (Test-CachedCommand 'gcloud')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'gcloud' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'gcloud' -InstallHint $installHint
            }
            else {
                Write-Warning "gcloud is not installed. Install it with: scoop install gcloud"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'cloud.gcp.project.manage' -Context @{
                action     = if ($List) { 'list' } elseif ($ProjectId) { 'set' } else { 'show' }
                project_id = $ProjectId
            } -ScriptBlock {
                if ($List) {
                    $output = & gcloud projects list 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to list projects. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
                elseif ($ProjectId) {
                    $output = & gcloud config set project $ProjectId 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to switch project. Exit code: $LASTEXITCODE"
                    }
                    Write-Host "Switched to project: $ProjectId" -ForegroundColor Green
                    return $output
                }
                else {
                    # Show current project
                    $output = & gcloud config get-value project 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to get current project. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
            }
        }
        else {
            try {
                if ($List) {
                    $output = & gcloud projects list 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to list projects. Exit code: $LASTEXITCODE"
                    }
                }
                elseif ($ProjectId) {
                    $output = & gcloud config set project $ProjectId 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Switched to project: $ProjectId" -ForegroundColor Green
                        return $output
                    }
                    else {
                        Write-Error "Failed to switch project. Exit code: $LASTEXITCODE"
                    }
                }
                else {
                    # Show current project
                    $output = & gcloud config get-value project 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to get current project. Exit code: $LASTEXITCODE"
                    }
                }
            }
            catch {
                Write-Error "Failed to run gcloud command: $_"
            }
        }
    }

    # ===============================================
    # Get-DopplerSecrets - Get secrets from Doppler
    # ===============================================

    <#
    .SYNOPSIS
        Retrieves secrets from Doppler.
    
    .DESCRIPTION
        Gets secrets from Doppler secrets management service.
        Supports different output formats and project/config selection.
    
    .PARAMETER Project
        Doppler project name.
    
    .PARAMETER Config
        Doppler config name (e.g., dev, staging, prod).
    
    .PARAMETER Secret
        Specific secret name to retrieve. If not specified, returns all secrets.
    
    .PARAMETER OutputFormat
        Output format: json, env, shell. Defaults to env.
    
    .EXAMPLE
        Get-DopplerSecrets -Project "my-project" -Config "dev"
        
        Gets all secrets from the specified project and config.
    
    .EXAMPLE
        Get-DopplerSecrets -Project "my-project" -Config "prod" -Secret "API_KEY"
        
        Gets a specific secret value.
    
    .OUTPUTS
        System.String. Secret values in the specified format.
    #>
    function Get-DopplerSecrets {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$Project,
            
            [string]$Config,
            
            [string]$Secret,
            
            [ValidateSet('json', 'env', 'shell')]
            [string]$OutputFormat = 'env'
        )

        if (-not (Test-CachedCommand 'doppler')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'doppler' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'doppler' -InstallHint $installHint
            }
            else {
                Write-Warning "doppler is not installed. Install it with: scoop install doppler"
            }
            return
        }

        $arguments = @('secrets', 'get')

        if ($Project) {
            $arguments += '--project', $Project
        }

        if ($Config) {
            $arguments += '--config', $Config
        }

        if ($Secret) {
            $arguments += $Secret
        }

        if ($OutputFormat -eq 'json') {
            $arguments += '--format', 'json'
        }
        elseif ($OutputFormat -eq 'shell') {
            $arguments += '--format', 'shell'
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'cloud.doppler.secrets.get' -Context @{
                project       = $Project
                config        = $Config
                secret        = $Secret
                output_format = $OutputFormat
            } -ScriptBlock {
                $output = & doppler $arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to get Doppler secrets. Exit code: $LASTEXITCODE"
                }
                return $output
            }
        }
        else {
            try {
                $output = & doppler $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to get Doppler secrets. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to run doppler: $_"
            }
        }
    }

    # ===============================================
    # Deploy-Heroku - Heroku deployment helpers
    # ===============================================

    <#
    .SYNOPSIS
        Deploys to Heroku.
    
    .DESCRIPTION
        Provides helper functions for Heroku deployments.
        Supports git-based deployments and direct app management.
    
    .PARAMETER AppName
        Heroku app name.
    
    .PARAMETER Action
        Action to perform: deploy, logs, status, restart. Defaults to deploy.
    
    .PARAMETER Branch
        Git branch to deploy. Defaults to main.
    
    .EXAMPLE
        Deploy-Heroku -AppName "my-app"
        
        Deploys the current git repository to Heroku.
    
    .EXAMPLE
        Deploy-Heroku -AppName "my-app" -Action "logs"
        
        Shows Heroku application logs.
    
    .OUTPUTS
        System.String. Deployment status or command output.
    #>
    function Deploy-Heroku {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$AppName,
            
            [ValidateSet('deploy', 'logs', 'status', 'restart')]
            [string]$Action = 'deploy',
            
            [string]$Branch = 'main'
        )

        if (-not (Test-CachedCommand 'heroku')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'heroku-cli' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'heroku' -InstallHint $installHint
            }
            else {
                Write-Warning "heroku is not installed. Install it with: scoop install heroku-cli"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "cloud.heroku.$Action" -Context @{
                app_name = $AppName
                action   = $Action
                branch   = $Branch
            } -ScriptBlock {
                switch ($Action) {
                    'deploy' {
                        $output = & git push heroku $Branch 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Heroku deployment failed. Exit code: $LASTEXITCODE"
                        }
                        return $output
                    }
                    'logs' {
                        $output = & heroku logs --tail --app $AppName 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Failed to get Heroku logs. Exit code: $LASTEXITCODE"
                        }
                        return $output
                    }
                    'status' {
                        $output = & heroku ps --app $AppName 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Failed to get Heroku status. Exit code: $LASTEXITCODE"
                        }
                        return $output
                    }
                    'restart' {
                        $output = & heroku restart --app $AppName 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Failed to restart Heroku app. Exit code: $LASTEXITCODE"
                        }
                        return $output
                    }
                }
            }
        }
        else {
            try {
                switch ($Action) {
                    'deploy' {
                        $output = & git push heroku $Branch 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Heroku deployment failed. Exit code: $LASTEXITCODE"
                        }
                    }
                    'logs' {
                        $output = & heroku logs --tail --app $AppName 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to get Heroku logs. Exit code: $LASTEXITCODE"
                        }
                    }
                    'status' {
                        $output = & heroku ps --app $AppName 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to get Heroku status. Exit code: $LASTEXITCODE"
                        }
                    }
                    'restart' {
                        $output = & heroku restart --app $AppName 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to restart Heroku app. Exit code: $LASTEXITCODE"
                        }
                    }
                }
            }
            catch {
                Write-Error "Failed to run Heroku command: $_"
            }
        }
    }

    # ===============================================
    # Deploy-Vercel - Vercel deployment helpers
    # ===============================================

    <#
    .SYNOPSIS
        Deploys to Vercel.
    
    .DESCRIPTION
        Provides helper functions for Vercel deployments.
        Supports project deployment and management.
    
    .PARAMETER Action
        Action to perform: deploy, list, remove. Defaults to deploy.
    
    .PARAMETER ProjectPath
        Path to the project directory. Defaults to current directory.
    
    .PARAMETER Production
        Deploy to production environment.
    
    .EXAMPLE
        Deploy-Vercel
        
        Deploys the current project to Vercel.
    
    .EXAMPLE
        Deploy-Vercel -Production
        
        Deploys to production environment.
    
    .OUTPUTS
        System.String. Deployment status or command output.
    #>
    function Deploy-Vercel {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [ValidateSet('deploy', 'list', 'remove')]
            [string]$Action = 'deploy',
            
            [string]$ProjectPath = (Get-Location).Path,
            
            [switch]$Production
        )

        if (-not (Test-CachedCommand 'vercel')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'vercel' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'vercel' -InstallHint $installHint
            }
            else {
                Write-Warning "vercel is not installed. Install it with: npm install -g vercel"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "cloud.vercel.$Action" -Context @{
                action       = $Action
                project_path = $ProjectPath
                production   = $Production.IsPresent
            } -ScriptBlock {
                Push-Location $ProjectPath
                try {
                    switch ($Action) {
                        'deploy' {
                            $arguments = @()
                            if ($Production) {
                                $arguments += '--prod'
                            }
                            $output = & vercel $arguments 2>&1
                            if ($LASTEXITCODE -ne 0) {
                                throw "Vercel deployment failed. Exit code: $LASTEXITCODE"
                            }
                            return $output
                        }
                        'list' {
                            $output = & vercel ls 2>&1
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to list Vercel deployments. Exit code: $LASTEXITCODE"
                            }
                            return $output
                        }
                        'remove' {
                            $output = & vercel remove 2>&1
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to remove Vercel deployment. Exit code: $LASTEXITCODE"
                            }
                            return $output
                        }
                    }
                }
                finally {
                    Pop-Location
                }
            }
        }
        else {
            try {
                Push-Location $ProjectPath

                switch ($Action) {
                    'deploy' {
                        $arguments = @()
                        if ($Production) {
                            $arguments += '--prod'
                        }
                        $output = & vercel $arguments 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Vercel deployment failed. Exit code: $LASTEXITCODE"
                        }
                    }
                    'list' {
                        $output = & vercel ls 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to list Vercel deployments. Exit code: $LASTEXITCODE"
                        }
                    }
                    'remove' {
                        $output = & vercel remove 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to remove Vercel deployment. Exit code: $LASTEXITCODE"
                        }
                    }
                }
            }
            catch {
                Write-Error "Failed to run Vercel command: $_"
            }
            finally {
                Pop-Location
            }
        }
    }

    # ===============================================
    # Deploy-Netlify - Netlify deployment helpers
    # ===============================================

    <#
    .SYNOPSIS
        Deploys to Netlify.
    
    .DESCRIPTION
        Provides helper functions for Netlify deployments.
        Supports site deployment and management.
    
    .PARAMETER Action
        Action to perform: deploy, status, open. Defaults to deploy.
    
    .PARAMETER ProjectPath
        Path to the project directory. Defaults to current directory.
    
    .PARAMETER Production
        Deploy to production environment.
    
    .EXAMPLE
        Deploy-Netlify
        
        Deploys the current project to Netlify.
    
    .EXAMPLE
        Deploy-Netlify -Action "status"
        
        Shows Netlify deployment status.
    
    .OUTPUTS
        System.String. Deployment status or command output.
    #>
    function Deploy-Netlify {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [ValidateSet('deploy', 'status', 'open')]
            [string]$Action = 'deploy',
            
            [string]$ProjectPath = (Get-Location).Path,
            
            [switch]$Production
        )

        if (-not (Test-CachedCommand 'netlify')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'netlify' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'netlify' -InstallHint $installHint
            }
            else {
                Write-Warning "netlify is not installed. Install it with: npm install -g netlify-cli"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "cloud.netlify.$Action" -Context @{
                action       = $Action
                project_path = $ProjectPath
                production   = $Production.IsPresent
            } -ScriptBlock {
                Push-Location $ProjectPath
                try {
                    switch ($Action) {
                        'deploy' {
                            $arguments = @('deploy')
                            if ($Production) {
                                $arguments += '--prod'
                            }
                            $output = & netlify $arguments 2>&1
                            if ($LASTEXITCODE -ne 0) {
                                throw "Netlify deployment failed. Exit code: $LASTEXITCODE"
                            }
                            return $output
                        }
                        'status' {
                            $output = & netlify status 2>&1
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to get Netlify status. Exit code: $LASTEXITCODE"
                            }
                            return $output
                        }
                        'open' {
                            $output = & netlify open 2>&1
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to open Netlify site. Exit code: $LASTEXITCODE"
                            }
                            return $output
                        }
                    }
                }
                finally {
                    Pop-Location
                }
            }
        }
        else {
            try {
                Push-Location $ProjectPath

                switch ($Action) {
                    'deploy' {
                        $arguments = @('deploy')
                        if ($Production) {
                            $arguments += '--prod'
                        }
                        $output = & netlify $arguments 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Netlify deployment failed. Exit code: $LASTEXITCODE"
                        }
                    }
                    'status' {
                        $output = & netlify status 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to get Netlify status. Exit code: $LASTEXITCODE"
                        }
                    }
                    'open' {
                        $output = & netlify open 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            return $output
                        }
                        else {
                            Write-Error "Failed to open Netlify site. Exit code: $LASTEXITCODE"
                        }
                    }
                }
            }
            catch {
                Write-Error "Failed to run Netlify command: $_"
            }
            finally {
                Pop-Location
            }
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Set-AzureSubscription' -Body ${function:Set-AzureSubscription}
        Set-AgentModeFunction -Name 'Set-GcpProject' -Body ${function:Set-GcpProject}
        Set-AgentModeFunction -Name 'Get-DopplerSecrets' -Body ${function:Get-DopplerSecrets}
        Set-AgentModeFunction -Name 'Deploy-Heroku' -Body ${function:Deploy-Heroku}
        Set-AgentModeFunction -Name 'Deploy-Vercel' -Body ${function:Deploy-Vercel}
        Set-AgentModeFunction -Name 'Deploy-Netlify' -Body ${function:Deploy-Netlify}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Set-AzureSubscription -Value ${function:Set-AzureSubscription} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Set-GcpProject -Value ${function:Set-GcpProject} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-DopplerSecrets -Value ${function:Get-DopplerSecrets} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Deploy-Heroku -Value ${function:Deploy-Heroku} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Deploy-Vercel -Value ${function:Deploy-Vercel} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Deploy-Netlify -Value ${function:Deploy-Netlify} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'cloud-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: cloud-enhanced" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load cloud-enhanced fragment: $($_.Exception.Message)"
    }
}
