<#
.SYNOPSIS
    Integration tests for CLI UI tool fragments (gum).

.DESCRIPTION
    Tests Gum helper functions.
    These tests verify that functions are created correctly.
    Note: Gum functions don't use Write-MissingToolWarning, they directly call gum.
#>

Describe 'CLI UI Tools Integration Tests' {
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
            Write-Error "Failed to initialize CLI UI tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Gum helpers (gum.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'gum.ps1')
        }

        It 'Creates Invoke-GumConfirm function' {
            Get-Command Invoke-GumConfirm -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates confirm alias for Invoke-GumConfirm' {
            Get-Alias confirm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias confirm).ResolvedCommandName | Should -Be 'Invoke-GumConfirm'
        }

        It 'Creates Invoke-GumChoose function' {
            Get-Command Invoke-GumChoose -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates choose alias for Invoke-GumChoose' {
            Get-Alias choose -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias choose).ResolvedCommandName | Should -Be 'Invoke-GumChoose'
        }

        It 'Creates Invoke-GumInput function' {
            Get-Command Invoke-GumInput -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates input alias for Invoke-GumInput' {
            Get-Alias input -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias input).ResolvedCommandName | Should -Be 'Invoke-GumInput'
        }

        It 'Creates Invoke-GumSpin function' {
            Get-Command Invoke-GumSpin -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates spin alias for Invoke-GumSpin' {
            Get-Alias spin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias spin).ResolvedCommandName | Should -Be 'Invoke-GumSpin'
        }

        It 'Creates Invoke-GumStyle function' {
            Get-Command Invoke-GumStyle -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates style alias for Invoke-GumStyle' {
            Get-Alias style -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias style).ResolvedCommandName | Should -Be 'Invoke-GumStyle'
        }
    }
}

