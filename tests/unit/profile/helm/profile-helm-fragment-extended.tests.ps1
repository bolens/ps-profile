# ===============================================
# profile-helm-fragment-extended.tests.ps1
# Execution tests for helm.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'helm.ps1')
}

Describe 'profile.d/helm.ps1 extended scenarios' {
    It 'Registers Invoke-Helm and chart management helpers' {
        Get-Command Invoke-Helm -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Install-HelmChart -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command helm -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers helm-install alias targeting Install-HelmChart' {
        Get-Alias helm-install -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias helm-install).ResolvedCommandName | Should -Be 'Install-HelmChart'
    }

    It 'Invoke-Helm warns when helm is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('helm')
        Set-TestCommandAvailabilityState -CommandName 'helm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('helm', [ref]$null)
        }

        $output = Invoke-Helm --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'helm not found'
    }
}
