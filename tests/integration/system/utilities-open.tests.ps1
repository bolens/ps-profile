<#
.SYNOPSIS
    Integration tests for system utility fragments (open.ps1).

.DESCRIPTION
    Tests Open-Item helper function.
    These tests verify that functions are created correctly.
#>

Describe 'System Utilities - Open Integration Tests' {
    BeforeAll {
        $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
        if (-not (Test-Path -LiteralPath $testSupportPath)) {
            throw "TestSupport file not found at: $testSupportPath"
        }
        . $testSupportPath

        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap

        $openPath = Join-Path $script:ProfileDir 'open.ps1'
        if (-not (Test-Path -LiteralPath $openPath)) {
            throw "open.ps1 fragment not found at: $openPath"
        }
        $null = . $openPath
    }

    Context 'Open helpers (open.ps1)' {
        It 'Creates Open-Item function' {
            Get-Command Open-Item -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates open alias for Open-Item' {
            Get-Command Open-Item -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $openCommand = Get-Command open -ErrorAction SilentlyContinue
            if ($openCommand -and $openCommand.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'A system open executable shadows the profile open alias on this platform'
            }
            elseif ($openCommand -and $openCommand.CommandType -eq 'Alias') {
                $openCommand.Definition | Should -Be 'Open-Item'
            }
        }

        It 'Open-Item function handles missing path parameter' {
            $openItem = Get-Command Open-Item -CommandType Function -ErrorAction SilentlyContinue
            $openItem | Should -Not -Be $null
            { & $openItem | Out-Null } | Should -Not -Throw
        }
    }
}

