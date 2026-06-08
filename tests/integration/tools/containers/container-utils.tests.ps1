BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\..\TestSupport.ps1')
}

Describe "Container Utils Module" {
    BeforeAll {
        try {
            $bootstrapFragment = Get-TestPath "profile.d\bootstrap.ps1" -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $bootstrapFragment -or [string]::IsNullOrWhiteSpace($bootstrapFragment)) {
                throw "BootstrapFragment is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapFragment)) {
                throw "Bootstrap fragment not found at: $bootstrapFragment"
            }
            . $bootstrapFragment

            $containerUtilsFragment = Get-TestPath "profile.d\containers.ps1" -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $containerUtilsFragment -or [string]::IsNullOrWhiteSpace($containerUtilsFragment)) {
                throw "ContainerUtilsFragment is null or empty"
            }
            if (-not (Test-Path -LiteralPath $containerUtilsFragment)) {
                throw "Container utils fragment not found at: $containerUtilsFragment"
            }
            . $containerUtilsFragment
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize container utils tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context "Test-ContainerEngine" {
        BeforeEach {
            Set-Variable -Name '__ContainerEngineInfo' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
            Set-Variable -Name '__CommandCache' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
        }

        It "Should return container engine info when docker is available" {
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker = $true
                podman = $false
            }
            Setup-CapturingCommandMock -CommandName 'docker' -ExitCode 0

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'docker'
            $result.Compose | Should -Be 'subcommand'
        }

        It "Should return container engine info when podman is available" {
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker           = $false
                'docker-compose' = $false
                podman           = $true
                'podman-compose' = $false
            }
            Setup-CapturingCommandMock -CommandName 'podman' -ExitCode 0

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'podman'
            $result.Compose | Should -Be 'subcommand'
        }

        It "Should respect environment preference for docker" {
            $env:CONTAINER_ENGINE_PREFERENCE = 'docker'

            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker = $true
                podman = $true
            }
            Setup-CapturingCommandMock -CommandName 'docker' -ExitCode 0

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'docker'
            $result.Preferred | Should -Be 'docker'

            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should respect environment preference for podman" {
            $env:CONTAINER_ENGINE_PREFERENCE = 'podman'

            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker = $true
                podman = $true
            }
            Setup-CapturingCommandMock -CommandName 'podman' -ExitCode 0

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'podman'
            $result.Preferred | Should -Be 'podman'

            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should handle no container engines available" {
            Initialize-ContainerEngineUnavailableMocks

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -BeNullOrEmpty
            $result.Compose | Should -BeNullOrEmpty
        }
    }

    Context "Get-ContainerEnginePreference" {
        BeforeEach {
            Set-Variable -Name '__ContainerEngineInfo' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
            Set-Variable -Name '__ContainerEnginePreference' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
            Set-Variable -Name '__CommandCache' -Scope Script -Value $null -Force -ErrorAction SilentlyContinue
        }

        It "Returns container engine preference object with all required fields" {
            Initialize-ContainerEngineUnavailableMocks
            
            $result = Get-ContainerEnginePreference
            $result | Should -BeOfType [hashtable]
            $result.ContainsKey('Engine') | Should -Be $true
            $result.ContainsKey('Available') | Should -Be $true
            $result.ContainsKey('DockerAvailable') | Should -Be $true
            $result.ContainsKey('PodmanAvailable') | Should -Be $true
            $result.ContainsKey('DockerComposeAvailable') | Should -Be $true
            $result.ContainsKey('PodmanComposeAvailable') | Should -Be $true
            $result.ContainsKey('InstallationCommand') | Should -Be $true
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

        It "Handles docker-compose standalone command" {
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker           = $false
                'docker-compose' = $true
                podman           = $false
                'podman-compose' = $false
            }

            $result = Get-ContainerEnginePreference
            $result.DockerComposeAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

        It "Handles podman-compose standalone command" {
            Initialize-ContainerEngineAvailabilityMocks -Availability @{
                docker           = $false
                'docker-compose' = $false
                podman           = $false
                'podman-compose' = $true
            }

            $result = Get-ContainerEnginePreference
            $result.PodmanComposeAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

    }

    Context "Set-ContainerEnginePreference" {
        It "Should set preference to docker" {
            { Set-ContainerEnginePreference -Engine 'docker' } | Should -Not -Throw

            $env:CONTAINER_ENGINE_PREFERENCE | Should -Be 'docker'

            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should set preference to podman" {
            { Set-ContainerEnginePreference -Engine 'podman' } | Should -Not -Throw

            $env:CONTAINER_ENGINE_PREFERENCE | Should -Be 'podman'

            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should validate engine parameter" {
            { Set-ContainerEnginePreference -Engine 'invalid' } | Should -Throw
        }
    }
}
