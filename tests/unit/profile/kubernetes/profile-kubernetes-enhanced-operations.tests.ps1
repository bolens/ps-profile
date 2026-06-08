# ===============================================
# profile-kubernetes-enhanced-operations.tests.ps1
# Unit tests for Kubernetes operation functions
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

    $script:TestRoot = New-TestTempDirectory -Prefix 'KubeOps'
    $script:ManifestsDir = Join-Path $script:TestRoot 'manifests'
    $script:DeploymentFile = Join-Path $script:TestRoot 'deployment.yaml'
    $script:MissingPath = Join-Path $script:TestRoot 'nonexistent'

    New-Item -ItemType Directory -Path $script:ManifestsDir -Force | Out-Null
    Set-Content -Path $script:DeploymentFile -Value 'apiVersion: v1' -Encoding utf8
}

Describe 'kubernetes-enhanced.ps1 - Operation Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'kubectl'
    }

    Context 'Exec-KubePod' {
        It 'Returns null when kubectl is not available' {
            $result = Exec-KubePod -Pod 'test-pod' -Command 'ls' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls kubectl exec with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'command output'

            $result = Exec-KubePod -Pod 'test-pod' -Command 'ls -la' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'exec'
            $args | Should -Contain 'test-pod'
            $args | Should -Contain '--'
            $args | Should -Contain 'ls -la'
            $result | Should -Be 'command output'
        }

        It 'Adds container flag when specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'output'

            Exec-KubePod -Pod 'test-pod' -Container 'web' -Command 'ls' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-c'
            $args | Should -Contain 'web'
        }

        It 'Adds interactive flag when Interactive specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'output'

            Exec-KubePod -Pod 'test-pod' -Interactive -Command '/bin/sh' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-it'
        }
    }

    Context 'PortForward-KubeService' {
        It 'Returns when kubectl is not available' {
            PortForward-KubeService -Resource 'test-pod' -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }

        It 'Errors when RemotePort missing for service' {
            Setup-CapturingCommandMock -CommandName 'kubectl'

            { PortForward-KubeService -Resource 'test-service' -ResourceType 'service' -ErrorAction Stop } | Should -Throw
        }

        It 'Calls kubectl port-forward with correct arguments for pod' {
            Setup-CapturingCommandMock -CommandName 'kubectl'

            PortForward-KubeService -Resource 'test-pod' -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'port-forward'
            $args | Should -Contain 'test-pod'
            $args | Should -Contain '8080:80'
        }

        It 'Calls kubectl port-forward with service resource type' {
            Setup-CapturingCommandMock -CommandName 'kubectl'

            PortForward-KubeService -Resource 'test-service' -ResourceType 'service' -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'service/test-service'
        }

        It 'Adds namespace when specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl'

            PortForward-KubeService -Resource 'test-pod' -LocalPort 8080 -RemotePort 80 -Namespace 'production' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-n'
            $args | Should -Contain 'production'
        }
    }

    Context 'Describe-KubeResource' {
        It 'Returns null when kubectl is not available' {
            $result = Describe-KubeResource -ResourceType 'pods' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls kubectl describe with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'resource description'

            $result = Describe-KubeResource -ResourceType 'pods' -ResourceName 'test-pod' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'describe'
            $args | Should -Contain 'pods'
            $args | Should -Contain 'test-pod'
            $result | Should -Be 'resource description'
        }

        It 'Calls kubectl get with yaml when ShowYaml specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'yaml output'

            $result = Describe-KubeResource -ResourceType 'pods' -ShowYaml -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'get'
            $args | Should -Contain '-o'
            $args | Should -Contain 'yaml'
            $result | Should -Be 'yaml output'
        }

        It 'Removes Events section when ShowEvents is false' {
            $mockOutput = @"
Name: test-pod
Namespace: default
Status: Running

Events:
  Type    Reason   Age   From     Message
  Normal  Started  1m    kubelet  Started container
"@
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output $mockOutput

            $result = Describe-KubeResource -ResourceType 'pods' -ResourceName 'test-pod' -ShowEvents:$false -ErrorAction SilentlyContinue

            $result | Should -Not -Match 'Events:'
        }
    }

    Context 'Apply-KubeManifests' {
        It 'Returns null when kubectl is not available' {
            $result = Apply-KubeManifests -Path $script:ManifestsDir -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when path does not exist' {
            Setup-CapturingCommandMock -CommandName 'kubectl'

            $result = Apply-KubeManifests -Path $script:MissingPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }

        It 'Calls kubectl apply with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'applied'

            $result = Apply-KubeManifests -Path $script:ManifestsDir -Confirm:$false -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'apply'
            $args | Should -Contain '-f'
            $args | Should -Contain $script:ManifestsDir
            $result | Should -Be 'applied'
        }

        It 'Adds recursive flag when Recursive specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'applied'

            Apply-KubeManifests -Path $script:ManifestsDir -Recursive -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-R'
        }

        It 'Adds dry-run flag when DryRun specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'dry-run output'

            Apply-KubeManifests -Path $script:DeploymentFile -DryRun -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--dry-run=client'
        }

        It 'Adds namespace when specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'applied'

            Apply-KubeManifests -Path $script:DeploymentFile -Namespace 'production' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-n'
            $args | Should -Contain 'production'
        }

        It 'Adds server-side flag when ServerSide specified' {
            Setup-CapturingCommandMock -CommandName 'kubectl' -Output 'applied'

            Apply-KubeManifests -Path $script:DeploymentFile -ServerSide -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--server-side'
        }
    }
}
