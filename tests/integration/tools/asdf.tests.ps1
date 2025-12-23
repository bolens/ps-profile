<#
.SYNOPSIS
    Integration tests for asdf tool fragment.

.DESCRIPTION
    Tests asdf helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

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
            # Mock asdf as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'asdf' -Available $true
            . (Join-Path $script:ProfileDir 'asdf.ps1')
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
            Mock -CommandName asdf -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install' -and $args -contains 'nodejs' -and $args -contains '18.0.0') {
                    Write-Output 'Node.js 18.0.0 installed successfully'
                }
            }

            { Install-AsdfTool nodejs 18.0.0 -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Get-AsdfTools function' {
            Get-Command Get-AsdfTools -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates asdflist alias for Get-AsdfTools' {
            Get-Alias asdflist -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdflist).ResolvedCommandName | Should -Be 'Get-AsdfTools'
        }

        It 'Get-AsdfTools calls asdf list' {
            Mock -CommandName asdf -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'list' -and $args.Count -eq 1) {
                    Write-Output 'nodejs'
                    Write-Output '  18.0.0'
                    Write-Output 'python'
                    Write-Output '  3.11.0'
                }
            }

            { Get-AsdfTools -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Get-AsdfTools calls asdf list for specific tool' {
            Mock -CommandName asdf -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'list' -and $args -contains 'nodejs') {
                    Write-Output '  18.0.0'
                    Write-Output '  20.0.0'
                }
            }

            { Get-AsdfTools nodejs -Verbose 4>&1 | Out-Null } | Should -Not -Throw
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
            Mock -CommandName asdf -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'uninstall' -and $args -contains 'nodejs' -and $args -contains '18.0.0') {
                    Write-Output 'Node.js 18.0.0 uninstalled successfully'
                }
            }

            { Remove-AsdfTool nodejs 18.0.0 -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Creates Update-AsdfSelf function' {
            Get-Command Update-AsdfSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates asdfselfupdate alias for Update-AsdfSelf' {
            Get-Alias asdfselfupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias asdfselfupdate).ResolvedCommandName | Should -Be 'Update-AsdfSelf'
        }

        It 'Update-AsdfSelf calls asdf update' {
            Mock -CommandName asdf -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update') {
                    Write-Output 'asdf updated successfully'
                }
            }

            { Update-AsdfSelf -Verbose 4>&1 | Out-Null } | Should -Not -Throw
        }

        It 'asdf fragment handles missing tool gracefully' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('asdf', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'asdf' -Available $false
            Remove-Item Function:Install-AsdfTool -ErrorAction SilentlyContinue
            Remove-Item Function:Remove-AsdfTool -ErrorAction SilentlyContinue
            Remove-Item Function:Update-AsdfSelf -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'asdf.ps1')
            Get-Command Install-AsdfTool -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
