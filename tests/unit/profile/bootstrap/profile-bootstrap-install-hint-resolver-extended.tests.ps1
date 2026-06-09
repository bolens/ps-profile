# ===============================================
# profile-bootstrap-install-hint-resolver-extended.tests.ps1
# Execution tests for bootstrap/InstallHintResolver.ps1 behavior
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

Describe 'profile.d/bootstrap/InstallHintResolver.ps1 extended scenarios' {
    It 'Registers install hint resolution helpers' {
        Get-Command Get-PreferenceAwareInstallHint -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-MissingToolWarning -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Resolve-InstallPackageName -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-MissingToolWarning emits a missing-tool warning' {
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('nonexistent-tool-xyz', [ref]$null)
        }

        $output = & { Invoke-MissingToolWarning -ToolName 'nonexistent-tool-xyz' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'nonexistent-tool-xyz not found'
    }

    It 'Preserves install hint helper bodies on repeated module loads' {
        $firstInvoke = Get-Command Invoke-MissingToolWarning -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'InstallHintResolver.ps1')

        (Get-Command Invoke-MissingToolWarning -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInvoke.ScriptBlock.ToString()
    }
}
