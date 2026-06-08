# ===============================================
# profile-winget-fragment-extended.tests.ps1
# Execution tests for winget.ps1 fragment behavior
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

Describe 'profile.d/winget.ps1 extended scenarios' {
    It 'Registers winget helpers when winget is available' {
        Set-TestCommandAvailabilityState -CommandName 'winget' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'winget.ps1')

        Get-Command Install-WingetPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-WingetOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command winget-install -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips winget helper registration when winget is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'winget' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'winget.ps1')

        Get-Command Install-WingetPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when winget is unavailable at load time' {
        if (Get-Command Test-ToolAvailableOnPlatform -ErrorAction SilentlyContinue) {
            if (-not (Test-ToolAvailableOnPlatform -Tool 'winget')) {
                Set-ItResult -Inconclusive -Because 'Winget install hints are only emitted on Windows'
            }
        }

        Set-TestCommandAvailabilityState -CommandName 'winget' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('winget', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'winget.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'winget not found'
    }
}
