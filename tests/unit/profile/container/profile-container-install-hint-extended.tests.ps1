<#
tests/unit/profile-container-install-hint-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for container engine install hint helpers.
#>

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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
            'InstallHintResolver.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Container install hint extended scenarios' {
    Context 'Get-ContainerEngineInstallHint' {
        It 'Returns the generic fallback when platform hints are unavailable' {
            try {
            $originalPlatformHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue

                        Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            $hint = Get-ContainerEngineInstallHint
            $hint | Should -Match 'docker'
            $hint | Should -Match 'podman'
            }
            finally {
                if ($null -ne $originalPlatformHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalPlatformHint.ScriptBlock -Force
                }
            }
        }

        It 'Includes separate docker and podman guidance when platform hints are available' {
            $hint = Get-ContainerEngineInstallHint
            $hint | Should -Match 'docker'
            $hint | Should -Match 'podman'
        }
    }

    Context 'Get-ContainerInstallationCommand' {
        It 'Strips the Install with prefix from the combined hint' {
            $command = Get-ContainerInstallationCommand
            $command | Should -Not -Match '^Install with:'
            $command | Should -Match 'docker'
        }

        It 'Falls back to platform-aware guidance when Get-ContainerEngineInstallHint is unavailable' {
            try {
            $originalHint = Get-Command Get-ContainerEngineInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-ContainerEngineInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-ContainerEngineInstallHint -Force -ErrorAction SilentlyContinue

            $command = Get-ContainerInstallationCommand
            $command | Should -Match 'docker'
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $command | Should -Match 'scoop install docker'
            }
            elseif ($IsLinux) {
                $command | Should -Match 'apt|dnf|yum|pacman'
                $command | Should -Not -Match 'scoop install'
            }
            elseif ($IsMacOS) {
                $command | Should -Match 'brew'
                $command | Should -Not -Match 'scoop install'
            }
            }
            finally {
                if ($null -ne $originalHint) {
                    Set-Item -Path Function:\global:Get-ContainerEngineInstallHint -Value $originalHint.ScriptBlock -Force
                }
            }
        }
    }
}
