# ===============================================
# network-analysis.tests.ps1
# Integration tests for network-analysis.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'network-analysis.ps1')
}

Describe 'network-analysis.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'network-analysis.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'network-analysis.ps1')
            . (Join-Path $script:ProfileDir 'network-analysis.ps1')
        } | Should -Not -Throw
    }
}

Describe 'network-analysis.ps1 - Function Registration' {
    It 'Registers Start-Wireshark function' {
        Get-Command -Name 'Start-Wireshark' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-NetworkScan function' {
        Get-Command -Name 'Invoke-NetworkScan' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-IpInfo function' {
        Get-Command -Name 'Get-IpInfo' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Start-CloudflareTunnel function' {
        Get-Command -Name 'Start-CloudflareTunnel' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Send-NtfyNotification function' {
        Get-Command -Name 'Send-NtfyNotification' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'network-analysis.ps1 - Graceful Degradation' {
    It 'Start-Wireshark handles missing tool gracefully' {
        { Start-Wireshark -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-NetworkScan handles missing tool gracefully' {
        { Invoke-NetworkScan -Target '192.168.1.1' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Get-IpInfo handles missing tool gracefully' {
        { Get-IpInfo -IpAddress '8.8.8.8' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Start-CloudflareTunnel handles missing tool gracefully' {
        { Start-CloudflareTunnel -Url 'http://localhost:8080' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Send-NtfyNotification handles missing tool gracefully' {
        { Send-NtfyNotification -Message 'Test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

