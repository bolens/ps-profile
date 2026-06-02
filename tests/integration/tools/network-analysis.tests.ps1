# ===============================================
# network-analysis.tests.ps1
# Integration tests for network-analysis.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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

        foreach ($cmd in @('wireshark', 'sniffnet', 'trippy', 'nali', 'ipinfo', 'cloudflared', 'ntfy')) {
            Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
        }
    }

    It 'Start-Wireshark handles missing tool gracefully' {
        $output = & { Start-Wireshark -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'wireshark not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'wireshark'
    }

    It 'Invoke-NetworkScan handles missing tool gracefully' {
        $output = & { Invoke-NetworkScan -Target '192.168.1.1' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'sniffnet not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'sniffnet'
    }

    It 'Get-IpInfo handles missing tool gracefully' {
        $output = & { Get-IpInfo -IpAddress '8.8.8.8' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'nali not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'nali'
    }

    It 'Start-CloudflareTunnel handles missing tool gracefully' {
        $output = & { Start-CloudflareTunnel -Url 'http://localhost:8080' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'cloudflared not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cloudflared'
    }

    It 'Send-NtfyNotification handles missing tool gracefully' {
        $output = & { Send-NtfyNotification -Message 'Test' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'ntfy not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ntfy'
    }
}

