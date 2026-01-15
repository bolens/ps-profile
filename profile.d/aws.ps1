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
    Functions check for aws availability using Test-CachedCommand for efficient
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
    
    # Use base module if available, otherwise fallback to direct execution
    if (Get-Command Invoke-CloudCommand -ErrorAction SilentlyContinue) {
        return Invoke-CloudCommand -CommandName 'aws' -Arguments $Arguments -ParseJson $false -ErrorOnNonZeroExit $false -InstallHint 'Install with: scoop install aws'
    }
    else {
        # Fallback to original implementation
        if (Test-CachedCommand aws) {
            aws @Arguments
        }
        else {
            Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        }
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
    
    # Use base module if available
    if (Get-Command Set-CloudProfile -ErrorAction SilentlyContinue) {
        return Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value $ProfileName -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -DisplayName 'AWS profile' -InstallHint 'Install with: scoop install aws'
    }
    else {
        # Fallback to original implementation
        if (Test-CachedCommand aws) {
            $env:AWS_PROFILE = $ProfileName
            Write-Host "AWS profile set to: $ProfileName"
        }
        else {
            Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        }
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
    
    # Use base module if available
    if (Get-Command Set-CloudProfile -ErrorAction SilentlyContinue) {
        return Set-CloudProfile -ProviderName 'aws' -ProfileType 'Region' -Value $Region -EnvVarName 'AWS_REGION' -CommandName 'aws' -DisplayName 'AWS region' -InstallHint 'Install with: scoop install aws'
    }
    else {
        # Fallback to original implementation
        if (Test-CachedCommand aws) {
            $env:AWS_REGION = $Region
            Write-Host "AWS region set to: $Region"
        }
        else {
            Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        }
    }
}

# ===============================================
# Get-AwsCredentials - List configured profiles
# ===============================================

<#
.SYNOPSIS
    Lists configured AWS credential profiles.

.DESCRIPTION
    Retrieves a list of all configured AWS profiles from the credentials file.
    Shows profile names and optionally their access key IDs.

.PARAMETER ShowKeys
    Show access key IDs (partially masked) for each profile.

.EXAMPLE
    Get-AwsCredentials
    
    Lists all configured AWS profiles.

.EXAMPLE
    Get-AwsCredentials -ShowKeys
    
    Lists profiles with partially masked access key IDs.

.OUTPUTS
    System.Object[]. Array of profile information objects.
#>
function Get-AwsCredentials {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [switch]$ShowKeys
    )
    
    if (-not (Test-CachedCommand aws)) {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        return
    }
    
    try {
        $profiles = @()
        $credentialsPath = Join-Path $env:USERPROFILE '.aws' 'credentials'
        
        if (Test-Path -LiteralPath $credentialsPath) {
            $content = Get-Content -LiteralPath $credentialsPath
            $currentProfile = $null
            
            foreach ($line in $content) {
                if ($line -match '^\s*\[(.+)\]\s*$') {
                    if ($currentProfile) {
                        $profiles += $currentProfile
                    }
                    $currentProfile = [PSCustomObject]@{
                        ProfileName = $matches[1]
                        AccessKeyId = $null
                    }
                }
                elseif ($currentProfile -and $line -match '^\s*aws_access_key_id\s*=\s*(.+)\s*$') {
                    $keyId = $matches[1].Trim()
                    if ($ShowKeys) {
                        # Mask middle part of key ID
                        if ($keyId.Length -gt 8) {
                            $currentProfile.AccessKeyId = $keyId.Substring(0, 4) + '****' + $keyId.Substring($keyId.Length - 4)
                        }
                        else {
                            $currentProfile.AccessKeyId = '****'
                        }
                    }
                }
            }
            
            if ($currentProfile) {
                $profiles += $currentProfile
            }
        }
        else {
            # Fallback: try to get profiles from AWS CLI
            $output = aws configure list-profiles 2>&1
            if ($LASTEXITCODE -eq 0) {
                foreach ($profileName in $output) {
                    $profiles += [PSCustomObject]@{
                        ProfileName = $profileName.Trim()
                        AccessKeyId = $null
                    }
                }
            }
        }
        
        return $profiles
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "aws.credentials.list" -Context @{
                show_keys = $ShowKeys.IsPresent
            }
        }
        else {
            Write-Error "Failed to get AWS credentials: $_"
        }
    }
}

