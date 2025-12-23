<#
.SYNOPSIS
    Integration tests for system utility fragments (open.ps1).

.DESCRIPTION
    Tests Open-Item helper function.
    These tests verify that functions are created correctly.
#>

Describe 'System Utilities - Open Integration Tests' {
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
            Write-Error "Failed to initialize system utilities open tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Open helpers (open.ps1)' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'open.ps1')
        }

        It 'Creates Open-Item function' {
            Get-Command Open-Item -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates open alias for Open-Item' {
            Get-Alias open -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias open).ResolvedCommandName | Should -Be 'Open-Item'
        }

        It 'Open-Item function handles missing path parameter' {
            $output = Open-Item 2>&1
            $output | Should -Not -BeNullOrEmpty
            $outputString = $output | Out-String
            $outputString | Should -Match 'No path or URL provided to open'
        }
    }
}

