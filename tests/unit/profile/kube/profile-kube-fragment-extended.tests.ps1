# ===============================================
# profile-kube-fragment-extended.tests.ps1
# Execution tests for kube.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'kube.ps1')
}

Describe 'profile.d/kube.ps1 extended scenarios' {
    It 'Registers minikube cluster helpers and aliases' {
        Get-Command Start-MinikubeCluster -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Stop-MinikubeCluster -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command minikube-start -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Start-MinikubeCluster warns when minikube is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'minikube' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('minikube', [ref]$null)
        }

        $output = Start-MinikubeCluster 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'minikube not found'
    }

    It 'Preserves existing kube helper bodies on repeated fragment loads' {
        $firstStart = Get-Command Start-MinikubeCluster -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'kube.ps1')

        (Get-Command Start-MinikubeCluster -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstStart.ScriptBlock.ToString()
    }
}
