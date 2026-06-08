# ===============================================
# profile-local-overrides-fragment-extended.tests.ps1
# Execution tests for local-overrides.ps1 fragment behavior
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
    $script:SavedOverrideFlag = $env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES
    if (Test-Path -Path Variable:global:ProfileFragmentRoot) {
        $script:SavedFragmentRoot = $global:ProfileFragmentRoot
    }
    else {
        $script:SavedFragmentRoot = $null
    }
}

AfterAll {
    $env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES = $script:SavedOverrideFlag
    if ($null -eq $script:SavedFragmentRoot) {
        Remove-Variable -Name 'ProfileFragmentRoot' -Scope Global -ErrorAction SilentlyContinue
    }
    else {
        $global:ProfileFragmentRoot = $script:SavedFragmentRoot
    }
    Remove-Variable -Name 'LocalOverrideProbe' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/local-overrides.ps1 extended scenarios' {
    It 'Does not load overrides when PS_PROFILE_ENABLE_LOCAL_OVERRIDES is disabled' {
        $env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES = $null
        Remove-Variable -Name 'LocalOverrideProbe' -Scope Global -ErrorAction SilentlyContinue

        { . (Join-Path $script:ProfileDir 'local-overrides.ps1') } | Should -Not -Throw
        Get-Variable -Name 'LocalOverrideProbe' -Scope Global -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }

    It 'Loads override file content when local overrides are enabled' {
        $overrideDir = New-TestTempDirectory -Prefix 'local-overrides-fragment'
        $overridePath = Join-Path $overrideDir 'local-overrides.ps1'
        Set-Content -LiteralPath $overridePath -Value '$global:LocalOverrideProbe = "loaded"' -Encoding UTF8

        try {
            $global:ProfileFragmentRoot = $overrideDir
            $env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES = '1'
            Remove-Variable -Name 'LocalOverrideProbe' -Scope Global -ErrorAction SilentlyContinue

            . (Join-Path $script:ProfileDir 'local-overrides.ps1')

            (Get-Variable -Name 'LocalOverrideProbe' -Scope Global -ErrorAction Stop).Value |
                Should -Be 'loaded'
        }
        finally {
            Remove-TestArtifacts
        }
    }

    It 'Ignores missing override files without throwing when enabled' {
        $overrideDir = New-TestTempDirectory -Prefix 'local-overrides-missing'
        try {
            $global:ProfileFragmentRoot = $overrideDir
            $env:PS_PROFILE_ENABLE_LOCAL_OVERRIDES = '1'

            { . (Join-Path $script:ProfileDir 'local-overrides.ps1') } | Should -Not -Throw
        }
        finally {
            Remove-TestArtifacts
        }
    }
}
