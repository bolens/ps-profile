# ===============================================
# profile-kubernetes-enhanced-resources.tests.ps1
# Unit tests for Get-KubeResources, Start-Minikube, and Start-K9s functions
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

Describe 'kubernetes-enhanced.ps1 - Get-KubeResources' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'kubectl'
    }

    Context 'Tool not available' {
        It 'Returns null when kubectl is not available' {
            $result = Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls kubectl get with resource type' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'Pod list'

            $result = Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'get'
            $args | Should -Contain 'pods'
            $args | Should -Contain '-o'
            $args | Should -Contain 'wide'
            $result | Should -Be 'Pod list'
        }

        It 'Calls kubectl get with namespace and output format' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'Deployment YAML'

            Get-KubeResources -ResourceType 'deployments' -Namespace 'production' -OutputFormat 'yaml' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-n'
            $args | Should -Contain 'production'
            $args | Should -Contain '-o'
            $args | Should -Contain 'yaml'
        }

        It 'Calls kubectl get with specific resource name' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'Pod details'

            Get-KubeResources -ResourceType 'pods' -ResourceName 'my-pod' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'my-pod'
        }

        It 'Handles kubectl execution errors' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -ExitCode 1

            $result = Get-KubeResources -ResourceType 'pods' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'kubernetes-enhanced.ps1 - Start-Minikube' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'minikube' -Available $false
        Remove-Item -Path 'Function:\minikube' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:minikube' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when minikube is not available' {
            $result = Start-Minikube -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls minikube start with default profile' {
            Setup-CapturingCommandMock -CommandName 'minikube' -Output 'Minikube started'

            $result = Start-Minikube -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'start'
            $args | Should -Contain '-p'
            $args | Should -Contain 'minikube'
            $result | Should -Be 'Minikube started'
        }

        It 'Calls minikube start with custom profile and driver' {
            Setup-CapturingCommandMock -CommandName 'minikube' -Output 'Minikube started'

            Start-Minikube -Profile 'dev' -Driver 'docker' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-p'
            $args | Should -Contain 'dev'
            $args | Should -Contain '--driver'
            $args | Should -Contain 'docker'
        }

        It 'Calls minikube status for status action' {
            Setup-CapturingCommandMock -CommandName 'minikube' -Output 'Running'

            $result = Start-Minikube -Status -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'status'
            $args | Should -Contain '-p'
            $args | Should -Contain 'minikube'
            $result | Should -Be 'Running'
        }

        It 'Handles minikube execution errors' {
            Setup-CapturingCommandMock -CommandName 'minikube' -ExitCode 1

            $result = Start-Minikube -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'kubernetes-enhanced.ps1 - Start-K9s' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'k9s' -Available $false
        Remove-Item -Path 'Function:\k9s' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:k9s' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when k9s is not available' {
            $result = Start-K9s -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches k9s without arguments' {
            Setup-CapturingCommandMock -CommandName 'k9s'

            Start-K9s -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
        }

        It 'Launches k9s with namespace' {
            Setup-CapturingCommandMock -CommandName 'k9s'

            Start-K9s -Namespace 'production' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-n'
            $args | Should -Contain 'production'
        }
    }
}
