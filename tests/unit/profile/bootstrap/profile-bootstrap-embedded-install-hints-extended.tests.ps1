# ===============================================
# profile-bootstrap-embedded-install-hints-extended.tests.ps1
# Execution tests for bootstrap/EmbeddedInstallHints.ps1 behavior
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

Describe 'profile.d/bootstrap/EmbeddedInstallHints.ps1 extended scenarios' {
    It 'Registers embedded install hint helpers' {
        Get-Command Expand-EmbeddedNodeInstallHints -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Expand-EmbeddedPythonInstallHints -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-EmbeddedInstallCommandFromHint -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Expand-EmbeddedNodeInstallHints replaces node install placeholders' {
        $expanded = Expand-EmbeddedNodeInstallHints -Script 'run __NODE_INSTALL_CMD__' -PackageNames @('example')
        $expanded | Should -Not -Match '__NODE_INSTALL_CMD__'
        $expanded | Should -Match 'install'
    }

    It 'Preserves embedded install hint helper bodies on repeated module loads' {
        $firstExpand = Get-Command Expand-EmbeddedNodeInstallHints -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'EmbeddedInstallHints.ps1')

        (Get-Command Expand-EmbeddedNodeInstallHints -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstExpand.ScriptBlock.ToString()
    }
}
