<#
.SYNOPSIS
    Integration tests for asdf tool fragment.

.DESCRIPTION
    Tests asdf helper functions.
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

Describe 'asdf Tools Integration Tests' {
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
            Write-Error "Failed to initialize asdf tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'asdf helpers (asdf.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'asdf' -Available $true
            . (Join-Path $script:ProfileDir 'asdf.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Install-AsdfTool function' {
            Get-Command Install-AsdfTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates asdfinstall alias for Install-AsdfTool' {
            Get-Alias asdfinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdfinstall).ResolvedCommandName | Should -Be 'Install-AsdfTool'
        }

        It 'Creates asdfadd alias for Install-AsdfTool' {
            Get-Alias asdfadd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdfadd).ResolvedCommandName | Should -Be 'Install-AsdfTool'
        }

        It 'Install-AsdfTool calls asdf install' {
            Setup-CapturingCommandMock -CommandName 'asdf' -Output 'Node.js 18.0.0 installed successfully'

            Install-AsdfTool nodejs 18.0.0
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Get-AsdfTools function' {
            Get-Command Get-AsdfTools -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates asdflist alias for Get-AsdfTools' {
            Get-Alias asdflist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdflist).ResolvedCommandName | Should -Be 'Get-AsdfTools'
        }

        It 'Get-AsdfTools calls asdf list' {
            Setup-CapturingCommandMock -CommandName 'asdf' -Output @(
                'nodejs'
                '  18.0.0'
                'python'
                '  3.11.0'
            )

            Get-AsdfTools
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Get-AsdfTools calls asdf list for specific tool' {
            Setup-CapturingCommandMock -CommandName 'asdf' -Output @(
                '  18.0.0'
                '  20.0.0'
            )

            Get-AsdfTools nodejs
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Remove-AsdfTool function' {
            Get-Command Remove-AsdfTool -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates asdfuninstall alias for Remove-AsdfTool' {
            Get-Alias asdfuninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdfuninstall).ResolvedCommandName | Should -Be 'Remove-AsdfTool'
        }

        It 'Creates asdfremove alias for Remove-AsdfTool' {
            Get-Alias asdfremove -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdfremove).ResolvedCommandName | Should -Be 'Remove-AsdfTool'
        }

        It 'Remove-AsdfTool calls asdf uninstall' {
            Setup-CapturingCommandMock -CommandName 'asdf' -Output 'Node.js 18.0.0 uninstalled successfully'

            Remove-AsdfTool nodejs 18.0.0
            Assert-TestCommandInvokedExactlyOnce
        }

        It 'Creates Update-AsdfSelf function' {
            Get-Command Update-AsdfSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates asdfselfupdate alias for Update-AsdfSelf' {
            Get-Alias asdfselfupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdfselfupdate).ResolvedCommandName | Should -Be 'Update-AsdfSelf'
        }

        It 'Update-AsdfSelf calls asdf update' {
            Setup-CapturingCommandMock -CommandName 'asdf' -Output 'asdf updated successfully'

            Update-AsdfSelf
            Assert-TestCommandInvokedExactlyOnce
        }

    }

    Context 'Graceful degradation when asdf is unavailable' {
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

            @('Install-AsdfTool', 'Remove-AsdfTool', 'Update-AsdfSelf') | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'asdf' -Available $false
            $script:MissingAsdfOutput = & { . (Join-Path $script:ProfileDir 'asdf.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when asdf is unavailable' {
            Get-Command Install-AsdfTool -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when asdf is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingAsdfOutput -Pattern 'asdf not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingAsdfOutput -ToolName 'asdf'
        }
    }
}
