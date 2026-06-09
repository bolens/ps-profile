# ===============================================
# profile-bootstrap-package-manager-base-extended.tests.ps1
# Execution tests for bootstrap/PackageManagerBase.ps1 behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-PackageManagerBaseState {
    Clear-FragmentLoaded -FragmentName 'package-manager-base' -ErrorAction SilentlyContinue
}

Describe 'profile.d/bootstrap/PackageManagerBase.ps1 extended scenarios' {
    BeforeEach {
        Reset-PackageManagerBaseState
    }

    It 'Registers package manager helpers and marks the fragment loaded' {
        . (Join-Path $script:BootstrapDir 'PackageManagerBase.ps1')

        Get-Command Register-PackageManager -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'package-manager-base' | Should -Be $true
    }

    It 'Register-PackageManager creates standardized package manager helpers' {
        . (Join-Path $script:BootstrapDir 'PackageManagerBase.ps1')

        Register-PackageManager -ManagerName 'FakePkg' -CommandName 'fakepkgcli' | Out-Null
        Get-Command Install-FakePkgPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-FakePkg -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips re-initialization when package-manager-base is already loaded' {
        . (Join-Path $script:BootstrapDir 'PackageManagerBase.ps1')
        $firstRegister = Get-Command Register-PackageManager -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'PackageManagerBase.ps1')

        (Get-Command Register-PackageManager -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRegister.ScriptBlock.ToString()
    }
}
