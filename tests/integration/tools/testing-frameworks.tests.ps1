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

<#
.SYNOPSIS
    Integration tests for JavaScript testing framework fragments.

.DESCRIPTION
    Tests JavaScript testing framework helper functions (jest, vitest, playwright, cypress, mocha).
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Testing Frameworks Integration Tests' {
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
            Write-Error "Failed to initialize testing frameworks tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Testing frameworks helpers (dev-tools-modules/build/testing-frameworks.ps1)' {
        BeforeAll {
            $testingFrameworksPath = Join-Path $script:ProfileDir 'dev-tools-modules/build/testing-frameworks.ps1'
            if (-not ($testingFrameworksPath -and -not [string]::IsNullOrWhiteSpace($testingFrameworksPath) -and (Test-Path -LiteralPath $testingFrameworksPath))) {
                throw "Testing frameworks fragment not found at: $testingFrameworksPath"
            }
            
            Mark-TestCommandsUnavailable -CommandNames @('jest', 'vitest', 'playwright', 'cypress', 'mocha', 'npx')
            Set-TestCommandAvailabilityState -CommandName 'jest' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'vitest' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'playwright' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'cypress' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'mocha' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            . $testingFrameworksPath
            Register-TestFragmentAliases @{
                jest       = 'Invoke-Jest'
                vitest     = 'Invoke-Vitest'
                playwright = 'Invoke-Playwright'
                cypress    = 'Invoke-Cypress'
                mocha      = 'Invoke-Mocha'
            }
        }

        It 'Creates Invoke-Jest function' {
            Get-Command Invoke-Jest -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates jest alias for Invoke-Jest' {
            Get-Alias jest -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jest).ResolvedCommandName | Should -Be 'Invoke-Jest'
        }

        It 'jest alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('jest or npx', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('jest', 'npx')
            Set-TestCommandAvailabilityState -CommandName 'jest' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-Alias -Name jest -Value Invoke-Jest -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = jest --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'jest or npx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolNames @('jest', 'nodejs') -ToolType 'node-package'
        }

        It 'Creates Invoke-Vitest function' {
            Get-Command Invoke-Vitest -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vitest alias for Invoke-Vitest' {
            Get-Alias vitest -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vitest).ResolvedCommandName | Should -Be 'Invoke-Vitest'
        }

        It 'Creates Invoke-Playwright function' {
            Get-Command Invoke-Playwright -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates playwright alias for Invoke-Playwright' {
            Get-Alias playwright -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias playwright).ResolvedCommandName | Should -Be 'Invoke-Playwright'
        }

        It 'Creates Invoke-Cypress function' {
            Get-Command Invoke-Cypress -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates cypress alias for Invoke-Cypress' {
            Get-Alias cypress -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias cypress).ResolvedCommandName | Should -Be 'Invoke-Cypress'
        }

        It 'Creates Invoke-Mocha function' {
            Get-Command Invoke-Mocha -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates mocha alias for Invoke-Mocha' {
            Get-Alias mocha -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mocha).ResolvedCommandName | Should -Be 'Invoke-Mocha'
        }
    }
}

