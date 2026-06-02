# ===============================================
# cloud-enhanced.tests.ps1
# Integration tests for cloud-enhanced.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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
    }

    It 'Set-AzureSubscription handles missing tool gracefully' {
        Mock-CommandAvailabilityPester -CommandName 'az' -Available $false
        $output = & { Set-AzureSubscription -List -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'az not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'az'
    }

    It 'Set-GcpProject handles missing tool gracefully' {
        Mock-CommandAvailabilityPester -CommandName 'gcloud' -Available $false
        $output = & { Set-GcpProject -List -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gcloud not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'gcloud'
    }

    It 'Get-DopplerSecrets handles missing tool gracefully' {
        Mock-CommandAvailabilityPester -CommandName 'doppler' -Available $false
        $output = & { Get-DopplerSecrets -Project 'test' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'doppler not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'doppler'
    }

    It 'Deploy-Heroku handles missing tool gracefully' {
        Mock-CommandAvailabilityPester -CommandName 'heroku' -Available $false
        $output = & { Deploy-Heroku -AppName 'test' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'heroku not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'heroku'
    }

    It 'Deploy-Vercel handles missing tool gracefully' {
        Mock-CommandAvailabilityPester -CommandName 'vercel' -Available $false
        $output = & { Deploy-Vercel -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'vercel not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'vercel'
    }

    It 'Deploy-Netlify handles missing tool gracefully' {
        Mock-CommandAvailabilityPester -CommandName 'netlify' -Available $false
        $output = & { Deploy-Netlify -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'netlify not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'netlify'
    }
}

