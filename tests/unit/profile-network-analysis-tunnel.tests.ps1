# ===============================================
# profile-network-analysis-tunnel.tests.ps1
# Unit tests for Start-CloudflareTunnel and Send-NtfyNotification functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'network-analysis.ps1')
}

Describe 'network-analysis.ps1 - Start-CloudflareTunnel' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cloudflared', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when cloudflared is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cloudflared' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cloudflared' } -MockWith { return $null }
            
            $result = Start-CloudflareTunnel -Url 'http://localhost:8080' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cloudflared with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'cloudflared'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cloudflared' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            Start-CloudflareTunnel -Url 'http://localhost:8080' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'tunnel'
            $script:capturedArgs | Should -Contain '--url'
            $script:capturedArgs | Should -Contain 'http://localhost:8080'
        }
        
        It 'Calls cloudflared with hostname' {
            Setup-AvailableCommandMock -CommandName 'cloudflared'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cloudflared' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            Start-CloudflareTunnel -Url 'http://localhost:8080' -Hostname 'example.com' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--hostname'
            $script:capturedArgs | Should -Contain 'example.com'
        }
        
        It 'Calls cloudflared with protocol' {
            Setup-AvailableCommandMock -CommandName 'cloudflared'
            
            $script:capturedArgs = $null
            Mock -CommandName 'cloudflared' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            Start-CloudflareTunnel -Url 'tcp://localhost:22' -Protocol 'ssh' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--protocol'
            $script:capturedArgs | Should -Contain 'ssh'
        }
    }
}

Describe 'network-analysis.ps1 - Send-NtfyNotification' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('ntfy', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when ntfy is not available' {
            Mock-CommandAvailabilityPester -CommandName 'ntfy' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'ntfy' } -MockWith { return $null }
            
            $result = Send-NtfyNotification -Message 'Test message' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls ntfy with message' {
            Setup-AvailableCommandMock -CommandName 'ntfy'
            
            $script:capturedArgs = $null
            Mock -CommandName 'ntfy' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Notification sent'
            }
            
            $result = Send-NtfyNotification -Message 'Test message' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'publish'
            $script:capturedArgs | Should -Contain 'Test message'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls ntfy with topic' {
            Setup-AvailableCommandMock -CommandName 'ntfy'
            
            $script:capturedArgs = $null
            Mock -CommandName 'ntfy' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Notification sent'
            }
            
            $result = Send-NtfyNotification -Message 'Test message' -Topic 'alerts' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'alerts'
        }
        
        It 'Calls ntfy with title and priority' {
            Setup-AvailableCommandMock -CommandName 'ntfy'
            
            $script:capturedArgs = $null
            Mock -CommandName 'ntfy' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Notification sent'
            }
            
            $result = Send-NtfyNotification -Message 'Test message' -Title 'Alert' -Priority 'urgent' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--title'
            $script:capturedArgs | Should -Contain 'Alert'
            $script:capturedArgs | Should -Contain '--priority'
            $script:capturedArgs | Should -Contain 'urgent'
        }
        
        It 'Handles ntfy execution errors' {
            Setup-AvailableCommandMock -CommandName 'ntfy'
            
            Mock -CommandName 'ntfy' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Send-NtfyNotification -Message 'Test message' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

