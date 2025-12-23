<#
.SYNOPSIS
    Integration tests for text processing tool fragments (jq-yq, rg).

.DESCRIPTION
    Tests jq/yq and ripgrep helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Text Processing Tools Integration Tests' {
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
            Write-Error "Failed to initialize text processing tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'jq/yq helpers (jq-yq.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'jq' and 'yq' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'jq' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'yq' } -MockWith { $null }
            # Mock jq and yq commands before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'jq' -Available $false -Scope Context
            Mock-CommandAvailabilityPester -CommandName 'yq' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'jq' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'yq' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'jq-yq.ps1')
        }

        It 'Creates Convert-JqToJson function' {
            Get-Command Convert-JqToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates jq2json alias for Convert-JqToJson' {
            Get-Alias jq2json -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jq2json).ResolvedCommandName | Should -Be 'Convert-JqToJson'
        }

        It 'jq2json alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('jq', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'jq' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'jq' } -MockWith { $false }
            $output = jq2json file.json 2>&1 3>&1 | Out-String
            $output | Should -Match 'jq not found'
            $output | Should -Match 'scoop install jq'
        }

        It 'Creates Convert-YqToJson function' {
            Get-Command Convert-YqToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates yq2json alias for Convert-YqToJson' {
            Get-Alias yq2json -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yq2json).ResolvedCommandName | Should -Be 'Convert-YqToJson'
        }

        It 'yq2json alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('yq', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'yq' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'yq' } -MockWith { $false }
            $output = yq2json file.yaml 2>&1 3>&1 | Out-String
            $output | Should -Match 'yq not found'
            $output | Should -Match 'scoop install yq'
        }
    }

    Context 'ripgrep helpers (rg.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'rg' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'rg' } -MockWith { $null }
            # Mock rg command before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'rg' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'rg' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'rg.ps1')
        }

        It 'Creates Find-RipgrepText function' {
            Get-Command Find-RipgrepText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates rgf alias for Find-RipgrepText' {
            Get-Alias rgf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias rgf).ResolvedCommandName | Should -Be 'Find-RipgrepText'
        }

        It 'rgf alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('rg', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'rg' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'rg' } -MockWith { $false }
            $output = rgf pattern 2>&1 3>&1 | Out-String
            $output | Should -Match 'rg not found'
            $output | Should -Match 'scoop install ripgrep'
        }
    }
}

