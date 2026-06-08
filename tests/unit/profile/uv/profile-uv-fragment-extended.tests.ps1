# ===============================================
# profile-uv-fragment-extended.tests.ps1
# Execution tests for uv.ps1 fragment behavior
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

Describe 'profile.d/uv.ps1 extended scenarios' {
    It 'Registers uv helpers when uv is available' {
        Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'uv.ps1')

        Get-Command Invoke-UVRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-UVDependency -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command uvrun -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips uv helper registration when uv is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'uv' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'uv.ps1')

        Get-Command Invoke-UVRun -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when uv is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'uv' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('uv', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'uv.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'uv not found'
    }
}
