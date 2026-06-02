<#
.SYNOPSIS
    Integration tests for CocoaPods tool fragment.

.DESCRIPTION
    Tests CocoaPods helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

Describe 'CocoaPods Tools Integration Tests' {
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
            Write-Error "Failed to initialize CocoaPods tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'CocoaPods helpers (cocoapods.ps1)' {
        BeforeAll {
            # Mock pod as available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'pod' -Available $true
            . (Join-Path $script:ProfileDir 'cocoapods.ps1')
        }

        It 'Creates Install-CocoaPodsDependencies function' {
            Get-Command Install-CocoaPodsDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates podinstall alias for Install-CocoaPodsDependencies' {
            Get-Alias podinstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias podinstall).ResolvedCommandName | Should -Be 'Install-CocoaPodsDependencies'
        }

        It 'Install-CocoaPodsDependencies calls pod install' {
            Mock -CommandName pod -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install') {
                    Write-Output 'Dependencies installed successfully'
                }
            }

            Install-CocoaPodsDependencies
            Should -Invoke -CommandName 'pod' -Times 1 -Exactly
        }

        It 'Creates Update-CocoaPodsDependencies function' {
            Get-Command Update-CocoaPodsDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates podupdate alias for Update-CocoaPodsDependencies' {
            Get-Alias podupdate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias podupdate).ResolvedCommandName | Should -Be 'Update-CocoaPodsDependencies'
        }

        It 'Update-CocoaPodsDependencies calls pod update for all packages' {
            Mock -CommandName pod -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args.Count -eq 1) {
                    Write-Output 'All dependencies updated successfully'
                }
            }

            Update-CocoaPodsDependencies
            Should -Invoke -CommandName 'pod' -Times 1 -Exactly
        }

        It 'Update-CocoaPodsDependencies calls pod update for specific pods' {
            Mock -CommandName pod -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'update' -and $args -contains 'Alamofire') {
                    Write-Output 'Alamofire updated successfully'
                }
            }

            Update-CocoaPodsDependencies Alamofire
            Should -Invoke -CommandName 'pod' -Times 1 -Exactly
        }

        It 'Creates Remove-CocoaPodsIntegration function' {
            Get-Command Remove-CocoaPodsIntegration -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates poddeintegrate alias for Remove-CocoaPodsIntegration' {
            Get-Alias poddeintegrate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias poddeintegrate).ResolvedCommandName | Should -Be 'Remove-CocoaPodsIntegration'
        }

        It 'Remove-CocoaPodsIntegration calls pod deintegrate' {
            Mock -CommandName pod -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'deintegrate') {
                    Write-Output 'CocoaPods integration removed successfully'
                }
            }

            Remove-CocoaPodsIntegration
            Should -Invoke -CommandName 'pod' -Times 1 -Exactly
        }

    }
}

Describe 'CocoaPods unavailable graceful degradation' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    }

    It 'Functions are not created when pod is unavailable' {
        $installCommand = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'pod' -Available $false
            . (Join-Path $script:ProfileDir 'cocoapods.ps1')
            Get-Command Install-CocoaPodsDependencies -ErrorAction SilentlyContinue
        }
        $installCommand | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when pod is unavailable' {
        $output = & {
            if ($global:CollectedMissingToolWarnings) { $global:CollectedMissingToolWarnings.Clear() }
            if ($global:MissingToolWarnings) { $global:MissingToolWarnings.Clear() }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'pod' -Available $false
            . (Join-Path $script:ProfileDir 'cocoapods.ps1')
        } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pod not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cocoapods'
    }
}
