# ===============================================
# profile-bootstrap-platform-paths-extended.tests.ps1
# Execution tests for bootstrap/PlatformPaths.ps1 behavior
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

Describe 'profile.d/bootstrap/PlatformPaths.ps1 extended scenarios' {
    It 'Imports PlatformPaths library helpers through bootstrap' {
        Get-Command Get-TempDirectory -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ConfigDirectory -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-UserDirectory -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-TempDirectory returns a non-empty existing directory path' {
        $tempDir = Get-TempDirectory
        $tempDir | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $tempDir -PathType Container | Should -Be $true
    }

    It 'Allows repeated PlatformPaths module load without throwing' {
        { . (Join-Path $script:BootstrapDir 'PlatformPaths.ps1') } | Should -Not -Throw
        Get-Command Get-TempDirectory -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
