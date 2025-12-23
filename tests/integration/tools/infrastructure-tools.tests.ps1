

<#
.SYNOPSIS
    Integration tests for infrastructure tool fragments (kubectl, terraform).

.DESCRIPTION
    Tests kubectl and terraform helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Infrastructure Tools Integration Tests' {
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
            Write-Error "Failed to initialize infrastructure tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'kubectl helpers (kubectl.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'kubectl.ps1')
        }

        It 'Creates Invoke-Kubectl function' {
            try {
                Get-Command Invoke-Kubectl -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Invoke-Kubectl function should be created"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Invoke-Kubectl'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Invoke-Kubectl function creation test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Creates k alias for Invoke-Kubectl' {
            Get-Alias k -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias k).ResolvedCommandName | Should -Be 'Invoke-Kubectl'
        }

        It 'k alias handles missing tool gracefully and recommends installation' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false -Scope It
            # Directly mock Test-HasCommand to ensure it takes precedence (working pattern from tfd test)
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'kubectl' } -MockWith { $false }
            $output = k version 2>&1 3>&1 | Out-String
            $output | Should -Match 'kubectl not found'
            $output | Should -Match 'scoop install kubectl'
        }

        It 'Creates Set-KubectlContext function' {
            Get-Command Set-KubectlContext -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates kn alias for Set-KubectlContext' {
            Get-Alias kn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias kn).ResolvedCommandName | Should -Be 'Set-KubectlContext'
        }

        It 'kn alias handles missing kubectl gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'kubectl' } -MockWith { $false }
            $output = kn my-context 2>&1 3>&1 | Out-String
            $output | Should -Match 'kubectl not found'
            $output | Should -Match 'scoop install kubectl'
        }

        It 'Creates Get-KubectlResource function' {
            Get-Command Get-KubectlResource -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates kg alias for Get-KubectlResource' {
            Get-Alias kg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias kg).ResolvedCommandName | Should -Be 'Get-KubectlResource'
        }

        It 'kg alias handles missing kubectl gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'kubectl' } -MockWith { $false }
            $output = kg pods 2>&1 3>&1 | Out-String
            $output | Should -Match 'kubectl not found'
            $output | Should -Match 'scoop install kubectl'
        }

        It 'Creates Describe-KubectlResource function' {
            Get-Command Describe-KubectlResource -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates kd alias for Describe-KubectlResource' {
            Get-Alias kd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias kd).ResolvedCommandName | Should -Be 'Describe-KubectlResource'
        }

        It 'kd alias handles missing kubectl gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'kubectl' } -MockWith { $false }
            $output = kd pod my-pod 2>&1 3>&1 | Out-String
            $output | Should -Match 'kubectl not found'
            $output | Should -Match 'scoop install kubectl'
        }

        It 'Creates Get-KubectlContext function' {
            Get-Command Get-KubectlContext -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates kctx alias for Get-KubectlContext' {
            Get-Alias kctx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias kctx).ResolvedCommandName | Should -Be 'Get-KubectlContext'
        }

        It 'kctx alias handles missing kubectl gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'kubectl' } -MockWith { $false }
            $output = kctx 2>&1 3>&1 | Out-String
            $output | Should -Match 'kubectl not found'
            $output | Should -Match 'scoop install kubectl'
        }
    }

    Context 'Terraform helpers (terraform.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'terraform.ps1')
        }

        It 'Creates Invoke-Terraform function' {
            Get-Command Invoke-Terraform -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates tf alias for Invoke-Terraform' {
            Get-Alias tf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tf).ResolvedCommandName | Should -Be 'Invoke-Terraform'
        }

        It 'tf alias handles missing tool gracefully and recommends installation' {
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'terraform' } -MockWith { $false }
            $output = tf version 2>&1 3>&1 | Out-String
            $output | Should -Match 'terraform not found'
            $output | Should -Match 'scoop install terraform'
        }

        It 'Creates Initialize-Terraform function' {
            Get-Command Initialize-Terraform -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates tfi alias for Initialize-Terraform' {
            Get-Alias tfi -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tfi).ResolvedCommandName | Should -Be 'Initialize-Terraform'
        }

        It 'tfi alias handles missing terraform gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('terraform', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'terraform' } -MockWith { $false }
            $output = tfi 2>&1 3>&1 | Out-String
            $output | Should -Match 'terraform not found'
            $output | Should -Match 'scoop install terraform'
        }

        It 'Creates Get-TerraformPlan function' {
            Get-Command Get-TerraformPlan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates tfp alias for Get-TerraformPlan' {
            Get-Alias tfp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tfp).ResolvedCommandName | Should -Be 'Get-TerraformPlan'
        }

        It 'tfp alias handles missing terraform gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('terraform', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'terraform' } -MockWith { $false }
            $output = tfp 2>&1 3>&1 | Out-String
            $output | Should -Match 'terraform not found'
            $output | Should -Match 'scoop install terraform'
        }

        It 'Creates Invoke-TerraformApply function' {
            Get-Command Invoke-TerraformApply -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates tfa alias for Invoke-TerraformApply' {
            Get-Alias tfa -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tfa).ResolvedCommandName | Should -Be 'Invoke-TerraformApply'
        }

        It 'tfa alias handles missing terraform gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('terraform', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'terraform' } -MockWith { $false }
            $output = tfa 2>&1 3>&1 | Out-String
            $output | Should -Match 'terraform not found'
            $output | Should -Match 'scoop install terraform'
        }

        It 'Creates Remove-TerraformInfrastructure function' {
            Get-Command Remove-TerraformInfrastructure -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates tfd alias for Remove-TerraformInfrastructure' {
            Get-Alias tfd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tfd).ResolvedCommandName | Should -Be 'Remove-TerraformInfrastructure'
        }

        It 'tfd alias handles missing terraform gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('terraform', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'terraform' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'terraform' } -MockWith { $false }
            $output = tfd 2>&1 3>&1 | Out-String
            $output | Should -Match 'terraform not found'
            $output | Should -Match 'scoop install terraform'
        }
    }
}

