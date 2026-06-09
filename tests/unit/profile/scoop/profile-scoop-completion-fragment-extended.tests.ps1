# ===============================================
# profile-scoop-completion-fragment-extended.tests.ps1
# Execution tests for scoop-completion.ps1 fragment behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-ScoopCompletionFragmentState {
    Remove-Variable -Name 'ScoopCompletionLoaded' -Scope Global -Force -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\Enable-ScoopCompletion -Force -ErrorAction SilentlyContinue
    $env:SCOOP = $null
    $env:SCOOP_GLOBAL = $null
}

Describe 'profile.d/scoop-completion.ps1 extended scenarios' {
    BeforeEach {
        Reset-ScoopCompletionFragmentState
    }

    It 'Loads without setting ScoopCompletionLoaded until completion is enabled' {
        $isolatedHome = New-TestTempDirectory -Prefix 'ScoopExtendedNone'
        $originalHome = $env:HOME
        $originalUserProfile = $env:USERPROFILE
        try {
            $env:HOME = $isolatedHome
            $env:USERPROFILE = $isolatedHome

            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
        finally {
            $env:HOME = $originalHome
            $env:USERPROFILE = $originalUserProfile
        }
    }

    It 'Registers Enable-ScoopCompletion when a Scoop completion module is discovered' {
        $testScoopDir = New-TestTempDirectory -Prefix 'ScoopExtended'
        $completionPath = Join-Path $testScoopDir 'apps' 'scoop' 'current' 'supporting' 'completion' 'Scoop-Completion.psd1'
        New-Item -ItemType Directory -Path (Split-Path $completionPath -Parent) -Force | Out-Null
        New-Item -ItemType File -Path $completionPath -Force | Out-Null

        $env:SCOOP = $testScoopDir
        . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

        Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips re-initialization when ScoopCompletionLoaded is already set' {
        Set-Variable -Name 'ScoopCompletionLoaded' -Value $true -Scope Global -Force
        New-Item -Path Function:\Enable-ScoopCompletion -Value { 'existing' } -Force | Out-Null
        $firstEnable = Get-Command Enable-ScoopCompletion -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

        (Get-Command Enable-ScoopCompletion -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstEnable.ScriptBlock.ToString()
    }
}
