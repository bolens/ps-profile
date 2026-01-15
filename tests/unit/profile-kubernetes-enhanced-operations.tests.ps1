# ===============================================
# profile-kubernetes-enhanced-operations.tests.ps1
# Unit tests for Kubernetes operation functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Operation Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('kubectl', [ref]$null)
        }
    }
    
    Context 'Exec-KubePod' {
        It 'Returns empty string when kubectl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            
            $result = Exec-KubePod -Pod "test-pod" -Command "ls" -ErrorAction SilentlyContinue
            
            $result | Should -Be ""
        }
        
        It 'Calls kubectl exec with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'exec') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "command output"
                }
            }
            
            $result = Exec-KubePod -Pod "test-pod" -Command "ls -la" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'exec'
            $script:capturedArgs | Should -Contain 'test-pod'
            $script:capturedArgs | Should -Contain '--'
            $script:capturedArgs | Should -Contain 'ls -la'
            $result | Should -Be "command output"
        }
        
        It 'Adds container flag when specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'exec') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "output"
                }
            }
            
            Exec-KubePod -Pod "test-pod" -Container "web" -Command "ls" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-c'
            $script:capturedArgs | Should -Contain 'web'
        }
        
        It 'Adds interactive flag when Interactive specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'exec') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "output"
                }
            }
            
            Exec-KubePod -Pod "test-pod" -Interactive -Command "/bin/sh" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-it'
        }
    }
    
    Context 'PortForward-KubeService' {
        It 'Returns when kubectl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            
            PortForward-KubeService -Resource "test-pod" -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue
            
            # Should complete without error
        }
        
        It 'Errors when RemotePort missing for service' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            
            { PortForward-KubeService -Resource "test-service" -ResourceType "service" -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls kubectl port-forward with correct arguments for pod' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'port-forward') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            PortForward-KubeService -Resource "test-pod" -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'port-forward'
            $script:capturedArgs | Should -Contain 'test-pod'
            $script:capturedArgs | Should -Contain '8080:80'
        }
        
        It 'Calls kubectl port-forward with service resource type' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'port-forward') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            PortForward-KubeService -Resource "test-service" -ResourceType "service" -LocalPort 8080 -RemotePort 80 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'service/test-service'
        }
        
        It 'Adds namespace when specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'port-forward') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            PortForward-KubeService -Resource "test-pod" -LocalPort 8080 -RemotePort 80 -Namespace "production" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-n'
            $script:capturedArgs | Should -Contain 'production'
        }
    }
    
    Context 'Describe-KubeResource' {
        It 'Returns empty string when kubectl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            
            $result = Describe-KubeResource -ResourceType "pods" -ErrorAction SilentlyContinue
            
            $result | Should -Be ""
        }
        
        It 'Calls kubectl describe with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'describe') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "resource description"
                }
            }
            
            $result = Describe-KubeResource -ResourceType "pods" -ResourceName "test-pod" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'describe'
            $script:capturedArgs | Should -Contain 'pods'
            $script:capturedArgs | Should -Contain 'test-pod'
            $result | Should -Be "resource description"
        }
        
        It 'Calls kubectl get with yaml when ShowYaml specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'get') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "yaml output"
                }
            }
            
            $result = Describe-KubeResource -ResourceType "pods" -ShowYaml -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'get'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'yaml'
            $result | Should -Be "yaml output"
        }
        
        It 'Removes Events section when ShowEvents is false' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            $mockOutput = @"
Name: test-pod
Namespace: default
Status: Running

Events:
  Type    Reason   Age   From     Message
  Normal  Started  1m    kubelet  Started container
"@
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'describe') {
                    $global:LASTEXITCODE = 0
                    return $mockOutput
                }
            }
            
            $result = Describe-KubeResource -ResourceType "pods" -ResourceName "test-pod" -ShowEvents:$false -ErrorAction SilentlyContinue
            
            $result | Should -Not -Match 'Events:'
        }
    }
    
    Context 'Apply-KubeManifests' {
        It 'Returns empty string when kubectl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            
            $result = Apply-KubeManifests -Path "manifests/" -ErrorAction SilentlyContinue
            
            $result | Should -Be ""
        }
        
        It 'Errors when path does not exist' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent' } -MockWith { return $false }
            
            { Apply-KubeManifests -Path "nonexistent" -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls kubectl apply with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'manifests/' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'manifests/' -and $PathType -eq 'Container' } -MockWith { return $true }
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'apply') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "applied"
                }
            }
            
            $result = Apply-KubeManifests -Path "manifests/" -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'apply'
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain 'manifests/'
            $result | Should -Be "applied"
        }
        
        It 'Adds recursive flag when Recursive specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'manifests/' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'manifests/' -and $PathType -eq 'Container' } -MockWith { return $true }
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'apply') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "applied"
                }
            }
            
            Apply-KubeManifests -Path "manifests/" -Recursive -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-R'
        }
        
        It 'Adds dry-run flag when DryRun specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'deployment.yaml' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'deployment.yaml' -and $PathType -eq 'Container' } -MockWith { return $false }
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'apply') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "dry-run output"
                }
            }
            
            Apply-KubeManifests -Path "deployment.yaml" -DryRun -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--dry-run=client'
        }
        
        It 'Adds namespace when specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'deployment.yaml' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'deployment.yaml' -and $PathType -eq 'Container' } -MockWith { return $false }
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'apply') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "applied"
                }
            }
            
            Apply-KubeManifests -Path "deployment.yaml" -Namespace "production" -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-n'
            $script:capturedArgs | Should -Contain 'production'
        }
        
        It 'Adds server-side flag when ServerSide specified' {
            Setup-AvailableCommandMock -CommandName 'kubectl'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'deployment.yaml' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'deployment.yaml' -and $PathType -eq 'Container' } -MockWith { return $false }
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'kubectl' -and $args[0] -eq 'apply') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "applied"
                }
            }
            
            Apply-KubeManifests -Path "deployment.yaml" -ServerSide -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--server-side'
        }
    }
}
