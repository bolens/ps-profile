# ===============================================
# profile-kubectl-fragment-extended.tests.ps1
# Execution tests for kubectl.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'kubectl.ps1')
}

Describe 'profile.d/kubectl.ps1 extended scenarios' {
    It 'Registers Invoke-Kubectl and context helper commands' {
        Get-Command Invoke-Kubectl -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-KubectlContext -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command k -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers k shorthand alias targeting Invoke-Kubectl' {
        (Get-Alias k).ResolvedCommandName | Should -Be 'Invoke-Kubectl'
    }

    It 'Invoke-Kubectl warns when kubectl is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('kubectl')
        Set-TestCommandAvailabilityState -CommandName 'kubectl' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('kubectl', [ref]$null)
        }

        $output = Invoke-Kubectl version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'kubectl not found'
    }
}
