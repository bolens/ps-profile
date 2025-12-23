# ===============================================
# profile-cloud-enhanced-deploy.tests.ps1
# Unit tests for deployment functions (Doppler, Heroku, Vercel, Netlify)
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
}

Describe 'cloud-enhanced.ps1 - Get-DopplerSecrets' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('doppler', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when doppler is not available' {
            Mock-CommandAvailabilityPester -CommandName 'doppler' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'doppler' } -MockWith { return $null }
            
            $result = Get-DopplerSecrets -Project 'my-project' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls doppler with project and config' {
            Setup-AvailableCommandMock -CommandName 'doppler'
            
            $script:capturedArgs = $null
            Mock -CommandName 'doppler' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'SECRET=value'
            }
            
            $result = Get-DopplerSecrets -Project 'my-project' -Config 'dev' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'secrets'
            $script:capturedArgs | Should -Contain 'get'
            $script:capturedArgs | Should -Contain '--project'
            $script:capturedArgs | Should -Contain 'my-project'
            $script:capturedArgs | Should -Contain '--config'
            $script:capturedArgs | Should -Contain 'dev'
        }
        
        It 'Calls doppler with JSON format' {
            Setup-AvailableCommandMock -CommandName 'doppler'
            
            $script:capturedArgs = $null
            Mock -CommandName 'doppler' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '{"SECRET": "value"}'
            }
            
            $result = Get-DopplerSecrets -Project 'my-project' -OutputFormat 'json' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--format'
            $script:capturedArgs | Should -Contain 'json'
        }
    }
}

Describe 'cloud-enhanced.ps1 - Deploy-Heroku' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('heroku', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('git', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when heroku is not available' {
            Mock-CommandAvailabilityPester -CommandName 'heroku' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'heroku' } -MockWith { return $null }
            
            $result = Deploy-Heroku -AppName 'my-app' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Deploys using git push for deploy action' {
            Setup-AvailableCommandMock -CommandName 'heroku'
            Setup-AvailableCommandMock -CommandName 'git'
            
            $script:capturedArgs = $null
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Deployed'
            }
            
            $result = Deploy-Heroku -AppName 'my-app' -Action 'deploy' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'push'
            $script:capturedArgs | Should -Contain 'heroku'
        }
        
        It 'Calls heroku logs for logs action' {
            Setup-AvailableCommandMock -CommandName 'heroku'
            
            $script:capturedArgs = $null
            Mock -CommandName 'heroku' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Log output'
            }
            
            $result = Deploy-Heroku -AppName 'my-app' -Action 'logs' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'logs'
            $script:capturedArgs | Should -Contain '--tail'
            $script:capturedArgs | Should -Contain '--app'
            $script:capturedArgs | Should -Contain 'my-app'
        }
    }
}

Describe 'cloud-enhanced.ps1 - Deploy-Vercel' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('vercel', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when vercel is not available' {
            Mock-CommandAvailabilityPester -CommandName 'vercel' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'vercel' } -MockWith { return $null }
            
            $result = Deploy-Vercel -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls vercel deploy' {
            Setup-AvailableCommandMock -CommandName 'vercel'
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = 'C:\Test' } }
            Mock Push-Location { }
            Mock Pop-Location { }
            
            $script:capturedArgs = $null
            Mock -CommandName 'vercel' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Deployed'
            }
            
            $result = Deploy-Vercel -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -BeNullOrEmpty
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls vercel with --prod for production' {
            Setup-AvailableCommandMock -CommandName 'vercel'
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = 'C:\Test' } }
            Mock Push-Location { }
            Mock Pop-Location { }
            
            $script:capturedArgs = $null
            Mock -CommandName 'vercel' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Deployed'
            }
            
            $result = Deploy-Vercel -Production -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--prod'
        }
    }
}

Describe 'cloud-enhanced.ps1 - Deploy-Netlify' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('netlify', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when netlify is not available' {
            Mock-CommandAvailabilityPester -CommandName 'netlify' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'netlify' } -MockWith { return $null }
            
            $result = Deploy-Netlify -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls netlify deploy' {
            Setup-AvailableCommandMock -CommandName 'netlify'
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = 'C:\Test' } }
            Mock Push-Location { }
            Mock Pop-Location { }
            
            $script:capturedArgs = $null
            Mock -CommandName 'netlify' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Deployed'
            }
            
            $result = Deploy-Netlify -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'deploy'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls netlify status for status action' {
            Setup-AvailableCommandMock -CommandName 'netlify'
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = 'C:\Test' } }
            Mock Push-Location { }
            Mock Pop-Location { }
            
            $script:capturedArgs = $null
            Mock -CommandName 'netlify' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Status'
            }
            
            $result = Deploy-Netlify -Action 'status' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'status'
        }
    }
}

