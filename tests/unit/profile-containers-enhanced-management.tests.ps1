# ===============================================
# profile-containers-enhanced-management.tests.ps1
# Unit tests for container management functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'containers.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
}

Describe 'containers-enhanced.ps1 - Management Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('docker', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('podman', [ref]$null)
        }
        
        # Mock Get-ContainerEnginePreference
        Mock Get-ContainerEnginePreference -MockWith {
            return @{
                Engine          = 'docker'
                Available       = $true
                DockerAvailable = $true
                PodmanAvailable = $false
            }
        }
    }
    
    Context 'Clean-Containers' {
        It 'Returns when no container engine available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $result = Clean-Containers -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls docker container prune when engine available' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'container') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "Cleaned containers"
                }
            }
            
            Clean-Containers -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'container'
            $script:capturedArgs | Should -Contain 'prune'
        }
        
        It 'Adds volumes flag when RemoveVolumes specified' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'container') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "Cleaned"
                }
            }
            
            Clean-Containers -RemoveVolumes -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--volumes'
        }
        
        It 'Calls system prune when PruneSystem specified' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'system') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "Pruned system"
                }
            }
            
            Clean-Containers -PruneSystem -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'system'
            $script:capturedArgs | Should -Contain 'prune'
        }
    }
    
    Context 'Export-ContainerLogs' {
        It 'Returns null when no container engine available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $result = Export-ContainerLogs -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Exports logs for specified container' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'logs') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "log output"
                }
            }
            Mock Out-File -MockWith { return }
            
            $result = Export-ContainerLogs -Container "test-container" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'logs'
            $script:capturedArgs | Should -Contain 'test-container'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Adds tail parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'logs') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "log output"
                }
            }
            Mock Out-File -MockWith { return }
            
            Export-ContainerLogs -Container "test" -Tail 100 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--tail'
            $script:capturedArgs | Should -Contain '100'
        }
    }
    
    Context 'Get-ContainerStats' {
        It 'Returns empty string when no container engine available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $result = Get-ContainerStats -ErrorAction SilentlyContinue
            
            $result | Should -Be ""
        }
        
        It 'Calls docker stats when engine available' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'stats') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "stats output"
                }
            }
            
            $result = Get-ContainerStats -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'stats'
            $result | Should -Be "stats output"
        }
        
        It 'Adds no-stream flag when NoStream specified' {
            Setup-AvailableCommandMock -CommandName 'docker'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'stats') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "stats"
                }
            }
            
            Get-ContainerStats -NoStream -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--no-stream'
        }
    }
    
    Context 'Backup-ContainerVolumes' {
        It 'Returns null when no container engine available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $result = Backup-ContainerVolumes -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Creates backup for specified volume' {
            Setup-AvailableCommandMock -CommandName 'docker'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'volume' -and $args[1] -eq 'ls') {
                    $global:LASTEXITCODE = 0
                    return "test-volume"
                }
                if ($cmd -eq 'docker' -and $args[0] -eq 'run') {
                    $global:LASTEXITCODE = 0
                }
            }
            Mock Test-Path -MockWith { return $true }
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            
            $result = Backup-ContainerVolumes -Volume "test-volume" -Confirm:$false -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Restore-ContainerVolumes' {
        It 'Returns null when no container engine available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $result = Restore-ContainerVolumes -BackupPath "backup.tar.gz" -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Errors when backup file does not exist' {
            Setup-AvailableCommandMock -CommandName 'docker'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.tar.gz' } -MockWith { return $false }
            
            { Restore-ContainerVolumes -BackupPath "nonexistent.tar.gz" -ErrorAction Stop } | Should -Throw
        }
        
        It 'Restores volume from backup' {
            Setup-AvailableCommandMock -CommandName 'docker'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'backup.tar.gz' } -MockWith { return $true }
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'volume') {
                    if ($args[1] -eq 'inspect') {
                        $global:LASTEXITCODE = 0
                        return "{}"
                    }
                    if ($args[1] -eq 'create') {
                        $global:LASTEXITCODE = 0
                    }
                }
                if ($cmd -eq 'docker' -and $args[0] -eq 'run') {
                    $global:LASTEXITCODE = 0
                }
            }
            Mock Split-Path -MockWith { 
                param($Path, $Leaf, $Parent)
                if ($Leaf) { return "backup.tar.gz" }
                if ($Parent) { return $TestDrive }
            }
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            
            $result = Restore-ContainerVolumes -BackupPath "backup.tar.gz" -Volume "restored-volume" -CreateVolume -Confirm:$false -ErrorAction SilentlyContinue
            
            $result | Should -Be "restored-volume"
        }
    }
    
    Context 'Health-CheckContainers' {
        It 'Returns empty array when no container engine available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $result = Health-CheckContainers -ErrorAction SilentlyContinue
            
            $result | Should -Be @()
        }
        
        It 'Checks health for all containers' {
            Setup-AvailableCommandMock -CommandName 'docker'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'ps') {
                    $global:LASTEXITCODE = 0
                    return "container1`ncontainer2"
                }
                if ($cmd -eq 'docker' -and $args[0] -eq 'inspect') {
                    $global:LASTEXITCODE = 0
                    return '{"Status":"healthy","FailingStreak":0,"Log":[]}'
                }
            }
            
            $result = Health-CheckContainers -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
        
        It 'Returns JSON format when specified' {
            Setup-AvailableCommandMock -CommandName 'docker'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'docker' -and $args[0] -eq 'ps') {
                    $global:LASTEXITCODE = 0
                    return "container1"
                }
                if ($cmd -eq 'docker' -and $args[0] -eq 'inspect') {
                    $global:LASTEXITCODE = 0
                    return '{"Status":"healthy","FailingStreak":0,"Log":[]}'
                }
            }
            
            $result = Health-CheckContainers -Format json -ErrorAction SilentlyContinue
            
            $result | Should -Match 'json'
        }
    }
}
