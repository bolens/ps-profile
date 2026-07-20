# ===============================================
# profile-containers-enhanced-management.tests.ps1
# Unit tests for container management functions
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
    . (Join-Path $script:ProfileDir 'containers.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')

    $script:OriginalGetContainerEnginePreference = ${function:Get-ContainerEnginePreference}
}

AfterAll {
    if ($script:OriginalGetContainerEnginePreference) {
        Set-Item -Path Function:\global:Get-ContainerEnginePreference -Value $script:OriginalGetContainerEnginePreference -Force
        Set-Item -Path Function:\Get-ContainerEnginePreference -Value $script:OriginalGetContainerEnginePreference -Force
    }
}

function global:Set-TestContainerEnginePreference {
    param(
        [Parameter(Mandatory)]
        [hashtable]$EngineInfo
    )

    $script:TestContainerEngineInfo = $EngineInfo
    Set-Item -Path Function:\global:Get-ContainerEnginePreference -Value {
        return $script:TestContainerEngineInfo
    } -Force
    Set-Item -Path Function:\Get-ContainerEnginePreference -Value {
        return $script:TestContainerEngineInfo
    } -Force
}

function global:Get-TestDockerCaptureAt {
    param(
        [int]$Index = 0
    )

    if (-not $global:TestCommandInvocationCaptures -or $global:TestCommandInvocationCaptures.Count -le $Index) {
        return @()
    }

    return [object[]]$global:TestCommandInvocationCaptures[$Index]
}

function global:Mark-TestContainerCommandsUnavailable {
    param(
        [Parameter(Mandatory)]
        [string[]]$CommandNames
    )

    foreach ($command in $CommandNames) {
        Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue

        if ($global:AssumedAvailableCommands) {
            $removed = $null
            $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)
        }

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}

function global:Install-TestDockerEnginePreference {
    Set-TestContainerEnginePreference -EngineInfo @{
        Engine          = 'docker'
        Available       = $true
        DockerAvailable = $true
        PodmanAvailable = $false
    }
}

function global:Install-TestUnavailableContainerEnginePreference {
    Set-TestContainerEnginePreference -EngineInfo @{
        Engine          = $null
        Available       = $false
        DockerAvailable = $false
        PodmanAvailable = $false
    }
}

