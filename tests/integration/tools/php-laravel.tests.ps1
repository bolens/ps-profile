<#
.SYNOPSIS
    Integration tests for PHP and Laravel tool fragments.

.DESCRIPTION
    Tests PHP and Laravel helper functions.
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

Describe 'PHP and Laravel Tools Integration Tests' {
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
            Write-Error "Failed to initialize PHP and Laravel tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'PHP helpers (php.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('php', 'composer')
            Set-TestCommandAvailabilityState -CommandName 'php' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $true
            . (Join-Path $script:ProfileDir 'php.ps1')
            Register-TestFragmentAliases @{
                php      = 'Invoke-Php'
                composer = 'Invoke-Composer'
            }
        }

        BeforeEach {
            Clear-TestCommandInvocationCapture
        }

        It 'Creates Invoke-Php function' {
            Get-Command Invoke-Php -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates php alias for Invoke-Php' {
            Get-Alias php -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias php).ResolvedCommandName | Should -Be 'Invoke-Php'
        }

        It 'Invoke-Php emits missing-tool warning when php is unavailable' {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'php' -Available $false
            $output = & { Invoke-Php --version } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'php not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'php'
        }

        It 'Creates Start-PhpServer function' {
            Get-Command Start-PhpServer -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates php-server alias for Start-PhpServer' {
            Get-Alias php-server -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias php-server).ResolvedCommandName | Should -Be 'Start-PhpServer'
        }

        It 'Creates Invoke-Composer function' {
            Get-Command Invoke-Composer -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates composer alias for Invoke-Composer' {
            Get-Alias composer -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias composer).ResolvedCommandName | Should -Be 'Invoke-Composer'
        }

        It 'Invoke-Composer emits missing-tool warning when composer is unavailable' {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $false
            $output = & { Invoke-Composer --version } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'composer not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'composer'
        }

        It 'Creates Test-ComposerOutdated function' {
            Get-Command Test-ComposerOutdated -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates composer-outdated alias for Test-ComposerOutdated' {
            Get-Alias composer-outdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias composer-outdated).ResolvedCommandName | Should -Be 'Test-ComposerOutdated'
        }

        It 'Test-ComposerOutdated calls composer outdated' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $true

            Setup-CapturingCommandMock -CommandName 'composer' -Output @(
                'Package    Current  Latest'
                'package1  1.0.0    1.2.0'
            )

            Test-ComposerOutdated
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Test-ComposerOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-ComposerPackages function' {
            Get-Command Update-ComposerPackages -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates composer-update alias for Update-ComposerPackages' {
            Get-Alias composer-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias composer-update).ResolvedCommandName | Should -Be 'Update-ComposerPackages'
        }

        It 'Update-ComposerPackages calls composer update' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $true

            Setup-CapturingCommandMock -CommandName 'composer' -Output 'Packages updated successfully'

            Update-ComposerPackages
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-ComposerPackages -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-ComposerSelf function' {
            Get-Command Update-ComposerSelf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates composer-self-update alias for Update-ComposerSelf' {
            Get-Alias composer-self-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias composer-self-update).ResolvedCommandName | Should -Be 'Update-ComposerSelf'
        }

        It 'Update-ComposerSelf calls composer self-update' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $true

            Setup-CapturingCommandMock -CommandName 'composer' -Output 'Composer updated successfully'

            Update-ComposerSelf
            Assert-TestCommandInvokedExactlyOnce
            Get-Command Update-ComposerSelf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Laravel helpers (laravel.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('artisan', 'art')
            Set-TestCommandAvailabilityState -CommandName 'artisan' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'art' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $false
            . (Join-Path $script:ProfileDir 'laravel.ps1')
        }

        It 'Creates Invoke-LaravelArtisan function' {
            Get-Command Invoke-LaravelArtisan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates artisan alias for Invoke-LaravelArtisan' {
            Get-Alias artisan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias artisan).ResolvedCommandName | Should -Be 'Invoke-LaravelArtisan'
        }

        It 'Creates Invoke-LaravelArt function' {
            Get-Command Invoke-LaravelArt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates art alias for Invoke-LaravelArt' {
            Get-Alias art -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias art).ResolvedCommandName | Should -Be 'Invoke-LaravelArt'
        }

        It 'Creates New-LaravelApp function' {
            Get-Command New-LaravelApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates laravel-new alias for New-LaravelApp' {
            Get-Alias laravel-new -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias laravel-new).ResolvedCommandName | Should -Be 'New-LaravelApp'
        }

        It 'New-LaravelApp emits missing-tool warning when composer is unavailable' {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'composer' -Available $false
            $output = & { New-LaravelApp 'my-app' } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'composer not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'composer'
        }

        It 'Invoke-LaravelArtisan emits missing-tool warning when artisan is unavailable' {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-TestCommandAvailabilityState -CommandName 'artisan' -Available $false
            $output = & { Invoke-LaravelArtisan --version } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'artisan not found'
        }
    }
}
