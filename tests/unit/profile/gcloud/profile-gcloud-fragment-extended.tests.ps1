# ===============================================
# profile-gcloud-fragment-extended.tests.ps1
# Execution tests for gcloud.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'gcloud.ps1')
}

Describe 'profile.d/gcloud.ps1 extended scenarios' {
    It 'Registers Invoke-GCloud and the gcloud alias' {
        Get-Command Invoke-GCloud -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias gcloud -ErrorAction SilentlyContinue
        if ($null -eq $alias) {
            $existing = Get-Command gcloud -ErrorAction SilentlyContinue
            if ($null -ne $existing -and $existing.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'gcloud application is on PATH; Set-AgentModeAlias skips alias registration by design'
                return
            }
        }

        $alias | Should -Not -BeNullOrEmpty
        $alias.ResolvedCommandName | Should -Be 'Invoke-GCloud'
    }

    It 'Registers Set-GCloudConfig helper command' {
        Get-Command Set-GCloudConfig -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-GCloud warns when gcloud is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('gcloud')
        Set-TestCommandAvailabilityState -CommandName 'gcloud' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('gcloud', [ref]$null)
        }

        $output = Invoke-GCloud --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gcloud not found'
    }
}