Describe 'containers-enhanced.ps1 - Management Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestContainerCommandsUnavailable -CommandNames @('docker', 'podman')
        Install-TestDockerEnginePreference
    }

    Context 'Clean-Containers' {
        It 'Returns when no container engine available' {
            Install-TestUnavailableContainerEnginePreference

            $result = Clean-Containers -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls docker container prune when engine available' {
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'Cleaned containers'

            Clean-Containers -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures[0] | Should -Contain 'container'
            $global:TestCommandInvocationCaptures[0] | Should -Contain 'prune'
        }

        It 'Adds volumes flag when RemoveVolumes specified' {
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'Cleaned'

            Clean-Containers -RemoveVolumes -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures[0] | Should -Contain '--volumes'
        }

        It 'Calls system prune when PruneSystem specified' {
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'Pruned system'

            Clean-Containers -PruneSystem -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'system'
            $args | Should -Contain 'prune'
        }
    }

    Context 'Export-ContainerLogs' {
        It 'Returns null when no container engine available' {
            Install-TestUnavailableContainerEnginePreference

            $result = Export-ContainerLogs -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Exports logs for specified container' {
            $outputPath = Join-Path (New-TestTempDirectory -Prefix 'ContainerLogs') 'logs.txt'
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'log output'

            $result = Export-ContainerLogs -Container 'test-container' -OutputPath $outputPath -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'logs'
            $args | Should -Contain 'test-container'
            $result | Should -Be $outputPath
        }

        It 'Adds tail parameter when specified' {
            $outputPath = Join-Path (New-TestTempDirectory -Prefix 'ContainerLogsTail') 'logs.txt'
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'log output'

            Export-ContainerLogs -Container 'test' -OutputPath $outputPath -Tail 100 -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--tail'
            $args | Should -Contain '100'
        }
    }

    Context 'Get-ContainerStats' {
        It 'Returns empty when no container engine available' {
            Install-TestUnavailableContainerEnginePreference

            $result = Get-ContainerStats -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls docker stats when engine available' {
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'stats output'

            $result = Get-ContainerStats -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'stats'
            $result | Should -Be 'stats output'
        }

        It 'Adds no-stream flag when NoStream specified' {
            Setup-CapturingCommandMock -CommandName 'docker' -Output 'stats'

            Get-ContainerStats -NoStream -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--no-stream'
        }
    }

    Context 'Backup-ContainerVolumes' {
        It 'Returns null when no container engine available' {
            Install-TestUnavailableContainerEnginePreference

            $result = Backup-ContainerVolumes -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Creates backup for specified volume' {
            try {
            $backupDir = New-TestTempDirectory -Prefix 'VolumeBackup'
            $script:TestVolumeBackupDir = $backupDir
            Setup-CapturingCommandMock -CommandName 'docker' -OnInvoke {
                if ($args[0] -eq 'run') {
                    $backupFile = Join-Path $script:TestVolumeBackupDir 'test-volume-backup.tar.gz'
                    Set-Content -Path $backupFile -Value 'backup-data'
                }
            }

            Push-Location $backupDir
                        $result = Backup-ContainerVolumes -Volume 'test-volume' -OutputPath 'test-volume-backup.tar.gz' -Confirm:$false -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Restore-ContainerVolumes' {
        It 'Returns null when no container engine available' {
            Install-TestUnavailableContainerEnginePreference

            $backupPath = Get-TestArtifactPath -FileName 'backup.tar.gz'
            $result = Restore-ContainerVolumes -BackupPath $backupPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Errors when backup file does not exist' {
            Setup-CapturingCommandMock -CommandName 'docker' -Output ''
            $missingBackup = Join-Path (New-TestTempDirectory -Prefix 'VolumeRestoreMissing') 'nonexistent.tar.gz'

            $result = Restore-ContainerVolumes -BackupPath $missingBackup -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Restores volume from backup' {
            $restoreDir = New-TestTempDirectory -Prefix 'VolumeRestore'
            $backupFile = Join-Path $restoreDir 'backup.tar.gz'
            Set-Content -Path $backupFile -Value 'backup-data'

            Setup-CapturingCommandMock -CommandName 'docker' -OnInvoke {
                if ($args[0] -eq 'volume' -and $args[1] -eq 'inspect') {
                    Write-Output '{}'
                }
            }

            $result = Restore-ContainerVolumes -BackupPath $backupFile -Volume 'restored-volume' -CreateVolume -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -Be 'restored-volume'
        }
    }

    Context 'Health-CheckContainers' {
        It 'Returns empty array when no container engine available' {
            Install-TestUnavailableContainerEnginePreference

            $result = Health-CheckContainers -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Checks health for all containers' {
            Setup-CapturingCommandMock -CommandName 'docker' -OnInvoke {
                if ($args[0] -eq 'ps') {
                    Write-Output 'container1'
                    Write-Output 'container2'
                }
                elseif ($args[0] -eq 'inspect') {
                    Write-Output '{"Status":"healthy","FailingStreak":0,"Log":[]}'
                }
            }

            $result = Health-CheckContainers -ErrorAction SilentlyContinue

            @($result).Count | Should -BeGreaterThan 0
        }

        It 'Returns JSON format when specified' {
            Setup-CapturingCommandMock -CommandName 'docker' -OnInvoke {
                if ($args[0] -eq 'ps') {
                    Write-Output 'container1'
                }
                elseif ($args[0] -eq 'inspect') {
                    Write-Output '{"Status":"healthy","FailingStreak":0,"Log":[]}'
                }
            }

            $result = Health-CheckContainers @{ Format = 'json' } -ErrorAction SilentlyContinue

            @($result).Count | Should -BeGreaterThan 0
            $result | Should -Match 'healthy'
        }
    }
}
