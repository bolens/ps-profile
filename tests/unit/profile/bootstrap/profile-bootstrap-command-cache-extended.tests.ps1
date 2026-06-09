# ===============================================
# profile-bootstrap-command-cache-extended.tests.ps1
# Execution tests for bootstrap/CommandCache.ps1 behavior
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

Describe 'profile.d/bootstrap/CommandCache.ps1 extended scenarios' {
    It 'Registers command cache helpers' {
        Get-Command Test-CachedCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-CachedExternalCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clear-TestCachedCommandCache -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-CachedCommand returns false for non-existent commands' {
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        $missing = "MissingCmd_$([Guid]::NewGuid().ToString('N'))"
        Test-CachedCommand -Name $missing | Should -Be $false
    }

    It 'Preserves command cache helper bodies on repeated module loads' {
        $firstTest = Get-Command Test-CachedCommand -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'CommandCache.ps1')

        (Get-Command Test-CachedCommand -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTest.ScriptBlock.ToString()
    }
}
