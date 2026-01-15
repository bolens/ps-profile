# ===============================================
# iac-tools.ps1
# Infrastructure as Code tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, terraform, ansible
# Environment: cloud, development

<#
.SYNOPSIS
    Infrastructure as Code tools fragment.

.DESCRIPTION
    Provides enhanced wrapper functions for Infrastructure as Code tools:
    - Terragrunt: Terraform wrapper for DRY configurations
    - OpenTofu: Terraform fork
    - Pulumi: Infrastructure as code with multiple languages
    - Vault: Secrets management
    - Enhanced Terraform operations: state queries, planning, applying

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances existing terraform.ps1 and ansible.ps1 modules.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'iac-tools') { return }
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
    # Invoke-Terragrunt - Terragrunt wrapper
    # ===============================================

    <#
    .SYNOPSIS
        Executes Terragrunt commands.
    
    .DESCRIPTION
        Wrapper function for Terragrunt, a thin wrapper for Terraform that provides
        extra tools for working with multiple Terraform modules.
    
    .PARAMETER Arguments
        Arguments to pass to terragrunt.
    
    .EXAMPLE
        Invoke-Terragrunt plan
        
        Runs terragrunt plan.
    
    .EXAMPLE
        Invoke-Terragrunt apply -auto-approve
        
        Applies Terragrunt changes automatically.
    #>
    function Invoke-Terragrunt {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'terragrunt')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'terragrunt' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'terragrunt' -InstallHint $installHint
            }
            else {
                Write-Warning "terragrunt is not installed. Install it with: scoop install terragrunt"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'iac.terragrunt.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                terragrunt @Arguments
            } | Out-Null
        }
        else {
            try {
                terragrunt @Arguments
            }
            catch {
                Write-Error "Failed to run terragrunt: $_"
            }
        }
    }

    # ===============================================
    # Invoke-OpenTofu - OpenTofu wrapper
    # ===============================================

    <#
    .SYNOPSIS
        Executes OpenTofu commands.
    
    .DESCRIPTION
        Wrapper function for OpenTofu, an open-source fork of Terraform.
        Provides the same interface as Terraform with open-source licensing.
    
    .PARAMETER Arguments
        Arguments to pass to opentofu.
    
    .EXAMPLE
        Invoke-OpenTofu init
        
        Initializes OpenTofu working directory.
    
    .EXAMPLE
        Invoke-OpenTofu plan
        
        Creates an OpenTofu execution plan.
    #>
    function Invoke-OpenTofu {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'tofu')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'opentofu' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'tofu' -InstallHint $installHint
            }
            else {
                Write-Warning "opentofu is not installed. Install it with: scoop install opentofu"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'iac.opentofu.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                tofu @Arguments
            } | Out-Null
        }
        else {
            try {
                tofu @Arguments
            }
            catch {
                Write-Error "Failed to run opentofu: $_"
            }
        }
    }

    # ===============================================
    # Plan-Infrastructure - Plan infrastructure changes
    # ===============================================

    <#
    .SYNOPSIS
        Plans infrastructure changes.
    
    .DESCRIPTION
        Creates an execution plan for infrastructure changes using Terraform or OpenTofu.
        Prefers Terraform, falls back to OpenTofu if Terraform is not available.
    
    .PARAMETER Tool
        Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).
    
    .PARAMETER OutputFile
        Optional file to save the plan to.
    
    .PARAMETER Arguments
        Additional arguments to pass to the plan command.
    
    .EXAMPLE
        Plan-Infrastructure
        
        Creates a plan using the default tool (Terraform).
    
    .EXAMPLE
        Plan-Infrastructure -OutputFile "plan.out" -Tool "opentofu"
        
        Creates a plan using OpenTofu and saves to plan.out.
    
    .OUTPUTS
        System.String. Plan output.
    #>
    function Plan-Infrastructure {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [ValidateSet('terraform', 'opentofu', 'auto')]
            [string]$Tool = 'auto',
            
            [string]$OutputFile,
            
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        $useTerraform = Test-CachedCommand 'terraform'
        $useOpenTofu = Test-CachedCommand 'tofu'

        if ($Tool -eq 'auto') {
            if ($useTerraform) {
                $Tool = 'terraform'
            }
            elseif ($useOpenTofu) {
                $Tool = 'opentofu'
            }
        }

        if (-not $useTerraform -and -not $useOpenTofu) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'terraform' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'terraform' -InstallHint $installHint
            }
            else {
                Write-Warning "terraform is not installed. Install it with: scoop install terraform"
            }
            return
        }

        $command = if ($Tool -eq 'opentofu' -and $useOpenTofu) { 'tofu' } else { 'terraform' }
        
        $planArgs = @('plan')
        
        if ($OutputFile) {
            $planArgs += '-out', $OutputFile
        }
        
        if ($Arguments) {
            $planArgs += $Arguments
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'iac.terraform.plan' -Context @{
                tool                = $Tool
                output_file         = $OutputFile
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $output = & $command $planArgs 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Plan failed. Exit code: $LASTEXITCODE"
                }
                return $output
            }
        }
        else {
            try {
                $output = & $command $planArgs 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Plan failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to run plan: $_"
            }
        }
    }

    # ===============================================
    # Apply-Infrastructure - Apply infrastructure changes
    # ===============================================

    <#
    .SYNOPSIS
        Applies infrastructure changes.
    
    .DESCRIPTION
        Applies infrastructure changes using Terraform or OpenTofu.
        Prefers Terraform, falls back to OpenTofu if Terraform is not available.
    
    .PARAMETER Tool
        Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).
    
    .PARAMETER PlanFile
        Optional plan file to apply.
    
    .PARAMETER AutoApprove
        Automatically approve the apply without prompting.
    
    .PARAMETER Arguments
        Additional arguments to pass to the apply command.
    
    .EXAMPLE
        Apply-Infrastructure
        
        Applies infrastructure changes using the default tool.
    
    .EXAMPLE
        Apply-Infrastructure -PlanFile "plan.out" -AutoApprove
        
        Applies a specific plan file automatically.
    
    .OUTPUTS
        System.String. Apply output.
    #>
    function Apply-Infrastructure {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [ValidateSet('terraform', 'opentofu', 'auto')]
            [string]$Tool = 'auto',
            
            [string]$PlanFile,
            
            [switch]$AutoApprove,
            
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        $useTerraform = Test-CachedCommand 'terraform'
        $useOpenTofu = Test-CachedCommand 'tofu'

        if ($Tool -eq 'auto') {
            if ($useTerraform) {
                $Tool = 'terraform'
            }
            elseif ($useOpenTofu) {
                $Tool = 'opentofu'
            }
        }

        if (-not $useTerraform -and -not $useOpenTofu) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'terraform' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'terraform' -InstallHint $installHint
            }
            else {
                Write-Warning "terraform is not installed. Install it with: scoop install terraform"
            }
            return
        }

        if (-not $PSCmdlet.ShouldProcess("Infrastructure", "Apply changes")) {
            return
        }

        $command = if ($Tool -eq 'opentofu' -and $useOpenTofu) { 'tofu' } else { 'terraform' }
        
        $applyArgs = @('apply')
        
        if ($AutoApprove) {
            $applyArgs += '-auto-approve'
        }
        
        if ($PlanFile) {
            $applyArgs += $PlanFile
        }
        
        if ($Arguments) {
            $applyArgs += $Arguments
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'iac.terraform.apply' -Context @{
                tool                = $Tool
                plan_file           = $PlanFile
                auto_approve        = $AutoApprove.IsPresent
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $output = & $command $applyArgs 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Apply failed. Exit code: $LASTEXITCODE"
                }
                return $output
            }
        }
        else {
            try {
                $output = & $command $applyArgs 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Apply failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to run apply: $_"
            }
        }
    }

    # ===============================================
    # Get-TerraformState - Query Terraform state
    # ===============================================

    <#
    .SYNOPSIS
        Queries Terraform state.
    
    .DESCRIPTION
        Queries Terraform state file to get information about managed resources.
        Supports various output formats and filtering options.
    
    .PARAMETER ResourceAddress
        Optional resource address to query. If not specified, lists all resources.
    
    .PARAMETER OutputFormat
        Output format: json, raw. Defaults to raw.
    
    .PARAMETER StateFile
        Optional path to state file. Defaults to terraform.tfstate in current directory.
    
    .PARAMETER Tool
        Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).
    
    .EXAMPLE
        Get-TerraformState
        
        Lists all resources in the state file.
    
    .EXAMPLE
        Get-TerraformState -ResourceAddress "aws_instance.web" -OutputFormat "json"
        
        Gets specific resource information as JSON.
    
    .OUTPUTS
        System.String. State information in the specified format.
    #>
    function Get-TerraformState {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$ResourceAddress,
            
            [ValidateSet('json', 'raw')]
            [string]$OutputFormat = 'raw',
            
            [string]$StateFile,
            
            [ValidateSet('terraform', 'opentofu', 'auto')]
            [string]$Tool = 'auto'
        )

        $useTerraform = Test-CachedCommand 'terraform'
        $useOpenTofu = Test-CachedCommand 'tofu'

        if ($Tool -eq 'auto') {
            if ($useTerraform) {
                $Tool = 'terraform'
            }
            elseif ($useOpenTofu) {
                $Tool = 'opentofu'
            }
        }

        if (-not $useTerraform -and -not $useOpenTofu) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'terraform' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'terraform' -InstallHint $installHint
            }
            else {
                Write-Warning "terraform is not installed. Install it with: scoop install terraform"
            }
            return
        }

        $command = if ($Tool -eq 'opentofu' -and $useOpenTofu) { 'tofu' } else { 'terraform' }
        
        $stateArgs = @('state', 'show')
        
        if ($StateFile) {
            $stateArgs += '-state', $StateFile
        }
        
        if ($OutputFormat -eq 'json') {
            $stateArgs += '-json'
        }
        
        if ($ResourceAddress) {
            $stateArgs += $ResourceAddress
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'iac.terraform.state.query' -Context @{
                tool             = $Tool
                resource_address = $ResourceAddress
                output_format    = $OutputFormat
                state_file       = $StateFile
            } -ScriptBlock {
                $output = & $command $stateArgs 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "State query failed. Exit code: $LASTEXITCODE"
                }
                return $output
            }
        }
        else {
            try {
                $output = & $command $stateArgs 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "State query failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to query state: $_"
            }
        }
    }

    # ===============================================
    # Invoke-Pulumi - Pulumi wrapper
    # ===============================================

    <#
    .SYNOPSIS
        Executes Pulumi commands.
    
    .DESCRIPTION
        Wrapper function for Pulumi, an infrastructure as code tool that supports
        multiple programming languages.
    
    .PARAMETER Arguments
        Arguments to pass to pulumi.
    
    .EXAMPLE
        Invoke-Pulumi preview
        
        Previews Pulumi changes.
    
    .EXAMPLE
        Invoke-Pulumi up --yes
        
        Applies Pulumi changes automatically.
    #>
    function Invoke-Pulumi {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'pulumi')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'pulumi' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'pulumi' -InstallHint $installHint
            }
            else {
                Write-Warning "pulumi is not installed. Install it with: scoop install pulumi"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'iac.pulumi.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                pulumi @Arguments
            } | Out-Null
        }
        else {
            try {
                pulumi @Arguments
            }
            catch {
                Write-Error "Failed to run pulumi: $_"
            }
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Invoke-Terragrunt' -Body ${function:Invoke-Terragrunt}
        Set-AgentModeFunction -Name 'Invoke-OpenTofu' -Body ${function:Invoke-OpenTofu}
        Set-AgentModeFunction -Name 'Plan-Infrastructure' -Body ${function:Plan-Infrastructure}
        Set-AgentModeFunction -Name 'Apply-Infrastructure' -Body ${function:Apply-Infrastructure}
        Set-AgentModeFunction -Name 'Get-TerraformState' -Body ${function:Get-TerraformState}
        Set-AgentModeFunction -Name 'Invoke-Pulumi' -Body ${function:Invoke-Pulumi}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Invoke-Terragrunt -Value ${function:Invoke-Terragrunt} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-OpenTofu -Value ${function:Invoke-OpenTofu} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Plan-Infrastructure -Value ${function:Plan-Infrastructure} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Apply-Infrastructure -Value ${function:Apply-Infrastructure} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-TerraformState -Value ${function:Get-TerraformState} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-Pulumi -Value ${function:Invoke-Pulumi} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'iac-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: iac-tools" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load iac-tools fragment: $($_.Exception.Message)"
    }
}
