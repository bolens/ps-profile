# ===============================================
# iac-tools.tests.ps1
# Integration tests for terraform.ps1 fragment (IaC helpers)
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'terraform.ps1')
}

Describe 'terraform.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'terraform.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'terraform.ps1')
            . (Join-Path $script:ProfileDir 'terraform.ps1')
        } | Should -Not -Throw
    }
}

Describe 'terraform.ps1 - Function Registration' {
    It 'Registers Invoke-Terraform function' {
        Get-Command -Name 'Invoke-Terraform' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Initialize-Terraform function' {
        Get-Command -Name 'Initialize-Terraform' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-TerraformPlan function' {
        Get-Command -Name 'Get-TerraformPlan' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-TerraformApply function' {
        Get-Command -Name 'Invoke-TerraformApply' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Remove-TerraformInfrastructure function' {
        Get-Command -Name 'Remove-TerraformInfrastructure' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers tf alias' {
        Get-Alias tf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'terraform.ps1 - Graceful Degradation' {
    BeforeEach {
        if ($global:CollectedMissingToolWarnings) {
            $global:CollectedMissingToolWarnings.Clear()
        }
        if ($global:MissingToolWarnings) {
            $global:MissingToolWarnings.Clear()
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        Set-TestCommandAvailabilityState -CommandName 'terraform' -Available $false
    }

    It 'Invoke-Terraform handles missing tool gracefully' {
        $output = & { Invoke-Terraform version -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'terraform not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'terraform'
    }
    
    It 'Initialize-Terraform handles missing tool gracefully' {
        $output = & { Initialize-Terraform -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'terraform not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'terraform'
    }
    
    It 'Get-TerraformPlan handles missing tool gracefully' {
        $output = & { Get-TerraformPlan -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'terraform not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'terraform'
    }
    
    It 'Invoke-TerraformApply handles missing tool gracefully' {
        $output = & { Invoke-TerraformApply -auto-approve -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'terraform not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'terraform'
    }
    
    It 'Remove-TerraformInfrastructure handles missing tool gracefully' {
        $output = & { Remove-TerraformInfrastructure -auto-approve -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'terraform not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'terraform'
    }
}

