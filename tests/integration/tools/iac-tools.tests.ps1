# ===============================================
# iac-tools.tests.ps1
# Integration tests for iac-tools.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'iac-tools.ps1')
}

Describe 'iac-tools.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'iac-tools.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'iac-tools.ps1')
            . (Join-Path $script:ProfileDir 'iac-tools.ps1')
        } | Should -Not -Throw
    }
}

Describe 'iac-tools.ps1 - Function Registration' {
    It 'Registers Invoke-Terragrunt function' {
        Get-Command -Name 'Invoke-Terragrunt' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-OpenTofu function' {
        Get-Command -Name 'Invoke-OpenTofu' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Plan-Infrastructure function' {
        Get-Command -Name 'Plan-Infrastructure' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Apply-Infrastructure function' {
        Get-Command -Name 'Apply-Infrastructure' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-TerraformState function' {
        Get-Command -Name 'Get-TerraformState' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-Pulumi function' {
        Get-Command -Name 'Invoke-Pulumi' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'iac-tools.ps1 - Graceful Degradation' {
    It 'Invoke-Terragrunt handles missing tool gracefully' {
        { Invoke-Terragrunt plan -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-OpenTofu handles missing tool gracefully' {
        { Invoke-OpenTofu init -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Plan-Infrastructure handles missing tool gracefully' {
        { Plan-Infrastructure -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Apply-Infrastructure handles missing tool gracefully' {
        { Apply-Infrastructure -ErrorAction SilentlyContinue -WhatIf:$false } | Should -Not -Throw
    }
    
    It 'Get-TerraformState handles missing tool gracefully' {
        { Get-TerraformState -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-Pulumi handles missing tool gracefully' {
        { Invoke-Pulumi preview -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