# ===============================================
# Test-AwsConnection - Test AWS connectivity
# ===============================================

<#
.SYNOPSIS
    Tests AWS connectivity and credentials.

.DESCRIPTION
    Verifies that AWS CLI can connect to AWS and that credentials are valid.
    Uses sts get-caller-identity to test authentication.

.PARAMETER Profile
    Optional AWS profile to test. Uses current profile if not specified.

.EXAMPLE
    Test-AwsConnection
    
    Tests connectivity with the current AWS profile.

.EXAMPLE
    Test-AwsConnection -Profile "production"
    
    Tests connectivity with the specified profile.

.OUTPUTS
    System.Boolean. True if connection is successful, false otherwise.
#>
function Test-AwsConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$Profile
    )
    
    if (-not (Test-CachedCommand aws)) {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        return $false
    }
    
    # Use base module if available
    if (Get-Command Test-CloudConnection -ErrorAction SilentlyContinue) {
        $testCommand = @('sts', 'get-caller-identity')
        if ($Profile) {
            $testCommand += '--profile', $Profile
        }
        
        $result = Test-CloudConnection -CommandName 'aws' -TestCommand $testCommand -SuccessIndicator 'Account' -OperationName "aws.connection.test" -Context @{
            profile = $Profile
        } -InstallHint 'Install with: scoop install aws'
        
        return $result
    }
    else {
        # Fallback to original implementation
        try {
            $arguments = @('sts', 'get-caller-identity')
            
            if ($Profile) {
                $arguments += '--profile', $Profile
            }
            
            $output = aws $arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                $identity = $output | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($identity) {
                    Write-Host "AWS connection successful. Account: $($identity.Account), User: $($identity.Arn)" -ForegroundColor Green
                    return $true
                }
            }
            else {
                Write-Warning "AWS connection failed: $output"
                return $false
            }
        }
        catch {
            Write-Error "Failed to test AWS connection: $_"
            return $false
        }
    }
}

# ===============================================
# Get-AwsResources - List AWS resources by type
# ===============================================

<#
.SYNOPSIS
    Lists AWS resources by type.

.DESCRIPTION
    Retrieves a list of AWS resources of a specified type using AWS CLI.
    Supports common resource types like EC2 instances, S3 buckets, etc.

.PARAMETER ResourceType
    AWS resource type (e.g., 'ec2', 's3', 'lambda', 'rds').

.PARAMETER Service
    AWS service name (e.g., 'ec2', 's3', 'lambda').

.PARAMETER Action
    Service action to list resources (e.g., 'describe-instances', 'list-buckets').

.EXAMPLE
    Get-AwsResources -Service 'ec2' -Action 'describe-instances'
    
    Lists EC2 instances.

.EXAMPLE
    Get-AwsResources -Service 's3' -Action 'list-buckets'
    
    Lists S3 buckets.

.OUTPUTS
    System.Object. Resource list from AWS CLI.
#>
function Get-AwsResources {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $true)]
        [string]$Action
    )
    
    if (-not (Test-CachedCommand aws)) {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        return
    }
    
    # Use base module if available
    if (Get-Command Get-CloudResources -ErrorAction SilentlyContinue) {
        return Get-CloudResources -CommandName 'aws' -Service $Service -Action $Action -OperationName "aws.resources.list" -Context @{
            service = $Service
            action  = $Action
        }
    }
    else {
        # Fallback to original implementation
        try {
            $arguments = @($Service, $Action)
            $output = aws $arguments 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                # Try to parse as JSON, fallback to raw output
                try {
                    return $output | ConvertFrom-Json
                }
                catch {
                    return $output
                }
            }
            else {
                Write-Error "Failed to get AWS resources: $output"
            }
        }
        catch {
            Write-Error "Failed to run AWS command: $_"
        }
    }
}

# ===============================================
# Export-AwsCredentials - Export credentials securely
# ===============================================

<#
.SYNOPSIS
    Exports AWS credentials to environment variables.

