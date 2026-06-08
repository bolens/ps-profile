# ===============================================
# profile-firebase-fragment-extended.tests.ps1
# Execution tests for firebase.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'firebase.ps1')
}

Describe 'profile.d/firebase.ps1 extended scenarios' {
    It 'Registers Firebase CLI helpers and aliases' {
        Get-Command Invoke-Firebase -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Publish-FirebaseDeployment -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command fb -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Firebase warns when firebase is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'firebase' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('firebase', [ref]$null)
        }

        $output = Invoke-Firebase --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'firebase not found'
    }

    It 'Preserves existing firebase helper bodies on repeated fragment loads' {
        $firstFirebase = Get-Command Invoke-Firebase -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'firebase.ps1')

        (Get-Command Invoke-Firebase -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstFirebase.ScriptBlock.ToString()
    }
}
