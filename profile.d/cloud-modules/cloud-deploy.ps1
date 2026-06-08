# ===============================================
# cloud-deploy.ps1
# Cloud deployment helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
<#
.SYNOPSIS
    Cloud deployment helpers
.DESCRIPTION
    Doppler, Heroku, Vercel, and Netlify deploy helpers.
.NOTES
    Loaded by cloud-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'cloud-deploy') { return }
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
    

    .OUTPUTS
        System.String. Secret values in the specified format.

    .EXAMPLE
        Get-DopplerSecrets -Project "my-project" -Config "dev"
        
        Gets all secrets from the specified project and config.
    

    .EXAMPLE
        Get-DopplerSecrets -Project "my-project" -Config "prod" -Secret "API_KEY"
        
        Gets a specific secret value.
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
            Invoke-MissingToolWarning -ToolName 'doppler'
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
    

    .OUTPUTS
        System.String. Deployment status or command output.

    .EXAMPLE
        Deploy-Heroku -AppName "my-app"
        
        Deploys the current git repository to Heroku.
    

    .EXAMPLE
        Deploy-Heroku -AppName "my-app" -Action "logs"
        
        Shows Heroku application logs.
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
            Invoke-MissingToolWarning -ToolName 'heroku-cli' -Tool 'heroku'
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
    

    .OUTPUTS
        System.String. Deployment status or command output.

    .EXAMPLE
    Deploy-Vercel -Action 'value' -ProjectPath 'value'
        Deploys the current project to Vercel.
    

    .EXAMPLE
        Deploy-Vercel -Production
        
        Deploys to production environment.
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
            Invoke-MissingToolWarning -ToolName 'vercel'
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
    

    .OUTPUTS
        System.String. Deployment status or command output.

    .EXAMPLE
    Deploy-Netlify -Action 'value' -ProjectPath 'value'
        Deploys the current project to Netlify.
    

    .EXAMPLE
        Deploy-Netlify -Action "status"
        
        Shows Netlify deployment status.
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
            Invoke-MissingToolWarning -ToolName 'netlify'
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

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'cloud-deploy'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'cloud-deploy' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load cloud-deploy: "
    }
}
