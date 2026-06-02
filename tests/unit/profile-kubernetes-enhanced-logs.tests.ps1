# ===============================================
# profile-kubernetes-enhanced-logs.tests.ps1
# Unit tests for Tail-KubeLogs function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Tail-KubeLogs' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('stern', 'kubectl')
    }

    Context 'Tool not available' {
        It 'Returns null when neither stern nor kubectl is available' {
            $result = Tail-KubeLogs -Pattern 'my-app' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'stern available' {
        It 'Calls stern with pattern' {
            Setup-CapturingCommandMock -CommandName 'stern' -Output 'Log output'

            Tail-KubeLogs -Pattern 'my-app' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'my-app'
            $args | Should -Contain '--tail'
            $args | Should -Contain '0'
        }

        It 'Calls stern with namespace and container' {
            Setup-CapturingCommandMock -CommandName 'stern' -Output 'Log output'

            Tail-KubeLogs -Pattern 'nginx' -Namespace 'production' -Container 'web' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-n'
            $args | Should -Contain 'production'
            $args | Should -Contain '-c'
            $args | Should -Contain 'web'
        }
    }

    Context 'kubectl fallback' {
        It 'Calls kubectl logs when stern not available' {
            Mark-TestCommandsUnavailable -CommandNames 'stern'
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'Log output'

            Tail-KubeLogs -Pattern 'my-app' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'logs'
            $args | Should -Contain '-f'
            $args | Should -Contain '-l'
            $args | Should -Contain 'app=my-app'
        }
    }
}
