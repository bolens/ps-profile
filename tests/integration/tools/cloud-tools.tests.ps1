<#
.SYNOPSIS
    Integration tests for cloud tool fragments (AWS, Azure, gcloud).

.DESCRIPTION
    Tests AWS CLI, Azure CLI, and Google Cloud CLI helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Cloud Tools Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize cloud tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'AWS CLI helpers (aws.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'aws' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'aws' } -MockWith { $null }
            # Mock aws command before loading fragment to prevent conflicts
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'aws' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'aws.ps1')
        }

        It 'Creates Invoke-Aws function' {
            try {
                Get-Command Invoke-Aws -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Invoke-Aws function should be created"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Invoke-Aws'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Invoke-Aws function creation test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Creates aws alias for Invoke-Aws' {
            $alias = Get-Alias aws -ErrorAction SilentlyContinue
            if ($null -eq $alias) {
                # Check if function exists as fallback
                Get-Command aws -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
                $alias.ResolvedCommandName | Should -Be 'Invoke-Aws'
            }
        }

        It 'aws alias handles missing tool gracefully and recommends installation' {
            # Re-apply mocks for this specific test
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false -Scope It
            # Also directly mock Test-HasCommand to ensure it takes precedence (working pattern from infrastructure-tools.tests.ps1)
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'aws' } -MockWith { $false }
            # Capture warnings by redirecting warning stream (3) to output stream (1)
            $allOutput = (aws --version 2>&1 3>&1 | Out-String)
            $allOutput | Should -Match 'aws not found'
            $allOutput | Should -Match 'scoop install aws'
        }

        It 'Creates Set-AwsProfile function' {
            Get-Command Set-AwsProfile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates aws-profile alias for Set-AwsProfile' {
            Get-Alias aws-profile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias aws-profile).ResolvedCommandName | Should -Be 'Set-AwsProfile'
        }

        It 'aws-profile alias sets AWS_PROFILE environment variable' {
            if (Get-Command Set-AwsProfile -CommandType Function -ErrorAction SilentlyContinue) {
                $originalProfile = $env:AWS_PROFILE
                try {
                    Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true -Scope It
                    Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'aws' } -MockWith { $true }
                    Mock -CommandName Write-Host -MockWith { }
                    aws-profile 'test-profile'
                    $env:AWS_PROFILE | Should -Be 'test-profile'
                }
                finally {
                    $env:AWS_PROFILE = $originalProfile
                }
            }
        }

        It 'Creates Set-AwsRegion function' {
            Get-Command Set-AwsRegion -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates aws-region alias for Set-AwsRegion' {
            Get-Alias aws-region -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias aws-region).ResolvedCommandName | Should -Be 'Set-AwsRegion'
        }

        It 'aws-region alias sets AWS_REGION environment variable' {
            if (Get-Command Set-AwsRegion -CommandType Function -ErrorAction SilentlyContinue) {
                $originalRegion = $env:AWS_REGION
                try {
                    Mock-CommandAvailabilityPester -CommandName 'aws' -Available $true -Scope It
                    Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'aws' } -MockWith { $true }
                    Mock -CommandName Write-Host -MockWith { }
                    aws-region 'us-east-1'
                    $env:AWS_REGION | Should -Be 'us-east-1'
                }
                finally {
                    $env:AWS_REGION = $originalRegion
                }
            }
        }
    }

    Context 'Azure CLI helpers (azure.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'az' and 'azd' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'az' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'azd' } -MockWith { $null }
            # Mock az and azd commands before loading fragment to prevent conflicts and recursion
            Mock-CommandAvailabilityPester -CommandName 'az' -Available $false -Scope Context
            Mock-CommandAvailabilityPester -CommandName 'azd' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'az' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'azd' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'azure.ps1')
        }

        It 'Creates Invoke-Azure function' {
            Get-Command Invoke-Azure -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates az alias for Invoke-Azure' {
            $alias = Get-Alias az -ErrorAction SilentlyContinue
            if ($null -eq $alias) {
                # Check if function exists as fallback
                Get-Command az -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
                $alias.ResolvedCommandName | Should -Be 'Invoke-Azure'
            }
        }

        It 'az alias handles missing tool gracefully and recommends installation' {
            # Re-apply mocks for this specific test
            Mock-CommandAvailabilityPester -CommandName 'az' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'az' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = az --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'az not found'
            $output | Should -Match 'scoop install azure-cli'
        }

        It 'Creates Invoke-AzureDeveloper function' {
            Get-Command Invoke-AzureDeveloper -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates azd alias for Invoke-AzureDeveloper' {
            $alias = Get-Alias azd -ErrorAction SilentlyContinue
            if ($null -eq $alias) {
                # Check if function exists as fallback
                Get-Command azd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
                $alias.ResolvedCommandName | Should -Be 'Invoke-AzureDeveloper'
            }
        }

        It 'azd alias handles missing tool gracefully and recommends installation' {
            # Re-apply mocks for this specific test to prevent recursion
            Mock-CommandAvailabilityPester -CommandName 'azd' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'azd' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = azd --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'azd not found'
            $output | Should -Match 'scoop install azure-developer-cli'
        }

        It 'Creates Connect-AzureAccount function' {
            Get-Command Connect-AzureAccount -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates az-login alias for Connect-AzureAccount' {
            Get-Alias az-login -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias az-login).ResolvedCommandName | Should -Be 'Connect-AzureAccount'
        }

        It 'az-login alias handles missing tool gracefully and recommends installation' {
            Mock-CommandAvailabilityPester -CommandName 'az' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'az' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = az-login 2>&1 3>&1 | Out-String
            $output | Should -Match 'Azure CLI.*not found'
            $output | Should -Match 'scoop install azure-cli'
        }

        It 'Creates Start-AzureDeveloperUp function' {
            Get-Command Start-AzureDeveloperUp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates azd-up alias for Start-AzureDeveloperUp' {
            Get-Alias azd-up -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias azd-up).ResolvedCommandName | Should -Be 'Start-AzureDeveloperUp'
        }

        It 'azd-up alias handles missing tool gracefully and recommends installation' {
            Mock-CommandAvailabilityPester -CommandName 'azd' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'azd' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = azd-up 2>&1 3>&1 | Out-String
            $output | Should -Match 'Azure Developer CLI.*not found'
            $output | Should -Match 'scoop install azure-developer-cli'
        }
    }

    Context 'Google Cloud CLI helpers (gcloud.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'gcloud.ps1')
        }

        It 'Creates Invoke-GCloud function' {
            Get-Command Invoke-GCloud -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gcloud alias for Invoke-GCloud' {
            Get-Alias gcloud -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gcloud).ResolvedCommandName | Should -Be 'Invoke-GCloud'
        }

        It 'gcloud alias handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gcloud' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = gcloud --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'gcloud not found'
        }

        It 'Creates Set-GCloudAuth function' {
            Get-Command Set-GCloudAuth -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gcloud-auth alias for Set-GCloudAuth' {
            Get-Alias gcloud-auth -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gcloud-auth).ResolvedCommandName | Should -Be 'Set-GCloudAuth'
        }

        It 'gcloud-auth alias handles missing tool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gcloud' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = gcloud-auth login 2>&1 3>&1 | Out-String
            $output | Should -Match 'Google Cloud CLI.*not found'
        }

        It 'Creates Set-GCloudConfig function' {
            Get-Command Set-GCloudConfig -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gcloud-config alias for Set-GCloudConfig' {
            Get-Alias gcloud-config -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gcloud-config).ResolvedCommandName | Should -Be 'Set-GCloudConfig'
        }

        It 'gcloud-config alias handles missing tool gracefully' {
            # Clear warning cache to ensure warning is shown (cache key is the Tool parameter value)
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('Google Cloud CLI (gcloud)', [ref]$null)
                $null = $global:MissingToolWarnings.TryRemove('gcloud', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gcloud' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = gcloud-config list 2>&1 3>&1 | Out-String
            $output | Should -Match 'Google Cloud CLI.*not found'
        }

        It 'Creates Get-GCloudProjects function' {
            Get-Command Get-GCloudProjects -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gcloud-projects alias for Get-GCloudProjects' {
            Get-Alias gcloud-projects -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gcloud-projects).ResolvedCommandName | Should -Be 'Get-GCloudProjects'
        }

        It 'gcloud-projects alias handles missing tool gracefully' {
            # Clear warning cache to ensure warning is shown (cache key is the Tool parameter value)
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('Google Cloud CLI (gcloud)', [ref]$null)
                $null = $global:MissingToolWarnings.TryRemove('gcloud', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gcloud' } -MockWith { $false }
            # Capture both stderr and warning stream (3>&1 redirects warnings to stdout)
            $output = gcloud-projects list 2>&1 3>&1 | Out-String
            $output | Should -Match 'Google Cloud CLI.*not found'
        }
    }
}

