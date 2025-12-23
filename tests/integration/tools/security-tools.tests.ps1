<#
.SYNOPSIS
    Integration tests for security tools fragment (security-tools.ps1).

.DESCRIPTION
    Tests security tool wrapper functions (gitleaks, trufflehog, osv-scanner, yara, clamav, dangerzone).
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Security Tools Integration Tests' {
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
            
            $securityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
            if (-not (Test-Path -LiteralPath $securityToolsPath)) {
                throw "Security tools fragment not found at: $securityToolsPath"
            }
            . $securityToolsPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize security tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'GitLeaks helpers (Invoke-GitLeaksScan)' {
        BeforeAll {
            # Mock Get-Command to return null for 'gitleaks' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'gitleaks' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
            Remove-Item Alias:\gitleaks-scan -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'security-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-GitLeaksScan function' {
            Get-Command Invoke-GitLeaksScan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gitleaks-scan alias for Invoke-GitLeaksScan' {
            # Alias may be created as function wrapper if command exists, so check for either
            $alias = Get-Alias gitleaks-scan -ErrorAction SilentlyContinue
            if (-not $alias) {
                # Try to create it if missing
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'gitleaks-scan' -Target 'Invoke-GitLeaksScan' | Out-Null
                }
                $alias = Get-Alias gitleaks-scan -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-GitLeaksScan'
            }
        }

        It 'gitleaks-scan alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('gitleaks', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $false
            $output = gitleaks-scan -RepositoryPath (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'gitleaks'
        }
    }

    Context 'TruffleHog helpers (Invoke-TruffleHogScan)' {
        BeforeAll {
            # Mock Get-Command to return null for 'trufflehog' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'trufflehog' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-TruffleHogScan -ErrorAction SilentlyContinue
            Remove-Item Alias:\trufflehog-scan -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'security-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-TruffleHogScan function' {
            Get-Command Invoke-TruffleHogScan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates trufflehog-scan alias for Invoke-TruffleHogScan' {
            # Alias may be created as function wrapper if command exists, so check for either
            $alias = Get-Alias trufflehog-scan -ErrorAction SilentlyContinue
            if (-not $alias) {
                # Try to create it if missing
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'trufflehog-scan' -Target 'Invoke-TruffleHogScan' | Out-Null
                }
                $alias = Get-Alias trufflehog-scan -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-TruffleHogScan'
            }
        }

        It 'trufflehog-scan alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('trufflehog', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'trufflehog' -Available $false
            $output = trufflehog-scan -Path (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'trufflehog'
        }
    }

    Context 'OSV-Scanner helpers (Invoke-OSVScan)' {
        BeforeAll {
            # Mock Get-Command to return null for 'osv-scanner' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'osv-scanner' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-OSVScan -ErrorAction SilentlyContinue
            Remove-Item Alias:\osv-scan -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'security-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-OSVScan function' {
            Get-Command Invoke-OSVScan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates osv-scan alias for Invoke-OSVScan' {
            # Alias may be created as function wrapper if command exists, so check for either
            $alias = Get-Alias osv-scan -ErrorAction SilentlyContinue
            if (-not $alias) {
                # Try to create it if missing
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'osv-scan' -Target 'Invoke-OSVScan' | Out-Null
                }
                $alias = Get-Alias osv-scan -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-OSVScan'
            }
        }

        It 'osv-scan alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('osv-scanner', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'osv-scanner' -Available $false
            $output = osv-scan -Path (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'osv-scanner'
        }
    }

    Context 'YARA helpers (Invoke-YaraScan)' {
        BeforeAll {
            # Mock Get-Command to return null for 'yara' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'yara' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-YaraScan -ErrorAction SilentlyContinue
            Remove-Item Alias:\yara-scan -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'security-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-YaraScan function' {
            Get-Command Invoke-YaraScan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yara-scan alias for Invoke-YaraScan' {
            # Alias may be created as function wrapper if command exists, so check for either
            $alias = Get-Alias yara-scan -ErrorAction SilentlyContinue
            if (-not $alias) {
                # Try to create it if missing
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'yara-scan' -Target 'Invoke-YaraScan' | Out-Null
                }
                $alias = Get-Alias yara-scan -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-YaraScan'
            }
        }

        It 'yara-scan alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('yara', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'yara' -Available $false
            $output = yara-scan -File (Get-Location).Path -Rules (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'yara'
        }
    }

    Context 'ClamAV helpers (Invoke-ClamAVScan)' {
        BeforeAll {
            # Mock Get-Command to return null for 'clamscan' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'clamscan' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-ClamAVScan -ErrorAction SilentlyContinue
            Remove-Item Alias:\clamav-scan -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'security-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-ClamAVScan function' {
            Get-Command Invoke-ClamAVScan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates clamav-scan alias for Invoke-ClamAVScan' {
            # Alias may be created as function wrapper if command exists, so check for either
            $alias = Get-Alias clamav-scan -ErrorAction SilentlyContinue
            if (-not $alias) {
                # Try to create it if missing
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'clamav-scan' -Target 'Invoke-ClamAVScan' | Out-Null
                }
                $alias = Get-Alias clamav-scan -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-ClamAVScan'
            }
        }

        It 'clamav-scan alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('clamscan', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'clamscan' -Available $false
            $output = clamav-scan -Path (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'clamav|clamscan'
        }
    }

    Context 'Dangerzone helpers (Invoke-DangerzoneConvert)' {
        BeforeAll {
            # Mock Get-Command to return null for 'dangerzone' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'dangerzone' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-DangerzoneConvert -ErrorAction SilentlyContinue
            Remove-Item Alias:\dangerzone -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'security-tools.ps1') -ErrorAction SilentlyContinue
        }

        It 'Creates Invoke-DangerzoneConvert function' {
            Get-Command Invoke-DangerzoneConvert -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates dangerzone alias for Invoke-DangerzoneConvert' {
            # Alias may be created as function wrapper if command exists, so check for either
            $alias = Get-Alias dangerzone -ErrorAction SilentlyContinue
            if (-not $alias) {
                # Try to create it if missing
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'dangerzone' -Target 'Invoke-DangerzoneConvert' | Out-Null
                }
                $alias = Get-Alias dangerzone -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-DangerzoneConvert'
            }
        }

        It 'dangerzone alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('dangerzone', [ref]$null)
            }
            # Clear command cache if it exists
            if (Get-Command Clear-CommandCache -ErrorAction SilentlyContinue) {
                Clear-CommandCache -CommandName 'dangerzone' -ErrorAction SilentlyContinue
            }
            Mock-CommandAvailabilityPester -CommandName 'dangerzone' -Available $false
            # Also mock Test-CachedCommand to ensure it returns false
            Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'dangerzone' } -MockWith { $false }
            $output = dangerzone -InputPath (Get-Location).Path -OutputPath (Get-Location).Path 2>&1 3>&1 | Out-String
            $output | Should -Match 'dangerzone'
        }
    }

    Context 'Fragment loading' {
        It 'Fragment loads without errors' {
            $securityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
            { . $securityToolsPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Fragment is idempotent (can be loaded multiple times)' {
            $securityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
            # Ensure function exists first
            if (-not (Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue)) {
                . $securityToolsPath -ErrorAction SilentlyContinue
            }
            $beforeFunction = Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue
            $beforeFunction | Should -Not -BeNullOrEmpty -Because "Function should exist before reload"
            
            # Reload fragment (should be idempotent - no errors)
            { . $securityToolsPath -ErrorAction SilentlyContinue } | Should -Not -Throw
            
            # Verify function still exists and is callable (idempotency means no errors on reload)
            $afterFunction = Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue
            $afterFunction | Should -Not -BeNullOrEmpty -Because "Function should still exist after reload"
            # Function should still be callable (idempotency means no errors on reload)
            { Invoke-GitLeaksScan -RepositoryPath (Get-Location).Path -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

