
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
}

Describe "Container Functions" {
    BeforeAll {
        try {
            # Load bootstrap first to get Test-HasCommand
            $global:__psprofile_fragment_loaded = @{}
            $profileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $profileDir -or [string]::IsNullOrWhiteSpace($profileDir)) {
                throw "Get-TestPath returned null or empty value for profileDir"
            }
            if (-not (Test-Path -LiteralPath $profileDir)) {
                throw "Profile directory not found at: $profileDir"
            }
            
            $bootstrapPath = Join-Path $profileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath

            # Load the containers fragment with guard clearing
            $containersPath = Join-Path $profileDir 'containers.ps1'
            if ($null -eq $containersPath -or [string]::IsNullOrWhiteSpace($containersPath)) {
                throw "ContainersPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $containersPath)) {
                throw "Containers fragment not found at: $containersPath"
            }
            . $containersPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize container functions tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    BeforeEach {
        Set-Variable -Name '__ContainerEngineInfo' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
        Set-Variable -Name '__ContainerEnginePreference' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue

        Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue

        Set-Variable -Name '__CommandCache' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
    }

    Context "Get-ContainerEnginePreference" {
        It "Returns container engine preference object" {
            try {
                # Mock container commands as unavailable for consistent test behavior
                Initialize-ContainerEngineUnavailableMocks
                
                $result = Get-ContainerEnginePreference
                $result | Should -BeOfType [hashtable] -Because "Get-ContainerEnginePreference should return a hashtable"
                $result.Contains('Engine') | Should -Be $true -Because "result should contain Engine property"
                $result.Contains('Available') | Should -Be $true -Because "result should contain Available property"
                $result.Contains('DockerAvailable') | Should -Be $true -Because "result should contain DockerAvailable property"
                $result.Contains('PodmanAvailable') | Should -Be $true -Because "result should contain PodmanAvailable property"
                $result.Contains('InstallationCommand') | Should -Be $true -Because "result should contain InstallationCommand property"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Get-ContainerEnginePreference'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Container engine preference test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It "Provides installation command when no engines are available" {
            Initialize-ContainerEngineUnavailableMocks

            $result = Get-ContainerEnginePreference
            $result.Available | Should -Be $false
            $result.InstallationCommand | Should -Not -BeNullOrEmpty
            $result.InstallationCommand | Should -Match 'docker'
            $result.InstallationCommand | Should -Match 'podman'
            Assert-TestOutputContainsInstallCommand -Output $result.InstallationCommand -ToolNames @('docker', 'podman')
        }

        It "Detects docker availability correctly" {
            # Mock docker as available
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker           = $true
                'docker-compose' = $false
                podman           = $false
                'podman-compose' = $false
            }
            Set-TestContainerComposeVersionMock -Engine docker
            
            $result = Get-ContainerEnginePreference
            $result.DockerAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

        It "Detects podman availability correctly" {
            # Mock podman as available
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker           = $false
                'docker-compose' = $false
                podman           = $true
                'podman-compose' = $false
            }
            Set-TestContainerComposeVersionMock -Engine podman
            
            $result = Get-ContainerEnginePreference
            $result.PodmanAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }
    }

    Context "Get-ContainerEngineInfo" {
        It "Returns container engine info object" {
            Initialize-ContainerEngineUnavailableMocks
            
            $result = Get-ContainerEngineInfo
            $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $result.Contains('Preferred') | Should -Be $true
            $result.Contains('Engine') | Should -Be $true
            $result.Contains('SupportsComposeSubcommand') | Should -Be $true
            $result.Contains('HasDockerComposeCmd') | Should -Be $true
            $result.Contains('HasPodmanComposeCmd') | Should -Be $true
        }

        It "Returns cached result on subsequent calls" {
            Initialize-ContainerEngineUnavailableMocks
            
            $result1 = Get-ContainerEngineInfo
            $result2 = Get-ContainerEngineInfo
            $result1 | Should -Be $result2
        }

        It "Respects CONTAINER_ENGINE_PREFERENCE environment variable" {
            # Mock docker as available when preference is set
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker           = $true
                'docker-compose' = $false
                podman           = $false
                'podman-compose' = $false
            }
            
            $env:CONTAINER_ENGINE_PREFERENCE = 'docker'
            $result = Get-ContainerEngineInfo
            $result.Preferred | Should -Be 'docker'
        }
    }

    Context "Start-ContainerCompose" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Start-ContainerCompose } | Should -Not -Throw
        }

        It "Has dcu alias for Start-ContainerCompose" {
            Get-Alias -Name dcu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dcu).ResolvedCommandName | Should -Be 'Start-ContainerCompose'
        }

        It "Provides installation recommendation when no container engine is available" {
            Initialize-ContainerEngineUnavailableMocks

            $warningOutput = Start-ContainerCompose 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $warningOutput -Pattern 'Neither docker nor podman found'
            Assert-TestOutputContainsInstallCommand -Output $warningOutput -ToolNames @('docker', 'podman')
        }
    }

    Context "Stop-ContainerCompose" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Stop-ContainerCompose } | Should -Not -Throw
        }

        It "Has dcd alias for Stop-ContainerCompose" {
            Assert-ProfileCommandAlias -AliasName 'dcd' -FunctionName 'Stop-ContainerCompose'
        }
    }

    Context "Get-ContainerComposeLogs" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Get-ContainerComposeLogs } | Should -Not -Throw
        }

        It "Has dcl alias for Get-ContainerComposeLogs" {
            Get-Alias -Name dcl -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dcl).ResolvedCommandName | Should -Be 'Get-ContainerComposeLogs'
        }
    }

    Context "Clear-ContainerSystem" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Clear-ContainerSystem } | Should -Not -Throw
        }

        It "Has dprune alias for Clear-ContainerSystem" {
            Get-Alias -Name dprune -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dprune).ResolvedCommandName | Should -Be 'Clear-ContainerSystem'
        }
    }

    Context "Start-ContainerComposePodman" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Start-ContainerComposePodman } | Should -Not -Throw
        }

        It "Has pcu alias for Start-ContainerComposePodman" {
            Get-Alias -Name pcu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pcu).ResolvedCommandName | Should -Be 'Start-ContainerComposePodman'
        }
    }

    Context "Stop-ContainerComposePodman" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Stop-ContainerComposePodman } | Should -Not -Throw
        }

        It "Has pcd alias for Stop-ContainerComposePodman" {
            Get-Alias -Name pcd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pcd).ResolvedCommandName | Should -Be 'Stop-ContainerComposePodman'
        }
    }

    Context "Get-ContainerComposeLogsPodman" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Get-ContainerComposeLogsPodman } | Should -Not -Throw
        }

        It "Has pcl alias for Get-ContainerComposeLogsPodman" {
            Get-Alias -Name pcl -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pcl).ResolvedCommandName | Should -Be 'Get-ContainerComposeLogsPodman'
        }
    }

    Context "Clear-ContainerSystemPodman" {
        It "Executes without error when function exists" {
            Initialize-ContainerEngineUnavailableMocks
            { Clear-ContainerSystemPodman } | Should -Not -Throw
        }

        It "Has pprune alias for Clear-ContainerSystemPodman" {
            Get-Alias -Name pprune -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pprune).ResolvedCommandName | Should -Be 'Clear-ContainerSystemPodman'
        }
    }
}
