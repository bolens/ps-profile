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
    Integration tests for text processing tool fragments (jq-yq, rg).

.DESCRIPTION
    Tests jq/yq and ripgrep helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Text Processing Tools Integration Tests' {
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
        Write-Error "Failed to initialize text processing tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }

    Context 'jq/yq helpers (jq-yq.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('jq', 'yq')
            Set-TestCommandAvailabilityState -CommandName 'jq' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'yq' -Available $true
            . (Join-Path $script:ProfileDir 'jq-yq.ps1')
            Register-TestFragmentAliases @{
                jq2json = 'Convert-JqToJson'
                yq2json = 'Convert-YqToJson'
            }
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
            Mark-TestCommandsUnavailable -CommandNames @('jq')
            Set-TestCommandAvailabilityState -CommandName 'jq' -Available $false
            Set-Alias -Name jq2json -Value Convert-JqToJson -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = jq2json file.json 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'jq not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'jq'
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
            Mark-TestCommandsUnavailable -CommandNames @('yq')
            Set-TestCommandAvailabilityState -CommandName 'yq' -Available $false
            Set-Alias -Name yq2json -Value Convert-YqToJson -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = yq2json file.yaml 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'yq not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'yq'
        }
    }

    Context 'ripgrep helpers (rg.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('rg')
            Set-TestCommandAvailabilityState -CommandName 'rg' -Available $true
            . (Join-Path $script:ProfileDir 'rg.ps1')
            Register-TestFragmentAliases @{
                rgf = 'Find-RipgrepText'
            }
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
            Mark-TestCommandsUnavailable -CommandNames @('rg')
            Set-TestCommandAvailabilityState -CommandName 'rg' -Available $false
            Set-Alias -Name rgf -Value Find-RipgrepText -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = rgf pattern 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'rg not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'ripgrep'
        }
    }
}

