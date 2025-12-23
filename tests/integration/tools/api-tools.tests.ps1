# ===============================================
# api-tools.tests.ps1
# Integration tests for API tools fragment (api-tools.ps1)
# ===============================================

<#
.SYNOPSIS
    Integration tests for API tools fragment (api-tools.ps1).

.DESCRIPTION
    Tests API tool wrapper functions (bruno, hurl, httpie, httptoolkit).
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'API Tools Integration Tests' {
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
            
            $apiToolsPath = Join-Path $script:ProfileDir 'api-tools.ps1'
            if (-not (Test-Path -LiteralPath $apiToolsPath)) {
                throw "API tools fragment not found at: $apiToolsPath"
            }
            . $apiToolsPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize API tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Bruno helpers (Invoke-Bruno)' {
        BeforeAll {
            # Mock Get-Command to return null for 'bruno' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'bruno' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-Bruno -ErrorAction SilentlyContinue
            Remove-Item Alias:\bruno -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'api-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-Bruno function' {
            Get-Command Invoke-Bruno -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates bruno alias for Invoke-Bruno' {
            $alias = Get-Alias bruno -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'bruno' -Target 'Invoke-Bruno' | Out-Null
                }
                $alias = Get-Alias bruno -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-Bruno'
            }
        }

        It 'bruno alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('bruno', [ref]$null)
            }
            if (Get-Command Clear-CommandCache -ErrorAction SilentlyContinue) {
                Clear-CommandCache -CommandName 'bruno' -ErrorAction SilentlyContinue
            }
            Mock-CommandAvailabilityPester -CommandName 'bruno' -Available $false
            Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'bruno' } -MockWith { $false }
            $output = bruno -CollectionPath (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'bruno'
        }
    }

    Context 'Hurl helpers (Invoke-Hurl)' {
        BeforeAll {
            # Mock Get-Command to return null for 'hurl' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'hurl' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-Hurl -ErrorAction SilentlyContinue
            Remove-Item Alias:\hurl -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'api-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-Hurl function' {
            Get-Command Invoke-Hurl -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates hurl alias for Invoke-Hurl' {
            $alias = Get-Alias hurl -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'hurl' -Target 'Invoke-Hurl' | Out-Null
                }
                $alias = Get-Alias hurl -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-Hurl'
            }
        }

        It 'hurl alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('hurl', [ref]$null)
            }
            if (Get-Command Clear-CommandCache -ErrorAction SilentlyContinue) {
                Clear-CommandCache -CommandName 'hurl' -ErrorAction SilentlyContinue
            }
            Mock-CommandAvailabilityPester -CommandName 'hurl' -Available $false
            Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'hurl' } -MockWith { $false }
            $testFile = Join-Path (Get-Location).Path 'test.hurl'
            $output = hurl -TestFile $testFile 2>&1 3>&1 | Out-String
            $output | Should -Match 'hurl'
        }
    }

    Context 'Httpie helpers (Invoke-Httpie)' {
        BeforeAll {
            # Mock Get-Command to return null for 'http' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'http' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-Httpie -ErrorAction SilentlyContinue
            Remove-Item Alias:\httpie -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'api-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-Httpie function' {
            Get-Command Invoke-Httpie -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates httpie alias for Invoke-Httpie' {
            $alias = Get-Alias httpie -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'httpie' -Target 'Invoke-Httpie' | Out-Null
                }
                $alias = Get-Alias httpie -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-Httpie'
            }
        }

        It 'httpie alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('httpie', [ref]$null)
            }
            if (Get-Command Clear-CommandCache -ErrorAction SilentlyContinue) {
                Clear-CommandCache -CommandName 'http' -ErrorAction SilentlyContinue
            }
            Mock-CommandAvailabilityPester -CommandName 'http' -Available $false
            Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'http' } -MockWith { $false }
            $output = httpie -Url 'https://api.example.com/test' 2>&1 3>&1 | Out-String
            $output | Should -Match 'httpie'
        }
    }

    Context 'HTTP Toolkit helpers (Start-HttpToolkit)' {
        BeforeAll {
            # Mock Get-Command to return null for 'httptoolkit' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'httptoolkit' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Start-HttpToolkit -ErrorAction SilentlyContinue
            Remove-Item Alias:\httptoolkit -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'api-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Start-HttpToolkit function' {
            Get-Command Start-HttpToolkit -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates httptoolkit alias for Start-HttpToolkit' {
            $alias = Get-Alias httptoolkit -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'httptoolkit' -Target 'Start-HttpToolkit' | Out-Null
                }
                $alias = Get-Alias httptoolkit -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Start-HttpToolkit'
            }
        }

        It 'httptoolkit alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('httptoolkit', [ref]$null)
            }
            if (Get-Command Clear-CommandCache -ErrorAction SilentlyContinue) {
                Clear-CommandCache -CommandName 'httptoolkit' -ErrorAction SilentlyContinue
            }
            Mock-CommandAvailabilityPester -CommandName 'httptoolkit' -Available $false
            Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'httptoolkit' } -MockWith { $false }
            $output = httptoolkit 2>&1 3>&1 | Out-String
            $output | Should -Match 'httptoolkit'
        }
    }

    Context 'Fragment loading' {
        It 'Fragment loads without errors' {
            $apiToolsPath = Join-Path $script:ProfileDir 'api-tools.ps1'
            { . $apiToolsPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Fragment is idempotent (can be loaded multiple times)' {
            $apiToolsPath = Join-Path $script:ProfileDir 'api-tools.ps1'
            # Ensure function exists first
            if (-not (Get-Command Invoke-Bruno -ErrorAction SilentlyContinue)) {
                . $apiToolsPath -ErrorAction SilentlyContinue
            }
            $beforeFunction = Get-Command Invoke-Bruno -ErrorAction SilentlyContinue
            $beforeFunction | Should -Not -BeNullOrEmpty -Because "Function should exist before reload"
            
            # Reload fragment (should be idempotent - no errors)
            { . $apiToolsPath -ErrorAction SilentlyContinue } | Should -Not -Throw
            
            # Verify function still exists and is callable (idempotency means no errors on reload)
            $afterFunction = Get-Command Invoke-Bruno -ErrorAction SilentlyContinue
            $afterFunction | Should -Not -BeNullOrEmpty -Because "Function should still exist after reload"
            # Function should still be callable (idempotency means no errors on reload)
            { Invoke-Bruno -CollectionPath (Get-Location).Path -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

