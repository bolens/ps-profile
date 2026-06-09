<#
.SYNOPSIS
    Integration tests for swift tool fragment.

.DESCRIPTION
    Tests swift helper functions.
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

Describe 'swift Tools Integration Tests' {
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
        Write-Error "Failed to initialize swift tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }

    Context 'swift helpers (swift.ps1)' {
        BeforeAll {
            Set-TestCommandAvailabilityState -CommandName 'swift' -Available $true
            . (Join-Path $script:ProfileDir 'swift.ps1')
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Update-SwiftPackages function' {
            Get-Command Update-SwiftPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates swift-update alias for Update-SwiftPackages' {
            Get-Alias swift-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias swift-update).ResolvedCommandName | Should -Be 'Update-SwiftPackages'
        }

        It 'Update-SwiftPackages calls swift package update' {
            Setup-CapturingCommandMock -CommandName 'swift' -Output 'Packages updated successfully'

            Update-SwiftPackages
            Assert-TestCommandInvokedExactlyOnce
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
            Setup-CapturingCommandMock -CommandName 'swift' -Output 'Packages resolved successfully'

            Resolve-SwiftPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Resolve-SwiftPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful degradation when swift is unavailable' {
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

            @(
                'Update-SwiftPackages', 'Resolve-SwiftPackages',
                'Add-SwiftPackage', 'Remove-SwiftPackage'
            ) | ForEach-Object {
                Remove-Item "Function:$_" -ErrorAction SilentlyContinue
            }

            Set-TestCommandAvailabilityState -CommandName 'swift' -Available $false
            $script:MissingSwiftOutput = & { . (Join-Path $script:ProfileDir 'swift.ps1') } 2>&1 3>&1 | Out-String
        }

        It 'Functions are not created when swift is unavailable' {
            Get-Command Update-SwiftPackages -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits missing-tool warning when swift is unavailable' {
            Assert-TestMissingToolWarning -Output $script:MissingSwiftOutput -Pattern 'swift not found'
            Assert-TestOutputContainsInstallCommand -Output $script:MissingSwiftOutput -ToolName 'swift'
        }
    }
}
