# ===============================================
# profile-cloud-enhanced-azure.tests.ps1
# Unit tests for Set-AzureSubscription function
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
}

Describe 'cloud-enhanced.ps1 - Set-AzureSubscription' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'az' -Available $false
        Remove-Item -Path 'Function:\az' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:az' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when az is not available' {
            $result = Set-AzureSubscription -List -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Lists subscriptions when List is specified' {
            Setup-CapturingCommandMock -CommandName 'az' -Output 'Subscription list'

            $result = Set-AzureSubscription -List -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'account'
            $args | Should -Contain 'list'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Switches subscription when SubscriptionId is specified' {
            Setup-CapturingCommandMock -CommandName 'az' -Output ''

            $result = Set-AzureSubscription -SubscriptionId 'sub-123' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'account'
            $args | Should -Contain 'set'
            $args | Should -Contain 'sub-123'
        }

        It 'Shows current subscription when no parameters' {
            Setup-CapturingCommandMock -CommandName 'az' -Output 'Current subscription'

            $result = Set-AzureSubscription -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'account'
            $args | Should -Contain 'show'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles az execution errors' {
            Setup-CapturingCommandMock -CommandName 'az' -Output '' -ExitCode 1

            { Set-AzureSubscription -List -ErrorAction Stop } | Should -Throw
        }
    }
}
