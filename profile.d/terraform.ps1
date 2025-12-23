# ===============================================
# terraform.ps1
# Terraform helpers (guarded)
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env
# Environment: cloud, development, iac-tools

<#
.SYNOPSIS
    Terraform helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Terraform operations.
    Functions check for terraform availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Terraform
    Author: PowerShell Profile
#>

# Terraform execute - run terraform with arguments
<#
.SYNOPSIS
    Executes terraform with the specified arguments.

.DESCRIPTION
    Wrapper function for terraform that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to terraform.

.EXAMPLE
    Invoke-Terraform version

.EXAMPLE
    Invoke-Terraform init
#>
function Invoke-Terraform {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand terraform) {
        terraform @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'terraform' -InstallHint 'Install with: scoop install terraform'
    }
}

# Terraform init - initialize working directory
<#
.SYNOPSIS
    Initializes a Terraform working directory.

.DESCRIPTION
    Wrapper for terraform init command.

.PARAMETER Arguments
    Arguments to pass to terraform init.

.EXAMPLE
    Initialize-Terraform

.EXAMPLE
    Initialize-Terraform -upgrade
#>
function Initialize-Terraform {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand terraform) {
        terraform init @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'terraform' -InstallHint 'Install with: scoop install terraform'
    }
}

# Terraform plan - show execution plan
<#
.SYNOPSIS
    Creates a Terraform execution plan.

.DESCRIPTION
    Wrapper for terraform plan command.

.PARAMETER Arguments
    Arguments to pass to terraform plan.

.EXAMPLE
    Get-TerraformPlan

.EXAMPLE
    Get-TerraformPlan -out=tfplan
#>
function Get-TerraformPlan {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand terraform) {
        terraform plan @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'terraform' -InstallHint 'Install with: scoop install terraform'
    }
}

# Terraform apply - apply changes
<#
.SYNOPSIS
    Applies Terraform changes.

.DESCRIPTION
    Wrapper for terraform apply command.

.PARAMETER Arguments
    Arguments to pass to terraform apply.

.EXAMPLE
    Invoke-TerraformApply

.EXAMPLE
    Invoke-TerraformApply -auto-approve
#>
function Invoke-TerraformApply {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand terraform) {
        terraform apply @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'terraform' -InstallHint 'Install with: scoop install terraform'
    }
}

# Terraform destroy - destroy infrastructure
<#
.SYNOPSIS
    Destroys Terraform-managed infrastructure.

.DESCRIPTION
    Wrapper for terraform destroy command.

.PARAMETER Arguments
    Arguments to pass to terraform destroy.

.EXAMPLE
    Remove-TerraformInfrastructure

.EXAMPLE
    Remove-TerraformInfrastructure -auto-approve
#>
function Remove-TerraformInfrastructure {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand terraform) {
        terraform destroy @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'terraform' -InstallHint 'Install with: scoop install terraform'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'tf' -Target 'Invoke-Terraform'
    Set-AgentModeAlias -Name 'tfi' -Target 'Initialize-Terraform'
    Set-AgentModeAlias -Name 'tfp' -Target 'Get-TerraformPlan'
    Set-AgentModeAlias -Name 'tfa' -Target 'Invoke-TerraformApply'
    Set-AgentModeAlias -Name 'tfd' -Target 'Remove-TerraformInfrastructure'
}
else {
    Set-Alias -Name 'tf' -Value 'Invoke-Terraform' -ErrorAction SilentlyContinue
    Set-Alias -Name 'tfi' -Value 'Initialize-Terraform' -ErrorAction SilentlyContinue
    Set-Alias -Name 'tfp' -Value 'Get-TerraformPlan' -ErrorAction SilentlyContinue
    Set-Alias -Name 'tfa' -Value 'Invoke-TerraformApply' -ErrorAction SilentlyContinue
    Set-Alias -Name 'tfd' -Value 'Remove-TerraformInfrastructure' -ErrorAction SilentlyContinue
}
