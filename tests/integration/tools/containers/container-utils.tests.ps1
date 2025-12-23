Describe "Container Utils Module" {
    BeforeAll {
        try {
            # Load the bootstrap fragment first (for Test-HasCommand)
            $bootstrapFragment = Get-TestPath "profile.d\bootstrap.ps1" -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $bootstrapFragment -or [string]::IsNullOrWhiteSpace($bootstrapFragment)) {
                throw "BootstrapFragment is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapFragment)) {
                throw "Bootstrap fragment not found at: $bootstrapFragment"
            }
            . $bootstrapFragment

            # Load the container utils fragment directly
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
            # Clear cached container engine info between tests
            if (Get-Variable -Name '__ContainerEngineInfo' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEngineInfo' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            # Clear environment preference
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
            # Clear any cached command detection
            if (Get-Variable -Name '__CommandCache' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__CommandCache' -Scope Script -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should return container engine info when docker is available" {
            # Mock command availability using standardized framework
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It

            # Mock docker command to simulate compose subcommand success
            Mock -CommandName 'docker' {
                $global:LASTEXITCODE = 0
            }

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'docker'
            $result.Compose | Should -Be 'subcommand'
        }

        It "Should return container engine info when podman is available" {
            # Mock command availability using standardized framework
            # Must mock docker-compose and podman-compose too
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $true }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }

            # Mock podman command to simulate compose subcommand success
            Mock -CommandName 'podman' {
                $global:LASTEXITCODE = 0
            }

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'podman'
            $result.Compose | Should -Be 'subcommand'
        }

        It "Should respect environment preference for docker" {
            $env:CONTAINER_ENGINE_PREFERENCE = 'docker'

            # Mock both commands as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $true -Scope It

            # Mock docker command to simulate compose subcommand success
            Mock -CommandName 'docker' {
                $global:LASTEXITCODE = 0
            }

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'docker'
            $result.Preferred | Should -Be 'docker'

            # Clean up
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should respect environment preference for podman" {
            $env:CONTAINER_ENGINE_PREFERENCE = 'podman'

            # Mock both commands as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $true -Scope It

            # Mock podman command to simulate compose subcommand success
            Mock -CommandName 'podman' {
                $global:LASTEXITCODE = 0
            }

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'podman'
            $result.Preferred | Should -Be 'podman'

            # Clean up
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should handle no container engines available" {
            # Mock both commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            # Also mock docker-compose and podman-compose as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -BeNullOrEmpty
            $result.Compose | Should -BeNullOrEmpty
        }
    }

    Context "Get-ContainerEnginePreference" {
        BeforeEach {
            # Clear cached container engine info between tests
            if (Get-Variable -Name '__ContainerEngineInfo' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEngineInfo' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            # Clear environment preference
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
            # Clear any cached command detection
            if (Get-Variable -Name '__CommandCache' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__CommandCache' -Scope Script -Force -ErrorAction SilentlyContinue
            }
        }

        It "Returns container engine preference object with all required fields" {
            # Mock all container commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
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
            # Clear cached container engine info
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            
            # Mock all container commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }
            
            $result = Get-ContainerEnginePreference
            $result.Available | Should -Be $false
            $result.InstallationCommand | Should -Not -BeNullOrEmpty
            $result.InstallationCommand | Should -Match 'scoop install (docker|podman)'
        }

        It "Detects docker availability correctly" {
            # Clear cached container engine info
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            
            # Mock docker as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $true }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }
            
            # Mock docker compose version check
            Mock -CommandName docker -MockWith { 
                if ($args[0] -eq 'compose' -and $args[1] -eq 'version') {
                    $global:LASTEXITCODE = 0
                    return "Docker Compose version 2.0.0"
                }
            }
            
            $result = Get-ContainerEnginePreference
            $result.DockerAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

        It "Detects podman availability correctly" {
            # Clear cached container engine info
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            
            # Mock podman as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $true }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }
            
            # Mock podman compose version check
            Mock -CommandName podman -MockWith { 
                if ($args[0] -eq 'compose' -and $args[1] -eq 'version') {
                    $global:LASTEXITCODE = 0
                    return "Podman Compose version 1.0.0"
                }
            }
            
            $result = Get-ContainerEnginePreference
            $result.PodmanAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

        It "Handles docker-compose standalone command" {
            # Clear cached container engine info
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            
            # Mock docker-compose as available but not docker
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $true }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }
            
            $result = Get-ContainerEnginePreference
            $result.DockerComposeAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

        It "Handles podman-compose standalone command" {
            # Clear cached container engine info
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
            }
            
            # Mock podman-compose as available but not podman
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $true -Scope It
            
            # Also directly mock Test-HasCommand to ensure it takes precedence
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $true }
            
            $result = Get-ContainerEnginePreference
            $result.PodmanComposeAvailable | Should -Be $true
            $result.Available | Should -Be $true
        }

    }

    Context "Set-ContainerEnginePreference" {
        It "Should set preference to docker" {
            { Set-ContainerEnginePreference -Engine 'docker' } | Should -Not -Throw

            $env:CONTAINER_ENGINE_PREFERENCE | Should -Be 'docker'

            # Clean up
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should set preference to podman" {
            { Set-ContainerEnginePreference -Engine 'podman' } | Should -Not -Throw

            $env:CONTAINER_ENGINE_PREFERENCE | Should -Be 'podman'

            # Clean up
            Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue
        }

        It "Should validate engine parameter" {
            { Set-ContainerEnginePreference -Engine 'invalid' } | Should -Throw
        }
    }
}

