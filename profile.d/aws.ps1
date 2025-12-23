# ===============================================
# aws.ps1
# AWS CLI helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: cloud, development

<#
.SYNOPSIS
    AWS CLI helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common AWS CLI operations.
    Functions check for aws availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Aws
    Author: PowerShell Profile
#>

# AWS execute - run aws with arguments
<#
.SYNOPSIS
    Executes AWS CLI commands.

.DESCRIPTION
    Wrapper function for AWS CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to aws.

.EXAMPLE
    Invoke-Aws s3 ls

.EXAMPLE
    Invoke-Aws ec2 describe-instances
#>
function Invoke-Aws {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand aws) {
        aws @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
    }
}

# AWS profile switcher - set AWS profile
<#
.SYNOPSIS
    Sets the AWS profile environment variable.

.DESCRIPTION
    Sets the AWS_PROFILE environment variable to the specified profile name.

.PARAMETER ProfileName
    Name of the AWS profile to use.

.EXAMPLE
    Set-AwsProfile -ProfileName "production"

.EXAMPLE
    Set-AwsProfile -ProfileName "development"
#>
function Set-AwsProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ProfileName
    )
    
    if (Test-CachedCommand aws) {
        $env:AWS_PROFILE = $ProfileName
        Write-Host "AWS profile set to: $ProfileName"
    }
    else {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
    }
}

# AWS region switcher - set AWS region
<#
.SYNOPSIS
    Sets the AWS region environment variable.

.DESCRIPTION
    Sets the AWS_REGION environment variable to the specified region.

.PARAMETER Region
    AWS region name (e.g., "us-east-1", "eu-west-1").

.EXAMPLE
    Set-AwsRegion -Region "us-east-1"

.EXAMPLE
    Set-AwsRegion -Region "eu-west-1"
#>
function Set-AwsRegion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Region
    )
    
    if (Test-CachedCommand aws) {
        $env:AWS_REGION = $Region
        Write-Host "AWS region set to: $Region"
    }
    else {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aws' -Target 'Invoke-Aws'
    Set-AgentModeAlias -Name 'aws-profile' -Target 'Set-AwsProfile'
    Set-AgentModeAlias -Name 'aws-region' -Target 'Set-AwsRegion'
}
else {
    Set-Alias -Name 'aws' -Value 'Invoke-Aws' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-profile' -Value 'Set-AwsProfile' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-region' -Value 'Set-AwsRegion' -ErrorAction SilentlyContinue
}
