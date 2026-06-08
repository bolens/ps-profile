# ===============================================
# profile-maven-fragment-extended.tests.ps1
# Execution tests for maven.ps1 fragment behavior
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

Describe 'profile.d/maven.ps1 extended scenarios' {
    It 'Registers maven helpers when mvn is available' {
        Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'maven.ps1')

        Get-Command Test-MavenOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-MavenDependency -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command maven-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips maven helper registration when mvn is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'maven.ps1')

        Get-Command Test-MavenOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when mvn is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'mvn' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('maven', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'maven.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mvn not found'
    }
}
