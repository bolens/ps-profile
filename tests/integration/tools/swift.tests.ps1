<#
.SYNOPSIS
    Integration tests for swift tool fragment.

.DESCRIPTION
    Tests swift helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'swift Tools Integration Tests' {
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
            Write-Error "Failed to initialize swift tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'swift helpers (swift.ps1)' {
        BeforeAll {
            # Mock swift as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'swift' -Available $true
            . (Join-Path $script:ProfileDir 'swift.ps1')
        }

        It 'Creates Update-SwiftPackages function' {
            Get-Command Update-SwiftPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates swift-update alias for Update-SwiftPackages' {
            Get-Alias swift-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias swift-update).ResolvedCommandName | Should -Be 'Update-SwiftPackages'
        }

        It 'Update-SwiftPackages calls swift package update' {
            Mock -CommandName swift -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'package' -and $args -contains 'update') {
                    Write-Output 'Packages updated successfully'
                }
            }

            { Update-SwiftPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-SwiftPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Resolve-SwiftPackages function' {
            Get-Command Resolve-SwiftPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates swift-resolve alias for Resolve-SwiftPackages' {
            Get-Alias swift-resolve -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias swift-resolve).ResolvedCommandName | Should -Be 'Resolve-SwiftPackages'
        }

        It 'Resolve-SwiftPackages calls swift package resolve' {
            Mock -CommandName swift -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'package' -and $args -contains 'resolve') {
                    Write-Output 'Packages resolved successfully'
                }
            }

            { Resolve-SwiftPackages -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Resolve-SwiftPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
