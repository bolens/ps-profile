# ===============================================
# CloudProviderBase.ps1
# Base module for cloud provider CLI wrappers
# ===============================================

<#
.SYNOPSIS
    Base module providing common patterns for cloud provider CLI wrappers.

.DESCRIPTION
    Extracts common patterns from AWS, Azure, and GCloud modules to reduce duplication.
    Provides abstract functions that cloud-specific modules can use or extend.
    
    Common Patterns:
    1. Command execution with tool detection
    2. Profile/account/configuration management
    3. Resource listing with JSON parsing
    4. Credential management and connection testing
    5. Error handling and output formatting

.NOTES
    This is a base module. Cloud-specific modules (aws.ps1, azure.ps1, gcloud.ps1)
    should use these functions or extend them with provider-specific logic.
#>

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'cloud-provider-base') { return }
    }

    # ===============================================
    # Invoke-CloudCommand - Base command execution
    # ===============================================

    <#
    .SYNOPSIS
        Executes a cloud provider CLI command with standardized error handling.
    
    .DESCRIPTION
        Base function for executing cloud provider CLI commands. Handles:
        - Tool detection using Test-CachedCommand
        - Missing tool warnings
        - Error handling and output parsing
        - Wide event tracking (if available)
    
    .PARAMETER CommandName
        Name of the CLI command (e.g., 'aws', 'az', 'gcloud').
    
    .PARAMETER Arguments
        Arguments to pass to the command.
    
    .PARAMETER OperationName
        Operation name for event tracking (e.g., 'aws.s3.upload').
        If not provided, defaults to "{CommandName}.{FirstArgument}".
    
    .PARAMETER Context
        Additional context for event tracking.
    
    .PARAMETER InstallHint
        Installation hint for missing tool warning.
    
    .PARAMETER ParseJson
        Attempt to parse output as JSON (default: $true).
    
    .PARAMETER ErrorOnNonZeroExit
        Throw error if command exits with non-zero code (default: $true).
    
    .EXAMPLE
        Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -OperationName 'aws.s3.list'
        
        Executes 'aws s3 ls' with event tracking.
    
    .OUTPUTS
        System.Object. Command output (parsed JSON if ParseJson is true, otherwise raw output).
    #>
    function Invoke-CloudCommand {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$CommandName,
            
            [Parameter(Mandatory = $true)]
            [string[]]$Arguments,
            
            [string]$OperationName,
            
            [hashtable]$Context = @{},
            
            [string]$InstallHint,
            
            [bool]$ParseJson = $true,
            
            [bool]$ErrorOnNonZeroExit = $true
        )

        # Check for command availability
        if (-not (Test-CachedCommand $CommandName)) {
            $hint = if ($InstallHint) { $InstallHint } else { "Install with: scoop install $CommandName" }
            Write-MissingToolWarning -Tool $CommandName -InstallHint $hint
            return $null
        }

        # Generate operation name if not provided
        if (-not $OperationName) {
            $firstArg = if ($Arguments.Count -gt 0) { $Arguments[0] } else { 'command' }
            $OperationName = "$CommandName.$firstArg"
        }

        # Build context
        $eventContext = $Context.Clone()
        $eventContext.command = $CommandName
        $eventContext.arguments = $Arguments -join ' '

        # Execute with wide event tracking if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName $OperationName -Context $eventContext -ScriptBlock {
                $output = & $CommandName @Arguments 2>&1
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -ne 0 -and $ErrorOnNonZeroExit) {
                    $errorMessage = if ($output -is [string]) { $output } else { ($output | Out-String) }
                    throw "Command '$CommandName' failed with exit code $exitCode : $errorMessage"
                }
                
                # Parse JSON if requested and output looks like JSON
                if ($ParseJson -and $output -is [string] -and $output.Trim().StartsWith('{') -or $output.Trim().StartsWith('[')) {
                    try {
                        return $output | ConvertFrom-Json
                    }
                    catch {
                        # If JSON parsing fails, return raw output
                        return $output
                    }
                }
                
                return $output
            }
        }
        else {
            # Fallback: execute without wide event tracking
            try {
                $output = & $CommandName @Arguments 2>&1
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -ne 0 -and $ErrorOnNonZeroExit) {
                    $errorMessage = if ($output -is [string]) { $output } else { ($output | Out-String) }
                    Write-Error "Command '$CommandName' failed with exit code $exitCode : $errorMessage"
                    return $null
                }
                
                # Parse JSON if requested
                if ($ParseJson -and $output -is [string] -and ($output.Trim().StartsWith('{') -or $output.Trim().StartsWith('['))) {
                    try {
                        return $output | ConvertFrom-Json
                    }
                    catch {
                        return $output
                    }
                }
                
                return $output
            }
            catch {
                Write-Error "Failed to execute $CommandName : $_"
                return $null
            }
        }
    }

    # ===============================================
    # Set-CloudProfile - Base profile/account/config management
    # ===============================================

    <#
    .SYNOPSIS
        Sets cloud provider profile, account, or configuration.
    
    .DESCRIPTION
        Base function for managing cloud provider profiles/accounts/configurations.
        Handles environment variable setting and validation.
    
    .PARAMETER ProviderName
        Provider name (e.g., 'aws', 'azure', 'gcloud').
    
    .PARAMETER ProfileType
        Type of profile setting: 'Profile', 'Region', 'Account', 'Project', 'Config'.
    
    .PARAMETER Value
        Value to set.
    
    .PARAMETER EnvVarName
        Environment variable name to set (e.g., 'AWS_PROFILE', 'GCLOUD_PROJECT').
    
    .PARAMETER CommandName
        CLI command name for validation.
    
    .PARAMETER DisplayName
        Display name for the setting (e.g., 'AWS profile', 'GCloud project').
    
    .PARAMETER ValidateCommand
        Optional command to validate the setting (e.g., 'aws sts get-caller-identity').
    
    .EXAMPLE
        Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -DisplayName 'AWS profile'
        
        Sets AWS profile to 'production'.
    
    .OUTPUTS
        System.Boolean. True if successful, false otherwise.
    #>
    function Set-CloudProfile {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ProviderName,
            
            [Parameter(Mandatory = $true)]
            [ValidateSet('Profile', 'Region', 'Account', 'Project', 'Config')]
            [string]$ProfileType,
            
            [Parameter(Mandatory = $true)]
            [string]$Value,
            
            [Parameter(Mandatory = $true)]
            [string]$EnvVarName,
            
            [string]$CommandName,
            
            [string]$DisplayName,
            
            [string]$ValidateCommand
        )

        # Check command availability if specified
        if ($CommandName -and -not (Test-CachedCommand $CommandName)) {
            Write-MissingToolWarning -Tool $CommandName -InstallHint "Install with: scoop install $CommandName"
            return $false
        }

        # Set environment variable
        Set-Item -Path "Env:$EnvVarName" -Value $Value -ErrorAction Stop
        
        $display = if ($DisplayName) { $DisplayName } else { "$ProviderName $ProfileType" }
        Write-Host "$display set to: $Value" -ForegroundColor Green

        # Validate if command provided
        if ($ValidateCommand -and $CommandName) {
            try {
                $validationResult = Invoke-CloudCommand -CommandName $CommandName -Arguments ($ValidateCommand -split ' ') -ParseJson $true -ErrorOnNonZeroExit $false
                if ($validationResult) {
                    Write-Host "Validation successful." -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Warning "Validation failed. Setting applied but may not be valid."
                    return $false
                }
            }
            catch {
                Write-Warning "Validation command failed: $_"
                return $false
            }
        }

        return $true
    }

    # ===============================================
    # Get-CloudResources - Base resource listing
    # ===============================================

    <#
    .SYNOPSIS
        Lists cloud provider resources using service/action pattern.
    
    .DESCRIPTION
        Base function for listing cloud provider resources. Supports:
        - Service/Action pattern (AWS style)
        - Direct command pattern (Azure/GCloud style)
        - JSON parsing and error handling
    
    .PARAMETER CommandName
        CLI command name (e.g., 'aws', 'az', 'gcloud').
    
    .PARAMETER Service
        Service name (e.g., 'ec2', 's3', 'compute').
        Optional for direct command pattern.
    
    .PARAMETER Action
        Action name (e.g., 'describe-instances', 'list-buckets', 'list').
        Optional for direct command pattern.
    
    .PARAMETER Arguments
        Direct arguments (alternative to Service/Action pattern).
    
    .PARAMETER OperationName
        Operation name for event tracking.
    
    .PARAMETER Context
        Additional context for event tracking.
    
    .EXAMPLE
        Get-CloudResources -CommandName 'aws' -Service 'ec2' -Action 'describe-instances' -OperationName 'aws.ec2.list'
        
        Lists EC2 instances.
    
    .OUTPUTS
        System.Object. Resource list (parsed JSON or raw output).
    #>
    function Get-CloudResources {
        [CmdletBinding()]
        [OutputType([object])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$CommandName,
            
            [string]$Service,
            
            [string]$Action,
            
            [string[]]$Arguments,
            
            [string]$OperationName,
            
            [hashtable]$Context = @{}
        )

        # Build arguments
        $cmdArgs = @()
        if ($Service -and $Action) {
            # Service/Action pattern (AWS style)
            $cmdArgs = @($Service, $Action)
            if (-not $OperationName) {
                $OperationName = "$CommandName.$Service.$Action"
            }
        }
        elseif ($Arguments) {
            # Direct arguments pattern (Azure/GCloud style)
            $cmdArgs = $Arguments
            if (-not $OperationName) {
                $firstArg = if ($Arguments.Count -gt 0) { $Arguments[0] } else { 'list' }
                $OperationName = "$CommandName.$firstArg"
            }
        }
        else {
            Write-Error "Either Service/Action or Arguments must be provided."
            return $null
        }

        # Build context
        $eventContext = $Context.Clone()
        $eventContext.service = $Service
        $eventContext.action = $Action

        # Execute command
        return Invoke-CloudCommand -CommandName $CommandName -Arguments $cmdArgs -OperationName $OperationName -Context $eventContext -ParseJson $true
    }

    # ===============================================
    # Test-CloudConnection - Base connection testing
    # ===============================================

    <#
    .SYNOPSIS
        Tests connection to cloud provider.
    
    .DESCRIPTION
        Base function for testing cloud provider connections.
        Executes a validation command and parses the response.
    
    .PARAMETER CommandName
        CLI command name (e.g., 'aws', 'az', 'gcloud').
    
    .PARAMETER TestCommand
        Command to test connection (e.g., 'sts get-caller-identity', 'account show').
    
    .PARAMETER ParseJson
        Parse response as JSON (default: $true).
    
    .PARAMETER SuccessIndicator
        Property path to check for success (e.g., 'Account', 'id').
        If provided, checks if this property exists in the response.
    
    .PARAMETER OperationName
        Operation name for event tracking.
    
    .PARAMETER Context
        Additional context for event tracking.
    
    .EXAMPLE
        Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'
        
        Tests AWS connection by checking caller identity.
    
    .OUTPUTS
        System.Boolean. True if connection successful, false otherwise.
    #>
    function Test-CloudConnection {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$CommandName,
            
            [Parameter(Mandatory = $true)]
            [string[]]$TestCommand,
            
            [bool]$ParseJson = $true,
            
            [string]$SuccessIndicator,
            
            [string]$OperationName,
            
            [hashtable]$Context = @{}
        )

        if (-not $OperationName) {
            $OperationName = "$CommandName.connection.test"
        }

        try {
            $result = Invoke-CloudCommand -CommandName $CommandName -Arguments $TestCommand -OperationName $OperationName -Context $Context -ParseJson $ParseJson -ErrorOnNonZeroExit $false
            
            if (-not $result) {
                Write-Warning "$CommandName connection test failed: No response"
                return $false
            }

            # Check success indicator if provided
            if ($SuccessIndicator) {
                $indicatorValue = $result
                $pathParts = $SuccessIndicator -split '\.'
                foreach ($part in $pathParts) {
                    if ($indicatorValue -and $indicatorValue.PSObject.Properties[$part]) {
                        $indicatorValue = $indicatorValue.$part
                    }
                    else {
                        Write-Warning "$CommandName connection test failed: Success indicator '$SuccessIndicator' not found"
                        return $false
                    }
                }
                
                Write-Host "$CommandName connection successful. $SuccessIndicator : $indicatorValue" -ForegroundColor Green
                return $true
            }
            else {
                # If no success indicator, assume success if we got a result
                Write-Host "$CommandName connection successful." -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Warning "$CommandName connection test failed: $_"
            return $false
        }
    }

    # Register functions
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Invoke-CloudCommand' -Body ${function:Invoke-CloudCommand}
        Set-AgentModeFunction -Name 'Set-CloudProfile' -Body ${function:Set-CloudProfile}
        Set-AgentModeFunction -Name 'Get-CloudResources' -Body ${function:Get-CloudResources}
        Set-AgentModeFunction -Name 'Test-CloudConnection' -Body ${function:Test-CloudConnection}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Invoke-CloudCommand -Value ${function:Invoke-CloudCommand} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Set-CloudProfile -Value ${function:Set-CloudProfile} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-CloudResources -Value ${function:Get-CloudResources} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Test-CloudConnection -Value ${function:Test-CloudConnection} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'cloud-provider-base'
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName "cloud-provider-base.load" -Context @{
            fragment      = 'cloud-provider-base'
            fragment_type = 'base-module'
        }
    }
    elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
        Handle-FragmentError -ErrorRecord $_ -Context "Fragment: cloud-provider-base"
    }
    elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: cloud-provider-base" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load cloud-provider-base fragment: $($_.Exception.Message)"
    }
}
