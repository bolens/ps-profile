# ===============================================
# profile-bootstrap-missing-tool-warnings-extended.tests.ps1
# Execution tests for bootstrap/MissingToolWarnings.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/MissingToolWarnings.ps1 extended scenarios' {
    It 'Registers missing tool warning helpers' {
        Get-Command Get-PlatformSpecificTools -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-ToolAvailableOnPlatform -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-MissingToolWarning -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-PlatformSpecificTools maps winget to Windows only' {
        $tools = Get-PlatformSpecificTools
        $tools.ContainsKey('winget') | Should -Be $true
        $tools['winget'] | Should -Contain 'Windows'
    }

    It 'Preserves missing tool warning helper bodies on repeated module loads' {
        $firstWrite = Get-Command Write-MissingToolWarning -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'MissingToolWarnings.ps1')

        (Get-Command Write-MissingToolWarning -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstWrite.ScriptBlock.ToString()
    }
}
