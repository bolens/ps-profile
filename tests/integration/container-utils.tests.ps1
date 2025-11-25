Describe "Container Utils Module" {
    BeforeAll {
        # Source the test support
        . "$PSScriptRoot\..\TestSupport.ps1"

        # Load the bootstrap fragment first (for Test-HasCommand)
        $bootstrapFragment = Get-TestPath "profile.d\00-bootstrap.ps1"
        . $bootstrapFragment

        # Load the container utils fragment directly
        $containerUtilsFragment = Get-TestPath "profile.d\22-containers.ps1"
        . $containerUtilsFragment
    }

    Context "Test-ContainerEngine" {
        It "Should return container engine info when docker is available" {
            # Ensure no preference is set
            $env:CONTAINER_ENGINE_PREFERENCE = $null

            # Mock Test-HasCommand to simulate docker availability only
            Mock Test-HasCommand {
                param($Name)
                Write-Host "Test-HasCommand called with: '$Name', returning: $($Name -eq 'docker')" -ForegroundColor Yellow
                return $Name -eq 'docker'
            }

            # Mock docker command to simulate compose subcommand success
            Mock -CommandName 'docker' {
                Write-Host "docker compose version called, setting LASTEXITCODE=0" -ForegroundColor Yellow
                $global:LASTEXITCODE = 0
            }

            $result = Test-ContainerEngine
            Write-Host "Result: $($result | ConvertTo-Json)" -ForegroundColor Cyan

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -Be 'docker'
            $result.Compose | Should -Be 'subcommand'
        }

        It "Should return container engine info when podman is available" {
            # Ensure no preference is set
            $env:CONTAINER_ENGINE_PREFERENCE = $null

            # Mock Test-HasCommand to simulate podman availability only
            Mock Test-HasCommand {
                param($Name)
                return $Name -eq 'podman'
            }

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

            # Mock Test-HasCommand to simulate both available
            Mock Test-HasCommand { return $true }

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

            # Mock Test-HasCommand to simulate both available
            Mock Test-HasCommand { return $true }

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
            Mock Test-HasCommand { return $false }

            $result = Test-ContainerEngine

            $result | Should -Not -BeNullOrEmpty
            $result.Engine | Should -BeNullOrEmpty
            $result.Compose | Should -BeNullOrEmpty
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
