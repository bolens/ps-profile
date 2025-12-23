# ===============================================
# cloud-enhanced.tests.ps1
# Integration tests for cloud-enhanced.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
}

Describe 'cloud-enhanced.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
            . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
        } | Should -Not -Throw
    }
}

Describe 'cloud-enhanced.ps1 - Function Registration' {
    It 'Registers Set-AzureSubscription function' {
        Get-Command -Name 'Set-AzureSubscription' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Set-GcpProject function' {
        Get-Command -Name 'Set-GcpProject' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-DopplerSecrets function' {
        Get-Command -Name 'Get-DopplerSecrets' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Deploy-Heroku function' {
        Get-Command -Name 'Deploy-Heroku' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Deploy-Vercel function' {
        Get-Command -Name 'Deploy-Vercel' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Deploy-Netlify function' {
        Get-Command -Name 'Deploy-Netlify' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'cloud-enhanced.ps1 - Graceful Degradation' {
    It 'Set-AzureSubscription handles missing tool gracefully' {
        { Set-AzureSubscription -List -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Set-GcpProject handles missing tool gracefully' {
        { Set-GcpProject -List -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Get-DopplerSecrets handles missing tool gracefully' {
        { Get-DopplerSecrets -Project 'test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Deploy-Heroku handles missing tool gracefully' {
        { Deploy-Heroku -AppName 'test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Deploy-Vercel handles missing tool gracefully' {
        { Deploy-Vercel -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Deploy-Netlify handles missing tool gracefully' {
        { Deploy-Netlify -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