.DESCRIPTION
    Exports AWS credentials from a profile to environment variables.
    Useful for scripts that need AWS credentials but don't use profiles.

.PARAMETER Profile
    AWS profile name to export. Uses current profile if not specified.

.PARAMETER ExportToEnv
    Export to environment variables (default). If false, only displays values.

.EXAMPLE
    Export-AwsCredentials -Profile "production"
    
    Exports production profile credentials to environment variables.

.EXAMPLE
    Export-AwsCredentials -Profile "dev" -ExportToEnv:$false
    
    Displays credentials without exporting them.

.OUTPUTS
    System.Object. Credential information object.
#>
function Export-AwsCredentials {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([object])]
    param(
        [string]$Profile,
        
        [switch]$ExportToEnv = $true
    )
    
    if (-not (Test-CachedCommand aws)) {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        return
    }
    
    try {
        $profileArgs = @()
        if ($Profile) {
            $profileArgs = @('--profile', $Profile)
        }
        
        $accessKey = aws configure get aws_access_key_id @profileArgs 2>&1
        $secretKey = aws configure get aws_secret_access_key @profileArgs 2>&1
        $region = aws configure get region @profileArgs 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("Failed to get credentials from profile: $Profile"),
                    "AwsCredentialsError",
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Profile
                )
                Write-StructuredError -ErrorRecord $errorRecord -OperationName "aws.credentials.get" -Context @{
                    profile = $Profile
                }
            }
            else {
                Write-Error "Failed to get credentials from profile: $Profile"
            }
            return
        }
        
        $credentials = [PSCustomObject]@{
            AccessKeyId     = $accessKey.Trim()
            SecretAccessKey = $secretKey.Trim()
            Region          = $region.Trim()
        }
        
        if ($ExportToEnv) {
            if ($PSCmdlet.ShouldProcess("Environment variables", "Export AWS credentials")) {
                $env:AWS_ACCESS_KEY_ID = $credentials.AccessKeyId
                $env:AWS_SECRET_ACCESS_KEY = $credentials.SecretAccessKey
                if ($credentials.Region) {
                    $env:AWS_REGION = $credentials.Region
                }
                Write-Host "AWS credentials exported to environment variables" -ForegroundColor Green
            }
        }
        
        return $credentials
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "aws.credentials.export" -Context @{
                profile = $Profile
            }
        }
        else {
            Write-Error "Failed to export AWS credentials: $_"
        }
    }
}

# ===============================================
# Switch-AwsAccount - Quick account switching
# ===============================================

<#
.SYNOPSIS
    Switches AWS account/profile quickly.

.DESCRIPTION
    A convenience function that combines setting profile and testing connection.
    Sets the AWS profile and verifies connectivity.

.PARAMETER ProfileName
    Name of the AWS profile to switch to.

.PARAMETER SkipTest
    Skip connection test after switching.

.EXAMPLE
    Switch-AwsAccount -ProfileName "production"
    
    Switches to production profile and tests connection.

.EXAMPLE
    Switch-AwsAccount -ProfileName "dev" -SkipTest
    
    Switches to dev profile without testing connection.

.OUTPUTS
    System.Boolean. True if switch and test (if not skipped) are successful.
#>
function Switch-AwsAccount {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileName,
        
        [switch]$SkipTest
    )
    
    if (-not (Test-CachedCommand aws)) {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        return $false
    }
    
    try {
        Set-AwsProfile -ProfileName $ProfileName
        
        if (-not $SkipTest) {
            return Test-AwsConnection -Profile $ProfileName
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to switch AWS account: $_"
        return $false
    }
}

# ===============================================
# Get-AwsCosts - Cost estimation helpers
# ===============================================

<#
.SYNOPSIS
    Gets AWS cost information.

.DESCRIPTION
    Retrieves AWS cost information using AWS Cost Explorer API or billing commands.
    Requires appropriate IAM permissions.

.PARAMETER StartDate
    Start date for cost query (YYYY-MM-DD format). Defaults to first day of current month.

.PARAMETER EndDate
    End date for cost query (YYYY-MM-DD format). Defaults to today.

.PARAMETER Service
    Optional service name to filter costs (e.g., 'EC2', 'S3', 'Lambda').

