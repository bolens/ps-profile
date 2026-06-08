# ===============================================
# profile-kubernetes-enhanced-context.tests.ps1
# Unit tests for Set-KubeContext and Set-KubeNamespace functions
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
    . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Set-KubeContext' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('kubectx', 'kubectl')
    }

    Context 'Tool not available' {
        It 'Returns null when neither kubectx nor kubectl is available' {
            $result = Set-KubeContext -List -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'kubectx available' {
        It 'Lists contexts using kubectx' {
            Setup-CapturingCommandMock -CommandName 'kubectx' -OnInvoke { return @('context1', 'context2') }

            $result = Set-KubeContext -List -ErrorAction SilentlyContinue

            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Switches context using kubectx' {
            Setup-CapturingCommandMock -CommandName 'kubectx'

            Set-KubeContext -ContextName 'my-context' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'my-context'
        }
    }

    Context 'kubectl fallback' {
        It 'Lists contexts using kubectl when kubectx not available' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -OnInvoke { return @('context1', 'context2') }
            Mark-TestCommandsUnavailable -CommandNames 'kubectx'

            Test-CachedCommand 'kubectl' | Should -Be $true

            $result = Set-KubeContext -List -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'config'
            $args | Should -Contain 'get-contexts'
            $args | Should -Contain '-o'
            $args | Should -Contain 'name'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Switches context using kubectl when kubectx not available' {
            Setup-CapturingCommandMock -CommandName 'kubectl'
            Mark-TestCommandsUnavailable -CommandNames 'kubectx'

            Set-KubeContext -ContextName 'my-context' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'config'
            $args | Should -Contain 'use-context'
            $args | Should -Contain 'my-context'
        }
    }
}

Describe 'kubernetes-enhanced.ps1 - Set-KubeNamespace' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('kubens', 'kubectl')
    }

    Context 'Tool not available' {
        It 'Returns null when neither kubens nor kubectl is available' {
            $result = Set-KubeNamespace -List -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'kubens available' {
        It 'Lists namespaces using kubens' {
            Setup-CapturingCommandMock -CommandName 'kubens' -OnInvoke { return @('default', 'production') }

            $result = Set-KubeNamespace -List -ErrorAction SilentlyContinue

            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Switches namespace using kubens' {
            Setup-CapturingCommandMock -CommandName 'kubens'

            Set-KubeNamespace -Namespace 'production' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'production'
        }
    }

    Context 'kubectl fallback' {
        It 'Lists namespaces using kubectl when kubens not available' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -OnInvoke { return @('namespace/default', 'namespace/production') }
            Mark-TestCommandsUnavailable -CommandNames 'kubens'

            Test-CachedCommand 'kubectl' | Should -Be $true

            $result = Set-KubeNamespace -List -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'get'
            $args | Should -Contain 'namespaces'
            $args | Should -Contain '-o'
            $args | Should -Contain 'name'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Switches namespace using kubectl when kubens not available' {
            Setup-CapturingCommandMock -CommandName 'kubectl'
            Mark-TestCommandsUnavailable -CommandNames 'kubens'

            Set-KubeNamespace -Namespace 'production' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'config'
            $args | Should -Contain 'set-context'
            $args | Should -Contain '--current'
            $args | Should -Contain '--namespace=production'
        }
    }
}
