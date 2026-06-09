# ===============================================
# profile-nuxt-fragment-extended.tests.ps1
# Execution tests for nuxt.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'nuxt.ps1')
}

Describe 'profile.d/nuxt.ps1 extended scenarios' {
    It 'Registers Nuxt helpers and aliases' {
        Get-Command Invoke-Nuxt -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-NuxtDev -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command nuxi -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Nuxt warns when nuxi is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'nuxi' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('nuxi', [ref]$null)
        }

        $output = Invoke-Nuxt --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'nuxi not found'
    }

    It 'Start-NuxtDev warns when npx is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('npm', [ref]$null)
        }

        $output = Start-NuxtDev 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'npx not found'
    }
}
