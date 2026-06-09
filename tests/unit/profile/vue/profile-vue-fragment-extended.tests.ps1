# ===============================================
# profile-vue-fragment-extended.tests.ps1
# Execution tests for vue.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'vue.ps1')
}

Describe 'profile.d/vue.ps1 extended scenarios' {
    It 'Registers Vue CLI helpers and aliases' {
        Get-Command Invoke-Vue -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-VueApp -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command vue -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Vue warns when npx and vue are unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'vue' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('npm', [ref]$null)
        }

        $output = Invoke-Vue --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'npx or vue not found'
    }

    It 'Preserves existing vue helper bodies on repeated fragment loads' {
        $firstVue = Get-Command Invoke-Vue -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'vue.ps1')

        (Get-Command Invoke-Vue -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstVue.ScriptBlock.ToString()
    }
}
