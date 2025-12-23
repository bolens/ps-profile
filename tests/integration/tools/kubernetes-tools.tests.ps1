<#
.SYNOPSIS
    Integration tests for Kubernetes tool fragments (helm, minikube).

.DESCRIPTION
    Tests Helm and Minikube helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Kubernetes Tools Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize Kubernetes tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Helm helpers (helm.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'helm' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'helm' } -MockWith { $null }
            # Mock helm command before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'helm' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'helm' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'helm.ps1')
        }

        It 'Creates Invoke-Helm function' {
            Get-Command Invoke-Helm -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates helm alias for Invoke-Helm' {
            Get-Alias helm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias helm).ResolvedCommandName | Should -Be 'Invoke-Helm'
        }

        It 'helm alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('helm', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'helm' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'helm' } -MockWith { $false }
            $output = helm --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'helm not found'
            $output | Should -Match 'scoop install helm'
        }

        It 'Creates Install-HelmChart function' {
            Get-Command Install-HelmChart -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates helm-install alias for Install-HelmChart' {
            Get-Alias helm-install -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias helm-install).ResolvedCommandName | Should -Be 'Install-HelmChart'
        }

        It 'Creates Update-HelmRelease function' {
            Get-Command Update-HelmRelease -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates helm-upgrade alias for Update-HelmRelease' {
            Get-Alias helm-upgrade -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias helm-upgrade).ResolvedCommandName | Should -Be 'Update-HelmRelease'
        }

        It 'Creates Get-HelmReleases function' {
            Get-Command Get-HelmReleases -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates helm-list alias for Get-HelmReleases' {
            Get-Alias helm-list -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias helm-list).ResolvedCommandName | Should -Be 'Get-HelmReleases'
        }
    }

    Context 'Minikube helpers (kube.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'minikube' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'minikube' } -MockWith { $null }
            # Mock minikube command before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'minikube' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'minikube' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'kube.ps1')
        }

        It 'Creates Start-MinikubeCluster function' {
            Get-Command Start-MinikubeCluster -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates minikube-start alias for Start-MinikubeCluster' {
            Get-Alias minikube-start -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias minikube-start).ResolvedCommandName | Should -Be 'Start-MinikubeCluster'
        }

        It 'minikube-start alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('minikube', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'minikube' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'minikube' } -MockWith { $false }
            $output = minikube-start 2>&1 3>&1 | Out-String
            $output | Should -Match 'minikube not found'
            $output | Should -Match 'scoop install minikube'
        }

        It 'Creates Stop-MinikubeCluster function' {
            Get-Command Stop-MinikubeCluster -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates minikube-stop alias for Stop-MinikubeCluster' {
            Get-Alias minikube-stop -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias minikube-stop).ResolvedCommandName | Should -Be 'Stop-MinikubeCluster'
        }
    }
}

