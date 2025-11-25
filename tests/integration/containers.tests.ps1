Describe "Container Functions" {
    BeforeAll {
        # Source TestSupport.ps1 for helper functions
        . "$PSScriptRoot\..\TestSupport.ps1"

        # Load bootstrap first to get Test-HasCommand
        $global:__psprofile_fragment_loaded = @{}
        . "$PSScriptRoot\..\..\profile.d\00-bootstrap.ps1"

        # Load the containers fragment with guard clearing
        . "$PSScriptRoot\..\..\profile.d\22-containers.ps1"
    }

    BeforeEach {
        # Clear any cached container engine info before each test
        $script:__ContainerEngineInfo = $null

        # Clear environment variable
        $env:CONTAINER_ENGINE_PREFERENCE = $null
    }

    Context "Get-ContainerEngineInfo" {
        It "Returns container engine info object" {
            $result = Get-ContainerEngineInfo
            $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $result.Contains('Preferred') | Should -Be $true
            $result.Contains('Engine') | Should -Be $true
            $result.Contains('SupportsComposeSubcommand') | Should -Be $true
            $result.Contains('HasDockerComposeCmd') | Should -Be $true
            $result.Contains('HasPodmanComposeCmd') | Should -Be $true
        }

        It "Returns cached result on subsequent calls" {
            $result1 = Get-ContainerEngineInfo
            $result2 = Get-ContainerEngineInfo
            $result1 | Should -Be $result2
        }

        It "Respects CONTAINER_ENGINE_PREFERENCE environment variable" {
            $env:CONTAINER_ENGINE_PREFERENCE = 'docker'
            $result = Get-ContainerEngineInfo
            $result.Preferred | Should -Be 'docker'
        }
    }

    Context "Start-ContainerCompose" {
        It "Executes without error when function exists" {
            { Start-ContainerCompose } | Should -Not -Throw
        }

        It "Has dcu alias" {
            Get-Alias -Name dcu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Stop-ContainerCompose" {
        It "Executes without error when function exists" {
            { Stop-ContainerCompose } | Should -Not -Throw
        }

        It "Has dcd alias" {
            Get-Alias -Name dcd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-ContainerComposeLogs" {
        It "Executes without error when function exists" {
            { Get-ContainerComposeLogs } | Should -Not -Throw
        }

        It "Has dcl alias" {
            Get-Alias -Name dcl -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Clear-ContainerSystem" {
        It "Executes without error when function exists" {
            { Clear-ContainerSystem } | Should -Not -Throw
        }

        It "Has dprune alias" {
            Get-Alias -Name dprune -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Start-ContainerComposePodman" {
        It "Executes without error when function exists" {
            { Start-ContainerComposePodman } | Should -Not -Throw
        }

        It "Has pcu alias" {
            Get-Alias -Name pcu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Stop-ContainerComposePodman" {
        It "Executes without error when function exists" {
            { Stop-ContainerComposePodman } | Should -Not -Throw
        }

        It "Has pcd alias" {
            Get-Alias -Name pcd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-ContainerComposeLogsPodman" {
        It "Executes without error when function exists" {
            { Get-ContainerComposeLogsPodman } | Should -Not -Throw
        }

        It "Has pcl alias" {
            Get-Alias -Name pcl -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Clear-ContainerSystemPodman" {
        It "Executes without error when function exists" {
            { Clear-ContainerSystemPodman } | Should -Not -Throw
        }

        It "Has pprune alias" {
            Get-Alias -Name pprune -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