.EXAMPLE
    Get-AwsCosts
    
    Gets costs for the current month.

.EXAMPLE
    Get-AwsCosts -StartDate "2024-01-01" -EndDate "2024-01-31" -Service "EC2"
    
    Gets EC2 costs for January 2024.

.OUTPUTS
    System.Object. Cost information from AWS.
#>
function Get-AwsCosts {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [string]$StartDate,
        
        [string]$EndDate,
        
        [string]$Service
    )
    
    if (-not (Test-CachedCommand aws)) {
        Write-MissingToolWarning -Tool 'aws' -InstallHint 'Install with: scoop install aws'
        return
    }
    
    try {
        # Default to current month if dates not provided
        if (-not $StartDate) {
            $StartDate = (Get-Date -Day 1).ToString('yyyy-MM-dd')
        }
        
        if (-not $EndDate) {
            $EndDate = (Get-Date).ToString('yyyy-MM-dd')
        }
        
        $arguments = @('ce', 'get-cost-and-usage',
            '--time-period', "Start=$StartDate,End=$EndDate",
            '--granularity', 'MONTHLY',
            '--metrics', 'BlendedCost'
        )
        
        if ($Service) {
            $filterJson = @{
                Dimensions = @{
                    Service = $Service
                }
            } | ConvertTo-Json -Compress
            $arguments += '--filter', $filterJson
        }
        
        $output = aws $arguments 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            try {
                return $output | ConvertFrom-Json
            }
            catch {
                Write-Warning "Failed to parse cost data as JSON. Raw output: $output"
                return $output
            }
        }
        else {
            Write-Warning "AWS Cost Explorer may not be available or you may lack permissions. Error: $output"
            Write-Host "Tip: Ensure you have 'ce:GetCostAndUsage' permission and Cost Explorer is enabled." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "aws.costs.get" -Context @{
                start_date = $StartDate
                end_date   = $EndDate
            }
        }
        else {
            Write-Error "Failed to get AWS costs: $_"
        }
    }
}

# Register new functions
if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Get-AwsCredentials' -Body ${function:Get-AwsCredentials}
    Set-AgentModeFunction -Name 'Test-AwsConnection' -Body ${function:Test-AwsConnection}
    Set-AgentModeFunction -Name 'Get-AwsResources' -Body ${function:Get-AwsResources}
    Set-AgentModeFunction -Name 'Export-AwsCredentials' -Body ${function:Export-AwsCredentials}
    Set-AgentModeFunction -Name 'Switch-AwsAccount' -Body ${function:Switch-AwsAccount}
    Set-AgentModeFunction -Name 'Get-AwsCosts' -Body ${function:Get-AwsCosts}
}
else {
    # Fallback: direct function registration
    Set-Item -Path Function:Get-AwsCredentials -Value ${function:Get-AwsCredentials} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Test-AwsConnection -Value ${function:Test-AwsConnection} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Get-AwsResources -Value ${function:Get-AwsResources} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Export-AwsCredentials -Value ${function:Export-AwsCredentials} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Switch-AwsAccount -Value ${function:Switch-AwsAccount} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Get-AwsCosts -Value ${function:Get-AwsCosts} -Force -ErrorAction SilentlyContinue
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aws' -Target 'Invoke-Aws'
    Set-AgentModeAlias -Name 'aws-profile' -Target 'Set-AwsProfile'
    Set-AgentModeAlias -Name 'aws-region' -Target 'Set-AwsRegion'
    Set-AgentModeAlias -Name 'aws-credentials' -Target 'Get-AwsCredentials'
    Set-AgentModeAlias -Name 'aws-test' -Target 'Test-AwsConnection'
    Set-AgentModeAlias -Name 'aws-switch' -Target 'Switch-AwsAccount'
}
else {
    Set-Alias -Name 'aws' -Value 'Invoke-Aws' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-profile' -Value 'Set-AwsProfile' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-region' -Value 'Set-AwsRegion' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-credentials' -Value 'Get-AwsCredentials' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-test' -Value 'Test-AwsConnection' -ErrorAction SilentlyContinue
    Set-Alias -Name 'aws-switch' -Value 'Switch-AwsAccount' -ErrorAction SilentlyContinue
}
