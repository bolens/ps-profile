# ===============================================
# profile-files-module-registry-load-ensure-extended.tests.ps1
# Execution tests for Load-EnsureModules deferred loading behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
}

Describe 'profile.d/files-module-registry.ps1 Load-EnsureModules extended scenarios' {
    It 'Registers Load-EnsureModules deferred loading helper' {
        Get-Command Load-EnsureModules -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Load-EnsureModules loads git modules from the registry' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-Git' -BaseDir $script:ProfileDir

        Get-Command Invoke-GitCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Load-EnsureModules can be called repeatedly without error' {
        { Load-EnsureModules -EnsureFunctionName 'Ensure-Git' -BaseDir $script:ProfileDir } | Should -Not -Throw
        { Load-EnsureModules -EnsureFunctionName 'Ensure-Git' -BaseDir $script:ProfileDir } | Should -Not -Throw
    }
}
