<#
.SYNOPSIS
    Integration tests for PDM tool fragment.

.DESCRIPTION
    Tests PDM helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
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
}

Describe 'PDM Tools Integration Tests' {
    BeforeAll {
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
        Write-Error "Failed to initialize PDM tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }

    Context 'PDM helpers (pdm.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'pdm' -Available $true
            . (Join-Path $script:ProfileDir 'pdm.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Add-PdmPackage function' {
            Get-Command Add-PdmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pdmadd alias for Add-PdmPackage' {
            Get-Alias pdmadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmadd).ResolvedCommandName | Should -Be 'Add-PdmPackage'
        }

        It 'Creates pdminstall alias for Add-PdmPackage' {
            Get-Alias pdminstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdminstall).ResolvedCommandName | Should -Be 'Add-PdmPackage'
        }

        It 'Add-PdmPackage calls pdm add' {
            Setup-CapturingCommandMock -CommandName 'pdm' -Output 'Package added successfully'

            Add-PdmPackage -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Add-PdmPackage supports --dev flag' {
            Setup-CapturingCommandMock -CommandName 'pdm' -Output 'Dev package added successfully'

            Add-PdmPackage -Packages pytest -Dev
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Remove-PdmPackage function' {
            Get-Command Remove-PdmPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pdmremove alias for Remove-PdmPackage' {
            Get-Alias pdmremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmremove).ResolvedCommandName | Should -Be 'Remove-PdmPackage'
        }

        It 'Creates pdmuninstall alias for Remove-PdmPackage' {
            Get-Alias pdmuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmuninstall).ResolvedCommandName | Should -Be 'Remove-PdmPackage'
        }

        It 'Remove-PdmPackage calls pdm remove' {
            Setup-CapturingCommandMock -CommandName 'pdm' -Output 'Package removed successfully'

            Remove-PdmPackage -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-PdmPackages function' {
            Get-Command Update-PdmPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates pdmupdate alias for Update-PdmPackages' {
            Get-Alias pdmupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdmupdate).ResolvedCommandName | Should -Be 'Update-PdmPackages'
        }

        It 'Update-PdmPackages calls pdm update for all packages' {
            Setup-CapturingCommandMock -CommandName 'pdm' -Output 'All packages updated successfully'

            Update-PdmPackages
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Update-PdmPackages calls pdm update for specific packages' {
            Setup-CapturingCommandMock -CommandName 'pdm' -Output 'requests updated successfully'

            Update-PdmPackages -Packages requests
            Assert-TestCommandInvokedExactlyOnce
        }

    }

    Context 'Graceful degradation when pdm is unavailable' {
        BeforeAll {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            @('Add-PdmPackage', 'Remove-PdmPackage', 'Update-PdmPackages') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'pdm' -Available $false
            $script:MissingPdmOutput = & { . (Join-Path $script:ProfileDir 'pdm.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when pdm is unavailable' {
            Get-Command Add-PdmPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when pdm is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingPdmOutput -Pattern 'pdm not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingPdmOutput -ToolName 'pdm'
        }
    }
}
