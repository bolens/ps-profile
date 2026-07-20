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
    Integration tests for JavaScript build tool fragments.

.DESCRIPTION
    Tests JavaScript build tool helper functions (turbo, esbuild, rollup, serve, http-server).
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Build Tools Integration Tests' {
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
            Write-Error "Failed to initialize build tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Build tools helpers (dev-tools-modules/build/build-tools.ps1)' {
        BeforeAll {
            $buildToolsPath = Join-Path $script:ProfileDir 'dev-tools-modules/build/build-tools.ps1'
            if (-not ($buildToolsPath -and -not [string]::IsNullOrWhiteSpace($buildToolsPath) -and (Test-Path -LiteralPath $buildToolsPath))) {
                throw "Build tools fragment not found at: $buildToolsPath"
            }
            
            Mark-TestCommandsUnavailable -CommandNames @('turbo', 'esbuild', 'rollup', 'serve', 'http-server', 'npx')
            Set-TestCommandAvailabilityState -CommandName 'turbo' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'esbuild' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'rollup' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'serve' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'http-server' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            . $buildToolsPath
            Register-TestFragmentAliases @{
                turbo        = 'Invoke-Turbo'
                esbuild      = 'Invoke-Esbuild'
                rollup       = 'Invoke-Rollup'
                serve        = 'Invoke-Serve'
                'http-server' = 'Invoke-HttpServer'
            }
        }

        It 'Creates Invoke-Turbo function' {
            Get-Command Invoke-Turbo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates turbo alias for Invoke-Turbo' {
            Get-Alias turbo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias turbo).ResolvedCommandName | Should -Be 'Invoke-Turbo'
        }

        It 'turbo alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('turbo or npx', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('turbo', 'npx')
            Set-TestCommandAvailabilityState -CommandName 'turbo' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-Alias -Name turbo -Value Invoke-Turbo -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = turbo --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'turbo or npx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolNames @('turbo', 'nodejs') -ToolType 'node-package'
        }

        It 'Creates Invoke-Esbuild function' {
            Get-Command Invoke-Esbuild -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates esbuild alias for Invoke-Esbuild' {
            Get-Alias esbuild -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias esbuild).ResolvedCommandName | Should -Be 'Invoke-Esbuild'
        }

        It 'Creates Invoke-Rollup function' {
            Get-Command Invoke-Rollup -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates rollup alias for Invoke-Rollup' {
            Get-Alias rollup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias rollup).ResolvedCommandName | Should -Be 'Invoke-Rollup'
        }

        It 'Creates Invoke-Serve function' {
            Get-Command Invoke-Serve -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates serve alias for Invoke-Serve' {
            Get-Alias serve -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias serve).ResolvedCommandName | Should -Be 'Invoke-Serve'
        }

        It 'Creates Invoke-HttpServer function' {
            Get-Command Invoke-HttpServer -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates http-server alias for Invoke-HttpServer' {
            Get-Alias http-server -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias http-server).ResolvedCommandName | Should -Be 'Invoke-HttpServer'
        }
    }
}

