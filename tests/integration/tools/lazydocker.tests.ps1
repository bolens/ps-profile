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
    Integration tests for lazydocker tool fragment.

.DESCRIPTION
    Tests lazydocker helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'LazyDocker Integration Tests' {
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
            Write-Error "Failed to initialize lazydocker tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'lazydocker helpers (lazydocker.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('lazydocker', 'ld')
            Set-TestCommandAvailabilityState -CommandName 'lazydocker' -Available $true
            . (Join-Path $script:ProfileDir 'lazydocker.ps1')
            Register-TestFragmentAliases @{
                ld = 'Invoke-LazyDocker'
            }
        }

        It 'Creates Invoke-LazyDocker function' {
            Get-Command Invoke-LazyDocker -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ld alias for Invoke-LazyDocker' {
            Get-Alias ld -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ld).ResolvedCommandName | Should -Be 'Invoke-LazyDocker'
        }

        It 'ld alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('lazydocker', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('lazydocker')
            Set-TestCommandAvailabilityState -CommandName 'lazydocker' -Available $false
            Set-Alias -Name ld -Value Invoke-LazyDocker -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = ld 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'lazydocker not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'lazydocker'
        }
    }
}

