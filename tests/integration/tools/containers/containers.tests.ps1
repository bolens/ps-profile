
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
        # Clear any cached container engine info before each test
        if (Get-Variable -Name '__ContainerEngineInfo' -Scope Script -ErrorAction SilentlyContinue) {
            Remove-Variable -Name '__ContainerEngineInfo' -Scope Script -Force -ErrorAction SilentlyContinue
        }
        
        # Clear cached container engine preference before each test
        if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
            Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
        }

        # Clear environment variable
        Remove-Item Env:\CONTAINER_ENGINE_PREFERENCE -ErrorAction SilentlyContinue

        # Clear any cached command detection
        if (Get-Variable -Name '__CommandCache' -Scope Script -ErrorAction SilentlyContinue) {
            Remove-Variable -Name '__CommandCache' -Scope Script -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Get-ContainerEnginePreference" {
        It "Returns container engine preference object" {
            try {
                # Mock container commands as unavailable for consistent test behavior
                Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
                Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
                Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
                Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
                
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
            # Clear cache to ensure fresh evaluation
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force
            }
            
            # Mock all container commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also mock Test-HasCommand to ensure it returns false
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }
            
            $result = Get-ContainerEnginePreference
            $result.Available | Should -Be $false
            $result.InstallationCommand | Should -Match 'scoop install (docker|podman)'
        }

        It "Detects docker availability correctly" {
            # Mock docker as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
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
            # Mock podman as available
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
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
    }

    Context "Get-ContainerEngineInfo" {
        It "Returns container engine info object" {
            # Mock container commands as unavailable for consistent test behavior
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            $result = Get-ContainerEngineInfo
            $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $result.Contains('Preferred') | Should -Be $true
            $result.Contains('Engine') | Should -Be $true
            $result.Contains('SupportsComposeSubcommand') | Should -Be $true
            $result.Contains('HasDockerComposeCmd') | Should -Be $true
            $result.Contains('HasPodmanComposeCmd') | Should -Be $true
        }

        It "Returns cached result on subsequent calls" {
            # Mock container commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            $result1 = Get-ContainerEngineInfo
            $result2 = Get-ContainerEngineInfo
            $result1 | Should -Be $result2
        }

        It "Respects CONTAINER_ENGINE_PREFERENCE environment variable" {
            # Mock docker as available when preference is set
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $true -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            $env:CONTAINER_ENGINE_PREFERENCE = 'docker'
            $result = Get-ContainerEngineInfo
            $result.Preferred | Should -Be 'docker'
        }
    }

    Context "Start-ContainerCompose" {
        It "Executes without error when function exists" {
            { Start-ContainerCompose } | Should -Not -Throw
        }

        It "Has dcu alias for Start-ContainerCompose" {
            Get-Alias -Name dcu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dcu).ResolvedCommandName | Should -Be 'Start-ContainerCompose'
        }

        It "Provides installation recommendation when no container engine is available" {
            # Clear cache to ensure fresh evaluation
            if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
                Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force
            }
            
            # Mock all container commands as unavailable
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'docker-compose' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'podman-compose' -Available $false -Scope It
            
            # Also mock Test-HasCommand to ensure it returns false
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'docker-compose' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'podman-compose' } -MockWith { $false }
            
            # Capture warning output correctly
            $warningOutput = Start-ContainerCompose 2>&1 3>&1 | Out-String
            $warningOutput | Should -Match 'scoop install (docker|podman)'
        }
    }

    Context "Stop-ContainerCompose" {
        It "Executes without error when function exists" {
            { Stop-ContainerCompose } | Should -Not -Throw
        }

        It "Has dcd alias for Stop-ContainerCompose" {
            Get-Alias -Name dcd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dcd).ResolvedCommandName | Should -Be 'Stop-ContainerCompose'
        }
    }

    Context "Get-ContainerComposeLogs" {
        It "Executes without error when function exists" {
            { Get-ContainerComposeLogs } | Should -Not -Throw
        }

        It "Has dcl alias for Get-ContainerComposeLogs" {
            Get-Alias -Name dcl -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dcl).ResolvedCommandName | Should -Be 'Get-ContainerComposeLogs'
        }
    }

    Context "Clear-ContainerSystem" {
        It "Executes without error when function exists" {
            { Clear-ContainerSystem } | Should -Not -Throw
        }

        It "Has dprune alias for Clear-ContainerSystem" {
            Get-Alias -Name dprune -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dprune).ResolvedCommandName | Should -Be 'Clear-ContainerSystem'
        }
    }

    Context "Start-ContainerComposePodman" {
        It "Executes without error when function exists" {
            { Start-ContainerComposePodman } | Should -Not -Throw
        }

        It "Has pcu alias for Start-ContainerComposePodman" {
            Get-Alias -Name pcu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pcu).ResolvedCommandName | Should -Be 'Start-ContainerComposePodman'
        }
    }

    Context "Stop-ContainerComposePodman" {
        It "Executes without error when function exists" {
            { Stop-ContainerComposePodman } | Should -Not -Throw
        }

        It "Has pcd alias for Stop-ContainerComposePodman" {
            Get-Alias -Name pcd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pcd).ResolvedCommandName | Should -Be 'Stop-ContainerComposePodman'
        }
    }

    Context "Get-ContainerComposeLogsPodman" {
        It "Executes without error when function exists" {
            { Get-ContainerComposeLogsPodman } | Should -Not -Throw
        }

        It "Has pcl alias for Get-ContainerComposeLogsPodman" {
            Get-Alias -Name pcl -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pcl).ResolvedCommandName | Should -Be 'Get-ContainerComposeLogsPodman'
        }
    }

    Context "Clear-ContainerSystemPodman" {
        It "Executes without error when function exists" {
            { Clear-ContainerSystemPodman } | Should -Not -Throw
        }

        It "Has pprune alias for Clear-ContainerSystemPodman" {
            Get-Alias -Name pprune -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pprune).ResolvedCommandName | Should -Be 'Clear-ContainerSystemPodman'
        }
    }
}
