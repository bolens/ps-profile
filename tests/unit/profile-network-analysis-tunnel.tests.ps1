# ===============================================
# profile-network-analysis-tunnel.tests.ps1
# Unit tests for Start-CloudflareTunnel and Send-NtfyNotification functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'network-analysis.ps1')
}

Describe 'network-analysis.ps1 - Start-CloudflareTunnel' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'cloudflared' -Available $false
        Remove-Item -Path 'Function:\cloudflared' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:cloudflared' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when cloudflared is not available' {
            $result = Start-CloudflareTunnel -Url 'http://localhost:8080' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cloudflared with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'cloudflared'

            Start-CloudflareTunnel -Url 'http://localhost:8080' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'tunnel'
            $args | Should -Contain '--url'
            $args | Should -Contain 'http://localhost:8080'
        }

        It 'Calls cloudflared with hostname' {
            Setup-CapturingCommandMock -CommandName 'cloudflared'

            Start-CloudflareTunnel -Url 'http://localhost:8080' -Hostname 'example.com' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--hostname'
            $args | Should -Contain 'example.com'
        }

        It 'Calls cloudflared with protocol' {
            Setup-CapturingCommandMock -CommandName 'cloudflared'

            Start-CloudflareTunnel -Url 'tcp://localhost:22' -Protocol 'ssh' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--protocol'
            $args | Should -Contain 'ssh'
        }
    }
}

Describe 'network-analysis.ps1 - Send-NtfyNotification' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'ntfy' -Available $false
        Remove-Item -Path 'Function:\ntfy' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:ntfy' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when ntfy is not available' {
            $result = Send-NtfyNotification -Message 'Test message' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls ntfy with message' {
            Setup-CapturingCommandMock -CommandName 'ntfy' -Output 'Notification sent'

            $result = Send-NtfyNotification -Message 'Test message' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'publish'
            $args | Should -Contain 'Test message'
            $result | Should -Be 'Notification sent'
        }

        It 'Calls ntfy with topic' {
            Setup-CapturingCommandMock -CommandName 'ntfy' -Output 'Notification sent'

            Send-NtfyNotification -Message 'Test message' -Topic 'alerts' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'alerts'
        }

        It 'Calls ntfy with title and priority' {
            Setup-CapturingCommandMock -CommandName 'ntfy' -Output 'Notification sent'

            Send-NtfyNotification -Message 'Test message' -Title 'Alert' -Priority 'urgent' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--title'
            $args | Should -Contain 'Alert'
            $args | Should -Contain '--priority'
            $args | Should -Contain 'urgent'
        }

        It 'Handles ntfy execution errors' {
            Setup-CapturingCommandMock -CommandName 'ntfy' -ExitCode 1

            { Send-NtfyNotification -Message 'Test message' -ErrorAction Stop } | Should -Throw
        }
    }
}
