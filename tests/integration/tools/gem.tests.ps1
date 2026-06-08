<#
.SYNOPSIS
    Integration tests for gem tool fragment.

.DESCRIPTION
    Tests gem helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe 'gem Tools Integration Tests' {
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
            Write-Error "Failed to initialize gem tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'gem helpers (gem.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'gem' -Available $true
            . (Join-Path $script:ProfileDir 'gem.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Test-GemOutdated function' {
            Get-Command Test-GemOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gem-outdated alias for Test-GemOutdated' {
            Get-Alias gem-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gem-outdated).ResolvedCommandName | Should -Be 'Test-GemOutdated'
        }

        It 'Test-GemOutdated calls gem outdated' {
            Setup-CapturingCommandMock -CommandName 'gem' -Output 'package1 (1.0.0 < 1.2.0)'

            Test-GemOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-GemOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-GemPackages function' {
            Get-Command Update-GemPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gem-update alias for Update-GemPackages' {
            Get-Alias gem-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gem-update).ResolvedCommandName | Should -Be 'Update-GemPackages'
        }

        It 'Update-GemPackages calls gem update' {
            Setup-CapturingCommandMock -CommandName 'gem' -Output 'Packages updated successfully'

            Update-GemPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-GemPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-GemSelf function' {
            Get-Command Update-GemSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gem-self-update alias for Update-GemSelf' {
            Get-Alias gem-self-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gem-self-update).ResolvedCommandName | Should -Be 'Update-GemSelf'
        }

        It 'Update-GemSelf calls gem update --system' {
            Setup-CapturingCommandMock -CommandName 'gem' -Output 'RubyGems updated successfully'

            Update-GemSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-GemSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'gem unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when gem is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'gem' -Available $false
            . (Join-Path $script:ProfileDir 'gem.ps1')
            Get-Command Install-GemPackage -ErrorAction SilentlyContinue
        }
        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when gem is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'gem' -Available $false
            . (Join-Path $script:ProfileDir 'gem.ps1')
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gem not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'gem'
    }
}
